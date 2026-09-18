-- Die verwaisten Journalbuchungen im Einzelnen, zur Entscheidung.
--
-- Jede verweist auf eine Zahlung, die es nicht mehr gibt. Dadurch stehen im
-- Journal Forderungen zu Rechnungen, die geloescht wurden -- Ertrag und
-- Forderungen sind entsprechend zu hoch.
DO $$
DECLARE r record; v_forderung numeric := 0; v_eingang numeric := 0; v_n int;
BEGIN
  RAISE NOTICE 'Datum      | Rechnung           | Buchung      | Soll->Haben | CHF';
  RAISE NOTICE '-----------+--------------------+--------------+-------------+------';
  FOR r IN
    SELECT j.date, j.description, j."debitCode", j."creditCode", j.amount,
           CASE WHEN j.description LIKE 'Zahlungseingang%' THEN 'Eingang' ELSE 'Forderung' END AS art
      FROM public.accounting_journal j
     WHERE j."referenceId" IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId")
     ORDER BY j.date, j.description
  LOOP
    RAISE NOTICE '% | % | % | % -> %  | %',
      r.date,
      rpad(coalesce(regexp_replace(r.description, '^(Rechnung|Zahlungseingang) ', ''), '-'), 18),
      rpad(r.art, 12), r."debitCode", r."creditCode", r.amount;
    IF r.art = 'Eingang' THEN v_eingang := v_eingang + r.amount;
    ELSE v_forderung := v_forderung + r.amount; END IF;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE 'Forderungen ohne Rechnung: % CHF -- Ertrag und Forderungen zu hoch', v_forderung;
  RAISE NOTICE 'Zahlungseingaenge ohne Rechnung: % CHF', v_eingang;

  -- Gibt es die Rechnungsnummern noch unter einer anderen Zahlung? Dann waere
  -- es ein verwaister Bezug und keine geloeschte Rechnung.
  RAISE NOTICE '';
  RAISE NOTICE '=== Existieren diese Rechnungsnummern noch? ===';
  v_n := 0;
  FOR r IN
    SELECT DISTINCT regexp_replace(j.description, '^(Rechnung|Zahlungseingang) ', '') AS nummer
      FROM public.accounting_journal j
     WHERE j."referenceId" IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId")
  LOOP
    IF EXISTS (SELECT 1 FROM public.payments p WHERE p."invoiceNumber" = r.nummer) THEN
      RAISE NOTICE '  % -- gibt es noch, nur unter anderer Kennung', r.nummer;
      v_n := v_n + 1;
    END IF;
  END LOOP;
  IF v_n = 0 THEN
    RAISE NOTICE '  keine -- alle zugehoerigen Rechnungen sind tatsaechlich fort';
  END IF;

  -- Und die Buchungen ohne Kontonummer.
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_forderung
    FROM public.accounting_journal
   WHERE "debitCode" IS NULL OR "creditCode" IS NULL;
  RAISE NOTICE '';
  RAISE NOTICE 'Buchungen ohne Kontonummer: % ueber % CHF', v_n, v_forderung;
  FOR r IN SELECT date, description, coalesce("debitCode",'<leer>') AS soll,
                  coalesce("creditCode",'<leer>') AS haben, amount
             FROM public.accounting_journal
            WHERE "debitCode" IS NULL OR "creditCode" IS NULL
            ORDER BY date LIMIT 12 LOOP
    RAISE NOTICE '  % | % | % -> % | %', r.date, left(coalesce(r.description,'-'),30), r.soll, r.haben, r.amount;
  END LOOP;
END $$;
