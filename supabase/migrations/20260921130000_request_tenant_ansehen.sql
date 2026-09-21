DO $$
DECLARE v text;
BEGIN
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='request_tenant';
  RAISE NOTICE 'request_tenant:'; RAISE NOTICE '%', v;
END $$;
