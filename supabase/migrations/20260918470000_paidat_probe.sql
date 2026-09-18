-- Verteilt sich paidAt ueber das Jahr?
--
-- timestamp ist der Zeitpunkt, zu dem der Datensatz entstand -- bei allen 80
-- bezahlten Rechnungen ist das derselbe Monat, weil sie aus einem Import
-- stammen. Eine Umsatzentwicklung daraus ist ein einziger Punkt und damit
-- keine Linie. paidAt dagegen sagt, wann das Geld tatsaechlich einging.
DO $$
DECLARE r record; v_ohne int;
BEGIN
  SELECT count(*) INTO v_ohne FROM public.payments
   WHERE status = 'PAID' AND ("paidAt" IS NULL OR btrim("paidAt") = '');
  RAISE NOTICE 'Davon ohne Zahlungsdatum: % -- fuer diese bleibt der Zeitstempel der Rueckfall', v_ohne;

  RAISE NOTICE '=== Nach Zeitstempel (Entstehung des Datensatzes) ===';
  FOR r IN SELECT to_char("timestamp", 'YYYY-MM') AS monat, count(*) AS n, sum(amount) AS chf
             FROM public.payments WHERE status='PAID' GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  %: % Zahlungen, % CHF', r.monat, r.n, r.chf;
  END LOOP;

  RAISE NOTICE '=== Nach Zahlungsdatum (tatsaechlicher Eingang) ===';
  FOR r IN SELECT substr("paidAt", 1, 7) AS monat, count(*) AS n, sum(amount) AS chf
             FROM public.payments
            WHERE status='PAID' AND "paidAt" IS NOT NULL AND btrim("paidAt") <> ''
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  %: % Zahlungen, % CHF', r.monat, r.n, r.chf;
  END LOOP;
END $$;
