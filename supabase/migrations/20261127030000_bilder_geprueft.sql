-- Geprueftte Bilder fuer die Nachbarschaften: hoechstens 5, und nur solche,
-- die die Funktion bild-pruefen erzeugt hat.
--
-- Warum serverseitig: was im Browser verkleinert und geprueft wird, laesst
-- sich umgehen -- jeder angemeldete Benutzer kann eine Datei direkt in den
-- Speicher legen. bild-pruefen prueft das Format an den ersten Bytes,
-- zerlegt das Bild in Pixel und schreibt daraus ein neues JPEG. Was immer
-- in der Datei steckte (Skript, eingebettete Daten, Metadaten mit
-- GPS-Ort), ist danach weg: es bleiben nur Pixel.
--
-- Damit das gilt, darf niemand ausser dieser Funktion in den Ordner
-- geprueft/ schreiben. Die Funktion schreibt mit dem Dienstschluessel, der
-- an den Zeilenregeln vorbeigeht; fuer alle anderen sperren die Regeln den
-- Ordner. Und die Datenbank nimmt fuer eine Nachbarschaft nur Adressen aus
-- genau ihrem Unterordner an.

-- 1. Speicher: der Ordner geprueft/ ist fuer direktes Hochladen gesperrt.
DROP POLICY IF EXISTS uploads_insert ON storage.objects;
CREATE POLICY uploads_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'uploads' AND name NOT LIKE 'geprueft/%');

DROP POLICY IF EXISTS uploads_update ON storage.objects;
CREATE POLICY uploads_update ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'uploads' AND name NOT LIKE 'geprueft/%' AND ((owner = auth.uid()) OR public.is_member_manager()))
  WITH CHECK (bucket_id = 'uploads' AND name NOT LIKE 'geprueft/%');

-- 2. Darf der Aufrufer fuer diese Nachbarschaft ein Bild hinzufuegen?
-- Gibt den Verein zurueck (fuer den Ablageort) und prueft dieselben
-- Rechte wie das Speichern.
CREATE OR REPLACE FUNCTION public.nachbarschaft_bild_erlaubt(p_nachbarschaft text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL OR NOT EXISTS (SELECT 1 FROM public.neighborhoods n
       WHERE n.id = p_nachbarschaft AND n."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Diese Nachbarschaft gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_member_manager() OR p_nachbarschaft IN (SELECT id FROM public.my_neighborhoods())) THEN
    RAISE EXCEPTION 'Nur Verwaltung, Vorstand und die Vertreter dieser Nachbarschaft.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_verein;
END $$;
REVOKE ALL ON FUNCTION public.nachbarschaft_bild_erlaubt(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nachbarschaft_bild_erlaubt(text) TO authenticated;

-- 3. Speichern: hoechstens 5 Bilder, alle aus dem eigenen geprueften Ordner.
CREATE OR REPLACE FUNCTION public.nachbarschaft_profil_speichern(
  p_nachbarschaft text, p_text jsonb, p_bilder jsonb, p_gebiet jsonb, p_ort text, p_sichtbar boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.nachbarschaft_bild_erlaubt(p_nachbarschaft);
  v_wer text; v_p jsonb; v_b jsonb;
  v_ordner text := '/storage/v1/object/public/uploads/geprueft/nachbarschaften/' || v_verein || '/' || p_nachbarschaft || '/';
BEGIN
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

  IF jsonb_typeof(coalesce(p_bilder, '[]')) <> 'array' OR jsonb_array_length(coalesce(p_bilder, '[]')) > 5 THEN
    RAISE EXCEPTION 'Hoechstens 5 Bilder je Nachbarschaft.' USING ERRCODE = 'check_violation';
  END IF;
  FOR v_b IN SELECT * FROM jsonb_array_elements(coalesce(p_bilder, '[]')) LOOP
    IF position(v_ordner IN coalesce(v_b->>'url', '')) = 0 OR coalesce(v_b->>'url', '') !~ '^https://' THEN
      RAISE EXCEPTION 'Bilder muessen ueber die Pruefung hochgeladen werden.' USING ERRCODE = 'check_violation';
    END IF;
  END LOOP;

  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.nachbarschaft_profil (nachbarschaft, "tenantId", sichtbar, text, bilder, gebiet, ort, geaendert_von)
  VALUES (p_nachbarschaft, v_verein, coalesce(p_sichtbar, false), coalesce(p_text, '{}'), coalesce(p_bilder, '[]'),
          coalesce(p_gebiet, '[]'), nullif(btrim(coalesce(p_ort, '')), ''), v_wer)
  ON CONFLICT (nachbarschaft) DO UPDATE SET
    sichtbar = EXCLUDED.sichtbar, text = EXCLUDED.text, bilder = EXCLUDED.bilder, gebiet = EXCLUDED.gebiet,
    ort = EXCLUDED.ort, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;
END $$;

NOTIFY pgrst, 'reload schema';
