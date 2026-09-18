-- Was ist an Familienangaben ueberhaupt vorhanden?
DO $$
DECLARE v_n int; v_g int; r record;
BEGIN
  SELECT count(*) INTO v_g FROM public.users;
  SELECT count(*) INTO v_n FROM public.users WHERE coalesce(btrim("familyId"),'') <> '';
  RAISE NOTICE 'Mit familyId: % von %', v_n, v_g;

  SELECT count(*) INTO v_n FROM (
    SELECT "familyId" FROM public.users WHERE coalesce(btrim("familyId"),'') <> ''
     GROUP BY 1) x;
  RAISE NOTICE 'Verschiedene Familienkennungen: %', v_n;

  FOR r IN SELECT "familyId", count(*) AS n,
                  string_agg("displayName", ', ' ORDER BY "displayName") AS wer
             FROM public.users WHERE coalesce(btrim("familyId"),'') <> ''
            GROUP BY 1 ORDER BY 2 DESC LIMIT 6 LOOP
    RAISE NOTICE '  Familie % (%): %', r."familyId", r.n, left(r.wer, 80);
  END LOOP;

  -- Woraus liesse sich sonst etwas ableiten?
  SELECT count(*) INTO v_n FROM public.users WHERE coalesce(btrim("lastName"),'') <> '';
  RAISE NOTICE 'Mit Nachname: % von %', v_n, v_g;

  SELECT count(*) INTO v_n FROM (
    SELECT lower(btrim("lastName")) AS n, "neighborhoodId"
      FROM public.users WHERE coalesce(btrim("lastName"),'') <> ''
     GROUP BY 1,2 HAVING count(*) > 1) x;
  RAISE NOTICE 'Nachname+Nachbarschaft mehrfach (moegliche Haushalte): %', v_n;

  SELECT count(*) INTO v_n FROM (
    SELECT btrim(street), btrim(zip) FROM public.users
     WHERE coalesce(btrim(street),'') <> '' AND coalesce(btrim(zip),'') <> ''
     GROUP BY 1,2 HAVING count(*) > 1) x;
  RAISE NOTICE 'Gleiche Adresse mehrfach (echte Haushalte): %', v_n;

  -- Gibt es schon irgendeine Beziehungstabelle?
  SELECT count(*) INTO v_n FROM information_schema.tables
   WHERE table_schema='public' AND (table_name ILIKE '%famil%' OR table_name ILIKE '%relation%');
  RAISE NOTICE 'Vorhandene Beziehungstabellen: %', v_n;
END $$;
