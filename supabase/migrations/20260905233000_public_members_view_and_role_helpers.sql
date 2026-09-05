-- Serverseitiges Rollenmodell und eine oeffentliche Projektion auf users.
--
-- Ausgangslage: users ist ohne Login vollstaendig lesbar (341 Datensaetze inkl.
-- Adresse, Geburtsdatum, Telefon, internen Notizen). Oeffentlich gebraucht wird
-- davon nur, was die Startseite und die Ueber-uns-Seite anzeigen: Name, Bild,
-- Ort, Land, Status. Diese View ist die einzige Ausnahme, die anon spaeter noch
-- sehen darf.

-- Admin-Allowlist serverseitig. Das Gegenstueck zu ADMIN_EMAILS in App.tsx --
-- die Konstante im Browser ist keine Berechtigung, sondern nur eine Anzeige-
-- entscheidung. Ohne diese Tabelle koennte sich der Administrator nach dem
-- Einschalten von RLS nicht mehr selbst berechtigen, weil seine users-Zeile
-- erst beim ersten Login entsteht.
CREATE TABLE IF NOT EXISTS public.admin_emails (
  email text PRIMARY KEY
);
ALTER TABLE public.admin_emails ENABLE ROW LEVEL SECURITY;
-- Keine Policy: die Tabelle ist ausschliesslich fuer SECURITY-DEFINER-Funktionen
-- und den service_role da, nie fuer Clients.
REVOKE ALL ON TABLE public.admin_emails FROM anon, authenticated;

INSERT INTO public.admin_emails (email) VALUES ('email@dervishi.ch')
ON CONFLICT (email) DO NOTHING;

-- Rolle des aktuellen Nutzers. Reihenfolge: Allowlist schlaegt users.role,
-- damit der Administrator auch dann handlungsfaehig ist, wenn seine users-Zeile
-- fehlt oder noch die Legacy-ID traegt.
CREATE OR REPLACE FUNCTION public.app_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT 'SUPER_ADMIN'
       WHERE auth.jwt() ->> 'email' IS NOT NULL
         AND EXISTS (SELECT 1 FROM public.admin_emails
                      WHERE lower(email) = lower(auth.jwt() ->> 'email'))),
    (SELECT role FROM public.users WHERE id = auth.uid()::text),
    'GUEST'
  )
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')
$$;

-- Quartier des aktuellen Nutzers, fuer die Quartiersverantwortlichen. Als
-- DEFINER, damit eine Policy auf users nicht rekursiv users abfragt.
CREATE OR REPLACE FUNCTION public.app_neighborhood()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT "neighborhoodId" FROM public.users WHERE id = auth.uid()::text
$$;

REVOKE ALL ON FUNCTION public.app_role(), public.is_staff(), public.app_neighborhood() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.app_role(), public.is_staff(), public.app_neighborhood() TO authenticated;

-- Oeffentliche Projektion. Bewusst ohne security_invoker: die View laeuft mit
-- den Rechten ihres Eigentuemers und umgeht damit die RLS auf users -- genau
-- deshalb ist die Spaltenliste hier die eigentliche Zugriffsgrenze.
-- Kein Statusfilter: Hero filtert selbst auf ACTIVE, und AboutUsPage joint
-- Vorstandsmitglieder ueber die id, die sonst herausfallen koennten.
CREATE OR REPLACE VIEW public.public_members AS
  SELECT id,
         "displayName",
         "photoFileName",
         city,
         country,
         "membershipStatus",
         "livesInKoretin"
    FROM public.users;

GRANT SELECT ON public.public_members TO anon, authenticated;
