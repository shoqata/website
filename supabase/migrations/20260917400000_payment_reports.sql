-- Zahlungsmeldungen.
--
-- Die verantwortliche Person einer Nachbarschaft weiss oft als Erste, dass
-- jemand bezahlt hat -- bar an der Haustuer, per Ueberweisung, im Gespraech.
-- Sie soll das melden koennen, ohne den Stand der Rechnung selbst zu
-- veraendern. Buchen bleibt bei Vorstand und Administration.
--
-- Die Trennung steckt in den Regeln, nicht in der Benutzeroberflaeche: die
-- Betreuung hat auf payments kein Schreibrecht, und der Status einer Meldung
-- laesst sich von ihr nicht aendern. Ein veraenderter Client hilft ihr nichts.

CREATE TABLE IF NOT EXISTS public.payment_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  "paymentId"   text NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  "reportedBy"  text NOT NULL,
  method        text,
  amount        numeric,
  "paidOn"      date,
  note          text,
  status        text NOT NULL DEFAULT 'OPEN',
  "decidedBy"   text,
  "decidedAt"   timestamptz,
  "decisionNote" text,
  "createdAt"   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payment_reports_status_chk CHECK (status IN ('OPEN', 'CONFIRMED', 'REJECTED'))
);

-- Zwei offene Meldungen zur selben Rechnung waeren nur Verwirrung.
CREATE UNIQUE INDEX IF NOT EXISTS payment_reports_one_open
  ON public.payment_reports ("paymentId") WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS payment_reports_tenant_status
  ON public.payment_reports ("tenantId", status);

ALTER TABLE public.payment_reports ENABLE ROW LEVEL SECURITY;

-- Lesen: die Geschaeftsfuehrung alles im Verein, die Betreuung ihre eigenen
-- Meldungen, das Mitglied die Meldungen zu seinen eigenen Rechnungen -- wer
-- gemeldet wurde, soll das auch sehen koennen.
DROP POLICY IF EXISTS payment_reports_read ON public.payment_reports;
CREATE POLICY payment_reports_read ON public.payment_reports FOR SELECT TO authenticated
  USING (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR "reportedBy" = public.current_user_row_id()
    OR "paymentId" IN (SELECT p.id FROM public.payments p
                        WHERE p."userId" = public.current_user_row_id())
  );

-- Melden: nur zu Rechnungen von Mitgliedern der eigenen Nachbarschaft, nur im
-- eigenen Namen, nur als offene Meldung. Die Felder der Entscheidung bleiben
-- dabei zwingend leer -- sonst koennte sich eine Meldung selbst bestaetigen.
DROP POLICY IF EXISTS payment_reports_insert ON public.payment_reports;
CREATE POLICY payment_reports_insert ON public.payment_reports FOR INSERT TO authenticated
  WITH CHECK (
    "tenantId" = public.current_tenant()
    AND "reportedBy" = public.current_user_row_id()
    AND status = 'OPEN'
    AND "decidedBy" IS NULL
    AND "decidedAt" IS NULL
    AND (
      public.is_member_manager()
      OR (public.is_neighborhood_steward()
          AND "paymentId" IN (
            SELECT p.id FROM public.payments p
              JOIN public.users u ON u.id = p."userId"
             WHERE u."neighborhoodId" IN (SELECT public.my_neighborhoods())))
    )
  );

-- Entscheiden: ausschliesslich Vorstand und Administration.
DROP POLICY IF EXISTS payment_reports_decide ON public.payment_reports;
CREATE POLICY payment_reports_decide ON public.payment_reports FOR UPDATE TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
  WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS payment_reports_delete ON public.payment_reports;
CREATE POLICY payment_reports_delete ON public.payment_reports FOR DELETE TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());

REVOKE ALL ON public.payment_reports FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payment_reports TO authenticated;

-- ------------------------------------------------ Melden und entscheiden
-- Eine Meldung absetzen. Der Verein und die meldende Person werden
-- serverseitig bestimmt; der Client kann beides nicht vorgeben.
CREATE OR REPLACE FUNCTION public.report_payment_paid(
  p_payment text,
  p_method  text DEFAULT NULL,
  p_paid_on date DEFAULT NULL,
  p_note    text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_me     text := public.current_user_row_id();
  v_tenant text := public.current_tenant();
  v_betrag numeric;
  v_id     uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Die Rechnung muss fuer den Aufrufer sichtbar sein. Das entscheidet die
  -- Leseregel auf payments, nicht diese Funktion -- deshalb SECURITY INVOKER.
  SELECT p.amount INTO v_betrag FROM public.payments p WHERE p.id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht oder sie gehoert nicht zu Ihrer Nachbarschaft.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.payment_reports
    ("tenantId", "paymentId", "reportedBy", method, amount, "paidOn", note)
  VALUES (v_tenant, p_payment, v_me, p_method, v_betrag, COALESCE(p_paid_on, current_date), p_note)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

-- Ueber eine Meldung entscheiden. Nur hier wird der Stand der Rechnung
-- veraendert, und nur die Geschaeftsfuehrung kommt herein.
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
           "paidAt" = COALESCE("paidAt", COALESCE(r."paidOn"::timestamptz, now())),
           method = COALESCE(r.method, method),
           "collectedBy" = COALESCE("collectedBy", r."reportedBy")
     WHERE id = r."paymentId";
  END IF;

  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION public.report_payment_paid(text, text, date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decide_payment_report(uuid, boolean, text) TO authenticated;

-- ------------------------------------------- Verantwortliche fuer Mitglieder
-- Ein Mitglied soll wissen, an wen es sich wenden kann. Dafuer wird die
-- Leseregel auf users nicht geweitet -- sonst kaeme jeder an fremde
-- Datensaetze. Stattdessen gibt diese Funktion genau die Kontaktangaben der
-- Verantwortlichen der eigenen Nachbarschaft heraus, sonst nichts.
CREATE OR REPLACE FUNCTION public.my_neighborhood_contacts()
RETURNS TABLE (
  id text, "displayName" text, phone text, email text,
  "neighborhoodId" text, "neighborhoodName" text
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH meine AS (
    SELECT u."neighborhoodId" AS nb
      FROM public.users u
     WHERE u.id = public.current_user_row_id()
  )
  SELECT k.id, k."displayName", k.phone, k.email, n.id, n.name
    FROM public.neighborhoods n
    JOIN meine m ON m.nb = n.id
    JOIN public.users k
      ON k.id IN (
           SELECT jsonb_array_elements_text(n."contactPersonIds")
            WHERE n."contactPersonIds" IS NOT NULL
         )
      OR k.id = n."representativeId"
      OR k.id = n."managerId"
   WHERE k."tenantId" = n."tenantId"
$$;

GRANT EXECUTE ON FUNCTION public.my_neighborhood_contacts() TO authenticated;

NOTIFY pgrst, 'reload schema';
