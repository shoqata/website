-- Umgehen die Sichten die Zugriffsregeln der Tabellen darunter?
--
-- Eine Sicht laeuft standardmaessig mit den Rechten ihres Eigentuemers. Liegt
-- darunter eine Tabelle mit Zugriffsregeln, greifen diese dann NICHT -- wer
-- die Sicht lesen darf, sieht alles. Erst security_invoker = on dreht das um.
-- Bei fuenf Sichten im oeffentlichen Schema gehoert das geklaert.
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Sichten im Schema public ===';
  FOR r IN
    SELECT c.relname,
           coalesce((SELECT option_value FROM pg_options_to_table(c.reloptions)
                      WHERE option_name = 'security_invoker'), 'aus') AS invoker,
           pg_get_userbyid(c.relowner) AS eigentuemer
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relkind = 'v'
     ORDER BY c.relname
  LOOP
    RAISE NOTICE '  %: security_invoker = % (Eigentuemer %)', r.relname, r.invoker, r.eigentuemer;
  END LOOP;

  RAISE NOTICE '=== Worauf bauen sie auf, und wie viel geben sie preis? ===';
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='v' ORDER BY c.relname LOOP
    BEGIN
      EXECUTE format('SELECT count(*) FROM public.%I', r.relname) INTO v_n;
      RAISE NOTICE '  % enthaelt % Zeilen', r.relname, v_n;
    EXCEPTION WHEN others THEN
      RAISE NOTICE '  % nicht lesbar', r.relname;
    END;
  END LOOP;

  RAISE NOTICE '=== Spalten von public_members -- was saehe ein Fremder? ===';
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='public_members'
            ORDER BY ordinal_position LOOP
    RAISE NOTICE '  %', r.column_name;
  END LOOP;

  RAISE NOTICE '=== Definition von socialMediaPosts ===';
  FOR r IN SELECT pg_get_viewdef('public."socialMediaPosts"'::regclass, true) AS def LOOP
    RAISE NOTICE '  %', left(replace(r.def, E'\n', ' '), 300);
  END LOOP;
END $$;
