-- Welche Eindeutigkeiten gelten global statt je Verein?
-- In einer Anwendung fuer mehrere Vereine ist das ein Fehler: was bei einem
-- Verein vergeben ist, waere beim naechsten blockiert.
DO $$
DECLARE r record; v_n int := 0;
BEGIN
  FOR r IN
    SELECT c.conname, t.relname AS tabelle,
           pg_get_constraintdef(c.oid) AS regel
      FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
     WHERE n.nspname='public' AND c.contype='u'
       -- nur Tabellen, die einem Verein gehoeren
       AND EXISTS (SELECT 1 FROM information_schema.columns ic
                    WHERE ic.table_schema='public' AND ic.table_name=t.relname
                      AND ic.column_name='tenantId')
       AND pg_get_constraintdef(c.oid) NOT ILIKE '%tenantId%'
     ORDER BY t.relname, c.conname
  LOOP
    RAISE NOTICE '  %.%  ->  %', rpad(r.tabelle,22), rpad(r.conname,34), r.regel;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; ELSE RAISE NOTICE '  % Stueck', v_n; END IF;

  RAISE NOTICE '--- dasselbe fuer eindeutige Indizes ---';
  v_n := 0;
  FOR r IN
    SELECT i.indexname, i.tablename, i.indexdef
      FROM pg_indexes i
     WHERE i.schemaname='public' AND i.indexdef ILIKE '%UNIQUE%'
       AND i.indexdef NOT ILIKE '%tenantId%'
       AND EXISTS (SELECT 1 FROM information_schema.columns ic
                    WHERE ic.table_schema='public' AND ic.table_name=i.tablename
                      AND ic.column_name='tenantId')
       AND i.indexname NOT LIKE '%_pkey'
     ORDER BY i.tablename
  LOOP
    RAISE NOTICE '  %.%', rpad(r.tablename,22), r.indexname;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; ELSE RAISE NOTICE '  % Stueck', v_n; END IF;
END $$;
