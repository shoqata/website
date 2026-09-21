-- Selbsttest. Legt einen Probeverein an, setzt den Administrator, prueft
-- beide Tueren und raeumt wieder auf.
DO $$
DECLARE
  v_back text := current_user;
  v_betreiber text; v_bmail text;
  v_verein text; v_erg jsonb;
  v_uid uuid; v_rolle text; v_n int;
  v_mitglied text; v_mmail text := 'probe.mitglied@example.org';
  v_chef text; v_cmail text := 'probe.chef@example.org';
  v_anmeldung uuid; v_geholt text;
BEGIN
  -- Betreiber ist, wer in platform_admins steht -- nicht, wer SUPER_ADMIN
  -- in einem Verein ist. Genau daran ist der erste Anlauf gescheitert.
  SELECT pa.email INTO v_bmail FROM public.platform_admins pa
   WHERE EXISTS (SELECT 1 FROM public.users u
                  WHERE lower(u.email)=lower(pa.email) AND u."authUserId" IS NOT NULL)
   LIMIT 1;
  IF v_bmail IS NULL THEN SELECT email INTO v_bmail FROM public.platform_admins LIMIT 1; END IF;
  SELECT u."authUserId" INTO v_betreiber FROM public.users u
   WHERE lower(u.email) = lower(v_bmail) LIMIT 1;
  v_betreiber := coalesce(v_betreiber, gen_random_uuid()::text);
  RAISE NOTICE '0. Betreiber im Test: %', v_bmail;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_betreiber,'role','authenticated','email',v_bmail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  v_verein := public.create_tenant('Probe Administrator', NULL, 'probe-admin.example.org', NULL);
  RAISE NOTICE '1. Verein angelegt: %', v_verein;

  v_erg := public.vereins_administrator_setzen(v_verein, 'Probe.Chef@Example.ORG');
  RAISE NOTICE '2. Zugang gesetzt: neu=% E-Mail=% Passwortlaenge=%',
    v_erg->>'created', v_erg->>'email', length(v_erg->>'password');

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT u.id, u."authUserId"::uuid, coalesce(u.role,'MEMBER')
    INTO v_chef, v_uid, v_rolle
    FROM public.users u WHERE u."tenantId"=v_verein AND lower(u.email)=v_cmail;
  SELECT count(*) INTO v_n FROM auth.users WHERE id = v_uid;
  RAISE NOTICE '3. Zeile: Rolle=% verknuepft=% Anmeldekonto vorhanden=%',
    v_rolle, (v_uid IS NOT NULL), v_n;

  -- --- Tuer 1: darf sich jemand die ADMIN-Zeile selbst holen? ------------
  -- Dazu wird die Verknuepfung geloest und eine fremde Anmeldung gebaut.
  UPDATE public.users SET "authUserId" = NULL WHERE id = v_chef;
  v_anmeldung := gen_random_uuid();
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_anmeldung,'role','authenticated','email',v_cmail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  v_geholt := public.claim_my_profile();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE '4. ADMIN-Zeile selbst holen: % (erwartet: keine)',
    coalesce(v_geholt, 'keine');

  -- --- Tuer 2: ein gewoehnliches Mitglied darf weiterhin ----------------
  v_mitglied := gen_random_uuid()::text;
  INSERT INTO public.users (id,"tenantId",email,role,"membershipStatus","displayName","joinedAt")
  VALUES (v_mitglied, v_verein, v_mmail, 'MEMBER','ACTIVE','Probe Mitglied', now());
  v_anmeldung := gen_random_uuid();
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_anmeldung,'role','authenticated','email',v_mmail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  v_geholt := public.claim_my_profile();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE '5. MEMBER-Zeile selbst holen: % (erwartet: ja)',
    CASE WHEN v_geholt = v_mitglied THEN 'ja' ELSE coalesce(v_geholt,'keine') END;

  -- --- Aufraeumen -------------------------------------------------------
  DELETE FROM public.security_logs WHERE "tenantId" = v_verein;
  DELETE FROM public.accounting_accounts WHERE "tenantId" = v_verein;
  DELETE FROM public.fiscal_years WHERE "tenantId" = v_verein;
  DELETE FROM public.settings WHERE "tenantId" = v_verein;
  DELETE FROM public.users WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;
  DELETE FROM auth.identities WHERE user_id = v_uid;
  DELETE FROM auth.users WHERE id = v_uid;

  SELECT count(*) INTO v_n FROM public.tenants WHERE id = v_verein;
  RAISE NOTICE '6. aufgeraeumt: Vereinszeilen uebrig %', v_n;
EXCEPTION WHEN OTHERS THEN
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'TEST GESCHEITERT: %', SQLERRM;
  RAISE;
END $$;
