-- Mehrere Vertreter in einer Nachbarschaft, jeder fuer seine Leute.
--
-- Bisher sah jeder, der in einer Nachbarschaft hinterlegt ist, alle ihre
-- Mitglieder. Wunsch des Vereins: Einer ist fuer die in Kosovo zustaendig,
-- einer fuer die Schweiz, einer fuer Deutschland.
--
-- Entscheid der Vereinsfuehrung:
--   * Zugeteilt wird pro Mitglied (users.betreuer). Das Land hilft nur beim
--     Zuteilen: Bei Koretini haben 257 von 354 Mitgliedern kein Land, und
--     dasselbe Land steht verschieden drin (Schweiz, Switzerland, CH). Eine
--     reine Landregel liesse die meisten durchfallen.
--   * Wer keinem Vertreter zugeteilt ist, sehen alle Vertreter seiner
--     Nachbarschaft -- wie bisher. Fuer Koretini aendert sich damit nichts,
--     bis jemand zuteilt.
--
-- Die Grenze zieht wie immer die Datenbank. Alle Wege der Vertreter an
-- Mitglieder laufen ueber vertreter_sieht(); vertreter_mitglieder() und die
-- Zeilenregeln an users, payment_reports und family_links benutzen sie.

-- ------------------------------------------------------------ Spalte
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS betreuer text;
-- Ohne Fremdschluessel: das Zuruecksetzen des Demovereins legt die
-- Mitglieder in beliebiger Reihenfolge wieder an. Eine Zuteilung auf
-- jemanden, den es nicht mehr gibt, gilt ohnehin als keine
-- (vertreter_sieht).
CREATE INDEX IF NOT EXISTS users_betreuer ON public.users ("tenantId", betreuer);

-- Der Vertreter selbst darf seine Zuteilung nicht aendern -- sonst holte er
-- sich fremde Mitglieder oder schoebe eigene ab.
CREATE OR REPLACE FUNCTION public.vertreter_felder_gesperrt()
RETURNS text[] LANGUAGE sql IMMUTABLE AS $$
  SELECT ARRAY['id','tenantId','authUserId','role','neighborhoodId','membershipStatus','betreuer'];
$$;

-- ------------------------------------------------------------ Laender
-- Ein Code je Land, egal wie es eingetragen wurde.
CREATE OR REPLACE FUNCTION public.land_code(p text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN v = '' THEN NULL
    WHEN v IN ('CH','SCHWEIZ','SWITZERLAND','SUISSE','SVIZZERA','ZVICRA','ZVICËR','ZVICER') THEN 'CH'
    WHEN v IN ('DE','DEUTSCHLAND','GERMANY','GJERMANI','GJERMANIA','ALLEMAGNE') THEN 'DE'
    WHEN v IN ('XK','KOSOVO','KOSOVA','KOSOVË','KOSOVE') THEN 'XK'
    WHEN v IN ('AT','ÖSTERREICH','OESTERREICH','AUSTRIA','AUSTRI') THEN 'AT'
    WHEN v IN ('NL','HOLLAND','NIEDERLANDE','NETHERLANDS','HOLANDA','HOLANDË') THEN 'NL'
    WHEN v IN ('FR','FRANKREICH','FRANCE','FRANCA','FRANCË') THEN 'FR'
    WHEN v IN ('IT','ITALIEN','ITALY','ITALIA','ITALI') THEN 'IT'
    WHEN v IN ('AL','ALBANIEN','ALBANIA','SHQIPËRI','SHQIPERI','SHQIPERIA') THEN 'AL'
    WHEN v IN ('MK','NORDMAZEDONIEN','MAZEDONIEN','NORTH MACEDONIA','MAQEDONI') THEN 'MK'
    WHEN v IN ('SE','SCHWEDEN','SWEDEN','SUEDI') THEN 'SE'
    WHEN v IN ('BE','BELGIEN','BELGIUM','BELGJIKË','BELGJIKE') THEN 'BE'
    WHEN v IN ('GB','UK','ENGLAND','GROSSBRITANNIEN','UNITED KINGDOM','ANGLI') THEN 'GB'
    WHEN v IN ('US','USA','AMERIKA','UNITED STATES','SHBA') THEN 'US'
    ELSE v END
  FROM (SELECT upper(btrim(coalesce(p, ''))) AS v) x;
$$;

-- Fuer welche Laender ein Vertreter in einer Nachbarschaft zustaendig ist.
-- Nur Hilfe beim Zuteilen, keine Sichtregel.
CREATE TABLE IF NOT EXISTS public.vertreter_gebiet (
  "tenantId"       text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "neighborhoodId" text NOT NULL,
  person           text NOT NULL,
  laender          text[] NOT NULL DEFAULT '{}',
  "geaendertVon"   text,
  "geaendertAm"    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("tenantId", "neighborhoodId", person)
);
ALTER TABLE public.vertreter_gebiet ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vertreter_gebiet FROM anon, authenticated;

-- ------------------------------------------------------------ Sichtregel
-- Ist diese Person in dieser Nachbarschaft hinterlegt? Dieselben drei Wege
-- wie my_neighborhoods().
CREATE OR REPLACE FUNCTION public.ist_vertreter_von(p_nb text, p_person text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p_person IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.neighborhoods n
     WHERE n.id = p_nb
       AND (n."representativeId" = p_person OR n."managerId" = p_person
            OR coalesce(n."contactPersonIds", '[]'::jsonb) @> to_jsonb(p_person)));
$$;

-- Sieht der angemeldete Vertreter ein Mitglied mit dieser Nachbarschaft und
-- diesem Betreuer? Zeigt die Zuteilung auf jemanden, der dort nicht mehr
-- hinterlegt ist, gilt das Mitglied als nicht zugeteilt -- sonst saehe es
-- nach einem Wechsel niemand mehr.
--
-- Mit Spalten statt einer Kennung, damit die Pruefung beim Aendern die
-- NEUE Zeile beurteilt und nicht den Stand davor.
CREATE OR REPLACE FUNCTION public.vertreter_sieht(p_nb text, p_betreuer text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p_nb IN (SELECT public.my_neighborhoods())
     AND (p_betreuer IS NULL
          OR p_betreuer = public.current_user_row_id()
          OR NOT public.ist_vertreter_von(p_nb, p_betreuer));
$$;
REVOKE ALL ON FUNCTION public.ist_vertreter_von(text, text) FROM public, anon;
REVOKE ALL ON FUNCTION public.vertreter_sieht(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.ist_vertreter_von(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vertreter_sieht(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.vertreter_mitglieder()
RETURNS TABLE(id text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id
    FROM public.users u
   WHERE public.is_neighborhood_steward()
     AND u."tenantId" = public.current_tenant()
     AND public.vertreter_sieht(u."neighborhoodId", u.betreuer);
$$;

-- ------------------------------------------------------------ Zeilenregeln
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
  USING (
    ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
    OR ((SELECT public.is_neighborhood_steward())
        AND "tenantId" = (SELECT public.current_tenant())
        AND public.vertreter_sieht("neighborhoodId", betreuer))
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
        AND public.vertreter_sieht("neighborhoodId", betreuer)
        AND COALESCE(role, 'MEMBER') = 'MEMBER')
    OR id = (SELECT auth.uid()::text)
    OR "authUserId" = (SELECT auth.uid()::text)
  )
  WITH CHECK (
    ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
    OR ((SELECT public.is_neighborhood_steward())
        AND "tenantId" = (SELECT public.current_tenant())
        AND public.vertreter_sieht("neighborhoodId", betreuer)
        AND COALESCE(role, 'MEMBER') = 'MEMBER')
    OR ((id = (SELECT auth.uid()::text) OR "authUserId" = (SELECT auth.uid()::text))
        AND COALESCE(role, 'MEMBER') = COALESCE((SELECT public.app_role()), 'MEMBER'))
  );

DROP POLICY IF EXISTS payment_reports_insert ON public.payment_reports;
CREATE POLICY payment_reports_insert ON public.payment_reports FOR INSERT TO authenticated
  WITH CHECK (
    "tenantId" = public.current_tenant()
    AND "reportedBy" = public.current_user_row_id()
    AND status = 'OPEN' AND "decidedBy" IS NULL AND "decidedAt" IS NULL
    AND (public.is_member_manager()
         OR (public.is_neighborhood_steward()
             AND "paymentId" IN (SELECT p.id FROM public.payments p
                                  WHERE p."userId" IN (SELECT public.vertreter_mitglieder()))))
  );

DROP POLICY IF EXISTS family_links_lesen ON public.family_links;
CREATE POLICY family_links_lesen ON public.family_links FOR SELECT TO authenticated
  USING (
    "tenantId" = public.current_tenant()
    AND public.modul_aktiv('STAMMBAUM')
    AND (public.is_member_manager()
         OR (public.is_neighborhood_steward()
             AND (von IN (SELECT public.vertreter_mitglieder())
                  OR nach IN (SELECT public.vertreter_mitglieder()))))
  );

-- ------------------------------------------------------------ Funktionen
-- Melden und Neuerfassen: dieselbe Grenze. Der Text der Funktionen wird
-- uebernommen und nur an der einen Stelle ersetzt.
DO $$
DECLARE v_def text; v_neu text;
BEGIN
  v_def := pg_get_functiondef('public.mitglied_melden'::regproc);
  v_neu := replace(v_def,
    'AND u."neighborhoodId" IN (SELECT public.my_neighborhoods())',
    'AND public.vertreter_sieht(u."neighborhoodId", u.betreuer)');
  IF v_neu = v_def THEN RAISE EXCEPTION 'mitglied_melden: Stelle nicht gefunden'; END IF;
  EXECUTE v_neu;

  -- Wer vor Ort jemanden aufnimmt, ist fuer ihn zustaendig.
  SELECT string_agg(pg_get_functiondef(p.oid), '') INTO v_def
    FROM pg_proc p WHERE p.proname = 'vertreter_mitglied_anlegen'
     AND p.pronamespace = 'public'::regnamespace;
  v_neu := replace(v_def,
    '"invoiceDeliveryMethod", "internalNotes")',
    '"invoiceDeliveryMethod", "internalNotes", betreuer)');
  v_neu := replace(v_neu,
    '|| '' am '' || to_char(now(), ''DD.MM.YYYY''));',
    '|| '' am '' || to_char(now(), ''DD.MM.YYYY''), public.current_user_row_id());');
  IF v_neu = v_def OR position('internalNotes", betreuer)' in v_neu) = 0
     OR position('current_user_row_id());' in v_neu) = 0 THEN
    RAISE EXCEPTION 'vertreter_mitglied_anlegen: Stelle nicht gefunden';
  END IF;
  EXECUTE v_neu;
END $$;

-- ------------------------------------------------------------ Verwaltung
CREATE OR REPLACE FUNCTION public._zustaendigkeit_pruefen()
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_member_manager() OR public.is_platform_admin()) OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand teilen Mitglieder zu.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_verein;
END $$;
REVOKE ALL ON FUNCTION public._zustaendigkeit_pruefen() FROM public, anon, authenticated;

-- Je Vertreter einer Nachbarschaft: Laender, Zahl der Zugeteilten; dazu je
-- Nachbarschaft, wie viele noch niemandem zugeteilt sind.
CREATE OR REPLACE FUNCTION public.zustaendigkeit_stand()
RETURNS TABLE (r_nachbarschaft text, r_name text, r_person text, r_person_name text,
               r_laender text[], r_zugeteilt int, r_offen int, r_mitglieder int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH z AS (
    SELECT DISTINCT n.id AS nb, n.name AS nb_name, p AS person
      FROM public.neighborhoods n
      CROSS JOIN LATERAL (
        SELECT n."representativeId" AS p
        UNION SELECT n."managerId"
        UNION SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb))
      ) x
     WHERE n."tenantId" = public.current_tenant()
       AND p IS NOT NULL AND btrim(p) <> ''
       AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = p)
  ),
  m AS (
    SELECT u.id, u."neighborhoodId" AS nb,
           CASE WHEN public.ist_vertreter_von(u."neighborhoodId", u.betreuer)
                THEN u.betreuer END AS betreuer
      FROM public.users u
     WHERE u."tenantId" = public.current_tenant()
       AND coalesce(u."membershipStatus", 'ACTIVE') <> 'INACTIVE'
  )
  SELECT z.nb, z.nb_name, z.person,
         coalesce(u."displayName", trim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",'')), z.person),
         coalesce(g.laender, '{}'),
         (SELECT count(*)::int FROM m WHERE m.nb = z.nb AND m.betreuer = z.person),
         (SELECT count(*)::int FROM m WHERE m.nb = z.nb AND m.betreuer IS NULL),
         (SELECT count(*)::int FROM m WHERE m.nb = z.nb)
    FROM z
    LEFT JOIN public.users u ON u.id = z.person
    LEFT JOIN public.vertreter_gebiet g
           ON g."tenantId" = public.current_tenant() AND g."neighborhoodId" = z.nb AND g.person = z.person
   WHERE public.is_member_manager() OR public.is_platform_admin()
   ORDER BY z.nb_name, 4;
$$;

-- Die Mitglieder einer Nachbarschaft mit Land und Zuteilung.
CREATE OR REPLACE FUNCTION public.zustaendigkeit_mitglieder(p_nb text)
RETURNS TABLE (r_id text, r_name text, r_land text, r_ort text, r_betreuer text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id,
         coalesce(u."displayName", trim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         public.land_code(u.country), u.city,
         CASE WHEN public.ist_vertreter_von(u."neighborhoodId", u.betreuer) THEN u.betreuer END
    FROM public.users u
   WHERE u."tenantId" = public.current_tenant()
     AND u."neighborhoodId" = p_nb
     AND coalesce(u."membershipStatus", 'ACTIVE') <> 'INACTIVE'
     AND (public.is_member_manager() OR public.is_platform_admin())
   ORDER BY 2;
$$;

-- Mitglieder einem Vertreter zuteilen, oder mit NULL die Zuteilung loesen.
CREATE OR REPLACE FUNCTION public.betreuer_setzen(p_mitglieder text[], p_betreuer text)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._zustaendigkeit_pruefen(); v_falsch text; v_n int;
BEGIN
  IF p_betreuer IS NOT NULL THEN
    SELECT string_agg(coalesce(u."displayName", u.id), ', ') INTO v_falsch
      FROM public.users u
     WHERE u.id = ANY (p_mitglieder) AND u."tenantId" = v_verein
       AND NOT public.ist_vertreter_von(u."neighborhoodId", p_betreuer);
    IF v_falsch IS NOT NULL THEN
      RAISE EXCEPTION 'Diese Person ist in der Nachbarschaft von % nicht als Vertreter hinterlegt.', v_falsch
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  UPDATE public.users u SET betreuer = p_betreuer
   WHERE u.id = ANY (p_mitglieder) AND u."tenantId" = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END $$;

-- Die Laender eines Vertreters in einer Nachbarschaft.
CREATE OR REPLACE FUNCTION public.vertreter_gebiet_setzen(p_nb text, p_person text, p_laender text[])
RETURNS text[]
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._zustaendigkeit_pruefen(); v_l text[];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.neighborhoods n WHERE n.id = p_nb AND n."tenantId" = v_verein)
     OR NOT public.ist_vertreter_von(p_nb, p_person) THEN
    RAISE EXCEPTION 'Diese Person ist in dieser Nachbarschaft nicht als Vertreter hinterlegt.'
      USING ERRCODE = 'check_violation';
  END IF;
  SELECT coalesce(array_agg(DISTINCT c ORDER BY c), '{}') INTO v_l
    FROM (SELECT public.land_code(x) AS c FROM unnest(coalesce(p_laender, '{}')) x) y
   WHERE c IS NOT NULL;
  INSERT INTO public.vertreter_gebiet ("tenantId", "neighborhoodId", person, laender, "geaendertVon", "geaendertAm")
  VALUES (v_verein, p_nb, p_person, v_l, public.current_user_row_id(), now())
  ON CONFLICT ("tenantId", "neighborhoodId", person) DO UPDATE
     SET laender = EXCLUDED.laender, "geaendertVon" = EXCLUDED."geaendertVon", "geaendertAm" = now();
  RETURN v_l;
END $$;

-- Alle noch nicht Zugeteilten nach ihrem Land verteilen. Passt ein Land zu
-- genau einem Vertreter, bekommt er das Mitglied; passt es zu keinem oder
-- zu mehreren, bleibt es offen. Bestehende Zuteilungen bleiben unberuehrt.
CREATE OR REPLACE FUNCTION public.nach_land_zuteilen(p_nb text)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._zustaendigkeit_pruefen(); v_n int;
BEGIN
  WITH kandidat AS (
    SELECT u.id, min(g.person) AS person, count(*) AS anzahl
      FROM public.users u
      JOIN public.vertreter_gebiet g
        ON g."tenantId" = v_verein AND g."neighborhoodId" = u."neighborhoodId"
       AND public.land_code(u.country) = ANY (g.laender)
       AND public.ist_vertreter_von(u."neighborhoodId", g.person)
     WHERE u."tenantId" = v_verein AND u."neighborhoodId" = p_nb
       AND NOT public.ist_vertreter_von(u."neighborhoodId", u.betreuer)
     GROUP BY u.id
  )
  UPDATE public.users u SET betreuer = k.person
    FROM kandidat k
   WHERE u.id = k.id AND k.anzahl = 1;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END $$;

-- Fuer den Vertreter selbst: wofuer er zustaendig ist.
CREATE OR REPLACE FUNCTION public.meine_zustaendigkeit()
RETURNS TABLE (r_nachbarschaft text, r_name text, r_laender text[], r_eigene int, r_offen int, r_kollegen int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT n.id, n.name, coalesce(g.laender, '{}'),
         (SELECT count(*)::int FROM public.users u
           WHERE u."neighborhoodId" = n.id AND u.betreuer = public.current_user_row_id()),
         (SELECT count(*)::int FROM public.users u
           WHERE u."neighborhoodId" = n.id AND u."tenantId" = n."tenantId"
             AND NOT public.ist_vertreter_von(n.id, u.betreuer)),
         (SELECT count(*)::int - 1 FROM (
            SELECT n."representativeId" AS p UNION SELECT n."managerId"
            UNION SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb))) x
           WHERE p IS NOT NULL AND btrim(p) <> '')
    FROM public.neighborhoods n
    LEFT JOIN public.vertreter_gebiet g
           ON g."tenantId" = n."tenantId" AND g."neighborhoodId" = n.id
          AND g.person = public.current_user_row_id()
   WHERE n.id IN (SELECT public.my_neighborhoods())
   ORDER BY n.name;
$$;

REVOKE ALL ON FUNCTION public.zustaendigkeit_stand() FROM public, anon;
REVOKE ALL ON FUNCTION public.zustaendigkeit_mitglieder(text) FROM public, anon;
REVOKE ALL ON FUNCTION public.betreuer_setzen(text[], text) FROM public, anon;
REVOKE ALL ON FUNCTION public.vertreter_gebiet_setzen(text, text, text[]) FROM public, anon;
REVOKE ALL ON FUNCTION public.nach_land_zuteilen(text) FROM public, anon;
REVOKE ALL ON FUNCTION public.meine_zustaendigkeit() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zustaendigkeit_stand() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zustaendigkeit_mitglieder(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.betreuer_setzen(text[], text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vertreter_gebiet_setzen(text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nach_land_zuteilen(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.meine_zustaendigkeit() TO authenticated;

-- ------------------------------------------------------------ Demoverein
-- Lagjja e Epërme hat vier Vertreter. Xhevat betreut Kosovo, Arta die
-- Schweiz, Astrit Deutschland; Blerta hat kein Land und sieht nur, wer
-- noch niemandem zugeteilt ist.
UPDATE public.users SET country = 'Deutschland'
 WHERE "tenantId" = 'demo' AND id IN ('demo-u17', 'demo-u23');
UPDATE public.users SET country = 'Kosovo'
 WHERE "tenantId" = 'demo' AND id IN ('demo-u20');

INSERT INTO public.vertreter_gebiet ("tenantId", "neighborhoodId", person, laender)
SELECT 'demo', 'demo-lagje-2', p, l
  FROM (VALUES ('demo-v01', ARRAY['XK']),
               ('1e292d76-a0ac-4dec-98df-836ff794cc76', ARRAY['CH']),
               ('demo-u21', ARRAY['DE'])) v(p, l)
 WHERE EXISTS (SELECT 1 FROM public.users u WHERE u.id = v.p)
   AND public.ist_vertreter_von('demo-lagje-2', v.p)
ON CONFLICT DO NOTHING;

-- Zuteilen wie der Knopf: offene mit passendem Land. Leonora (Vorstand) und
-- zwei weitere bleiben offen, damit die Verwaltung die Liste sieht.
WITH kandidat AS (
  SELECT u.id, min(g.person) AS person, count(*) AS anzahl
    FROM public.users u
    JOIN public.vertreter_gebiet g
      ON g."tenantId" = 'demo' AND g."neighborhoodId" = u."neighborhoodId"
     AND public.land_code(u.country) = ANY (g.laender)
   WHERE u."tenantId" = 'demo' AND u."neighborhoodId" = 'demo-lagje-2'
     AND u.betreuer IS NULL
     AND u.id NOT IN ('demo-u02', 'demo-u14', 'demo-u11')
     AND u.id NOT IN ('demo-v01', '1e292d76-a0ac-4dec-98df-836ff794cc76')
   GROUP BY u.id
)
UPDATE public.users u SET betreuer = k.person
  FROM kandidat k WHERE u.id = k.id AND k.anzahl = 1;

-- Den Demostand neu als Vorlage sichern, sonst holte das Zuruecksetzen die
-- Zuteilung nicht zurueck. Die neue Tabelle nimmt _demo_tabellen() von
-- selbst auf (sie hat tenantId).
DO $$
DECLARE v_betreiber text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;
  SELECT email INTO v_betreiber FROM public.platform_admins LIMIT 1;
  PERFORM set_config('request.jwt.claims', json_build_object('email', v_betreiber, 'role', 'authenticated')::text, true);
  PERFORM public.demo_vorlage_speichern();
  PERFORM set_config('request.jwt.claims', '', true);
END $$;

-- ------------------------------------------------------------ Selbsttest
DO $$
DECLARE v_x int; v_a int; v_b int; v_alle int; v_fremd int; v_eigen text := current_user;
BEGIN
  -- Xhevat
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', (SELECT "authUserId" FROM public.users WHERE id = 'demo-v01'),
                      'email', (SELECT email FROM public.users WHERE id = 'demo-v01'),
                      'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_x FROM public.users WHERE "neighborhoodId" = 'demo-lagje-2';
  SELECT count(*) INTO v_fremd FROM public.users
   WHERE "neighborhoodId" = 'demo-lagje-2' AND betreuer IS NOT NULL AND betreuer <> 'demo-v01';
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  PERFORM set_config('request.jwt.claims', '', true);
  SELECT count(*) INTO v_alle FROM public.users WHERE "neighborhoodId" = 'demo-lagje-2';
  SELECT count(*) INTO v_b FROM public.users
   WHERE "neighborhoodId" = 'demo-lagje-2' AND (betreuer IS NULL OR betreuer = 'demo-v01');
  RAISE NOTICE 'Xhevat sieht % von % (erwartet %), fremde Zugeteilte: %', v_x, v_alle, v_b, v_fremd;
  IF (SELECT "authUserId" FROM public.users WHERE id = 'demo-v01') IS NOT NULL THEN
    IF v_fremd <> 0 OR v_x <> v_b THEN
      RAISE EXCEPTION 'Selbsttest: Xhevat sieht falsche Mitglieder';
    END IF;
  END IF;
  SELECT count(*) INTO v_a FROM public.users WHERE "tenantId" = 'demo' AND betreuer IS NOT NULL;
  RAISE NOTICE 'Demo: % Mitglieder zugeteilt', v_a;
END $$;

NOTIFY pgrst, 'reload schema';
