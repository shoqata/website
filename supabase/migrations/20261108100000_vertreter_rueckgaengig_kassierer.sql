-- Nach "Rueckgaengig" stand der Vertreter weiter als Kassierer (collectedBy)
-- an der Rechnung, obwohl kein Bareingang mehr da war. Der Selbsttest der
-- vorigen Migration hat es gezeigt: PENDING/0/demo-v01.
CREATE OR REPLACE FUNCTION public.vertreter_kassieren_rueckgaengig(p_kasse uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); k public.vertreter_kasse;
BEGIN
  IF NOT public.vertreter_darf('KASSIEREN') THEN
    RAISE EXCEPTION 'Kassieren ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO k FROM public.vertreter_kasse x
   WHERE x.id = p_kasse AND x."tenantId" = v_verein AND x.person = public.current_user_row_id()
     AND x.art = 'EINNAHME';
  IF k.id IS NULL THEN
    RAISE EXCEPTION 'Diesen Eintrag gibt es in Ihrer Kasse nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF k.erfasst_am::date <> current_date THEN
    RAISE EXCEPTION 'Nur am selben Tag. Melden Sie den Fehler dem Vorstand.' USING ERRCODE = 'check_violation';
  END IF;
  DELETE FROM public.zahlungseingaenge WHERE id = k."eingangId";
  IF EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId" = k."eingangId"::text) THEN
    INSERT INTO public.accounting_journal (id, "tenantId", date, description, "debitCode", "creditCode",
           amount, "referenceId", "isSystemEntry")
    SELECT gen_random_uuid()::text, j."tenantId", current_date::text, 'Storno ' || j.description,
           j."creditCode", j."debitCode", j.amount, j."referenceId", true
      FROM public.accounting_journal j WHERE j."referenceId" = k."eingangId"::text
       AND j.description NOT LIKE 'Storno %';
  END IF;
  UPDATE public.payments p SET "collectedBy" = NULL
   WHERE p.id = k."paymentId"
     AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge z WHERE z."paymentId" = p.id AND z.weg = 'CASH');
  DELETE FROM public.vertreter_kasse WHERE id = k.id;
END $$;
