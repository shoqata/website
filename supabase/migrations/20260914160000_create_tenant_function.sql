-- Einen Verein anlegen, der danach auch benutzbar ist.
--
-- Bisher erzeugte das Super-Admin-Dashboard nur die Zeile in tenants. Ohne
-- Domain ist die Website des Vereins nicht auffindbar, und ohne einen
-- Administrator mit Zugehoerigkeit kann ihn niemand verwalten -- is_staff()
-- setzt eine users-Zeile in genau diesem Verein voraus. Der Verein war also
-- angelegt und zugleich unbrauchbar.
--
-- Die drei Schritte gehoeren zusammen und laufen deshalb serverseitig in einer
-- Funktion: entweder entsteht ein vollstaendiger Verein oder keiner.

CREATE OR REPLACE FUNCTION public.create_tenant(
  p_name        text,
  p_slug        text,
  p_domain      text,
  p_admin_email text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id     text;
  v_domain text := lower(btrim(p_domain));
  v_email  text := lower(btrim(p_admin_email));
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
  IF v_email = '' OR position('@' in v_email) = 0 THEN
    RAISE EXCEPTION 'E-Mail des Administrators fehlt oder ist unvollstaendig.'
      USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (SELECT 1 FROM public.tenant_domains WHERE domain = v_domain) THEN
    RAISE EXCEPTION 'Die Domain % ist bereits einem Verein zugeordnet.', v_domain
      USING ERRCODE = 'unique_violation';
  END IF;
  -- users.email ist projektweit eindeutig: dieselbe Adresse kann nicht in zwei
  -- Vereinen Mitglied sein. Lieber hier klar scheitern als spaeter unklar.
  IF EXISTS (SELECT 1 FROM public.users WHERE lower(email) = v_email) THEN
    RAISE EXCEPTION 'Die Adresse % ist bereits vergeben.', v_email
      USING ERRCODE = 'unique_violation';
  END IF;

  v_id := coalesce(nullif(btrim(p_slug), ''), regexp_replace(lower(p_name), '[^a-z0-9]+', '-', 'g'));
  IF EXISTS (SELECT 1 FROM public.tenants WHERE id = v_id) THEN
    v_id := v_id || '-' || substr(gen_random_uuid()::text, 1, 6);
  END IF;

  INSERT INTO public.tenants (id, slug, name, "subscriptionPlan", "subscriptionStatus", "contactEmail")
  VALUES (v_id, v_id, p_name, 'FREE', 'ACTIVE', v_email);

  INSERT INTO public.tenant_domains (domain, "tenantId", "isPrimary")
  VALUES (v_domain, v_id, true);

  -- Der Administrator wird als Mitglied des neuen Vereins angelegt, aber noch
  -- ohne Auth-Identitaet. Meldet er sich spaeter mit dieser Adresse an,
  -- verbindet claim_my_profile() beides -- derselbe Weg, den Bestandsmitglieder
  -- beim ersten Login gehen.
  INSERT INTO public.users (id, "tenantId", email, role, "displayName", "membershipStatus", "profileComplete")
  VALUES (gen_random_uuid()::text, v_id, v_email, 'ADMIN',
          split_part(v_email, '@', 1), 'ACTIVE', false);

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION public.create_tenant(text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_tenant(text, text, text, text) TO authenticated;
