DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args,
                  p.prosecdef, p.prosrc
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname IN ('create_tenant','verein_einrichten') LOOP
    RAISE NOTICE '=== %(%) security_definer=% ===', r.proname, r.args, r.prosecdef;
    RAISE NOTICE '%', r.prosrc;
  END LOOP;
END $$;
