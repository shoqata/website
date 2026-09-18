DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text;
        v_mgr boolean; v_stew boolean; v_ten text; v_rolle text;
BEGIN
  SELECT u."authUserId", u.email, u.id, u.role INTO v_uid, v_mail, v_id, v_rolle
    FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  RAISE NOTICE 'Geprueftes Mitglied: % (Rolle %)', v_mail, coalesce(v_rolle,'MEMBER');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.is_member_manager(), public.is_neighborhood_steward(), public.current_tenant()
    INTO v_mgr, v_stew, v_ten;
  RAISE NOTICE '  is_member_manager      : %', v_mgr;
  RAISE NOTICE '  is_neighborhood_steward: %', v_stew;
  RAISE NOTICE '  current_tenant         : %', v_ten;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  RAISE NOTICE 'Ist dieses Mitglied irgendwo verantwortlich?';
  RAISE NOTICE '  %', (SELECT count(*) FROM public.neighborhoods n
                        WHERE n."contactPersonIds" @> to_jsonb(v_id)
                           OR n."representativeId" = v_id OR n."managerId" = v_id);

  RAISE NOTICE 'Regeln auf family_links:';
  DECLARE r record;
  BEGIN
    FOR r IN SELECT policyname, cmd, qual::text FROM pg_policies
              WHERE schemaname='public' AND tablename='family_links' LOOP
      RAISE NOTICE '  % (%) : %', r.policyname, r.cmd, left(r.qual, 110);
    END LOOP;
  END;
END $$;
