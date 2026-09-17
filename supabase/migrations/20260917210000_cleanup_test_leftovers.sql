-- Rueckstaende aus den Selbsttests aufraeumen und offene Betreuungen pruefen.
DO $$
DECLARE r record; v int;
BEGIN
  RAISE NOTICE '--- Vereine ---';
  FOR r IN SELECT id, name FROM public.tenants ORDER BY id LOOP
    RAISE NOTICE '  % | %', r.id, r.name;
  END LOOP;

  RAISE NOTICE '--- Betreuungen ---';
  FOR r IN SELECT email, "tenantId", "startedAt", "endedAt" FROM public.platform_support ORDER BY "startedAt" LOOP
    RAISE NOTICE '  % -> % | offen: %', r.email, r."tenantId", (r."endedAt" IS NULL);
  END LOOP;

  -- Testvereine entfernen, sofern leer
  FOR r IN SELECT id FROM public.tenants
            WHERE id LIKE 'selbsttest-verein%' OR id LIKE 'sichtpruefung%' LOOP
    SELECT count(*) INTO v FROM public.users WHERE "tenantId"=r.id;
    IF v = 0 THEN
      DELETE FROM public.platform_support WHERE "tenantId"=r.id;
      DELETE FROM public.tenant_domains  WHERE "tenantId"=r.id;
      DELETE FROM public.tenants         WHERE id=r.id;
      RAISE NOTICE 'Testverein % entfernt.', r.id;
    ELSE
      RAISE NOTICE 'Testverein % hat % Mitglieder -- stehen gelassen.', r.id, v;
    END IF;
  END LOOP;

  -- Offene Betreuungen schliessen, damit niemand versehentlich im falschen
  -- Verein arbeitet.
  UPDATE public.platform_support SET "endedAt"=now() WHERE "endedAt" IS NULL;
  GET DIAGNOSTICS v = ROW_COUNT;
  RAISE NOTICE 'Offene Betreuungen geschlossen: %', v;
END $$;
