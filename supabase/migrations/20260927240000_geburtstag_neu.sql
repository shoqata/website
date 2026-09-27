-- Der Geburtstagsgruss ist heute frueh fuenfmal an einer Verbindung
-- gescheitert -- das Bild eines gesperrten Ports 25. Seit heute steht der
-- Postausgang auf 587; damit ist ein neuer Versuch fuellig, und zwar heute,
-- weil ein Geburtstagsgruss morgen wertlos ist.
DO $$
DECLARE v_n int; r record;
BEGIN
  UPDATE public.mail_queue
     SET status = 'PENDING', attempts = 0,
         "lastError" = coalesce("lastError",'') || ' | neu angesetzt nach Wechsel auf Port 587'
   WHERE status = 'FAILED' AND "lastError" ILIKE '%onnection%';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Neu angesetzt: %', v_n;

  FOR r IN SELECT status, count(*) AS n FROM public.mail_queue GROUP BY 1 LOOP
    RAISE NOTICE '  % -> %', rpad(r.status,10), r.n;
  END LOOP;
END $$;
