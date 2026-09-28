DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT id, public, file_size_limit, allowed_mime_types FROM storage.buckets LOOP
    RAISE NOTICE '  % | oeffentlich=% | Grenze % | erlaubt: %',
      rpad(r.id,12), r.public, coalesce(r.file_size_limit::text,'-'),
      coalesce(array_to_string(r.allowed_mime_types, ', '), '(alle)');
  END LOOP;
END $$;
