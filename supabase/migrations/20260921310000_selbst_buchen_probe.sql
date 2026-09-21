-- Darf ein Verein buchen -- und bleibt eine Sperre wirklich eine Sperre?
DO $$
DECLARE v_back text := current_user; r record; v_t text; v_frei boolean;
BEGIN
  SELECT alle_module_frei INTO v_frei FROM public.tenants WHERE id='koretini';
  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';

  FOR r IN SELECT u."authUserId" AS uid, u.email, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL ORDER BY 3,2 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      SELECT public.modul_umschalten('koretini','STAMMBAUM','AN') INTO v_t;
    EXCEPTION WHEN OTHERS THEN v_t := 'abgewiesen'; END;
    RAISE NOTICE '  % (%) bucht STAMMBAUM: %', rpad(left(r.email,26),26), rpad(r.rolle,11), v_t;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END LOOP;

  -- Jetzt sperren und sehen, ob der Verein sie loesen kann.
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES ('koretini','BUCHHALTUNG','GESPERRT')
  ON CONFLICT ("tenantId",modul) DO UPDATE SET zustand='GESPERRT';

  SELECT u."authUserId", u.email INTO r.uid, r.email FROM public.users u
   WHERE u.role IN ('SUPER_ADMIN','ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    SELECT public.modul_umschalten('koretini','BUCHHALTUNG','AN') INTO v_t;
    RAISE NOTICE '  Verein loest die Sperre: % -- LOCH', v_t;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Verein loest die Sperre: abgewiesen -- richtig';
  END;
  BEGIN
    SELECT public.modul_umschalten('koretini','LIVESTREAM','AN') INTO v_t;
    RAISE NOTICE '  Verein bucht ein ungebautes Modul: % -- LOCH', v_t;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Verein bucht ein ungebautes Modul: abgewiesen -- richtig';
  END;
  BEGIN
    SELECT public.modul_umschalten('andererverein','STAMMBAUM','AN') INTO v_t;
    RAISE NOTICE '  Verein bucht fuer einen fremden Verein: % -- LOCH', v_t;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Verein bucht fuer einen fremden Verein: abgewiesen -- richtig';
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';
  UPDATE public.tenants SET alle_module_frei = v_frei WHERE id='koretini';
  RAISE NOTICE 'Aufgeraeumt, Freistellung = %', v_frei;
END $$;
