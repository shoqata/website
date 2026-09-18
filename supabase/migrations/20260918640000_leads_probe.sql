DO $$
DECLARE r record; z text;
BEGIN
  RAISE NOTICE '=== Spalten von platform_leads ===';
  FOR r IN SELECT column_name, data_type, is_nullable, coalesce(column_default,'-') AS vorgabe
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='platform_leads' ORDER BY ordinal_position LOOP
    RAISE NOTICE '  % (%)%  Vorgabe %', r.column_name, r.data_type,
      CASE WHEN r.is_nullable='NO' THEN ' Pflicht' ELSE '' END, r.vorgabe;
  END LOOP;

  RAISE NOTICE '=== Regeln ===';
  FOR r IN SELECT policyname, cmd, roles::text AS rollen FROM pg_policies
            WHERE schemaname='public' AND tablename='platform_leads' LOOP
    RAISE NOTICE '  % [%] fuer %', r.policyname, r.cmd, r.rollen;
  END LOOP;

  RAISE NOTICE '=== Bestand ===';
  RAISE NOTICE '  % Eintraege', (SELECT count(*) FROM public.platform_leads);

  RAISE NOTICE '=== Vorbild: submit_sponsor ===';
  FOR r IN SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='submit_sponsor' LOOP
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', left(btrim(z), 110); END IF;
    END LOOP;
  END LOOP;
END $$;
