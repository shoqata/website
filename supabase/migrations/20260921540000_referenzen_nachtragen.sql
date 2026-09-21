-- Referenznummern fuer die bestehenden Rechnungen nachtragen.
--
-- Angefasst wird ausschliesslich die Spalte reference. Betrag, Zustand,
-- Zahlungsdatum, Mahnstufe und das Journal bleiben unberuehrt -- 79
-- Rechnungen sind bereits bezahlt, und an einer bezahlten Rechnung darf
-- sich buchhalterisch nichts mehr bewegen.
--
-- Auch bezahlte Rechnungen bekommen eine: die Referenz ist eine Kennung,
-- keine Zahlungsaufforderung. Wer sie rueckwirkend im Kontoauszug sucht,
-- findet sie dadurch auch dort.
--
-- Einzelne Variablen statt Datensaetze: dem vorigen Anlauf fehlten im
-- zweiten SELECT die Spaltennamen, die Pruefung brach ab und die ganze
-- Migration rollte zurueck.
DO $$
DECLARE
  a1 int; a2 int; a3 int; a4 numeric; a5 numeric; a6 int; a7 numeric; a8 int; a9 int;
  b1 int; b2 int; b3 int; b4 numeric; b5 numeric; b6 int; b7 numeric; b8 int; b9 int;
  v_n int; v_abweichungen int := 0;
BEGIN
  SELECT count(*) INTO a1 FROM public.payments;
  SELECT count(*) INTO a2 FROM public.payments WHERE status='PAID';
  SELECT count(*) INTO a3 FROM public.payments WHERE status='PENDING';
  SELECT coalesce(sum(amount),0) INTO a4 FROM public.payments;
  SELECT coalesce(sum(amount),0) INTO a5 FROM public.payments WHERE status='PAID';
  SELECT count(*) INTO a6 FROM public.accounting_journal;
  SELECT coalesce(sum(amount),0) INTO a7 FROM public.accounting_journal;
  SELECT count(*) INTO a8 FROM public.payments WHERE "paidAt" IS NOT NULL;
  SELECT coalesce(sum(coalesce("dunningLevel",0)),0) INTO a9 FROM public.payments;

  UPDATE public.payments p
     SET reference = public.referenz_fuer_rechnung(p."invoiceNumber", p."tenantId")
   WHERE coalesce(btrim(p.reference),'') = ''
     AND coalesce(btrim(p."invoiceNumber"),'') <> '';
  GET DIAGNOSTICS v_n = ROW_COUNT;

  SELECT count(*) INTO b1 FROM public.payments;
  SELECT count(*) INTO b2 FROM public.payments WHERE status='PAID';
  SELECT count(*) INTO b3 FROM public.payments WHERE status='PENDING';
  SELECT coalesce(sum(amount),0) INTO b4 FROM public.payments;
  SELECT coalesce(sum(amount),0) INTO b5 FROM public.payments WHERE status='PAID';
  SELECT count(*) INTO b6 FROM public.accounting_journal;
  SELECT coalesce(sum(amount),0) INTO b7 FROM public.accounting_journal;
  SELECT count(*) INTO b8 FROM public.payments WHERE "paidAt" IS NOT NULL;
  SELECT coalesce(sum(coalesce("dunningLevel",0)),0) INTO b9 FROM public.payments;

  RAISE NOTICE 'Referenz nachgetragen bei % Rechnungen', v_n;
  RAISE NOTICE '--- Buchhalterischer Stand, vorher / nachher ---';
  RAISE NOTICE '  Rechnungen      % / %   %', a1, b1, CASE WHEN a1=b1 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  davon bezahlt   % / %   %', a2, b2, CASE WHEN a2=b2 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  davon offen     % / %  %', a3, b3, CASE WHEN a3=b3 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  Summe        % / %   %', a4, b4, CASE WHEN a4=b4 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  Summe bezahlt % / %   %', a5, b5, CASE WHEN a5=b5 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  Journalzeilen   % / %   %', a6, b6, CASE WHEN a6=b6 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  Journalsumme % / %   %', a7, b7, CASE WHEN a7=b7 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  mit Zahldatum   % / %    %', a8, b8, CASE WHEN a8=b8 THEN 'gleich' ELSE 'ABWEICHUNG' END;
  RAISE NOTICE '  Mahnstufen      % / %    %', a9, b9, CASE WHEN a9=b9 THEN 'gleich' ELSE 'ABWEICHUNG' END;

  IF a1<>b1 OR a2<>b2 OR a3<>b3 OR a4<>b4 OR a5<>b5 OR a6<>b6 OR a7<>b7 OR a8<>b8 OR a9<>b9 THEN
    RAISE EXCEPTION 'Buchhalterischer Stand hat sich veraendert -- Aenderung wird zurueckgerollt.';
  END IF;

  RAISE NOTICE '--- Referenzen ---';
  SELECT count(*) INTO v_n FROM public.payments WHERE coalesce(btrim(reference),'')<>'';
  RAISE NOTICE '  mit Referenz: % von %', v_n, b1;
  SELECT count(*) INTO v_n FROM (
    SELECT reference FROM public.payments WHERE coalesce(btrim(reference),'')<>''
     GROUP BY 1 HAVING count(*)>1) x;
  RAISE NOTICE '  doppelte: % (soll 0)', v_n;
  IF v_n > 0 THEN RAISE EXCEPTION 'Doppelte Referenzen -- zurueckgerollt.'; END IF;
  SELECT count(*) INTO v_n FROM public.payments
   WHERE coalesce(btrim(reference),'')<>'' AND reference !~ '^RF[0-9]{2}[A-Z0-9]+$';
  RAISE NOTICE '  nicht wohlgeformt: % (soll 0)', v_n;
  IF v_n > 0 THEN RAISE EXCEPTION 'Fehlerhafte Referenzen -- zurueckgerollt.'; END IF;

  -- Und stimmen die Pruefziffern? Stichprobe ueber alle.
  SELECT count(*) INTO v_n FROM public.payments
   WHERE coalesce(btrim(reference),'')<>''
     AND substr(reference,3,2) <> public.mod97_pruefziffern(substr(reference,5));
  RAISE NOTICE '  falsche Pruefziffer: % (soll 0)', v_n;
  IF v_n > 0 THEN RAISE EXCEPTION 'Pruefziffern falsch -- zurueckgerollt.'; END IF;
END $$;
