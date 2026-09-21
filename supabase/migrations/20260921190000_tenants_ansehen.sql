DO $$
DECLARE r record; s text := '';
BEGIN
  FOR r IN SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema='public' AND table_name='tenants' ORDER BY ordinal_position LOOP
    s := s || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'tenants: %', s;
  RAISE NOTICE 'Vereine: %', (SELECT count(*) FROM public.tenants);
END $$;
