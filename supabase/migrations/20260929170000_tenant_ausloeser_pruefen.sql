DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Welche Tabellen fuellen tenantId selbst? ===';
  FOR r IN SELECT c.relname AS tabelle,
                  EXISTS (SELECT 1 FROM pg_trigger t
                           WHERE t.tgrelid = c.oid AND NOT t.tgisinternal
                             AND t.tgfoid = 'public.set_tenant_on_insert'::regproc) AS hat_ausloeser
             FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             JOIN information_schema.columns col
               ON col.table_schema='public' AND col.table_name=c.relname AND col.column_name='tenantId'
            WHERE n.nspname='public' AND c.relkind='r'
            ORDER BY 2, 1 LOOP
    RAISE NOTICE '  % %', CASE WHEN r.hat_ausloeser THEN ' ja ' ELSE ' NEIN' END, r.tabelle;
  END LOOP;
END $$;
