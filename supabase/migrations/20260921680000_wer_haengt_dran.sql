-- Was haengt an accounting_accounts_code_key?
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.conname, t.relname AS tabelle, pg_get_constraintdef(c.oid) AS def
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
     WHERE c.confrelid = 'public.accounting_accounts'::regclass
  LOOP
    RAISE NOTICE '  Fremdschluessel %.% -> %', r.tabelle, r.conname, r.def;
  END LOOP;
END $$;
