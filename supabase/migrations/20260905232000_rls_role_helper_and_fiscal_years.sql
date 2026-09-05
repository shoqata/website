-- Vorbereitung fuer den Wechsel vom service_role-Key auf den publishable Key.
--
-- fiscal_years ist die einzige Tabelle mit aktivem RLS, hat aber keine einzige
-- Policy. Solange die App mit dem service_role-Key laeuft, faellt das nicht auf
-- (service_role umgeht RLS). Mit dem publishable Key waere die Tabelle fuer die
-- App komplett unlesbar und der Jahresabschluss in AdminAccounting kaputt.

-- Rollen-Helper: liest users.role als SECURITY DEFINER und umgeht damit RLS.
-- Ohne das wuerde eine Policy auf users, die users.role prueft, sich selbst
-- rekursiv aufrufen.
CREATE OR REPLACE FUNCTION public.app_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid()::text
$$;

REVOKE ALL ON FUNCTION public.app_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.app_role() TO authenticated;

-- fiscal_years: nur Vorstand und Administration, nie anonym.
DROP POLICY IF EXISTS fiscal_years_staff_all ON public.fiscal_years;
CREATE POLICY fiscal_years_staff_all ON public.fiscal_years
  FOR ALL TO authenticated
  USING (public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD'))
  WITH CHECK (public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD'));
