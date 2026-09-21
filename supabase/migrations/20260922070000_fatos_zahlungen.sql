DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p."invoiceNumber", p.amount, p.method, p.status, p."paidAt",
                  coalesce(p."collectedBy",'-') AS kassiert, u.email,
                  (SELECT string_agg(j.date||' '||j."debitCode"||'/'||j."creditCode"||' '||j.amount, '  |  ' ORDER BY j.date)
                     FROM public.accounting_journal j WHERE j."referenceId"=p.id) AS buchungen
             FROM public.payments p JOIN public.users u ON u.id=p."userId"
            WHERE u."tenantId"='koretini' AND lower(u."lastName")='selmani' AND lower(u."firstName")='fatos'
            ORDER BY p."invoiceNumber" LOOP
    RAISE NOTICE '  % | CHF % | % | % | bezahlt % | kassiert von %',
      r."invoiceNumber", r.amount, rpad(coalesce(r.method,'-'),10), rpad(r.status,6), coalesce(r."paidAt",'-'), r.kassiert;
    RAISE NOTICE '      % ', r.email;
    RAISE NOTICE '      %', r.buchungen;
  END LOOP;
END $$;
