DO $$
DECLARE r record; v_n int; v_mit int;
BEGIN
  SELECT count(*) INTO v_n FROM public.payments;
  SELECT count(*) INTO v_mit FROM public.payments WHERE coalesce(btrim(reference),'') <> '';
  RAISE NOTICE 'Rechnungen: % insgesamt, % mit Referenznummer', v_n, v_mit;
  FOR r IN SELECT reference, "invoiceNumber", amount FROM public.payments
            WHERE coalesce(btrim(reference),'') <> '' LIMIT 3 LOOP
    RAISE NOTICE '  % | % | % Stellen', r."invoiceNumber", r.reference, length(r.reference);
  END LOOP;
  FOR r IN SELECT payment ->> 'qrIban' AS qr, payment ->> 'iban' AS normal FROM public.settings WHERE id='payment' LOOP
    RAISE NOTICE 'Hinterlegt: qrIban=% iban=%', r.qr, r.normal;
  END LOOP;
END $$;
