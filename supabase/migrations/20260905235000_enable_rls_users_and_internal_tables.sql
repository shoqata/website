-- RLS fuer die Tabellen, die niemals oeffentlich sein duerfen.
--
-- Bisher galt: RLS aus, GRANT ALL an anon. Jeder Besucher konnte die
-- Mitgliederdatenbank samt Adressen, Geburtsdaten und Zahlungen lesen und
-- schreiben. Die oeffentlichen Seiten lesen seit dem letzten Deploy nur noch
-- public_members, deshalb kann users jetzt zugemacht werden.
--
-- Leitgedanke: bestehende Ablaeufe bleiben erhalten, nur Rechteausweitung wird
-- unterbunden. Repraesentanten und Quartiersverantwortliche verwalten heute
-- Mitglieder und duerfen das weiterhin -- aber niemand kann sich selbst oder
-- andere zu ADMIN machen.

CREATE OR REPLACE FUNCTION public.is_member_manager()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.app_role() IN
    ('SUPER_ADMIN', 'ADMIN', 'BOARD', 'REPRESENTATIVE', 'NEIGHBORHOOD_MANAGER')
$$;

-- Rolle, die ein Nutzer beim ersten Login uebernehmen darf. Legacy-Mitglieder
-- bekommen in App.tsx eine neue Zeile mit ihrer Auth-UID, die die Daten der
-- alten Zeile kopiert -- inklusive Rolle. Ohne diesen Helfer waere entweder die
-- Uebernahme kaputt oder jeder koennte sich selbst zum Admin ernennen.
CREATE OR REPLACE FUNCTION public.claimable_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT role FROM public.users
      WHERE auth.jwt() ->> 'email' IS NOT NULL
        AND lower(email) = lower(auth.jwt() ->> 'email')
        AND id <> auth.uid()::text
      LIMIT 1),
    'MEMBER')
$$;

REVOKE ALL ON FUNCTION public.is_member_manager(), public.claimable_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_member_manager(), public.claimable_role() TO authenticated;

-- ---------------------------------------------------------------- users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.users FROM anon;

DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
USING (
  public.is_member_manager()
  OR id = auth.uid()::text
  -- Eigene Legacy-Zeile: App.tsx sucht nach dem Login per E-Mail danach.
  OR (auth.jwt() ->> 'email' IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
);

DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
WITH CHECK (
  public.is_staff()
  OR (public.is_member_manager() AND COALESCE(role, 'MEMBER') IN ('MEMBER', 'GUEST'))
  OR (id = auth.uid()::text AND COALESCE(role, 'MEMBER') IN (public.claimable_role(), 'MEMBER'))
);

DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
USING (
  public.is_member_manager()
  OR id = auth.uid()::text
)
WITH CHECK (
  public.is_staff()
  OR (public.is_member_manager() AND COALESCE(role, 'MEMBER') IN ('MEMBER', 'GUEST'))
  -- Selbstaenderung darf die eigene Rolle nicht anheben.
  OR (id = auth.uid()::text AND COALESCE(role, 'MEMBER') = COALESCE(public.app_role(), 'MEMBER'))
);

DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users FOR DELETE TO authenticated
USING (public.is_staff());

-- ------------------------------------------------- Mitglieder-bezogene Daten
-- payments: Mitglied sieht die eigenen, Verwaltung sieht und pflegt alle.
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.payments FROM anon;
DROP POLICY IF EXISTS payments_read ON public.payments;
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
USING (public.is_member_manager() OR "userId" = auth.uid()::text);
DROP POLICY IF EXISTS payments_write ON public.payments;
CREATE POLICY payments_write ON public.payments FOR ALL TO authenticated
USING (public.is_member_manager()) WITH CHECK (public.is_member_manager());

-- inquiries: eigene Anfragen lesen und stellen.
ALTER TABLE public.inquiries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.inquiries FROM anon;
DROP POLICY IF EXISTS inquiries_read ON public.inquiries;
CREATE POLICY inquiries_read ON public.inquiries FOR SELECT TO authenticated
USING (public.is_member_manager() OR "userId" = auth.uid()::text);
DROP POLICY IF EXISTS inquiries_insert ON public.inquiries;
CREATE POLICY inquiries_insert ON public.inquiries FOR INSERT TO authenticated
WITH CHECK (public.is_member_manager() OR "userId" = auth.uid()::text);
DROP POLICY IF EXISTS inquiries_manage ON public.inquiries;
CREATE POLICY inquiries_manage ON public.inquiries FOR UPDATE TO authenticated
USING (public.is_member_manager()) WITH CHECK (public.is_member_manager());

-- event_registrations: eigene Anmeldung, Verwaltung sieht alle.
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.event_registrations FROM anon;
DROP POLICY IF EXISTS event_registrations_read ON public.event_registrations;
CREATE POLICY event_registrations_read ON public.event_registrations FOR SELECT TO authenticated
USING (public.is_member_manager() OR "userId" = auth.uid()::text);
DROP POLICY IF EXISTS event_registrations_insert ON public.event_registrations;
CREATE POLICY event_registrations_insert ON public.event_registrations FOR INSERT TO authenticated
WITH CHECK (public.is_member_manager() OR "userId" = auth.uid()::text);
DROP POLICY IF EXISTS event_registrations_manage ON public.event_registrations;
CREATE POLICY event_registrations_manage ON public.event_registrations FOR UPDATE TO authenticated
USING (public.is_member_manager()) WITH CHECK (public.is_member_manager());

-- --------------------------------------------------- rein interne Tabellen
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['expenses', 'accounting_journal', 'accounting_accounts',
                           'board_meetings', 'tasks', 'security_logs', 'socialmediaposts']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM anon', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_staff', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated
         USING (public.is_member_manager()) WITH CHECK (public.is_member_manager())',
      t || '_staff', t);
  END LOOP;
END $$;
