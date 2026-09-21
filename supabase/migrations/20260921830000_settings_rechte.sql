DO $$
DECLARE v_back text := current_user; r record; v_uid text; v_mail text; v_n int;
BEGIN
  RAISE NOTICE 'Regeln auf settings:';
  FOR r IN SELECT policyname, cmd, left(coalesce(qual::text,'-'),90) AS q
             FROM pg_policies WHERE schemaname='public' AND tablename='settings' LOOP
    RAISE NOTICE '  % (%): %', rpad(r.policyname,26), r.cmd, r.q;
  END LOOP;

  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.settings;
  RAISE NOTICE 'Vereinsadministrator sieht % Einstellungszeilen', v_n;
  BEGIN
    UPDATE public.settings SET payment = payment WHERE id='payment';
    RAISE NOTICE 'darf schreiben: ja';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'darf schreiben: NEIN -- %', left(SQLERRM,50);
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Ein gewoehnliches Mitglied
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    UPDATE public.settings SET payment = payment WHERE id='payment';
    RAISE NOTICE 'Mitglied darf schreiben: JA -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Mitglied darf schreiben: nein -- richtig';
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
