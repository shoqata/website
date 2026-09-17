DO $$
DECLARE r record; v_back text := current_user; v_owner uuid; v_mail text; v_n int; v_plan text;
BEGIN
  RAISE NOTICE '--- Regeln auf public.tenants ---';
  FOR r IN SELECT polname, polcmd, polpermissive,
                  pg_get_expr(polqual, polrelid) AS lesen,
                  pg_get_expr(polwithcheck, polrelid) AS schreiben,
                  (SELECT string_agg(rolname,',') FROM pg_roles WHERE oid = ANY(polroles)) AS rollen
             FROM pg_policy WHERE polrelid='public.tenants'::regclass LOOP
    RAISE NOTICE '  % | % | Rollen % | USING % | CHECK %', r.polname, r.polcmd, r.rollen, r.lesen, r.schreiben;
  END LOOP;
  RAISE NOTICE 'UPDATE-Recht fuer authenticated: %', has_table_privilege('authenticated','public.tenants','UPDATE');

  SELECT u."authUserId", u.email INTO v_owner, v_mail
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email)=lower(u.email)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;
  IF v_owner IS NULL THEN RETURN; END IF;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_owner::text,'role','authenticated','email',v_mail)::text,false);
  EXECUTE 'SET ROLE authenticated';

  UPDATE public.tenants SET "subscriptionPlan"='ENTERPRISE' WHERE id='koretini';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  SELECT "subscriptionPlan" INTO v_plan FROM public.tenants WHERE id='koretini';
  RAISE NOTICE 'Betreiber aendert den Plan: % Zeilen, Wert danach % -- erwartet 1 / ENTERPRISE', v_n, v_plan;

  EXECUTE format('SET ROLE %I', v_back);
  UPDATE public.tenants SET "subscriptionPlan"='FREE' WHERE id='koretini';
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE 'Zuruecksetzen auf FREE.';
END $$;
