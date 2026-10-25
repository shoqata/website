-- Uebergabe beim Vorstandswechsel: festgehalten, wer wem welche Rolle
-- uebergeben hat, mit Notiz. Die Rollen selbst setzt rolle_setzen() (nur
-- Vereinsadministration); hier steht die Geschichte dazu.
CREATE TABLE IF NOT EXISTS public.uebergaben (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  von         text REFERENCES public.users(id) ON DELETE SET NULL,
  von_name    text,
  an          text REFERENCES public.users(id) ON DELETE SET NULL,
  an_name     text,
  rolle       text NOT NULL,
  amt         text,
  notiz       text,
  schritte    jsonb NOT NULL DEFAULT '{}',
  erfasst_am  timestamptz NOT NULL DEFAULT now(),
  erfasst_von text
);
ALTER TABLE public.uebergaben ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.uebergaben FROM anon, authenticated, public;
GRANT SELECT ON public.uebergaben TO authenticated;
CREATE POLICY uebergaben_lesen ON public.uebergaben FOR SELECT TO authenticated
  USING ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()));

CREATE OR REPLACE FUNCTION public.uebergabe_festhalten(p_von text, p_an text, p_rolle text, p_amt text, p_notiz text, p_schritte jsonb)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id uuid; v_verein text := public.current_tenant();
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Uebergaben haelt die Vereinsadministration fest.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_an AND "tenantId" = v_verein)
     OR (p_von IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_von AND "tenantId" = v_verein)) THEN
    RAISE EXCEPTION 'Diese Person gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  INSERT INTO public.uebergaben ("tenantId", von, von_name, an, an_name, rolle, amt, notiz, schritte, erfasst_von)
  SELECT v_verein, p_von, (SELECT "displayName" FROM public.users WHERE id = p_von),
         p_an, (SELECT "displayName" FROM public.users WHERE id = p_an),
         p_rolle, nullif(btrim(coalesce(p_amt,'')),''), nullif(btrim(coalesce(p_notiz,'')),''), coalesce(p_schritte,'{}'),
         (SELECT "displayName" FROM public.users WHERE id = public.current_user_row_id())
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.uebergabe_festhalten(text, text, text, text, text, jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.uebergabe_festhalten(text, text, text, text, text, jsonb) TO authenticated;
NOTIFY pgrst, 'reload schema';
