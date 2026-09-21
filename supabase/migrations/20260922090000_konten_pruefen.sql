DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT code, name, class FROM public.accounting_accounts
            WHERE "tenantId"='koretini' AND code IN ('1020','1100','2000','3000','3200','2300')
            ORDER BY code LOOP
    RAISE NOTICE '  % | % | %', r.code, rpad(r.name,44), r.class;
  END LOOP;
  RAISE NOTICE '--- alle Passivkonten ---';
  FOR r IN SELECT code, name FROM public.accounting_accounts
            WHERE "tenantId"='koretini' AND class='PASSIVEN' ORDER BY code LOOP
    RAISE NOTICE '  % | %', r.code, r.name;
  END LOOP;
END $$;
