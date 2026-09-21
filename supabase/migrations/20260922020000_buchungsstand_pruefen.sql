DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Stimmt bookedInJournal mit dem Journal ueberein? ===';
  FOR r IN SELECT
      count(*) FILTER (WHERE NOT coalesce(p."bookedInJournal",false)
        AND EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId"=p.id)) AS falsch_nein,
      count(*) FILTER (WHERE coalesce(p."bookedInJournal",false)
        AND NOT EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId"=p.id)) AS falsch_ja,
      count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId"=p.id)) AS ohne_buchung,
      count(*) AS gesamt
    FROM public.payments p WHERE p."tenantId"='koretini' LOOP
    RAISE NOTICE '  % Zahlungen: % sagen "nicht gebucht", sind aber gebucht; % umgekehrt; % ganz ohne Buchung',
      r.gesamt, r.falsch_nein, r.falsch_ja, r.ohne_buchung;
  END LOOP;

  RAISE NOTICE '=== Die fuenf Alt-Dubletten im Detail ===';
  FOR r IN SELECT coalesce(u."displayName",'') AS dn, u.email,
                  coalesce(u."membershipStatus",'') AS st,
                  p."invoiceNumber", p."billingYear", p.amount, p.status,
                  (SELECT count(*) FROM public.accounting_journal j WHERE j."referenceId"=p.id) AS buchungen
             FROM public.users u LEFT JOIN public.payments p ON p."userId"=u.id
            WHERE u."tenantId"='koretini'
              AND lower(u."firstName")||' '||lower(u."lastName") IN
                  ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
            ORDER BY u."lastName", u."firstName", u.email LOOP
    RAISE NOTICE '  % | % | % | % % % % | Buchungen %',
      rpad(r.dn,18), rpad(left(r.email,44),44), rpad(r.st,8),
      rpad(coalesce(r."invoiceNumber",'(keine)'),14), coalesce(r."billingYear"::text,'-'),
      coalesce(r.amount::text,'-'), rpad(coalesce(r.status,'-'),8), coalesce(r.buchungen,0);
  END LOOP;
END $$;
