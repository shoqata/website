DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Wo liegen die http-Funktionen wirklich? ===';
  FOR r IN SELECT n.nspname||'.'||p.proname AS f,
                  pg_get_function_identity_arguments(p.oid) AS args
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE p.proname IN ('http_post','http_get') ORDER BY 1 LOOP
    RAISE NOTICE '  %(%)', r.f, left(r.args,110);
  END LOOP;

  RAISE NOTICE '=== Der Befehl des Postausgang-Auftrags ===';
  FOR r IN SELECT command FROM cron.job WHERE jobname='postausgang_leeren' LOOP
    RAISE NOTICE '%', r.command;
  END LOOP;
END $$;
