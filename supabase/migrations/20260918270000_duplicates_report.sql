-- Die mehrfach vorkommenden Namen im Einzelnen.
--
-- Fuer jede Zeile das, woran sich entscheidet, welche bleiben muss: haengen
-- Rechnungen daran, gibt es ein Anmeldekonto, ist sie aktiv, und traegt sie
-- eine echte oder eine kuenstlich veraenderte Adresse.
DO $$
DECLARE r record; v_name text := ''; v_zeilen int; v_namen int;
BEGIN
  SELECT count(*) INTO v_namen FROM (
    SELECT lower(btrim("displayName")) FROM public.users
     WHERE "displayName" IS NOT NULL AND btrim("displayName") <> ''
     GROUP BY 1 HAVING count(*) > 1) x;
  RAISE NOTICE 'Mehrfach vorkommende Namen: %', v_namen;
  RAISE NOTICE '';

  FOR r IN
    SELECT u.id,
           u."displayName" AS nm,
           coalesce(u.email, '<keine>') AS mail,
           coalesce(u.role, 'MEMBER') AS rolle,
           coalesce(u."membershipStatus", '<null>') AS status,
           coalesce(n.name, '<keine>') AS nachbarschaft,
           (SELECT count(*) FROM public.payments p WHERE p."userId" = u.id) AS rechnungen,
           (SELECT count(*) FROM public.payments p WHERE p."userId" = u.id AND p.status='PAID') AS bezahlt,
           (u."authUserId" IS NOT NULL) AS hat_konto,
           (u.email IS NOT NULL AND split_part(u.email,'@',1) ~ '_[A-Za-z0-9]{4,6}$') AS kuenstlich,
           (u.email IS NULL OR u.email ILIKE '%@koretini.legacy' OR u.email ILIKE '%no-email-%') AS ohne_mail,
           coalesce(u."joinedAt"::text, '-') AS beigetreten,
           (SELECT count(*) FROM public.neighborhoods x
             WHERE x."contactPersonIds" @> to_jsonb(u.id)
                OR x."representativeId" = u.id OR x."managerId" = u.id) AS betreut
      FROM public.users u
      LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
     WHERE lower(btrim(u."displayName")) IN (
             SELECT lower(btrim("displayName")) FROM public.users
              WHERE "displayName" IS NOT NULL AND btrim("displayName") <> ''
              GROUP BY 1 HAVING count(*) > 1)
     ORDER BY lower(btrim(u."displayName")), u."joinedAt" NULLS LAST, u.id
  LOOP
    IF v_name IS DISTINCT FROM r.nm THEN
      v_name := r.nm;
      SELECT count(*) INTO v_zeilen FROM public.users
       WHERE lower(btrim("displayName")) = lower(btrim(r.nm));
      RAISE NOTICE '--- %  (% Zeilen) ---', r.nm, v_zeilen;
    END IF;
    RAISE NOTICE '   %', r.id;
    RAISE NOTICE '      %  [%]  %', r.mail, r.rolle, r.status;
    RAISE NOTICE '      Nachbarschaft: %  |  Rechnungen: % (% bezahlt)',
      r.nachbarschaft, r.rechnungen, r.bezahlt;
    RAISE NOTICE '      Konto: %  |  Adresse kuenstlich: %  |  ohne Adresse: %  |  betreut % Nachbarschaft(en)',
      r.hat_konto, r.kuenstlich, r.ohne_mail, r.betreut;
  END LOOP;
END $$;
