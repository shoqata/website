-- Passwort zuruecksetzen ueber denselben Weg wie alles andere.
--
-- Bisher lief das ueber eine Edge Function unter /functions/v1/. Zweimal kam
-- dabei kein Konto zustande, und zwar spurlos: kein Konto, kein
-- Protokolleintrag, waehrend gleichzeitig jede andere Aktion der Anwendung
-- durchging. Das passt zu einem blockierten Pfad -- /functions/v1/ ist eine
-- andere Adresse als /rest/v1/, und Werbeblocker oder Firmennetze behandeln
-- sie unterschiedlich. Die Meldung "TypeError: Failed to fetch" deutet genau
-- darauf: die Anfrage erreicht den Server nicht.
--
-- Diese Funktion liegt in der Datenbank und wird ueber /rest/v1/rpc/
-- aufgerufen -- derselbe Weg, ueber den Mitglieder, Rechnungen und Protokolle
-- laufen und der nachweislich funktioniert.
--
-- Der Aufbau der Anmeldezeile folgt zwei Konten, die damit angelegt wurden und
-- sich beide anmelden koennen. Die vier Token-Felder muessen auf dem leeren
-- String stehen: auf NULL bricht GoTrue mit "Database error querying schema"
-- ab, obwohl Konto, Passwort und Identitaet stimmen.

CREATE OR REPLACE FUNCTION public.reset_member_password(p_member text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_mail   text;
  v_name   text;
  v_verein text;
  v_uid    uuid;
  v_neu    boolean := false;
  v_pw     text := '';
  v_wer    text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int;
BEGIN
  -- Wer darf: Administration und Vorstand des eigenen Vereins, sowie der
  -- Betreiber der Plattform. Entschieden wird das hier, nicht im Client.
  IF NOT (public.is_member_manager() OR public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Passwoerter zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u.email, u."displayName", u."tenantId", u."authUserId"::uuid
    INTO v_mail, v_name, v_verein, v_uid
    FROM public.users u WHERE u.id = p_member;

  IF v_mail IS NULL AND v_verein IS NULL THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  IF NOT public.is_platform_admin() AND v_verein <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_mail := lower(btrim(coalesce(v_mail, '')));
  IF v_mail = '' OR v_mail LIKE '%@koretini.legacy' OR v_mail LIKE '%no-email-%'
     OR v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Dieses Mitglied hat keine echte E-Mail-Adresse. Ohne sie gibt es kein Konto, dessen Passwort sich setzen liesse.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Lesbar, ohne verwechselbare Zeichen.
  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

  -- Ein Konto kann auch unter der Adresse bestehen, ohne dass die
  -- Mitgliedszeile darauf verweist.
  IF v_uid IS NULL THEN
    SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_mail LIMIT 1;
  END IF;

  IF v_uid IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    UPDATE auth.users
       SET encrypted_password = extensions.crypt(v_pw, extensions.gen_salt('bf')),
           updated_at = now(),
           email_confirmed_at = coalesce(email_confirmed_at, now()),
           -- Auf NULL bricht die Anmeldung ab; das gilt auch fuer Konten,
           -- die von anderswoher stammen.
           confirmation_token     = coalesce(confirmation_token, ''),
           recovery_token         = coalesce(recovery_token, ''),
           email_change_token_new = coalesce(email_change_token_new, ''),
           email_change           = coalesce(email_change, '')
     WHERE id = v_uid;
  ELSE
    v_neu := true;
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
      false, false, '', '', '', ''
    );

    -- Ohne diese Zeile laesst GoTrue keine Anmeldung mit Passwort zu.
    INSERT INTO auth.identities (
      id, user_id, provider_id, identity_data, provider, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::text,
      jsonb_build_object('sub', v_uid::text, 'email', v_mail,
                         'email_verified', true, 'phone_verified', false),
      'email', now(), now()
    );
  END IF;

  UPDATE public.users SET "authUserId" = v_uid::text WHERE id = p_member;

  INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
  VALUES (gen_random_uuid(), v_verein, 'PASSWORD_RESET',
          CASE WHEN v_neu THEN 'ACCOUNT_CREATED' ELSE 'PASSWORD_SET' END,
          p_member,
          to_jsonb(format('durch %s fuer %s (%s)', coalesce(nullif(v_wer,''),'unbekannt'),
                          coalesce(v_name, v_mail), v_mail)),
          now(), now());

  RETURN jsonb_build_object(
    'ok', true, 'created', v_neu, 'email', v_mail,
    'displayName', v_name, 'password', v_pw
  );
END $$;

REVOKE ALL ON FUNCTION public.reset_member_password(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.reset_member_password(text) TO authenticated;

NOTIFY pgrst, 'reload schema';
