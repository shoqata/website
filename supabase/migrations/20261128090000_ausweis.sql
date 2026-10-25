-- Mitgliederausweis: der QR-Code im Mitgliederbereich enthaelt nur die
-- Mitgliedsnummer. Was dahinter steht, sieht nur, wer pruefen darf
-- (Verwaltung, Vorstand, Vertreter) -- ein Fremder mit dem Code erfaehrt nichts.
CREATE OR REPLACE FUNCTION public.ausweis_pruefen(p_id text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE u record; v_jahr int := extract(year FROM now() AT TIME ZONE 'Europe/Zurich')::int;
BEGIN
  IF NOT (public.is_staff() OR public.is_neighborhood_steward()) THEN
    RAISE EXCEPTION 'Nur Vorstand und Vertreter koennen Ausweise pruefen.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT x.id, x."displayName", x."membershipStatus", x."joinedAt", n.name AS nb
    INTO u FROM public.users x LEFT JOIN public.neighborhoods n ON n.id = x."neighborhoodId"
   WHERE x.id = p_id AND x."tenantId" = public.current_tenant();
  IF u.id IS NULL THEN RETURN jsonb_build_object('gefunden', false); END IF;
  RETURN jsonb_build_object(
    'gefunden', true, 'name', u."displayName", 'status', coalesce(u."membershipStatus", 'ACTIVE'),
    'nachbarschaft', u.nb, 'seit', u."joinedAt", 'jahr', v_jahr,
    'bezahlt', EXISTS (SELECT 1 FROM public.payments p WHERE p."userId" = u.id AND p.status = 'PAID'
                        AND coalesce(p."billingYear", extract(year FROM p."timestamp")::int) = v_jahr));
END $$;
REVOKE ALL ON FUNCTION public.ausweis_pruefen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.ausweis_pruefen(text) TO authenticated;
NOTIFY pgrst, 'reload schema';
