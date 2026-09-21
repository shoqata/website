DO $$
DECLARE v_back text := current_user; r record; v_t text; v_n int;
BEGIN
  RAISE NOTICE '--- Wer steht in platform_admins? ---';
  FOR r IN SELECT * FROM public.platform_admins LOOP
    RAISE NOTICE '  %', r;
  END LOOP;

  FOR r IN SELECT p.email, a.id::text AS uid
             FROM public.platform_admins p
             LEFT JOIN auth.users a ON lower(a.email) = lower(p.email) LOOP
    IF r.uid IS NULL THEN
      RAISE NOTICE '  % hat kein Anmeldekonto -- nicht pruefbar', r.email;
      CONTINUE;
    END IF;
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', r.uid, 'role','authenticated','email', r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      SELECT public.modul_umschalten('koretini','STAMMBAUM','AN') INTO v_t;
      RAISE NOTICE '  % schaltet um: % -- richtig', r.email, v_t;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  % schaltet um: ABGEWIESEN (%) -- Fehler', r.email, left(SQLERRM,50);
    END;
    BEGIN
      SELECT count(*) INTO v_n FROM public.marktplatz_uebersicht('koretini');
      RAISE NOTICE '  % sieht fremden Verein: % Module', r.email, v_n;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  % sieht fremden Verein: abgewiesen', r.email;
    END;
    -- Kernmodul darf sich nicht abschalten lassen
    BEGIN
      PERFORM public.modul_umschalten('koretini','MITGLIEDER','AUS');
      RAISE NOTICE '  Kernmodul abgeschaltet -- FEHLER';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  Kernmodul abschalten: abgewiesen -- richtig';
    END;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END LOOP;

  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';
  RAISE NOTICE 'Aufgeraeumt.';
END $$;
