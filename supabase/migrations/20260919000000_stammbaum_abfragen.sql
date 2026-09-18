-- Abfragen zum Stammbaum.

-- --- Wer haengt mit wem zusammen? -----------------------------------------
-- Eine Familie ist keine gespeicherte Einheit, sondern ergibt sich: alle
-- Personen, die ueber Eltern- oder Partnerbeziehungen erreichbar sind. Als
-- Kennung dient die kleinste Personennummer in der Gruppe -- stabil, solange
-- niemand austritt, und ohne eine zweite Wahrheit einzufuehren.
CREATE OR REPLACE FUNCTION public.familien_uebersicht()
RETURNS TABLE (
  familie text, person text, name text, nachname text,
  nachbarschaft text, strasse text, plz text, ort text,
  geburtsdatum text, eltern jsonb, partner jsonb, kinder jsonb
)
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE
  kanten AS (
    -- ungerichtet betrachtet, damit die Gruppe in beide Richtungen waechst
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
  )
  SELECT
    g.familie, u.id, u."displayName", u."lastName",
    n.name, u.street, u.zip, u.city, u.birthdate,
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', e.von, 'name', eu."displayName"))
                FROM public.family_links e JOIN public.users eu ON eu.id = e.von
               WHERE e.nach = u.id AND e.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', p.id, 'name', p."displayName"))
                FROM public.family_links f
                JOIN public.users p ON p.id = CASE WHEN f.von = u.id THEN f.nach ELSE f.von END
               WHERE f.art = 'PARTNER' AND (f.von = u.id OR f.nach = u.id)), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', k.nach, 'name', ku."displayName"))
                FROM public.family_links k JOIN public.users ku ON ku.id = k.nach
               WHERE k.von = u.id AND k.art = 'ELTERNTEIL'), '[]'::jsonb)
    FROM gruppe g
    JOIN public.users u ON u.id = g.person
    LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
   ORDER BY g.familie, u."displayName";
END $$;

-- --- Woraus laesst sich ein Anfang machen? --------------------------------
-- Erfasst ist noch nichts. Gemessen teilen sich aber 37 Gruppen eine
-- Adresse -- das sind echte Haushalte und der naheliegende Ausgangspunkt.
-- Vorgeschlagen, nicht angelegt: wer mit wem verwandt ist, weiss nur ein
-- Mensch.
CREATE OR REPLACE FUNCTION public.haushalt_vorschlaege()
RETURNS TABLE (
  strasse text, plz text, ort text, anzahl bigint,
  nachbarschaft text, personen jsonb, schon_verknuepft boolean
)
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH haushalte AS (
    SELECT btrim(u.street) AS s, btrim(u.zip) AS z, btrim(u.city) AS o,
           count(*) AS n,
           min(coalesce(nb.name, '')) AS nachb,
           jsonb_agg(jsonb_build_object(
             'id', u.id, 'name', u."displayName",
             'nachname', u."lastName", 'geburtsdatum', u.birthdate)
             ORDER BY u."displayName") AS leute,
           array_agg(u.id) AS ids
      FROM public.users u
      LEFT JOIN public.neighborhoods nb ON nb.id = u."neighborhoodId"
     WHERE coalesce(btrim(u.street),'') <> '' AND coalesce(btrim(u.zip),'') <> ''
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     GROUP BY 1,2,3 HAVING count(*) > 1
  )
  SELECT h.s, h.z, h.o, h.n, h.nachb, h.leute,
         EXISTS (SELECT 1 FROM public.family_links f
                  WHERE f.von = ANY(h.ids) AND f.nach = ANY(h.ids))
    FROM haushalte h
   ORDER BY h.n DESC, h.s;
END $$;

REVOKE ALL ON FUNCTION public.familien_uebersicht() FROM public, anon;
REVOKE ALL ON FUNCTION public.haushalt_vorschlaege() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.familien_uebersicht() TO authenticated;
GRANT EXECUTE ON FUNCTION public.haushalt_vorschlaege() TO authenticated;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.haushalt_vorschlaege();
  RAISE NOTICE 'Haushalte mit gemeinsamer Adresse: %', v_n;
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE 'Erfasste Beziehungen: %', v_n;
END $$;
