-- Woraus besteht der "Community Puls" heute, und was waere aussagekraeftig?
--
-- Die Kennzahl rechnet ACTIVE / alle. Wenn nahezu jeder ACTIVE ist, steht sie
-- dauerhaft bei hundert Prozent und misst nichts. Hier die Zahlen, an denen
-- sich das entscheidet.
DO $$
DECLARE
  v_jahr int := EXTRACT(YEAR FROM current_date)::int;
  v_nb text; v_name text;
  v_ges int; v_aktiv int; v_paid int; v_open int; v_none int;
  r record;
BEGIN
  SELECT n.id, n.name INTO v_nb, v_name FROM public.neighborhoods n
   WHERE n."contactPersonIds" IS NOT NULL AND jsonb_array_length(n."contactPersonIds") > 0 LIMIT 1;

  SELECT count(*), count(*) FILTER (WHERE "membershipStatus" = 'ACTIVE')
    INTO v_ges, v_aktiv FROM public.users WHERE "neighborhoodId" = v_nb;

  SELECT
    count(*) FILTER (WHERE z = 'PAID'), count(*) FILTER (WHERE z = 'OPEN'), count(*) FILTER (WHERE z = 'NONE')
  INTO v_paid, v_open, v_none
  FROM (SELECT CASE
          WHEN EXISTS (SELECT 1 FROM public.payments p WHERE p."userId"=u.id AND p."billingYear"::int=v_jahr AND p.status='PAID') THEN 'PAID'
          WHEN EXISTS (SELECT 1 FROM public.payments p WHERE p."userId"=u.id AND p."billingYear"::int=v_jahr) THEN 'OPEN'
          ELSE 'NONE' END AS z
        FROM public.users u WHERE u."neighborhoodId" = v_nb) x;

  RAISE NOTICE '=== % ===', v_name;
  RAISE NOTICE 'Mitglieder %, davon ACTIVE %  -> heutiger Puls %%%',
    v_ges, v_aktiv, round(v_aktiv::numeric * 100 / nullif(v_ges,0));
  RAISE NOTICE 'Beitrag %: bezahlt %, offen %, nicht verrechnet %  -> Zahlquote %%%',
    v_jahr, v_paid, v_open, v_none, round(v_paid::numeric * 100 / nullif(v_ges,0));

  RAISE NOTICE '=== Zum Vergleich alle Nachbarschaften ===';
  FOR r IN
    SELECT n.name,
           count(u.*) AS ges,
           count(*) FILTER (WHERE u."membershipStatus"='ACTIVE') AS aktiv,
           count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.payments p
                        WHERE p."userId"=u.id AND p."billingYear"::int=v_jahr AND p.status='PAID')) AS bezahlt
      FROM public.neighborhoods n JOIN public.users u ON u."neighborhoodId" = n.id
     GROUP BY n.name HAVING count(u.*) >= 5 ORDER BY count(u.*) DESC LIMIT 8
  LOOP
    RAISE NOTICE '  %: % Mitglieder, ACTIVE % (%%%), bezahlt % (%%%)',
      rpad(r.name, 30), r.ges, r.aktiv, round(r.aktiv::numeric*100/r.ges),
      r.bezahlt, round(r.bezahlt::numeric*100/r.ges);
  END LOOP;
END $$;
