DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='platform_support' LOOP
    RAISE NOTICE 'Spalten: %', r.s;
  END LOOP;
  FOR r IN SELECT count(*) AS n FROM public.platform_support LOOP
    RAISE NOTICE 'Eintraege: %', r.n;
  END LOOP;
END $$;
