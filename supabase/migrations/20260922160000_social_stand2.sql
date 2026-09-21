DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Welche settings-Zeilen gibt es? ===';
  FOR r IN SELECT "tenantId", id FROM public.settings ORDER BY 1,2 LOOP
    RAISE NOTICE '  % / %', rpad(r."tenantId",12), r.id;
  END LOOP;
  RAISE NOTICE '=== Spalten von socialmediaposts ===';
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns WHERE table_schema='public' AND table_name='socialmediaposts' LOOP
    RAISE NOTICE '  %', r.s;
  END LOOP;
  FOR r IN SELECT count(*) AS n FROM public.socialmediaposts LOOP
    RAISE NOTICE '=== Beitraege gespeichert: % ===', r.n;
  END LOOP;
END $$;
