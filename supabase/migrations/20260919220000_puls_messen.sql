-- Was sieht ein angemeldetes Mitglied von seiner Nachbarschaft?
-- Der Community-Puls zaehlt die Zeilen, die users zurueckgibt -- was die
-- Zeilenregel nicht herausgibt, fehlt in der Quote.
DO $$
DECLARE v_back text := current_user; r record;
        v_uid text; v_mail text; v_id text; v_lagje text; v_n int; v_echt int;
BEGIN
  RAISE NOTICE '--- Regel auf users (SELECT) ---';
  FOR r IN SELECT policyname, left(qual::text, 220) AS q FROM pg_policies
            WHERE schemaname='public' AND tablename='users' AND cmd='SELECT' LOOP
    RAISE NOTICE '  %: %', r.policyname, r.q;
  END LOOP;

  FOR r IN SELECT u."authUserId" AS uid, u.email, u.id, u."neighborhoodId" AS lagje,
                  coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u
            WHERE u."authUserId" IS NOT NULL AND u."neighborhoodId" IS NOT NULL
            ORDER BY coalesce(u.role,'MEMBER')
  LOOP
    SELECT count(*) INTO v_echt FROM public.users
     WHERE "neighborhoodId" = r.lagje AND coalesce("membershipStatus",'') <> 'INACTIVE';

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role','authenticated','email', r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT count(*) INTO v_n FROM public.users
     WHERE "neighborhoodId" = r.lagje AND coalesce("membershipStatus",'') <> 'INACTIVE';
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);

    RAISE NOTICE '  % (%) sieht % von % in der eigenen Nachbarschaft -- %',
      rpad(left(r.email, 30), 30), rpad(r.rolle, 11), v_n, v_echt,
      CASE WHEN v_n = v_echt THEN 'vollstaendig' ELSE 'UNVOLLSTAENDIG' END;
  END LOOP;
END $$;
