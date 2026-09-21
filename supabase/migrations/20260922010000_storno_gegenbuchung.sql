-- Gegenbuchung zur stornierten Doppelverrechnung.
--
-- Im Aufraeumlauf davor stand die Annahme, INV-18027322 sei nicht gebucht --
-- das Feld bookedInJournal der Zahlung stand auf false. Das Journal sagt
-- etwas anderes: am 13.06.2026 wurde 1100 an 3000 ueber CHF 120 gebucht
-- (isSystemEntry). Das Feld ist also nicht verlaesslich; das Journal ist es.
-- Ohne Gegenbuchung waeren Forderungen und Ertrag je 120 zu hoch.
--
-- Die Gegenbuchung steht bewusst nicht als Systembuchung da. Sie ist eine
-- Korrektur von Hand und soll in der Liste auch so aussehen.
DO $$
DECLARE
  v_zahlung text := 'liLfRRhDBDiJo6fSjsUb';
  v_n int; r record;
BEGIN
  IF EXISTS (SELECT 1 FROM public.accounting_journal
              WHERE "referenceId" = v_zahlung AND coalesce(description,'') ILIKE 'Storno%') THEN
    RAISE NOTICE 'Gegenbuchung besteht schon -- nichts zu tun.';
    RETURN;
  END IF;

  INSERT INTO public.accounting_journal
    (id, "tenantId", date, "debitCode", "creditCode", amount, description,
     "referenceId", "isSystemEntry", timestamp, "createdAt")
  VALUES
    (gen_random_uuid()::text, 'koretini', current_date, '3000', '1100', 120,
     'Storno Rechnung INV-18027322 -- Doppelverrechnung Valton Rexha, INV-18027321 desselben Jahres ist bezahlt',
     v_zahlung, false, now(), now());
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Gegenbuchung gesetzt: % (3000 an 1100, CHF 120)', v_n;

  UPDATE public.payments SET "bookedInJournal" = true WHERE id = v_zahlung;

  RAISE NOTICE '--- Alle Buchungen zu dieser Rechnung ---';
  FOR r IN SELECT date, "debitCode" AS s, "creditCode" AS h, amount, description
             FROM public.accounting_journal WHERE "referenceId" = v_zahlung ORDER BY date LOOP
    RAISE NOTICE '  % | % an % | % | %', r.date, r.s, r.h, r.amount, left(r.description,60);
  END LOOP;

  RAISE NOTICE '--- Saldo der betroffenen Konten ---';
  FOR r IN SELECT k.code,
             (SELECT coalesce(sum(amount),0) FROM public.accounting_journal
               WHERE "tenantId"='koretini' AND "debitCode"=k.code) AS soll,
             (SELECT coalesce(sum(amount),0) FROM public.accounting_journal
               WHERE "tenantId"='koretini' AND "creditCode"=k.code) AS haben
             FROM (VALUES ('1100'),('3000')) AS k(code) LOOP
    RAISE NOTICE '  Konto %: Soll % / Haben % / Saldo %',
      r.code, r.soll, r.haben, r.soll - r.haben;
  END LOOP;
END $$;
