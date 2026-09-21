DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns WHERE table_schema='public' AND table_name='modules' LOOP
    RAISE NOTICE 'Spalten: %', r.s;
  END LOOP;
  FOR r IN SELECT to_jsonb(m) AS j FROM public.modules m ORDER BY m.reihenfolge, m.schluessel LOOP
    RAISE NOTICE '%', r.j;
  END LOOP;
END $$;
