-- Rechte aufraeumen: anon darf nur noch, was die oeffentliche Seite
-- wirklich braucht.
--
-- Ausgangslage, gemessen und nicht vermutet:
--   * Sieben Tabellen trugen INSERT/UPDATE/DELETE/TRUNCATE fuer anon.
--     Das kam nicht aus einer Migration, sondern aus der
--     Standardvergabe von Supabase (ALTER DEFAULT PRIVILEGES).
--   * Offen war dadurch NICHTS: auf allen sieben ist RLS an, und es
--     gibt keine einzige Schreibregel in der ganzen Datenbank, die
--     ohne Waechter auskommt (is_staff / is_platform_admin /
--     is_member_manager / current_tenant / auth.uid /
--     current_user_row_id). Alle sind fuer anon false bzw. NULL.
--   * EXECUTE liegt in PostgreSQL von Haus aus bei PUBLIC. Dadurch
--     durfte anon 77 SECURITY-DEFINER-Funktionen aufrufen. Die
--     gefaehrlichen weisen intern ab -- geprueft an jahresabschluss,
--     treffen_zugang_erstellen, revisionszugang_erstellen,
--     treffen_verrechnen, treffen_essenszahlen.
--
-- Es wird also keine Luecke geschlossen, sondern eine zweite Mauer
-- gezogen: heute haelt allein RLS beziehungsweise die Wache in der
-- Funktion. Wer morgen eine grosszuegige Regel ergaenzt oder RLS an
-- einer Tabelle vergisst, soll nicht sofort offen dastehen.
--
-- Was ausdruecklich BLEIBT, weil es das Produkt ist:
--   * event_registrations INSERT fuer anon -- die oeffentliche
--     Anmeldung zu einem Anlass. Die Regel prueft Verein und Modul.
--   * Die Funktionen der oeffentlichen Seiten und der Token-Wege
--     (Spenden, Gastverein, Selbstvorstellung, Heft, Revision).
--     Ein Token IST dort die Anmeldung.
--
-- NICHT angefasst werden Hilfs- und Triggerfunktionen. RLS wertet
-- is_staff() & Co. mit den Rechten des fragenden Kontos aus -- ein
-- Entzug dort legt jede oeffentliche Seite lahm.

-- ---------------------------------------------------------------- Tabellen
DO $$
DECLARE r RECORD; n int := 0;
BEGIN
  FOR r IN SELECT c.relname
             FROM pg_class c JOIN pg_namespace ns ON ns.oid = c.relnamespace
            WHERE ns.nspname = 'public' AND c.relkind IN ('r','p')
  LOOP
    EXECUTE format(
      'REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.%I FROM anon, PUBLIC',
      r.relname);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'Schreibrechte von anon entzogen auf % Tabellen', n;
END $$;

-- Der eine Weg, der bleibt: die oeffentliche Anmeldung zu einem Anlass.
GRANT INSERT ON public.event_registrations TO anon;

-- ---------------------------------------------------------------- Funktionen
DO $$
DECLARE
  -- Was anon NICHT mehr aufrufen darf. Hergeleitet daraus, wer die
  -- Funktion im Frontend aufruft: alle diese stehen ausschliesslich
  -- hinter einer Anmeldung.
  gesperrt text[] := ARRAY[
    'create_tenant','decide_payment_report','end_tenant_support','start_tenant_support',
    'familien_uebersicht','jahresabschluss','jahresrechnung_betrag','kontenplan_anlegen',
    'mail_einstellungen_lesen','mail_einstellungen_speichern','mark_payment_paid',
    'marktplatz_uebersicht','modul_katalog_speichern','modul_umschalten','modul_verbreitung',
    'my_neighborhood_contacts','my_neighborhoods','nachbarschaft_puls',
    'plattform_geheimnis_setzen','plattform_geheimnisse','report_payment_paid',
    'reset_member_password','revisionsbericht','revisionszugang_erstellen',
    'revisionszugang_widerrufen','social_einrichtung','social_jetzt_senden',
    'social_seite_waehlen','social_trennen','social_verbinden_starten','social_verbindungen',
    'spende_bescheinigt','spende_bezahlt','spendenaufrufe_stand','startseiten_vorlagen_auswahl',
    'treffen_ausflugslisten','treffen_essenszahlen','treffen_kosten','treffen_mein_antworten',
    'treffen_meine','treffen_namensschilder','treffen_programm_verschieben','treffen_verrechnen',
    'treffen_vorstellung_links','treffen_zugang_erstellen','treffen_zugang_widerrufen',
    'vereins_administrator_setzen','widersprueche_zaehlen','zahlungen_verbuchen'];
  r RECORD; n int := 0;
BEGIN
  FOR r IN SELECT p.oid, p.proname,
                  pg_get_function_identity_arguments(p.oid) AS args
             FROM pg_proc p JOIN pg_namespace ns ON ns.oid = p.pronamespace
            WHERE ns.nspname = 'public' AND p.proname = ANY(gesperrt)
  LOOP
    -- Erst PUBLIC weg, dann gezielt zurueckgeben. Nur PUBLIC zu
    -- entziehen genuegt nicht: authenticated haette dann gar nichts
    -- mehr, denn es hing bloss am PUBLIC-Recht.
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM PUBLIC, anon',
                   r.proname, r.args);
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO authenticated, service_role',
                   r.proname, r.args);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'EXECUTE fuer anon entzogen auf % Funktionen', n;
END $$;

-- Was die oeffentliche Seite und die Token-Wege brauchen, ausdruecklich
-- bestaetigt -- damit es hier steht und nicht aus einer Vorgabe faellt.
DO $$
DECLARE
  oeffentlich text[] := ARRAY[
    'startseiten_vorlage','startseite_variante','module_oeffentlich','spendenseite_sichtbar',
    'beitragsstand_oeffentlich','spendenaufrufe_oeffentlich','spende_anlegen',
    'spende_aufruf_zuordnen','treffen_oeffentlich','revisionsdaten','treffen_gast_lesen',
    'treffen_gast_antworten','treffen_token_pruefen','vorstellung_lesen','vorstellung_speichern',
    'ausfluege_fuer','ausflug_anmelden','heft_fuer_teilnehmer','submit_platform_lead',
    'submit_sponsor','claim_my_profile','wer_bin_ich'];
  r RECORD; n int := 0;
BEGIN
  FOR r IN SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
             FROM pg_proc p JOIN pg_namespace ns ON ns.oid = p.pronamespace
            WHERE ns.nspname = 'public' AND p.proname = ANY(oeffentlich)
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO anon, authenticated',
                   r.proname, r.args);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'oeffentlich bestaetigt: % Funktionen', n;
END $$;


-- ---------------------------------------------------------------- Selbsttest
-- Nicht "lief durch", sondern: stimmt hinterher, was stimmen soll --
-- und zwar in BEIDE Richtungen. Eine Sperre, die auch das Erlaubte
-- sperrt, ist keine Verbesserung.
DO $$
DECLARE
  schreibrechte int;
  fremd         text;
  durchgefallen text;
  fehlend       text;
BEGIN
  -- 1. Kein anon-Schreibrecht ausser der Anlass-Anmeldung.
  SELECT count(*), string_agg(DISTINCT table_name||':'||privilege_type, ', ')
    INTO schreibrechte, fremd
    FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon'
     AND privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE')
     AND NOT (table_name='event_registrations' AND privilege_type='INSERT');
  IF schreibrechte > 0 THEN
    RAISE EXCEPTION 'anon haelt noch % Schreibrecht(e): %', schreibrechte, fremd;
  END IF;

  -- 2. Keine gesperrte Funktion ist fuer anon erreichbar.
  SELECT string_agg(p.proname, ', ') INTO durchgefallen
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public'
     AND p.proname = ANY(ARRAY['create_tenant','jahresabschluss','mark_payment_paid',
         'reset_member_password','revisionszugang_erstellen','treffen_zugang_erstellen',
         'treffen_verrechnen','plattform_geheimnisse','vereins_administrator_setzen',
         'startseiten_vorlagen_auswahl','zahlungen_verbuchen','social_verbinden_starten'])
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF durchgefallen IS NOT NULL THEN
    RAISE EXCEPTION 'anon darf noch aufrufen: %', durchgefallen;
  END IF;

  -- 3. Gegenprobe: authenticated darf es weiterhin. Sonst haette ich
  --    die Verwaltung abgeschlossen statt die Tuer.
  SELECT string_agg(p.proname, ', ') INTO fehlend
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public'
     AND p.proname = ANY(ARRAY['create_tenant','jahresabschluss','mark_payment_paid',
         'reset_member_password','revisionszugang_erstellen','treffen_zugang_erstellen',
         'treffen_verrechnen','plattform_geheimnisse','vereins_administrator_setzen',
         'startseiten_vorlagen_auswahl','zahlungen_verbuchen','social_verbinden_starten'])
     AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE');
  IF fehlend IS NOT NULL THEN
    RAISE EXCEPTION 'authenticated verlor den Zugriff auf: %', fehlend;
  END IF;

  -- 4. Gegenprobe: die oeffentlichen Wege stehen noch offen.
  SELECT string_agg(p.proname, ', ') INTO fehlend
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public'
     AND p.proname = ANY(ARRAY['startseiten_vorlage','module_oeffentlich','spende_anlegen',
         'treffen_gast_lesen','vorstellung_speichern','heft_fuer_teilnehmer','revisionsdaten',
         'submit_platform_lead','ausflug_anmelden','wer_bin_ich'])
     AND NOT has_function_privilege('anon', p.oid, 'EXECUTE');
  IF fehlend IS NOT NULL THEN
    RAISE EXCEPTION 'oeffentlicher Weg zugemauert: %', fehlend;
  END IF;

  -- 5. Und die Anlass-Anmeldung muss bleiben.
  IF NOT EXISTS (SELECT 1 FROM information_schema.role_table_grants
                  WHERE table_schema='public' AND table_name='event_registrations'
                    AND grantee='anon' AND privilege_type='INSERT') THEN
    RAISE EXCEPTION 'Die oeffentliche Anmeldung zu Anlaessen wurde mit abgeraeumt.';
  END IF;

  RAISE NOTICE 'Selbsttest bestanden: anon schreibt nur noch Anlass-Anmeldungen, '
               'die Verwaltung und die oeffentlichen Wege sind unveraendert erreichbar.';
END $$;
