DO $$
DECLARE r record; v_n int; v_doppelt int;
BEGIN
  SELECT count(*) INTO v_n FROM public.payments WHERE coalesce(btrim("invoiceNumber"),'')<>'';
  RAISE NOTICE 'Mit Rechnungsnummer: % von %', v_n, (SELECT count(*) FROM public.payments);
  SELECT count(*) INTO v_doppelt FROM (
    SELECT "invoiceNumber" FROM public.payments WHERE coalesce(btrim("invoiceNumber"),'')<>''
     GROUP BY 1 HAVING count(*)>1) x;
  RAISE NOTICE 'Doppelte Rechnungsnummern: %', v_doppelt;
  FOR r IN SELECT "invoiceNumber", status, amount FROM public.payments
            WHERE coalesce(btrim("invoiceNumber"),'')<>'' ORDER BY "invoiceNumber" LIMIT 4 LOOP
    RAISE NOTICE '  % | % | %', rpad(r."invoiceNumber",18), rpad(r.status,8), r.amount;
  END LOOP;
  SELECT count(*) INTO v_n FROM public.payments WHERE coalesce(btrim("invoiceNumber"),'')='';
  RAISE NOTICE 'Ohne Rechnungsnummer: %', v_n;
END $$;
