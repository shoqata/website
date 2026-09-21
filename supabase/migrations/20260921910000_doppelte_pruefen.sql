DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '--- Spalten der Tabelle users ---';
  FOR r IN SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='users' LOOP
    RAISE NOTICE '%', r.s;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.users
   WHERE email ~ '_[A-Za-z0-9]{4,6}@';
  RAISE NOTICE '--- Zeilen mit Zusatz im E-Mail-Namen: % ---', v_n;
END $$;
