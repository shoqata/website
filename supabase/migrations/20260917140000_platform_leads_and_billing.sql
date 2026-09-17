-- Die Vereinsverwaltung war bis hierher zu grossen Teilen Attrappe: die
-- Interessenten, der Monatsumsatz und die Transaktionen standen fest im Code,
-- "Verwalten" hatte keine Funktion, und Gebuehren liessen sich nirgends
-- hinterlegen. Diese Migration legt die Daten dafuer an.

-- ------------------------------------------------- Gebuehren je Verein
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS "annualFee"    numeric(10,2);
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS "setupFee"     numeric(10,2);
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS currency       text DEFAULT 'CHF';
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS "contractStart" date;
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS "billingNote"  text;
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS "contactName"  text;
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS phone          text;

-- ------------------------------------------------- Interessenten (CRM)
CREATE TABLE IF NOT EXISTS public.platform_leads (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  "contactName" text,
  email         text,
  phone         text,
  city          text,
  -- LEAD = moegliche Interessenten, TALKS = in Gespraechen,
  -- ONBOARDING = Einrichtung laeuft, WON = Verein angelegt, LOST = abgesagt
  stage         text NOT NULL DEFAULT 'LEAD',
  "expectedMembers" int,
  note          text,
  "tenantId"    text REFERENCES public.tenants(id) ON DELETE SET NULL,
  "createdAt"   timestamptz NOT NULL DEFAULT now(),
  "updatedAt"   timestamptz
);
ALTER TABLE public.platform_leads DROP CONSTRAINT IF EXISTS platform_leads_stage_check;
ALTER TABLE public.platform_leads ADD CONSTRAINT platform_leads_stage_check
  CHECK (stage IN ('LEAD','TALKS','ONBOARDING','WON','LOST'));
CREATE INDEX IF NOT EXISTS platform_leads_stage_idx ON public.platform_leads (stage);

-- ------------------------------------ Rechnungen der Plattform an Vereine
CREATE TABLE IF NOT EXISTS public.platform_invoices (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  -- SETUP = einmalige Einrichtungsgebuehr, ANNUAL = Jahresgebuehr
  kind          text NOT NULL DEFAULT 'ANNUAL',
  amount        numeric(10,2) NOT NULL,
  currency      text NOT NULL DEFAULT 'CHF',
  year          int,
  status        text NOT NULL DEFAULT 'DRAFT',
  "invoiceNumber" text,
  "issuedAt"    date NOT NULL DEFAULT current_date,
  "dueDate"     date,
  "paidAt"      date,
  note          text,
  "createdAt"   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_invoices DROP CONSTRAINT IF EXISTS platform_invoices_kind_check;
ALTER TABLE public.platform_invoices ADD CONSTRAINT platform_invoices_kind_check
  CHECK (kind IN ('SETUP','ANNUAL','OTHER'));
ALTER TABLE public.platform_invoices DROP CONSTRAINT IF EXISTS platform_invoices_status_check;
ALTER TABLE public.platform_invoices ADD CONSTRAINT platform_invoices_status_check
  CHECK (status IN ('DRAFT','SENT','PAID','CANCELLED'));
CREATE INDEX IF NOT EXISTS platform_invoices_tenant_idx ON public.platform_invoices ("tenantId");
CREATE INDEX IF NOT EXISTS platform_invoices_status_idx ON public.platform_invoices (status);

-- ------------------------------------------------------------------ Rechte
-- Beides geht ausschliesslich den Betreiber der Plattform an. Kein Verein,
-- auch nicht dessen Administration, darf hier etwas sehen.
ALTER TABLE public.platform_leads    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS platform_leads_owner ON public.platform_leads;
CREATE POLICY platform_leads_owner ON public.platform_leads FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS platform_invoices_owner ON public.platform_invoices;
CREATE POLICY platform_invoices_owner ON public.platform_invoices FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

REVOKE ALL ON public.platform_leads    FROM anon;
REVOKE ALL ON public.platform_invoices FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.platform_leads    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.platform_invoices TO authenticated;

NOTIFY pgrst, 'reload schema';
