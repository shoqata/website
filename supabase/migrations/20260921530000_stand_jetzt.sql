DO $$
BEGIN
  RAISE NOTICE 'Rechnungen mit Referenz jetzt: % von %',
    (SELECT count(*) FROM public.payments WHERE coalesce(btrim(reference),'')<>''),
    (SELECT count(*) FROM public.payments);
END $$;
