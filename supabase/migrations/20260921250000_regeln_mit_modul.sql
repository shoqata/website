-- Die Zeilenregeln fragen jetzt zusaetzlich nach dem Modul.
--
-- Jede bestehende Bedingung bleibt Wort fuer Wort erhalten -- ergaenzt wird
-- nur AND modul_aktiv('...'). Damit ist ein abgeschaltetes Modul auch ueber
-- die Schnittstelle abgeschaltet, nicht bloss im Reiter verborgen.
--
-- Nicht angefasst werden die Kernmodule (Mitglieder, Finanzen, Vorstand):
-- modul_aktiv() gibt fuer sie ohnehin immer true zurueck, und eine
-- zusaetzliche Bedingung an users oder payments waere ein Risiko ohne
-- Gegenwert.

-- ====================================================== BUCHHALTUNG
DROP POLICY IF EXISTS accounting_journal_staff ON public.accounting_journal;
CREATE POLICY accounting_journal_staff ON public.accounting_journal FOR ALL
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'));

DROP POLICY IF EXISTS accounting_accounts_staff ON public.accounting_accounts;
CREATE POLICY accounting_accounts_staff ON public.accounting_accounts FOR ALL
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'));

DROP POLICY IF EXISTS fiscal_budgets_staff ON public.fiscal_budgets;
CREATE POLICY fiscal_budgets_staff ON public.fiscal_budgets FOR ALL
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'));

DROP POLICY IF EXISTS fiscal_years_staff_all ON public.fiscal_years;
CREATE POLICY fiscal_years_staff_all ON public.fiscal_years FOR ALL
  USING (app_role() = ANY (ARRAY['SUPER_ADMIN','ADMIN','BOARD'])
         AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'))
  WITH CHECK (app_role() = ANY (ARRAY['SUPER_ADMIN','ADMIN','BOARD'])
         AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'));

DROP POLICY IF EXISTS expenses_staff ON public.expenses;
CREATE POLICY expenses_staff ON public.expenses FOR ALL
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('BUCHHALTUNG'));

-- ====================================================== STAMMBAUM
DROP POLICY IF EXISTS family_links_schreiben ON public.family_links;
CREATE POLICY family_links_schreiben ON public.family_links FOR ALL TO authenticated
  USING ("tenantId" = current_tenant() AND is_member_manager() AND modul_aktiv('STAMMBAUM'))
  WITH CHECK ("tenantId" = current_tenant() AND is_member_manager() AND modul_aktiv('STAMMBAUM'));

DROP POLICY IF EXISTS family_links_lesen ON public.family_links;
CREATE POLICY family_links_lesen ON public.family_links FOR SELECT TO authenticated
  USING (
    "tenantId" = current_tenant() AND modul_aktiv('STAMMBAUM')
    AND (is_member_manager()
         OR (is_neighborhood_steward() AND EXISTS (
               SELECT 1 FROM public.users u
                WHERE u.id IN (family_links.von, family_links.nach)
                  AND u."neighborhoodId" IN (SELECT public.my_neighborhoods()))))
  );

DROP POLICY IF EXISTS families_schreiben ON public.families;
CREATE POLICY families_schreiben ON public.families FOR ALL TO authenticated
  USING ("tenantId" = current_tenant() AND is_member_manager() AND modul_aktiv('STAMMBAUM'))
  WITH CHECK ("tenantId" = current_tenant() AND is_member_manager() AND modul_aktiv('STAMMBAUM'));

DROP POLICY IF EXISTS families_lesen ON public.families;
CREATE POLICY families_lesen ON public.families FOR SELECT TO authenticated
  USING (
    "tenantId" = current_tenant() AND modul_aktiv('STAMMBAUM')
    AND (is_member_manager()
         OR (is_neighborhood_steward() AND EXISTS (
               SELECT 1 FROM public.users u
                WHERE u.id = families.anker
                  AND u."neighborhoodId" IN (SELECT public.my_neighborhoods()))))
  );

-- ====================================================== ANLAESSE
DROP POLICY IF EXISTS events_manage ON public.events;
CREATE POLICY events_manage ON public.events FOR ALL
  USING (is_staff() AND "tenantId" = current_tenant() AND modul_aktiv('ANLAESSE'))
  WITH CHECK (is_staff() AND "tenantId" = current_tenant() AND modul_aktiv('ANLAESSE'));

DROP POLICY IF EXISTS events_public_read ON public.events;
CREATE POLICY events_public_read ON public.events FOR SELECT
  USING ("tenantId" = COALESCE(current_tenant(), request_tenant()) AND modul_aktiv('ANLAESSE'));

DROP POLICY IF EXISTS event_registrations_read ON public.event_registrations;
CREATE POLICY event_registrations_read ON public.event_registrations FOR SELECT
  USING (modul_aktiv('ANLAESSE')
         AND ((is_member_manager() AND "tenantId" = current_tenant())
              OR "userId" = current_user_row_id()));

DROP POLICY IF EXISTS event_registrations_insert ON public.event_registrations;
CREATE POLICY event_registrations_insert ON public.event_registrations FOR INSERT
  WITH CHECK (modul_aktiv('ANLAESSE')
              AND ((is_member_manager() AND "tenantId" = current_tenant())
                   OR "userId" = current_user_row_id()));

DROP POLICY IF EXISTS event_registrations_guest_insert ON public.event_registrations;
CREATE POLICY event_registrations_guest_insert ON public.event_registrations FOR INSERT
  WITH CHECK ("userId" IS NULL AND modul_aktiv('ANLAESSE'));

DROP POLICY IF EXISTS event_registrations_manage ON public.event_registrations;
CREATE POLICY event_registrations_manage ON public.event_registrations FOR UPDATE
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('ANLAESSE'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('ANLAESSE'));

-- ====================================================== NEUIGKEITEN
DROP POLICY IF EXISTS news_manage ON public.news;
CREATE POLICY news_manage ON public.news FOR ALL
  USING (is_staff() AND "tenantId" = current_tenant() AND modul_aktiv('NEUIGKEITEN'))
  WITH CHECK (is_staff() AND "tenantId" = current_tenant() AND modul_aktiv('NEUIGKEITEN'));

DROP POLICY IF EXISTS news_public_read ON public.news;
CREATE POLICY news_public_read ON public.news FOR SELECT
  USING ("tenantId" = COALESCE(current_tenant(), request_tenant()) AND modul_aktiv('NEUIGKEITEN'));

-- ====================================================== TURNIER
DROP POLICY IF EXISTS sponsors_staff_read ON public.sponsors;
CREATE POLICY sponsors_staff_read ON public.sponsors FOR SELECT
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('TURNIER'));
DROP POLICY IF EXISTS sponsors_staff_update ON public.sponsors;
CREATE POLICY sponsors_staff_update ON public.sponsors FOR UPDATE
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('TURNIER'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('TURNIER'));
DROP POLICY IF EXISTS sponsors_staff_delete ON public.sponsors;
CREATE POLICY sponsors_staff_delete ON public.sponsors FOR DELETE
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('TURNIER'));

-- ====================================================== SOCIAL
DROP POLICY IF EXISTS socialmediaposts_staff ON public.socialmediaposts;
CREATE POLICY socialmediaposts_staff ON public.socialmediaposts FOR ALL
  USING (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('SOCIAL'))
  WITH CHECK (is_member_manager() AND "tenantId" = current_tenant() AND modul_aktiv('SOCIAL'));

DO $$ BEGIN RAISE NOTICE 'Schalter an 18 Zeilenregeln gehaengt.'; END $$;
