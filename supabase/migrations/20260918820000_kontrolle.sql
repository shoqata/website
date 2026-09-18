DO $$
DECLARE v_n int; v_chf numeric;
BEGIN
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_chf FROM public.accounting_journal;
  RAISE NOTICE 'Journal: % Buchungen ueber % CHF', v_n, v_chf;
  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "debitCode" IS NULL OR "creditCode" IS NULL;
  RAISE NOTICE 'Punkt 6 -- ohne Kontonummer: % (war 4)', v_n;
  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  RAISE NOTICE 'Punkt 5 -- ohne Rechnung: % (war 14)', v_n;
  SELECT count(*) INTO v_n FROM public.settings
   WHERE payment ? 'paypalSecret' AND coalesce(payment ->> 'paypalSecret','') <> '';
  RAISE NOTICE 'Punkt 7 -- Zeilen mit PayPal-Geheimnis: % (war 2)', v_n;
  SELECT count(*) INTO v_n FROM public.settings WHERE id='global' AND payment ? 'iban';
  RAISE NOTICE 'Sicherung der Bankangaben in settings/global erhalten: %', v_n = 1;
END $$;
