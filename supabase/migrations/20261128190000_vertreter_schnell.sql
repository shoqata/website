-- Betreuer-Ansicht: "canceling statement due to statement timeout".
--
-- Ein Betreuer (Besart Selmani, Koretini) oeffnete "Meine Nachbarschaft
-- verwalten" und bekam nach acht Sekunden den Abbruch. Bei 383
-- Mitgliedern und 30 Nachbarschaften -- die Tabellen sind winzig, die
-- Rechnung war es nicht:
--
--   users_select   ruft vertreter_sieht() fuer JEDE Mitgliederzeile auf,
--   vertreter_sieht   ruft my_neighborhoods() auf,
--   my_neighborhoods  ruft current_user_row_id() fuer JEDE Nachbarschaft
--                     auf (und current_tenant(), das es noch einmal ruft),
--   current_user_row_id  sucht ueber "authUserId = x OR id = x" -- ohne
--                     passenden Index ein Durchlauf ueber alle Mitglieder.
--
-- Also rund 383 x 30 x 2 x 383 Zeilen fuer eine einzige Abfrage. Der
-- Vorstand merkt davon nichts: fuer ihn greift der erste Zweig der Regel
-- (is_member_manager), und der Rest wird nicht ausgewertet.
--
-- Die Abhilfe aendert nicht, WER was sieht, nur WIE OFT es gerechnet wird:
--
-- 1. my_neighborhoods() bestimmt die eigene Zeile und den Verein EINMAL.
-- 2. vertreter_mitglieder() rechnet die sichtbaren Mitglieder als Menge,
--    mit derselben Bedingung wie vertreter_sieht().
-- 3. users_select und der USING-Teil von users_update fragen
--    "id IN (SELECT vertreter_mitglieder())" -- unabhaengig von der Zeile,
--    also einmal je Abfrage statt einmal je Zeile.
--    WITH CHECK von users_update behaelt vertreter_sieht(): dort zaehlen
--    die NEUEN Werte (ein Betreuer darf niemanden in eine fremde
--    Nachbarschaft schieben), und es geht um eine einzige Zeile.
-- 4. Ein Index auf "authUserId" fuer current_user_row_id().

CREATE INDEX IF NOT EXISTS users_authuserid_idx ON public.users ("authUserId");

CREATE OR REPLACE FUNCTION public.my_neighborhoods()
 RETURNS TABLE(id text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  WITH ich AS MATERIALIZED (
    SELECT public.current_user_row_id() AS id, public.current_tenant() AS verein
  )
  SELECT n.id
    FROM public.neighborhoods n, ich
   WHERE ich.id IS NOT NULL
     AND n."tenantId" = ich.verein
     AND (
          (n."contactPersonIds" IS NOT NULL
             AND n."contactPersonIds" @> to_jsonb(ich.id))
       OR n."representativeId" = ich.id
       OR n."managerId"        = ich.id
     )
  UNION
  -- Nur zum Vorfuehren: der Betreiber im Demo-Verein.
  SELECT n.id
    FROM public.neighborhoods n
   WHERE n."tenantId" = 'demo'
     AND (SELECT public.is_platform_admin())
     AND (SELECT coalesce(public.current_tenant(), public.request_tenant())) = 'demo';
$function$;

CREATE OR REPLACE FUNCTION public.vertreter_mitglieder()
 RETURNS TABLE(id text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  -- Dieselbe Bedingung wie vertreter_sieht(), als Menge gerechnet:
  -- in einer eigenen Nachbarschaft, und betreut entweder von niemandem,
  -- von mir, oder von jemandem, der dort nicht (mehr) Vertreter ist.
  WITH ich AS MATERIALIZED (
    SELECT public.current_user_row_id() AS id, public.current_tenant() AS verein
  ), meine AS MATERIALIZED (
    SELECT m.id FROM public.my_neighborhoods() m
  )
  SELECT u.id
    FROM public.users u, ich
   WHERE u."tenantId" = ich.verein
     AND u."neighborhoodId" IN (SELECT meine.id FROM meine)
     AND (u.betreuer IS NULL
          OR u.betreuer = ich.id
          OR NOT public.ist_vertreter_von(u."neighborhoodId", u.betreuer));
$function$;

CREATE OR REPLACE FUNCTION public.vertreter_sieht(p_nb text, p_betreuer text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT p_nb IN (SELECT m.id FROM public.my_neighborhoods() m)
     AND (p_betreuer IS NULL
          OR p_betreuer = public.current_user_row_id()
          OR NOT public.ist_vertreter_von(p_nb, p_betreuer));
$function$;

ALTER POLICY users_select ON public.users USING (
  ((( SELECT is_member_manager()) AND ("tenantId" = ( SELECT current_tenant()))))
  OR (( SELECT is_neighborhood_steward()) AND ("tenantId" = ( SELECT current_tenant()))
      AND (id IN ( SELECT vertreter_mitglieder())))
  OR (id = ( SELECT (auth.uid())::text))
  OR ("authUserId" = ( SELECT (auth.uid())::text))
  OR ((( SELECT (auth.jwt() ->> 'email'::text)) IS NOT NULL)
      AND (lower(email) = lower(( SELECT (auth.jwt() ->> 'email'::text)))))
);

ALTER POLICY users_update ON public.users USING (
  ((( SELECT is_member_manager()) AND ("tenantId" = ( SELECT current_tenant()))))
  OR (( SELECT is_neighborhood_steward()) AND ("tenantId" = ( SELECT current_tenant()))
      AND (id IN ( SELECT vertreter_mitglieder()))
      AND (COALESCE(role, 'MEMBER'::text) = 'MEMBER'::text))
  OR (id = ( SELECT (auth.uid())::text))
  OR ("authUserId" = ( SELECT (auth.uid())::text))
);
-- WITH CHECK von users_update bleibt, wie es ist (siehe 3.).

-- Selbsttest: vertreter_mitglieder() und vertreter_sieht() muessen fuer
-- jeden Betreuer dieselben Mitglieder liefern. Geprueft fuer alle
-- Vertreter aller Vereine, mit deren Kennung als angemeldeter Person.
DO $$
DECLARE v record; a int; b int; fehler int := 0; geprueft int := 0;
BEGIN
  FOR v IN
    SELECT DISTINCT u.id, u."authUserId", u."tenantId"
      FROM public.users u
      JOIN public.neighborhoods n ON n."tenantId" = u."tenantId"
       AND (n."representativeId" = u.id OR n."managerId" = u.id
            OR coalesce(n."contactPersonIds", '[]'::jsonb) @> to_jsonb(u.id))
     WHERE u."authUserId" IS NOT NULL
  LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v."authUserId", 'role', 'authenticated')::text, true);
    SELECT count(*) INTO a FROM public.vertreter_mitglieder();
    SELECT count(*) INTO b FROM public.users u
     WHERE u."tenantId" = public.current_tenant()
       AND public.vertreter_sieht(u."neighborhoodId", u.betreuer);
    geprueft := geprueft + 1;
    IF a <> b THEN
      fehler := fehler + 1;
      RAISE NOTICE 'Abweichung bei %: Menge % / je Zeile %', v.id, a, b;
    END IF;
  END LOOP;
  PERFORM set_config('request.jwt.claims', '', true);
  RAISE NOTICE 'Betreuer geprueft: %, Abweichungen: %', geprueft, fehler;
  IF fehler > 0 THEN RAISE EXCEPTION 'vertreter_mitglieder weicht ab'; END IF;
END $$;
