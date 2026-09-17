-- Betreuung eines Vereins durch den Plattformbetreiber.
--
-- Beim Anlegen eines Vereins scheiterte die eigene Adresse des Betreibers:
-- users.email ist projektweit eindeutig, und er ist bereits Mitglied seines
-- eigenen Vereins. Ihn zusaetzlich als Mitglied des neuen Vereins anzulegen
-- waere der falsche Weg -- er soll dort ja gerade kein Mitglied sein, sondern
-- nur so lange helfen, bis die Administration des Vereins uebernimmt.
--
-- Stattdessen: eine Betreuungssitzung. Solange sie offen ist, arbeitet der
-- Betreiber im betreuten Verein; danach ist er dort wieder aussen vor. Jede
-- Sitzung bleibt mit Anfang und Ende stehen -- der Verein kann nachlesen, wer
-- wann Zugriff hatte.

CREATE TABLE IF NOT EXISTS public.platform_support (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email       text NOT NULL,
  "tenantId"  text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  reason      text,
  "startedAt" timestamptz NOT NULL DEFAULT now(),
  "endedAt"   timestamptz
);
CREATE INDEX IF NOT EXISTS platform_support_open_idx
  ON public.platform_support (lower(email)) WHERE "endedAt" IS NULL;

ALTER TABLE public.platform_support ENABLE ROW LEVEL SECURITY;

-- Der Betreiber sieht seine eigenen Sitzungen. Die Administration eines
-- Vereins sieht, wer ihren Verein betreut hat -- Nachvollziehbarkeit gehoert
-- dazu, wenn jemand von aussen Zugriff hat.
DROP POLICY IF EXISTS platform_support_read ON public.platform_support;
CREATE POLICY platform_support_read ON public.platform_support FOR SELECT TO authenticated
  USING (
    public.is_platform_admin()
    OR "tenantId" = (SELECT u."tenantId" FROM public.users u WHERE u.id = public.current_user_row_id())
  );

DROP POLICY IF EXISTS platform_support_write ON public.platform_support;
CREATE POLICY platform_support_write ON public.platform_support FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

REVOKE ALL ON public.platform_support FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.platform_support TO authenticated;

-- ------------------------------------------------------------------------
-- Der Verein der laufenden Sitzung.
--
-- Fuer alle ausser dem Betreiber mit offener Betreuung bleibt das Verhalten
-- unveraendert: der Verein der eigenen Zeile. Die Bedingung is_platform_admin()
-- steht ausdruecklich drin -- ohne sie koennte ein Eintrag in der Tabelle
-- allein schon den Verein wechseln.
CREATE OR REPLACE FUNCTION public.current_tenant()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT s."tenantId"
       FROM public.platform_support s
      WHERE s."endedAt" IS NULL
        AND public.is_platform_admin()
        AND auth.jwt() ->> 'email' IS NOT NULL
        AND lower(s.email) = lower(auth.jwt() ->> 'email')
      ORDER BY s."startedAt" DESC
      LIMIT 1),
    (SELECT u."tenantId" FROM public.users u WHERE u.id = public.current_user_row_id())
  )
$$;

-- ------------------------------------------------------- Betreuung steuern
CREATE OR REPLACE FUNCTION public.start_tenant_support(p_tenant text, p_reason text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_mail text := lower(auth.jwt() ->> 'email'); v_id uuid;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf einen Verein betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_tenant) THEN
    RAISE EXCEPTION 'Verein % gibt es nicht.', p_tenant USING ERRCODE = 'check_violation';
  END IF;

  -- Immer nur ein Verein gleichzeitig, sonst waere unklar, worin man arbeitet.
  UPDATE public.platform_support SET "endedAt" = now()
   WHERE lower(email) = v_mail AND "endedAt" IS NULL;

  INSERT INTO public.platform_support (email, "tenantId", reason)
  VALUES (v_mail, p_tenant, p_reason)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.end_tenant_support()
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_mail text := lower(auth.jwt() ->> 'email'); v_n int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf eine Betreuung beenden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  UPDATE public.platform_support SET "endedAt" = now()
   WHERE lower(email) = v_mail AND "endedAt" IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END $$;

GRANT EXECUTE ON FUNCTION public.start_tenant_support(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.end_tenant_support() TO authenticated;

-- ---------------------------------- Vereinsanlage ohne fremden Mitgliedseintrag
-- p_admin_email darf jetzt leer bleiben. Dann entsteht kein Administratorkonto,
-- und der Betreiber richtet den Verein selbst ein, bis jemand uebernimmt.
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

  -- Eine Adresse nur pruefen, wenn ueberhaupt eine angegeben wurde.
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
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (gen_random_uuid()::text, v_id, v_email, 'ADMIN', 'ACTIVE', v_email, now()::text);
  END IF;

  RETURN v_id;
END $$;

GRANT EXECUTE ON FUNCTION public.create_tenant(text, text, text, text) TO authenticated;

NOTIFY pgrst, 'reload schema';
