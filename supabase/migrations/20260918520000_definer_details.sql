DO $$
DECLARE r record; z text;
BEGIN
  FOR r IN SELECT p.proname, p.prosrc,
                  array_to_string(ARRAY(SELECT g.grantee FROM information_schema.role_routine_grants g
                                         WHERE g.routine_name = p.proname
                                           AND g.grantee IN ('anon','authenticated')), ',') AS wer
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.prosecdef
              AND p.proname IN ('book_payment_entries','queue_birthday_greetings','set_registration_tenant')
            ORDER BY p.proname LOOP
    RAISE NOTICE '--- % (ausfuehrbar fuer: %) ---', r.proname, coalesce(nullif(r.wer,''), 'niemand direkt');
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', left(z, 120); END IF;
    END LOOP;
  END LOOP;
END $$;
