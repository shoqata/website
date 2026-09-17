-- Was tut claim_my_profile tatsaechlich?
DO $$
DECLARE r record; z text;
BEGIN
  FOR r IN SELECT p.proname, p.prosrc, p.prosecdef FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='claim_my_profile' LOOP
    RAISE NOTICE '--- % (SECURITY DEFINER: %) ---', r.proname, r.prosecdef;
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', z; END IF;
    END LOOP;
  END LOOP;

  -- Mehrdeutige Adressen wuerden jede Zuordnung ueber die E-Mail unsicher machen.
  RAISE NOTICE '=== Mehrfach vergebene Adressen ===';
  FOR r IN SELECT lower(email) AS mail, count(*) AS n FROM public.users
            WHERE coalesce(btrim(email),'') <> '' GROUP BY 1 HAVING count(*) > 1 LIMIT 10 LOOP
    RAISE NOTICE '  % kommt % mal vor', r.mail, r.n;
  END LOOP;

  RAISE NOTICE '=== Anmeldekonten ===';
  FOR r IN SELECT count(*) AS n, (email_confirmed_at IS NOT NULL) AS bestaetigt
             FROM auth.users GROUP BY 2 LOOP
    RAISE NOTICE '  Konten %: E-Mail bestaetigt %', r.n, r.bestaetigt;
  END LOOP;

  RAISE NOTICE '=== Konto gegen Mitgliedszeile ===';
  FOR r IN SELECT au.email,
                  (SELECT count(*) FROM public.users u WHERE lower(u.email)=lower(au.email)) AS zeilen,
                  (SELECT count(*) FROM public.users u WHERE u."authUserId"=au.id::text) AS zugeordnet
             FROM auth.users au LIMIT 10 LOOP
    RAISE NOTICE '  % -> passende Zeilen %, zugeordnet %', r.email, r.zeilen, r.zugeordnet;
  END LOOP;
END $$;
