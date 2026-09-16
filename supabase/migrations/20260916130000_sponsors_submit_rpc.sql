-- Aufloesung des 42501 beim Sponsorenformular.
--
-- Der Fehler kam nicht von der Einfuege-Regel -- die lautete zuletzt
-- WITH CHECK (true) und wies trotzdem ab. Ursache ist das Zurueckgeben der
-- neuen Zeile: sowohl "Prefer: return=representation" als auch ein
-- INSERT ... RETURNING verlangen zusaetzlich eine Leseberechtigung auf genau
-- diese Zeile. Fuer einen anonymen Besucher gibt es keine, und PostgreSQL
-- meldet das als Verstoss gegen die Zeilenregel.
--
-- Statt dem Besucher dafuer ein Leserecht einzuraeumen, bekommt er einen
-- einzigen, eng geschnittenen Eingang: eine Funktion, die genau eine Anfrage
-- anlegt und nur deren Kennung zurueckgibt. Das Einfuegerecht auf der Tabelle
-- wird ihm wieder entzogen -- die Tabelle bleibt damit vollstaendig zu.

CREATE OR REPLACE FUNCTION public.submit_sponsor(
  p_package  text,
  p_amount   numeric,
  p_company  text,
  p_contact  text,
  p_email    text,
  p_phone    text DEFAULT NULL,
  p_street   text DEFAULT NULL,
  p_zip      text DEFAULT NULL,
  p_city     text DEFAULT NULL,
  p_country  text DEFAULT NULL,
  p_website  text DEFAULT NULL,
  p_message  text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tenant text;
  v_id     uuid;
  v_pkg    text;
BEGIN
  v_tenant := COALESCE(public.current_tenant(), public.request_tenant());
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Sponsorenanfrage ohne erkennbaren Verein.'
      USING ERRCODE = 'check_violation';
  END IF;

  IF coalesce(btrim(p_company), '') = '' THEN
    RAISE EXCEPTION 'Firmenname fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_contact), '') = '' THEN
    RAISE EXCEPTION 'Ansprechperson fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_email), '') !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'E-Mail-Adresse ist ungueltig.' USING ERRCODE = 'check_violation';
  END IF;

  v_pkg := upper(coalesce(btrim(p_package), 'BASIC'));
  IF v_pkg NOT IN ('BASIC','STANDARD','GOLD','TOURNAMENT','CUSTOM') THEN
    v_pkg := 'CUSTOM';
  END IF;

  -- Ein eigener Betrag muss plausibel sein; Paketbetraege setzt ohnehin
  -- der Server nicht, sie dienen nur der Einordnung im Vorstand.
  IF p_amount IS NOT NULL AND (p_amount < 0 OR p_amount > 1000000) THEN
    RAISE EXCEPTION 'Betrag ist ausserhalb des zulaessigen Bereichs.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.sponsors (
    "tenantId", "packageKey", amount, currency,
    company, "contactName", email, phone,
    street, zip, city, country, website, message, status
  ) VALUES (
    v_tenant, v_pkg, p_amount, 'CHF',
    btrim(p_company), btrim(p_contact), lower(btrim(p_email)), nullif(btrim(coalesce(p_phone,'')), ''),
    nullif(btrim(coalesce(p_street,'')), ''), nullif(btrim(coalesce(p_zip,'')), ''),
    nullif(btrim(coalesce(p_city,'')), ''), nullif(btrim(coalesce(p_country,'')), ''),
    nullif(btrim(coalesce(p_website,'')), ''), nullif(btrim(coalesce(p_message,'')), ''),
    'NEW'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

GRANT EXECUTE ON FUNCTION public.submit_sponsor(
  text, numeric, text, text, text, text, text, text, text, text, text, text
) TO anon, authenticated;

-- Die Tabelle selbst bleibt fuer Besucher zu. Der einzige Weg hinein ist die
-- Funktion oben.
DROP POLICY IF EXISTS sponsors_public_insert ON public.sponsors;
REVOKE INSERT ON public.sponsors FROM anon;
REVOKE ALL ON public.sponsors FROM anon;

DROP TRIGGER IF EXISTS sponsors_set_tenant ON public.sponsors;
DROP FUNCTION IF EXISTS public.set_sponsor_tenant();
DROP FUNCTION IF EXISTS public.sponsor_tenant_probe();

-- Der Selbsttest stand hier und ist nach bestandener Messung entfernt.
-- Gemessen in der Rolle des Besuchers, mit gesetztem Origin:
--
--   1 erlaubter Fall (www.koretini.me)      -> angelegt
--   2 Besucher liest die Tabelle mit        -> abgewiesen (42501)
--   3 ungueltige E-Mail                     -> abgewiesen
--   4 fremde Adresse ohne Vereinszuordnung  -> abgewiesen
--
-- Der Block selbst endete in der Rolle anon und liess damit jede nachfolgende
-- Anweisung scheitern; das Aufraeumen der Testzeilen steht deshalb in einer
-- eigenen Migration.

NOTIFY pgrst, 'reload schema';
