-- Welche Module laufen auf dieser Domain?
--
-- Die Zeilenregeln sperren die Daten bereits -- eine abgeschaltete
-- Neuigkeiten-Seite zeigt 0 Beitraege. Aber der Verweis im Menue bleibt
-- stehen und fuehrt auf eine leere Seite; das sieht nach Fehler aus.
--
-- Herausgegeben werden ausschliesslich die Schluessel der aktiven Module --
-- keine Preise, keine Zustaende, kein Hinweis darauf, was ein Verein
-- gebucht und wieder abbestellt hat.
CREATE OR REPLACE FUNCTION public.oeffentliche_module()
RETURNS TABLE (schluessel text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.schluessel FROM public.modules m
   WHERE public.modul_aktiv(m.schluessel)
     AND m.status <> 'EINGESTELLT';
$$;
REVOKE ALL ON FUNCTION public.oeffentliche_module() FROM public;
GRANT EXECUTE ON FUNCTION public.oeffentliche_module() TO anon, authenticated;

DO $$
DECLARE v_back text := current_user; r record;
BEGIN
  SET LOCAL ROLE anon;
  PERFORM set_config('request.headers',
    json_build_object('origin','https://koretini.me')::text, true);
  FOR r IN SELECT schluessel FROM public.oeffentliche_module() ORDER BY 1 LOOP
    RAISE NOTICE '  aktiv auf koretini.me: %', r.schluessel;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);
END $$;
