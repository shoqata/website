-- anon hatte durch die Vorgabe-Rechte Zugriff auf die Tabelle. Die
-- Zeilenregel lieferte zwar 0 Zeilen -- ein Leck war es also nicht --, aber
-- das Recht gehoert gar nicht erst erteilt.
REVOKE ALL ON public.family_links FROM anon;

-- Die beiden Abfragen laufen als SECURITY INVOKER, die Zeilenregeln auf
-- users und family_links gelten also auch fuer sie. Hier wird das
-- nachgewiesen statt angenommen -- haushalt_vorschlaege() gibt Adressen
-- zurueck, das waere die teuerste Stelle fuer einen Irrtum.
DO $$
DECLARE v_n int; v_back text := current_user;
BEGIN
  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.family_links;
    RAISE NOTICE 'anon Tabelle: % Zeilen -- sollte einen Fehler geben', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'anon Tabelle: kein Zugriff (richtig)';
  END;
  BEGIN
    SELECT count(*) INTO v_n FROM public.haushalt_vorschlaege();
    IF v_n = 0 THEN
      RAISE NOTICE 'anon Haushalte: 0 Adressen (richtig)';
    ELSE
      RAISE NOTICE 'anon Haushalte: % Adressen -- LOCH', v_n;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon Haushalte: abgewiesen (richtig)';
  END;
  BEGIN
    SELECT count(*) INTO v_n FROM public.familien_uebersicht();
    IF v_n = 0 THEN
      RAISE NOTICE 'anon Familien: 0 Personen (richtig)';
    ELSE
      RAISE NOTICE 'anon Familien: % Personen -- LOCH', v_n;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon Familien: abgewiesen (richtig)';
  END;
  EXECUTE format('SET ROLE %I', v_back);
END $$;
