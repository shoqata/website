-- fiscal_budgets fehlt, obwohl AdminFinance sie liest und schreibt.
--
-- Beim Umzug von Firestore ist die Sammlung nicht mitgekommen. Das Lesen in
-- fetchBudget hat keine Fehlerbehandlung, die Abfrage wirft also ungefangen und
-- das Budget-Panel laedt gar nicht erst; das Speichern meldet "Fehler beim
-- Speichern". Die Form ergibt sich vollstaendig aus dem Code: das Jahr als id,
-- die Positionen als JSONB.
CREATE TABLE IF NOT EXISTS public.fiscal_budgets (
  id text PRIMARY KEY,
  year integer,
  entries jsonb NOT NULL DEFAULT '{}',
  "tenantId" text,
  "updatedAt" timestamptz DEFAULT now()
);

-- Wie die uebrigen Buchhaltungstabellen: nie oeffentlich, nur die Verwaltung.
ALTER TABLE public.fiscal_budgets ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.fiscal_budgets FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.fiscal_budgets TO authenticated;

DROP POLICY IF EXISTS fiscal_budgets_staff ON public.fiscal_budgets;
CREATE POLICY fiscal_budgets_staff ON public.fiscal_budgets
  FOR ALL TO authenticated
  USING (public.is_member_manager())
  WITH CHECK (public.is_member_manager());
