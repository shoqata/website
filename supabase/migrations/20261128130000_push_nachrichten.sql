-- Push-Nachrichten auf den Sperrbildschirm.
--
-- Das Benachrichtigungscenter zeigt Neues nur, solange die App offen ist.
-- Mit Push kommt dieselbe Benachrichtigung aufs Handy, auch wenn sie zu ist.
--
-- Weg: eine neue Zeile in benachrichtigungen -> dieser Ausloeser ruft die
-- Funktion push-senden auf -> sie schickt an jedes Geraet, das der Empfaenger
-- angemeldet hat (push_abos). Ein Geraet meldet die App an, sobald das
-- Mitglied im Benachrichtigungscenter "Push aktivieren" waehlt.

CREATE TABLE public.push_abos (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  empfaenger  text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  endpoint    text NOT NULL UNIQUE,
  p256dh      text NOT NULL,
  auth        text NOT NULL,
  -- Von welcher Adresse aus angemeldet: dorthin fuehrt ein Tipp auf die
  -- Nachricht (jeder Verein hat seine eigene Domain).
  herkunft    text,
  geraet      text,
  erstellt_am timestamptz NOT NULL DEFAULT now(),
  zuletzt_ok  timestamptz
);
CREATE INDEX push_abos_empfaenger_idx ON public.push_abos (empfaenger);

ALTER TABLE public.push_abos ENABLE ROW LEVEL SECURITY;
CREATE POLICY push_abos_eigene ON public.push_abos
  FOR SELECT TO authenticated USING (empfaenger = public.current_user_row_id());
GRANT SELECT ON public.push_abos TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.push_abos FROM anon, authenticated;

-- Geraet anmelden. Derselbe Endpunkt wird uebernommen, falls er vorher
-- einer anderen Person gehoerte (geteiltes Geraet, neu angemeldet).
CREATE OR REPLACE FUNCTION public.push_abo_speichern(
  p_endpoint text, p_p256dh text, p_auth text, p_herkunft text DEFAULT NULL, p_geraet text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_ich text := public.current_user_row_id(); v_verein text;
BEGIN
  IF v_ich IS NULL THEN RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'check_violation'; END IF;
  IF coalesce(p_endpoint, '') !~ '^https://' OR length(p_endpoint) > 1000
     OR coalesce(p_p256dh, '') = '' OR coalesce(p_auth, '') = '' THEN
    RAISE EXCEPTION 'Ungueltige Anmeldung des Geraets.' USING ERRCODE = 'check_violation'; END IF;
  SELECT "tenantId" INTO v_verein FROM public.users WHERE id = v_ich;
  INSERT INTO public.push_abos ("tenantId", empfaenger, endpoint, p256dh, auth, herkunft, geraet)
  VALUES (v_verein, v_ich, p_endpoint, p_p256dh, p_auth,
          CASE WHEN p_herkunft ~ '^https://[a-z0-9.-]+$' THEN p_herkunft END, left(p_geraet, 120))
  ON CONFLICT (endpoint) DO UPDATE SET
    "tenantId" = EXCLUDED."tenantId", empfaenger = EXCLUDED.empfaenger,
    p256dh = EXCLUDED.p256dh, auth = EXCLUDED.auth,
    herkunft = EXCLUDED.herkunft, geraet = EXCLUDED.geraet, erstellt_am = now();
END $$;

CREATE OR REPLACE FUNCTION public.push_abo_loeschen(p_endpoint text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' AS $$
  DELETE FROM public.push_abos WHERE endpoint = p_endpoint AND empfaenger = public.current_user_row_id();
$$;

REVOKE ALL ON FUNCTION public.push_abo_speichern(text, text, text, text, text) FROM public, anon;
REVOKE ALL ON FUNCTION public.push_abo_loeschen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.push_abo_speichern(text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.push_abo_loeschen(text) TO authenticated;

-- Pruefschluessel fuer den Aufruf der Funktion. Die Funktion liest ihn mit
-- dem Dienstschluessel selbst aus dieser Tabelle -- kein weiteres Geheimnis
-- zum Einrichten. Erzeugt hier, steht also nicht im Code.
INSERT INTO public.platform_secrets (schluessel, wert, notiz)
SELECT 'push_token', encode(extensions.gen_random_bytes(24), 'hex'),
       'Pruefschluessel: Datenbank -> Funktion push-senden'
 WHERE NOT EXISTS (SELECT 1 FROM public.platform_secrets WHERE schluessel = 'push_token');

-- Einmal je Anweisung, nicht je Zeile: eine Veranstaltung fuer 300
-- Mitglieder ist eine einzige INSERT-Anweisung und damit ein einziger
-- Aufruf. Nur wer ueberhaupt ein Geraet angemeldet hat, wird mitgeschickt.
CREATE OR REPLACE FUNCTION public.push_ausloesen() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_ids uuid[];
BEGIN
  BEGIN
    SELECT array_agg(n.id) INTO v_ids FROM neu n
     WHERE EXISTS (SELECT 1 FROM public.push_abos p WHERE p.empfaenger = n.empfaenger);
    IF v_ids IS NULL THEN RETURN NULL; END IF;
    PERFORM net.http_post(
      url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/push-senden',
      headers := jsonb_build_object('Content-Type', 'application/json',
                   'x-push-token', (SELECT wert FROM public.platform_secrets WHERE schluessel = 'push_token')),
      body    := jsonb_build_object('ids', to_jsonb(v_ids)));
  EXCEPTION WHEN others THEN
    -- Push ist Zugabe: die Benachrichtigung in der App bleibt in jedem Fall.
    RAISE WARNING 'Push ausloesen fehlgeschlagen: %', SQLERRM;
  END;
  RETURN NULL;
END $$;
REVOKE ALL ON FUNCTION public.push_ausloesen() FROM public, anon, authenticated;

CREATE TRIGGER push_nach_benachrichtigung
  AFTER INSERT ON public.benachrichtigungen
  REFERENCING NEW TABLE AS neu
  FOR EACH STATEMENT EXECUTE FUNCTION public.push_ausloesen();
