-- Eigene Domain je Verein, und oeffentliche Inhalte nach Verein trennbar.
--
-- Bisher hing die Zuordnung an einer einzelnen Spalte tenants.domain. Ein Verein
-- braucht aber mehrere Adressen -- mit und ohne www, die Vorschau-Adresse, im
-- Zweifel eine zweite Domain. Und die oeffentlichen Sichten gaben den Verein
-- gar nicht preis, liessen sich also nicht nach ihm filtern.

-- ------------------------------------------------------ Domains je Verein
CREATE TABLE IF NOT EXISTS public.tenant_domains (
  domain     text PRIMARY KEY,
  "tenantId" text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "isPrimary" boolean DEFAULT false,
  "createdAt" timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tenant_domains_tenant_idx ON public.tenant_domains ("tenantId");

ALTER TABLE public.tenant_domains ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.tenant_domains FROM anon, authenticated;

-- Aufloesen muss auch ohne Anmeldung moeglich sein -- die Seite kennt den
-- Verein sonst nicht, bevor jemand eingeloggt ist. Die Sicht enthaelt nur
-- Adresse und Kennung, keine Abrechnungs- oder Kontaktdaten.
CREATE OR REPLACE VIEW public.public_tenant_domains AS
  SELECT d.domain, d."tenantId", t.slug, t.name, t."logoUrl",
         t."primaryColor", t."secondaryColor"
    FROM public.tenant_domains d
    JOIN public.tenants t ON t.id = d."tenantId";
GRANT SELECT ON public.public_tenant_domains TO anon, authenticated;

-- Nur der Betreiber vergibt Domains: sonst koennte ein Vereinsadministrator
-- die Adresse eines anderen Vereins auf sich umbiegen.
DROP POLICY IF EXISTS tenant_domains_platform ON public.tenant_domains;
CREATE POLICY tenant_domains_platform ON public.tenant_domains FOR ALL TO authenticated
USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

INSERT INTO public.tenant_domains (domain, "tenantId", "isPrimary") VALUES
  ('www.koretini.me',             'koretini', true),
  ('koretini.me',                 'koretini', false),
  ('shoqatawebsite.vercel.app',   'koretini', false),
  ('localhost',                   'koretini', false)
ON CONFLICT (domain) DO NOTHING;

-- ------------------------------------- Oeffentliche Sichten mit Vereinsbezug
-- DROP statt REPLACE: eine bestehende Sicht laesst keine neue Spalte an
-- zweiter Stelle zu. Die Rechte werden danach neu vergeben.
DROP VIEW IF EXISTS public.public_members;
CREATE VIEW public.public_members AS
  SELECT id, "tenantId", "displayName", "photoFileName", city, country,
         "membershipStatus", "livesInKoretin"
    FROM public.users
   WHERE "membershipStatus" IS DISTINCT FROM 'INACTIVE';
GRANT SELECT ON public.public_members TO anon, authenticated;

DROP VIEW IF EXISTS public.public_settings;
CREATE VIEW public.public_settings AS
  SELECT id, "tenantId",
         (payment - 'paypalSecret' - 'paypalClientId') AS payment,
         company, branding, system, data
    FROM public.settings;
GRANT SELECT ON public.public_settings TO anon, authenticated;

-- --------------------------- Gastanmeldungen: Verein aus der Veranstaltung
-- Der Verein darf hier nicht vom Aufrufer kommen. Ein Gast ist nicht
-- angemeldet, current_tenant() ist also leer, und die bisherige Notloesung fiel
-- auf 'koretini' zurueck -- mit einem zweiten Verein waere jede fremde
-- Gastanmeldung bei Koretini gelandet. Die Veranstaltung weiss es besser.
CREATE OR REPLACE FUNCTION public.set_registration_tenant()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_tenant text;
BEGIN
  SELECT e."tenantId" INTO v_tenant FROM public.events e WHERE e.id = NEW."eventId";
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Anmeldung ohne zuordenbare Veranstaltung (%).', NEW."eventId"
      USING ERRCODE = 'check_violation';
  END IF;
  NEW."tenantId" := v_tenant;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS event_registrations_set_tenant ON public.event_registrations;
CREATE TRIGGER event_registrations_set_tenant
BEFORE INSERT ON public.event_registrations
FOR EACH ROW EXECUTE FUNCTION public.set_registration_tenant();
