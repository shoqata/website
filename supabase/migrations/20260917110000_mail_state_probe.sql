-- Wohin schreibt sendEmail() heute, und existiert dort ueberhaupt etwas?
DO $$
DECLARE v bool; v_cnt int; r record;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                  WHERE table_schema='public' AND table_name='mail') INTO v;
  RAISE NOTICE 'Tabelle public.mail vorhanden: %', v;

  IF v THEN
    EXECUTE 'SELECT count(*) FROM public.mail' INTO v_cnt;
    RAISE NOTICE '  Zeilen darin: %', v_cnt;
  END IF;

  RAISE NOTICE '--- Tabellen mit "mail" im Namen ---';
  FOR r IN SELECT table_schema, table_name FROM information_schema.tables
            WHERE table_name ILIKE '%mail%' ORDER BY 1,2 LOOP
    RAISE NOTICE '  %.%', r.table_schema, r.table_name;
  END LOOP;

  RAISE NOTICE '--- hinterlegte Absenderangaben in settings ---';
  FOR r IN SELECT id, system->>'systemEmail' AS system_email,
                  payment->>'contactEmail' AS kontakt
             FROM public.settings WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  %: systemEmail=% kontakt=%', r.id, COALESCE(r.system_email,'(leer)'), COALESCE(r.kontakt,'(leer)');
  END LOOP;
END $$;
