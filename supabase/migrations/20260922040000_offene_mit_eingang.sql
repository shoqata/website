DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.id, p."invoiceNumber", p.amount, p.status, p."billingYear",
                  coalesce(u."displayName",u.email) AS wer, coalesce(u."membershipStatus",'') AS st
             FROM public.payments p LEFT JOIN public.users u ON u.id=p."userId"
            WHERE p."tenantId"='koretini' AND p.status='PENDING'
              AND EXISTS (SELECT 1 FROM public.accounting_journal j
                           WHERE j."referenceId"=p.id AND j."creditCode"='1100') LOOP
    RAISE NOTICE '  % | % | % | % | % [%]',
      left(r.id,12), r."invoiceNumber", r.amount, r."billingYear", r.wer, r.st;
    FOR r IN SELECT date, "debitCode" AS s, "creditCode" AS h, amount, left(description,60) AS d
               FROM public.accounting_journal WHERE "referenceId" = r.id ORDER BY date LOOP
      RAISE NOTICE '      % | % an % | % | %', r.date, r.s, r.h, r.amount, r.d;
    END LOOP;
  END LOOP;
END $$;
