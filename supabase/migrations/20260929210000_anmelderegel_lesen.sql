DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT policyname, cmd, roles::text AS wer,
                  coalesce(with_check::text, qual::text) AS bedingung
             FROM pg_policies WHERE schemaname='public' AND tablename='event_registrations' LOOP
    RAISE NOTICE '  % (%) fuer %', r.policyname, r.cmd, r.wer;
    RAISE NOTICE '     %', r.bedingung;
  END LOOP;
END $$;
