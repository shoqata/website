-- create_tenant scheitert, sobald eine Administrator-Adresse angegeben wird.
--
-- Die Funktion schreibt now()::text in users."joinedAt" -- eine Spalte vom Typ
-- timestamptz. PostgreSQL weist das mit "column joinedAt is of type timestamp
-- with time zone but expression is of type text" zurueck.
--
-- Aufgefallen ist es beim Trennungstest, der denselben Fehler machte. Bisher
-- blieb es unbemerkt, weil Vereine hier immer ohne Administrator-Adresse
-- angelegt wurden -- dann wird der Einfuegebefehl uebersprungen.
CREATE OR REPLACE FUNCTION public.create_tenant(
  p_name        text,
  p_slug        text,
  p_domain      text,
  p_admin_email text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id     text;
  v_domain text := lower(btrim(p_domain));
  v_email  text := lower(btrim(coalesce(p_admin_email, '')));
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf Vereine anlegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_name), '') = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_domain = '' THEN
    RAISE EXCEPTION 'Domain fehlt -- ohne sie ist die Website des Vereins nicht auffindbar.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tenant_domains WHERE domain = v_domain) THEN
    RAISE EXCEPTION 'Die Domain % ist bereits einem Verein zugeordnet.', v_domain
      USING ERRCODE = 'unique_violation';
  END IF;

  IF v_email <> '' THEN
    IF position('@' in v_email) = 0 THEN
      RAISE EXCEPTION 'E-Mail des Administrators ist unvollstaendig.' USING ERRCODE = 'check_violation';
    END IF;
    IF EXISTS (SELECT 1 FROM public.users WHERE lower(email) = v_email) THEN
      RAISE EXCEPTION 'Die Adresse % ist bereits vergeben. Lassen Sie das Feld leer, wenn Sie den Verein zunaechst selbst einrichten wollen.', v_email
        USING ERRCODE = 'unique_violation';
    END IF;
  END IF;

  v_id := coalesce(nullif(btrim(p_slug), ''), regexp_replace(lower(p_name), '[^a-z0-9]+', '-', 'g'));
  v_id := btrim(v_id, '-');
  IF EXISTS (SELECT 1 FROM public.tenants WHERE id = v_id) THEN
    v_id := v_id || '-' || substr(md5(random()::text), 1, 4);
  END IF;

  INSERT INTO public.tenants (id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt")
  VALUES (v_id, btrim(p_name), v_id, 'FREE', 'ACTIVE', now());

  INSERT INTO public.tenant_domains ("tenantId", domain) VALUES (v_id, v_domain);

  IF v_email <> '' THEN
    -- now() statt now()::text -- die Spalte ist ein Zeitstempel.
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (gen_random_uuid()::text, v_id, v_email, 'ADMIN', 'ACTIVE', v_email, now());
  END IF;

  RETURN v_id;
END $$;

GRANT EXECUTE ON FUNCTION public.create_tenant(text, text, text, text) TO authenticated;

-- Gegenprobe: mit Administrator-Adresse anlegen und wieder entfernen.
DO $$
DECLARE
  v_back text := current_user;
  v_uid text; v_mail text; v_id text; v_err text;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email)=lower(u.email)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;
  IF v_uid IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Betreiber.'; RETURN; END IF;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    v_id := public.create_tenant('Probeverein mit Admin', 'probe-mit-admin',
                                 'probe-mit-admin.invalid', 'admin@probe-mit-admin.invalid');
    RAISE NOTICE 'Verein mit Administrator-Adresse angelegt: % -- vorher scheiterte das', v_id;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE 'Anlegen mit Administrator-Adresse: FEHLGESCHLAGEN -- %', v_err;
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  IF v_id IS NOT NULL THEN
    RAISE NOTICE 'Administratorzeile angelegt: %',
      (SELECT count(*) FROM public.users WHERE "tenantId" = v_id);
    DELETE FROM public.users WHERE "tenantId" = v_id;
    DELETE FROM public.tenant_domains WHERE "tenantId" = v_id;
    DELETE FROM public.tenants WHERE id = v_id;
    RAISE NOTICE 'Probeverein entfernt, % Vereine bleiben.', (SELECT count(*) FROM public.tenants);
  END IF;
END $$;
