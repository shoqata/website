-- Erst sehen, dann entscheiden. Nichts wird hier geaendert.
DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '--- Buchungen, deren Rechnung es nicht mehr gibt ---';
  FOR r IN
    SELECT j.id, j.date, j.description, j.amount, j."debitCode", j."creditCode",
           j.debit, j.credit, j."isSystemEntry"
      FROM public.accounting_journal j
     WHERE j."referenceId" IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId")
     ORDER BY j.date, j.id
  LOOP
    RAISE NOTICE '  % | %CHF | S%/H% | % | % -> %',
      r.date, lpad(r.amount::text, 8), coalesce(r."debitCode",'----'),
      coalesce(r."creditCode",'----'), rpad(left(coalesce(r.description,''), 34), 34),
      left(coalesce(r.debit,''), 14), left(coalesce(r.credit,''), 14);
  END LOOP;

  RAISE NOTICE '--- Buchungen ohne Kontonummer ---';
  FOR r IN
    SELECT id, date, description, amount, "debitCode", "creditCode", debit, credit, "referenceId"
      FROM public.accounting_journal
     WHERE "debitCode" IS NULL OR "creditCode" IS NULL ORDER BY date
  LOOP
    RAISE NOTICE '  % | %CHF | S%/H% | % | % -> % | Bezug %',
      r.date, lpad(r.amount::text, 8), coalesce(r."debitCode",'----'),
      coalesce(r."creditCode",'----'), rpad(left(coalesce(r.description,''), 30), 30),
      left(coalesce(r.debit,''), 12), left(coalesce(r.credit,''), 12),
      CASE WHEN r."referenceId" IS NULL THEN 'keiner' ELSE left(r."referenceId", 10) END;
  END LOOP;

  RAISE NOTICE '--- Womit buchen vergleichbare Vorgaenge? ---';
  FOR r IN
    SELECT "debitCode", "creditCode", debit, credit, count(*) AS n, sum(amount) AS chf
      FROM public.accounting_journal
     WHERE "debitCode" IS NOT NULL AND "creditCode" IS NOT NULL
     GROUP BY 1,2,3,4 ORDER BY n DESC LIMIT 10
  LOOP
    RAISE NOTICE '  S%/H% | % -> % | %x | % CHF',
      r."debitCode", r."creditCode", rpad(left(coalesce(r.debit,''),16),16),
      rpad(left(coalesce(r.credit,''),16),16), r.n, r.chf;
  END LOOP;

  RAISE NOTICE '--- PayPal: welche Zeilen tragen Zugangsdaten? (ohne Werte) ---';
  FOR r IN SELECT id, (payment ? 'paypalSecret') AS geheim,
                  (payment ? 'paypalClientId') AS kennung,
                  (data ? 'paypalSecret') AS geheim_in_data
             FROM public.settings ORDER BY id
  LOOP
    RAISE NOTICE '  settings/% | payment.Geheimnis % | payment.Kennung % | data.Geheimnis %',
      rpad(r.id, 9), r.geheim, r.kennung, r.geheim_in_data;
  END LOOP;
END $$;
