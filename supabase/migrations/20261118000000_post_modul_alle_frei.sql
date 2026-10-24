-- Briefversand: "alle Module frei" gilt auch hier.
--
-- post_kontingent_stand() und post_kontingent_kaufen() fragten das Modul
-- direkt in tenant_modules ab. Ein Verein mit alle_module_frei (Koretini)
-- hat dort keine Zeile -- er galt als "Modul nicht aktiv" und haette nie
-- Guthaben kaufen koennen. Jetzt dieselbe Regel wie modul_aktiv(): frei
-- fuer den Verein, oder eine Zeile AN/TESTPHASE.

CREATE OR REPLACE FUNCTION public.post_modul_an(p_verein text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce((SELECT t.alle_module_frei FROM public.tenants t WHERE t.id = p_verein), false)
      OR EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = p_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')
                    AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date));
$$;
REVOKE ALL ON FUNCTION public.post_modul_an(text) FROM public, anon, authenticated;

DO $$
DECLARE f text; v_def text; v_neu text; v_n int;
BEGIN
  FOREACH f IN ARRAY ARRAY['post_kontingent_stand', 'post_kontingent_kaufen'] LOOP
    SELECT pg_get_functiondef(p.oid) INTO v_def FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.proname = f;
    v_neu := regexp_replace(v_def,
      'EXISTS \(SELECT 1 FROM public\.tenant_modules tm\s+WHERE tm\."tenantId" = v_verein AND tm\.modul = ''POSTVERSAND''\s+AND tm\.zustand IN \(''AN'',''TESTPHASE''\)\)',
      'public.post_modul_an(v_verein)', 'g');
    IF v_neu = v_def THEN RAISE EXCEPTION 'Modulpruefung in % nicht gefunden', f; END IF;
    EXECUTE v_neu;
  END LOOP;
END $$;

-- Selbsttest: Koretini (alle frei) gilt als aktiv.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.tenants WHERE id = 'koretini' AND alle_module_frei)
     AND NOT public.post_modul_an('koretini') THEN
    RAISE EXCEPTION 'Selbsttest: Koretini gilt als ohne Briefversand';
  END IF;
END $$;
