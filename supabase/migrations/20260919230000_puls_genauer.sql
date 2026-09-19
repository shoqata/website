DO $$
DECLARE v_back text := current_user; r record; v_q text;
        v_mgr boolean; v_stew boolean; v_n int;
BEGIN
  SELECT qual::text INTO v_q FROM pg_policies
   WHERE schemaname='public' AND tablename='users' AND cmd='SELECT';
  RAISE NOTICE 'Regel users_select vollstaendig:';
  RAISE NOTICE '%', v_q;
  RAISE NOTICE '---';

  FOR r IN SELECT u."authUserId" AS uid, u.email, u."neighborhoodId" AS lagje,
                  coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role','authenticated','email', r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT public.is_member_manager(), public.is_neighborhood_steward() INTO v_mgr, v_stew;
    SELECT count(*) INTO v_n FROM public.users;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
    RAISE NOTICE '  % | % | Verwaltung % | Verantwortlich % | sieht % Zeilen',
      rpad(left(r.email,28),28), rpad(r.rolle,11), v_mgr, v_stew, v_n;
  END LOOP;

  RAISE NOTICE '---';
  RAISE NOTICE 'Ein gewoehnliches Mitglied ohne Verantwortung saehe nach dieser';
  RAISE NOTICE 'Regel nur die eigene Zeile: der Puls waere 1 von 1.';
END $$;
