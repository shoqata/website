DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Die sechs Zeilen mit Zusatz ===';
  FOR r IN SELECT u.id, u.email, coalesce(u."displayName",'') AS dn,
                  coalesce(u."firstName",'') AS vn, coalesce(u."lastName",'') AS nn,
                  coalesce(u.role,'MEMBER') AS rolle, coalesce(u."membershipStatus",'') AS st,
                  u."joinedAt", (u."authUserId" IS NOT NULL) AS konto,
                  coalesce(u.phone,'') AS tel
             FROM public.users u WHERE u.email ~ '_[A-Za-z0-9]{4,6}@' ORDER BY u."lastName", u."firstName" LOOP
    RAISE NOTICE '% | % | % % | dn=% | % | % | Konto=% | Tel=% | seit %',
      left(r.id,8), rpad(r.email,34), rpad(r.vn,12), rpad(r.nn,14), rpad(r.dn,24),
      rpad(r.rolle,20), rpad(r.st,10), r.konto, rpad(r.tel,16), r."joinedAt";
  END LOOP;
END $$;
