-- Anmeldekonto fuer valton.rexha@gmail.com -- zweiter Anlauf.
--
-- Der erste scheiterte zweimal, und die zweite Ursache ist der eigentliche
-- Fund: security_logs.details ist keine Textspalte, sondern json. Eine
-- gewoehnliche Zeichenkette hineinzuschreiben ergibt "invalid input syntax for
-- type json". In den bisherigen Protokollausgaben stand der Text deshalb in
-- Anfuehrungszeichen -- das war der Hinweis, den ich vorher uebersehen hatte.
--
-- Der Aufbau folgt einem bestehenden Konto, Feld fuer Feld nachgesehen:
-- aud und role 'authenticated', instance_id die Nullkennung,
-- raw_app_meta_data mit dem Anbieter email, dazu eine Zeile in
-- auth.identities -- ohne sie laesst GoTrue keine Anmeldung mit Passwort zu.
DO $$
DECLARE
  v_mail   text := 'valton.rexha@gmail.com';
  v_zeile  text; v_verein text;
  v_uid    uuid;
  v_pw     text := '';
  v_typ    text;
  v_da     int;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int;
BEGIN
  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='security_logs' AND column_name='details';
  RAISE NOTICE 'security_logs.details ist vom Typ % -- deshalb to_jsonb()', v_typ;

  SELECT id, "tenantId" INTO v_zeile, v_verein FROM public.users WHERE lower(email) = v_mail;
  IF v_zeile IS NULL THEN RAISE EXCEPTION 'Keine Mitgliedszeile mit dieser Adresse.'; END IF;

  SELECT count(*) INTO v_da FROM auth.users WHERE lower(email) = v_mail;
  IF v_da > 0 THEN
    RAISE NOTICE 'Es gibt bereits ein Konto zu % -- es wird nichts angelegt.', v_mail;
    RETURN;
  END IF;

  -- Lesbar, ohne verwechselbare Zeichen, 14 Stellen.
  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

  v_uid := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, is_sso_user, is_anonymous
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
    v_mail, extensions.crypt(v_pw, extensions.gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"email_verified":true}'::jsonb,
    false, false, false
  );

  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_uid, v_uid::text,
    jsonb_build_object('sub', v_uid::text, 'email', v_mail,
                       'email_verified', true, 'phone_verified', false),
    'email', NULL, now(), now()
  );

  UPDATE public.users SET "authUserId" = v_uid::text WHERE id = v_zeile;

  INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
  VALUES (gen_random_uuid(), v_verein, 'PASSWORD_RESET', 'ACCOUNT_CREATED', v_zeile,
          to_jsonb('Konto in der Datenbank angelegt, nachdem der Adminbereich keines erzeugt hatte'::text),
          now(), now());

  RAISE NOTICE '==================================================';
  RAISE NOTICE ' Konto angelegt fuer %', v_mail;
  RAISE NOTICE ' Passwort: %', v_pw;
  RAISE NOTICE ' verknuepft mit der Mitgliedszeile %', v_zeile;
  RAISE NOTICE '==================================================';
END $$;

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Konten im Vergleich ===';
  FOR r IN SELECT au.email, au.aud, au.role,
                  (au.email_confirmed_at IS NOT NULL) AS bestaetigt,
                  (au.encrypted_password IS NOT NULL) AS passwort,
                  (SELECT count(*) FROM auth.identities i WHERE i.user_id = au.id) AS identitaeten,
                  (SELECT count(*) FROM public.users u WHERE u."authUserId" = au.id::text) AS verknuepft
             FROM auth.users au ORDER BY au.created_at LOOP
    RAISE NOTICE '  % | % / % | bestaetigt % | Passwort % | Identitaeten % | verknuepft %',
      r.email, r.aud, r.role, r.bestaetigt, r.passwort, r.identitaeten, r.verknuepft;
  END LOOP;
END $$;
