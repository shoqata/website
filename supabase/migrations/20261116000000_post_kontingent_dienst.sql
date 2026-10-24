-- post_kontingent_stand() fuer den Arbeiter.
--
-- pingen-versand fragt mit dem Dienstschluessel nach dem Guthaben. Die
-- Funktion liess nur Betreiber und Vorstand zu und wies den Dienst ab --
-- der Arbeiter las daraus "0 Briefe" und gab nie einen Brief auf ("ohne
-- Kontingent"), obwohl Guthaben da war. Jetzt darf der Dienst nach jedem
-- Verein fragen; Betreiber und Vorstand wie bisher.

CREATE OR REPLACE FUNCTION public.post_kontingent_stand(p_verein text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_verein text;
  v_stand int; v_gekauft int; v_verbraucht int;
  v_preis numeric; v_waehrung text; v_modul boolean;
BEGIN
  -- Der Betreiber und der Dienst (Arbeiter) duerfen nach einem Verein
  -- fragen; ein Verein sieht nur den eigenen Stand.
  v_verein := CASE
    WHEN coalesce(auth.jwt() ->> 'role', '') = 'service_role' THEN p_verein
    WHEN public.is_platform_admin() THEN coalesce(p_verein, public.current_tenant())
    WHEN public.is_member_manager() THEN public.current_tenant()
    ELSE NULL END;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce(sum(menge), 0),
         coalesce(sum(menge) FILTER (WHERE menge > 0), 0),
         coalesce(-sum(menge) FILTER (WHERE menge < 0), 0)
    INTO v_stand, v_gekauft, v_verbraucht
    FROM public.post_kontingent WHERE "tenantId" = v_verein;

  SELECT preis_je_brief, waehrung INTO v_preis, v_waehrung
    FROM public.post_preise WHERE "tenantId" = v_verein;

  SELECT EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = v_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')) INTO v_modul;

  RETURN jsonb_build_object(
    'verein', v_verein,
    'modul_aktiv', v_modul,
    'stand', v_stand,
    'gekauft', v_gekauft,
    'verbraucht', v_verbraucht,
    'preis_je_brief', v_preis,
    'waehrung', coalesce(v_waehrung, 'CHF'),
    'kaufbar', v_preis IS NOT NULL AND v_preis > 0);
END $function$;
