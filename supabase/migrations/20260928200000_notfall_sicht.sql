DO $$
DECLARE v_back text := current_user; v_uid text; v_n int; v_z int; v_t text; r record;
BEGIN
  RAISE NOTICE '=== Was sieht wer, mit Origin koretini.me ===';
  FOR r IN SELECT u.email, u."authUserId" AS uid, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL ORDER BY u.role LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    PERFORM set_config('request.headers',
      json_build_object('origin','https://www.koretini.me')::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT public.current_tenant() INTO v_t;
    SELECT count(*) INTO v_n FROM public.users;
    SELECT count(*) INTO v_z FROM public.payments;
    EXECUTE format('SET ROLE %I', v_back);
    RAISE NOTICE '  % | % | Verein=% | % Mitglieder | % Rechnungen',
      rpad(r.email,26), rpad(r.rolle,20), rpad(coalesce(v_t,'(keiner)'),10), v_n, v_z;
  END LOOP;

  -- Und der Betreiber
  SELECT au.id::text INTO v_uid FROM auth.users au WHERE lower(au.email)='burim@dervishi.ch';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email','burim@dervishi.ch')::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.current_tenant() INTO v_t;
  SELECT count(*) INTO v_n FROM public.users;
  SELECT count(*) INTO v_z FROM public.payments;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '  % | BETREIBER | Verein=% | % Mitglieder | % Rechnungen',
    rpad('burim@dervishi.ch',26), rpad(coalesce(v_t,'(keiner)'),10), v_n, v_z;

  PERFORM set_config('request.jwt.claims', NULL, false);
  PERFORM set_config('request.headers', NULL, false);
END $$;
