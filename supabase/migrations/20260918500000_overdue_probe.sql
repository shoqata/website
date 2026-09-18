-- Was heisst "ueberfaellig"?
--
-- Das Mahnwesen zeigt ueberfaellige Rechnungen, das Armaturenbrett null. Der
-- Verdacht: die eine Stelle rechnet das Faelligkeitsdatum aus, die andere
-- verlaesst sich auf den Status. Steht der Status bei keiner Rechnung auf
-- OVERDUE, zeigt die zweite Stelle dauerhaft nichts.
DO $$
DECLARE v_status int; v_datum int; v_beides int; v_ohne_faellig int; r record;
BEGIN
  SELECT count(*) INTO v_status FROM public.payments WHERE status = 'OVERDUE';
  RAISE NOTICE 'Rechnungen mit Status OVERDUE: %', v_status;

  SELECT count(*) INTO v_datum FROM public.payments
   WHERE status = 'PENDING' AND "dueDate" IS NOT NULL
     AND btrim("dueDate") <> '' AND "dueDate"::date < current_date;
  RAISE NOTICE 'Offen und Faelligkeit ueberschritten: %', v_datum;

  SELECT count(*) INTO v_ohne_faellig FROM public.payments
   WHERE status = 'PENDING' AND ("dueDate" IS NULL OR btrim("dueDate") = '');
  RAISE NOTICE 'Offen ohne Faelligkeitsdatum: % -- diese gelten nirgends als ueberfaellig', v_ohne_faellig;

  SELECT count(*) INTO v_beides FROM public.payments WHERE status = 'PENDING';
  RAISE NOTICE 'Offen insgesamt: %', v_beides;

  RAISE NOTICE '=== Verteilung der Faelligkeiten ===';
  FOR r IN SELECT coalesce(substr("dueDate", 1, 7), '<keines>') AS monat,
                  count(*) AS n, count(*) FILTER (WHERE status='PENDING') AS offen
             FROM public.payments GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  faellig %: % Rechnungen, davon % offen', r.monat, r.n, r.offen;
  END LOOP;

  RAISE NOTICE '=== Status insgesamt ===';
  FOR r IN SELECT status, count(*) AS n, sum(amount) AS chf
             FROM public.payments GROUP BY status ORDER BY status LOOP
    RAISE NOTICE '  %: % Rechnungen, % CHF', coalesce(r.status,'<null>'), r.n, r.chf;
  END LOOP;
END $$;
