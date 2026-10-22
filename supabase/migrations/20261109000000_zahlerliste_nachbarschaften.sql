-- Zahlerliste und Beitragsstatistik je Nachbarschaft.
--
-- Der Verein stellt ein (settings.system -> 'zahlerliste'):
--   sichtbar         AUS | MITGLIEDER | OEFFENTLICH
--   inhalt           STATISTIK | NAMEN
--   nachbarschaften  true | false  -- aufgeteilt nach Nachbarschaft
--
-- Wie bei beitragsstand_oeffentlich() wirkt die Einstellung HIER und nicht
-- im Browser: steht sie auf MITGLIEDER, bekommt ein Besucher ohne Anmeldung
-- nur die Auskunft, dass es die Liste fuer Mitglieder gibt -- keine Zahl,
-- keinen Namen. Und der Widerspruch eines Mitglieds (nicht_oeffentlich)
-- gilt auch in der Mitgliederliste: er nimmt den Namen heraus, die Zahl
-- zaehlt ihn weiter, weil eine Summe niemanden benennt.
--
-- Gezaehlt wird, wer im Jahr eine bezahlte Rechnung hat; die Grundmenge sind
-- alle nicht entfernten Mitglieder (membershipStatus <> INACTIVE). Gaeste
-- und Mitglieder ohne Rechnung zaehlen mit -- sonst sahe eine Nachbarschaft,
-- in der niemand eine Rechnung bekam, vollzaehlig aus.

CREATE OR REPLACE FUNCTION public.zahlerliste(p_jahr int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := coalesce(public.current_tenant(), public.request_tenant());
  v_jahr   int  := coalesce(p_jahr, extract(year FROM current_date)::int);
  v_cfg    jsonb;
  v_sicht  text;
  v_namen  boolean;
  v_nb     boolean;
  v_mitglied boolean;
  v_basis  jsonb;
BEGIN
  IF v_verein IS NULL THEN RETURN jsonb_build_object('sichtbar', 'AUS'); END IF;

  SELECT s.system -> 'zahlerliste' INTO v_cfg
    FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'system';
  v_sicht := upper(coalesce(v_cfg ->> 'sichtbar', 'AUS'));
  v_namen := upper(coalesce(v_cfg ->> 'inhalt', 'STATISTIK')) = 'NAMEN';
  v_nb    := coalesce((v_cfg ->> 'nachbarschaften')::boolean, false);

  IF v_sicht NOT IN ('MITGLIEDER', 'OEFFENTLICH') THEN
    RETURN jsonb_build_object('sichtbar', 'AUS');
  END IF;

  v_mitglied := public.is_platform_admin()
    OR EXISTS (SELECT 1 FROM public.users u
                WHERE u.id = public.current_user_row_id() AND u."tenantId" = v_verein
                  AND coalesce(u."membershipStatus", '') <> 'INACTIVE');
  IF v_sicht = 'MITGLIEDER' AND NOT v_mitglied THEN
    RETURN jsonb_build_object('sichtbar', 'MITGLIEDER', 'gesperrt', true);
  END IF;

  WITH m AS (
    SELECT u.id, u."neighborhoodId" AS nb, coalesce(u.nicht_oeffentlich, false) AS verborgen,
           coalesce(nullif(btrim(u."displayName"), ''),
                    btrim(coalesce(u."firstName", '') || ' ' || coalesce(u."lastName", ''))) AS name,
           EXISTS (SELECT 1 FROM public.payments p
                    WHERE p."userId" = u.id AND p."tenantId" = v_verein AND p.status = 'PAID'
                      AND coalesce(p."billingYear", extract(year FROM p."timestamp")::int) = v_jahr) AS bezahlt
      FROM public.users u
     WHERE u."tenantId" = v_verein
       AND coalesce(u."membershipStatus", '') <> 'INACTIVE'
       AND coalesce(u.role, 'MEMBER') <> 'GUEST'
  )
  SELECT jsonb_build_object(
    'sichtbar', v_sicht, 'jahr', v_jahr, 'namen_an', v_namen, 'nachbarschaften_an', v_nb,
    'gesamt', (SELECT count(*) FROM m),
    'bezahlt', (SELECT count(*) FROM m WHERE m.bezahlt),
    'namen', CASE WHEN v_namen AND NOT v_nb THEN
        (SELECT coalesce(jsonb_agg(m.name ORDER BY m.name), '[]') FROM m
          WHERE m.bezahlt AND NOT m.verborgen AND m.name <> '') END,
    'nachbarschaften', CASE WHEN v_nb THEN (
        SELECT coalesce(jsonb_agg(x ORDER BY x.sort, x.name), '[]') FROM (
          SELECT coalesce(n.name, 'Ohne Nachbarschaft') AS name, (n.id IS NULL)::int AS sort,
                 count(*) AS gesamt, count(*) FILTER (WHERE m.bezahlt) AS bezahlt,
                 CASE WHEN v_namen THEN coalesce(
                   jsonb_agg(m.name ORDER BY m.name) FILTER (WHERE m.bezahlt AND NOT m.verborgen AND m.name <> ''),
                   '[]') END AS namen
            FROM m LEFT JOIN public.neighborhoods n ON n.id = m.nb AND n."tenantId" = v_verein
           GROUP BY n.id, n.name) x) END
  ) INTO v_basis;

  RETURN v_basis;
END $$;
REVOKE ALL ON FUNCTION public.zahlerliste(int) FROM public;
GRANT EXECUTE ON FUNCTION public.zahlerliste(int) TO anon, authenticated;

-- Eigene Seiten: angemeldete Benutzer sahen veroeffentlichte Seiten ALLER
-- Vereine (status = OEFFENTLICH ohne Vereinsbedingung). In der Fusszeile und
-- jetzt in der Kopfzeile tauchten damit fremde Seiten auf.
DROP POLICY IF EXISTS seiten_intern ON public.seiten;
CREATE POLICY seiten_intern ON public.seiten FOR SELECT TO authenticated
USING (
  (status = 'OEFFENTLICH' AND "tenantId" = (SELECT coalesce(public.current_tenant(), public.request_tenant())))
  OR ("tenantId" = (SELECT public.current_tenant())
      AND ((SELECT public.is_platform_admin()) OR (SELECT public.is_staff())))
);

-- Selbsttest: Einstellung je Stufe, als Besucher und als Mitglied.
DO $$
DECLARE v_eigen text := current_user; v_alt jsonb; r jsonb; v_auth text;
BEGIN
  SELECT system INTO v_alt FROM public.settings WHERE "tenantId" = 'demo' AND id = 'system';
  SELECT "authUserId" INTO v_auth FROM public.users WHERE id = 'demo-u05';

  UPDATE public.settings SET system = coalesce(system, '{}') || '{"zahlerliste":{"sichtbar":"MITGLIEDER","inhalt":"NAMEN","nachbarschaften":true}}'
   WHERE "tenantId" = 'demo' AND id = 'system';

  -- Besucher ohne Anmeldung auf demo.unityhub.li
  PERFORM set_config('request.headers', '{"origin":"https://demo.unityhub.li"}', true);
  PERFORM set_config('request.jwt.claims', '{"role":"anon"}', true);
  SET LOCAL ROLE anon;
  r := public.zahlerliste();
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT coalesce((r ->> 'gesperrt')::boolean, false) OR r ? 'bezahlt' THEN
    RAISE EXCEPTION 'Selbsttest: Besucher sieht die Mitgliederliste: %', r;
  END IF;

  -- Mitglied
  IF v_auth IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_auth, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    r := public.zahlerliste();
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF r ? 'gesperrt' OR jsonb_array_length(r -> 'nachbarschaften') = 0 THEN
      RAISE EXCEPTION 'Selbsttest: Mitglied bekommt keine Liste: %', r;
    END IF;
  END IF;

  -- Oeffentlich, nur Statistik: keine Namen
  UPDATE public.settings SET system = system || '{"zahlerliste":{"sichtbar":"OEFFENTLICH","inhalt":"STATISTIK","nachbarschaften":true}}'
   WHERE "tenantId" = 'demo' AND id = 'system';
  PERFORM set_config('request.jwt.claims', '{"role":"anon"}', true);
  SET LOCAL ROLE anon;
  r := public.zahlerliste();
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF r -> 'nachbarschaften' -> 0 -> 'namen' <> 'null'::jsonb OR r -> 'namen' <> 'null'::jsonb THEN
    RAISE EXCEPTION 'Selbsttest: Statistik verraet Namen: %', r;
  END IF;

  UPDATE public.settings SET system = v_alt WHERE "tenantId" = 'demo' AND id = 'system';
END $$;
