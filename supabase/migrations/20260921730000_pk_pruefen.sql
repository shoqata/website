DO $$
DECLARE r record; v_n int := 0;
BEGIN
  FOR r IN
    SELECT t.relname AS tabelle, pg_get_constraintdef(c.oid) AS def
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='public' AND c.contype='p'
       AND EXISTS (SELECT 1 FROM information_schema.columns ic
                    WHERE ic.table_schema='public' AND ic.table_name=t.relname
                      AND ic.column_name='tenantId')
       AND pg_get_constraintdef(c.oid) NOT ILIKE '%tenantId%'
       -- uuid- und text-Kennungen sind von sich aus eindeutig; gemeint sind
       -- sprechende Schluessel wie 'payment' oder 'system'.
       AND t.relname IN ('settings')
     ORDER BY 1
  LOOP
    RAISE NOTICE '  %: %', r.tabelle, r.def; v_n := v_n+1;
  END LOOP;
  IF v_n=0 THEN RAISE NOTICE '  keine'; END IF;
END $$;
