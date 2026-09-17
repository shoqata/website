-- Was steht fuer einen taeglichen Lauf zur Verfuegung?
DO $$
DECLARE r record; v text := '';
BEGIN
  RAISE NOTICE '=== Installierte Erweiterungen ===';
  FOR r IN SELECT extname FROM pg_extension ORDER BY extname LOOP
    v := v || r.extname || ' ';
  END LOOP;
  RAISE NOTICE '  %', v;

  v := '';
  RAISE NOTICE '=== Verfuegbar, aber nicht installiert (Auswahl) ===';
  FOR r IN SELECT name, default_version FROM pg_available_extensions
            WHERE name IN ('pg_cron','pg_net','http') ORDER BY name LOOP
    v := v || r.name || ' (' || r.default_version || ') ';
  END LOOP;
  RAISE NOTICE '  %', coalesce(nullif(v,''), 'keine davon');
END $$;
