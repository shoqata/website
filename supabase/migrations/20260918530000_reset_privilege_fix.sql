-- Rechteausweitung ueber das Zuruecksetzen von Passwoertern schliessen.
--
-- Gemessener Befund: der Betreiber der Plattform ist zugleich SUPER_ADMIN in
-- koretini, und sechs Personen desselben Vereins durften dort Passwoerter
-- setzen. Jedes Vorstandsmitglied haette damit sein Konto uebernehmen koennen
-- -- und ueber is_platform_admin() saemtliche Vereine. Aus "darf Mitglieder
-- verwalten" wurde so "darf die Plattform uebernehmen".
--
-- Der Fehler stammt aus meiner eigenen Fassung: sie prueft, ob jemand die
-- Geschaeftsfuehrung eines Vereins ist, aber nicht, WEN er sich vornimmt.
--
-- Neue Regel: zuruecksetzen darf man nur bei jemandem, der weniger Rechte hat
-- als man selbst. Wer gleich hoch steht, ist ausgenommen -- ein Vorstand kann
-- also keinen anderen Vorstand uebernehmen. Und an ein Konto des Betreibers
-- kommt ueberhaupt nur ein Betreiber.

CREATE OR REPLACE FUNCTION public.rollen_rang(p_rolle text)
RETURNS int
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE upper(coalesce(p_rolle, 'MEMBER'))
           WHEN 'SUPER_ADMIN'          THEN 4
           WHEN 'ADMIN'                THEN 3
           WHEN 'BOARD'                THEN 2
           WHEN 'NEIGHBORHOOD_MANAGER' THEN 1
           WHEN 'REPRESENTATIVE'       THEN 1
           ELSE 0
         END
$$;

CREATE OR REPLACE FUNCTION public.reset_member_password(p_member text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_mail   text;
  v_name   text;
  v_verein text;
  v_rolle  text;
  v_uid    uuid;
  v_neu    boolean := false;
  v_pw     text := '';
  v_wer    text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_betreiber boolean := public.is_platform_admin();
  v_eigener_rang int;
  v_ziel_rang    int;
  v_ziel_betreiber boolean;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int;
BEGIN
  IF NOT (public.is_member_manager() OR v_betreiber) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Passwoerter zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u.email, u."displayName", u."tenantId", u.role, u."authUserId"::uuid
    INTO v_mail, v_name, v_verein, v_rolle, v_uid
    FROM public.users u WHERE u.id = p_member;

  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  IF NOT v_betreiber AND v_verein <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- ------------------------------------------------ Wen darf man sich vornehmen?
  SELECT EXISTS (SELECT 1 FROM public.platform_admins pa
                  WHERE lower(pa.email) = lower(coalesce(v_mail, '')))
    INTO v_ziel_betreiber;

  IF v_ziel_betreiber AND NOT v_betreiber THEN
    RAISE EXCEPTION 'Dieses Konto gehoert dem Betreiber der Plattform. Nur er selbst kann es zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT v_betreiber THEN
    v_eigener_rang := public.rollen_rang(public.app_role());
    v_ziel_rang    := public.rollen_rang(v_rolle);
    IF v_ziel_rang >= v_eigener_rang THEN
      RAISE EXCEPTION
        'Sie koennen das Passwort von % (%) nicht zuruecksetzen -- diese Person hat dieselben oder mehr Rechte als Sie.',
        coalesce(v_name, v_mail), coalesce(v_rolle, 'MEMBER')
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  -- --------------------------------------------------------------- Adresse
  v_mail := lower(btrim(coalesce(v_mail, '')));
  IF v_mail = '' OR v_mail LIKE '%@koretini.legacy' OR v_mail LIKE '%no-email-%'
     OR v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Dieses Mitglied hat keine echte E-Mail-Adresse. Ohne sie gibt es kein Konto, dessen Passwort sich setzen liesse.'
      USING ERRCODE = 'check_violation';
  END IF;

  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

  IF v_uid IS NULL THEN
    SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_mail LIMIT 1;
  END IF;

  IF v_uid IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    UPDATE auth.users
       SET encrypted_password = extensions.crypt(v_pw, extensions.gen_salt('bf')),
           updated_at = now(),
           email_confirmed_at = coalesce(email_confirmed_at, now()),
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
          to_jsonb(format('durch %s fuer %s (%s, Rolle %s)', coalesce(nullif(v_wer,''),'unbekannt'),
                          coalesce(v_name, v_mail), v_mail, coalesce(v_rolle,'MEMBER'))),
          now(), now());

  RETURN jsonb_build_object(
    'ok', true, 'created', v_neu, 'email', v_mail,
    'displayName', v_name, 'password', v_pw
  );
END $$;

REVOKE ALL ON FUNCTION public.reset_member_password(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.reset_member_password(text) TO authenticated;

-- ------------------------------------------------- Geburtstagsgruesse schuetzen
-- Die Funktion stand jedem Angemeldeten offen. Sie richtet keinen grossen
-- Schaden an -- ein Gruss je Mitglied und Jahr --, aber sie schreibt in die
-- Warteschlange, und dort hat ein gewoehnliches Mitglied nichts einzufuegen.
CREATE OR REPLACE FUNCTION public.queue_birthday_greetings(p_day date DEFAULT NULL)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tag   date := COALESCE(p_day, current_date);
  v_jahr  int  := EXTRACT(YEAR FROM v_tag)::int;
  v_n     int  := 0;
  r       record;
  v_anrede text;
  v_html  text;
BEGIN
  -- Der taegliche Auftrag laeuft ohne Anmeldung; dann ist auth.uid() leer und
  -- die Pruefung entfaellt. Ein angemeldeter Aufrufer muss zur
  -- Geschaeftsfuehrung gehoeren.
  IF auth.uid() IS NOT NULL AND NOT (public.is_member_manager() OR public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Geburtstagsgruesse einreihen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR r IN
    SELECT u.id, u."tenantId", u.email,
           COALESCE(NULLIF(btrim(u."firstName"), ''), u."displayName") AS name,
           t.name AS verein
      FROM public.users u
      LEFT JOIN public.tenants t ON t.id = u."tenantId"
     WHERE u.birthdate IS NOT NULL
       AND btrim(u.birthdate::text) <> ''
       AND EXTRACT(MONTH FROM u.birthdate::date) = EXTRACT(MONTH FROM v_tag)
       AND EXTRACT(DAY   FROM u.birthdate::date) = EXTRACT(DAY   FROM v_tag)
       AND u.email IS NOT NULL
       AND btrim(u.email) <> ''
       AND u.email NOT ILIKE '%@koretini.legacy'
       AND u.email NOT ILIKE '%no-email-%'
       AND u.email LIKE '%@%.%'
       AND COALESCE(u."membershipStatus", 'ACTIVE') <> 'INACTIVE'
  LOOP
    v_anrede := COALESCE(NULLIF(btrim(r.name), ''), 'mik i dashur');
    v_html :=
      '<div style="font-family:Georgia,serif;max-width:520px;margin:0 auto;padding:32px;color:#1c1917">'
      || '<p style="font-size:26px;font-weight:bold;margin:0 0 20px">Gëzuar ditëlindjen, ' || v_anrede || '!</p>'
      || '<p style="font-size:15px;line-height:1.7;margin:0 0 24px">'
      || 'Të urojmë shëndet, gëzim dhe shumë ditë të bukura. Faleminderit që je pjesë e '
      || COALESCE(r.verein, 'shoqatës sonë') || '.</p>'
      || '<hr style="border:none;border-top:1px solid #e7e5e4;margin:28px 0">'
      || '<p style="font-size:22px;font-weight:bold;margin:0 0 16px">Herzlichen Glückwunsch zum Geburtstag, ' || v_anrede || '!</p>'
      || '<p style="font-size:14px;line-height:1.7;color:#57534e;margin:0 0 24px">'
      || 'Wir wünschen dir Gesundheit, Freude und viele schöne Tage. Danke, dass du Teil von '
      || COALESCE(r.verein, 'unserem Verein') || ' bist.</p>'
      || '<p style="font-size:12px;color:#a8a29e;margin:32px 0 0">' || COALESCE(r.verein, '') || '</p>'
      || '</div>';

    BEGIN
      INSERT INTO public.mail_queue
        ("tenantId", recipient, subject, html, kind, "memberId", "refYear")
      VALUES (r."tenantId", r.email,
              'Gëzuar ditëlindjen, ' || v_anrede || '! · Alles Gute zum Geburtstag!',
              v_html, 'BIRTHDAY', r.id, v_jahr);
      v_n := v_n + 1;
    EXCEPTION WHEN unique_violation THEN
      NULL;
    END;
  END LOOP;

  RETURN v_n;
END $$;

REVOKE ALL ON FUNCTION public.queue_birthday_greetings(date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.queue_birthday_greetings(date) TO authenticated;

NOTIFY pgrst, 'reload schema';
