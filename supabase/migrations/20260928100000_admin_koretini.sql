DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Wer steht als Betreiber der Plattform? ===';
  FOR r IN SELECT email FROM public.platform_admins ORDER BY 1 LOOP
    RAISE NOTICE '  %', r.email;
  END LOOP;

  RAISE NOTICE '=== Bevorrechtigte Zeilen bei koretini ===';
  FOR r IN SELECT u.email, coalesce(u.role,'MEMBER') AS rolle,
                  coalesce(u."membershipStatus",'-') AS status,
                  (u."authUserId" IS NOT NULL) AS verknuepft,
                  u."authUserId"
             FROM public.users u
            WHERE u."tenantId"='koretini'
              AND coalesce(u.role,'MEMBER') NOT IN ('MEMBER','GUEST')
            ORDER BY u.role, u.email LOOP
    RAISE NOTICE '  % | % | % | verknuepft=% | %',
      rpad(coalesce(r.email,'(ohne)'),34), rpad(r.rolle,20), rpad(r.status,9),
      r.verknuepft, coalesce(left(r."authUserId",12),'-');
  END LOOP;

  RAISE NOTICE '=== Anmeldekonten zu diesen Adressen ===';
  FOR r IN SELECT au.email, au.id::text AS uid, au.last_sign_in_at,
                  (SELECT count(*) FROM public.users u WHERE u."authUserId" = au.id::text) AS zeilen
             FROM auth.users au
            WHERE lower(au.email) LIKE '%dervishi.ch%' OR lower(au.email) LIKE '%trifti%'
            ORDER BY au.email LOOP
    RAISE NOTICE '  % | % | zuletzt % | verknuepfte users-Zeilen %',
      rpad(r.email,30), left(r.uid,12), coalesce(r.last_sign_in_at::text,'nie'), r.zeilen;
  END LOOP;
END $$;
