DO $$
DECLARE r record; s text;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.tables
            WHERE table_schema='public' AND table_name IN ('fiscal_years','accounting_accounts','settings') LOOP
    s := '';
    FOR r IN SELECT column_name, data_type, is_nullable FROM information_schema.columns
              WHERE table_schema='public' AND table_name=r.table_name ORDER BY ordinal_position LOOP
      s := s || r.column_name || '(' || left(r.data_type,9) || ') ';
    END LOOP;
    RAISE NOTICE '%', s;
  END LOOP;
END $$;
