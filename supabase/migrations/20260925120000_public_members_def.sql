DO $$
DECLARE r record; i int := 0; z text;
BEGIN
  RAISE NOTICE '=== public_members, Zeile fuer Zeile ===';
  FOR z IN SELECT unnest(string_to_array(pg_get_viewdef('public.public_members'::regclass, true), E'\n')) LOOP
    RAISE NOTICE '  %', z;
  END LOOP;
  RAISE NOTICE '=== Wieviel gibt sie fuer anon her? ===';
  FOR r IN SELECT count(*) AS n FROM public.public_members LOOP
    RAISE NOTICE '  Zeilen insgesamt: %', r.n;
  END LOOP;
END $$;
