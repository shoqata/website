-- Testzugaenge fuer Interessenten im Demoverein.
--
-- Der Betreiber legt im Betreiberbereich zu einem Interessenten (platform_leads)
-- einen Zugang an: ein eigenes Konto mit der E-Mail des Interessenten, Rolle
-- Administration im Verein 'demo', gueltig fuer eine bestimmte Zahl Tage.
-- Das Passwort wird einmal angezeigt; verschickt wird es vom Betreiber.
--
-- Was dazugehoert:
--   * demo_zugaenge: welcher Interessent welches Konto hat und bis wann;
--   * Ablauf: ein Zeitplan sperrt abgelaufene Konten im Anmeldesystem und
--     beendet ihre Sitzungen; schon vorher verweigert darf_schreiben jedes
--     Schreiben, sobald die Frist um ist;
--   * Schutz der Interessenten voreinander: ihre Zeilen sind fuer andere
--     unsichtbar, und sie koennen weder Passwoerter setzen noch Rollen von
--     Konten aendern noch Konten loeschen noch Domains, Zahlungs-, Mail-,
--     Social- oder Vereinseinstellungen aendern (die ueberdauern sonst das
--     Zuruecksetzen oder betreffen Geheimnisse);
--   * ein eigenes kleines Floky-Kontingent je Zugang;
--   * Zuruecksetzen des Demovereins jede Nacht -- die Zugaenge bleiben dabei
--     bestehen und behalten ihr Passwort.
--
-- Nebenbei geschlossen: reset_member_password setzte das Passwort eines
-- Kontos, das ueber die E-Mail-Adresse gefunden wurde, auch wenn dieses Konto
-- einer Person in einem anderen Verein gehoerte. Eine Administration konnte
-- so einem eigenen Mitglied die Adresse einer fremden Person geben und deren
-- Konto uebernehmen. Jetzt darf das nur der Betreiber.
--
-- Die Tabelle hat bewusst keine Spalte "tenantId": _demo_tabellen nimmt jede
-- solche Tabelle in das Zuruecksetzen auf, und dann waeren die Zugaenge nach
-- der ersten Nacht weg. Aus demselben Grund verweist sie nicht per
-- Fremdschluessel auf public.users -- das Zuruecksetzen loescht und schreibt
-- diese Zeilen neu.

CREATE TABLE IF NOT EXISTS public.demo_zugaenge (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id        uuid REFERENCES public.platform_leads(id) ON DELETE SET NULL,
  auth_user_id   uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id        text NOT NULL,
  email          text NOT NULL,
  name           text,
  gueltig_bis    timestamptz NOT NULL,
  gesperrt_am    timestamptz,
  floky_anfragen int NOT NULL DEFAULT 0,
  floky_grenze   int NOT NULL DEFAULT 30,
  angelegt_am    timestamptz NOT NULL DEFAULT now(),
  angelegt_von   text
);
CREATE INDEX IF NOT EXISTS demo_zugaenge_lead ON public.demo_zugaenge (lead_id);

ALTER TABLE public.demo_zugaenge ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demo_zugaenge FROM anon, authenticated;

-- ------------------------------------------------------------ Wer ist Gast?
CREATE OR REPLACE FUNCTION public.ist_demogast()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  SELECT auth.uid() IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.auth_user_id = auth.uid())
$$;

CREATE OR REPLACE FUNCTION public.demogast_abgelaufen()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  SELECT auth.uid() IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.demo_zugaenge z
                  WHERE z.auth_user_id = auth.uid()
                    AND (z.gueltig_bis <= now() OR z.gesperrt_am IS NOT NULL))
$$;

-- Ist diese Zeile von public.users das Konto eines Gastes?
CREATE OR REPLACE FUNCTION public._ist_demogast_konto(p_auth text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  SELECT p_auth IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.auth_user_id::text = p_auth)
$$;

REVOKE ALL ON FUNCTION public.ist_demogast(), public.demogast_abgelaufen(),
                       public._ist_demogast_konto(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ist_demogast(), public.demogast_abgelaufen(),
                          public._ist_demogast_konto(text) TO authenticated;

-- --------------------------------------------- Gaeste sehen einander nicht
-- Einschraenkend, also zusaetzlich zu den bestehenden Regeln. Andere Vereine
-- als 'demo' pruefen nur den ersten Vergleich.
DROP POLICY IF EXISTS demogaeste_unsichtbar ON public.users;
CREATE POLICY demogaeste_unsichtbar ON public.users AS RESTRICTIVE FOR SELECT
  USING (
    "tenantId" <> 'demo'
    OR NOT public._ist_demogast_konto("authUserId")
    OR "authUserId" = (SELECT auth.uid()::text)
    OR (SELECT public.is_platform_admin())
  );

-- ------------------------------------------------ Was ein Gast nicht darf
CREATE OR REPLACE FUNCTION public.demogast_users_pruefen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.ist_demogast() THEN
    RETURN coalesce(NEW, OLD);
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD."authUserId" IS NOT NULL THEN
      RAISE EXCEPTION 'Im Testzugang lassen sich keine Mitglieder mit eigenem Login loeschen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN OLD;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF public._ist_demogast_konto(OLD."authUserId") AND OLD."authUserId" <> auth.uid()::text THEN
      RAISE EXCEPTION 'Dieses Konto gehoert zu einem anderen Testzugang.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NEW."authUserId" IS DISTINCT FROM OLD."authUserId" THEN
      RAISE EXCEPTION 'Im Testzugang lassen sich Logins nicht neu verknuepfen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF OLD."authUserId" IS NOT NULL AND NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Im Testzugang lassen sich Rollen von Mitgliedern mit eigenem Login nicht aendern.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  IF TG_OP = 'INSERT' AND NEW."authUserId" IS NOT NULL THEN
    RAISE EXCEPTION 'Im Testzugang lassen sich keine Logins anlegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS users_demogast ON public.users;
CREATE TRIGGER users_demogast BEFORE INSERT OR UPDATE OR DELETE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.demogast_users_pruefen();

-- Einstellungen, die das Zuruecksetzen ueberdauern (tenants, Domains) oder
-- Geheimnisse halten: fuer Gaeste ganz gesperrt.
CREATE OR REPLACE FUNCTION public.demogast_sperre()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF public.ist_demogast() THEN
    RAISE EXCEPTION 'Diese Einstellung ist im Testzugang gesperrt.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce(NEW, OLD);
END $$;

DO $$
DECLARE v_t text;
BEGIN
  FOREACH v_t IN ARRAY ARRAY['tenants', 'tenant_domains', 'zahlungsgeheimnisse', 'mail_settings',
                             'social_connections', 'revisionszugaenge', 'floky_einstellungen'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS demogast_sperre ON public.%I', v_t);
    EXECUTE format('CREATE TRIGGER demogast_sperre BEFORE INSERT OR UPDATE OR DELETE ON public.%I '
                   'FOR EACH ROW EXECUTE FUNCTION public.demogast_sperre()', v_t);
  END LOOP;
END $$;

-- Abgelaufen heisst: ab sofort nichts mehr schreiben, auch bevor der
-- Zeitplan das Konto sperrt. Sonst wie bisher.
CREATE OR REPLACE FUNCTION public.darf_schreiben()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  SELECT CASE
    -- Ein abgelaufener Testzugang nie.
    WHEN public.demogast_abgelaufen() THEN false
    -- Betreiber und Vereinsadministration immer.
    WHEN public.is_platform_admin() THEN true
    WHEN public.app_role() IN ('SUPER_ADMIN','ADMIN') THEN true
    -- Der Vorstand nur, solange sein Verein es zulaesst.
    WHEN public.app_role() = 'BOARD' THEN
      coalesce((SELECT t.vorstand_schreibt FROM public.tenants t
                 WHERE t.id = public.current_tenant()), true)
    -- Alle uebrigen Rollen schreiben ohnehin nur ueber eigene Regeln
    -- (eigenes Profil, eigene Zusage); die bleiben unberuehrt, weil
    -- diese Schranke nur greift, wo bereits eine Erlaubnis besteht.
    ELSE true
  END;
$$;

-- ------------------------------------------------------ Floky je Zugang
CREATE OR REPLACE FUNCTION public.floky_anfrage_zaehlen()
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_verein text := public.current_tenant();
        v_k int; v_a int;
        v_ga int; v_gk int;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.floky_darf() THEN
    RAISE EXCEPTION 'Floky ist fuer diesen Verein nicht gebucht oder fuer diese Rolle nicht vorgesehen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ein Testzugang hat sein eigenes, kleines Kontingent -- sonst verbraucht
  -- ein einzelner Interessent das des ganzen Demovereins.
  IF public.ist_demogast() THEN
    UPDATE public.demo_zugaenge SET floky_anfragen = floky_anfragen + 1
     WHERE auth_user_id = auth.uid()
    RETURNING floky_anfragen, floky_grenze INTO v_ga, v_gk;
    IF v_ga > v_gk THEN
      RAISE EXCEPTION 'Ihr Testzugang hat seine % Fragen an den Assistenten aufgebraucht.', v_gk
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  SELECT coalesce(kontingent_monat, 300) INTO v_k
    FROM public.floky_einstellungen WHERE "tenantId" = v_verein;
  v_k := coalesce(v_k, 300);

  INSERT INTO public.floky_verbrauch AS vb ("tenantId", monat, anfragen)
  VALUES (v_verein, date_trunc('month', current_date)::date, 1)
  ON CONFLICT ("tenantId", monat) DO UPDATE SET anfragen = vb.anfragen + 1
  RETURNING vb.anfragen INTO v_a;

  IF v_a > v_k THEN
    -- Die Zeile bleibt stehen: der Versuch hat stattgefunden. Aber der
    -- Aufrufer bekommt einen Fehler und damit keine Antwort.
    RAISE EXCEPTION 'Das Kontingent fuer diesen Monat ist aufgebraucht (% von %).', v_a - 1, v_k
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN v_k - v_a;
END $$;

-- ------------------------------------------- Passwort setzen, abgesichert
CREATE OR REPLACE FUNCTION public.reset_member_password(p_member text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
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
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT (public.is_member_manager() OR v_betreiber) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Passwoerter zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ein Testzugang legt keine Konten an und setzt keine Passwoerter: sonst
  -- koennte ein Interessent sich ein Konto ohne Ablaufdatum schaffen oder
  -- das eines anderen Interessenten uebernehmen.
  IF public.ist_demogast() THEN
    RAISE EXCEPTION 'Im Testzugang lassen sich keine Passwoerter setzen. In Ihrem eigenen Verein geht das hier.'
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

  IF v_uid IS NULL THEN
    SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_mail LIMIT 1;
  END IF;

  -- Das Konto kann mehr sein als dieses Mitglied: dieselbe Person in einem
  -- anderen Verein, die Administration hier, ein Betreiber- oder ein
  -- Testzugang. Gefunden wird es ueber die Adresse oder die Verknuepfung --
  -- beides kann eine Administration an der eigenen Zeile einstellen. Ein
  -- solches Konto setzt nur der Betreiber zurueck.
  IF NOT v_betreiber AND v_uid IS NOT NULL AND (
       EXISTS (SELECT 1 FROM auth.users au
                WHERE au.id = v_uid
                  AND (EXISTS (SELECT 1 FROM public.platform_admins pa WHERE lower(pa.email) = lower(au.email))
                    OR EXISTS (SELECT 1 FROM public.admin_emails ae WHERE lower(ae.email) = lower(au.email))))
    OR EXISTS (SELECT 1 FROM public.users u
                WHERE u."authUserId" = v_uid::text
                  AND (u."tenantId" <> v_verein
                       OR (u.id <> p_member AND public.rollen_rang(u.role) >= v_eigener_rang)))
    OR EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.auth_user_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Zu dieser Adresse gehoert ein Login, das auch ausserhalb Ihres Vereins oder mit mehr Rechten genutzt wird. Dessen Passwort kann nur der Betreiber der Plattform zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

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

-- ------------------------------------------- Zugang anlegen und verwalten
CREATE OR REPLACE FUNCTION public._demo_passwort()
RETURNS text
LANGUAGE plpgsql VOLATILE SET search_path TO 'public'
AS $$
DECLARE
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  v_pw text := '';
  i int;
BEGIN
  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;
  RETURN v_pw;
END $$;
REVOKE ALL ON FUNCTION public._demo_passwort() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._nur_betreiber()
RETURNS void
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur fuer den Plattformbetreiber.' USING ERRCODE = '42501';
  END IF;
END $$;
REVOKE ALL ON FUNCTION public._nur_betreiber() FROM PUBLIC, anon, authenticated;

-- Konto sperren oder entsperren, Sitzungen beenden.
CREATE OR REPLACE FUNCTION public._demo_konto_sperren(p_auth uuid, p_sperren boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  -- Ein fernes Datum statt 'infinity', siehe _demo_paket_anwenden.
  UPDATE auth.users
     SET banned_until = CASE WHEN p_sperren THEN timestamptz '2999-12-31' ELSE NULL END,
         updated_at = now()
   WHERE id = p_auth;
  IF p_sperren THEN
    DELETE FROM auth.refresh_tokens WHERE user_id = p_auth::text;
    DELETE FROM auth.sessions WHERE user_id = p_auth;
  END IF;
END $$;
REVOKE ALL ON FUNCTION public._demo_konto_sperren(uuid, boolean) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.demo_zugang_anlegen(p_lead uuid, p_tage int)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
  v_lead  public.platform_leads%ROWTYPE;
  v_mail  text;
  v_name  text;
  v_vor   text;
  v_nach  text;
  v_uid   uuid := gen_random_uuid();
  v_pw    text := public._demo_passwort();
  v_bis   timestamptz;
BEGIN
  PERFORM public._nur_betreiber();

  IF p_tage IS NULL OR p_tage < 1 OR p_tage > 90 THEN
    RAISE EXCEPTION 'Die Dauer muss zwischen 1 und 90 Tagen liegen.' USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_lead FROM public.platform_leads WHERE id = p_lead;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Interessenten gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  v_mail := lower(btrim(coalesce(v_lead.email, '')));
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Beim Interessenten steht keine gueltige E-Mail-Adresse. Tragen Sie sie zuerst ein und speichern Sie.'
      USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.lead_id = p_lead) THEN
    RAISE EXCEPTION 'Dieser Interessent hat schon einen Testzugang. Verlaengern Sie ihn oder setzen Sie ein neues Passwort.'
      USING ERRCODE = 'unique_violation';
  END IF;

  -- Ein bestehendes Konto wird nie zum Testzugang: es koennte einem
  -- Mitglied eines echten Vereins gehoeren, und dessen Passwort aenderten
  -- wir sonst ungefragt.
  IF EXISTS (SELECT 1 FROM auth.users au WHERE lower(au.email) = v_mail) THEN
    RAISE EXCEPTION 'Mit dieser E-Mail-Adresse gibt es schon ein Login auf der Plattform. Ein Testzugang braucht eine eigene Adresse.'
      USING ERRCODE = 'unique_violation';
  END IF;

  v_name := coalesce(nullif(btrim(v_lead."contactName"), ''), v_lead.name);
  IF position(' ' IN btrim(coalesce(v_lead."contactName", ''))) > 0 THEN
    v_vor  := split_part(btrim(v_lead."contactName"), ' ', 1);
    v_nach := btrim(substr(btrim(v_lead."contactName"), length(v_vor) + 1));
  END IF;
  v_bis := now() + make_interval(days => p_tage);

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
    '{"email_verified":true,"demo_gast":true}'::jsonb,
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

  INSERT INTO public.users (id, "authUserId", "tenantId", email, "displayName", "firstName", "lastName",
                            role, "membershipStatus", "profileComplete", nicht_oeffentlich, "joinedAt")
  VALUES (v_uid::text, v_uid::text, 'demo', v_mail, v_name, v_vor, v_nach,
          'ADMIN', 'ACTIVE', true, true, now());

  INSERT INTO public.demo_zugaenge (lead_id, auth_user_id, user_id, email, name, gueltig_bis, angelegt_von)
  VALUES (p_lead, v_uid, v_uid::text, v_mail, v_name, v_bis, auth.jwt() ->> 'email');

  INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
  VALUES (gen_random_uuid(), 'demo', 'PASSWORD_RESET', 'ACCOUNT_CREATED', v_uid::text,
          to_jsonb(format('Testzugang fuer %s (%s) bis %s durch %s', v_name, v_mail,
                          to_char(v_bis AT TIME ZONE 'Europe/Zurich', 'DD.MM.YYYY'),
                          coalesce(auth.jwt() ->> 'email', 'unbekannt'))),
          now(), now());

  RETURN jsonb_build_object('email', v_mail, 'passwort', v_pw, 'gueltig_bis', v_bis,
                            'adresse', 'https://demo.unityhub.li');
END $$;

CREATE OR REPLACE FUNCTION public.demo_zugang_verlaengern(p_zugang uuid, p_tage int)
RETURNS timestamptz
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_bis timestamptz; v_auth uuid;
BEGIN
  PERFORM public._nur_betreiber();
  IF p_tage IS NULL OR p_tage < 1 OR p_tage > 90 THEN
    RAISE EXCEPTION 'Die Dauer muss zwischen 1 und 90 Tagen liegen.' USING ERRCODE = 'check_violation';
  END IF;
  UPDATE public.demo_zugaenge
     SET gueltig_bis = greatest(gueltig_bis, now()) + make_interval(days => p_tage),
         gesperrt_am = NULL
   WHERE id = p_zugang
  RETURNING gueltig_bis, auth_user_id INTO v_bis, v_auth;
  IF v_auth IS NULL THEN
    RAISE EXCEPTION 'Diesen Testzugang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  PERFORM public._demo_konto_sperren(v_auth, false);
  RETURN v_bis;
END $$;

CREATE OR REPLACE FUNCTION public.demo_zugang_sperren(p_zugang uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_auth uuid;
BEGIN
  PERFORM public._nur_betreiber();
  UPDATE public.demo_zugaenge
     SET gueltig_bis = least(gueltig_bis, now()), gesperrt_am = coalesce(gesperrt_am, now())
   WHERE id = p_zugang
  RETURNING auth_user_id INTO v_auth;
  IF v_auth IS NULL THEN
    RAISE EXCEPTION 'Diesen Testzugang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  PERFORM public._demo_konto_sperren(v_auth, true);
END $$;

CREATE OR REPLACE FUNCTION public.demo_zugang_neues_passwort(p_zugang uuid)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_auth uuid; v_pw text := public._demo_passwort();
BEGIN
  PERFORM public._nur_betreiber();
  SELECT auth_user_id INTO v_auth FROM public.demo_zugaenge WHERE id = p_zugang;
  IF v_auth IS NULL THEN
    RAISE EXCEPTION 'Diesen Testzugang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  UPDATE auth.users
     SET encrypted_password = extensions.crypt(v_pw, extensions.gen_salt('bf')), updated_at = now()
   WHERE id = v_auth;
  DELETE FROM auth.refresh_tokens WHERE user_id = v_auth::text;
  DELETE FROM auth.sessions WHERE user_id = v_auth;
  RETURN v_pw;
END $$;

-- Endgueltig entfernen: Login, Zeile im Demoverein und den Zugang. Die
-- personenbezogenen Daten des Interessenten bleiben so nicht liegen.
CREATE OR REPLACE FUNCTION public.demo_zugang_entfernen(p_zugang uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_z public.demo_zugaenge%ROWTYPE;
BEGIN
  PERFORM public._nur_betreiber();
  SELECT * INTO v_z FROM public.demo_zugaenge WHERE id = p_zugang;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Testzugang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  -- Was der Gast angelegt hat und auf ihn zeigt, haengt am Demoverein und
  -- verschwindet spaetestens beim naechsten Zuruecksetzen; hier nur das,
  -- was ihn selbst betrifft.
  DELETE FROM public.benachrichtigungen WHERE empfaenger = v_z.user_id;
  DELETE FROM public.push_abos WHERE empfaenger = v_z.user_id;
  DELETE FROM public.users WHERE "tenantId" = 'demo' AND "authUserId" = v_z.auth_user_id::text;
  DELETE FROM auth.users WHERE id = v_z.auth_user_id;   -- nimmt den Zugang mit (ON DELETE CASCADE)
END $$;

CREATE OR REPLACE FUNCTION public.demo_zugaenge_lesen()
RETURNS TABLE (id uuid, lead_id uuid, email text, name text, gueltig_bis timestamptz,
               gesperrt_am timestamptz, aktiv boolean, zuletzt_angemeldet timestamptz,
               floky_anfragen int, floky_grenze int, angelegt_am timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public._nur_betreiber();
  RETURN QUERY
    SELECT z.id, z.lead_id, z.email, z.name, z.gueltig_bis, z.gesperrt_am,
           (z.gesperrt_am IS NULL AND z.gueltig_bis > now()),
           au.last_sign_in_at, z.floky_anfragen, z.floky_grenze, z.angelegt_am
      FROM public.demo_zugaenge z
      LEFT JOIN auth.users au ON au.id = z.auth_user_id
     ORDER BY z.angelegt_am DESC;
END $$;

-- Fuer das Band im Demoverein: nur der eigene Zugang, sonst nichts.
CREATE OR REPLACE FUNCTION public.mein_demozugang()
RETURNS TABLE (gueltig_bis timestamptz, floky_uebrig int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  SELECT z.gueltig_bis, greatest(z.floky_grenze - z.floky_anfragen, 0)
    FROM public.demo_zugaenge z
   WHERE z.auth_user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.demo_zugang_anlegen(uuid, int), public.demo_zugang_verlaengern(uuid, int),
                       public.demo_zugang_sperren(uuid), public.demo_zugang_neues_passwort(uuid),
                       public.demo_zugang_entfernen(uuid), public.demo_zugaenge_lesen(),
                       public.mein_demozugang() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.demo_zugang_anlegen(uuid, int), public.demo_zugang_verlaengern(uuid, int),
                          public.demo_zugang_sperren(uuid), public.demo_zugang_neues_passwort(uuid),
                          public.demo_zugang_entfernen(uuid), public.demo_zugaenge_lesen(),
                          public.mein_demozugang() TO authenticated;

-- ------------------------------------------------------------ Ablauf
CREATE OR REPLACE FUNCTION public._demo_zugaenge_ablaufen()
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_z record; v_n int := 0;
BEGIN
  FOR v_z IN
    SELECT z.id, z.auth_user_id FROM public.demo_zugaenge z
     WHERE z.gueltig_bis <= now() AND z.gesperrt_am IS NULL
  LOOP
    PERFORM public._demo_konto_sperren(v_z.auth_user_id, true);
    UPDATE public.demo_zugaenge SET gesperrt_am = now() WHERE id = v_z.id;
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public._demo_zugaenge_ablaufen() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------- Zuruecksetzen ohne die Gaeste
CREATE OR REPLACE FUNCTION public._demo_paket_anwenden(p_paket text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF p_paket = 'LIGHT' THEN
    UPDATE public.tenants SET alle_module_frei = false WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AUS' FROM public.modules m WHERE NOT m.ist_kern
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AUS', testet_bis = NULL;
  ELSIF p_paket = 'VOLL' THEN
    UPDATE public.tenants SET alle_module_frei = true WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AN' FROM public.modules m
     WHERE NOT m.ist_kern AND m.status <> 'EINGESTELLT'
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AN', testet_bis = NULL;
  ELSE
    RAISE EXCEPTION 'Unbekanntes Paket: %', p_paket;
  END IF;

  -- Zugaenge. Ein fernes Datum statt 'infinity': das Anmeldesystem liest
  -- den Wert als Zeitpunkt, und 'infinity' kann es nicht in einen solchen
  -- umwandeln -- die Anmeldung scheiterte dann mit einem Serverfehler
  -- statt mit "gesperrt". Testzugaenge regelt ihr eigenes Ablaufdatum;
  -- sonst entsperrte das Paket Voll einen abgelaufenen Zugang wieder.
  UPDATE auth.users a
     SET banned_until = CASE WHEN p_paket = 'LIGHT' AND u.role <> 'ADMIN'
                             THEN timestamptz '2999-12-31' ELSE NULL END
    FROM public.users u
   WHERE u."authUserId" = a.id::text AND u."tenantId" = 'demo'
     AND NOT EXISTS (SELECT 1 FROM public.platform_admins p WHERE lower(p.email) = lower(a.email))
     AND NOT EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.auth_user_id = a.id);

  IF p_paket = 'LIGHT' THEN
    DELETE FROM auth.refresh_tokens r USING public.users u
     WHERE u."tenantId" = 'demo' AND u.role <> 'ADMIN' AND u."authUserId" = r.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId")
       AND NOT public._ist_demogast_konto(u."authUserId");
    DELETE FROM auth.sessions s USING public.users u
     WHERE u."tenantId" = 'demo' AND u.role <> 'ADMIN' AND u."authUserId" = s.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId")
       AND NOT public._ist_demogast_konto(u."authUserId");
  END IF;
END $$;

-- Die eigentliche Arbeit, ohne Pruefung des Aufrufers -- fuer den Knopf
-- (demo_zuruecksetzen, nur Betreiber) und den naechtlichen Zeitplan.
CREATE OR REPLACE FUNCTION public._demo_zuruecksetzen_intern(p_von text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
  v_tab   text[];
  v_t     text;
  v_i     int;
  v_sp    text;
  v_hash  text;
  v_zeilen int;
  v_konten int := 0;
  v_gaeste jsonb;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.demo_vorlage) THEN
    RAISE EXCEPTION 'Es gibt noch keine Demo-Vorlage.';
  END IF;

  SET LOCAL lock_timeout = '5s';
  v_tab := public._demo_tabellen();

  -- Die Zeilen der Testzugaenge stehen nicht in der Vorlage. Sie werden
  -- gemerkt und nach dem Zuruecksetzen wieder eingesetzt.
  SELECT coalesce(jsonb_agg(to_jsonb(u)), '[]'::jsonb) INTO v_gaeste
    FROM public.users u
   WHERE u."tenantId" = 'demo' AND public._ist_demogast_konto(u."authUserId");

  FOREACH v_t IN ARRAY v_tab LOOP
    EXECUTE format('ALTER TABLE public.%I DISABLE TRIGGER USER', v_t);
  END LOOP;

  FOR v_i IN REVERSE cardinality(v_tab) .. 1 LOOP
    EXECUTE format('DELETE FROM public.%I WHERE "tenantId" = %L', v_tab[v_i], 'demo');
  END LOOP;

  FOREACH v_t IN ARRAY v_tab LOOP
    SELECT string_agg(quote_ident(column_name::text), ', ' ORDER BY ordinal_position) INTO v_sp
      FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = v_t AND is_generated = 'NEVER';
    EXECUTE format(
      'INSERT INTO public.%1$I (%2$s) SELECT %3$s FROM public.demo_vorlage v, jsonb_populate_record(NULL::public.%1$I, v.zeile) r WHERE v.tabelle = %4$L',
      v_t, v_sp, 'r.' || replace(v_sp, ', ', ', r.'), v_t);
  END LOOP;

  SELECT string_agg(quote_ident(column_name::text), ', ' ORDER BY ordinal_position) INTO v_sp
    FROM information_schema.columns
   WHERE table_schema = 'public' AND table_name = 'users' AND is_generated = 'NEVER';
  EXECUTE format(
    'INSERT INTO public.users (%1$s) SELECT %2$s FROM jsonb_populate_recordset(NULL::public.users, $1) r ON CONFLICT (id) DO NOTHING',
    v_sp, 'r.' || replace(v_sp, ', ', ', r.'))
  USING v_gaeste;

  FOREACH v_t IN ARRAY v_tab LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER USER', v_t);
  END LOOP;

  -- Zugaenge: alle auf das gemeinsame Passwort, offene Sitzungen beenden.
  -- Ein Betreiberkonto ist nie dabei, auch wenn es im Demoverein eine Zeile
  -- haette, und ein Testzugang auch nicht -- der behaelt sein Passwort.
  SELECT passwort_hash INTO v_hash FROM public.demo_stand WHERE id = 1;
  IF v_hash IS NOT NULL THEN
    WITH konten AS (
      SELECT a.id FROM auth.users a
        JOIN public.users u ON u."authUserId" = a.id::text AND u."tenantId" = 'demo'
       WHERE NOT EXISTS (SELECT 1 FROM public.platform_admins p WHERE lower(p.email) = lower(a.email))
         AND NOT EXISTS (SELECT 1 FROM public.demo_zugaenge z WHERE z.auth_user_id = a.id)
    ), gesetzt AS (
      UPDATE auth.users a SET encrypted_password = v_hash, updated_at = now()
        FROM konten k WHERE a.id = k.id RETURNING a.id
    )
    SELECT count(*) INTO v_konten FROM gesetzt;

    DELETE FROM auth.refresh_tokens r USING public.users u
     WHERE u."tenantId" = 'demo' AND u."authUserId" = r.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId")
       AND NOT public._ist_demogast_konto(u."authUserId");
    DELETE FROM auth.sessions s USING public.users u
     WHERE u."tenantId" = 'demo' AND u."authUserId" = s.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId")
       AND NOT public._ist_demogast_konto(u."authUserId");
  END IF;

  -- Das gewaehlte Paket gilt weiter (Light oder Voll).
  PERFORM public._demo_paket_anwenden(coalesce((SELECT paket FROM public.demo_stand WHERE id = 1), 'VOLL'));

  SELECT count(*) INTO v_zeilen FROM public.demo_vorlage;
  UPDATE public.demo_stand
     SET zurueckgesetzt_am = now(), zurueckgesetzt_von = p_von
   WHERE id = 1;

  RETURN jsonb_build_object('zeilen', v_zeilen, 'konten', v_konten, 'passwort', v_hash IS NOT NULL,
                            'testzugaenge', jsonb_array_length(v_gaeste));
END $$;
REVOKE ALL ON FUNCTION public._demo_zuruecksetzen_intern(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.demo_zuruecksetzen()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Demoverein zuruecksetzen.'
      USING ERRCODE = '42501';
  END IF;
  RETURN public._demo_zuruecksetzen_intern(auth.jwt() ->> 'email');
END $$;
REVOKE ALL ON FUNCTION public.demo_zuruecksetzen() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.demo_zuruecksetzen() TO authenticated;

-- ------------------------------------------------------------ Zeitplaene
-- Abgelaufene Zugaenge alle 15 Minuten sperren.
SELECT cron.unschedule('demo_zugaenge_ablauf')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'demo_zugaenge_ablauf');
SELECT cron.schedule('demo_zugaenge_ablauf', '*/15 * * * *',
  $cron$ SELECT public._demo_zugaenge_ablaufen(); $cron$);

-- Den Demoverein jede Nacht um 3 Uhr Schweizer Zeit (Winterzeit; im Sommer
-- 4 Uhr) auf die Vorlage zuruecksetzen. Nur wenn es eine Vorlage gibt.
SELECT cron.unschedule('demo_nachts_zuruecksetzen')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'demo_nachts_zuruecksetzen');
SELECT cron.schedule('demo_nachts_zuruecksetzen', '0 2 * * *', $cron$
  SELECT public._demo_zuruecksetzen_intern('Zeitplan')
   WHERE EXISTS (SELECT 1 FROM public.demo_vorlage);
$cron$);
