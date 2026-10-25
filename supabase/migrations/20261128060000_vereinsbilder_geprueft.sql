-- Alle Website-Bilder ueber die Pruefung (bild-pruefen), nicht nur die der
-- Nachbarschaften: Logo, Startbilder, Vorstand, Neuigkeiten, Chronik,
-- Seiten. Darf der Aufrufer fuer seinen Verein ein solches Bild ablegen?
-- Dieselben Rechte wie beim Bearbeiten der Website: is_staff + darf_schreiben.
CREATE OR REPLACE FUNCTION public.vereinsbild_erlaubt(p_zweck text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF p_zweck NOT IN ('logo','branding','hero','live','board','news','chronik','seiten') THEN
    RAISE EXCEPTION 'Unbekannter Zweck.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_verein IS NULL OR NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand laden Website-Bilder hoch.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_verein;
END $$;
REVOKE ALL ON FUNCTION public.vereinsbild_erlaubt(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vereinsbild_erlaubt(text) TO authenticated;
NOTIFY pgrst, 'reload schema';
