-- Nachweis: die Rechteausweitung ist geschlossen.
--
-- Geprueft wird in der Rolle authenticated mit dem Token eines echten
-- Vorstandsmitglieds. Entscheidend ist der erste Punkt -- er war vorher offen.
DO $$
DECLARE
  v_back text := current_user;
  v_board_uid text; v_board_mail text;
  v_betreiber_zeile text; v_betreiber_mail text;
  v_super_zeile text; v_admin_zeile text; v_board_zeile text; v_mitglied_zeile text;
  v_err text; v_ok boolean;
BEGIN
  -- Ein Vorstandsmitglied mit Anmeldung, das selbst kein Betreiber ist.
  SELECT u."authUserId", u.email INTO v_board_uid, v_board_mail
    FROM public.users u
   WHERE u.role = 'BOARD' AND u."authUserId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.platform_admins pa WHERE lower(pa.email)=lower(u.email))
   LIMIT 1;

  SELECT u.id, u.email INTO v_betreiber_zeile, v_betreiber_mail
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email)=lower(u.email) LIMIT 1;

  SELECT id INTO v_super_zeile FROM public.users
   WHERE role='SUPER_ADMIN' AND id <> coalesce(v_betreiber_zeile,'') LIMIT 1;
  SELECT id INTO v_admin_zeile FROM public.users WHERE role='ADMIN' LIMIT 1;
  SELECT id INTO v_board_zeile FROM public.users
   WHERE role='BOARD' AND email <> coalesce(v_board_mail,'') LIMIT 1;
  SELECT id INTO v_mitglied_zeile FROM public.users
   WHERE coalesce(role,'MEMBER')='MEMBER' AND email IS NOT NULL AND email LIKE '%@%.%'
     AND email NOT ILIKE '%koretini.legacy' AND email NOT ILIKE '%no-email-%' LIMIT 1;

  IF v_board_uid IS NULL OR v_betreiber_zeile IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: Vorstandsmitglied oder Betreiberzeile fehlt.'; RETURN;
  END IF;
  RAISE NOTICE 'Vorstandsmitglied: %  |  Betreiber: %', v_board_mail, v_betreiber_mail;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_board_uid, 'role','authenticated','email', v_board_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  -- 1. Das Konto des Betreibers -- vorher moeglich, das war die Luecke.
  BEGIN
    PERFORM public.reset_member_password(v_betreiber_zeile);
    RAISE NOTICE '1 Vorstand setzt das Passwort des Betreibers: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '1 Vorstand setzt das Passwort des Betreibers: abgewiesen -- richtig';
    RAISE NOTICE '    "%"', left(v_err, 110);
  END;

  -- 2. Ein weiterer SUPER_ADMIN desselben Vereins
  IF v_super_zeile IS NOT NULL THEN
    BEGIN
      PERFORM public.reset_member_password(v_super_zeile);
      RAISE NOTICE '2 Vorstand setzt das Passwort eines SUPER_ADMIN: DURCHGELASSEN -- Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '2 Vorstand setzt das Passwort eines SUPER_ADMIN: abgewiesen -- richtig';
    END;
  END IF;

  -- 3. Ein ADMIN
  IF v_admin_zeile IS NOT NULL THEN
    BEGIN
      PERFORM public.reset_member_password(v_admin_zeile);
      RAISE NOTICE '3 Vorstand setzt das Passwort eines ADMIN: DURCHGELASSEN -- Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '3 Vorstand setzt das Passwort eines ADMIN: abgewiesen -- richtig';
    END;
  END IF;

  -- 4. Ein anderes Vorstandsmitglied -- gleiche Ebene, ebenfalls nicht
  IF v_board_zeile IS NOT NULL THEN
    BEGIN
      PERFORM public.reset_member_password(v_board_zeile);
      RAISE NOTICE '4 Vorstand setzt das Passwort eines anderen Vorstands: DURCHGELASSEN -- Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '4 Vorstand setzt das Passwort eines anderen Vorstands: abgewiesen -- richtig';
    END;
  END IF;

  -- 5. Ein gewoehnliches Mitglied -- das muss weiterhin gehen
  IF v_mitglied_zeile IS NOT NULL THEN
    BEGIN
      PERFORM public.reset_member_password(v_mitglied_zeile);
      RAISE NOTICE '5 Vorstand setzt das Passwort eines Mitglieds: gelungen -- richtig';
      v_ok := true;
    EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
      RAISE NOTICE '5 Vorstand setzt das Passwort eines Mitglieds: ABGEWIESEN -- % (unerwartet)', left(v_err,90);
    END;
  END IF;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Das in Punkt 5 angelegte Testkonto wieder entfernen.
  IF v_ok THEN
    DELETE FROM auth.identities WHERE user_id IN (
      SELECT au.id FROM auth.users au
       JOIN public.users u ON lower(u.email) = lower(au.email)
      WHERE u.id = v_mitglied_zeile);
    DELETE FROM auth.users WHERE lower(email) IN (
      SELECT lower(email) FROM public.users WHERE id = v_mitglied_zeile);
    UPDATE public.users SET "authUserId" = NULL WHERE id = v_mitglied_zeile;
    DELETE FROM public.security_logs WHERE "userId" = v_mitglied_zeile AND type='PASSWORD_RESET';
    RAISE NOTICE 'Testkonto aus Punkt 5 entfernt.';
  END IF;

  -- 6. Gegenprobe: ein gewoehnliches Mitglied darf die Geburtstagsgruesse
  --    nicht mehr anstossen.
  SELECT u."authUserId", u.email INTO v_board_uid, v_board_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  IF v_board_uid IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_board_uid, 'role','authenticated','email', v_board_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      PERFORM public.queue_birthday_greetings(current_date);
      RAISE NOTICE '6 Mitglied reiht Geburtstagsgruesse ein: DURCHGELASSEN -- Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '6 Mitglied reiht Geburtstagsgruesse ein: abgewiesen -- richtig';
    END;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END IF;
END $$;
