-- Warum bleiben zwei Grafiken in den Statistiken leer?
-- Nicht raten, sondern nachsehen, was in den Daten steht.
DO $$
DECLARE r record; v int;
BEGIN
  SELECT count(*) INTO v FROM public.neighborhoods WHERE "tenantId"='koretini';
  RAISE NOTICE 'Nachbarschaften: %', v;

  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini' AND "neighborhoodId" IS NOT NULL;
  RAISE NOTICE 'Mitglieder mit Nachbarschaft: %', v;

  SELECT count(*) INTO v FROM public.payments WHERE "tenantId"='koretini';
  RAISE NOTICE 'Zahlungen gesamt: %', v;

  RAISE NOTICE '--- Zahlungen nach Status ---';
  FOR r IN SELECT status, count(*) AS n,
                  count(*) FILTER (WHERE timestamp IS NULL) AS ohne_zeitstempel,
                  count(*) FILTER (WHERE "billingYear" IS NULL) AS ohne_jahr
             FROM public.payments WHERE "tenantId"='koretini'
            GROUP BY status ORDER BY 2 DESC
  LOOP
    RAISE NOTICE '  % : % (ohne Zeitstempel %, ohne billingYear %)', r.status, r.n, r.ohne_zeitstempel, r.ohne_jahr;
  END LOOP;

  RAISE NOTICE '--- Jahr aus dem Zeitstempel ---';
  FOR r IN SELECT extract(year from timestamp) AS jahr, count(*) AS n
             FROM public.payments WHERE "tenantId"='koretini' GROUP BY 1 ORDER BY 1
  LOOP
    RAISE NOTICE '  %: %', r.jahr, r.n;
  END LOOP;

  RAISE NOTICE '--- billingYear ---';
  FOR r IN SELECT "billingYear" AS jahr, count(*) AS n
             FROM public.payments WHERE "tenantId"='koretini' GROUP BY 1 ORDER BY 1
  LOOP
    RAISE NOTICE '  %: %', r.jahr, r.n;
  END LOOP;

  RAISE NOTICE '--- bezahlte Zahlungen: hat userId eine Entsprechung? ---';
  SELECT count(*) INTO v FROM public.payments p
   WHERE p."tenantId"='koretini' AND p.status='PAID'
     AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = p."userId");
  RAISE NOTICE '  bezahlte mit zuordenbarem Mitglied: %', v;

  SELECT count(*) INTO v FROM public.payments p
   WHERE p."tenantId"='koretini' AND p.status='PAID'
     AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = p."userId" AND u."neighborhoodId" IS NOT NULL);
  RAISE NOTICE '  davon in einer Nachbarschaft: %', v;
END $$;
