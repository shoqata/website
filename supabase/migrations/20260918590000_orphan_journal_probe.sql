-- Buchungen, die auf nichts verweisen.
--
-- Die Gegenprobe nach dem Bereinigen meldete 14 Journalbuchungen ohne
-- zugehoerige Zahlung. Ich habe genau vier entfernt, und die passten zu den
-- geloeschten Zahlungen -- die uebrigen bestanden also schon vorher. Eine
-- Forderung ohne Rechnung verfaelscht die Bilanz.
DO $$
DECLARE r record; v_n int; v_summe numeric;
BEGIN
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_summe
    FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  RAISE NOTICE 'Buchungen ohne zugehoerige Zahlung: % ueber % CHF', v_n, v_summe;

  RAISE NOTICE '=== Die betroffenen Buchungen ===';
  FOR r IN SELECT j.id, j.date, j.description, j."debitCode", j."creditCode",
                  j.amount, j."isSystemEntry", j."referenceId"
             FROM public.accounting_journal j
            WHERE j."referenceId" IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId")
            ORDER BY j.date, j.description LOOP
    RAISE NOTICE '  % | % | % -> % | % CHF | System % | Bezug %',
      r.date, left(coalesce(r.description,'-'), 34), r."debitCode", r."creditCode",
      r.amount, r."isSystemEntry", r."referenceId";
  END LOOP;

  RAISE NOTICE '=== Journal insgesamt ===';
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_summe FROM public.accounting_journal;
  RAISE NOTICE '  % Buchungen ueber % CHF', v_n, v_summe;

  RAISE NOTICE '=== Stimmt Soll gleich Haben je Konto? ===';
  FOR r IN
    SELECT konto,
           coalesce(sum(soll), 0) AS soll,
           coalesce(sum(haben), 0) AS haben
      FROM (
        SELECT "debitCode" AS konto, amount AS soll, 0 AS haben FROM public.accounting_journal
        UNION ALL
        SELECT "creditCode" AS konto, 0 AS soll, amount AS haben FROM public.accounting_journal
      ) x GROUP BY konto ORDER BY konto
  LOOP
    RAISE NOTICE '  Konto %: Soll % | Haben % | Saldo %',
      r.konto, r.soll, r.haben, r.soll - r.haben;
  END LOOP;
END $$;
