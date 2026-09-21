-- Wiederholung mit den Argumenten in der richtigen Reihenfolge.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text; r record;
BEGIN
  SELECT p.email, a.id::text INTO v_mail, v_uid FROM public.platform_admins p
    JOIN auth.users a ON lower(a.email)=lower(p.email) LIMIT 1;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.create_tenant('Probeverein Musterdorf', 'probeverein',
                              'probe.example.invalid', 'admin@probe.example.invalid') INTO v_id;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE 'Angelegt mit Kennung: %', v_id;

  FOR r IN
    SELECT 'users (Administrator)' AS t,
           (SELECT count(*) FROM public.users WHERE "tenantId"=v_id) AS neu, 1 AS soll
    UNION ALL SELECT 'settings',
           (SELECT count(*) FROM public.settings WHERE "tenantId"=v_id), 3
    UNION ALL SELECT 'accounting_accounts',
           (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"=v_id), 21
    UNION ALL SELECT 'fiscal_years',
           (SELECT count(*) FROM public.fiscal_years WHERE "tenantId"=v_id), 1
    UNION ALL SELECT 'tenant_modules',
           (SELECT count(*) FROM public.tenant_modules WHERE "tenantId"=v_id), 0
  LOOP
    RAISE NOTICE '  % : % (bei Koretini/erwartet %)  %', rpad(r.t,22), lpad(r.neu::text,3),
      lpad(r.soll::text,3), CASE WHEN r.neu < r.soll THEN '<<< FEHLT' ELSE '' END;
  END LOOP;

  RAISE NOTICE '--- Kann dieser Verein arbeiten? ---';
  RAISE NOTICE '  Kernmodule aktiv (ohne Buchung, ueber ist_kern): %',
    (SELECT count(*) FROM public.modules WHERE ist_kern);
  IF NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=v_id AND id='payment') THEN
    RAISE NOTICE '  keine Zahlungsangaben -> keine QR-Rechnung, keine Beitragssaetze';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts WHERE "tenantId"=v_id) THEN
    RAISE NOTICE '  kein Kontenplan -> jede Buchung scheitert';
  END IF;
  RAISE NOTICE '  Administrator hat Anmeldekonto: %',
    (SELECT count(*) FROM auth.users WHERE lower(email)='admin@probe.example.invalid');

  DELETE FROM public.users WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_domains WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_modules WHERE "tenantId"=v_id;
  DELETE FROM public.tenants WHERE id=v_id;
  RAISE NOTICE 'Entfernt. Vereine: %', (SELECT count(*) FROM public.tenants);
END $$;
