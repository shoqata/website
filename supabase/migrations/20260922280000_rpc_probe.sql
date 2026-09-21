DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;

  INSERT INTO public.socialmediaposts (id,"tenantId",content,platforms,status,timestamp)
  VALUES ('probe-rpc','koretini','Probe','["FACEBOOK"]'::jsonb,'DRAFT',now())
  ON CONFLICT (id) DO UPDATE SET status='DRAFT';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    PERFORM public.social_verbinden_starten('https://www.koretini.me/#/admin');
    RAISE NOTICE '  Verbinden starten: Link erzeugt';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  Verbinden starten: %', SQLERRM; END;

  BEGIN
    PERFORM public.social_jetzt_senden('probe-rpc');
    RAISE NOTICE '  Jetzt senden: angenommen';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  Jetzt senden: %', SQLERRM; END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Und als gewoehnliches Mitglied
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    PERFORM public.social_verbinden_starten(NULL);
    RAISE NOTICE '  Mitglied darf verbinden: JA -- LOCH';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  Mitglied darf verbinden: nein (%)', left(SQLERRM,40); END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.socialmediaposts WHERE id='probe-rpc';
END $$;
