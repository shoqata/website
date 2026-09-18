-- Was sieht die Betreiber-Domain? Gemessen, nicht vermutet.
--
-- resolveTenantId() liefert dort null, und die Bruecke filtert dann gar
-- nicht. Die Frage ist also: was kommt bei einer ungefilterten Abfrage auf
-- public_settings und public_tenant_domains zurueck?
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE 'Vereine insgesamt: %', (SELECT count(*) FROM public.tenants);

  FOR r IN SELECT domain, "tenantId" FROM public.tenant_domains ORDER BY 1 LOOP
    RAISE NOTICE '  Domain %  ->  %', rpad(r.domain, 22), r."tenantId";
  END LOOP;

  SELECT count(*) INTO v_n FROM public.settings WHERE id = 'branding';
  RAISE NOTICE 'settings-Zeilen mit id=branding: %', v_n;

  FOR r IN SELECT id, "tenantId" FROM public.settings ORDER BY 1 LOOP
    RAISE NOTICE '  settings/%  (Verein %)', rpad(r.id, 12), r."tenantId";
  END LOOP;
END $$;
