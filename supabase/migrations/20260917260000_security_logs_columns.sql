-- Die Passwort-Zuruecksetzung schreibt in security_logs. Nachsehen, welche
-- Spalten es dort gibt, damit die Funktion nichts erfindet.
DO $$
DECLARE r record; v text := '';
BEGIN
  FOR r IN SELECT column_name, is_nullable FROM information_schema.columns
            WHERE table_schema='public' AND table_name='security_logs' ORDER BY ordinal_position LOOP
    v := v || r.column_name || CASE WHEN r.is_nullable='NO' THEN '!' ELSE '' END || ' ';
  END LOOP;
  RAISE NOTICE 'security_logs: %  (! = Pflichtfeld)', v;
END $$;
