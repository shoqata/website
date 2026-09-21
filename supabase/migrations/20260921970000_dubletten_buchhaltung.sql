DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Rechnungen beider Valton-Zeilen ===';
  FOR r IN SELECT u.email, coalesce(u."membershipStatus",'') AS st, p."invoiceNumber", p."billingYear",
                  p.amount, p.currency, p.status, p."dueDate"
             FROM public.users u LEFT JOIN public.payments p ON p."userId" = u.id
            WHERE lower(u."firstName")='valton' AND lower(u."lastName")='rexha'
            ORDER BY u.email, p."billingYear" LOOP
    RAISE NOTICE '  % [%] -> % / % / % % / % / faellig %',
      rpad(r.email,32), rpad(r.st,9), coalesce(r."invoiceNumber",'(keine)'),
      coalesce(r."billingYear"::text,'-'), r.amount, r.currency, r.status, r."dueDate";
  END LOOP;

  RAISE NOTICE '=== Die fuenf Alt-Dubletten: wer traegt Zahlungen? ===';
  FOR r IN SELECT u.id, u.email, coalesce(u."displayName",'') AS dn,
                  coalesce(u."membershipStatus",'') AS st, coalesce(u.role,'MEMBER') AS rolle,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id) AS zahlungen,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id AND p.status='PAID') AS bezahlt,
                  (u."authUserId" IS NOT NULL) AS konto,
                  coalesce(u."familyId",'-') AS fam
             FROM public.users u
            WHERE u."tenantId"='koretini'
              AND lower(u."firstName")||' '||lower(u."lastName") IN
                  ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
            ORDER BY u."lastName", u."firstName", u.email LOOP
    RAISE NOTICE '  % | % | % | % | Zahlungen % (davon bezahlt %) | Konto=% | Familie %',
      rpad(r.dn,20), rpad(r.email,48), rpad(r.st,9), rpad(r.rolle,8),
      r.zahlungen, r.bezahlt, r.konto, r.fam;
  END LOOP;

  RAISE NOTICE '=== Zeigen die neighborhoodId der drei ueberhaupt auf etwas? ===';
  FOR r IN SELECT count(*) AS n FROM public.neighborhoods WHERE id IN ('Gw8s5lNhST','5KwI3rPMft') LOOP
    RAISE NOTICE '  Gw8s5lNhST / 5KwI3rPMft vorhanden: %', r.n;
  END LOOP;
  FOR r IN SELECT count(DISTINCT u."neighborhoodId") AS verwiesen,
                  count(DISTINCT u."neighborhoodId") FILTER (
                    WHERE EXISTS (SELECT 1 FROM public.neighborhoods n WHERE n.id=u."neighborhoodId")) AS gueltig
             FROM public.users u WHERE u."tenantId"='koretini' AND u."neighborhoodId" IS NOT NULL LOOP
    RAISE NOTICE '  Mitglieder verweisen auf % Nachbarschaften, davon % vorhanden', r.verwiesen, r.gueltig;
  END LOOP;
END $$;
