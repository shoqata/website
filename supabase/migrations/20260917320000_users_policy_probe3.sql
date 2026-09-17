DO $$
DECLARE r record; z text;
BEGIN
  FOR r IN SELECT p.proname, p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public'
              AND p.proname IN ('app_role','claimable_role','is_member_manager','claim_user_row','current_user_row_id')
            ORDER BY p.proname LOOP
    RAISE NOTICE '--- % ---', r.proname;
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', z; END IF;
    END LOOP;
  END LOOP;
END $$;
