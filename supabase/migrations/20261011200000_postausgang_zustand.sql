-- Was der Versand ueber sich selbst weiss.
--
-- Die Oberflaeche konnte bisher nur in mail_settings nachsehen, ob ein
-- Postausgang eingerichtet ist. Das ist die falsche Stelle: die
-- Zugangsdaten duerfen auch als Geheimnis der Funktion liegen -- das war
-- die ausdrueckliche Bedingung -- und davon weiss die Datenbank nichts.
--
-- Am 09.10. fuehrte genau das zu einer falschen Auskunft: der Betreiber
-- hatte SMTP_HOST und Co. gesetzt, und die Maske meldete weiterhin
-- "kein Postausgang eingerichtet".
--
-- Deshalb berichtet jetzt der Versand selbst. Hier stehen NUR Zustand
-- und Zeitpunkt -- keine Adresse, kein Konto, kein Kennwort.

CREATE TABLE IF NOT EXISTS public.postausgang_zustand (
  id            boolean PRIMARY KEY DEFAULT true CHECK (id),  -- genau eine Zeile
  bereit        boolean NOT NULL DEFAULT false,
  quelle        text,            -- 'tabelle' oder 'geheimnis'
  geprueft_am   timestamptz,
  letzter_fehler text
);
INSERT INTO public.postausgang_zustand (id) VALUES (true) ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE public.postausgang_zustand IS
  'Was der Versand ueber sich selbst meldet. Nur Zustand und Zeitpunkt -- '
  'niemals Zugangsdaten; die bleiben im Geheimnis der Funktion.';

ALTER TABLE public.postausgang_zustand ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS postausgang_zustand_lesen ON public.postausgang_zustand;
CREATE POLICY postausgang_zustand_lesen ON public.postausgang_zustand
  FOR SELECT TO authenticated USING (true);
REVOKE ALL ON public.postausgang_zustand FROM anon, public;
GRANT SELECT ON public.postausgang_zustand TO authenticated;


-- Der Versand meldet seinen Zustand. Nur mit dem Dienstschluessel.
CREATE OR REPLACE FUNCTION public.postausgang_melden(
  p_bereit boolean, p_quelle text, p_fehler text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.postausgang_zustand
     SET bereit = coalesce(p_bereit, false), quelle = p_quelle,
         geprueft_am = now(), letzter_fehler = left(coalesce(p_fehler,''), 300)
   WHERE id;
END $$;
REVOKE ALL ON FUNCTION public.postausgang_melden(boolean, text, text) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.postausgang_melden(boolean, text, text) TO service_role;


-- Die Auskunft beruecksichtigt jetzt beide Wege.
CREATE OR REPLACE FUNCTION public.postausgang_bereit()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    -- Eine brauchbare Zeile in mail_settings ...
    EXISTS (SELECT 1 FROM public.mail_settings m
             WHERE m.aktiv AND coalesce(btrim(m.kennwort), '') <> '')
    -- ... oder der Versand hat zuletzt gemeldet, dass er kann. Aelter als
    -- zwei Tage gilt nicht: ein Geheimnis kann zurueckgezogen worden sein,
    -- und eine veraltete Zusage ist schlimmer als keine.
    OR EXISTS (SELECT 1 FROM public.postausgang_zustand z
                WHERE z.bereit AND z.geprueft_am > now() - interval '2 days');
$$;
REVOKE ALL ON FUNCTION public.postausgang_bereit() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.postausgang_bereit() TO authenticated;


-- Der Zeitplan darf nicht mehr an mail_settings haengen.
--
-- Er lautete: nur laufen, wenn eine aktive Zeile mit Kennwort existiert.
-- Damit lief er NIE, solange die Zugangsdaten als Geheimnis der Funktion
-- liegen -- und genau dort sollen sie liegen duerfen. Das erklaert die
-- "0 Versuche" an der Testnachricht: es wurde nie probiert.
--
-- Jetzt laeuft er, sobald etwas wartet. Ob er kann, entscheidet die
-- Funktion, und sie sagt es anschliessend hier.
SELECT cron.unschedule('postausgang_leeren') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'postausgang_leeren');

SELECT cron.schedule('postausgang_leeren', '*/10 * * * *', $cron$
  SELECT net.http_post(
    url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/send-mail-queue',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-cron-token', coalesce(
                   (SELECT zeitplan_token FROM public.mail_settings
                     WHERE zeitplan_token IS NOT NULL LIMIT 1), '')),
    body    := '{}'::jsonb
  ) WHERE EXISTS (SELECT 1 FROM public.mail_queue WHERE status = 'PENDING');
$cron$);


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_quelle text;
BEGIN
  IF (SELECT count(*) FROM public.postausgang_zustand) <> 1 THEN
    RAISE EXCEPTION 'postausgang_zustand muss genau eine Zeile haben.';
  END IF;

  -- Die Zustandstabelle darf nie Zugangsdaten aufnehmen.
  SELECT string_agg(column_name, ', ') INTO v_quelle
    FROM information_schema.columns
   WHERE table_schema='public' AND table_name='postausgang_zustand'
     AND column_name ~* '(kennwort|pass|benutzer|user|host|token)';
  IF v_quelle IS NOT NULL THEN
    RAISE EXCEPTION 'postausgang_zustand hat Spalten fuer Zugangsdaten: %', v_quelle;
  END IF;

  -- Niemand ausser dem Dienst darf melden -- sonst setzt sich ein Verein
  -- selbst auf "bereit" und die Maske luegt wieder.
  IF has_function_privilege('authenticated',
       'public.postausgang_melden(boolean, text, text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Angemeldete Konten koennen den Zustand selbst melden.';
  END IF;

  -- Der Zeitplan darf nicht mehr an mail_settings haengen.
  SELECT command INTO v_quelle FROM cron.job WHERE jobname='postausgang_leeren';
  IF v_quelle ~ 'aktiv' THEN
    RAISE EXCEPTION 'Der Zeitplan haengt weiterhin an einer aktiven mail_settings-Zeile.';
  END IF;

  SELECT count(*) INTO v_n FROM cron.job WHERE jobname='postausgang_leeren';
  IF v_n <> 1 THEN RAISE EXCEPTION 'Zeitplan postausgang_leeren: % statt 1.', v_n; END IF;

  RAISE NOTICE 'Zustandsmeldung bereit; der Zeitplan laeuft, sobald Post wartet.';
END $$;
