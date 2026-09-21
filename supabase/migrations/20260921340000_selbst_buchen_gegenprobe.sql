-- Nach dem Umbau der Signatur noch einmal alles durch.
DO $$
DECLARE v_back text := current_user; r record; v_t text; v_frei boolean;
        v_uid text; v_mail text;
BEGIN
  SELECT alle_module_frei INTO v_frei FROM public.tenants WHERE id='koretini';
  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';

  FOR r IN SELECT u."authUserId" AS uid, u.email, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL ORDER BY 3,2 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      SELECT public.modul_umschalten('STAMMBAUM','AN') INTO v_t;
    EXCEPTION WHEN OTHERS THEN v_t := 'abgewiesen'; END;
    RAISE NOTICE '  % (%) bucht ohne Vereinsangabe: %',
      rpad(left(r.email,26),26), rpad(r.rolle,11), v_t;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END LOOP;

  -- Betreiber, fuer einen benannten Verein
  SELECT p.email, a.id::text INTO v_mail, v_uid
    FROM public.platform_admins p JOIN auth.users a ON lower(a.email)=lower(p.email) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    SELECT public.modul_umschalten('BUCHHALTUNG','GESPERRT','koretini') INTO v_t;
    RAISE NOTICE '  Betreiber sperrt: %', v_t;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  Betreiber sperrt: ABGEWIESEN -- Fehler'; END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Verein versucht die Sperre zu loesen
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('SUPER_ADMIN','ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    SELECT public.modul_umschalten('BUCHHALTUNG','AN') INTO v_t;
    RAISE NOTICE '  Verein loest die Sperre: % -- LOCH', v_t;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Verein loest die Sperre: abgewiesen -- richtig';
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';
  UPDATE public.tenants SET alle_module_frei = v_frei WHERE id='koretini';
  RAISE NOTICE 'Aufgeraeumt, Freistellung = %', v_frei;
END $$;
