-- Referenznummern fuer Mitgliederrechnungen.
--
-- Gemessen: 0 von 322 Rechnungen tragen eine. Sie wurde beim Anzeigen im
-- Browser erzeugt, nie gespeichert -- und weil die IBAN keine QR-IBAN ist,
-- vom Beleg verworfen. Jede eingehende Zahlung musste von Hand zugeordnet
-- werden.
--
-- Die Referenz wird aus der Rechnungsnummer abgeleitet: so laesst sie sich
-- zurueckverfolgen, und sie ist fuer dieselbe Rechnung immer dieselbe. Eine
-- laufende Nummer waere bei einem zweiten Durchlauf eine andere -- und eine
-- Referenz, die sich aendert, nachdem der Beleg verschickt wurde, ist
-- schlimmer als keine.
CREATE OR REPLACE FUNCTION public.referenz_fuer_rechnung(
  p_rechnungsnummer text, p_verein text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_art text; v_kern text; v_ref text;
BEGIN
  IF coalesce(btrim(p_rechnungsnummer),'') = '' THEN RETURN NULL; END IF;
  -- Nur Ziffern aus der Rechnungsnummer; "INV-180210" wird zu "180210".
  v_kern := regexp_replace(p_rechnungsnummer, '\D', '', 'g');
  IF v_kern = '' THEN RETURN NULL; END IF;

  v_art := public.referenzart(p_verein);
  IF v_art = 'QRR' THEN
    v_ref := lpad(v_kern, 26, '0');
    RETURN v_ref || public.mod10_pruefziffer(v_ref);
  ELSE
    -- Creditor Reference nach ISO 11649. MB fuer Mitgliederbeitrag, damit
    -- sich eine Rechnung im Kontoauszug von einer Spende (SP) unterscheidet.
    RETURN public.scor_referenz('MB' || lpad(v_kern, 12, '0'));
  END IF;
END $$;

-- Damit die naechste Rechnung nicht wieder ohne dasteht.
CREATE OR REPLACE FUNCTION public.rechnung_referenz_setzen()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF coalesce(btrim(NEW.reference),'') = '' THEN
    NEW.reference := public.referenz_fuer_rechnung(NEW."invoiceNumber", NEW."tenantId");
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS payments_referenz_trg ON public.payments;
CREATE TRIGGER payments_referenz_trg
  BEFORE INSERT ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.rechnung_referenz_setzen();

REVOKE ALL ON FUNCTION public.referenz_fuer_rechnung(text,text) FROM public;
GRANT EXECUTE ON FUNCTION public.referenz_fuer_rechnung(text,text) TO authenticated;

-- Probe an drei echten Rechnungsnummern, ohne etwas zu aendern.
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT "invoiceNumber", "tenantId", status FROM public.payments
            ORDER BY "invoiceNumber" LIMIT 3 LOOP
    RAISE NOTICE '  % (%) -> %', rpad(r."invoiceNumber",14), rpad(r.status,8),
      public.referenz_fuer_rechnung(r."invoiceNumber", r."tenantId");
  END LOOP;
END $$;
