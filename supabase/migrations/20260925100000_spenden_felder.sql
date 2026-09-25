DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns WHERE table_schema='public' AND table_name='donations' LOOP
    RAISE NOTICE 'donations: %', r.s;
  END LOOP;
  RAISE NOTICE '=== Oeffentlich lesbare Sichten ===';
  FOR r IN SELECT table_name FROM information_schema.views WHERE table_schema='public' ORDER BY 1 LOOP
    RAISE NOTICE '  %', r.table_name;
  END LOOP;
  RAISE NOTICE '=== Was darf anon ueberhaupt lesen? ===';
  FOR r IN SELECT table_name, string_agg(DISTINCT privilege_type,',') AS rechte
             FROM information_schema.role_table_grants
            WHERE grantee='anon' AND table_schema='public'
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  % -> %', rpad(r.table_name,26), r.rechte;
  END LOOP;
END $$;
