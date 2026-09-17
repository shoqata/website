DO $$
DECLARE r record; v text := '';
BEGIN
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='users' ORDER BY ordinal_position LOOP
    v := v || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'Spalten von users: %', v;
  RAISE NOTICE 'firstName vorhanden: %', EXISTS(SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='firstName');
  RAISE NOTICE 'lastName vorhanden: %', EXISTS(SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='lastName');
END $$;
