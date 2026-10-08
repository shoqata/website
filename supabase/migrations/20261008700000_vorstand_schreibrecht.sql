-- Der Verein kann dem Vorstand das Schreiben entziehen.
--
-- Gemessen, bevor etwas geaendert wurde:
--   is_staff() steckt in 14 reinen LESEregeln und 25 ALL-Regeln.
--   Haette ich dort BOARD herausgenommen, haette der Vorstand auch das
--   LESEN verloren -- Sitzungen, Protokolle, Mitgliederliste. Gewollt
--   war das Gegenteil: er soll sehen duerfen, nur nicht mehr aendern.
--
-- Deshalb wird keine bestehende Regel angefasst. Stattdessen kommt je
-- Tabelle eine EINSCHRAENKENDE Regel dazu, die ausschliesslich INSERT,
-- UPDATE und DELETE trifft. Einschraenkende Regeln werden mit UND
-- verknuepft: eine bestehende Erlaubnis bleibt noetig, reicht aber nicht
-- mehr allein. SELECT bleibt voellig unberuehrt.
--
-- Vorgabe ist AN -- wer nichts umstellt, merkt von dieser Migration nichts.

-- ------------------------------------------------------- Die Einstellung
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS vorstand_schreibt boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.tenants.vorstand_schreibt IS
  'Darf die Rolle BOARD Daten aendern? true (Vorgabe) = wie bisher. '
  'false = der Vorstand sieht alles, aendert aber nichts. '
  'SUPER_ADMIN und ADMIN sind davon nie betroffen.';


-- ------------------------------------------------------- Die eine Frage
-- An einer Stelle beantwortet, nicht an einunddreissig.
CREATE OR REPLACE FUNCTION public.darf_schreiben()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    -- Betreiber und Vereinsadministration immer.
    WHEN public.is_platform_admin() THEN true
    WHEN public.app_role() IN ('SUPER_ADMIN','ADMIN') THEN true
    -- Der Vorstand nur, solange sein Verein es zulaesst.
    WHEN public.app_role() = 'BOARD' THEN
      coalesce((SELECT t.vorstand_schreibt FROM public.tenants t
                 WHERE t.id = public.current_tenant()), true)
    -- Alle uebrigen Rollen schreiben ohnehin nur ueber eigene Regeln
    -- (eigenes Profil, eigene Zusage); die bleiben unberuehrt, weil
    -- diese Schranke nur greift, wo bereits eine Erlaubnis besteht.
    ELSE true
  END;
$$;
-- anon braucht EXECUTE: die Schranke sitzt in Regeln, die auch fuer anon
-- gelten, und RLS wertet sie mit den Rechten des fragenden Kontos aus.
-- Verraten wird nichts -- die Funktion sagt nur etwas ueber den Fragenden.
REVOKE ALL ON FUNCTION public.darf_schreiben() FROM public;
GRANT EXECUTE ON FUNCTION public.darf_schreiben() TO anon, authenticated;


-- ------------------------------------------------- Die Schranke setzen
DO $$
DECLARE
  t text;
  tabellen text[] := ARRAY[
    'accounting_accounts','accounting_journal','board_meetings','board_members',
    'donations','event_registrations','events','expenses','families','family_links',
    'fiscal_budgets','glossar','inquiries','mail_queue','neighborhoods','news',
    'payment_reports','payments','polls','security_logs','settings','socialmediaposts',
    'spendenaufrufe','sponsors','tasks','textbausteine','treffen','treffen_delegation',
    'treffen_teilnehmer','users','videos'];
  n int := 0;
BEGIN
  FOREACH t IN ARRAY tabellen LOOP
    IF to_regclass('public.'||quote_ident(t)) IS NULL THEN
      RAISE EXCEPTION 'Tabelle % gibt es nicht -- Liste veraltet.', t;
    END IF;

    EXECUTE format('DROP POLICY IF EXISTS schreibschranke_ins ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS schreibschranke_upd ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS schreibschranke_del ON public.%I', t);

    -- Drei getrennte Regeln, je Befehl. Eine einzige FOR ALL waere
    -- bequemer, wuerde aber ueber USING auch SELECT treffen -- und
    -- genau das soll nicht passieren.
    EXECUTE format(
      'CREATE POLICY schreibschranke_ins ON public.%I AS RESTRICTIVE
         FOR INSERT TO authenticated WITH CHECK (public.darf_schreiben())', t);
    EXECUTE format(
      'CREATE POLICY schreibschranke_upd ON public.%I AS RESTRICTIVE
         FOR UPDATE TO authenticated
         USING (public.darf_schreiben()) WITH CHECK (public.darf_schreiben())', t);
    EXECUTE format(
      'CREATE POLICY schreibschranke_del ON public.%I AS RESTRICTIVE
         FOR DELETE TO authenticated USING (public.darf_schreiben())', t);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'Schreibschranke auf % Tabellen gesetzt', n;
END $$;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_spalte boolean; v_regeln int; v_select int; v_aus int;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='tenants'
                    AND column_name='vorstand_schreibt') INTO v_spalte;
  IF NOT v_spalte THEN RAISE EXCEPTION 'Spalte vorstand_schreibt fehlt.'; END IF;

  -- Vorgabe muss AN sein, sonst steht morgen jeder Vorstand still.
  SELECT count(*) INTO v_aus FROM public.tenants WHERE vorstand_schreibt IS NOT TRUE;
  IF v_aus > 0 THEN
    RAISE EXCEPTION '% Verein(e) haetten dem Vorstand sofort das Schreiben entzogen.', v_aus;
  END IF;

  SELECT count(*) INTO v_regeln FROM pg_policies
   WHERE schemaname='public' AND policyname LIKE 'schreibschranke_%';
  IF v_regeln <> 31 * 3 THEN
    RAISE EXCEPTION 'Erwartet % Schranken, gefunden %.', 31*3, v_regeln;
  END IF;

  -- Der Kern: keine Schranke darf SELECT betreffen. Genau das war der
  -- Grund, nicht einfach is_staff() zu aendern.
  SELECT count(*) INTO v_select FROM pg_policies
   WHERE schemaname='public' AND policyname LIKE 'schreibschranke_%'
     AND cmd NOT IN ('INSERT','UPDATE','DELETE');
  IF v_select > 0 THEN
    RAISE EXCEPTION '% Schranke(n) treffen auch das Lesen.', v_select;
  END IF;

  RAISE NOTICE 'Schreibschranke steht: % Regeln auf 31 Tabellen, keine davon auf SELECT. '
               'Vorgabe bleibt AN.', v_regeln;
END $$;
