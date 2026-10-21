-- Zeilenregeln einmal auswerten, nicht je Zeile.
--
-- Der Vertreter einer Nachbarschaft kam auf "Nachbarschaft verwalten"
-- nicht weiter: Zeitueberschreitung. Gemessen, bei 380 Nutzern und 360
-- Zahlungen -- es ist also kein Mengenproblem:
--
--   SELECT * FROM users       8 587 ms
--   SELECT * FROM payments   17 149 ms
--
-- Die Maske holt beides gleichzeitig und verlaesst sich darauf, dass die
-- Zeilenregeln begrenzen. Zusammen reisst das jede Zeitgrenze.
--
-- ZWEI URSACHEN, und die zweite ist die schlimmere.
--
-- 1. JE ZEILE AUSGEWERTET. In den Regeln stehen die Pruefungen nackt da:
--    is_member_manager(), current_tenant(), is_neighborhood_steward().
--    Sie sind STABLE, aber PostgreSQL merkt sich ihr Ergebnis nicht
--    ueber Zeilen hinweg -- es ruft sie fuer jede der 380 Zeilen neu
--    auf, und jede macht ihre eigene Abfrage. Im Plan stand
--    "Rows Removed by Filter: 340" bei 8,5 Sekunden.
--
--    Steht derselbe Aufruf in einer Unterabfrage -- (SELECT fn()) --,
--    zieht der Planer ihn als InitPlan heraus und wertet ihn EINMAL je
--    Anweisung aus. Dieselbe Bedeutung, weil keine dieser Funktionen von
--    der Zeile abhaengt.
--
-- 2. VERSCHACHTELTE ZEILENREGELN. payments_read enthielt eine
--    Unterabfrage auf users -- und auf die wird users_select erneut
--    angewandt. 360 Zahlungen gegen 380 Nutzer, jeder mit eigenen
--    Funktionsaufrufen. Im Plan: ein Seq Scan on users mit 8,3 Sekunden
--    INNERHALB des Scans auf payments. Dagegen hilft keine
--    Klammerung, sondern nur eine Funktion, die die Zeilenregeln
--    umgeht -- SECURITY DEFINER, mit der Pruefung in sich.
--
-- WAS SICH NICHT AENDERN DARF: wer was sieht. Eine Regelaenderung, die
-- mehr zeigt als vorher, ist ein Sicherheitsvorfall und kein
-- Geschwindigkeitsgewinn. Darum wurde die heutige Sichtbarkeit fuer drei
-- Rollen vorher festgehalten (public._rls_vorher), und der Nachweis am
-- Ende vergleicht nicht Anzahlen, sondern die IDs selbst.

-- ------------------------------------------------- Vorher festhalten
--
-- Die heutige Sichtbarkeit, je Rolle. In EINER Transaktion mit der
-- Aenderung: eine Tabelle aus einer anderen Sitzung gehoert einer
-- anderen Rolle, und db push darf sie nicht lesen -- genau daran ist
-- der erste Versuch gescheitert.
--
-- Das kostet hier rund 80 Sekunden, weil genau das gemessen wird, was
-- zu langsam ist. Danach ist es schnell.
SET statement_timeout = '300s';

CREATE TEMP TABLE _rls_vorher(rolle text, tabelle text, ids text[]);

DO $vorher$
DECLARE
  r record; a text[]; b text[]; c text[]; d text[];
  v_eigen text := current_user;   -- siehe unten bei RESET
BEGIN
  FOR r IN SELECT * FROM (VALUES
      ('vertreter', 'a67428c3-7d5f-442a-88df-a0c917aaa612'),
      ('admin',     '03d3e041-2fac-4ce4-81a5-1663086e1b9c'),
      ('mitglied',  '040e6cfc-39e9-47bb-bae8-dda9f34e287a')
    ) AS t(rolle, uid)
  LOOP
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role', 'authenticated')::text, true);
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO a FROM public.users;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO b FROM public.payments;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO c FROM public.neighborhoods;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO d FROM public.families;
    -- NICHT reset role: das faellt auf die Anmelderolle zurueck
    -- (cli_login_postgres), und die besitzt die temporaere Tabelle
    -- nicht -- "permission denied for table _rls_vorher".
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    INSERT INTO _rls_vorher VALUES
      (r.rolle,'users',a), (r.rolle,'payments',b),
      (r.rolle,'neighborhoods',c), (r.rolle,'families',d);
    RAISE NOTICE 'vorher %: users %, payments %', r.rolle,
      coalesce(array_length(a,1),0), coalesce(array_length(b,1),0);
  END LOOP;
END $vorher$;


-- ------------------------------------------------- Der Helfer
--
-- Die Mitglieder meiner Nachbarschaften, an den Zeilenregeln vorbei.
-- Dieselbe Bedingung wie bisher in der Unterabfrage -- nur ohne dass
-- dabei users_select 360 mal mitlaeuft.
CREATE OR REPLACE FUNCTION public.vertreter_mitglieder()
RETURNS TABLE (id text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id
    FROM public.users u
   WHERE public.is_neighborhood_steward()
     AND u."tenantId" = public.current_tenant()
     AND u."neighborhoodId" IN (SELECT public.my_neighborhoods());
$$;

REVOKE ALL ON FUNCTION public.vertreter_mitglieder() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_mitglieder() TO authenticated;


-- ------------------------------------------------- users
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
USING (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR ((SELECT public.is_neighborhood_steward())
      AND "tenantId" = (SELECT public.current_tenant())
      AND "neighborhoodId" IN (SELECT public.my_neighborhoods()))
  OR id = (SELECT auth.uid()::text)
  OR "authUserId" = (SELECT auth.uid()::text)
  OR ((SELECT auth.jwt() ->> 'email') IS NOT NULL
      AND lower(email) = lower((SELECT auth.jwt() ->> 'email')))
);

DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
USING (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR ((SELECT public.is_neighborhood_steward())
      AND "tenantId" = (SELECT public.current_tenant())
      AND "neighborhoodId" IN (SELECT public.my_neighborhoods())
      AND coalesce(role, 'MEMBER') = 'MEMBER')
  OR id = (SELECT auth.uid()::text)
  OR "authUserId" = (SELECT auth.uid()::text)
)
WITH CHECK (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR ((SELECT public.is_neighborhood_steward())
      AND "tenantId" = (SELECT public.current_tenant())
      AND "neighborhoodId" IN (SELECT public.my_neighborhoods())
      AND coalesce(role, 'MEMBER') = 'MEMBER')
  OR ((id = (SELECT auth.uid()::text) OR "authUserId" = (SELECT auth.uid()::text))
      AND coalesce(role, 'MEMBER') = coalesce((SELECT public.app_role()), 'MEMBER'))
);

DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users FOR DELETE TO authenticated
USING ((SELECT public.is_staff()) AND "tenantId" = (SELECT public.current_tenant()));

DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
WITH CHECK (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR (id = (SELECT auth.uid()::text)
      AND coalesce(role, 'MEMBER') = ANY (ARRAY[(SELECT public.claimable_role()), 'MEMBER']))
);


-- ------------------------------------------------- payments
DROP POLICY IF EXISTS payments_read ON public.payments;
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
USING (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR "userId" = (SELECT public.current_user_row_id())
  -- Hier stand die Unterabfrage auf users. Jetzt der Helfer: dieselbe
  -- Menge, aber ohne dass users_select je Zahlung mitlaeuft.
  OR ((SELECT public.is_neighborhood_steward())
      AND "tenantId" = (SELECT public.current_tenant())
      AND "userId" IN (SELECT public.vertreter_mitglieder()))
);

DROP POLICY IF EXISTS payments_write ON public.payments;
CREATE POLICY payments_write ON public.payments FOR ALL TO authenticated
USING ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
WITH CHECK ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()));


-- ------------------------------------------------- neighborhoods
DROP POLICY IF EXISTS neighborhoods_manage ON public.neighborhoods;
CREATE POLICY neighborhoods_manage ON public.neighborhoods FOR ALL TO authenticated
USING ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
WITH CHECK ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()));

DROP POLICY IF EXISTS neighborhoods_public_read ON public.neighborhoods;
CREATE POLICY neighborhoods_public_read ON public.neighborhoods FOR SELECT
USING ("tenantId" = (SELECT coalesce(public.current_tenant(), public.request_tenant())));


-- ------------------------------------------------- families
DROP POLICY IF EXISTS families_lesen ON public.families;
CREATE POLICY families_lesen ON public.families FOR SELECT TO authenticated
USING (
  "tenantId" = (SELECT public.current_tenant())
  AND (SELECT public.modul_aktiv('STAMMBAUM'))
  AND ((SELECT public.is_member_manager())
       OR ((SELECT public.is_neighborhood_steward())
           AND anker IN (SELECT public.vertreter_mitglieder())))
);

DROP POLICY IF EXISTS families_schreiben ON public.families;
CREATE POLICY families_schreiben ON public.families FOR ALL TO authenticated
USING ("tenantId" = (SELECT public.current_tenant())
       AND (SELECT public.is_member_manager())
       AND (SELECT public.modul_aktiv('STAMMBAUM')))
WITH CHECK ("tenantId" = (SELECT public.current_tenant())
       AND (SELECT public.is_member_manager())
       AND (SELECT public.modul_aktiv('STAMMBAUM')));


-- ------------------------------------------------- Nachweis
--
-- Verglichen werden nicht Anzahlen, sondern die IDs selbst. Zwei Mengen
-- gleicher Groesse koennen verschiedene Menschen enthalten -- und genau
-- das waere der Fehler, den eine Zaehlung durchliesse.
DO $nachweis$
DECLARE
  r record;
  a text[]; b text[]; c text[]; d text[];
  v_soll text[];
  v_eigen text := current_user;
  v_fehler text := '';
  v_start timestamptz;
  v_ms numeric;
BEGIN
  IF (SELECT count(*) FROM _rls_vorher) <> 12 THEN
    RAISE EXCEPTION 'Die Momentaufnahme ist unvollstaendig (% von 12 Zeilen). Ohne sie '
                    'ist nicht nachweisbar, dass sich die Sichtbarkeit nicht geaendert hat.',
                    (SELECT count(*) FROM _rls_vorher);
  END IF;

  FOR r IN SELECT * FROM (VALUES
      ('vertreter', 'a67428c3-7d5f-442a-88df-a0c917aaa612'),
      ('admin',     '03d3e041-2fac-4ce4-81a5-1663086e1b9c'),
      ('mitglied',  '040e6cfc-39e9-47bb-bae8-dda9f34e287a')
    ) AS t(rolle, uid)
  LOOP
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role', 'authenticated')::text, true);
    v_start := clock_timestamp();
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO a FROM public.users;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO b FROM public.payments;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO c FROM public.neighborhoods;
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO d FROM public.families;
    v_ms := extract(milliseconds FROM clock_timestamp() - v_start)
          + 1000 * extract(second FROM clock_timestamp() - v_start);
    -- Schreiben und Vergleichen als Eigentuemer: unter der angenommenen
    -- Rolle greift die Zeilenregel der Pruefungstabelle selbst.
    -- NICHT reset role: das faellt auf die Anmelderolle zurueck
    -- (cli_login_postgres), und die besitzt die temporaere Tabelle
    -- nicht -- "permission denied for table _rls_vorher".
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);

    FOR v_soll IN
      SELECT ids FROM _rls_vorher WHERE rolle = r.rolle AND tabelle = 'users'
    LOOP
      IF a IS DISTINCT FROM v_soll THEN
        v_fehler := v_fehler || format('%s/users: %s statt %s Zeilen; ',
          r.rolle, coalesce(array_length(a,1),0), coalesce(array_length(v_soll,1),0));
      END IF;
    END LOOP;
    FOR v_soll IN
      SELECT ids FROM _rls_vorher WHERE rolle = r.rolle AND tabelle = 'payments'
    LOOP
      IF b IS DISTINCT FROM v_soll THEN
        v_fehler := v_fehler || format('%s/payments: %s statt %s Zeilen; ',
          r.rolle, coalesce(array_length(b,1),0), coalesce(array_length(v_soll,1),0));
      END IF;
    END LOOP;
    FOR v_soll IN
      SELECT ids FROM _rls_vorher WHERE rolle = r.rolle AND tabelle = 'neighborhoods'
    LOOP
      IF c IS DISTINCT FROM v_soll THEN
        v_fehler := v_fehler || format('%s/neighborhoods abweichend; ', r.rolle);
      END IF;
    END LOOP;
    FOR v_soll IN
      SELECT ids FROM _rls_vorher WHERE rolle = r.rolle AND tabelle = 'families'
    LOOP
      IF d IS DISTINCT FROM v_soll THEN
        v_fehler := v_fehler || format('%s/families abweichend; ', r.rolle);
      END IF;
    END LOOP;

    RAISE NOTICE 'Rolle %: alle vier Abfragen in % ms (vorher allein users 8587 ms, payments 17149 ms)',
      r.rolle, round(v_ms);
  END LOOP;

  IF v_fehler <> '' THEN
    RAISE EXCEPTION 'Die Sichtbarkeit hat sich geaendert — %', v_fehler;
  END IF;

  DROP TABLE _rls_vorher;
  RAISE NOTICE 'Zeilenregeln: Sichtbarkeit unveraendert fuer Vertreter, Administration und Mitglied.';
END $nachweis$;
