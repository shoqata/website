-- Zwei Arbeitslisten zum Ausfuellen. Nur Ausgabe, keine Aenderung.
-- Trennzeichen Semikolon: so oeffnet Excel in der Schweiz ohne Nachfrage.
DO $$
DECLARE r record; v_z text;
BEGIN
  RAISE NOTICE 'LISTE8;Name;E-Mail;Telefon;Nachbarschaft;Geburtsdatum bitte eintragen (TT.MM.JJJJ)';
  FOR r IN
    SELECT u."displayName" AS name, coalesce(u.email,'') AS mail,
           coalesce(u.phone,'') AS tel, coalesce(n.name,'(keine)') AS nb
      FROM public.users u
      LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
     WHERE (u.birthdate IS NULL OR btrim(u.birthdate) = '')
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     ORDER BY coalesce(n.name,'zzz'), u."displayName"
  LOOP
    RAISE NOTICE 'LISTE8;%;%;%;%;',
      replace(coalesce(r.name,''), ';', ','), replace(r.mail, ';', ','),
      replace(r.tel, ';', ','), replace(r.nb, ';', ',');
  END LOOP;
END $$;
