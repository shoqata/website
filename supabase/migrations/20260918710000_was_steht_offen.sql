-- Restliche offene Punkte, jetzt mit der richtigen Spalte
-- (membershipStatus, nicht status).
DO $$
DECLARE v_n int; r record;
BEGIN
  FOR r IN SELECT "membershipStatus" AS s, count(*) AS n FROM public.users
            GROUP BY 1 ORDER BY 2 DESC LOOP
    RAISE NOTICE '   Mitgliedsstatus % : %', rpad(coalesce(r.s,'(leer)'),12), r.n;
  END LOOP;

  SELECT count(*) INTO v_n FROM (
    SELECT lower(btrim("displayName")) FROM public.users
     WHERE "displayName" IS NOT NULL
       AND coalesce("membershipStatus",'') NOT IN ('REMOVED','DELETED','INACTIVE')
     GROUP BY 1 HAVING count(*) > 1) x;
  RAISE NOTICE '6) Namen, die mehrfach vorkommen (ohne entfernte): %', v_n;

  SELECT count(*) INTO v_n FROM public.users WHERE birthdate IS NULL OR btrim(birthdate)='';
  RAISE NOTICE '7) Ohne Geburtsdatum: % von %', v_n, (SELECT count(*) FROM public.users);
END $$;
