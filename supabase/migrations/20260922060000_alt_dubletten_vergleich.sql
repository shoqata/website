DO $$
DECLARE r record; n record;
BEGIN
  FOR n IN SELECT DISTINCT lower(u."firstName") AS vn, lower(u."lastName") AS nn
             FROM public.users u WHERE u."tenantId"='koretini'
              AND lower(u."firstName")||' '||lower(u."lastName") IN
                  ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
            ORDER BY 2,1 LOOP
    RAISE NOTICE '=== % % ===', initcap(n.vn), initcap(n.nn);
    FOR r IN SELECT u.email,
                    coalesce(u."membershipStatus",'') AS st,
                    coalesce(regexp_replace(u.phone,'[^0-9]','','g'),'') AS tel,
                    coalesce(u.street,'') AS str, coalesce(u.zip,'') AS plz, coalesce(u.city,'') AS ort,
                    coalesce(u.birthdate::text,'-') AS geb,
                    coalesce(u."neighborhoodId",'-') AS nb,
                    coalesce(u."membershipCategory",'-') AS kat,
                    u."joinedAt"::date AS seit
               FROM public.users u
              WHERE u."tenantId"='koretini'
                AND lower(coalesce(u."firstName",''))=n.vn AND lower(coalesce(u."lastName",''))=n.nn
              ORDER BY u.email LOOP
      RAISE NOTICE '   % | % | Tel % | % % % | geb % | Nb % | % | seit %',
        rpad(left(r.email,46),46), rpad(r.st,8), rpad(r.tel,14),
        rpad(left(r.str,20),20), rpad(r.plz,6), rpad(left(r.ort,14),14),
        rpad(r.geb,10), rpad(left(r.nb,22),22), rpad(r.kat,10), r.seit;
    END LOOP;
  END LOOP;
END $$;
