-- Referenznummern, die zur IBAN des Vereins passen.
--
-- Gemessen: die hinterlegte IBAN CH13 0630 ... ist keine QR-IBAN
-- (Institutsnummer 6300, der QR-Bereich ist 30000-31999). Eine
-- QRR-Referenz ist damit unzulaessig, und der Beleg verwarf sie -- der
-- Einzahlungsschein trug "Referenzart NON" und gar keine Nummer. Damit
-- laesst sich keine eingehende Zahlung automatisch zuordnen.
--
-- Die Loesung braucht keine neue Bankverbindung: die Creditor Reference
-- nach ISO 11649 (SCOR, "RF...") ist mit einer normalen IBAN zulaessig und
-- leistet dasselbe.

-- Pruefziffern nach Modulo 97-10.
CREATE OR REPLACE FUNCTION public.mod97_pruefziffern(p_ref text)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE v text := ''; c text; i int; rest int := 0;
BEGIN
  -- Referenz + "RF00", Buchstaben als Zahlen (A=10 … Z=35).
  FOR i IN 1..length(p_ref || 'RF00') LOOP
    c := upper(substr(p_ref || 'RF00', i, 1));
    IF c ~ '[0-9]' THEN v := v || c;
    ELSIF c ~ '[A-Z]' THEN v := v || (ascii(c) - 55)::text;
    END IF;
  END LOOP;
  -- Stueckweise rechnen: die Zahl ist zu gross fuer bigint.
  FOR i IN 1..length(v) LOOP
    rest := (rest * 10 + substr(v, i, 1)::int) % 97;
  END LOOP;
  RETURN lpad((98 - rest)::text, 2, '0');
END $$;

CREATE OR REPLACE FUNCTION public.scor_referenz(p_kern text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT 'RF' || public.mod97_pruefziffern(p_kern) || p_kern;
$$;

-- Welche Art passt zur IBAN dieses Vereins?
CREATE OR REPLACE FUNCTION public.referenzart(p_verein text)
RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_iban text; v_iid int;
BEGIN
  SELECT replace(coalesce(payment ->> 'qrIban', payment ->> 'iban', ''), ' ', '')
    INTO v_iban FROM public.settings WHERE id = 'payment' AND "tenantId" = p_verein;
  IF v_iban IS NULL OR length(v_iban) < 9 THEN RETURN 'NON'; END IF;
  v_iid := substr(v_iban, 5, 5)::int;
  RETURN CASE WHEN v_iid BETWEEN 30000 AND 31999 THEN 'QRR' ELSE 'SCOR' END;
END $$;

REVOKE ALL ON FUNCTION public.referenzart(text) FROM public;
GRANT EXECUTE ON FUNCTION public.referenzart(text) TO anon, authenticated;

-- Probe an den Beispielen der Norm.
DO $$
BEGIN
  RAISE NOTICE 'RF18 5390 0754 7034 -> erzeugt: %', public.scor_referenz('539007547034');
  RAISE NOTICE '  (erwartet RF18539007547034)';
  RAISE NOTICE 'Referenzart koretini: % (erwartet SCOR)', public.referenzart('koretini');
END $$;
