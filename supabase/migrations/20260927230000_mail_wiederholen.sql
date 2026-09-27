DO $$
DECLARE r record;
BEGIN
  -- Spaltennamen nicht raten: "fehler" gibt es nicht.
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='mail_queue' LOOP
    RAISE NOTICE 'Spalten: %', r.s;
  END LOOP;
  FOR r IN SELECT to_jsonb(q) - 'html' - 'text' AS j FROM public.mail_queue q LOOP
    RAISE NOTICE '%', left(r.j::text, 340);
  END LOOP;
END $$;
