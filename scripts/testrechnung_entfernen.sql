-- Die Testrechnung samt allem, was daran haengt, wieder entfernen.
--
-- Angelegt zum Ausprobieren der Zahlungseingaenge: TEST-0001 ueber
-- CHF 40.00 auf Besart Selmani, Nachbarschaft Selmana-jt / Dervish-t.
--
-- Aufruf:
--   npx supabase db query --linked --file scripts/testrechnung_entfernen.sql
--
-- Vier Dinge haengen daran, und sie muessen in dieser Reihenfolge weg,
-- weil jedes auf das vorige zeigt:
--
--   die Buchungen der Zahlungseingaenge   (referenceId = Eingangs-Id)
--   die Buchung der Differenzentscheidung (referenceId = ...:differenz)
--   die Forderungsbuchung                 (referenceId = Rechnungs-Id)
--   die Meldungen und die Rechnung selbst
--
-- Die Eingaenge selbst verschwinden mit der Rechnung (ON DELETE
-- CASCADE); ihre Buchungen aber NICHT -- das Journal kennt keinen
-- Fremdschluessel auf die Eingaenge. Wer nur die Rechnung loescht, laesst
-- Buchungen ohne Bezug stehen, und die fallen erst beim Jahresabschluss
-- auf. Darum werden sie hier zuerst eingesammelt.

CREATE TEMP TABLE _weg(was text, anzahl int);

DO $$
DECLARE
  v_id text := 'TESTRECHNUNG-ZAHLUNGSEINGANG';
  v_eingaenge text[];
  v_n int;
BEGIN
  SELECT coalesce(array_agg(id::text), '{}') INTO v_eingaenge
    FROM public.zahlungseingaenge WHERE "paymentId" = v_id;

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

  DELETE FROM public.payment_reports WHERE "paymentId" = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Zahlungsmeldungen', v_n);

  DELETE FROM public.zahlungseingaenge WHERE "paymentId" = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('Zahlungseingaenge', v_n);

  DELETE FROM public.payments WHERE id = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO _weg VALUES ('die Rechnung selbst', v_n);

  -- Nachweis statt Zuversicht: bleibt irgendwo etwas stehen, soll das
  -- hier auffallen und nicht beim Abschluss.
  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "referenceId" = v_id OR "referenceId" = v_id || ':differenz'
      OR "referenceId" = ANY (v_eingaenge);
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Journalzeile(n) der Testrechnung blieben stehen.', v_n;
  END IF;
  INSERT INTO _weg VALUES ('Rueckstand im Journal', 0);
END $$;

SELECT was, anzahl FROM _weg;
