DO $$
DECLARE r record; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.accounting_accounts
   WHERE "tenantId"='koretini' AND code='3400';
  RAISE NOTICE 'Konto 3400 noch vorhanden: %', v_n;

  -- Diesmal die richtige Spalte: die Fremdschluessel sind zusammengesetzt
  -- (tenantId, code), und beim ersten Anlauf habe ich tenantId abgefragt.
  FOR r IN SELECT 'accounting_journal.debitCode' AS wo, count(*) AS n
             FROM public.accounting_journal WHERE "debitCode"='3400'
           UNION ALL SELECT 'accounting_journal.creditCode', count(*)
             FROM public.accounting_journal WHERE "creditCode"='3400'
           UNION ALL SELECT 'expenses (Kontospalte)', count(*)
             FROM public.expenses e
            WHERE to_jsonb(e)::text LIKE '%"3400"%' LOOP
    RAISE NOTICE '  % -> %', rpad(r.wo,32), r.n;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=j."tenantId" AND a.code=j."debitCode")
      OR NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId"=j."tenantId" AND a.code=j."creditCode");
  RAISE NOTICE 'Buchungen ohne gueltiges Konto: % (erwartet 0)', v_n;
END $$;
