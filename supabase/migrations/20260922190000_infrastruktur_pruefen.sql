DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Erweiterungen ===';
  FOR r IN SELECT extname, extnamespace::regnamespace AS wo FROM pg_extension
            WHERE extname IN ('pg_net','pg_cron','pgcrypto','http') LOOP
    RAISE NOTICE '  % in %', rpad(r.extname,10), r.wo;
  END LOOP;

  RAISE NOTICE '=== Laufende Auftraege (pg_cron) ===';
  BEGIN
    FOR r IN SELECT jobname, schedule, left(command, 70) AS befehl, active FROM cron.job LOOP
      RAISE NOTICE '  % | % | aktiv=% | %', rpad(r.jobname,26), rpad(r.schedule,14), r.active, r.befehl;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  (cron.job nicht lesbar: %)', left(SQLERRM,40);
  END;

  RAISE NOTICE '=== Ablagen (storage.buckets) ===';
  BEGIN
    FOR r IN SELECT id, public FROM storage.buckets LOOP
      RAISE NOTICE '  % | oeffentlich=%', rpad(r.id,24), r.public;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  (nicht lesbar: %)', left(SQLERRM,40);
  END;

  RAISE NOTICE '=== Gibt es schon eine Stelle fuer Plattform-Geheimnisse? ===';
  FOR r IN SELECT table_name FROM information_schema.tables
            WHERE table_schema='public'
              AND (table_name ILIKE '%secret%' OR table_name ILIKE '%credential%'
                   OR table_name ILIKE '%platform%' OR table_name ILIKE '%connection%') LOOP
    RAISE NOTICE '  %', r.table_name;
  END LOOP;
END $$;
