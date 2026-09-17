DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Rollen genau ===';
  FOR r IN SELECT role, count(*) AS n FROM public.users GROUP BY role ORDER BY role LOOP
    RAISE NOTICE '  %: %', coalesce(r.role,'<null>'), r.n;
  END LOOP;

  RAISE NOTICE '=== Jede Zeile mit Leitungsrolle ===';
  FOR r IN SELECT u.id, coalesce(u."displayName",'<ohne Name>') AS nm, u.role,
                  coalesce(u."neighborhoodId",'<keine>') AS nb, coalesce(u.email,'<keine>') AS mail
             FROM public.users u
            WHERE u.role IN ('REPRESENTATIVE','NEIGHBORHOOD_MANAGER','BOARD') LOOP
    RAISE NOTICE '  % | % | % | wohnt in % | %', r.id, r.nm, r.role, r.nb, r.mail;
  END LOOP;

  RAISE NOTICE '=== Wer ist als Verantwortlicher hinterlegt? ===';
  SELECT count(*) INTO v_n FROM public.neighborhoods
   WHERE "contactPersonIds" IS NOT NULL AND jsonb_array_length("contactPersonIds") > 0;
  RAISE NOTICE '  Nachbarschaften mit contactPersonIds: %', v_n;
  SELECT count(*) INTO v_n FROM public.neighborhoods WHERE "representativeId" IS NOT NULL;
  RAISE NOTICE '  Nachbarschaften mit representativeId (alt): %', v_n;
  SELECT count(*) INTO v_n FROM public.neighborhoods WHERE "managerId" IS NOT NULL;
  RAISE NOTICE '  Nachbarschaften mit managerId (alt): %', v_n;

  FOR r IN SELECT n.name, n."contactPersonIds"::text AS ids, coalesce(n."representativeId",'-') AS alt,
                  coalesce(n."contactPerson",'-') AS frei
             FROM public.neighborhoods n
            WHERE (n."contactPersonIds" IS NOT NULL AND jsonb_array_length(n."contactPersonIds") > 0)
               OR n."representativeId" IS NOT NULL LOOP
    RAISE NOTICE '  % -> ids % | alt % | frei %', r.name, r.ids, r.alt, r.frei;
  END LOOP;

  RAISE NOTICE '=== Rechnungen ===';
  SELECT count(*) INTO v_n FROM public.payments;
  RAISE NOTICE '  Zahlungen gesamt: %', v_n;
  FOR r IN SELECT status, count(*) AS n FROM public.payments GROUP BY status ORDER BY status LOOP
    RAISE NOTICE '    Status %: %', coalesce(r.status,'<null>'), r.n;
  END LOOP;
END $$;
