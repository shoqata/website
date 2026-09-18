-- Anmeldekonto fuer axhija.sokol@gmail.com.
--
-- Gleiches Bild wie zuvor bei Valton Rexha: kein Konto, kein Protokolleintrag
-- -- die Anfrage hat den Server nie erreicht. Das Konto wird deshalb hier
-- angelegt, mit allen Feldern, die GoTrue erwartet. Die vier Token-Felder auf
-- den leeren String zu setzen ist dabei nicht optional: auf NULL bricht der
-- Dienst mit "Database error querying schema" ab.
DO $$
DECLARE
  v_mail   text := 'axhija.sokol@gmail.com';
  v_zeile  text; v_verein text;
  v_uid    uuid;
  v_pw     text := '';
  v_da     int;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int;
BEGIN
  SELECT id, "tenantId" INTO v_zeile, v_verein FROM public.users WHERE lower(email) = v_mail;
  IF v_zeile IS NULL THEN RAISE EXCEPTION 'Keine Mitgliedszeile mit dieser Adresse.'; END IF;

  SELECT count(*) INTO v_da FROM auth.users WHERE lower(email) = v_mail;
  IF v_da > 0 THEN
    RAISE NOTICE 'Es gibt bereits ein Konto zu % -- es wird nichts angelegt.', v_mail;
    RETURN;
  END IF;

  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

  v_uid := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_sso_user, is_anonymous,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
    v_mail, extensions.crypt(v_pw, extensions.gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"email_verified":true}'::jsonb,
    false, false,
    '', '', '', ''
  );

  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_uid, v_uid::text,
    jsonb_build_object('sub', v_uid::text, 'email', v_mail,
                       'email_verified', true, 'phone_verified', false),
    'email', now(), now()
  );

  UPDATE public.users SET "authUserId" = v_uid::text WHERE id = v_zeile;

  INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
  VALUES (gen_random_uuid(), v_verein, 'PASSWORD_RESET', 'ACCOUNT_CREATED', v_zeile,
          to_jsonb('Konto in der Datenbank angelegt, nachdem der Adminbereich keines erzeugt hatte'::text),
          now(), now());

  RAISE NOTICE '==================================================';
  RAISE NOTICE ' Konto angelegt fuer %', v_mail;
  RAISE NOTICE ' Passwort: %', v_pw;
  RAISE NOTICE '==================================================';
END $$;
