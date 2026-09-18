DO $$
DECLARE r record; z text;
BEGIN
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='v' ORDER BY c.relname LOOP
    RAISE NOTICE '--- % ---', r.relname;
    FOREACH z IN ARRAY string_to_array(
        pg_get_viewdef(format('public.%I', r.relname)::regclass, true), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', btrim(z); END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE '=== Rechte je Sicht ===';
  FOR r IN SELECT table_name, grantee, string_agg(DISTINCT privilege_type, ',' ORDER BY privilege_type) AS rechte
             FROM information_schema.role_table_grants
            WHERE table_schema='public'
              AND table_name IN (SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                                  WHERE n.nspname='public' AND c.relkind='v')
              AND grantee IN ('anon','authenticated')
            GROUP BY 1,2 ORDER BY 1,2 LOOP
    RAISE NOTICE '  % / %: %', r.table_name, r.grantee, r.rechte;
  END LOOP;
END $$;
