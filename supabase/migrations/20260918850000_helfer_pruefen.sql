DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.proname, pg_get_function_result(p.oid) AS ergebnis
             FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public'
              AND p.proname IN ('current_tenant','request_tenant','is_platform_admin',
                                'is_member_manager','is_staff','app_role','current_user_row_id')
            ORDER BY 1 LOOP
    RAISE NOTICE '% -> %', rpad(r.proname, 22), r.ergebnis;
  END LOOP;
END $$;
