DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT pg_get_function_identity_arguments(p.oid) AS a
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='create_tenant' LOOP
    RAISE NOTICE 'create_tenant(%)', r.a;
  END LOOP;
END $$;
