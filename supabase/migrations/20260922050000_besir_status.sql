-- Eine Rechnung stand auf offen, obwohl der Zahlungseingang gebucht ist.
--
-- Gemessen: INV-1802385, Besir Canaj, CHF 120. Am 13.06.2026 als Forderung
-- gebucht, am 17.09.2026 "Kasse an Forderungen" -- also bar eingenommen und
-- verbucht. Der Status der Rechnung blieb PENDING.
--
-- Das ist nicht nur eine falsche Zahl in der Offen-Liste. Die Uebertragung
-- in AdminAccounting sammelt bezahlte Rechnungen ohne bookedInJournal und
-- bucht fuer jede einen Zahlungseingang. Haette jemand den Status spaeter
-- von Hand auf PAID gesetzt, waere ein zweiter Eingang gebucht worden.
-- Deshalb wird hier beides zugleich richtiggestellt.
DO $$
DECLARE v_id text := 'iNY7Fd6QjJ1z'; v_voll text; r record; v_n int;
BEGIN
  SELECT id INTO v_voll FROM public.payments
   WHERE "tenantId"='koretini' AND "invoiceNumber"='INV-1802385';
  IF v_voll IS NULL THEN RAISE NOTICE 'Rechnung nicht gefunden.'; RETURN; END IF;

  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "referenceId"=v_voll AND "creditCode"='1100';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'Erwartet war genau ein Zahlungseingang, gefunden %. Hier wird nichts geaendert.', v_n;
  END IF;

  UPDATE public.payments
     SET status = 'PAID',
         "paidAt" = coalesce("paidAt", (SELECT date::text FROM public.accounting_journal
                                         WHERE "referenceId"=v_voll AND "creditCode"='1100' LIMIT 1)),
         "bookedInJournal" = true,
         description = coalesce(description,'') ||
           ' -- Status am 21.09.2026 nachgezogen: Zahlungseingang war seit 17.09.2026 gebucht'
   WHERE id = v_voll;

  FOR r IN SELECT status, "paidAt", "bookedInJournal" AS gebucht, amount FROM public.payments WHERE id=v_voll LOOP
    RAISE NOTICE '  jetzt: % | bezahlt am % | gebucht=% | CHF %', r.status, r."paidAt", r.gebucht, r.amount;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.payments WHERE "tenantId"='koretini' AND status='PENDING';
  RAISE NOTICE '  offene Rechnungen jetzt: %', v_n;

  SELECT count(*) INTO v_n FROM public.payments p
   WHERE p."tenantId"='koretini' AND p.status='PAID' AND NOT coalesce(p."bookedInJournal",false)
     AND EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId"=p.id AND j."creditCode"='1100');
  RAISE NOTICE '  drohende Doppelbuchungen: %', v_n;
END $$;
