-- Zahlquote je Nachbarschaft.
--
-- Eine Rangliste nach Quote waere wertlos, wenn unten nur Nachbarschaften mit
-- ein oder zwei Mitgliedern stehen -- dort springt die Quote zwischen 0 und
-- 100 Prozent, ohne etwas auszusagen. Deshalb erst die Verteilung ansehen.
DO $$
DECLARE r record; v_jahr int := EXTRACT(YEAR FROM current_date)::int; v_n int;
BEGIN
  RAISE NOTICE 'Beitragsjahr %', v_jahr;
  RAISE NOTICE '%-32s %6s %6s %7s %10s', 'Nachbarschaft', 'Mitgl', 'zahlt', 'Quote', 'CHF';

  FOR r IN
    SELECT n.name,
           count(u.*) FILTER (WHERE u."membershipStatus" IS DISTINCT FROM 'INACTIVE') AS mitglieder,
           count(DISTINCT p."userId") FILTER (WHERE p.status = 'PAID') AS zahlend,
           coalesce(sum(p.amount) FILTER (WHERE p.status = 'PAID'), 0) AS chf
      FROM public.neighborhoods n
      LEFT JOIN public.users u
        ON u."neighborhoodId" = n.id AND u."membershipStatus" IS DISTINCT FROM 'INACTIVE'
      LEFT JOIN public.payments p
        ON p."userId" = u.id AND coalesce(p."billingYear"::int, v_jahr) = v_jahr
     GROUP BY n.name
     ORDER BY count(u.*) DESC
  LOOP
    RAISE NOTICE '%-32s %6s %6s %6s%% %10s',
      left(r.name, 32), r.mitglieder, r.zahlend,
      CASE WHEN r.mitglieder > 0
           THEN round(r.zahlend::numeric * 100 / r.mitglieder)::text ELSE '-' END,
      r.chf;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.neighborhoods n
   WHERE (SELECT count(*) FROM public.users u
           WHERE u."neighborhoodId" = n.id AND u."membershipStatus" IS DISTINCT FROM 'INACTIVE') < 5;
  RAISE NOTICE 'Nachbarschaften mit weniger als 5 Mitgliedern: % von %',
    v_n, (SELECT count(*) FROM public.neighborhoods);
END $$;
