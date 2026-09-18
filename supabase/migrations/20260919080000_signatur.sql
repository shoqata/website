DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.proname, pg_get_function_result(p.oid) AS erg
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname IN ('my_neighborhoods','is_neighborhood_steward') LOOP
    RAISE NOTICE '  % -> %', r.proname, r.erg;
  END LOOP;
END $$;
