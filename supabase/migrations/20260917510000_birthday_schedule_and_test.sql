-- Taeglicher Lauf, und die Probe aufs Exempel.
CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
DECLARE r record; v_n int; v_tag date; v_name text; v_mail text;
BEGIN
  -- Einmal taeglich frueh am Morgen. Ein bestehender Auftrag wird ersetzt,
  -- damit ein erneuter Lauf dieser Migration keine Dubletten anlegt.
  PERFORM cron.unschedule('geburtstagsgruesse')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'geburtstagsgruesse');

  PERFORM cron.schedule('geburtstagsgruesse', '5 6 * * *',
                        $cmd$ SELECT public.queue_birthday_greetings(); $cmd$);
  RAISE NOTICE 'Taeglicher Auftrag eingerichtet: 06:05 Uhr.';

  FOR r IN SELECT jobname, schedule, active FROM cron.job ORDER BY jobname LOOP
    RAISE NOTICE '  Auftrag % -- % (aktiv %)', r.jobname, r.schedule, r.active;
  END LOOP;

  -- ------------------------------------------------------------- Probe
  -- An einem Tag pruefen, an dem tatsaechlich jemand Geburtstag hat.
  SELECT u.birthdate::date, u."displayName", u.email INTO v_tag, v_name, v_mail
    FROM public.users u
   WHERE u.birthdate IS NOT NULL AND btrim(u.birthdate::text) <> ''
     AND u.email IS NOT NULL AND u.email LIKE '%@%.%'
     AND u.email NOT ILIKE '%@koretini.legacy' AND u.email NOT ILIKE '%no-email-%'
   LIMIT 1;

  IF v_tag IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: niemand mit Geburtsdatum und brauchbarer Adresse.';
    RETURN;
  END IF;

  -- Derselbe Tag und Monat, aber im laufenden Jahr.
  v_tag := make_date(EXTRACT(YEAR FROM current_date)::int,
                     EXTRACT(MONTH FROM v_tag)::int,
                     EXTRACT(DAY FROM v_tag)::int);
  RAISE NOTICE 'Probe fuer % (%) am %', v_name, v_mail, v_tag;

  SELECT public.queue_birthday_greetings(v_tag) INTO v_n;
  RAISE NOTICE '1 eingereiht: % -- erwartet mindestens 1', v_n;

  SELECT public.queue_birthday_greetings(v_tag) INTO v_n;
  RAISE NOTICE '2 derselbe Tag noch einmal: % -- erwartet 0, kein zweiter Gruss', v_n;

  FOR r IN SELECT recipient, subject, status FROM public.mail_queue
            WHERE kind = 'BIRTHDAY' ORDER BY "createdAt" DESC LIMIT 3 LOOP
    RAISE NOTICE '  Warteschlange: % | % | %', r.recipient, left(r.subject, 44), r.status;
  END LOOP;

  -- Ein Tag ohne Geburtstage darf nichts erzeugen.
  SELECT public.queue_birthday_greetings(v_tag + 200) INTO v_n;
  RAISE NOTICE '3 ein Tag ohne Geburtstage: % -- erwartet 0', v_n;

  -- Die Probe wieder entfernen; der Auftrag um 06:05 legt sie am Tag selbst an.
  DELETE FROM public.mail_queue WHERE kind = 'BIRTHDAY';
  RAISE NOTICE 'Probe aus der Warteschlange entfernt.';
END $$;
