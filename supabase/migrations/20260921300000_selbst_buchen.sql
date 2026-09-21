-- Vereine duerfen selbst zubuchen.
--
-- Die entscheidende Grenze: AN und AUS gehoeren dem Verein, GESPERRT dem
-- Betreiber. Wer gesperrt ist, darf sich nicht selbst wieder einschalten --
-- sonst waere der Mahnlauf wirkungslos und die Sperre eine Bitte.
--
-- Kernmodule bleiben fuer alle unantastbar.
CREATE OR REPLACE FUNCTION public.modul_umschalten(
  p_verein text, p_modul text, p_zustand text, p_testet_bis date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_kern boolean; v_status text; v_wer text;
        v_betreiber boolean := public.is_platform_admin();
        v_eigen text := public.current_tenant();
        v_bisher text;
BEGIN
  SELECT ist_kern, status INTO v_kern, v_status
    FROM public.modules WHERE schluessel = p_modul;
  IF v_kern IS NULL THEN
    RAISE EXCEPTION 'Unbekanntes Modul: %', p_modul;
  END IF;
  IF p_zustand NOT IN ('AN','AUS','TESTPHASE','GESPERRT') THEN
    RAISE EXCEPTION 'Unbekannter Zustand: %', p_zustand;
  END IF;
  IF v_kern AND p_zustand <> 'AN' THEN
    RAISE EXCEPTION 'Kernmodule lassen sich nicht abschalten.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT zustand INTO v_bisher FROM public.tenant_modules
   WHERE "tenantId" = p_verein AND modul = p_modul;

  IF NOT v_betreiber THEN
    -- Nur der eigene Verein.
    IF p_verein IS DISTINCT FROM v_eigen THEN
      RAISE EXCEPTION 'Nur der eigene Verein.' USING ERRCODE = 'insufficient_privilege';
    END IF;
    -- Nur die Verwaltung des Vereins, nicht jedes Mitglied.
    IF public.app_role() NOT IN ('SUPER_ADMIN','ADMIN') THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf Module buchen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    -- GESPERRT setzt und loest nur der Betreiber.
    IF p_zustand = 'GESPERRT' OR v_bisher = 'GESPERRT' THEN
      RAISE EXCEPTION 'Dieses Modul ist gesperrt. Bitte wenden Sie sich an den Betreiber.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    -- Eine Testphase vergibt der Betreiber, nicht der Verein selbst.
    IF p_zustand = 'TESTPHASE' THEN
      RAISE EXCEPTION 'Eine Testphase vergibt der Betreiber.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    -- Was es noch nicht gibt, laesst sich nicht buchen.
    IF v_status = 'EINGESTELLT' THEN
      RAISE EXCEPTION 'Dieses Modul ist noch nicht verfuegbar.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand, testet_bis, seit, geaendert_von)
  VALUES (p_verein, p_modul, p_zustand,
          CASE WHEN v_betreiber THEN p_testet_bis ELSE NULL END, now(), v_wer)
  ON CONFLICT ("tenantId", modul) DO UPDATE SET
    zustand = excluded.zustand,
    testet_bis = CASE WHEN v_betreiber THEN excluded.testet_bis
                      ELSE public.tenant_modules.testet_bis END,
    seit = now(), geaendert_von = excluded.geaendert_von;

  RETURN p_modul || ' -> ' || p_zustand;
END $$;

GRANT EXECUTE ON FUNCTION public.modul_umschalten(text,text,text,date) TO authenticated;
