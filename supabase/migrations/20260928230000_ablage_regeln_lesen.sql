DO $$ DECLARE r record; BEGIN
  RAISE NOTICE '=== Regeln auf storage.objects ===';
  FOR r IN SELECT policyname, cmd, roles::text AS wer,
                  left(coalesce(qual::text, with_check::text, '-'), 90) AS bedingung
             FROM pg_policies WHERE schemaname='storage' AND tablename='objects' LOOP
    RAISE NOTICE '  % | % | % | %', rpad(r.policyname,28), rpad(r.cmd,7), rpad(r.wer,22), r.bedingung;
  END LOOP;
END $$;
