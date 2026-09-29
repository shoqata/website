-- Diesmal mit gebuchtem Modul, sonst prueft der Test die falsche Sache.
--
-- Die Gastregel lautet: ("userId" IS NULL) AND modul_aktiv('ANLAESSE') --
-- sie prueft tenantId gar nicht. Mit dem alten Ausloeser, der bei
-- Unklarheit 'koretini' einsetzte, waere eine Anmeldung auf der Seite eines
-- anderen Vereins also durchgegangen und bei Koretini gelandet. Genau das
-- wird hier gemessen.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_wo text; v_n int;
BEGIN
  SELECT pa.email INTO v_mail FROM public.platform_admins pa LIMIT 1;
  SELECT u."authUserId" INTO v_uid FROM public.users u WHERE lower(u.email)=lower(v_mail) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  PERFORM public.create_tenant('Probe Fremdverein', NULL, 'probe-fremd.example.org', NULL);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES ('probe-fremdverein','ANLAESSE','AN')
  ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand='AN';

  INSERT INTO public.events (id, "tenantId", title, date, status)
  VALUES ('probe-fremd-anlass','probe-fremdverein','Probeanlass', (current_date+10)::text, 'PUBLISHED');

  PERFORM set_config('request.headers',
    json_build_object('origin','https://probe-fremd.example.org')::text, false);
  EXECUTE 'SET ROLE anon';
  BEGIN
    INSERT INTO public.event_registrations (id, "eventId", name, email)
    VALUES ('probe-anmeldung','probe-fremd-anlass','Probe Gast','gast@example.org');
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  abgewiesen: %', left(SQLERRM,70);
  END;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT "tenantId" INTO v_wo FROM public.event_registrations WHERE id='probe-anmeldung';
  RAISE NOTICE 'Gastanmeldung auf fremder Domain landet bei: %', coalesce(v_wo,'(keine Zeile)');
  RAISE NOTICE '  mit dem alten Ausloeser waere es koretini gewesen.';

  DELETE FROM public.event_registrations WHERE id='probe-anmeldung';
  DELETE FROM public.events WHERE id='probe-fremd-anlass';
  DELETE FROM public.tenant_modules WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.accounting_accounts WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.fiscal_years WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.settings WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.users WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.tenant_domains WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.tenants WHERE id='probe-fremdverein';
  PERFORM set_config('request.headers', NULL, false);
  SELECT count(*) INTO v_n FROM public.tenants;
  RAISE NOTICE 'Vereine danach: % | Anmeldungen bei koretini: %',
    v_n, (SELECT count(*) FROM public.event_registrations WHERE "tenantId"='koretini');
END $$;
