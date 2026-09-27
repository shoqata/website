-- Welche Startseite ein Besucher bekommt.
--
-- Zuerst war gedacht, das gebuchte Modul entscheide allein. Beim Probelauf
-- zeigte sich, warum das falsch waere: Koretini traegt alle_module_frei, das
-- Modul gilt dort also vom ersten Tag an als aktiv -- und die Startseite des
-- Vereins haette beim naechsten Ausliefern ungefragt gewechselt.
--
-- Also zwei Dinge, die beide stimmen muessen: das Modul bestimmt, ob die
-- Premium-Startseite ueberhaupt zur Wahl steht (und damit den Aufpreis), der
-- Verein bestimmt, wann er umschaltet. Entschieden wird das hier und nicht
-- im Browser -- sonst koennte ein Verein ohne Buchung die Seite durch einen
-- Eintrag in settings erzwingen.
CREATE OR REPLACE FUNCTION public.startseite_variante()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    WHEN public.modul_aktiv_oeffentlich('LANDINGPAGE')
     AND upper(coalesce(
           (SELECT s.system ->> 'startseiteVariante' FROM public.settings s
             WHERE s."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
               AND s.id = 'system'), 'STANDARD')) = 'PREMIUM'
    THEN 'PREMIUM' ELSE 'STANDARD' END;
$$;
REVOKE ALL ON FUNCTION public.startseite_variante() FROM public;
GRANT EXECUTE ON FUNCTION public.startseite_variante() TO anon, authenticated;

DO $$
DECLARE v_back text := current_user;
BEGIN
  PERFORM set_config('request.headers', json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  RAISE NOTICE 'koretini.me bekommt heute: %', public.startseite_variante();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);
END $$;
