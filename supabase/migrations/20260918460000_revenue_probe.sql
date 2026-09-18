-- Was muesste in der Analyse fuer 2026 stehen?
--
-- Wenn die Zahl in der Datenbank stimmt, liegt es an der Darstellung. Wenn sie
-- schon hier null ist, an den Daten.
DO $$
DECLARE
  v_jahr int := 2026;
  v_typ text; v_n int; v_summe numeric; r record;
BEGIN
  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='payments' AND column_name='amount';
  RAISE NOTICE 'payments.amount ist vom Typ %', v_typ;

  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='payments' AND column_name='billingYear';
  RAISE NOTICE 'payments."billingYear" ist vom Typ %', v_typ;

  SELECT count(*), coalesce(sum(amount), 0) INTO v_n, v_summe
    FROM public.payments
   WHERE status = 'PAID' AND coalesce("billingYear"::int, EXTRACT(YEAR FROM "timestamp")::int) = v_jahr;
  RAISE NOTICE 'Bezahlt fuer %: % Rechnungen, % CHF -- das muesste unter "Einnahmen Total" stehen',
    v_jahr, v_n, v_summe;

  SELECT count(*) INTO v_n FROM public.payments
   WHERE status = 'PAID'
     AND coalesce("billingYear"::int, EXTRACT(YEAR FROM "timestamp")::int) = v_jahr
     AND "timestamp" IS NULL;
  RAISE NOTICE 'Davon ohne Zeitstempel: % -- diese fehlen im Verlaufsdiagramm', v_n;

  RAISE NOTICE '=== Bezahlt je Monat (Grundlage der Umsatzentwicklung) ===';
  FOR r IN
    SELECT to_char("timestamp", 'YYYY-MM') AS monat, count(*) AS n, sum(amount) AS chf
      FROM public.payments
     WHERE status = 'PAID'
       AND coalesce("billingYear"::int, EXTRACT(YEAR FROM "timestamp")::int) = v_jahr
       AND "timestamp" IS NOT NULL
     GROUP BY 1 ORDER BY 1
  LOOP
    RAISE NOTICE '  %: % Zahlungen, % CHF', r.monat, r.n, r.chf;
  END LOOP;

  -- Zuletzt gebuchte Zahlungen -- die, die der Vorstand gerade gesetzt hat.
  RAISE NOTICE '=== Zuletzt auf bezahlt gesetzt ===';
  FOR r IN SELECT "invoiceNumber", amount, "paidAt", "billingYear", "collectedBy"
             FROM public.payments WHERE status = 'PAID'
            ORDER BY "paidAt" DESC NULLS LAST LIMIT 5 LOOP
    RAISE NOTICE '  % | % | bezahlt am % | Jahr % | gebucht von %',
      r."invoiceNumber", r.amount, coalesce(r."paidAt",'-'), coalesce(r."billingYear"::text,'-'),
      coalesce(r."collectedBy",'-');
  END LOOP;
END $$;
