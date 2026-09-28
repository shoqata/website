DO $$
DECLARE v_back text := current_user; r record; v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('burim@dervishi.ch','d24e6fe8'),
      ('email@dervishi.ch','03d3e041')) AS x(mail, kurz) LOOP
    DECLARE v_uid text; v_n int; v_t text; v_rolle text; v_staff boolean; v_betreiber boolean;
    BEGIN
      SELECT au.id::text INTO v_uid FROM auth.users au WHERE lower(au.email)=v.mail;
      PERFORM set_config('request.jwt.claims',
        json_build_object('sub',v_uid,'role','authenticated','email',v.mail)::text, false);
      PERFORM set_config('request.headers',
        json_build_object('origin','https://www.koretini.me')::text, false);
      EXECUTE 'SET ROLE authenticated';

      SELECT public.current_tenant(), public.app_role(),
             public.is_staff(), public.is_platform_admin()
        INTO v_t, v_rolle, v_staff, v_betreiber;
      SELECT count(*) INTO v_n FROM public.users;

      EXECUTE format('SET ROLE %I', v_back);
      RAISE NOTICE '--- % ---', v.mail;
      RAISE NOTICE '    current_tenant=% | Rolle=% | is_staff=% | Betreiber=%',
        coalesce(v_t,'(keiner)'), coalesce(v_rolle,'(keine)'), v_staff, v_betreiber;
      RAISE NOTICE '    sieht % Mitgliederzeilen', v_n;
    END;
  END LOOP;
  PERFORM set_config('request.jwt.claims', NULL, false);
  PERFORM set_config('request.headers', NULL, false);
END $$;
