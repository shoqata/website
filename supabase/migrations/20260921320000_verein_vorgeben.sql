-- Ohne Vereinsangabe gilt der eigene Verein.
--
-- Der Browser soll die Kennung weder kennen noch bestimmen muessen -- sie
-- steht ohnehin in den Anspruechen der Anmeldung, und jede Uebergabe waere
-- eine Stelle, an der sich etwas faelschen liesse.
DROP FUNCTION IF EXISTS public.modul_umschalten(text,text,text,date);
CREATE FUNCTION public.modul_umschalten(
  p_modul text, p_zustand text, p_verein text DEFAULT NULL, p_testet_bis date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_kern boolean; v_status text; v_wer text;
        v_betreiber boolean := public.is_platform_admin();
        v_eigen text := public.current_tenant();
        v_ziel text := coalesce(p_verein, public.current_tenant());
        v_bisher text;
BEGIN
  IF v_ziel IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT ist_kern, status INTO v_kern, v_status
    FROM public.modules WHERE schluessel = p_modul;
  IF v_kern IS NULL THEN RAISE EXCEPTION 'Unbekanntes Modul: %', p_modul; END IF;
  IF p_zustand NOT IN ('AN','AUS','TESTPHASE','GESPERRT') THEN
    RAISE EXCEPTION 'Unbekannter Zustand: %', p_zustand;
  END IF;
  IF v_kern AND p_zustand <> 'AN' THEN
    RAISE EXCEPTION 'Kernmodule lassen sich nicht abschalten.' USING ERRCODE='check_violation';
  END IF;

  SELECT zustand INTO v_bisher FROM public.tenant_modules
   WHERE "tenantId" = v_ziel AND modul = p_modul;

  IF NOT v_betreiber THEN
    IF v_ziel IS DISTINCT FROM v_eigen THEN
      RAISE EXCEPTION 'Nur der eigene Verein.' USING ERRCODE='insufficient_privilege';
    END IF;
    IF public.app_role() NOT IN ('SUPER_ADMIN','ADMIN') THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf Module buchen.'
        USING ERRCODE='insufficient_privilege';
    END IF;
    IF p_zustand = 'GESPERRT' OR v_bisher = 'GESPERRT' THEN
      RAISE EXCEPTION 'Dieses Modul ist gesperrt. Bitte wenden Sie sich an den Betreiber.'
        USING ERRCODE='insufficient_privilege';
    END IF;
    IF p_zustand = 'TESTPHASE' THEN
      RAISE EXCEPTION 'Eine Testphase vergibt der Betreiber.' USING ERRCODE='insufficient_privilege';
    END IF;
    IF v_status = 'EINGESTELLT' THEN
      RAISE EXCEPTION 'Dieses Modul ist noch nicht verfuegbar.' USING ERRCODE='check_violation';
    END IF;
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand, testet_bis, seit, geaendert_von)
  VALUES (v_ziel, p_modul, p_zustand,
          CASE WHEN v_betreiber THEN p_testet_bis ELSE NULL END, now(), v_wer)
  ON CONFLICT ("tenantId", modul) DO UPDATE SET
    zustand = excluded.zustand,
    testet_bis = CASE WHEN v_betreiber THEN excluded.testet_bis
                      ELSE public.tenant_modules.testet_bis END,
    seit = now(), geaendert_von = excluded.geaendert_von;

  RETURN p_modul || ' -> ' || p_zustand;
END $$;

REVOKE ALL ON FUNCTION public.modul_umschalten(text,text,text,date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.modul_umschalten(text,text,text,date) TO authenticated;
