-- Der Weg nach draussen: ausgeloest vom Server, nie vom Browser.
--
-- Im September blieb zweimal spurlos ein Konto aus, weil der Browser
-- /functions/v1/ nicht erreichte -- Werbeblocker und Firmennetze behandeln
-- diesen Pfad anders als /rest/v1/. Deshalb ruft hier ausschliesslich die
-- Datenbank die Funktion, ueber pg_net. Der Client spricht nur mit
-- /rest/v1/rpc/, also ueber denselben Weg wie alles andere.

CREATE TABLE IF NOT EXISTS public.platform_secrets (
  schluessel text PRIMARY KEY,
  wert       text NOT NULL,
  notiz      text,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_secrets ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.platform_secrets FROM anon, authenticated;

-- Einmal erzeugen, nicht bei jedem Lauf neu: sonst passt der Wert nicht
-- mehr zu dem, was in der Umgebung der Funktion steht.
INSERT INTO public.platform_secrets (schluessel, wert, notiz)
SELECT 'social_cron_token', encode(extensions.gen_random_bytes(24),'hex'),
       'Muss als SOCIAL_CRON_TOKEN in der Umgebung der Funktion social-publish stehen.'
 WHERE NOT EXISTS (SELECT 1 FROM public.platform_secrets WHERE schluessel='social_cron_token');


-- Einen Beitrag jetzt senden. Setzt ihn in die Warteschlange und stupst die
-- Funktion sofort an, damit niemand bis zum naechsten Zeitplanlauf wartet.
CREATE OR REPLACE FUNCTION public.social_jetzt_senden(p_beitrag text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text; v_status text; v_n int;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf veroeffentlichen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT "tenantId", status INTO v_verein, v_status
    FROM public.socialmediaposts WHERE id = p_beitrag;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Diesen Beitrag gibt es nicht.' USING ERRCODE='check_violation';
  END IF;
  IF v_verein <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieser Beitrag gehoert zu einem anderen Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF v_status = 'PUBLISHED' THEN
    RAISE EXCEPTION 'Dieser Beitrag ist bereits veroeffentlicht.' USING ERRCODE='check_violation';
  END IF;

  SELECT count(*) INTO v_n FROM public.social_connections
   WHERE "tenantId" = v_verein AND zustand = 'AKTIV';
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieser Verein ist mit keinem Kanal verbunden. Erst verbinden, dann senden.'
      USING ERRCODE='check_violation';
  END IF;

  UPDATE public.socialmediaposts
     SET status = 'QUEUED', "lastError" = NULL, "scheduledTime" = NULL
   WHERE id = p_beitrag;

  PERFORM net.http_post(
    url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/social-publish',
    headers := jsonb_build_object('Content-Type','application/json',
                 'x-cron-token', (SELECT wert FROM public.platform_secrets
                                   WHERE schluessel='social_cron_token')),
    body    := jsonb_build_object('beitrag', p_beitrag));

  RETURN 'in die Warteschlange gestellt';
END $$;
REVOKE ALL ON FUNCTION public.social_jetzt_senden(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.social_jetzt_senden(text) TO authenticated;


-- Der Zeitplan. Ruft nur an, wenn es ueberhaupt etwas zu tun gibt -- ein
-- Aufruf alle fuenf Minuten ins Leere kostet nichts, ist aber auch nichts
-- wert und verschleiert im Protokoll die echten Laeufe.
DO $$
DECLARE v_id bigint;
BEGIN
  PERFORM cron.unschedule('social_veroeffentlichen')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname='social_veroeffentlichen');

  SELECT cron.schedule('social_veroeffentlichen', '*/5 * * * *', $cmd$
    SELECT net.http_post(
      url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/social-publish',
      headers := jsonb_build_object('Content-Type','application/json',
                   'x-cron-token', (SELECT wert FROM public.platform_secrets
                                     WHERE schluessel='social_cron_token')),
      body    := '{}'::jsonb
    ) WHERE EXISTS (
      SELECT 1 FROM public.socialmediaposts p
       WHERE (p.status = 'QUEUED')
          OR (p.status = 'SCHEDULED' AND p."scheduledTime" IS NOT NULL
              AND p."scheduledTime"::timestamptz <= now()));
  $cmd$) INTO v_id;
  RAISE NOTICE 'Auftrag social_veroeffentlichen angelegt (Nummer %)', v_id;
END $$;

-- Den Befehl einmal wirklich ausfuehren. Ohne faellige Beitraege tut er
-- nichts -- aber ein Tippfehler im Schema oder Funktionsnamen faellt hier
-- auf und nicht erst in fuenf Minuten im Stillen.
DO $$
DECLARE v_befehl text;
BEGIN
  SELECT command INTO v_befehl FROM cron.job WHERE jobname='social_veroeffentlichen';
  BEGIN
    EXECUTE v_befehl;
    RAISE NOTICE 'Befehl laeuft durch.';
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Der Zeitplanbefehl ist fehlerhaft: %', SQLERRM;
  END;
END $$;
