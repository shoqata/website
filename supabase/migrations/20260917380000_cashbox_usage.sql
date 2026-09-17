DO $$
DECLARE v_e int; v_t int; v_c int; r record;
BEGIN
  SELECT count(*) INTO v_e FROM public.expenses;
  SELECT count(*) INTO v_t FROM public.tasks;
  RAISE NOTICE 'Ausgaben: %, Aufgaben: %', v_e, v_t;

  SELECT count(*) INTO v_c FROM public.payments WHERE "collectedBy" IS NOT NULL;
  RAISE NOTICE 'Zahlungen mit Einzug durch eine Person (collectedBy): %', v_c;
  FOR r IN SELECT "collectedBy", count(*) AS n FROM public.payments
            WHERE "collectedBy" IS NOT NULL GROUP BY 1 LOOP
    RAISE NOTICE '  eingezogen von %: %', r."collectedBy", r.n;
  END LOOP;

  RAISE NOTICE '=== Zahlungen je Nachbarschaft gesetzt? ===';
  SELECT count(*) INTO v_c FROM public.payments WHERE "neighborhoodId" IS NOT NULL;
  RAISE NOTICE '  mit neighborhoodId: % von 324', v_c;

  RAISE NOTICE '=== Methode der Zahlungen ===';
  FOR r IN SELECT coalesce(method,'<null>') AS m, count(*) AS n FROM public.payments GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  %: %', r.m, r.n;
  END LOOP;
END $$;
