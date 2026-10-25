-- "Ich habe bezahlt": das Mitglied meldet eine Zahlung zu seiner Rechnung.
-- Der Vorstand prueft den Eingang und setzt die Rechnung in den Finanzen auf
-- bezahlt -- die Meldung selbst bucht nichts (Buchhaltung bleibt revisionsfest).
ALTER TABLE public.mitglied_aenderungen DROP CONSTRAINT IF EXISTS mitglied_aenderungen_art_check;
ALTER TABLE public.mitglied_aenderungen ADD CONSTRAINT mitglied_aenderungen_art_check
  CHECK (art IN ('ADRESSE','FAMILIE','SONSTIGES','ZAHLUNG'));

CREATE OR REPLACE FUNCTION public.aenderung_melden(p_art text, p_daten jsonb)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text := public.current_user_row_id();
  v_verein text := public.current_tenant();
  v_id uuid;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_art NOT IN ('ADRESSE','FAMILIE','SONSTIGES','ZAHLUNG') OR jsonb_typeof(coalesce(p_daten,'{}')) <> 'object'
     OR length(p_daten::text) > 4000 THEN
    RAISE EXCEPTION 'Ungueltige Meldung.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_art = 'ADRESSE' AND coalesce(btrim(p_daten->>'street'),'') = '' THEN
    RAISE EXCEPTION 'Bitte die neue Strasse angeben.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_art IN ('FAMILIE','SONSTIGES') AND btrim(coalesce(p_daten->>'text','')) = '' THEN
    RAISE EXCEPTION 'Bitte kurz beschreiben, was sich geaendert hat.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_art = 'ZAHLUNG' THEN
    -- Nur zu einer eigenen, offenen Rechnung; je Rechnung eine offene Meldung.
    IF NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = p_daten->>'payment'
                     AND p."userId" = v_ich AND p.status <> 'PAID') THEN
      RAISE EXCEPTION 'Diese Rechnung ist nicht offen.' USING ERRCODE = 'check_violation';
    END IF;
    IF EXISTS (SELECT 1 FROM public.mitglied_aenderungen a WHERE a.mitglied = v_ich AND a.art = 'ZAHLUNG'
                 AND a.status = 'OFFEN' AND a.daten->>'payment' = p_daten->>'payment') THEN
      RAISE EXCEPTION 'Diese Zahlung ist schon gemeldet.' USING ERRCODE = 'check_violation';
    END IF;
    SELECT p_daten || jsonb_build_object('betrag', p.amount, 'rechnung', p."invoiceNumber", 'beschreibung', p.description)
      INTO p_daten FROM public.payments p WHERE p.id = p_daten->>'payment';
  END IF;
  IF (SELECT count(*) FROM public.mitglied_aenderungen WHERE mitglied = v_ich AND status = 'OFFEN') >= 10 THEN
    RAISE EXCEPTION 'Es sind schon viele Meldungen offen. Bitte warten Sie, bis der Vorstand sie bearbeitet hat.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.mitglied_aenderungen ("tenantId", mitglied, art, daten)
  VALUES (v_verein, v_ich, p_art, p_daten) RETURNING id INTO v_id;
  RETURN v_id;
END $$;
NOTIFY pgrst, 'reload schema';
