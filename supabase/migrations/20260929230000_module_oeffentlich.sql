-- Welche Module laufen bei dem Verein dieser Adresse?
--
-- marktplatz_uebersicht() beantwortet das nur fuer den Vorstand. Die
-- Navigation braucht es aber fuer jeden Besucher: ohne gebuchtes Modul
-- gehoert kein Verweis auf Spenden oder Videos in die Leiste, und mit
-- gebuchtem Modul gehoert er hinein. Bisher fehlte er in beiden Faellen.
--
-- Herausgegeben werden nur die Schluessel, nicht Preise oder Zustaende --
-- welche Seiten ein Verein hat, sieht man ohnehin an seiner Website.
CREATE OR REPLACE FUNCTION public.module_oeffentlich()
RETURNS TABLE (schluessel text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.schluessel FROM public.modules m
   WHERE m.status <> 'EINGESTELLT'
     AND public.modul_aktiv(m.schluessel)
   ORDER BY m.reihenfolge;
$$;
REVOKE ALL ON FUNCTION public.module_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.module_oeffentlich() TO anon, authenticated;

DO $$
DECLARE v_back text := current_user; r record; v_liste text;
BEGIN
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT string_agg(schluessel, ', ' ORDER BY schluessel) INTO v_liste
    FROM public.module_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Ein Besucher von koretini.me sieht: %', v_liste;

  -- Ohne bekannte Adresse darf nichts herauskommen.
  PERFORM set_config('request.headers', json_build_object('origin','https://fremd.example.org')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO r FROM public.module_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);
END $$;
