DO $$
DECLARE r record;
BEGIN
  -- Die Schaltflaeche in AdminAccounting sammelt PAID-Zahlungen ohne
  -- bookedInJournal und bucht fuer jede einen Zahlungseingang
  -- (Bank/Kasse an 1100). Die Frage ist also nicht, ob ueberhaupt etwas
  -- gebucht ist -- die Rechnungsbuchung 1100 an 3000 gibt es immer --,
  -- sondern ob der Zahlungseingang schon dasteht.
  FOR r IN SELECT
      count(*) AS bezahlt,
      count(*) FILTER (WHERE NOT coalesce(p."bookedInJournal",false)) AS gilt_als_offen,
      count(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM public.accounting_journal j
         WHERE j."referenceId"=p.id AND j."creditCode"='1100')) AS mit_eingang,
      count(*) FILTER (WHERE NOT coalesce(p."bookedInJournal",false) AND EXISTS (
        SELECT 1 FROM public.accounting_journal j
         WHERE j."referenceId"=p.id AND j."creditCode"='1100')) AS gefahr
    FROM public.payments p WHERE p."tenantId"='koretini' AND p.status='PAID' LOOP
    RAISE NOTICE '  % bezahlte Rechnungen', r.bezahlt;
    RAISE NOTICE '  davon gelten als noch nicht uebertragen: %', r.gilt_als_offen;
    RAISE NOTICE '  davon haben schon einen Zahlungseingang im Journal: %', r.mit_eingang;
    RAISE NOTICE '  -> wuerden beim naechsten Uebertragen doppelt gebucht: %', r.gefahr;
  END LOOP;

  RAISE NOTICE '=== Und die offenen: haben die faelschlich einen Eingang? ===';
  FOR r IN SELECT count(*) AS n FROM public.payments p
            WHERE p."tenantId"='koretini' AND p.status='PENDING'
              AND EXISTS (SELECT 1 FROM public.accounting_journal j
                           WHERE j."referenceId"=p.id AND j."creditCode"='1100') LOOP
    RAISE NOTICE '  %', r.n;
  END LOOP;
END $$;
