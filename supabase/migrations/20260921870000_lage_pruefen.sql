DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT u."tenantId", u.email, u.role FROM public.users u
            WHERE u."authUserId" IS NULL AND coalesce(u.role,'MEMBER') NOT IN ('MEMBER','GUEST') LOOP
    RAISE NOTICE '  % | % | %', rpad(r."tenantId",14), rpad(coalesce(r.email,'(ohne)'),34), r.role;
  END LOOP;
  FOR r IN SELECT count(*) FILTER (WHERE coalesce(role,'MEMBER') IN ('MEMBER','GUEST')) AS einfach,
                  count(*) FILTER (WHERE coalesce(role,'MEMBER') NOT IN ('MEMBER','GUEST')) AS bevorrechtigt
             FROM public.users WHERE "authUserId" IS NULL AND email IS NOT NULL LOOP
    RAISE NOTICE '  ohne Konto mit E-Mail: % einfach, % bevorrechtigt', r.einfach, r.bevorrechtigt;
  END LOOP;
END $$;
