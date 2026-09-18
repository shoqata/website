DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT extname, extnamespace::regnamespace AS schema FROM pg_extension
            WHERE extname IN ('pg_net','pg_cron','supabase_vault','pgsodium') ORDER BY 1 LOOP
    RAISE NOTICE 'Erweiterung % in %', rpad(r.extname,16), r.schema;
  END LOOP;
END $$;
