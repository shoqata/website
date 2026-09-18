-- Rundumpruefung des aktuellen Standes. Nur Messung, keine Aenderung.
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== 1. Tabellen ohne Zeilenregel (RLS) ===';
  v_n := 0;
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='r' AND NOT c.relrowsecurity
            ORDER BY 1 LOOP
    RAISE NOTICE '   OFFEN: %', r.relname; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;

  RAISE NOTICE '=== 2. Tabellen MIT RLS, aber ohne jede Regel und mit Rechten fuer anon/authenticated ===';
  v_n := 0;
  FOR r IN
    SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND c.relkind='r' AND c.relrowsecurity
       AND NOT EXISTS (SELECT 1 FROM pg_policies p WHERE p.schemaname='public' AND p.tablename=c.relname)
       AND EXISTS (SELECT 1 FROM information_schema.role_table_grants g
                    WHERE g.table_schema='public' AND g.table_name=c.relname
                      AND g.grantee IN ('anon','authenticated'))
     ORDER BY 1 LOOP
    RAISE NOTICE '   ERREICHBAR OHNE REGEL: %', r.relname; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;

  RAISE NOTICE '=== 3. Sichten, die Zeilenregeln umgehen (security_invoker aus) ===';
  v_n := 0;
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='v'
              AND coalesce((SELECT option_value FROM pg_options_to_table(c.reloptions)
                             WHERE option_name='security_invoker'), 'false') <> 'true'
            ORDER BY 1 LOOP
    RAISE NOTICE '   %', r.relname; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;

  RAISE NOTICE '=== 4. Sichten mit Schreibrechten fuer anon/authenticated ===';
  v_n := 0;
  FOR r IN SELECT DISTINCT g.table_name, g.grantee, g.privilege_type
             FROM information_schema.role_table_grants g
             JOIN pg_class c ON c.relname=g.table_name
             JOIN pg_namespace n ON n.oid=c.relnamespace AND n.nspname='public'
            WHERE c.relkind='v' AND g.grantee IN ('anon','authenticated')
              AND g.privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE')
            ORDER BY 1,2 LOOP
    RAISE NOTICE '   % : % darf %', r.table_name, r.grantee, r.privilege_type; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;

  RAISE NOTICE '=== 5. SECURITY-DEFINER-Funktionen ohne festen search_path ===';
  v_n := 0;
  FOR r IN SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.prosecdef
              AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig,'{}')) c
                               WHERE c LIKE 'search_path=%')
            ORDER BY 1 LOOP
    RAISE NOTICE '   %', r.proname; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;

  RAISE NOTICE '=== 6. SECURITY-DEFINER-Funktionen, die anon ausfuehren darf ===';
  v_n := 0;
  FOR r IN SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.prosecdef
              AND has_function_privilege('anon', p.oid, 'EXECUTE')
            ORDER BY 1 LOOP
    RAISE NOTICE '   %', r.proname; v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '   keine'; END IF;
END $$;
