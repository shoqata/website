-- Die Spende bekommt die Referenzart, die zur IBAN des Vereins passt.
-- Die Rueckgabe bekommt eine Spalte mehr (die Referenzart), deshalb erst
-- ablegen: CREATE OR REPLACE darf den Rueckgabetyp nicht aendern.
DROP FUNCTION IF EXISTS public.spende_anlegen(numeric,text,text,text,text,text,text,text,text,text,boolean);
CREATE FUNCTION public.spende_anlegen(
  p_betrag numeric, p_waehrung text DEFAULT 'CHF', p_name text DEFAULT NULL,
  p_email text DEFAULT NULL, p_strasse text DEFAULT NULL, p_plz text DEFAULT NULL,
  p_ort text DEFAULT NULL, p_land text DEFAULT 'CH', p_nachricht text DEFAULT NULL,
  p_zweck text DEFAULT NULL, p_anonym boolean DEFAULT false
) RETURNS TABLE (id uuid, referenz text, betrag numeric, waehrung text, art text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := COALESCE(public.current_tenant(), public.request_tenant());
        v_ref text; v_nummer bigint; v_offen int; v_id uuid; v_art text;
        v_ich text := public.current_user_row_id();
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE='check_violation'; END IF;
  IF NOT public.modul_aktiv('SPENDEN') THEN
    RAISE EXCEPTION 'Spenden sind bei diesem Verein nicht eingerichtet.'
      USING ERRCODE='check_violation'; END IF;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > 100000 THEN
    RAISE EXCEPTION 'Der Betrag muss zwischen 0 und 100000 liegen.'
      USING ERRCODE='check_violation'; END IF;
  IF coalesce(p_waehrung,'CHF') NOT IN ('CHF','EUR') THEN
    RAISE EXCEPTION 'Nur CHF oder EUR.' USING ERRCODE='check_violation'; END IF;
  IF NOT coalesce(p_anonym,false) AND coalesce(btrim(p_name),'') = '' THEN
    RAISE EXCEPTION 'Bitte einen Namen angeben, oder ausdruecklich anonym spenden.'
      USING ERRCODE='check_violation'; END IF;

  SELECT count(*) INTO v_offen FROM public.donations d
   WHERE d."tenantId" = v_verein AND d.status='OFFEN'
     AND d.erfasst_am > now() - interval '1 hour';
  IF v_offen >= 30 THEN
    RAISE EXCEPTION 'Zu viele offene Spenden in kurzer Zeit. Bitte spaeter erneut versuchen.'
      USING ERRCODE='check_violation'; END IF;

  v_nummer := nextval('public.spenden_nummer');
  v_art := public.referenzart(v_verein);

  IF v_art = 'QRR' THEN
    -- 27 Ziffern: Jahr, Kennzeichen 9 fuer Spenden, laufende Nummer, Pruefziffer.
    v_ref := extract(year FROM current_date)::text || '9' || lpad(v_nummer::text, 21, '0');
    v_ref := v_ref || public.mod10_pruefziffer(v_ref);
  ELSE
    -- Creditor Reference nach ISO 11649. Mit einer normalen IBAN ist das die
    -- zulaessige Art; QRR verlangt eine QR-IBAN, die dieser Verein nicht hat.
    v_ref := public.scor_referenz('SP' || extract(year FROM current_date)::text
                                  || lpad(v_nummer::text, 10, '0'));
  END IF;

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

  RETURN QUERY SELECT v_id, v_ref, p_betrag, coalesce(p_waehrung,'CHF'), v_art;
END $$;
GRANT EXECUTE ON FUNCTION public.spende_anlegen(numeric,text,text,text,text,text,text,text,text,text,boolean) TO anon, authenticated;

DO $$
DECLARE v_back text := current_user; r record;
BEGIN
  DELETE FROM public.donations WHERE "tenantId"='koretini';
  SET LOCAL ROLE anon;
  PERFORM set_config('request.headers', json_build_object('origin','https://koretini.me')::text, true);
  SELECT * INTO r FROM public.spende_anlegen(50,'CHF','Probe',NULL,NULL,NULL,NULL,'CH',NULL,NULL,false);
  RAISE NOTICE 'Referenz: % (Art %)', r.referenz, r.art;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);
  DELETE FROM public.donations WHERE "tenantId"='koretini';
END $$;
