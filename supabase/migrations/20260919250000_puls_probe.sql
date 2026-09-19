-- Zwei Fragen: liefert der Puls jedem dasselbe, und stimmt er mit der
-- Rechnung ueberein, die die Ansicht bisher clientseitig gemacht hat?
DO $$
DECLARE v_back text := current_user; r record; p record;
        v_jahr integer := extract(year FROM current_date)::integer;
        v_soll_gesamt int; v_soll_bezahlt int; v_soll_offen int; v_soll_ohne int;
BEGIN
  FOR r IN SELECT u."authUserId" AS uid, u.email, u."neighborhoodId" AS lagje,
                  coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u
            WHERE u."authUserId" IS NOT NULL AND u."neighborhoodId" IS NOT NULL
            ORDER BY 4, 2 LOOP

    -- Der Sollwert, unabhaengig von jeder Zeilenregel gerechnet.
    SELECT count(*) INTO v_soll_gesamt FROM public.users
     WHERE "neighborhoodId" = r.lagje AND coalesce("membershipStatus",'') <> 'INACTIVE';
    SELECT
      count(*) FILTER (WHERE x.bez),
      count(*) FILTER (WHERE x.n > 0 AND NOT x.bez),
      count(*) FILTER (WHERE x.n = 0)
      INTO v_soll_bezahlt, v_soll_offen, v_soll_ohne
      FROM (SELECT u.id,
                   bool_or(p2.status='PAID') AS bez,
                   count(p2.id) AS n
              FROM public.users u
              LEFT JOIN public.payments p2 ON p2."userId" = u.id
                AND coalesce(nullif(p2."billingYear",0),
                             extract(year FROM p2."timestamp")::integer) = v_jahr
             WHERE u."neighborhoodId" = r.lagje
               AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
             GROUP BY u.id) x;

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role','authenticated','email', r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT * INTO p FROM public.nachbarschaft_puls(v_jahr);
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);

    RAISE NOTICE '  % (%)', rpad(left(r.email,28),28), r.rolle;
    RAISE NOTICE '     Puls: % Mitglieder, % bezahlt, % offen, % ohne Rechnung',
      p.mitglieder, p.bezahlt, p.offen, p.ohne_rechnung;
    RAISE NOTICE '     Soll: % Mitglieder, % bezahlt, % offen, % ohne Rechnung  -> %',
      v_soll_gesamt, v_soll_bezahlt, v_soll_offen, v_soll_ohne,
      CASE WHEN p.mitglieder = v_soll_gesamt AND p.bezahlt = v_soll_bezahlt
            AND p.offen = v_soll_offen AND p.ohne_rechnung = v_soll_ohne
           THEN 'stimmt' ELSE 'WEICHT AB' END;
  END LOOP;

  -- Und anonym?
  SET LOCAL ROLE anon;
  BEGIN
    PERFORM * FROM public.nachbarschaft_puls();
    RAISE NOTICE '  anon: DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  anon: abgewiesen (%)', left(SQLERRM, 40);
  END;
  EXECUTE format('SET ROLE %I', v_back);
END $$;
