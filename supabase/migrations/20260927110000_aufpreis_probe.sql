DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_erg jsonb; v_verein text;
BEGIN
  SELECT pa.email INTO v_mail FROM public.platform_admins pa LIMIT 1;
  SELECT u."authUserId" INTO v_uid FROM public.users u WHERE lower(u.email)=lower(v_mail) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  v_verein := public.create_tenant('Probe Aufpreis', NULL, 'probe-aufpreis.example.org', NULL);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  UPDATE public.tenants SET "annualFee" = 480 WHERE id = v_verein;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  RAISE NOTICE '  ohne Zusatzmodul: %', public.jahresrechnung_betrag(v_verein);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES (v_verein, 'LANDINGPAGE', 'AN')
  ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand='AN';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  v_erg := public.jahresrechnung_betrag(v_verein);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE '  mit Startseite Premium: %', v_erg;

  -- Und sieht ein Besucher dieser Domain das Modul als aktiv?
  PERFORM set_config('request.headers',
    json_build_object('origin','https://probe-aufpreis.example.org')::text, false);
  EXECUTE 'SET ROLE anon';
  RAISE NOTICE '  Besucher sieht LANDINGPAGE aktiv: %', public.modul_aktiv_oeffentlich('LANDINGPAGE');
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  RAISE NOTICE '  Besucher von koretini.me sieht LANDINGPAGE aktiv: % (alles frei)',
    public.modul_aktiv_oeffentlich('LANDINGPAGE');
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);

  DELETE FROM public.tenant_modules WHERE "tenantId"=v_verein;
  DELETE FROM public.accounting_accounts WHERE "tenantId"=v_verein;
  DELETE FROM public.fiscal_years WHERE "tenantId"=v_verein;
  DELETE FROM public.settings WHERE "tenantId"=v_verein;
  DELETE FROM public.users WHERE "tenantId"=v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId"=v_verein;
  DELETE FROM public.tenants WHERE id=v_verein;
  RAISE NOTICE '  Probeverein entfernt.';
END $$;
