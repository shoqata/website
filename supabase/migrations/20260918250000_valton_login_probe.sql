-- Warum kommt Valton Rexha mit dem neuen Passwort nicht herein?
--
-- Drei Dinge muessen stimmen, damit eine Anmeldung gelingt: es gibt ein Konto
-- zu dieser Adresse, das Konto hat ein Passwort, und die Adresse gilt als
-- bestaetigt. Faellt eines davon aus, weist Supabase die Anmeldung ab -- mit
-- einer Meldung, die alle drei Faelle gleich aussehen laesst.
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Mitgliedszeilen mit dieser Adresse ===';
  FOR r IN SELECT u.id, u."displayName", u.email, coalesce(u."authUserId",'-') AS konto,
                  coalesce(u.role,'-') AS rolle, coalesce(u."membershipStatus",'-') AS status,
                  coalesce(u."tenantId",'-') AS verein
             FROM public.users u
            WHERE lower(u.email) LIKE '%valton%' OR lower(u."displayName") LIKE '%valton%'
               OR lower(u."displayName") LIKE '%rexha%' LOOP
    RAISE NOTICE '  % | % | %', r.id, r."displayName", r.email;
    RAISE NOTICE '     Konto % | Rolle % | Status % | Verein %', r.konto, r.rolle, r.status, r.verein;
  END LOOP;

  RAISE NOTICE '=== Anmeldekonten insgesamt ===';
  SELECT count(*) INTO v_n FROM auth.users;
  RAISE NOTICE '  % Konten', v_n;
  FOR r IN SELECT au.id, au.email,
                  (au.email_confirmed_at IS NOT NULL) AS bestaetigt,
                  (au.encrypted_password IS NOT NULL AND au.encrypted_password <> '') AS hat_passwort,
                  au.last_sign_in_at, au.created_at, au.updated_at,
                  coalesce(au.banned_until::text,'-') AS gesperrt_bis,
                  coalesce(au.deleted_at::text,'-') AS geloescht
             FROM auth.users au ORDER BY au.created_at LOOP
    RAISE NOTICE '  %', r.email;
    RAISE NOTICE '     id % | bestaetigt % | Passwort gesetzt %', r.id, r.bestaetigt, r.hat_passwort;
    RAISE NOTICE '     angelegt % | zuletzt geaendert %', r.created_at, r.updated_at;
    RAISE NOTICE '     zuletzt angemeldet % | gesperrt bis % | geloescht %',
      coalesce(r.last_sign_in_at::text,'nie'), r.gesperrt_bis, r.geloescht;
  END LOOP;

  RAISE NOTICE '=== Verknuepfung Konto <-> Mitgliedszeile ===';
  FOR r IN SELECT au.email,
                  (SELECT count(*) FROM public.users u WHERE lower(u.email) = lower(au.email)) AS zeilen,
                  (SELECT count(*) FROM public.users u WHERE u."authUserId" = au.id::text) AS verknuepft
             FROM auth.users au LOOP
    RAISE NOTICE '  % -> passende Zeilen %, verknuepft %', r.email, r.zeilen, r.verknuepft;
  END LOOP;

  RAISE NOTICE '=== Wurde das Zuruecksetzen protokolliert? ===';
  FOR r IN SELECT "createdAt", type, action, details FROM public.security_logs
            WHERE type = 'PASSWORD_RESET' ORDER BY "createdAt" DESC LIMIT 5 LOOP
    RAISE NOTICE '  % | % / % | %', r."createdAt", r.type, r.action, r.details;
  END LOOP;
  IF NOT FOUND THEN RAISE NOTICE '  kein Eintrag'; END IF;
END $$;
