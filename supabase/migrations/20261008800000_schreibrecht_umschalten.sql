-- Die Vereinsadministration schaltet das Schreibrecht des Vorstands.
--
-- Gemessen: tenants darf nur is_platform_admin() aendern -- die
-- Vereinsadministration gar nicht. Ihr die ganze Tabelle zu oeffnen,
-- waere falsch: dort stehen auch Domain, Jahresgebuehr und
-- alle_module_frei. Deshalb genau ein Weg fuer genau dieses eine Feld.
--
-- Und einer, der sich nicht selbst aushebeln laesst: BOARD ist
-- ausdruecklich ausgeschlossen. Koennte der Vorstand die Einstellung
-- umlegen, waere der Entzug eine Bitte und keine Schranke.

CREATE OR REPLACE FUNCTION public.vorstand_schreibrecht()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce((SELECT t.vorstand_schreibt FROM public.tenants t
                    WHERE t.id = public.current_tenant()), true);
$$;
REVOKE ALL ON FUNCTION public.vorstand_schreibrecht() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_schreibrecht() TO authenticated;


CREATE OR REPLACE FUNCTION public.vorstand_schreibrecht_setzen(p_an boolean)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_n int;
BEGIN
  -- Der Betreiber darf immer; im Verein nur die Administration.
  -- BOARD steht bewusst NICHT in der Liste: wer sich das Recht selbst
  -- zurueckgeben kann, hat es nie verloren.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf das Schreibrecht des Vorstands aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.tenants SET vorstand_schreibt = coalesce(p_an, true)
   WHERE id = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend sich nichts geaendert haette.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Verein % nicht gefunden.', v_verein USING ERRCODE = 'check_violation';
  END IF;

  RETURN coalesce(p_an, true);
END $$;
REVOKE ALL ON FUNCTION public.vorstand_schreibrecht_setzen(boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_schreibrecht_setzen(boolean) TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_quelle text;
BEGIN
  SELECT p.prosrc INTO v_quelle
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname='vorstand_schreibrecht_setzen';

  -- Die Wache muss da sein ...
  IF v_quelle !~ 'is_platform_admin' OR v_quelle !~ 'SUPER_ADMIN' THEN
    RAISE EXCEPTION 'Die Berechtigungspruefung fehlt in vorstand_schreibrecht_setzen.';
  END IF;
  -- ... und BOARD darf darin NICHT vorkommen. Genau dieser Fehler waere
  -- unsichtbar: alles funktionierte, nur der Entzug waere wirkungslos.
  IF v_quelle ~ '''BOARD''' THEN
    RAISE EXCEPTION 'BOARD steht in der Erlaubnisliste -- der Vorstand koennte '
                    'sich das Schreibrecht selbst zurueckgeben.';
  END IF;

  IF (SELECT count(*) FROM public.tenants WHERE vorstand_schreibt IS NOT TRUE) > 0 THEN
    RAISE EXCEPTION 'Ein Verein steht bereits auf AUS -- diese Migration aendert keine Einstellung.';
  END IF;

  RAISE NOTICE 'Umschalter bereit: Administration darf, Vorstand nicht.';
END $$;
