-- Der Versand bekommt einen Zeitplan.
--
-- Bisher stiess ihn nur die Anwendung an, wenn sie selbst etwas einreihte.
-- Die Geburtstagsgruesse legt der Auftrag geburtstagsgruesse um 06:05 ab --
-- und niemand holte sie ab. Sie waeren dort liegen geblieben.
--
-- pg_net fehlte, deshalb konnte der Zeitplan ueberhaupt keine Funktion
-- aufrufen.
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- --- Kennwort des Zeitplans pruefen ---------------------------------------
-- Die Funktion send-mail-queue fragt hierueber, ob ein mitgeschicktes
-- Kennwort zu einem Verein gehoert. Der Vergleich geschieht in der
-- Datenbank, damit das Kennwort nicht in die Funktion wandern muss.
CREATE OR REPLACE FUNCTION public.zeitplan_token_gueltig(p_token text)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.mail_settings
     WHERE zeitplan_token = p_token AND btrim(coalesce(p_token,'')) <> ''
  );
$$;
REVOKE ALL ON FUNCTION public.zeitplan_token_gueltig(text) FROM public, anon, authenticated;

-- --- Der Auftrag ----------------------------------------------------------
-- Alle zehn Minuten nachsehen, ob etwas offen ist. Haeufiger waere unnoetig:
-- was die Anwendung selbst einreiht, stoesst sie ohnehin sofort an. Dieser
-- Auftrag ist fuer das, was ohne Zutun entsteht -- Geburtstagsgruesse,
-- Mahnungen.
DO $$
DECLARE v_token text; v_id bigint;
BEGIN
  SELECT zeitplan_token INTO v_token FROM public.mail_settings LIMIT 1;

  IF v_token IS NULL THEN
    RAISE NOTICE 'Noch kein Postausgang eingetragen -- der Auftrag wird beim';
    RAISE NOTICE 'ersten Speichern in der Verwaltung mit angelegt.';
  END IF;

  PERFORM cron.unschedule('postausgang_leeren')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'postausgang_leeren');

  SELECT cron.schedule('postausgang_leeren', '*/10 * * * *', $cmd$
    SELECT extensions.http_post(
      url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/send-mail-queue',
      headers := jsonb_build_object(
                   'Content-Type', 'application/json',
                   'x-cron-token', (SELECT zeitplan_token FROM public.mail_settings LIMIT 1)),
      body    := '{}'::jsonb
    ) WHERE EXISTS (SELECT 1 FROM public.mail_queue WHERE status = 'PENDING');
  $cmd$) INTO v_id;
  RAISE NOTICE 'Auftrag postausgang_leeren angelegt (Nummer %)', v_id;
END $$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT jobname, schedule, active FROM cron.job ORDER BY jobname LOOP
    RAISE NOTICE 'Zeitplan: % | % | aktiv %', rpad(r.jobname, 24), rpad(r.schedule, 14), r.active;
  END LOOP;
END $$;
