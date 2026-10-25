-- Aufnahmeantraege: Selbstregistrierung mit Pruefung durch den Vorstand.
--
-- Bisher legte die Registrierung sofort ein Konto mit selbst gewaehltem
-- Passwort und eine neue Mitgliederzeile an. Bei Koretini haben von 341
-- aktiven Mitgliedern 9 ein Konto -- wer von den uebrigen sich registrierte,
-- bekam eine zweite Zeile neben seiner alten, ohne deren Rechnungen.
--
-- Jetzt:
--   1. Wer sich registriert, stellt einen Antrag (ohne Konto, ohne Passwort).
--   2. Der Vorstand sieht den Antrag zusammen mit moeglichen Treffern unter
--      den bestehenden Mitgliedern (E-Mail, Telefon, Name, Nachbarschaft).
--   3. Er gibt frei: als neues Mitglied oder als ein bestehendes. Dabei
--      entsteht gleich die Rechnung fuer das laufende Jahr.
--   4. Er setzt das Passwort (bestehende Funktion reset-member-password,
--      die das Konto anlegt, wenn es noch keines gibt).
--
-- Dem Antragsteller wird nie gesagt, ob er schon Mitglied ist -- sonst
-- liesse sich mit der Registrierung abfragen, wer im Verein ist.

CREATE TABLE public.aufnahmeantraege (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"     text NOT NULL REFERENCES public.tenants(id) ON UPDATE CASCADE,
  anrede         text,
  vorname        text NOT NULL,
  nachname       text NOT NULL,
  email          text NOT NULL,
  telefon        text,
  strasse        text,
  plz            text,
  ort            text,
  land           text,
  nachbarschaft  text,
  rechnungsweg   text NOT NULL DEFAULT 'EMAIL',
  sprache        text,
  status         text NOT NULL DEFAULT 'OFFEN' CHECK (status IN ('OFFEN', 'FREIGEGEBEN', 'ABGELEHNT')),
  mitglied       text REFERENCES public.users(id) ON DELETE SET NULL,
  rechnung       text,
  grund          text,
  eingegangen_am timestamptz NOT NULL DEFAULT now(),
  erledigt_von   text,
  erledigt_am    timestamptz
);
CREATE INDEX aufnahmeantraege_offen_idx ON public.aufnahmeantraege ("tenantId", eingegangen_am DESC) WHERE status = 'OFFEN';

ALTER TABLE public.aufnahmeantraege ENABLE ROW LEVEL SECURITY;
CREATE POLICY aufnahmeantraege_vorstand ON public.aufnahmeantraege
  FOR SELECT TO authenticated
  USING (public.is_staff() AND "tenantId" = public.current_tenant());
GRANT SELECT ON public.aufnahmeantraege TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.aufnahmeantraege FROM anon, authenticated;


-- --- Vergleichen ---------------------------------------------------------

-- Fuer den Vergleich: klein, ohne Akzente, nur Buchstaben und Ziffern.
-- "Krasniqi", "KRASNIQI " und "Krasníqi" sind derselbe Name; ë und ç
-- stehen in albanischen Namen staendig, mal mit, mal ohne.
CREATE OR REPLACE FUNCTION public.name_norm(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT regexp_replace(
    translate(lower(coalesce(t, '')),
      'ëçäöüéèêâàáîïíôóûúùšžćčđłñ',
      'ecaoueeeaaaiiioouuuszccdln'),
    '[^a-z0-9]', '', 'g');
$$;

-- Telefonnummern: nur Ziffern, davon die letzten neun. Damit sind
-- "+41 79 123 45 67", "0041791234567" und "079 123 45 67" gleich.
CREATE OR REPLACE FUNCTION public.telefon_norm(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN length(regexp_replace(coalesce(t, ''), '\D', '', 'g')) >= 7
              THEN right(regexp_replace(t, '\D', '', 'g'), 9) END;
$$;

CREATE OR REPLACE FUNCTION public.email_echt(t text) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT coalesce(t, '') ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     AND coalesce(t, '') !~* '(@koretini\.legacy|no-email-)';
$$;


-- --- Antrag stellen (oeffentlich) ---------------------------------------

CREATE OR REPLACE FUNCTION public.aufnahme_beantragen(
  p_vorname text, p_nachname text, p_email text,
  p_telefon text DEFAULT NULL, p_anrede text DEFAULT NULL,
  p_strasse text DEFAULT NULL, p_plz text DEFAULT NULL, p_ort text DEFAULT NULL,
  p_land text DEFAULT NULL, p_nachbarschaft text DEFAULT NULL,
  p_rechnungsweg text DEFAULT 'EMAIL', p_sprache text DEFAULT NULL)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_verein text := coalesce(public.current_tenant(), public.request_tenant());
        v_email text := lower(btrim(coalesce(p_email, '')));
        v_id uuid;
        kurz CONSTANT int := 200;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE = 'check_violation'; END IF;
  IF btrim(coalesce(p_vorname, '')) = '' OR btrim(coalesce(p_nachname, '')) = '' THEN
    RAISE EXCEPTION 'Bitte Vor- und Nachnamen angeben.' USING ERRCODE = 'check_violation'; END IF;
  -- Eine echte E-Mail ist Pflicht: ueber sie bekommt das Mitglied sein Konto.
  IF NOT public.email_echt(v_email) THEN
    RAISE EXCEPTION 'Bitte eine gueltige E-Mail-Adresse angeben.' USING ERRCODE = 'check_violation'; END IF;
  IF greatest(length(p_vorname), length(p_nachname), length(v_email), length(coalesce(p_telefon, '')),
              length(coalesce(p_strasse, '')), length(coalesce(p_ort, ''))) > kurz THEN
    RAISE EXCEPTION 'Eine Angabe ist zu lang.' USING ERRCODE = 'check_violation'; END IF;
  -- Schutz vor Massenantraegen.
  IF (SELECT count(*) FROM public.aufnahmeantraege
       WHERE "tenantId" = v_verein AND eingegangen_am > now() - interval '1 hour') >= 20 THEN
    RAISE EXCEPTION 'Gerade gehen sehr viele Antraege ein. Bitte spaeter erneut versuchen.'
      USING ERRCODE = 'check_violation'; END IF;

  -- Derselbe offene Antrag zweimal: still annehmen und den ersten
  -- aktualisieren, statt einen zweiten anzulegen. Keine Meldung, die
  -- verraet, dass es ihn schon gibt.
  SELECT id INTO v_id FROM public.aufnahmeantraege
   WHERE "tenantId" = v_verein AND status = 'OFFEN' AND lower(email) = v_email LIMIT 1;

  IF v_id IS NOT NULL THEN
    UPDATE public.aufnahmeantraege SET
      anrede = p_anrede, vorname = btrim(p_vorname), nachname = btrim(p_nachname),
      telefon = p_telefon, strasse = p_strasse, plz = p_plz, ort = p_ort, land = p_land,
      nachbarschaft = nullif(p_nachbarschaft, ''), rechnungsweg = coalesce(p_rechnungsweg, 'EMAIL'),
      sprache = p_sprache, eingegangen_am = now()
     WHERE id = v_id;
    RETURN true;
  END IF;

  INSERT INTO public.aufnahmeantraege ("tenantId", anrede, vorname, nachname, email, telefon,
      strasse, plz, ort, land, nachbarschaft, rechnungsweg, sprache)
  VALUES (v_verein, p_anrede, btrim(p_vorname), btrim(p_nachname), v_email, p_telefon,
      p_strasse, p_plz, p_ort, p_land, nullif(p_nachbarschaft, ''),
      CASE WHEN p_rechnungsweg IN ('EMAIL', 'POST', 'BOTH') THEN p_rechnungsweg ELSE 'EMAIL' END,
      CASE WHEN p_sprache IN ('de', 'sq', 'en') THEN p_sprache END);

  BEGIN
    PERFORM public.benachrichtigen(v_verein, public.empfaenger_vorstand(v_verein),
      'AUFNAHME', 'Neuer Aufnahmeantrag', btrim(p_vorname) || ' ' || btrim(p_nachname), '/admin');
  EXCEPTION WHEN others THEN NULL;
  END;
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.aufnahme_beantragen(text, text, text, text, text, text, text, text, text, text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.aufnahme_beantragen(text, text, text, text, text, text, text, text, text, text, text, text) TO anon, authenticated;


-- --- Moegliche Treffer (Vorstand) ---------------------------------------

CREATE OR REPLACE FUNCTION public.aufnahme_treffer(p_antrag uuid)
RETURNS TABLE (mitglied text, name text, email text, telefon text, nachbarschaft text,
               status text, hat_konto boolean, punkte int, gruende text[])
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE a public.aufnahmeantraege;
BEGIN
  SELECT * INTO a FROM public.aufnahmeantraege WHERE id = p_antrag;
  IF a.id IS NULL OR NOT public.is_staff() OR a."tenantId" IS DISTINCT FROM public.current_tenant() THEN
    RETURN; END IF;

  RETURN QUERY
  WITH k AS (
    SELECT u.*,
      (public.email_echt(u.email) AND lower(btrim(u.email)) = lower(a.email)) AS e_gleich,
      (public.telefon_norm(a.telefon) IS NOT NULL AND
       public.telefon_norm(a.telefon) IN (public.telefon_norm(u.phone), public.telefon_norm(u."phoneSecondary"))) AS t_gleich,
      (public.name_norm(a.vorname || a.nachname) <> '' AND
       public.name_norm(a.vorname || a.nachname) IN (
         public.name_norm(coalesce(u."firstName", '') || coalesce(u."lastName", '')),
         public.name_norm(coalesce(u."lastName", '') || coalesce(u."firstName", '')),
         public.name_norm(u."displayName"))) AS n_gleich,
      (public.name_norm(a.nachname) <> '' AND public.name_norm(a.nachname) = public.name_norm(u."lastName")) AS nn_gleich,
      (a.nachbarschaft IS NOT NULL AND a.nachbarschaft = u."neighborhoodId") AS nb_gleich
    FROM public.users u
    WHERE u."tenantId" = a."tenantId" AND u.role IN ('MEMBER', 'BOARD', 'ADMIN', 'REPRESENTATIVE')
  ), bewertet AS (
    SELECT k.*,
      (CASE WHEN e_gleich THEN 50 ELSE 0 END
     + CASE WHEN t_gleich THEN 40 ELSE 0 END
     + CASE WHEN n_gleich THEN 35 WHEN nn_gleich THEN 10 ELSE 0 END
     + CASE WHEN nb_gleich AND (n_gleich OR nn_gleich) THEN 15 ELSE 0 END) AS p,
      array_remove(ARRAY[
        CASE WHEN e_gleich THEN 'E-Mail' END,
        CASE WHEN t_gleich THEN 'Telefon' END,
        CASE WHEN n_gleich THEN 'Name' WHEN nn_gleich THEN 'Nachname' END,
        CASE WHEN nb_gleich AND (n_gleich OR nn_gleich) THEN 'Nachbarschaft' END], NULL) AS g
    FROM k
  )
  SELECT b.id, coalesce(nullif(b."displayName", ''), btrim(coalesce(b."firstName", '') || ' ' || coalesce(b."lastName", ''))),
         b.email, b.phone, n.name, b."membershipStatus", b."authUserId" IS NOT NULL, b.p, b.g
    FROM bewertet b LEFT JOIN public.neighborhoods n ON n.id = b."neighborhoodId"
   WHERE b.p >= 25
   ORDER BY b.p DESC, b."joinedAt" NULLS LAST
   LIMIT 5;
END $$;
REVOKE ALL ON FUNCTION public.aufnahme_treffer(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.aufnahme_treffer(uuid) TO authenticated;


-- --- Freigeben (Vorstand) -----------------------------------------------

-- Gibt einen Antrag frei: als neues Mitglied (p_mitglied leer) oder als
-- ein bestehendes (p_mitglied = dessen Zeile). Danach steht das Mitglied
-- auf ACTIVE und hat eine Rechnung fuer das laufende Jahr -- es sei denn,
-- es hat schon eine.
CREATE OR REPLACE FUNCTION public.aufnahme_freigeben(
  p_antrag uuid, p_mitglied text DEFAULT NULL, p_gruppe text DEFAULT 'STANDARD')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE a public.aufnahmeantraege;
        v_ich text := public.current_user_row_id();
        v_id text; v_jahr int := extract(year FROM now())::int;
        v_gruppe text := CASE WHEN p_gruppe IN ('STANDARD', 'REDUCED', 'KOSOVO') THEN p_gruppe ELSE 'STANDARD' END;
        u public.users; v_fees jsonb; v_betrag numeric; v_waehrung text;
        v_rechnung text; v_nummer text; v_schon boolean := false; v_land text;
BEGIN
  SELECT * INTO a FROM public.aufnahmeantraege WHERE id = p_antrag FOR UPDATE;
  IF a.id IS NULL OR NOT public.is_staff() OR a."tenantId" IS DISTINCT FROM public.current_tenant() THEN
    RAISE EXCEPTION 'Antrag nicht gefunden.' USING ERRCODE = 'check_violation'; END IF;
  IF a.status <> 'OFFEN' THEN
    RAISE EXCEPTION 'Dieser Antrag ist schon erledigt.' USING ERRCODE = 'check_violation'; END IF;

  IF p_mitglied IS NOT NULL THEN
    -- Bestehendes Mitglied: Status aktiv, fehlende Angaben aus dem Antrag
    -- ergaenzen. Vorhandene werden nicht ueberschrieben -- was im Verein
    -- steht, hat der Vorstand gepflegt.
    SELECT * INTO u FROM public.users WHERE id = p_mitglied AND "tenantId" = a."tenantId";
    IF u.id IS NULL THEN
      RAISE EXCEPTION 'Mitglied nicht gefunden.' USING ERRCODE = 'check_violation'; END IF;
    UPDATE public.users SET
      "membershipStatus" = 'ACTIVE',
      -- Platzhalter-Adressen aus dem Import durch die echte ersetzen, aber
      -- nur, wenn sie nicht schon einem anderen Mitglied gehoert.
      email = CASE WHEN NOT public.email_echt(email)
                    AND NOT EXISTS (SELECT 1 FROM public.users x WHERE x."tenantId" = a."tenantId"
                                      AND x.id <> u.id AND lower(btrim(x.email)) = a.email)
                   THEN a.email ELSE email END,
      "isLegacyEmail" = CASE WHEN NOT public.email_echt(email) THEN false ELSE "isLegacyEmail" END,
      phone = coalesce(nullif(phone, ''), a.telefon),
      street = coalesce(nullif(street, ''), a.strasse),
      zip = coalesce(nullif(zip, ''), a.plz),
      city = coalesce(nullif(city, ''), a.ort),
      country = coalesce(nullif(country, ''), a.land),
      "neighborhoodId" = coalesce("neighborhoodId", a.nachbarschaft),
      "firstName" = coalesce(nullif("firstName", ''), a.vorname),
      "lastName" = coalesce(nullif("lastName", ''), a.nachname),
      "billingGroup" = CASE WHEN "billingGroup" IS NULL AND v_gruppe <> 'STANDARD' THEN v_gruppe ELSE "billingGroup" END
     WHERE id = u.id;
    v_id := u.id;
  ELSE
    IF EXISTS (SELECT 1 FROM public.users WHERE "tenantId" = a."tenantId" AND lower(btrim(email)) = a.email) THEN
      RAISE EXCEPTION 'Diese E-Mail gehoert schon einem Mitglied. Bitte den Antrag diesem Mitglied zuordnen.'
        USING ERRCODE = 'check_violation'; END IF;
    v_id := gen_random_uuid()::text;
    INSERT INTO public.users (id, "tenantId", email, "displayName", role, "membershipStatus",
        salutation, "firstName", "lastName", phone, street, zip, city, country, address,
        "neighborhoodId", "invoiceDeliveryMethod", "joinedAt", "profileComplete", "billingGroup", sprache)
    VALUES (v_id, a."tenantId", a.email, a.vorname || ' ' || a.nachname, 'MEMBER', 'ACTIVE',
        a.anrede, a.vorname, a.nachname, a.telefon, a.strasse, a.plz, a.ort, a.land,
        concat_ws(', ', nullif(a.strasse, ''), nullif(btrim(coalesce(a.plz, '') || ' ' || coalesce(a.ort, '')), ''), nullif(a.land, '')),
        a.nachbarschaft, a.rechnungsweg, now(), true,
        CASE WHEN v_gruppe <> 'STANDARD' THEN v_gruppe END, a.sprache);
  END IF;

  SELECT * INTO u FROM public.users WHERE id = v_id;

  -- Rechnung fuer das laufende Jahr -- nur, wenn es noch keine gibt.
  SELECT id, "invoiceNumber" INTO v_rechnung, v_nummer FROM public.payments
   WHERE "userId" = v_id AND "billingYear" = v_jahr AND type = 'FEE' AND status <> 'CANCELLED'
   ORDER BY timestamp LIMIT 1;
  IF v_rechnung IS NOT NULL THEN
    v_schon := true;
  ELSE
    -- Derselbe Betrag wie im Rechnungsassistenten (beitragVon in
    -- AdminFinance): eigener Beitrag vor Gruppenbeitrag vor Standard.
    SELECT payment->'fees' INTO v_fees FROM public.settings WHERE id = 'payment' AND "tenantId" = a."tenantId";
    IF u."customAnnualFee" IS NOT NULL THEN
      v_betrag := u."customAnnualFee";
      v_waehrung := coalesce(nullif(u.currency, ''), v_fees->'STANDARD'->>'currency', 'CHF');
    ELSE
      v_betrag := coalesce((v_fees->coalesce(u."billingGroup", 'STANDARD')->>'amount')::numeric,
                           (v_fees->'STANDARD'->>'amount')::numeric, 120);
      v_waehrung := coalesce(v_fees->coalesce(u."billingGroup", 'STANDARD')->>'currency',
                             v_fees->'STANDARD'->>'currency', 'CHF');
    END IF;
    v_land := lower(coalesce(u.country, ''));
    v_rechnung := gen_random_uuid()::text;
    v_nummer := 'INV-' || right(extract(epoch FROM clock_timestamp())::bigint::text, 6) || '-'
                || lpad((floor(random() * 100000))::int::text, 5, '0');
    INSERT INTO public.payments (id, "tenantId", "userId", amount, currency, type, "billingYear",
        method, status, "deliveryMethod", "dueDate", "invoiceNumber", description)
    VALUES (v_rechnung, a."tenantId", v_id, v_betrag, v_waehrung, 'FEE', v_jahr,
        CASE WHEN v_land = '' OR v_land IN ('switzerland', 'schweiz', 'suisse', 'svizzera', 'ch', 'zvicër', 'zvicer') THEN 'QR_BILL'
             WHEN v_land IN ('germany', 'deutschland', 'de', 'austria', 'österreich', 'at', 'france', 'frankreich', 'fr', 'italy', 'italien', 'it') THEN 'GIRO_CODE'
             ELSE 'PAYPAL' END,
        'PENDING', coalesce(u."invoiceDeliveryMethod", 'EMAIL'),
        to_char(current_date + 30, 'YYYY-MM-DD'), v_nummer, 'Mitgliederbeitrag ' || v_jahr);
  END IF;

  UPDATE public.aufnahmeantraege SET status = 'FREIGEGEBEN', mitglied = v_id, rechnung = v_rechnung,
         erledigt_von = v_ich, erledigt_am = now()
   WHERE id = a.id;

  SELECT amount, currency INTO v_betrag, v_waehrung FROM public.payments WHERE id = v_rechnung;
  RETURN jsonb_build_object('mitglied', v_id, 'name', u."displayName", 'email', u.email,
    'rechnung', v_rechnung, 'rechnungsnummer', v_nummer, 'betrag', v_betrag, 'waehrung', v_waehrung,
    'rechnung_bestand_schon', v_schon, 'hat_konto', u."authUserId" IS NOT NULL);
END $$;
REVOKE ALL ON FUNCTION public.aufnahme_freigeben(uuid, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.aufnahme_freigeben(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.aufnahme_ablehnen(p_antrag uuid, p_grund text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE n int;
BEGIN
  UPDATE public.aufnahmeantraege
     SET status = 'ABGELEHNT', grund = left(p_grund, 500),
         erledigt_von = public.current_user_row_id(), erledigt_am = now()
   WHERE id = p_antrag AND status = 'OFFEN'
     AND public.is_staff() AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN RAISE EXCEPTION 'Antrag nicht gefunden oder schon erledigt.' USING ERRCODE = 'check_violation'; END IF;
END $$;
REVOKE ALL ON FUNCTION public.aufnahme_ablehnen(uuid, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.aufnahme_ablehnen(uuid, text) TO authenticated;
