DO $$
DECLARE r record; v_n int := 0;
BEGIN
  FOR r IN
    SELECT DISTINCT tc.constraint_name, tc.table_name, kcu.column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
      LEFT JOIN information_schema.key_column_usage kcu
        ON kcu.constraint_name = tc.constraint_name
     WHERE tc.constraint_type='FOREIGN KEY'
       AND ccu.table_name='accounting_accounts'
  LOOP
    RAISE NOTICE '  % auf %.%', r.constraint_name, r.table_name, r.column_name;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine Fremdschluessel gefunden'; END IF;
END $$;
