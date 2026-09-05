-- Oeffentliche Inhalte: lesbar fuer alle, aenderbar nur durch die Verwaltung.
--
-- Vor dieser Migration konnte ein anonymer Besucher News, Events, den Vorstand,
-- die Quartiere, die Mandantendaten und die Einstellungen nicht nur lesen,
-- sondern auch anlegen, aendern und loeschen -- ein Schreibversuch auf news
-- scheiterte nur an einer NOT-NULL-Spalte, nicht an einer Berechtigung.
--
-- Kein Statusfilter auf events/news: aktuell stehen dort ausschliesslich
-- DRAFT-Datensaetze, ein Filter wuerde die Startseite leeren. Das ist eine
-- Redaktionsentscheidung, keine Sicherheitsfrage.

DO $$
DECLARE
  t text;
  writer text;
BEGIN
  FOREACH t IN ARRAY ARRAY['events', 'news', 'board_members', 'tenants', 'settings',
                           'neighborhoods', 'polls']
  LOOP
    -- Quartiere pflegen auch Repraesentanten und Quartiersverantwortliche.
    writer := CASE WHEN t = 'neighborhoods'
                   THEN 'public.is_member_manager()'
                   ELSE 'public.is_staff()' END;

    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);

    -- Lesen bleibt oeffentlich, schreiben nicht.
    EXECUTE format('REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.%I FROM anon', t);
    EXECUTE format('GRANT SELECT ON TABLE public.%I TO anon', t);

    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_public_read', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO anon, authenticated USING (true)',
      t || '_public_read', t);

    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_manage', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (%s) WITH CHECK (%s)',
      t || '_manage', t, writer, writer);
  END LOOP;
END $$;

-- Abstimmen: Mitglieder aktualisieren polls.userVotes, ohne Umfragen anlegen
-- oder loeschen zu duerfen.
DROP POLICY IF EXISTS polls_vote ON public.polls;
CREATE POLICY polls_vote ON public.polls FOR UPDATE TO authenticated
USING (true) WITH CHECK (true);
