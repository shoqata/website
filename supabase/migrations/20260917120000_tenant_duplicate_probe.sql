-- Zwei Vereinszeilen fuer einen Verein: welche wird tatsaechlich benutzt?
DO $$
DECLARE r record; v int;
BEGIN
  RAISE NOTICE '--- Vereine ---';
  FOR r IN SELECT id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt" FROM public.tenants ORDER BY "createdAt" LOOP
    RAISE NOTICE '  id=% | % | slug=% | % | %', r.id, r.name, r.slug, r."subscriptionPlan", r."createdAt";
  END LOOP;

  RAISE NOTICE '--- Domains je Verein ---';
  FOR r IN SELECT "tenantId", string_agg(domain, ', ') AS domains FROM public.tenant_domains GROUP BY 1 LOOP
    RAISE NOTICE '  %: %', r."tenantId", r.domains;
  END LOOP;

  RAISE NOTICE '--- Wie viele Daten haengen an welchem Verein? ---';
  FOR r IN
    SELECT t.id,
      (SELECT count(*) FROM public.users u WHERE u."tenantId"=t.id) AS mitglieder,
      (SELECT count(*) FROM public.payments p WHERE p."tenantId"=t.id) AS zahlungen,
      (SELECT count(*) FROM public.neighborhoods n WHERE n."tenantId"=t.id) AS lagje,
      (SELECT count(*) FROM public.events e WHERE e."tenantId"=t.id) AS events,
      (SELECT count(*) FROM public.settings s WHERE s."tenantId"=t.id) AS einstellungen
    FROM public.tenants t
  LOOP
    RAISE NOTICE '  %: % Mitglieder, % Zahlungen, % Lagje, % Events, % Einstellungen',
      r.id, r.mitglieder, r.zahlungen, r.lagje, r.events, r.einstellungen;
  END LOOP;

  SELECT count(*) INTO v FROM public.platform_admins;
  RAISE NOTICE 'Plattform-Betreiber hinterlegt: %', v;
END $$;
