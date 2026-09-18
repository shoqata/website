-- Erst die Spalten, dann die Abfrage. Zweimal geraten ist einmal zu viel.
DO $$
DECLARE r record; s text := '';
BEGIN
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='accounting_journal' ORDER BY 1 LOOP
    s := s || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'accounting_journal: %', s;
  s := '';
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='settings' ORDER BY 1 LOOP
    s := s || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'settings: %', s;
END $$;
