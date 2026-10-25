-- Stammbaum: einfacher herausnehmen, Anrede fuer die Bezeichnungen.
--
-- 1. Herausnehmen war muehsam: jede Beziehung einzeln loesen, und hing der
--    Familienname an der Person, verschwand er mit ihr. Jetzt ein Aufruf,
--    der alle Beziehungen einer Person loest und den Namen an einen
--    bisherigen Angehoerigen weitergibt, der noch in der Familie steht.
--
--    SECURITY INVOKER: es gelten dieselben Zeilenregeln wie beim Loeschen
--    einzelner Beziehungen -- die Funktion faßt sie nur zusammen und gibt
--    niemandem ein Recht, das er nicht schon hat.
--
-- 2. Die Uebersicht liefert die Anrede mit. Damit heisst die Mutter Mutter
--    und nicht Elternteil, sofern die Anrede erfasst ist.

CREATE OR REPLACE FUNCTION public.stammbaum_person_loesen(p_person text)
RETURNS integer
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_angehoerige text[];
  v_neu text;
  v_n integer;
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur die Verwaltung und der Vorstand pflegen den Stammbaum.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT array_agg(DISTINCT CASE WHEN von = p_person THEN nach ELSE von END)
    INTO v_angehoerige
    FROM public.family_links
   WHERE (von = p_person OR nach = p_person) AND "tenantId" = public.current_tenant();

  DELETE FROM public.family_links
   WHERE (von = p_person OR nach = p_person) AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;

  -- Der Name der Familie haengt an einer Ankerperson. War es diese, geht er
  -- an einen Angehoerigen, der noch mit jemandem verbunden ist.
  IF EXISTS (SELECT 1 FROM public.families WHERE anker = p_person) THEN
    SELECT a INTO v_neu FROM unnest(coalesce(v_angehoerige, '{}')) a
     WHERE EXISTS (SELECT 1 FROM public.family_links f WHERE f.von = a OR f.nach = a)
       AND NOT EXISTS (SELECT 1 FROM public.families f WHERE f.anker = a)
     LIMIT 1;
    IF v_neu IS NOT NULL THEN
      UPDATE public.families SET anker = v_neu WHERE anker = p_person;
    ELSE
      DELETE FROM public.families WHERE anker = p_person;
    END IF;
  END IF;

  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.stammbaum_person_loesen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.stammbaum_person_loesen(text) TO authenticated;

-- Uebersicht mit Anrede. Neue Spalte, deshalb ablegen und neu anlegen.
DROP FUNCTION IF EXISTS public.familien_uebersicht();
CREATE OR REPLACE FUNCTION public.familien_uebersicht()
RETURNS TABLE (
  familie text, familienname text, familie_id uuid,
  person text, name text, nachname text,
  nachbarschaft text, strasse text, plz text, ort text, geburtsdatum text,
  eltern jsonb, partner jsonb, kinder jsonb, geschwister jsonb,
  anrede text
)
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE
  kanten AS (
    SELECT von AS a, nach AS b FROM public.family_links
    UNION ALL
    SELECT nach, von FROM public.family_links
  ),
  lauf(start, erreicht) AS (
    SELECT u.id, u.id FROM public.users u
    UNION
    SELECT l.start, k.b FROM lauf l JOIN kanten k ON k.a = l.erreicht
  ),
  gruppe AS (
    SELECT start AS person, min(erreicht) AS familie FROM lauf GROUP BY start
  ),
  benannt AS (
    SELECT g.familie, f.name, f.id,
           row_number() OVER (PARTITION BY g.familie ORDER BY f.geaendert_am DESC) AS rang
      FROM public.families f JOIN gruppe g ON g.person = f.anker
  )
  SELECT
    g.familie, b.name, b.id,
    u.id, u."displayName", u."lastName",
    n.name, u.street, u.zip, u.city, u.birthdate,
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', e.von, 'name', eu."displayName"))
                FROM public.family_links e JOIN public.users eu ON eu.id = e.von
               WHERE e.nach = u.id AND e.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', p.id, 'name', p."displayName"))
                FROM public.family_links f2
                JOIN public.users p ON p.id = CASE WHEN f2.von = u.id THEN f2.nach ELSE f2.von END
               WHERE f2.art = 'PARTNER' AND (f2.von = u.id OR f2.nach = u.id)), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', k.nach, 'name', ku."displayName"))
                FROM public.family_links k JOIN public.users ku ON ku.id = k.nach
               WHERE k.von = u.id AND k.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', gs.id, 'name', gs."displayName"))
                FROM public.family_links f3
                JOIN public.users gs ON gs.id = CASE WHEN f3.von = u.id THEN f3.nach ELSE f3.von END
               WHERE f3.art = 'GESCHWISTER' AND (f3.von = u.id OR f3.nach = u.id)), '[]'::jsonb),
    u.salutation
    FROM gruppe g
    JOIN public.users u ON u.id = g.person
    LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
    LEFT JOIN benannt b ON b.familie = g.familie AND b.rang = 1
   ORDER BY g.familie, u."displayName";
END $$;
REVOKE ALL ON FUNCTION public.familien_uebersicht() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.familien_uebersicht() TO authenticated;

-- Probe: anon darf beides nicht.
DO $$
DECLARE v_eigen text := current_user; v_ok boolean;
BEGIN
  SET LOCAL ROLE anon;
  BEGIN
    PERFORM public.stammbaum_person_loesen('x');
    v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT v_ok THEN RAISE EXCEPTION 'anon darf stammbaum_person_loesen aufrufen'; END IF;
  RAISE NOTICE 'Stammbaum: Herausnehmen und Anrede bereit.';
END $$;

NOTIFY pgrst, 'reload schema';
