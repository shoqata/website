DO $$ DECLARE z text; BEGIN
  FOR z IN SELECT unnest(string_to_array(prosrc, E'\n')) FROM pg_proc p
            JOIN pg_namespace n ON n.oid=p.pronamespace
           WHERE n.nspname='public' AND p.proname='current_tenant' LOOP
    RAISE NOTICE '%', z;
  END LOOP;
END $$;
