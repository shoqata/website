DO $$
DECLARE r record; s text := '';
BEGIN
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='accounting_accounts' ORDER BY ordinal_position LOOP
    s := s || r.column_name || ' '; END LOOP;
  RAISE NOTICE 'accounting_accounts: %', s;
  FOR r IN SELECT code, name FROM public.accounting_accounts ORDER BY code LOOP
    RAISE NOTICE '  % %', rpad(r.code,6), r.name;
  END LOOP;
END $$;
