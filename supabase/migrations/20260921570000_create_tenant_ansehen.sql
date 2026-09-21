DO $$
DECLARE v text;
BEGIN
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='create_tenant';
  RAISE NOTICE '%', v;
END $$;
