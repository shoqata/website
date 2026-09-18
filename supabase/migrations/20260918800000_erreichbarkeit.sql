-- Wie viele Mitglieder sind ueberhaupt erreichbar, und wie viele koennen
-- sich anmelden? Davon haengt ab, was die Arbeitslisten ueberhaupt bringen.
DO $$
DECLARE v_n int; v_g int;
BEGIN
  SELECT count(*) INTO v_g FROM public.users;

  SELECT count(*) INTO v_n FROM public.users
   WHERE coalesce(email,'') <> '' AND email NOT ILIKE '%@koretini.legacy'
     AND email NOT ILIKE '%no-email-%';
  RAISE NOTICE 'Echte E-Mail-Adresse:      % von %', v_n, v_g;

  SELECT count(*) INTO v_n FROM public.users WHERE "authUserId" IS NOT NULL;
  RAISE NOTICE 'Kann sich anmelden:        % von %', v_n, v_g;

  SELECT count(*) INTO v_n FROM public.users WHERE coalesce(phone,'') <> '';
  RAISE NOTICE 'Telefonnummer hinterlegt:  % von %', v_n, v_g;

  SELECT count(*) INTO v_n FROM public.users
   WHERE (birthdate IS NULL OR btrim(birthdate)='')
     AND coalesce(email,'') <> '' AND email NOT ILIKE '%@koretini.legacy'
     AND email NOT ILIKE '%no-email-%';
  RAISE NOTICE 'Ohne Geburtsdatum, aber mit echter E-Mail: %', v_n;

  SELECT count(*) INTO v_n FROM public.users
   WHERE birthdate IS NOT NULL AND btrim(birthdate) <> ''
     AND coalesce(email,'') <> '' AND email NOT ILIKE '%@koretini.legacy'
     AND email NOT ILIKE '%no-email-%';
  RAISE NOTICE 'Geburtstagsgruss erreicht heute: % Mitglieder', v_n;
END $$;
