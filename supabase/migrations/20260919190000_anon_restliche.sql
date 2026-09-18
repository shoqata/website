-- Die verbliebenen anon-aufrufbaren Funktionen, und was die oeffentlichen
-- Sichten einem Besucher tatsaechlich herausgeben.
DO $$
DECLARE v_back text := current_user; v_n int; v_t text; r record;
BEGIN
  SET LOCAL ROLE anon;

  BEGIN
    SELECT count(*) INTO v_n FROM public.my_neighborhood_contacts();
    RAISE NOTICE 'my_neighborhood_contacts : % Zeilen -- %', v_n,
      CASE WHEN v_n = 0 THEN 'leer, richtig' ELSE 'GIBT KONTAKTDATEN HERAUS' END;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'my_neighborhood_contacts : abgewiesen (%)', left(SQLERRM, 44);
  END;

  BEGIN
    SELECT public.claim_my_profile() INTO v_t;
    RAISE NOTICE 'claim_my_profile         : DURCHGELAUFEN -> %', coalesce(v_t,'(null)');
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'claim_my_profile         : abgewiesen (%)', left(SQLERRM, 44);
  END;

  BEGIN
    SELECT public.end_tenant_support() INTO v_n;
    RAISE NOTICE 'end_tenant_support       : DURCHGELAUFEN -> % Zeilen', v_n;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'end_tenant_support       : abgewiesen (%)', left(SQLERRM, 44);
  END;

  RAISE NOTICE '--- Was geben die oeffentlichen Sichten einem Besucher? ---';
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_members;
    RAISE NOTICE '  public_members       : % Zeilen (von % Mitgliedern)', v_n,
      (SELECT count(*) FROM public.users);
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  public_members       : kein Zugriff'; END;
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_tenants;
    RAISE NOTICE '  public_tenants       : % Zeilen', v_n;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  public_tenants       : kein Zugriff'; END;
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_settings;
    RAISE NOTICE '  public_settings      : % Zeilen', v_n;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  public_settings      : kein Zugriff'; END;
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_tenant_domains;
    RAISE NOTICE '  public_tenant_domains: % Zeilen', v_n;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  public_tenant_domains: kein Zugriff'; END;

  EXECUTE format('SET ROLE %I', v_back);

  RAISE NOTICE '--- Welche Spalten hat public_members? ---';
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='public_members' ORDER BY ordinal_position LOOP
    RAISE NOTICE '  %', r.column_name;
  END LOOP;
END $$;
