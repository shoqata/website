DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Zeilen in der Datenbank (ohne Zeilenregeln) ===';
  FOR r IN SELECT 'users' AS t, count(*) AS n FROM public.users
           UNION ALL SELECT 'payments', count(*) FROM public.payments
           UNION ALL SELECT 'accounting_journal', count(*) FROM public.accounting_journal
           UNION ALL SELECT 'events', count(*) FROM public.events
           UNION ALL SELECT 'neighborhoods', count(*) FROM public.neighborhoods
           UNION ALL SELECT 'tenants', count(*) FROM public.tenants
           UNION ALL SELECT 'settings', count(*) FROM public.settings LOOP
    RAISE NOTICE '  % -> %', rpad(r.t,22), r.n;
  END LOOP;

  RAISE NOTICE '=== Davon koretini ===';
  FOR r IN SELECT 'users' AS t, count(*) AS n FROM public.users WHERE "tenantId"='koretini'
           UNION ALL SELECT 'payments', count(*) FROM public.payments WHERE "tenantId"='koretini'
           UNION ALL SELECT 'accounting_journal', count(*) FROM public.accounting_journal WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  % -> %', rpad(r.t,22), r.n;
  END LOOP;
END $$;
