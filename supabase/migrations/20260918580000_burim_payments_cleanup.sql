-- Dreifach erfasster Mitgliederbeitrag auf eine Zahlung zurueckfuehren.
--
-- Burim Dervishi ist dreimal als Mitglied erfasst, und jede der drei Zeilen
-- traegt eine bezahlte Beitragsrechnung ueber 120 CHF. In den Buechern stehen
-- damit 360 CHF, wo einmal bezahlt wurde.
--
-- An jeder Zahlung haengen zwei Journalbuchungen: die Forderung bei
-- Rechnungsstellung und der Ausgleich beim Eingang. Sie muessen mit
-- verschwinden, sonst bleibt eine Forderung ohne Rechnung stehen und die
-- Bilanz geht nicht mehr auf.
--
-- Behalten wird INV-18024102 auf burim@dervishi.ch -- die Zeile, die kuenftig
-- die massgebliche sein soll.
DO $$
DECLARE
  v_behalten text := 'pZHE6a2GpY4bQYmrqilp';   -- INV-18024102, burim@dervishi.ch
  r record; v_zahlungen int; v_buchungen int; v_summe numeric;
BEGIN
  RAISE NOTICE '=== Vorher ===';
  FOR r IN SELECT p.id, p."invoiceNumber", p.amount, p.status, u.email,
                  (SELECT count(*) FROM public.accounting_journal j WHERE j."referenceId" = p.id) AS buchungen
             FROM public.payments p JOIN public.users u ON u.id = p."userId"
            WHERE lower(btrim(u."displayName")) = 'burim dervishi' ORDER BY p."invoiceNumber" LOOP
    RAISE NOTICE '  % | % CHF | % | % | % Buchungen',
      r."invoiceNumber", r.amount, r.status, r.email, r.buchungen;
  END LOOP;

  SELECT count(*), coalesce(sum(p.amount),0) INTO v_zahlungen, v_summe
    FROM public.payments p JOIN public.users u ON u.id = p."userId"
   WHERE lower(btrim(u."displayName")) = 'burim dervishi' AND p.status = 'PAID';
  RAISE NOTICE 'Bezahlt insgesamt: % Rechnungen, % CHF', v_zahlungen, v_summe;

  -- Kein abgeschlossenes Geschaeftsjahr im Weg? Sonst waere ein Storno noetig
  -- statt einer Loeschung.
  SELECT count(*) INTO v_buchungen FROM public.fiscal_years WHERE status = 'CLOSED';
  IF v_buchungen > 0 THEN
    RAISE EXCEPTION 'Es gibt abgeschlossene Geschaeftsjahre -- hier darf nicht geloescht werden.';
  END IF;
  RAISE NOTICE 'Kein abgeschlossenes Geschaeftsjahr -- Loeschen ist zulaessig.';

  -- Erst die Buchungen, dann die Zahlungen.
  DELETE FROM public.accounting_journal
   WHERE "referenceId" IN (
     SELECT p.id FROM public.payments p JOIN public.users u ON u.id = p."userId"
      WHERE lower(btrim(u."displayName")) = 'burim dervishi' AND p.id <> v_behalten);
  GET DIAGNOSTICS v_buchungen = ROW_COUNT;

  DELETE FROM public.payments
   WHERE id IN (
     SELECT p.id FROM public.payments p JOIN public.users u ON u.id = p."userId"
      WHERE lower(btrim(u."displayName")) = 'burim dervishi' AND p.id <> v_behalten);
  GET DIAGNOSTICS v_zahlungen = ROW_COUNT;

  RAISE NOTICE 'Entfernt: % Zahlungen und % Journalbuchungen', v_zahlungen, v_buchungen;

  RAISE NOTICE '=== Nachher ===';
  FOR r IN SELECT p."invoiceNumber", p.amount, p.status, u.email,
                  (SELECT count(*) FROM public.accounting_journal j WHERE j."referenceId" = p.id) AS buchungen
             FROM public.payments p JOIN public.users u ON u.id = p."userId"
            WHERE lower(btrim(u."displayName")) = 'burim dervishi' LOOP
    RAISE NOTICE '  % | % CHF | % | % | % Buchungen',
      r."invoiceNumber", r.amount, r.status, r.email, r.buchungen;
  END LOOP;

  -- Gegenprobe: keine Buchung ohne zugehoerige Zahlung.
  SELECT count(*) INTO v_buchungen FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  RAISE NOTICE 'Journalbuchungen ohne zugehoerige Zahlung: % -- erwartet 0', v_buchungen;

  SELECT coalesce(sum(amount),0) INTO v_summe FROM public.payments
   WHERE status = 'PAID' AND coalesce("billingYear", 2026) = 2026;
  RAISE NOTICE 'Einnahmen 2026 nach der Bereinigung: % CHF (vorher 9504)', v_summe;
END $$;
