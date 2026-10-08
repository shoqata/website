-- Der Schreibentzug galt nur fuer Tabellen, nicht fuer Funktionen.
--
-- Gemessen, bevor etwas geaendert wurde: 26 SECURITY-DEFINER-Funktionen
-- schreiben auf die Tabellen, die 20261008700000 geschuetzt hat. Zehn davon
-- lassen den Vorstand zu und pruefen den Entzug nicht:
--
--   decide_payment_report      mark_payment_paid        spende_bescheinigt
--   jahresabschluss            reset_member_password    spende_bezahlt
--   kontenplan_anlegen         revisionszugang_erstellen
--   treffen_vorstellung_links  zahlungen_verbuchen
--
-- SECURITY DEFINER umgeht die Zeilenregeln -- das ist sein Zweck. Genau
-- deshalb lief der Entzug ins Leere: ein Vorstand ohne Schreibrecht konnte
-- weiterhin Zahlungen als bezahlt kennzeichnen, den Jahresabschluss
-- ausloesen, Spendenbescheinigungen ausstellen und Mitgliederkennwoerter
-- zuruecksetzen. Die Einstellung in der Maske sagte das Gegenteil.
--
-- Die Wache kommt deshalb IN die Funktionen. Sie wird nicht von Hand
-- eingetippt, sondern in die lebende Quelle eingesetzt: wer sie abtippt,
-- verliert spaetere Aenderungen, die seit der ersten Migration dazugekommen
-- sind. Findet sich der Ankerpunkt nicht, bricht die Migration ab, statt
-- eine Funktion halb umzubauen.

DO $$
DECLARE
  f text;
  funktionen text[] := ARRAY[
    'decide_payment_report','jahresabschluss','kontenplan_anlegen','mark_payment_paid',
    'reset_member_password','revisionszugang_erstellen','spende_bescheinigt',
    'spende_bezahlt','treffen_vorstellung_links','zahlungen_verbuchen'];
  r record;
  v_def text; v_neu text; v_n int := 0;
  wache constant text :=
    E'\n  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die\n'
    '  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.\n'
    '  IF NOT public.darf_schreiben() THEN\n'
    '    RAISE EXCEPTION ''Der Vorstand darf in diesem Verein nichts aendern.''\n'
    '      USING ERRCODE = ''insufficient_privilege'';\n'
    '  END IF;\n';
BEGIN
  FOREACH f IN ARRAY funktionen LOOP
    FOR r IN
      SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'public' AND p.proname = f AND p.prosecdef
    LOOP
      v_def := pg_get_functiondef(r.oid);

      IF v_def ~ 'darf_schreiben' THEN
        RAISE NOTICE 'Wache steht bereits in %', f;
        CONTINUE;
      END IF;

      -- Das erste BEGIN nach dem Rumpfanfang. Nicht-gierig, damit es
      -- wirklich das erste ist und nicht irgendeines weiter unten.
      v_neu := regexp_replace(v_def, '(AS \$[a-zA-Z_]*\$.*?\mBEGIN\M)',
                              '\1' || wache, 'is');

      IF v_neu = v_def THEN
        RAISE EXCEPTION 'Kein BEGIN in % gefunden -- die Wache waere nicht gesetzt worden.', f;
      END IF;

      EXECUTE v_neu;
      v_n := v_n + 1;
    END LOOP;
  END LOOP;
  RAISE NOTICE '% Funktionen mit der Wache versehen', v_n;
END $$;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_fehlt text; v_doppelt text; v_n int;
BEGIN
  -- 1. In jeder der zehn muss die Wache genau einmal stehen.
  SELECT string_agg(p.proname, ', ') INTO v_fehlt
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname='public' AND p.prosecdef
     AND p.proname = ANY (ARRAY['decide_payment_report','jahresabschluss','kontenplan_anlegen',
         'mark_payment_paid','reset_member_password','revisionszugang_erstellen',
         'spende_bescheinigt','spende_bezahlt','treffen_vorstellung_links','zahlungen_verbuchen'])
     AND p.prosrc !~ 'darf_schreiben';
  IF v_fehlt IS NOT NULL THEN
    RAISE EXCEPTION 'Ohne Wache geblieben: %', v_fehlt;
  END IF;

  SELECT string_agg(p.proname, ', ') INTO v_doppelt
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname='public' AND p.prosecdef
     AND (length(p.prosrc) - length(replace(p.prosrc, 'darf_schreiben', ''))) / 14 > 1;
  IF v_doppelt IS NOT NULL THEN
    RAISE EXCEPTION 'Wache mehrfach eingesetzt in: %', v_doppelt;
  END IF;

  -- 2. Die Funktionen muessen noch aufrufbar sein -- eine kaputte Funktion
  --    waere schlimmer als eine ungeschuetzte.
  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='mark_payment_paid' AND p.prosecdef;
  IF v_n <> 1 THEN RAISE EXCEPTION 'mark_payment_paid ist verschwunden.'; END IF;

  -- 3. Keine der zehn darf anon ausfuehren duerfen.
  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public'
     AND p.proname = ANY (ARRAY['decide_payment_report','jahresabschluss','kontenplan_anlegen',
         'mark_payment_paid','reset_member_password','revisionszugang_erstellen',
         'spende_bescheinigt','spende_bezahlt','treffen_vorstellung_links','zahlungen_verbuchen'])
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_n > 0 THEN RAISE EXCEPTION '% dieser Funktionen sind fuer anon ausfuehrbar.', v_n; END IF;

  RAISE NOTICE 'Der Entzug gilt jetzt auch in den Funktionen.';
END $$;
