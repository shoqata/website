-- Zwei Arbeitslisten zum Ausfuellen. Nur Ausgabe, keine Aenderung.
-- Trennzeichen Semikolon: so oeffnet Excel in der Schweiz ohne Nachfrage.
DO $$
DECLARE r record; v_kandidaten text;
BEGIN
  -- --- Liste 1: fehlende Geburtsdaten -------------------------------------
  RAISE NOTICE 'L8;Nachbarschaft;Name;E-Mail;Telefon;Geburtsdatum (TT.MM.JJJJ)';
  FOR r IN
    SELECT u."displayName" AS name, coalesce(u.email,'') AS mail,
           coalesce(u.phone,'') AS tel, coalesce(n.name,'(keine)') AS nb
      FROM public.users u
      LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
     WHERE (u.birthdate IS NULL OR btrim(u.birthdate) = '')
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     ORDER BY coalesce(n.name,'zzzz'), u."displayName"
  LOOP
    RAISE NOTICE 'L8;%;%;%;%;',
      replace(r.nb, ';', ','), replace(coalesce(r.name,''), ';', ','),
      replace(r.mail, ';', ','), replace(r.tel, ';', ',');
  END LOOP;

  -- --- Liste 2: Nachbarschaften ohne verantwortliche Person ---------------
  -- Mit Vorschlaegen: die Mitglieder der jeweiligen Nachbarschaft, die
  -- erreichbar sind (E-Mail und Telefon hinterlegt) und ein Anmeldekonto
  -- haben -- ohne das kann niemand die Rolle ausueben.
  RAISE NOTICE 'L9;Nachbarschaft;Mitglieder;davon erreichbar;Vorschlaege (erreichbar, mit Konto);Verantwortlich soll sein';
  FOR r IN
    SELECT n.id, n.name,
           (SELECT count(*) FROM public.users u WHERE u."neighborhoodId" = n.id) AS anzahl,
           (SELECT count(*) FROM public.users u WHERE u."neighborhoodId" = n.id
             AND coalesce(u.email,'') <> '' AND coalesce(u.phone,'') <> '') AS erreichbar
      FROM public.neighborhoods n
     WHERE NOT EXISTS (SELECT 1 FROM public.users u
                        WHERE n."contactPersonIds" @> to_jsonb(u.id)
                           OR n."representativeId" = u.id OR n."managerId" = u.id)
     ORDER BY 3 DESC, n.name
  LOOP
    SELECT string_agg(x.name, ' / ') INTO v_kandidaten FROM (
      SELECT u."displayName" AS name FROM public.users u
       WHERE u."neighborhoodId" = r.id
         AND coalesce(u.email,'') <> '' AND coalesce(u.phone,'') <> ''
         AND u."authUserId" IS NOT NULL
         AND coalesce(u."membershipStatus",'') = 'ACTIVE'
       ORDER BY u."displayName" LIMIT 3) x;
    RAISE NOTICE 'L9;%;%;%;%;',
      replace(r.name, ';', ','), r.anzahl, r.erreichbar,
      replace(coalesce(v_kandidaten, 'niemand mit Konto -- zuerst Konto anlegen'), ';', ',');
  END LOOP;
END $$;
