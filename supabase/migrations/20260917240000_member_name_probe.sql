DO $$
DECLARE r record; v int;
BEGIN
  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini';
  RAISE NOTICE 'Mitglieder: %', v;
  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini'
     AND ("firstName" IS NULL OR btrim("firstName")='');
  RAISE NOTICE 'ohne Vorname: %', v;
  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini'
     AND ("lastName" IS NULL OR btrim("lastName")='');
  RAISE NOTICE 'ohne Nachname: %', v;
  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini'
     AND "displayName" IS NOT NULL AND btrim("displayName") <> '';
  RAISE NOTICE 'mit Anzeigename: %', v;

  RAISE NOTICE '--- Beispiel Selami Canaj ---';
  FOR r IN SELECT id, "displayName", "firstName", "lastName", salutation, country, street, zip, city
             FROM public.users WHERE "displayName" ILIKE '%canaj%' LIMIT 3 LOOP
    RAISE NOTICE '  Anzeige=% | Vorname=% | Nachname=% | Anrede=% | Land=% | % % %',
      r."displayName", COALESCE(r."firstName",'<leer>'), COALESCE(r."lastName",'<leer>'),
      COALESCE(r.salutation,'<leer>'), COALESCE(r.country,'<leer>'),
      COALESCE(r.street,''), COALESCE(r.zip,''), COALESCE(r.city,'');
  END LOOP;

  RAISE NOTICE '--- Laender im Bestand ---';
  FOR r IN SELECT COALESCE(NULLIF(btrim(country),''),'<leer>') AS land, count(*) AS n
             FROM public.users WHERE "tenantId"='koretini' GROUP BY 1 ORDER BY 2 DESC LIMIT 12 LOOP
    RAISE NOTICE '  %: %', r.land, r.n;
  END LOOP;
END $$;
