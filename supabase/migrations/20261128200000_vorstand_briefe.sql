-- Briefversand durch den Vorstand -- freischaltbar durch die Administration.
--
-- Bisher durfte der Vorstand Briefe in der Datenbank schon aufgeben
-- (is_member_manager), hatte in seiner Ansicht aber keinen Knopf dafuer.
-- Jetzt umgekehrt sauber: die Vereinsadministration entscheidet unter
-- Rollen, ob der Vorstand Briefe ueber Pingen aufgeben darf. Standard:
-- nein -- ein Brief kostet Porto.
--
-- Dasselbe Muster wie vorstand_schreibrecht: lesen darf jeder im Verein,
-- setzen nur Administration und Betreiber, nie der Vorstand selbst.

ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS vorstand_briefe boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.vorstand_briefrecht()
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
  SELECT coalesce((SELECT t.vorstand_briefe FROM public.tenants t
                    WHERE t.id = public.current_tenant()), false);
$function$;

CREATE OR REPLACE FUNCTION public.vorstand_briefrecht_setzen(p_an boolean)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_verein text := public.current_tenant(); v_n int;
BEGIN
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf den Briefversand des Vorstands freischalten.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  UPDATE public.tenants SET vorstand_briefe = coalesce(p_an, false) WHERE id = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Verein % nicht gefunden.', v_verein USING ERRCODE = 'check_violation';
  END IF;
  RETURN coalesce(p_an, false);
END $function$;

REVOKE ALL ON FUNCTION public.vorstand_briefrecht() FROM public, anon;
REVOKE ALL ON FUNCTION public.vorstand_briefrecht_setzen(boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_briefrecht() TO authenticated;
GRANT EXECUTE ON FUNCTION public.vorstand_briefrecht_setzen(boolean) TO authenticated;

-- post_einreihen: unveraendert bis auf die Pruefung fuer den Vorstand.
CREATE OR REPLACE FUNCTION public.post_einreihen(p_payment text, p_dateiname text, p_pdf text, p_produkt text DEFAULT 'cheap'::text, p_farbe text DEFAULT 'grayscale'::text, p_duplex boolean DEFAULT true, p_adresslage text DEFAULT 'left'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  r record; m record; v_id uuid; v_name text; v_vorhanden record;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf Post aufgeben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Der Vorstand nur, wenn die Vereinsadministration es freigegeben hat
  -- (vorstand_briefrecht_setzen). Ein Brief kostet Porto -- das soll nicht
  -- jeder ausloesen koennen, der Rechnungen lesen darf.
  IF public.app_role() = 'BOARD' AND NOT public.is_platform_admin()
     AND NOT coalesce((SELECT t.vorstand_briefe FROM public.tenants t
                        WHERE t.id = public.current_tenant()), false) THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein keine Briefe aufgeben. Die Vereinsadministration kann das unter Rollen freischalten.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_pdf), '') = '' THEN
    RAISE EXCEPTION 'Ohne Dokument kein Brief.' USING ERRCODE = 'check_violation';
  END IF;

  -- Schon unterwegs? Dann nicht ein zweites Mal. Der eindeutige Index
  -- faengt es ohnehin, aber eine Meldung ist besser als ein Fehler.
  SELECT * INTO v_vorhanden FROM public.post_ausgang
   WHERE "paymentId" = p_payment AND zustand <> 'ABGEBROCHEN';
  IF FOUND THEN
    RETURN jsonb_build_object('eingereiht', false, 'zustand', v_vorhanden.zustand,
      'grund', 'Für diese Rechnung ist schon ein Brief erfasst ('
               || v_vorhanden.zustand || ').');
  END IF;

  SELECT u.* INTO m FROM public.users u WHERE u.id = r."userId";
  v_name := coalesce(
    nullif(btrim(coalesce(m."displayName", '')), ''),
    r."customRecipient" ->> 'name',
    'Unbekannt');

  INSERT INTO public.post_ausgang
    ("tenantId", "paymentId", "memberId", empfaenger, dateiname, pdf,
     produkt, farbe, duplex, adresslage)
  VALUES (r."tenantId", p_payment, m.id,
          v_name || coalesce(' · ' || nullif(btrim(coalesce(m.city,'')), ''), ''),
          left(coalesce(nullif(btrim(p_dateiname),''), 'rechnung.pdf'), 120),
          p_pdf,
          coalesce(nullif(p_produkt,''), 'cheap'),
          coalesce(nullif(p_farbe,''), 'grayscale'),
          coalesce(p_duplex, true),
          CASE WHEN lower(coalesce(p_adresslage,'')) = 'right' THEN 'right' ELSE 'left' END)
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('eingereiht', true, 'id', v_id, 'empfaenger', v_name);
END $function$;
