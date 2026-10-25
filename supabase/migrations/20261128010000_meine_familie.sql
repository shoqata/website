-- "Meine Familie" fuer Mitglieder.
--
-- Mitglieder lesen family_links nicht (Zeilenregel: Verwaltung und
-- Vertreter). Diese Funktion gibt ihnen genau ihre eigene Familie: die
-- Gruppe, die ueber erfasste Beziehungen mit ihnen zusammenhaengt -- und von
-- jeder Person nur Name, Geburtsjahr und Anrede. Keine Adresse, kein
-- Telefon, kein Geburtstag; wer mit wem verwandt ist, sieht das Mitglied,
-- mehr nicht. Vom Betreiber so freigegeben (2026-10-25).

CREATE OR REPLACE FUNCTION public.meine_familie()
RETURNS TABLE (
  person text, name text, nachname text, geburtsjahr text, anrede text,
  familienname text, eltern jsonb, partner jsonb, kinder jsonb, geschwister jsonb, ich boolean
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text := public.current_user_row_id();
  v_verein text := public.current_tenant();
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL OR NOT public.modul_aktiv('STAMMBAUM') THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH RECURSIVE
  kanten AS (
    SELECT von AS a, nach AS b FROM public.family_links WHERE "tenantId" = v_verein
    UNION ALL
    SELECT nach, von FROM public.family_links WHERE "tenantId" = v_verein
  ),
  gruppe(id) AS (
    SELECT v_ich
    UNION
    SELECT k.b FROM gruppe g JOIN kanten k ON k.a = g.id
  ),
  drin AS (SELECT g.id FROM gruppe g),
  -- Nur Beziehungen innerhalb der eigenen Familie.
  fl AS (SELECT f.* FROM public.family_links f
          WHERE f."tenantId" = v_verein AND f.von IN (SELECT id FROM drin) AND f.nach IN (SELECT id FROM drin))
  SELECT
    u.id, u."displayName", u."lastName",
    substring(coalesce(u.birthdate, '') FROM '(\d{4})'),
    u.salutation,
    (SELECT fa.name FROM public.families fa WHERE fa.anker IN (SELECT id FROM drin)
      ORDER BY fa.geaendert_am DESC LIMIT 1),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', e.von, 'name', eu."displayName"))
                FROM fl e JOIN public.users eu ON eu.id = e.von
               WHERE e.nach = u.id AND e.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', p.id, 'name', p."displayName"))
                FROM fl f2 JOIN public.users p ON p.id = CASE WHEN f2.von = u.id THEN f2.nach ELSE f2.von END
               WHERE f2.art = 'PARTNER' AND (f2.von = u.id OR f2.nach = u.id)), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', k.nach, 'name', ku."displayName"))
                FROM fl k JOIN public.users ku ON ku.id = k.nach
               WHERE k.von = u.id AND k.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', gs.id, 'name', gs."displayName"))
                FROM fl f3 JOIN public.users gs ON gs.id = CASE WHEN f3.von = u.id THEN f3.nach ELSE f3.von END
               WHERE f3.art = 'GESCHWISTER' AND (f3.von = u.id OR f3.nach = u.id)), '[]'::jsonb),
    u.id = v_ich
  FROM public.users u
  WHERE u.id IN (SELECT id FROM drin) AND u."tenantId" = v_verein
  ORDER BY u."displayName";
END $$;
REVOKE ALL ON FUNCTION public.meine_familie() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.meine_familie() TO authenticated;

DO $$
DECLARE v_eigen text := current_user; v_ok boolean;
BEGIN
  SET LOCAL ROLE anon;
  BEGIN PERFORM public.meine_familie(); v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true; END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT v_ok THEN RAISE EXCEPTION 'anon darf meine_familie aufrufen'; END IF;
END $$;

NOTIFY pgrst, 'reload schema';
