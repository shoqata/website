DO $$
DECLARE r record; n record;
BEGIN
  FOR n IN SELECT u.id, u.email, u."firstName" AS vn, u."lastName" AS nn
             FROM public.users u
            WHERE u.email IN ('ledion_w23EC@dervishi.ch','qazim_dIoze@dervishi.ch',
                              'valton.rexha_IzziI@gmail.com') LOOP
    RAISE NOTICE '=== % % (Zeile %) ===', n.vn, n.nn, left(n.id,8);
    FOR r IN SELECT u.id, u.email, coalesce(u.role,'MEMBER') AS rolle,
                    coalesce(u."membershipStatus",'') AS st, coalesce(u.phone,'') AS tel,
                    coalesce(u.street,'') AS str, coalesce(u.city,'') AS ort,
                    (u."authUserId" IS NOT NULL) AS konto, u."joinedAt",
                    coalesce(u."neighborhoodId",'') AS nb
               FROM public.users u
              WHERE lower(coalesce(u."firstName",'')) = lower(n.vn)
                AND lower(coalesce(u."lastName",'')) = lower(n.nn)
              ORDER BY u."joinedAt" LOOP
      RAISE NOTICE '   % | % | % | % | Tel % | %, % | Konto=% | Nb=% | seit %',
        left(r.id,8), rpad(r.email,32), rpad(r.rolle,20), rpad(r.st,9),
        rpad(r.tel,16), rpad(r.str,22), rpad(r.ort,14), r.konto, rpad(r.nb,10), r."joinedAt";
    END LOOP;
  END LOOP;
END $$;
