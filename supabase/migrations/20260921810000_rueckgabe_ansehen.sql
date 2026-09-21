DO $$
DECLARE v text;
BEGIN
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='reset_member_password';
  -- Die letzten Zeilen: was gibt sie zurueck?
  RAISE NOTICE '%', substr(v, length(v)-700, 700);
END $$;
