-- Betreiber und Verein trennen.
--
-- Bisher war der Betreiber der Plattform zugleich SUPER_ADMIN in koretini.
-- Genau diese Kopplung war die Voraussetzung der Rechteausweitung, die heute
-- geschlossen wurde: wer im Verein Passwoerter setzen darf, haette sein Konto
-- uebernehmen koennen.
--
-- Kuenftig:
--   burim@dervishi.ch  -- Betreiber der Plattform, in keinem Verein Mitglied.
--                         Zugriff auf einen Verein nur ueber eine
--                         Betreuungssitzung, die mit Anfang und Ende stehen
--                         bleibt.
--   email@dervishi.ch  -- Administration von Koretini, gewoehnliche
--                         Mitgliedszeile mit allem, was daran haengt.
--
-- Nachgesehen, bevor umgestellt wird: is_platform_admin() prueft allein die
-- E-Mail im Anmeldetoken gegen platform_admins. Eine Mitgliedszeile braucht
-- der Betreiber also nicht -- er wuerde sich sonst aussperren.
DO $$
DECLARE
  v_betreiber text := 'burim@dervishi.ch';
  v_verein    text := 'email@dervishi.ch';
  v_alt_zeile text;   -- bisherige Zeile burim@dervishi.ch (BOARD, IT)
  v_neu_zeile text;   -- kuenftige Koretini-Zeile
  v_dublette  text;
  v_uid uuid; v_pw text := ''; v_da int;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int; v_n int;
BEGIN
  SELECT id INTO v_alt_zeile FROM public.users WHERE email = v_betreiber;
  SELECT id INTO v_neu_zeile FROM public.users WHERE email = v_verein;
  SELECT id INTO v_dublette  FROM public.users WHERE email = 'burim_roPmU@dervishi.ch';

  IF v_alt_zeile IS NULL OR v_neu_zeile IS NULL THEN
    RAISE EXCEPTION 'Eine der beiden Zeilen fehlt -- nichts geaendert.';
  END IF;

  -- 1. Was an der bisherigen Betreiberzeile haengt, zieht auf die
  --    Koretini-Zeile um. Zuerst die Zahlung, dann die Vorstandsfunktion.
  UPDATE public.payments SET "userId" = v_neu_zeile WHERE "userId" = v_alt_zeile;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '1 Zahlungen umgehaengt: %', v_n;

  UPDATE public.board_members SET "userId" = v_neu_zeile WHERE "userId" = v_alt_zeile;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '2 Vorstandseintraege umgehaengt: %', v_n;

  UPDATE public.neighborhoods SET "representativeId" = v_neu_zeile WHERE "representativeId" = v_alt_zeile;
  UPDATE public.neighborhoods SET "managerId"        = v_neu_zeile WHERE "managerId" = v_alt_zeile;
  UPDATE public.neighborhoods
     SET "contactPersonIds" = ("contactPersonIds" - v_alt_zeile) || to_jsonb(ARRAY[v_neu_zeile])
   WHERE "contactPersonIds" @> to_jsonb(v_alt_zeile);

  -- 2. Die Koretini-Zeile bekommt Namen und Rolle.
  UPDATE public.users
     SET role = 'ADMIN',
         "displayName" = 'Burim Dervishi',
         "firstName" = coalesce(nullif(btrim("firstName"),''), 'Burim'),
         "lastName"  = coalesce(nullif(btrim("lastName"),''),  'Dervishi')
   WHERE id = v_neu_zeile;
  RAISE NOTICE '3 % ist jetzt ADMIN in koretini', v_verein;

  -- 3. Die beiden ueberzaehligen Zeilen entfernen.
  DELETE FROM public.users WHERE id IN (v_alt_zeile, coalesce(v_dublette, '---'));
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '4 Mitgliedszeilen entfernt: %', v_n;

  -- 4. Betreiberrechte umhaengen.
  DELETE FROM public.platform_admins WHERE lower(email) = lower(v_verein);
  INSERT INTO public.platform_admins (email) VALUES (v_betreiber)
    ON CONFLICT DO NOTHING;
  DELETE FROM public.admin_emails WHERE lower(email) = lower(v_verein);
  INSERT INTO public.admin_emails (email) VALUES (v_betreiber)
    ON CONFLICT DO NOTHING;
  RAISE NOTICE '5 Betreiber ist jetzt %', v_betreiber;

  -- 5. Anmeldekonto fuer den Betreiber. Ohne eines waere er ausgesperrt: die
  --    bisherige Anmeldung gehoert zu email@dervishi.ch und bleibt dort.
  SELECT count(*) INTO v_da FROM auth.users WHERE lower(email) = lower(v_betreiber);
  IF v_da > 0 THEN
    RAISE NOTICE '6 Anmeldekonto fuer % besteht bereits.', v_betreiber;
  ELSE
    FOR i IN 1..14 LOOP
      v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    END LOOP;
    v_uid := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
      lower(v_betreiber), extensions.crypt(v_pw, extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"email_verified":true}'::jsonb, false, false, '', '', '', ''
    );
    INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at)
    VALUES (gen_random_uuid(), v_uid, v_uid::text,
            jsonb_build_object('sub', v_uid::text, 'email', lower(v_betreiber),
                               'email_verified', true, 'phone_verified', false),
            'email', now(), now());

    RAISE NOTICE '===================================================';
    RAISE NOTICE ' Betreiberkonto angelegt: %', v_betreiber;
    RAISE NOTICE ' Passwort: %', v_pw;
    RAISE NOTICE '===================================================';
  END IF;
END $$;

-- ------------------------------------------------------------- Gegenprobe
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Zustand nachher ===';
  FOR r IN SELECT u.id, u.email, u.role, u."tenantId",
                  (SELECT count(*) FROM public.board_members b WHERE b."userId"=u.id) AS vorstand,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id) AS zahlungen,
                  (u."authUserId" IS NOT NULL) AS konto
             FROM public.users u WHERE u.email LIKE '%dervishi.ch' ORDER BY u.email LOOP
    RAISE NOTICE '  % (%) | % in % | Vorstand % | Zahlungen % | Konto %',
      r.email, r.id, r.role, r."tenantId", r.vorstand, r.zahlungen, r.konto;
  END LOOP;

  RAISE NOTICE '=== Betreiber ===';
  FOR r IN SELECT email FROM public.platform_admins LOOP RAISE NOTICE '  platform_admins: %', r.email; END LOOP;
  FOR r IN SELECT email FROM public.admin_emails    LOOP RAISE NOTICE '  admin_emails:    %', r.email; END LOOP;

  SELECT count(*) INTO v_n FROM public.users u
   WHERE EXISTS (SELECT 1 FROM public.platform_admins pa WHERE lower(pa.email)=lower(u.email));
  RAISE NOTICE 'Betreiber, die zugleich Vereinsmitglied sind: % -- erwartet 0', v_n;

  RAISE NOTICE '=== Vorstandsliste ===';
  FOR r IN SELECT bm.role AS funktion, coalesce(u."displayName",'<Zeile fehlt>') AS person, coalesce(u.email,'-') AS mail
             FROM public.board_members bm LEFT JOIN public.users u ON u.id = bm."userId"
            ORDER BY bm.role LOOP
    RAISE NOTICE '  % -> % (%)', r.funktion, r.person, r.mail;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.payments p
   WHERE p."userId" IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = p."userId");
  RAISE NOTICE 'Zahlungen ohne Mitglied: % -- erwartet 0', v_n;
END $$;
