-- Eine Spende entgegennehmen -- auch von jemandem, der nicht angemeldet ist.
--
-- Die Referenznummer entsteht auf dem Server, nicht im Browser: sie muss
-- eindeutig sein, und eine im Browser erzeugte Nummer koennte doppelt
-- vergeben oder gefaelscht werden. Ueber sie ordnet die Bank die eingehende
-- Zahlung spaeter von selbst zu -- derselbe Mechanismus wie bei den
-- Mitgliederbeitraegen.
--
-- Eigener Nummernkreis: Jahr + '9' + laufende Nummer. Ohne die 9 koennte
-- eine Spendenreferenz mit der Rechnung eines Mitglieds zusammenfallen,
-- dessen Mitgliedsnummer zufaellig dieselbe Ziffernfolge ergibt.

CREATE SEQUENCE IF NOT EXISTS public.spenden_nummer;

-- Pruefziffer nach Modulo 10 rekursiv, wie sie die Swiss-QR-Rechnung
-- verlangt. Dieselbe Tabelle wie in services/qrBillService.ts -- beide
-- muessen dasselbe rechnen, sonst weist die Bank den Beleg ab.
CREATE OR REPLACE FUNCTION public.mod10_pruefziffer(p_ziffern text)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE tabelle int[] := ARRAY[0,9,4,6,8,2,7,1,3,5];
        uebertrag int := 0; i int;
BEGIN
  FOR i IN 1..length(p_ziffern) LOOP
    uebertrag := tabelle[((uebertrag + substr(p_ziffern, i, 1)::int) % 10) + 1];
  END LOOP;
  RETURN ((10 - uebertrag) % 10)::text;
END $$;

CREATE OR REPLACE FUNCTION public.spende_anlegen(
  p_betrag numeric,
  p_waehrung text DEFAULT 'CHF',
  p_name text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_strasse text DEFAULT NULL,
  p_plz text DEFAULT NULL,
  p_ort text DEFAULT NULL,
  p_land text DEFAULT 'CH',
  p_nachricht text DEFAULT NULL,
  p_zweck text DEFAULT NULL,
  p_anonym boolean DEFAULT false
) RETURNS TABLE (id uuid, referenz text, betrag numeric, waehrung text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := COALESCE(public.current_tenant(), public.request_tenant());
        v_ref text; v_nummer bigint; v_offen int; v_id uuid;
        v_ich text := public.current_user_row_id();
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.modul_aktiv('SPENDEN') THEN
    RAISE EXCEPTION 'Spenden sind bei diesem Verein nicht eingerichtet.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > 100000 THEN
    RAISE EXCEPTION 'Der Betrag muss zwischen 0 und 100000 liegen.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(p_waehrung,'CHF') NOT IN ('CHF','EUR') THEN
    RAISE EXCEPTION 'Nur CHF oder EUR.' USING ERRCODE = 'check_violation';
  END IF;
  -- Eine Bescheinigung muss auf einen Namen lauten. Wer anonym spendet,
  -- bekommt keine -- das wird hier festgehalten statt spaeter enttaeuscht.
  IF NOT coalesce(p_anonym,false) AND coalesce(btrim(p_name),'') = '' THEN
    RAISE EXCEPTION 'Bitte einen Namen angeben, oder ausdruecklich anonym spenden.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Bremse gegen Massenanlage: die Funktion ist anonym aufrufbar, und ohne
  -- Grenze liesse sich die Tabelle mit Scheinspenden fluten.
  SELECT count(*) INTO v_offen FROM public.donations d
   WHERE d."tenantId" = v_verein AND d.status = 'OFFEN'
     AND d.erfasst_am > now() - interval '1 hour';
  IF v_offen >= 30 THEN
    RAISE EXCEPTION 'Zu viele offene Spenden in kurzer Zeit. Bitte spaeter erneut versuchen.'
      USING ERRCODE = 'check_violation';
  END IF;

  v_nummer := nextval('public.spenden_nummer');
  v_ref := extract(year FROM current_date)::text || '9' || lpad(v_nummer::text, 21, '0');
  v_ref := v_ref || public.mod10_pruefziffer(v_ref);

  INSERT INTO public.donations
    ("tenantId", betrag, waehrung, name, email, strasse, plz, ort, land,
     anonym, nachricht, zweck, referenz, status, "userId", erfasst_von)
  VALUES
    (v_verein, p_betrag, coalesce(p_waehrung,'CHF'),
     nullif(btrim(p_name),''), nullif(btrim(p_email),''), nullif(btrim(p_strasse),''),
     nullif(btrim(p_plz),''), nullif(btrim(p_ort),''), coalesce(nullif(btrim(p_land),''),'CH'),
     coalesce(p_anonym,false), nullif(btrim(p_nachricht),''), nullif(btrim(p_zweck),''),
     v_ref, 'OFFEN', v_ich,
     CASE WHEN v_ich IS NULL THEN 'oeffentliche Seite' ELSE 'angemeldet' END)
  RETURNING donations.id INTO v_id;

  RETURN QUERY SELECT v_id, v_ref, p_betrag, coalesce(p_waehrung,'CHF');
END $$;

REVOKE ALL ON FUNCTION public.spende_anlegen(numeric,text,text,text,text,text,text,text,text,text,boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.spende_anlegen(numeric,text,text,text,text,text,text,text,text,text,boolean) TO anon, authenticated;
GRANT USAGE ON SEQUENCE public.spenden_nummer TO anon, authenticated;

-- Probe: stimmt die Pruefziffer mit der Rechnung im Browser ueberein?
DO $$
DECLARE v text;
BEGIN
  -- Beispiel aus der Swiss-QR-Dokumentation: 21 00000 00003 13947 14300 09017
  v := '21000000000313947143000901';
  RAISE NOTICE 'Pruefziffer fuer % -> % (erwartet 7)', v, public.mod10_pruefziffer(v);
END $$;
