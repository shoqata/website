-- pg_net legt seine Funktionen im Schema net ab, nicht in extensions --
-- ungeachtet des WITH SCHEMA in CREATE EXTENSION. Der eben angelegte
-- Auftrag haette alle zehn Minuten still nichts getan.
DO $$
DECLARE v_id bigint;
BEGIN
  PERFORM cron.unschedule('postausgang_leeren')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'postausgang_leeren');

  SELECT cron.schedule('postausgang_leeren', '*/10 * * * *', $cmd$
    SELECT net.http_post(
      url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/send-mail-queue',
      headers := jsonb_build_object(
                   'Content-Type', 'application/json',
                   'x-cron-token', (SELECT zeitplan_token FROM public.mail_settings
                                     WHERE aktiv AND coalesce(btrim(kennwort),'') <> '' LIMIT 1)),
      body    := '{}'::jsonb
    ) WHERE EXISTS (SELECT 1 FROM public.mail_queue WHERE status = 'PENDING')
      AND EXISTS (SELECT 1 FROM public.mail_settings
                   WHERE aktiv AND coalesce(btrim(kennwort),'') <> '');
  $cmd$) INTO v_id;
  RAISE NOTICE 'Auftrag postausgang_leeren richtiggestellt (Nummer %)', v_id;
END $$;

-- Und jetzt wirklich ausprobieren: der Befehl wird einmal von Hand
-- ausgefuehrt. Ohne eingetragenen Postausgang tut er nichts -- aber ein
-- Tippfehler im Schema oder Funktionsnamen faellt hier auf.
DO $$
DECLARE v_befehl text;
BEGIN
  SELECT command INTO v_befehl FROM cron.job WHERE jobname = 'postausgang_leeren';
  BEGIN
    EXECUTE v_befehl;
    RAISE NOTICE 'Der Befehl laeuft durch.';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Der Befehl scheitert: % (%)', SQLERRM, SQLSTATE;
  END;
END $$;
