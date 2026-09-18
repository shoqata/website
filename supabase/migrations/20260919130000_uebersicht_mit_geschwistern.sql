-- Die Uebersicht kennt jetzt Geschwister und den Namen der Familie.
--
-- Die Rueckgabe bekommt neue Spalten, deshalb erst ablegen: PostgreSQL
-- laesst CREATE OR REPLACE den Rueckgabetyp nicht aendern.
DROP FUNCTION IF EXISTS public.familien_uebersicht();
CREATE OR REPLACE FUNCTION public.familien_uebersicht()
RETURNS TABLE (
  familie text, familienname text, familie_id uuid,
  person text, name text, nachname text,
  nachbarschaft text, strasse text, plz text, ort text, geburtsdatum text,
  eltern jsonb, partner jsonb, kinder jsonb, geschwister jsonb
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
  -- Der Name haengt an einer Ankerperson; er gilt fuer die ganze Gruppe, in
  -- der diese Person steht. Stehen zwei benannte Familien nach einer
  -- Verknuepfung in derselben Gruppe, gewinnt die zuletzt geaenderte -- und
  -- die Verwaltung sieht es, weil beide Namen weiterhin in families stehen.
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
               WHERE f3.art = 'GESCHWISTER' AND (f3.von = u.id OR f3.nach = u.id)), '[]'::jsonb)
    FROM gruppe g
    JOIN public.users u ON u.id = g.person
    LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
    LEFT JOIN benannt b ON b.familie = g.familie AND b.rang = 1
   ORDER BY g.familie, u."displayName";
END $$;

GRANT EXECUTE ON FUNCTION public.familien_uebersicht() TO authenticated;

DO $$
DECLARE v_n int; t0 timestamptz := clock_timestamp();
BEGIN
  SELECT count(*) INTO v_n FROM public.familien_uebersicht();
  RAISE NOTICE 'Uebersicht: % Zeilen in % ms', v_n,
    round(extract(epoch FROM clock_timestamp()-t0)*1000);
END $$;
