DO $$
DECLARE v text;
BEGIN
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='reset_member_password';
  RAISE NOTICE '%', left(coalesce(v,'(nicht vorhanden)'), 1400);
END $$;
