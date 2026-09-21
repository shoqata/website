DO $$
DECLARE r record; v_letzte text := '';
BEGIN
  FOR r IN
    SELECT tablename, policyname, cmd,
           left(coalesce(qual::text,'-'), 120) AS lesen,
           left(coalesce(with_check::text,'-'), 80) AS schreiben
      FROM pg_policies
     WHERE schemaname='public'
       AND tablename IN ('accounting_journal','accounting_accounts','fiscal_years',
                         'fiscal_budgets','expenses','family_links','families',
                         'events','event_registrations','news','sponsors','socialmediaposts')
     ORDER BY tablename, cmd, policyname
  LOOP
    IF r.tablename <> v_letzte THEN
      RAISE NOTICE '--- % ---', r.tablename; v_letzte := r.tablename;
    END IF;
    RAISE NOTICE '  % (%): %', rpad(r.policyname, 30), r.cmd, r.lesen;
  END LOOP;
END $$;
