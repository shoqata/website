DO $$
DECLARE v text;
BEGIN
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='start_tenant_support';
  RAISE NOTICE 'start_tenant_support: %', left(coalesce(v,'(fehlt)'), 700);
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='current_tenant';
  RAISE NOTICE 'current_tenant: %', left(coalesce(v,'(fehlt)'), 700);
END $$;
