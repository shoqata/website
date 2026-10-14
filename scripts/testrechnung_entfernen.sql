-- Die Testrechnung samt allem, was daran haengt, wieder entfernen.
--
-- Angelegt zum Ausprobieren der Zahlungseingaenge: TEST-0001 ueber
-- CHF 40.00 auf Besart Selmani, Nachbarschaft Selmana-jt / Dervish-t.
--
-- Aufruf:
--   npx supabase db query --linked --file scripts/testrechnung_entfernen.sql
--
-- Die Reihenfolge ist nicht beliebig, und sie ist nicht die naheliegende.
--
-- Naheliegend waere: erst die Buchungen, dann die Rechnung. Genau das
-- schlaegt fehl, und zwar still erst beim Selbsttest. Denn an der
-- Rechnung und an den Eingaengen haengen Trigger, die BEIM LOESCHEN
-- weiterbuchen:
--
--   zahlungseingaenge_stand  →  zahlung_stand_pflegen
--        setzt bezahlt/Status der Rechnung zurueck
--   payments_book_entries    →  book_payment_entries
--        sieht eine Rechnung ohne Forderungsbuchung und legt sie neu an
--
-- Wer also zuerst das Journal raeumt, bekommt die Forderungsbuchung
-- zurueck, sobald er die Eingaenge entfernt. Darum: zuerst alles, was
-- Trigger ausloest, und erst danach das Journal.
--
-- Die Eingangs-Ids werden vorher eingesammelt: ihre Buchungen tragen die
-- Eingangs-Id als Referenz, und das Journal kennt keinen Fremdschluessel
-- darauf -- nach dem Loeschen waere der Bezug nicht mehr zu finden.

CREATE TEMP TABLE _weg(was text, anzahl int);

DO $$
DECLARE
  v_id text := 'TESTRECHNUNG-ZAHLUNGSEINGANG';
  v_eingaenge text[];
  v_n int;
BEGIN
  SELECT coalesce(array_agg(id::text), '{}') INTO v_eingaenge
    FROM public.zahlungseingaenge WHERE "paymentId" = v_id;

  -- 1. Was Trigger ausloest.
  DELETE FROM public.payment_reports WHERE "paymentId" = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Zahlungsmeldungen', v_n);

  DELETE FROM public.zahlungseingaenge WHERE "paymentId" = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Zahlungseingaenge', v_n);

  DELETE FROM public.payments WHERE id = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('die Rechnung selbst', v_n);

  -- 2. Erst jetzt das Journal. Jetzt kann niemand mehr nachbuchen.
  DELETE FROM public.accounting_journal
   WHERE "referenceId" = ANY (v_eingaenge);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Buchungen der Zahlungseingaenge', v_n);

  DELETE FROM public.accounting_journal WHERE "referenceId" = v_id || ':differenz';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Buchung der Differenzentscheidung', v_n);

  DELETE FROM public.accounting_journal WHERE "referenceId" = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Forderungs- und Eingangsbuchung der Rechnung', v_n);

  -- Nachweis statt Zuversicht. Dieser Test hat die falsche Reihenfolge
  -- gefunden; er bleibt stehen.
  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "referenceId" = v_id OR "referenceId" = v_id || ':differenz'
      OR "referenceId" = ANY (v_eingaenge);
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Journalzeile(n) der Testrechnung blieben stehen.', v_n;
  END IF;
  INSERT INTO _weg VALUES ('Rueckstand im Journal', 0);

  -- Und die Rechnung ist wirklich weg, nicht nur unsichtbar.
  IF EXISTS (SELECT 1 FROM public.payments WHERE id = v_id) THEN
    RAISE EXCEPTION 'Die Testrechnung steht noch.';
  END IF;
END $$;

SELECT was, anzahl FROM _weg;
