DO $$ DECLARE z text; BEGIN
  RAISE NOTICE '=== modul_aktiv, wie sie wirklich ist ===';
  FOR z IN SELECT unnest(string_to_array(prosrc, E'\n')) FROM pg_proc p
            JOIN pg_namespace n ON n.oid=p.pronamespace
           WHERE n.nspname='public' AND p.proname='modul_aktiv' LOOP
    RAISE NOTICE '%', z;
  END LOOP;
  RAISE NOTICE '=== Argumente von spende_anlegen ===';
  FOR z IN SELECT pg_get_function_identity_arguments(p.oid) FROM pg_proc p
            JOIN pg_namespace n ON n.oid=p.pronamespace
           WHERE n.nspname='public' AND p.proname='spende_anlegen' LOOP
    RAISE NOTICE '%', z;
  END LOOP;
END $$;
