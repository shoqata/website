-- paidAt ist in payments eine Textspalte, kein Zeitstempel.
--
-- decide_payment_report mischte sie mit now() und scheiterte deshalb beim
-- Bestaetigen: "COALESCE types text and timestamp with time zone cannot be
-- matched". Der Selbsttest hat es aufgedeckt, bevor die Funktion je benutzt
-- wurde. Statt die Spalte umzubauen -- daran haengen 324 Zeilen und die
-- Rechnungsansicht -- wird hier auf Text geschrieben, wie ueberall sonst.
CREATE OR REPLACE FUNCTION public.decide_payment_report(
  p_report  uuid,
  p_approve boolean,
  p_note    text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_me text := public.current_user_row_id();
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Meldung entscheiden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payment_reports WHERE id = p_report;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meldung nicht gefunden.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Meldung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF r.status <> 'OPEN' THEN
    RAISE EXCEPTION 'Ueber diese Meldung wurde bereits entschieden.'
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.payment_reports
     SET status = CASE WHEN p_approve THEN 'CONFIRMED' ELSE 'REJECTED' END,
         "decidedBy" = v_me, "decidedAt" = now(), "decisionNote" = p_note
   WHERE id = p_report;

  IF p_approve THEN
    UPDATE public.payments
       SET status = 'PAID',
           "paidAt" = COALESCE(NULLIF(btrim("paidAt"), ''),
                               COALESCE(r."paidOn"::text, now()::text)),
           method = COALESCE(r.method, method),
           "collectedBy" = COALESCE("collectedBy", r."reportedBy")
     WHERE id = r."paymentId";
  END IF;

  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION public.decide_payment_report(uuid, boolean, text) TO authenticated;

NOTIFY pgrst, 'reload schema';
