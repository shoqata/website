-- Arbeitslisten, sortiert nach Wirkung. Nur Ausgabe, keine Aenderung.
DO $$
DECLARE r record; v_k text;
BEGIN
  -- --- Geburtsdaten -------------------------------------------------------
  -- Oben stehen die Mitglieder mit einer echten Adresse: nur bei ihnen wirkt
  -- ein eingetragenes Geburtsdatum sofort. Darunter die uebrigen, bei denen
  -- zuerst die Adresse fehlt.
  RAISE NOTICE 'L8;Wirkt sofort;Nachbarschaft;Name;E-Mail;Telefon;Geburtsdatum (TT.MM.JJJJ)';
  FOR r IN
    SELECT u."displayName" AS name,
           CASE WHEN coalesce(u.email,'') <> '' AND u.email NOT ILIKE '%@koretini.legacy'
                 AND u.email NOT ILIKE '%no-email-%' THEN 'ja' ELSE 'nein -- E-Mail fehlt' END AS wirkt,
           CASE WHEN coalesce(u.email,'') = '' OR u.email ILIKE '%@koretini.legacy'
                 OR u.email ILIKE '%no-email-%' THEN '' ELSE u.email END AS mail,
           coalesce(u.phone,'') AS tel, coalesce(n.name,'(keine)') AS nb
      FROM public.users u
      LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
     WHERE (u.birthdate IS NULL OR btrim(u.birthdate) = '')
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     ORDER BY 2, coalesce(n.name,'zzzz'), u."displayName"
  LOOP
    RAISE NOTICE 'L8;%;%;%;%;%;',
      r.wirkt, replace(r.nb, ';', ','), replace(coalesce(r.name,''), ';', ','),
      replace(r.mail, ';', ','), replace(r.tel, ';', ',');
  END LOOP;

  -- --- Nachbarschaften ohne verantwortliche Person -------------------------
  -- Vorgeschlagen werden Mitglieder mit echter Adresse und Telefonnummer.
  -- Ein Anmeldekonto wird nicht vorausgesetzt -- es gibt im ganzen Verein
  -- nur fuenf, das waere kein Auswahlkriterium, sondern ein Ausschluss.
  RAISE NOTICE 'L9;Nachbarschaft;Mitglieder;mit echter E-Mail;Vorschlaege (echte E-Mail + Telefon);hat schon Konto;Verantwortlich soll sein';
  FOR r IN
    SELECT n.id, n.name,
           (SELECT count(*) FROM public.users u WHERE u."neighborhoodId" = n.id) AS anzahl,
           (SELECT count(*) FROM public.users u WHERE u."neighborhoodId" = n.id
             AND coalesce(u.email,'') <> '' AND u.email NOT ILIKE '%@koretini.legacy'
             AND u.email NOT ILIKE '%no-email-%') AS mitmail
      FROM public.neighborhoods n
     WHERE NOT EXISTS (SELECT 1 FROM public.users u
                        WHERE n."contactPersonIds" @> to_jsonb(u.id)
                           OR n."representativeId" = u.id OR n."managerId" = u.id)
     ORDER BY 3 DESC, n.name
  LOOP
    SELECT string_agg(x.name || CASE WHEN x.konto THEN ' (Konto)' ELSE '' END, ' / ')
      INTO v_k FROM (
      SELECT u."displayName" AS name, u."authUserId" IS NOT NULL AS konto
        FROM public.users u
       WHERE u."neighborhoodId" = r.id
         AND coalesce(u.email,'') <> '' AND u.email NOT ILIKE '%@koretini.legacy'
         AND u.email NOT ILIKE '%no-email-%'
         AND coalesce(u.phone,'') <> ''
         AND coalesce(u."membershipStatus",'') = 'ACTIVE'
       ORDER BY (u."authUserId" IS NOT NULL) DESC, u."displayName" LIMIT 4) x;
    RAISE NOTICE 'L9;%;%;%;%;;',
      replace(r.name, ';', ','), r.anzahl, r.mitmail,
      replace(coalesce(v_k, 'niemand erreichbar -- zuerst E-Mail/Telefon erfassen'), ';', ',');
  END LOOP;
END $$;
