-- Sponsorenanfragen aus dem oeffentlichen Formular.
--
-- Besonderheit gegenueber allen anderen Tabellen: hier schreibt ein
-- *nicht angemeldeter* Besucher. Das ist gewollt -- ein Sponsor soll sich
-- melden koennen, ohne vorher ein Konto anzulegen.
--
-- Damit daraus kein Einfallstor wird, entscheidet nicht der Client, fuer
-- welchen Verein er schreibt, sondern die Anfrage selbst: request_tenant()
-- loest den Verein aus der aufrufenden Adresse auf. Eine Anfrage ohne
-- erkennbare Herkunft loest zu NULL auf und wird von der Pruefung abgewiesen.

CREATE TABLE IF NOT EXISTS public.sponsors (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,

  -- Gewaehltes Paket. 'CUSTOM' bedeutet: eigener Betrag im Feld amount.
  "packageKey"  text NOT NULL DEFAULT 'BASIC',
  amount        numeric(10,2),
  currency      text NOT NULL DEFAULT 'CHF',

  -- Kontakt
  company       text NOT NULL,
  "contactName" text NOT NULL,
  email         text NOT NULL,
  phone         text,
  street        text,
  zip           text,
  city          text,
  country       text,
  website       text,
  "logoUrl"     text,
  message       text,

  -- Bearbeitungsstand im Vorstand
  status        text NOT NULL DEFAULT 'NEW',
  "internalNote" text,

  "createdAt"   timestamptz NOT NULL DEFAULT now(),
  "updatedAt"   timestamptz
);

ALTER TABLE public.sponsors
  DROP CONSTRAINT IF EXISTS sponsors_status_check;
ALTER TABLE public.sponsors
  ADD CONSTRAINT sponsors_status_check
  CHECK (status IN ('NEW','IN_PROGRESS','CONFIRMED','DECLINED'));

ALTER TABLE public.sponsors
  DROP CONSTRAINT IF EXISTS sponsors_tenant_fk;
ALTER TABLE public.sponsors
  ADD CONSTRAINT sponsors_tenant_fk
  FOREIGN KEY ("tenantId") REFERENCES public.tenants(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS sponsors_tenant_idx  ON public.sponsors ("tenantId");
CREATE INDEX IF NOT EXISTS sponsors_status_idx  ON public.sponsors ("tenantId", status);
CREATE INDEX IF NOT EXISTS sponsors_created_idx ON public.sponsors ("createdAt" DESC);

ALTER TABLE public.sponsors ENABLE ROW LEVEL SECURITY;

-- Schreiben: jeder Besucher, aber nur fuer den Verein der aufrufenden Adresse.
DROP POLICY IF EXISTS sponsors_public_insert ON public.sponsors;
CREATE POLICY sponsors_public_insert ON public.sponsors
  FOR INSERT TO anon, authenticated
  WITH CHECK ("tenantId" = COALESCE(public.current_tenant(), public.request_tenant()));

-- Lesen und bearbeiten: nur der Vorstand des eigenen Vereins.
DROP POLICY IF EXISTS sponsors_staff_read ON public.sponsors;
CREATE POLICY sponsors_staff_read ON public.sponsors
  FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS sponsors_staff_update ON public.sponsors;
CREATE POLICY sponsors_staff_update ON public.sponsors
  FOR UPDATE TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
  WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS sponsors_staff_delete ON public.sponsors;
CREATE POLICY sponsors_staff_delete ON public.sponsors
  FOR DELETE TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());

GRANT INSERT ON public.sponsors TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sponsors TO authenticated;

NOTIFY pgrst, 'reload schema';
