-- Eine Spende als bezahlt setzen und verbuchen.
--
-- Die Buchung geschieht in derselben Handlung wie das Bezahltsetzen. Waere
-- es zweierlei, gaebe es unweigerlich Spenden, die als bezahlt gelten und
-- nie im Journal stehen -- genau die Sorte Rueckstand, die ich in dieser
-- Sitzung schon einmal aufraeumen musste.
--
-- Gebucht wird auf 3200 "Ertrag Spenden". Daneben steht 3400 "Spenden" --
-- eine Dublette im Kontenplan, die jemand bereinigen sollte; ich waehle
-- die benannte und lasse die andere unberuehrt.
CREATE OR REPLACE FUNCTION public.spende_bezahlt(
  p_spende uuid, p_weg text, p_datum date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE d record; v_soll text; v_datum date := coalesce(p_datum, current_date);
        v_ertrag text := '3200'; v_wer text;
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf eine Spende buchen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('SPENDEN') THEN
    RAISE EXCEPTION 'Das Spendenmodul ist nicht aktiv.' USING ERRCODE='check_violation';
  END IF;
  IF coalesce(p_weg,'') NOT IN ('QR','TWINT','PAYPAL','BAR','UEBERWEISUNG') THEN
    RAISE EXCEPTION 'Unbekannter Zahlweg: %', p_weg;
  END IF;

  SELECT * INTO d FROM public.donations WHERE id = p_spende;
  IF NOT FOUND THEN RAISE EXCEPTION 'Spende nicht gefunden.'; END IF;
  IF d."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Spende gehoert zu einem anderen Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF d.status = 'BEZAHLT' THEN
    RAISE EXCEPTION 'Diese Spende ist bereits gebucht.' USING ERRCODE='check_violation';
  END IF;

  -- Wo das Geld ankommt, haengt am Weg.
  v_soll := CASE p_weg
    WHEN 'BAR' THEN '1000'
    WHEN 'PAYPAL' THEN '1021'
    ELSE '1020' END;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  UPDATE public.donations
     SET status = 'BEZAHLT', weg = p_weg, eingegangen_am = v_datum, gebucht = true
   WHERE id = p_spende;

  INSERT INTO public.accounting_journal
    (id, "tenantId", date, description, amount, "debitCode", "creditCode",
     "referenceId", "isSystemEntry", "createdAt")
  VALUES
    (gen_random_uuid()::text, d."tenantId", v_datum::text,
     'Spende ' || coalesce(nullif(d.name,''), 'anonym')
       || CASE WHEN d.zweck IS NOT NULL THEN ' — ' || d.zweck ELSE '' END,
     d.betrag, v_soll, v_ertrag, p_spende::text, true, now());

  RETURN 'gebucht: ' || v_soll || ' / ' || v_ertrag;
END $$;

-- Bescheinigung festhalten. Das PDF entsteht im Browser wie die uebrigen
-- Belege; hier wird nur vermerkt, dass eine ausgestellt wurde -- sonst
-- laesst sich spaeter nicht sagen, wer schon eine hat.
CREATE OR REPLACE FUNCTION public.spende_bescheinigt(p_spende uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE d record;
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung.' USING ERRCODE='insufficient_privilege';
  END IF;
  SELECT * INTO d FROM public.donations WHERE id = p_spende;
  IF NOT FOUND OR d."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Spende nicht gefunden.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF d.anonym THEN
    RAISE EXCEPTION 'Eine Bescheinigung muss auf einen Namen lauten; diese Spende ist anonym.'
      USING ERRCODE='check_violation';
  END IF;
  IF d.status <> 'BEZAHLT' THEN
    RAISE EXCEPTION 'Erst bescheinigen, wenn die Zahlung eingegangen ist.'
      USING ERRCODE='check_violation';
  END IF;
  UPDATE public.donations SET bescheinigt_am = now() WHERE id = p_spende;
  RETURN 'bescheinigt';
END $$;

REVOKE ALL ON FUNCTION public.spende_bezahlt(uuid,text,date) FROM public, anon;
REVOKE ALL ON FUNCTION public.spende_bescheinigt(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.spende_bezahlt(uuid,text,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.spende_bescheinigt(uuid) TO authenticated;
