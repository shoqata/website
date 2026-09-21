-- Das Modul fuer soziale Medien, gemessen statt vermutet.
DO $$
DECLARE v_back text := current_user; r record; v_n int;
BEGIN
  RAISE NOTICE '=== 1. Wo liegen die Zugangsdaten? ===';
  FOR r IN SELECT id,
                  (data ? 'fbAccessToken') AS fb,
                  (data ? 'igAccessToken') AS ig,
                  (data ? 'autoPostingEnabled') AS auto,
                  "tenantId"
             FROM public.settings WHERE data IS NOT NULL ORDER BY id LOOP
    RAISE NOTICE '  settings/% (Verein %): fbToken % | igToken % | autoPosting %',
      rpad(r.id,10), r."tenantId", r.fb, r.ig, r.auto;
  END LOOP;

  RAISE NOTICE '=== 2. Gibt public_settings die Spalte data heraus? ===';
  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema='public' AND table_name='public_settings' AND column_name='data';
  RAISE NOTICE '  Spalte data in public_settings: % (1 = ja, dann waeren Tokens oeffentlich)', v_n;

  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_settings WHERE data IS NOT NULL;
    RAISE NOTICE '  anon liest % Zeilen mit data', v_n;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  anon: kein Zugriff';
  END;
  EXECUTE format('SET ROLE %I', v_back);

  RAISE NOTICE '=== 3. Beitraege in der Tabelle ===';
  FOR r IN SELECT status, count(*) AS n FROM public.socialmediaposts GROUP BY 1 LOOP
    RAISE NOTICE '  %: %', rpad(coalesce(r.status,'(leer)'),10), r.n;
  END LOOP;
  SELECT count(*) INTO v_n FROM public.socialmediaposts;
  RAISE NOTICE '  insgesamt: %', v_n;

  SELECT count(*) INTO v_n FROM public.socialmediaposts WHERE "tenantId" IS NULL;
  RAISE NOTICE '  ohne Vereinszuordnung: %', v_n;

  RAISE NOTICE '=== 4. Verarbeitet irgendetwas geplante Beitraege? ===';
  SELECT count(*) INTO v_n FROM cron.job WHERE command ILIKE '%social%';
  RAISE NOTICE '  Zeitplan-Auftraege fuer soziale Medien: %', v_n;
END $$;
