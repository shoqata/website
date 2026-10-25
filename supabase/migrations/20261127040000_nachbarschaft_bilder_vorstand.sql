-- Bilder der Nachbarschaften: nur Verwaltung und Vorstand.
--
-- Entscheid des Vereins (25.10.2026): Bilder hochladen und aendern duerfen
-- Administration und Vorstand (is_member_manager: SUPER_ADMIN, ADMIN,
-- BOARD). Vertreter pflegen weiter Text, Lage und Gebiet ihrer
-- Nachbarschaft -- ihre Bilderliste wird beim Speichern nicht angenommen,
-- es bleibt die bestehende.

CREATE OR REPLACE FUNCTION public.nachbarschaft_bild_erlaubt(p_nachbarschaft text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL OR NOT EXISTS (SELECT 1 FROM public.neighborhoods n
       WHERE n.id = p_nachbarschaft AND n."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Diese Nachbarschaft gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Bilder laden nur Administration und Vorstand hoch.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_verein;
END $$;

CREATE OR REPLACE FUNCTION public.nachbarschaft_profil_speichern(
  p_nachbarschaft text, p_text jsonb, p_bilder jsonb, p_gebiet jsonb, p_ort text, p_sichtbar boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_verwaltung boolean := public.is_member_manager();
  v_wer text; v_p jsonb; v_b jsonb; v_bilder jsonb;
  v_ordner text;
BEGIN
  IF v_verein IS NULL OR NOT EXISTS (SELECT 1 FROM public.neighborhoods n
       WHERE n.id = p_nachbarschaft AND n."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Diese Nachbarschaft gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (v_verwaltung OR p_nachbarschaft IN (SELECT id FROM public.my_neighborhoods())) THEN
    RAISE EXCEPTION 'Nur Verwaltung, Vorstand und die Vertreter dieser Nachbarschaft.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  v_ordner := '/storage/v1/object/public/uploads/geprueft/nachbarschaften/' || v_verein || '/' || p_nachbarschaft || '/';

  IF jsonb_typeof(coalesce(p_gebiet, '[]')) <> 'array' OR jsonb_array_length(coalesce(p_gebiet, '[]')) > 200 THEN
    RAISE EXCEPTION 'Das Gebiet ist ungueltig.' USING ERRCODE = 'check_violation';
  END IF;
  FOR v_p IN SELECT * FROM jsonb_array_elements(coalesce(p_gebiet, '[]')) LOOP
    IF jsonb_typeof(v_p) <> 'array' OR jsonb_array_length(v_p) <> 2
       OR jsonb_typeof(v_p->0) <> 'number' OR jsonb_typeof(v_p->1) <> 'number'
       OR abs((v_p->>0)::numeric) > 90 OR abs((v_p->>1)::numeric) > 180 THEN
      RAISE EXCEPTION 'Das Gebiet enthaelt einen ungueltigen Punkt.' USING ERRCODE = 'check_violation';
    END IF;
  END LOOP;

  IF v_verwaltung THEN
    v_bilder := coalesce(p_bilder, '[]');
    IF jsonb_typeof(v_bilder) <> 'array' OR jsonb_array_length(v_bilder) > 5 THEN
      RAISE EXCEPTION 'Hoechstens 5 Bilder je Nachbarschaft.' USING ERRCODE = 'check_violation';
    END IF;
    FOR v_b IN SELECT * FROM jsonb_array_elements(v_bilder) LOOP
      IF position(v_ordner IN coalesce(v_b->>'url', '')) = 0 OR coalesce(v_b->>'url', '') !~ '^https://' THEN
        RAISE EXCEPTION 'Bilder muessen ueber die Pruefung hochgeladen werden.' USING ERRCODE = 'check_violation';
      END IF;
    END LOOP;
  ELSE
    SELECT p.bilder INTO v_bilder FROM public.nachbarschaft_profil p WHERE p.nachbarschaft = p_nachbarschaft;
    v_bilder := coalesce(v_bilder, '[]');
  END IF;

  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.nachbarschaft_profil (nachbarschaft, "tenantId", sichtbar, text, bilder, gebiet, ort, geaendert_von)
  VALUES (p_nachbarschaft, v_verein, coalesce(p_sichtbar, false), coalesce(p_text, '{}'), v_bilder,
          coalesce(p_gebiet, '[]'), nullif(btrim(coalesce(p_ort, '')), ''), v_wer)
  ON CONFLICT (nachbarschaft) DO UPDATE SET
    sichtbar = EXCLUDED.sichtbar, text = EXCLUDED.text, bilder = EXCLUDED.bilder, gebiet = EXCLUDED.gebiet,
    ort = EXCLUDED.ort, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;
END $$;

NOTIFY pgrst, 'reload schema';
