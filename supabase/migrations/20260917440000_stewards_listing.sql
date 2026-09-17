-- Wer wird im Adminbereich kuenftig als verantwortlich angezeigt?
--
-- Die Oberflaeche liest dieselben drei Felder wie my_neighborhoods(). Diese
-- Aufstellung zeigt, was dabei herauskommt -- damit die Anzeige nachpruefbar
-- ist und nicht bloss plausibel aussieht.
DO $$
DECLARE r record; v_n int := 0; v_tot int;
BEGIN
  SELECT count(*) INTO v_tot FROM public.neighborhoods;
  RAISE NOTICE '=== Zuordnungen ueber alle % Nachbarschaften ===', v_tot;

  FOR r IN
    SELECT n.name AS nb, k AS person_id,
           coalesce(u."displayName", '<keine Mitgliedszeile>') AS person,
           coalesce(u.role, '-') AS rolle,
           CASE WHEN n."contactPersonIds" @> to_jsonb(k) THEN 'contactPersonIds'
                WHEN n."representativeId" = k THEN 'representativeId (alt)'
                ELSE 'managerId (alt)' END AS herkunft
      FROM public.neighborhoods n
      CROSS JOIN LATERAL (
        SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb)) AS k
        UNION SELECT n."representativeId" WHERE n."representativeId" IS NOT NULL
        UNION SELECT n."managerId"        WHERE n."managerId"        IS NOT NULL
      ) z
      LEFT JOIN public.users u ON u.id = z.k
     ORDER BY n.name
  LOOP
    v_n := v_n + 1;
    RAISE NOTICE '  % -> % [%] via %', r.nb, r.person, r.rolle, r.herkunft;
  END LOOP;

  RAISE NOTICE '  insgesamt % Zuordnungen', v_n;

  RAISE NOTICE '=== Davon wirksam (Person existiert als Mitglied) ===';
  v_n := 0;
  FOR r IN
    SELECT DISTINCT u."displayName" AS person, coalesce(u.role,'-') AS rolle,
           count(*) OVER (PARTITION BY u.id) AS anzahl
      FROM public.neighborhoods n
      JOIN public.users u
        ON n."contactPersonIds" @> to_jsonb(u.id)
        OR n."representativeId" = u.id
        OR n."managerId"        = u.id
  LOOP
    v_n := v_n + 1;
    RAISE NOTICE '  % [Rolle %] fuehrt % Nachbarschaft(en)', r.person, r.rolle, r.anzahl;
  END LOOP;
  IF v_n = 0 THEN
    RAISE NOTICE '  keine -- solange niemand zugeordnet ist, hat auch niemand diese Rechte';
  END IF;
END $$;
