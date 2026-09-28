DO $$
DECLARE v_back text := current_user; v_uid text; w record; v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('burim@dervishi.ch'),    -- Betreiber
      ('email@dervishi.ch'),    -- Koretinis Administrator
      ('axhija.sokol@gmail.com') -- Vorstand
    ) AS x(mail) LOOP
    SELECT au.id::text INTO v_uid FROM auth.users au WHERE lower(au.email)=v.mail;
    IF v_uid IS NULL THEN RAISE NOTICE '  % -> kein Anmeldekonto', v.mail; CONTINUE; END IF;

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',v_uid,'role','authenticated','email',v.mail)::text, false);
    PERFORM set_config('request.headers',
      json_build_object('origin','https://unityhub.li')::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT * INTO w FROM public.wer_bin_ich();
    EXECUTE format('SET ROLE %I', v_back);

    RAISE NOTICE '  % | Betreiber=% | Verein=% | Domain=% | Rolle=%',
      rpad(v.mail,26), w.ist_betreiber, rpad(coalesce(w.verein,'-'),10),
      rpad(coalesce(w.vereinsdomain,'-'),18), w.rolle;
  END LOOP;
  PERFORM set_config('request.jwt.claims', NULL, false);
  PERFORM set_config('request.headers', NULL, false);
END $$;
