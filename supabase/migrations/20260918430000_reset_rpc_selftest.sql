-- Nachweis fuer das Zuruecksetzen ueber die Datenbankfunktion.
--
-- Geprueft wird in der Rolle authenticated -- einmal als Vorstand, einmal als
-- gewoehnliches Mitglied. Der entscheidende Punkt neben der Berechtigung: die
-- erzeugte Anmeldezeile muss Feld fuer Feld so aussehen wie eine, mit der die
-- Anmeldung nachweislich gelingt. Genau dort lag der Fehler beim ersten
-- Versuch -- vier Token-Felder standen auf NULL.
DO $$
DECLARE
  v_back text := current_user;
  v_vor_uid text; v_vor_mail text;
  v_mit_uid text; v_mit_mail text;
  v_ziel text; v_ziel_mail text;
  v_ergebnis jsonb; v_err text;
  v_neu jsonb; v_gut jsonb; k text; v_untersch int := 0;
  v_pw1 text; v_pw2 text; v_hash1 text; v_hash2 text;
BEGIN
  SELECT u."authUserId", u.email INTO v_vor_uid, v_vor_mail FROM public.users u
   WHERE u.role IN ('BOARD','ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT u."authUserId", u.email INTO v_mit_uid, v_mit_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;

  -- Ein Mitglied mit echter Adresse und ohne Konto.
  SELECT u.id, u.email INTO v_ziel, v_ziel_mail FROM public.users u
   WHERE u."authUserId" IS NULL
     AND u.email IS NOT NULL AND u.email LIKE '%@%.%'
     AND u.email NOT ILIKE '%@koretini.legacy' AND u.email NOT ILIKE '%no-email-%'
     AND NOT EXISTS (SELECT 1 FROM auth.users au WHERE lower(au.email) = lower(u.email))
   LIMIT 1;

  IF v_vor_uid IS NULL OR v_ziel IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: Vorstand oder geeignetes Zielmitglied fehlt.'; RETURN;
  END IF;
  RAISE NOTICE 'Vorstand % setzt zurueck fuer % (%)', v_vor_mail, v_ziel, v_ziel_mail;

  -- ---------------------------------------------- Gegenprobe zuerst: Mitglied
  IF v_mit_uid IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      PERFORM public.reset_member_password(v_ziel);
      RAISE NOTICE '1 gewoehnliches Mitglied setzt zurueck: DURCHGELASSEN -- schwerer Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '1 gewoehnliches Mitglied setzt zurueck: abgewiesen -- richtig';
    END;
    EXECUTE format('SET ROLE %I', v_back);
  END IF;

  -- ------------------------------------------------------------- Vorstand
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_vor_uid, 'role','authenticated','email', v_vor_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    v_ergebnis := public.reset_member_password(v_ziel);
    v_pw1 := v_ergebnis ->> 'password';
    RAISE NOTICE '2 Vorstand setzt zurueck: gelungen, Konto neu angelegt = %',
      v_ergebnis ->> 'created';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '2 Vorstand setzt zurueck: FEHLGESCHLAGEN -- %', v_err;
    EXECUTE format('SET ROLE %I', v_back); RETURN;
  END;

  -- Ein zweites Mal: jetzt besteht das Konto, es darf kein weiteres entstehen.
  v_ergebnis := public.reset_member_password(v_ziel);
  v_pw2 := v_ergebnis ->> 'password';
  RAISE NOTICE '3 erneut: Konto neu angelegt = % -- erwartet false', v_ergebnis ->> 'created';

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Das zweite Passwort muss gelten, das erste nicht mehr.
  SELECT encrypted_password INTO v_hash1 FROM auth.users WHERE lower(email) = lower(v_ziel_mail);
  RAISE NOTICE '4 zweites Passwort passt zum Konto: %  -- erwartet t',
    (v_hash1 = extensions.crypt(v_pw2, v_hash1));
  RAISE NOTICE '5 erstes Passwort gilt nicht mehr: %  -- erwartet t',
    (v_hash1 <> extensions.crypt(v_pw1, v_hash1));

  -- Der eigentliche Punkt: sieht die Zeile aus wie eine funktionierende?
  SELECT to_jsonb(au) INTO v_neu FROM auth.users au WHERE lower(au.email) = lower(v_ziel_mail);
  SELECT to_jsonb(au) INTO v_gut FROM auth.users au WHERE au.email = 'selmani.besart@hotmail.com';
  FOR k IN SELECT jsonb_object_keys(v_gut) ORDER BY 1 LOOP
    IF k IN ('id','email','created_at','updated_at','encrypted_password',
             'email_confirmed_at','confirmed_at','last_sign_in_at') THEN CONTINUE; END IF;
    IF (v_neu -> k) IS DISTINCT FROM (v_gut -> k) THEN
      RAISE NOTICE '   Unterschied bei %: neu=% funktionierend=%', k, (v_neu->k)::text, (v_gut->k)::text;
      v_untersch := v_untersch + 1;
    END IF;
  END LOOP;
  RAISE NOTICE '6 Unterschiede zu einer funktionierenden Anmeldezeile: % -- erwartet 0', v_untersch;

  RAISE NOTICE '7 Identitaeten zum neuen Konto: % -- erwartet 1',
    (SELECT count(*) FROM auth.identities i
      JOIN auth.users au ON au.id = i.user_id WHERE lower(au.email) = lower(v_ziel_mail));
  RAISE NOTICE '8 Mitgliedszeile verknuepft: % -- erwartet t',
    (SELECT "authUserId" IS NOT NULL FROM public.users WHERE id = v_ziel);

  -- Aufraeumen: das Testkonto wieder entfernen.
  DELETE FROM auth.identities WHERE user_id IN
    (SELECT id FROM auth.users WHERE lower(email) = lower(v_ziel_mail));
  DELETE FROM auth.users WHERE lower(email) = lower(v_ziel_mail);
  UPDATE public.users SET "authUserId" = NULL WHERE id = v_ziel;
  DELETE FROM public.security_logs WHERE "userId" = v_ziel AND type = 'PASSWORD_RESET';
  RAISE NOTICE 'Testkonto entfernt, Mitgliedszeile zurueckgesetzt.';
END $$;
