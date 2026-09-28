DO $$
DECLARE v_back text := current_user; v_uid text; v_n int; v_t text;
BEGIN
  SELECT au.id::text INTO v_uid FROM auth.users au WHERE lower(au.email)='burim@dervishi.ch';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email','burim@dervishi.ch')::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT public.current_tenant() INTO v_t;
  SELECT count(*) INTO v_n FROM public.users;
  RAISE NOTICE '1. vorher: current_tenant=% | % Mitglieder', coalesce(v_t,'(keiner)'), v_n;

  PERFORM public.start_tenant_support('koretini', 'Probe: Zugriff ueber die Vereinsdomain');
  SELECT public.current_tenant() INTO v_t;
  SELECT count(*) INTO v_n FROM public.users;
  RAISE NOTICE '2. mit Betreuung: current_tenant=% | % Mitglieder', coalesce(v_t,'(keiner)'), v_n;

  PERFORM public.end_tenant_support();
  SELECT public.current_tenant() INTO v_t;
  SELECT count(*) INTO v_n FROM public.users;
  RAISE NOTICE '3. nachher: current_tenant=% | % Mitglieder', coalesce(v_t,'(keiner)'), v_n;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT count(*) INTO v_n FROM public.platform_support WHERE "endedAt" IS NULL;
  RAISE NOTICE '4. offene Betreuungen danach: % (erwartet 0)', v_n;
END $$;
