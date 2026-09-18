-- Loest der hinterlegte Befehl ueberhaupt auf? cron.schedule speichert nur
-- Text -- ein Tippfehler faellt sonst erst nachts um zehn nach auf.
DO $$
DECLARE r record; v_n int;
BEGIN
  FOR r IN SELECT n.nspname AS schema, p.proname
             FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE p.proname IN ('http_post','http_get') ORDER BY 1,2 LOOP
    RAISE NOTICE 'gefunden: %.%', r.schema, r.proname;
  END LOOP;

  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'extensions' AND p.proname = 'http_post';
  IF v_n = 0 THEN
    RAISE NOTICE 'ACHTUNG: extensions.http_post gibt es nicht -- der Auftrag liefe ins Leere.';
  ELSE
    RAISE NOTICE 'extensions.http_post vorhanden.';
  END IF;
END $$;
