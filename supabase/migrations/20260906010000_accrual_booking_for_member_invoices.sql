-- Mitgliederrechnungen nach dem Soll-Prinzip verbuchen.
--
-- Bisher entstand ein Journaleintrag erst bei Zahlungseingang, und auch das nur,
-- wenn jemand in AdminAccounting den Knopf "Zahlungen verbuchen" drueckte. Das
-- ist nie passiert: alle 335 Zahlungen standen auf bookedInJournal = false.
-- Die vier vorhandenen Journalzeilen tragen weder debitCode noch creditCode und
-- fliessen deshalb in keine Saldenrechnung ein -- Bilanz und Erfolgsrechnung
-- waren schlicht leer.
--
-- Neu:
--   Rechnungsstellung  SOLL 1100 Forderungen  / HABEN 3000 Mitgliederbeitraege
--   Zahlungseingang    SOLL Bank bzw. Kasse   / HABEN 1100 Forderungen
--
-- Die Buchung haengt am Datensatz, nicht am Formular: es gibt drei Stellen im
-- Code, die Rechnungen anlegen, und ein Trigger erwischt alle drei -- auch
-- kuenftige.

-- Geldkonto nach Zahlungsart, wie es die bisherige Sync-Logik vorsah.
CREATE OR REPLACE FUNCTION public.payment_asset_code(p_method text, p_currency text)
RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_method = 'CASH'   THEN CASE WHEN p_currency = 'EUR' THEN '1001' ELSE '1000' END
    WHEN p_method = 'PAYPAL' THEN '1021'
    ELSE '1020'
  END
$$;

CREATE OR REPLACE FUNCTION public.book_payment_entries()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_label text;
  v_date  text;
BEGIN
  v_label := COALESCE(NULLIF(NEW."invoiceNumber", ''), NEW.id);

  -- 1. Forderung bei Rechnungsstellung. Einmal pro Zahlung, erkennbar am
  --    Gegenkonto 3000 zur selben referenceId.
  IF NOT EXISTS (
    SELECT 1 FROM public.accounting_journal
     WHERE "referenceId" = NEW.id AND "creditCode" = '3000'
  ) THEN
    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD'),
      'Rechnung ' || v_label,
      '1100', '3000', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );
  END IF;

  -- 2. Zahlungseingang gleicht die Forderung aus.
  IF NEW.status = 'PAID' AND NOT EXISTS (
    SELECT 1 FROM public.accounting_journal
     WHERE "referenceId" = NEW.id AND "creditCode" = '1100'
  ) THEN
    v_date := COALESCE(
      NULLIF(left(NEW."paidAt", 10), ''),
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD')
    );

    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      v_date,
      'Zahlungseingang ' || v_label,
      public.payment_asset_code(NEW.method, NEW.currency), '1100', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );

    IF NEW."bookedInJournal" IS DISTINCT FROM true THEN
      UPDATE public.payments SET "bookedInJournal" = true WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS payments_book_entries ON public.payments;
CREATE TRIGGER payments_book_entries
AFTER INSERT OR UPDATE OF status, amount ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.book_payment_entries();

-- Bestand nachbuchen: 335 Forderungen, davon 50 bereits ausgeglichen.
-- Laeuft ueber denselben Trigger, damit Nachbuchung und Laufbetrieb nicht
-- auseinanderdriften koennen.
UPDATE public.payments SET amount = amount;
