DO $$
DECLARE r record; v text := '';
BEGIN
  FOR r IN SELECT column_name, data_type, is_nullable FROM information_schema.columns
            WHERE table_schema='public' AND table_name='tenants' ORDER BY ordinal_position LOOP
    v := v || r.column_name || ' (' || r.data_type || ') ';
  END LOOP;
  RAISE NOTICE 'Spalten von tenants: %', v;
END $$;
