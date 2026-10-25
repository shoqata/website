-- Nachbarschaft auf der Website ein- oder ausblenden, ohne den Editor zu
-- oeffnen -- in der Uebersicht der Verwaltung ein Schalter je Karte.
CREATE OR REPLACE FUNCTION public.nachbarschaft_sichtbar_setzen(p_nachbarschaft text, p_sichtbar boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL OR NOT EXISTS (SELECT 1 FROM public.neighborhoods n
       WHERE n.id = p_nachbarschaft AND n."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Diese Nachbarschaft gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_member_manager() OR p_nachbarschaft IN (SELECT id FROM public.my_neighborhoods())) THEN
    RAISE EXCEPTION 'Nur Verwaltung, Vorstand und die Vertreter dieser Nachbarschaft.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  INSERT INTO public.nachbarschaft_profil (nachbarschaft, "tenantId", sichtbar)
  VALUES (p_nachbarschaft, v_verein, coalesce(p_sichtbar, false))
  ON CONFLICT (nachbarschaft) DO UPDATE SET sichtbar = EXCLUDED.sichtbar, geaendert_am = now();
END $$;
REVOKE ALL ON FUNCTION public.nachbarschaft_sichtbar_setzen(text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nachbarschaft_sichtbar_setzen(text, boolean) TO authenticated;
NOTIFY pgrst, 'reload schema';
