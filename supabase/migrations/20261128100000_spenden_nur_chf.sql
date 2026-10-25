-- Spenden: CHF ist die Basis.
--
-- Spendenaufrufe liessen EUR als Waehrung zu, die Spendenseite schickte aber
-- immer 'CHF' -- eine Spende an einen EUR-Aufruf waere mit dem Zahlenwert in
-- Franken gebucht worden. Gemessen am 25.10.2026: es gibt keinen Aufruf und
-- keine Spende in EUR. Statt die zweite Waehrung zu Ende zu bauen (Konto,
-- QR-Rechnung, Buchhaltung, Summen), wird sie geschlossen.
--
-- Die Vertreterkasse (Bargeld vor Ort in Kosovo) bleibt bewusst bei EUR;
-- sie gehoert nicht zu den Spenden.

ALTER TABLE public.spendenaufrufe
  ADD CONSTRAINT spendenaufrufe_nur_chf CHECK (waehrung = 'CHF');
ALTER TABLE public.donations
  ADD CONSTRAINT donations_nur_chf CHECK (waehrung = 'CHF');

CREATE OR REPLACE FUNCTION public.spende_anlegen(p_betrag numeric, p_waehrung text DEFAULT 'CHF'::text, p_name text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_strasse text DEFAULT NULL::text, p_plz text DEFAULT NULL::text, p_ort text DEFAULT NULL::text, p_land text DEFAULT 'CH'::text, p_nachricht text DEFAULT NULL::text, p_zweck text DEFAULT NULL::text, p_anonym boolean DEFAULT false)
 RETURNS TABLE(id uuid, referenz text, betrag numeric, waehrung text, art text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- CHF ist die Basis. Konto und QR-Rechnung des Vereins laufen auf Franken.
  IF coalesce(p_waehrung,'CHF') <> 'CHF' THEN
    RAISE EXCEPTION 'Spenden werden in CHF erfasst.' USING ERRCODE='check_violation'; END IF;
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
END $function$;
