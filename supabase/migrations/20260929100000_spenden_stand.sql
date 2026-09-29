DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns WHERE table_schema='public' AND table_name='donations' LOOP
    RAISE NOTICE 'donations: %', r.s;
  END LOOP;
  RAISE NOTICE '--- Funktionen rund um Spenden ---';
  FOR r IN SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname LIKE 'spende%' ORDER BY 1 LOOP
    RAISE NOTICE '  %(%)', r.proname, left(r.args, 110);
  END LOOP;
  FOR r IN SELECT count(*) AS n, count(DISTINCT zweck) AS zwecke FROM public.donations LOOP
    RAISE NOTICE '--- % Spenden, % verschiedene Zwecke ---', r.n, r.zwecke;
  END LOOP;
END $$;
