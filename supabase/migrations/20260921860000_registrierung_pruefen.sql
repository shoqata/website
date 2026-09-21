DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '--- Ausloeser auf auth.users ---';
  FOR r IN SELECT t.tgname, p.proname FROM pg_trigger t
             JOIN pg_proc p ON p.oid=t.tgfoid
             JOIN pg_class c ON c.oid=t.tgrelid
             JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='auth' AND c.relname='users' AND NOT t.tgisinternal LOOP
    RAISE NOTICE '  % -> %()', r.tgname, r.proname;
  END LOOP;

  RAISE NOTICE '--- Funktionen, die authUserId nach E-Mail verknuepfen ---';
  FOR r IN SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname IN ('public','auth')
              AND p.prosrc ILIKE '%authUserId%' AND p.prosrc ILIKE '%lower(email)%' LOOP
    RAISE NOTICE '  %()', r.proname;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.users WHERE role='ADMIN' AND "authUserId" IS NULL;
  RAISE NOTICE '--- Administratorzeilen ohne Anmeldekonto: % ---', v_n;
END $$;
