-- Briefe nur an vollstaendige Schweizer Adressen.
--
-- Gemessen am 16.11.2026 (Koretini, offene Rechnungen auf "per Post"):
-- 31 Rechnungen an Adressen im Ausland, eine davon bereits bei Pingen
-- aufgegeben (Wels, Oesterreich); 23 ohne Land oder mit unvollstaendiger
-- Adresse. post_einreihen pruefte die Anschrift nicht und setzte bei
-- fehlendem Namen "Unbekannt" ein. Pingen stellt nur in der Schweiz zu.
--
-- Dieselbe Regel steht in lib/rechnungsregeln.ts (postTauglich) fuer die
-- Oberflaeche; hier ist die Stelle, an der sie nicht umgangen werden kann.

CREATE OR REPLACE FUNCTION public.post_anschrift_mangel(p_payment text)
RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r record; u record;
  v_land text; v_name text; v_strasse text; v_plz text; v_ort text;
BEGIN
  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN RETURN 'Diese Rechnung gibt es nicht.'; END IF;
  SELECT * INTO u FROM public.users WHERE id = r."userId";
  IF FOUND THEN
    v_land := u.country; v_name := u."displayName";
    v_strasse := coalesce(nullif(btrim(coalesce(u.address,'')),''), u.street);
    v_plz := u.zip; v_ort := u.city;
  ELSE
    v_land := r."customRecipient"->>'country'; v_name := r."customRecipient"->>'name';
    v_strasse := coalesce(nullif(btrim(coalesce(r."customRecipient"->>'street','')),''), r."customRecipient"->>'address');
    v_plz := r."customRecipient"->>'zip'; v_ort := r."customRecipient"->>'city';
  END IF;

  IF coalesce(btrim(v_land),'') = '' THEN
    RETURN 'Beim Empfänger ist kein Land eingetragen. Ein Brief geht nur an eine Adresse, die ausdrücklich in der Schweiz liegt.';
  END IF;
  IF lower(btrim(v_land)) NOT IN ('schweiz','switzerland','suisse','svizzera','zvicer','zvicër','ch') THEN
    RETURN 'Die Adresse liegt im Ausland (' || btrim(v_land) || '). Der Briefversand stellt nur in der Schweiz zu.';
  END IF;
  IF coalesce(btrim(v_name),'') = '' THEN RETURN 'Der Name des Empfängers fehlt.'; END IF;
  IF coalesce(v_strasse,'') !~ '[[:alpha:]]' THEN RETURN 'Strasse und Hausnummer fehlen.'; END IF;
  IF coalesce(btrim(v_plz),'') !~ '^[1-9][0-9]{3}$' THEN
    RETURN 'Die Postleitzahl ist keine Schweizer Postleitzahl (vier Ziffern).';
  END IF;
  IF coalesce(btrim(v_ort),'') = '' THEN RETURN 'Der Ort fehlt.'; END IF;
  RETURN NULL;
END $$;

REVOKE ALL ON FUNCTION public.post_anschrift_mangel(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_anschrift_mangel(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.post_einreihen(p_payment text, p_dateiname text, p_pdf text, p_produkt text DEFAULT 'cheap'::text, p_farbe text DEFAULT 'grayscale'::text, p_duplex boolean DEFAULT true, p_adresslage text DEFAULT 'left'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  r record; m record; v_id uuid; v_name text; v_vorhanden record; v_mangel text;
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

  -- Nur eine vollstaendige Schweizer Anschrift (post_anschrift_mangel).
  -- Frueher ging hier alles durch; fehlte der Name, stand "Unbekannt" auf
  -- dem Brief.
  v_mangel := public.post_anschrift_mangel(p_payment);
  IF v_mangel IS NOT NULL THEN
    RETURN jsonb_build_object('eingereiht', false, 'grund', v_mangel);
  END IF;
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

-- Selbstpruefung: dieselben Zahlen wie die Messung vom 16.11.2026.
DO $$ DECLARE z record; BEGIN
  FOR z IN
    SELECT coalesce(split_part(public.post_anschrift_mangel(p.id), ' (', 1), 'tauglich') AS befund, count(*) AS n
      FROM public.payments p
     WHERE p."tenantId" = 'koretini' AND p."deliveryMethod" IN ('POST','BOTH')
       AND p.status NOT IN ('PAID','CANCELLED','WRITTEN_OFF','DRAFT')
     GROUP BY 1 ORDER BY 2 DESC
  LOOP
    RAISE NOTICE 'Koretini, offen auf Post: % -> %', z.n, z.befund;
  END LOOP;
END $$;
