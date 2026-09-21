-- Was bekommt ein neu angelegter Verein tatsaechlich?
-- Angelegt, verglichen, wieder entfernt.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text; r record;
BEGIN
  SELECT p.email, a.id::text INTO v_mail, v_uid FROM public.platform_admins p
    JOIN auth.users a ON lower(a.email)=lower(p.email) LIMIT 1;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.create_tenant('Probeverein Musterdorf', 'probe.example.invalid',
                              'admin@probe.example.invalid') INTO v_id;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE 'Angelegt: %', v_id;

  RAISE NOTICE '--- Was hat der neue Verein, was hat Koretini? ---';
  FOR r IN
    SELECT 'tenants' AS t,
           (SELECT count(*) FROM public.tenants WHERE id=v_id) AS neu,
           (SELECT count(*) FROM public.tenants WHERE id='koretini') AS alt
    UNION ALL SELECT 'tenant_domains',
           (SELECT count(*) FROM public.tenant_domains WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.tenant_domains WHERE "tenantId"='koretini')
    UNION ALL SELECT 'users',
           (SELECT count(*) FROM public.users WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.users WHERE "tenantId"='koretini')
    UNION ALL SELECT 'settings',
           (SELECT count(*) FROM public.settings WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.settings WHERE "tenantId"='koretini')
    UNION ALL SELECT 'accounting_accounts',
           (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"='koretini')
    UNION ALL SELECT 'fiscal_years',
           (SELECT count(*) FROM public.fiscal_years WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.fiscal_years WHERE "tenantId"='koretini')
    UNION ALL SELECT 'neighborhoods',
           (SELECT count(*) FROM public.neighborhoods WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.neighborhoods WHERE "tenantId"='koretini')
    UNION ALL SELECT 'tenant_modules',
           (SELECT count(*) FROM public.tenant_modules WHERE "tenantId"=v_id),
           (SELECT count(*) FROM public.tenant_modules WHERE "tenantId"='koretini')
  LOOP
    RAISE NOTICE '  % : neu % | koretini %   %', rpad(r.t, 20), lpad(r.neu::text,4),
      lpad(r.alt::text,4), CASE WHEN r.neu = 0 AND r.alt > 0 THEN '<<< FEHLT' ELSE '' END;
  END LOOP;

  RAISE NOTICE '--- Hat der Administrator ein Anmeldekonto? ---';
  RAISE NOTICE '  users-Zeile: %, auth-Konto: %',
    (SELECT count(*) FROM public.users WHERE "tenantId"=v_id),
    (SELECT count(*) FROM auth.users WHERE lower(email)='admin@probe.example.invalid');

  RAISE NOTICE '--- Was wuerde beim Arbeiten scheitern? ---';
  IF NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=v_id AND id='payment') THEN
    RAISE NOTICE '  keine Zahlungsangaben -> keine QR-Rechnung, keine Beitraege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts WHERE "tenantId"=v_id) THEN
    RAISE NOTICE '  kein Kontenplan -> Buchungen scheitern (spende_bezahlt bucht auf 3200)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.fiscal_years WHERE "tenantId"=v_id) THEN
    RAISE NOTICE '  kein Geschaeftsjahr -> Buchhaltung ohne Periode';
  END IF;

  -- Aufraeumen
  DELETE FROM public.users WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_domains WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_modules WHERE "tenantId"=v_id;
  DELETE FROM public.tenants WHERE id=v_id;
  RAISE NOTICE 'Probeverein entfernt. Vereine jetzt: %', (SELECT count(*) FROM public.tenants);
END $$;
