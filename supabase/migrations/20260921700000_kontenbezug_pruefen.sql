-- Passen alle Buchungen zum Kontenplan ihres eigenen Vereins?
-- Vor einer Umstellung auf einen vereinsbezogenen Fremdschluessel muss das
-- stimmen, sonst scheitert sie mitten im Bestand.
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE j."debitCode" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=j."tenantId" AND a.code=j."debitCode");
  RAISE NOTICE 'Buchungen, deren Sollkonto nicht zum eigenen Verein gehoert:  %', v_n;

  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE j."creditCode" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=j."tenantId" AND a.code=j."creditCode");
  RAISE NOTICE 'Buchungen, deren Habenkonto nicht zum eigenen Verein gehoert: %', v_n;

  SELECT count(*) INTO v_n FROM public.expenses e
   WHERE e."categoryAccountCode" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=e."tenantId" AND a.code=e."categoryAccountCode");
  RAISE NOTICE 'Ausgaben mit fremdem Aufwandkonto:  %', v_n;

  SELECT count(*) INTO v_n FROM public.expenses e
   WHERE e."paymentAccountCode" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=e."tenantId" AND a.code=e."paymentAccountCode");
  RAISE NOTICE 'Ausgaben mit fremdem Zahlkonto:     %', v_n;

  SELECT count(*) INTO v_n FROM public.accounting_journal WHERE "tenantId" IS NULL;
  RAISE NOTICE 'Buchungen ohne Vereinszuordnung:    %', v_n;
  SELECT count(*) INTO v_n FROM public.expenses WHERE "tenantId" IS NULL;
  RAISE NOTICE 'Ausgaben ohne Vereinszuordnung:     %', v_n;
END $$;
