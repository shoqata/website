-- Drei offene Punkte aus der Buchhaltung und den Einstellungen.
--
-- Reihenfolge mit Absicht: erst das Reparieren (Punkt 6), dann das Entfernen
-- (Punkt 5). Wer zuerst loescht, kann nicht mehr nachsehen, was drinstand.

-- --- Sicherung ------------------------------------------------------------
-- Entfernte Buchungen werden nicht vernichtet, sondern hierher gelegt. Ein
-- Verein muss nachweisen koennen, was mit einer Buchung geschehen ist, auch
-- wenn sie eine Bereinigung war.
CREATE TABLE IF NOT EXISTS public.accounting_journal_archiv (
  id            text PRIMARY KEY,
  "tenantId"    text,
  zeile         jsonb NOT NULL,
  entfernt_am   timestamptz NOT NULL DEFAULT now(),
  grund         text NOT NULL
);
ALTER TABLE public.accounting_journal_archiv ENABLE ROW LEVEL SECURITY;
-- Keine Regel heisst: ueber die Programmschnittstelle kommt niemand heran.
-- Absichtlich -- das Archiv ist fuer die Revision, nicht fuer die Anwendung.
REVOKE ALL ON public.accounting_journal_archiv FROM anon, authenticated;

DO $$
DECLARE v_vorher_n int; v_vorher_chf numeric; v_n int; v_chf numeric; r record;
BEGIN
  SELECT count(*), coalesce(sum(amount),0) INTO v_vorher_n, v_vorher_chf
    FROM public.accounting_journal;
  RAISE NOTICE 'Vorher: % Buchungen ueber % CHF', v_vorher_n, v_vorher_chf;

  -- --- Punkt 6: Kontonummern stehen in den falschen Spalten ---------------
  -- debit/credit tragen bei diesen vier die Kontonummer, debitCode/creditCode
  -- sind leer. Bei allen uebrigen ist es umgekehrt. Es fehlt also nichts, es
  -- steht nur woanders -- deshalb wird umkopiert und nichts erfunden.
  -- Kopiert wird ausschliesslich, was wie eine Kontonummer aussieht und im
  -- Kontenplan auch vorkommt.
  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE (j."debitCode" IS NULL AND j.debit ~ '^[0-9]{4}$')
      OR (j."creditCode" IS NULL AND j.credit ~ '^[0-9]{4}$');
  RAISE NOTICE 'Punkt 6: % Buchungen mit Kontonummer in der falschen Spalte', v_n;

  FOR r IN SELECT DISTINCT k FROM (
             SELECT debit AS k FROM public.accounting_journal
              WHERE "debitCode" IS NULL AND debit ~ '^[0-9]{4}$'
             UNION SELECT credit FROM public.accounting_journal
              WHERE "creditCode" IS NULL AND credit ~ '^[0-9]{4}$') x
  LOOP
    IF EXISTS (SELECT 1 FROM public.accounting_accounts a WHERE a.code = r.k) THEN
      RAISE NOTICE '   Konto % steht im Kontenplan', r.k;
    ELSE
      RAISE NOTICE '   Konto % steht NICHT im Kontenplan -- wird nicht gesetzt', r.k;
    END IF;
  END LOOP;

  UPDATE public.accounting_journal j
     SET "debitCode" = j.debit
   WHERE j."debitCode" IS NULL AND j.debit ~ '^[0-9]{4}$'
     AND EXISTS (SELECT 1 FROM public.accounting_accounts a WHERE a.code = j.debit);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Punkt 6: % Sollkonten gesetzt', v_n;

  UPDATE public.accounting_journal j
     SET "creditCode" = j.credit
   WHERE j."creditCode" IS NULL AND j.credit ~ '^[0-9]{4}$'
     AND EXISTS (SELECT 1 FROM public.accounting_accounts a WHERE a.code = j.credit);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Punkt 6: % Habenkonten gesetzt', v_n;

  -- --- Punkt 5: Buchungen ohne zugehoerige Rechnung ----------------------
  -- Sie verweisen auf Rechnungen, die es nicht mehr gibt -- Rueckstand der
  -- Bereinigung doppelter Mitglieder. Belegen laesst sich keine von ihnen,
  -- und solange sie stehen, weisen Forderungen und Ertrag zu viel aus.
  INSERT INTO public.accounting_journal_archiv (id, "tenantId", zeile, grund)
  SELECT j.id, j."tenantId", to_jsonb(j),
         'Verweist auf eine Rechnung, die es nicht mehr gibt (Bereinigung 18.09.2026)'
    FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId")
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Punkt 5: % Buchungen ins Archiv gelegt', v_n;

  DELETE FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  GET DIAGNOSTICS v_n = ROW_COUNT;
  SELECT coalesce(sum((zeile->>'amount')::numeric),0) INTO v_chf
    FROM public.accounting_journal_archiv;
  RAISE NOTICE 'Punkt 5: % Buchungen entfernt, % CHF im Archiv', v_n, v_chf;

  -- --- Punkt 7: doppelte PayPal-Zugangsdaten ------------------------------
  -- Gelesen wird ausschliesslich settings/payment. settings/global war als
  -- Sicherung der Bankangaben gedacht; die Zugangsdaten gehoeren dort nicht
  -- hin und liegen doppelt. Die Bankangaben bleiben stehen.
  UPDATE public.settings
     SET payment = payment - 'paypalSecret' - 'paypalClientId'
   WHERE id = 'global' AND payment ?| array['paypalSecret','paypalClientId'];
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Punkt 7: % Zeile bereinigt', v_n;

  -- --- Nachher ------------------------------------------------------------
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_chf FROM public.accounting_journal;
  RAISE NOTICE 'Nachher: % Buchungen ueber % CHF (% weniger, % CHF weniger)',
    v_n, v_chf, v_vorher_n - v_n, v_vorher_chf - v_chf;

  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "debitCode" IS NULL OR "creditCode" IS NULL;
  RAISE NOTICE 'Kontrolle: % Buchungen noch ohne Kontonummer', v_n;

  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  RAISE NOTICE 'Kontrolle: % Buchungen noch ohne Rechnung', v_n;

  SELECT count(*) INTO v_n FROM public.settings
   WHERE payment ? 'paypalSecret' AND coalesce(payment ->> 'paypalSecret','') <> '';
  RAISE NOTICE 'Kontrolle: % Zeile mit PayPal-Geheimnis (soll 1 sein)', v_n;
END $$;
