DO $$
DECLARE r record; v_s numeric; v_h numeric;
BEGIN
  SELECT sum(amount), sum(amount) INTO v_s, v_h FROM public.accounting_journal WHERE "tenantId"='koretini';
  RAISE NOTICE '=== Journal: jede Buchung hat Soll und Haben, Summe % / % ===', v_s, v_h;

  RAISE NOTICE '=== Die fuenf zusammengefuehrten Mitglieder ===';
  FOR r IN SELECT coalesce(u."displayName",'') AS dn, u.email, coalesce(u."membershipStatus",'') AS st,
                  coalesce(u.phone,'-') AS tel, coalesce(u.city,'-') AS ort,
                  coalesce(u."neighborhoodId",'-') AS nb,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id AND p.status<>'CANCELLED') AS rg,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id AND p.status='CANCELLED') AS storniert
             FROM public.users u
            WHERE u."tenantId"='koretini'
              AND lower(u."firstName")||' '||lower(u."lastName") IN
                  ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
            ORDER BY u."lastName" LOOP
    RAISE NOTICE '  % | % | % | % | % | Nb % | Rechnungen % (% storniert)',
      rpad(r.dn,18), rpad(left(r.email,30),30), rpad(r.st,7), rpad(r.tel,14),
      rpad(left(r.ort,12),12), rpad(left(r.nb,10),10), r.rg, r.storniert;
  END LOOP;

  RAISE NOTICE '=== Bleiben Namensdubletten? ===';
  FOR r IN SELECT lower(u."firstName")||' '||lower(u."lastName") AS person, count(*) AS n
             FROM public.users u WHERE u."tenantId"='koretini'
              AND coalesce(u."firstName",'')<>'' AND coalesce(u."lastName",'')<>''
            GROUP BY 1 HAVING count(*)>1 LOOP
    RAISE NOTICE '  % (%x)', r.person, r.n;
  END LOOP;

  RAISE NOTICE '=== Platzhalteradressen uebrig ===';
  FOR r IN SELECT count(*) AS n FROM public.users
            WHERE "tenantId"='koretini' AND email LIKE '%@koretini.legacy' LOOP
    RAISE NOTICE '  %', r.n;
  END LOOP;
END $$;
