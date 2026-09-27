-- Der Probeverein hat seinen Zweck erfuellt. Er bleibt nicht stehen: eine
-- Domain "localhost", die auf einen Verein zeigt, ist in der Datenbank eines
-- laufenden Betriebs nichts verloren.
DO $$
DECLARE v_id text := 'probe-premium'; v_n int;
BEGIN
  DELETE FROM public.events           WHERE "tenantId" = v_id;
  DELETE FROM public.users            WHERE "tenantId" = v_id;
  DELETE FROM public.tenant_modules   WHERE "tenantId" = v_id;
  DELETE FROM public.settings         WHERE "tenantId" = v_id;
  DELETE FROM public.accounting_accounts WHERE "tenantId" = v_id;
  DELETE FROM public.fiscal_years     WHERE "tenantId" = v_id;
  DELETE FROM public.security_logs    WHERE "tenantId" = v_id;
  DELETE FROM public.tenant_domains   WHERE "tenantId" = v_id;
  DELETE FROM public.tenants          WHERE id = v_id;

  SELECT count(*) INTO v_n FROM public.tenant_domains WHERE domain = 'localhost';
  RAISE NOTICE 'localhost zeigt noch auf % Verein(e) (erwartet 0)', v_n;
  SELECT count(*) INTO v_n FROM public.tenants;
  RAISE NOTICE 'Vereine insgesamt: %', v_n;
END $$;
