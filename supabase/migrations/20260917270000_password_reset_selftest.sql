-- Wer darf ein fremdes Passwort setzen?
--
-- Die Pruefung steckt in der Server-Funktion, nicht in der Datenbank. Hier
-- wird daher belegt, worauf sich diese Funktion stuetzt: dass Rolle, Verein
-- und Betreiberliste in der Datenbank eindeutig beantwortbar sind -- und dass
-- die Mehrheit der Mitglieder ueberhaupt kein Konto hat, an das ein Passwort
-- gebunden waere.
DO $$
DECLARE
  v_betreiber int; v_admins int; v_mitglieder int;
  v_mit_konto int; v_ohne_mail int; v_vereine int;
  r record;
BEGIN
  SELECT count(*) INTO v_betreiber FROM public.platform_admins;
  SELECT count(*) INTO v_vereine   FROM public.tenants;
  SELECT count(*) INTO v_admins    FROM public.users WHERE role IN ('ADMIN','SUPER_ADMIN','BOARD');
  SELECT count(*) INTO v_mitglieder FROM public.users;
  SELECT count(*) INTO v_mit_konto FROM public.users WHERE "authUserId" IS NOT NULL;
  SELECT count(*) INTO v_ohne_mail FROM public.users
   WHERE email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%';

  RAISE NOTICE 'Vereine: %, Betreiber der Plattform: %', v_vereine, v_betreiber;
  RAISE NOTICE 'Mitglieder gesamt: %, davon mit Anmeldekonto: %', v_mitglieder, v_mit_konto;
  RAISE NOTICE 'Berechtigt zum Zuruecksetzen (ADMIN/SUPER_ADMIN/BOARD): %', v_admins;
  RAISE NOTICE 'Ohne brauchbare E-Mail -- fuer diese lehnt die Funktion ab: %', v_ohne_mail;

  RAISE NOTICE '--- Wer darf, und in welchem Verein ---';
  FOR r IN SELECT role, "tenantId", count(*) AS n FROM public.users
            WHERE role IN ('ADMIN','SUPER_ADMIN','BOARD')
            GROUP BY role, "tenantId" ORDER BY "tenantId", role LOOP
    RAISE NOTICE '  % in %: %', r.role, r."tenantId", r.n;
  END LOOP;

  -- Mehr als ein Verein waere die interessante Lage: dann muss die Funktion
  -- ueber Vereinsgrenzen hinweg sperren. Bei nur einem Verein kann sie hier
  -- nicht scharf geprueft werden -- das gehoert festgehalten, nicht kaschiert.
  IF v_vereine < 2 THEN
    RAISE NOTICE 'HINWEIS: nur % Verein vorhanden -- die Sperre ueber Vereinsgrenzen', v_vereine;
    RAISE NOTICE '         hinweg ist hier nicht pruefbar, sie steht in der Funktion.';
  END IF;
END $$;
