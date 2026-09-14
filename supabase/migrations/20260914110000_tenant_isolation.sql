-- Mandantentrennung durchsetzen. Stufe 2 von 3.
--
-- Bis hierher lautete jede Regel sinngemaess "ist Verwaltung". Ab jetzt heisst
-- sie "ist Verwaltung DIESES Mandanten". Ohne diesen Schritt saehe der zweite
-- Verein die Daten des ersten -- nicht durch eine Luecke, sondern weil die
-- Trennung nirgends stattfand.
--
-- Nebenbei korrigiert: Mitglieder konnten ihre eigenen Zahlungen, Anfragen und
-- Anmeldungen nicht mehr sehen. Die Regeln verglichen mit auth.uid(), die
-- Fremdschluessel zeigen aber auf die users-Zeile -- und die traegt seit der
-- Profilverknuepfung weiterhin ihre urspruengliche ID. current_user_row_id()
-- loest genau das auf.

-- ----------------------------------------------------------------- users
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
USING (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  -- Die eigene Zeile bleibt ohne Mandantenbedingung erreichbar: sie wird zum
  -- Beanspruchen des Profils gebraucht, bevor ein Mandant ueberhaupt feststeht.
  OR id = auth.uid()::text
  OR "authUserId" = auth.uid()::text
  OR (auth.jwt() ->> 'email' IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
);

DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
WITH CHECK (
  (public.is_staff() AND "tenantId" = public.current_tenant())
  OR (public.is_member_manager() AND "tenantId" = public.current_tenant()
      AND COALESCE(role, 'MEMBER') IN ('MEMBER', 'GUEST'))
  -- Eigenanlage beim ersten Login: der Mandant wird vom Trigger gesetzt.
  OR (id = auth.uid()::text AND COALESCE(role, 'MEMBER') IN (public.claimable_role(), 'MEMBER'))
);

DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
USING (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR id = auth.uid()::text
  OR "authUserId" = auth.uid()::text
)
WITH CHECK (
  (public.is_staff() AND "tenantId" = public.current_tenant())
  OR (public.is_member_manager() AND "tenantId" = public.current_tenant()
      AND COALESCE(role, 'MEMBER') IN ('MEMBER', 'GUEST'))
  OR ((id = auth.uid()::text OR "authUserId" = auth.uid()::text)
      AND COALESCE(role, 'MEMBER') = COALESCE(public.app_role(), 'MEMBER'))
);

DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users FOR DELETE TO authenticated
USING (public.is_staff() AND "tenantId" = public.current_tenant());

-- ------------------------------------------------ eigene Daten der Mitglieder
DROP POLICY IF EXISTS payments_read ON public.payments;
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
USING (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR "userId" = public.current_user_row_id()
);
DROP POLICY IF EXISTS payments_write ON public.payments;
CREATE POLICY payments_write ON public.payments FOR ALL TO authenticated
USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS inquiries_read ON public.inquiries;
CREATE POLICY inquiries_read ON public.inquiries FOR SELECT TO authenticated
USING (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR "userId" = public.current_user_row_id()
);
DROP POLICY IF EXISTS inquiries_insert ON public.inquiries;
CREATE POLICY inquiries_insert ON public.inquiries FOR INSERT TO authenticated
WITH CHECK (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR "userId" = public.current_user_row_id()
);
DROP POLICY IF EXISTS inquiries_manage ON public.inquiries;
CREATE POLICY inquiries_manage ON public.inquiries FOR UPDATE TO authenticated
USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS event_registrations_read ON public.event_registrations;
CREATE POLICY event_registrations_read ON public.event_registrations FOR SELECT TO authenticated
USING (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR "userId" = public.current_user_row_id()
);
DROP POLICY IF EXISTS event_registrations_insert ON public.event_registrations;
CREATE POLICY event_registrations_insert ON public.event_registrations FOR INSERT TO authenticated
WITH CHECK (
  (public.is_member_manager() AND "tenantId" = public.current_tenant())
  OR "userId" = public.current_user_row_id()
);
DROP POLICY IF EXISTS event_registrations_manage ON public.event_registrations;
CREATE POLICY event_registrations_manage ON public.event_registrations FOR UPDATE TO authenticated
USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

-- --------------------------------------------------- rein interne Tabellen
DO $$
DECLARE t text; p text;
BEGIN
  FOREACH t IN ARRAY ARRAY['expenses','accounting_journal','accounting_accounts',
                           'board_meetings','tasks','security_logs','socialmediaposts'] LOOP
    p := t || '_staff';
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p, t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated
         USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
         WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant())', p, t);
  END LOOP;
END $$;

DROP POLICY IF EXISTS fiscal_years_staff_all ON public.fiscal_years;
CREATE POLICY fiscal_years_staff_all ON public.fiscal_years FOR ALL TO authenticated
USING (public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD') AND "tenantId" = public.current_tenant())
WITH CHECK (public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD') AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS fiscal_budgets_staff ON public.fiscal_budgets;
CREATE POLICY fiscal_budgets_staff ON public.fiscal_budgets FOR ALL TO authenticated
USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

-- --------------------------------------------- Inhalte: lesen oeffentlich,
-- aendern nur durch die Verwaltung des eigenen Mandanten
DO $$
DECLARE t text; p text; w text;
BEGIN
  FOREACH t IN ARRAY ARRAY['events','news','board_members','settings','neighborhoods','polls'] LOOP
    w := CASE WHEN t IN ('neighborhoods') THEN 'public.is_member_manager()' ELSE 'public.is_staff()' END;
    p := t || '_manage';
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p, t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated
         USING (%s AND "tenantId" = public.current_tenant())
         WITH CHECK (%s AND "tenantId" = public.current_tenant())', p, t, w, w);
  END LOOP;
END $$;

DROP POLICY IF EXISTS settings_staff_read ON public.settings;
CREATE POLICY settings_staff_read ON public.settings FOR SELECT TO authenticated
USING (public.is_staff() AND "tenantId" = public.current_tenant());

-- ------------------------------------------- Mandantenverzeichnis abriegeln
-- tenants ist kein Vereinsinhalt, sondern das Verzeichnis der Plattform.
-- Schreiben darf ausschliesslich der Betreiber. Fuer die oeffentliche Seite
-- genuegt eine Sicht ohne Abrechnungs- und Kontaktdaten.
CREATE OR REPLACE VIEW public.public_tenants AS
  SELECT id, slug, domain, name, "logoUrl", "primaryColor", "secondaryColor"
    FROM public.tenants;
GRANT SELECT ON public.public_tenants TO anon, authenticated;

REVOKE ALL ON TABLE public.tenants FROM anon;
DROP POLICY IF EXISTS tenants_public_read ON public.tenants;
DROP POLICY IF EXISTS tenants_manage ON public.tenants;

CREATE POLICY tenants_own_read ON public.tenants FOR SELECT TO authenticated
USING (public.is_platform_admin() OR id = public.current_tenant());

CREATE POLICY tenants_platform_manage ON public.tenants FOR ALL TO authenticated
USING (public.is_platform_admin())
WITH CHECK (public.is_platform_admin());
