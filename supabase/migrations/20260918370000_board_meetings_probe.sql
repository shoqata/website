-- Aufbau und Bestand der Sitzungsprotokolle.
DO $$
DECLARE r record; v text := '';
BEGIN
  RAISE NOTICE '=== Spalten von board_meetings ===';
  FOR r IN SELECT column_name, data_type, is_nullable FROM information_schema.columns
            WHERE table_schema='public' AND table_name='board_meetings' ORDER BY ordinal_position LOOP
    RAISE NOTICE '  % (%)%', r.column_name, r.data_type,
      CASE WHEN r.is_nullable='NO' THEN ' Pflicht' ELSE '' END;
  END LOOP;

  RAISE NOTICE '=== Bestand ===';
  FOR r IN SELECT * FROM public.board_meetings ORDER BY date DESC LIMIT 6 LOOP
    RAISE NOTICE '  %', left(to_jsonb(r)::text, 420);
  END LOOP;

  RAISE NOTICE '=== Regeln ===';
  FOR r IN SELECT policyname, cmd, coalesce(qual,'-') AS q FROM pg_policies
            WHERE schemaname='public' AND tablename='board_meetings' LOOP
    RAISE NOTICE '  % [%] USING %', r.policyname, r.cmd, r.q;
  END LOOP;

  RAISE NOTICE '=== Wer gilt als Vorstand? ===';
  FOR r IN SELECT role, count(*) AS n FROM public.users
            WHERE role IN ('BOARD','ADMIN','SUPER_ADMIN') GROUP BY role ORDER BY role LOOP
    RAISE NOTICE '  %: %', r.role, r.n;
  END LOOP;
END $$;
