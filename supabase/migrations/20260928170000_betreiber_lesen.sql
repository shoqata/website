DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT p.email,
                  (SELECT count(*) FROM auth.users a WHERE lower(a.email)=lower(p.email)) AS konto,
                  (SELECT max(a.last_sign_in_at)::text FROM auth.users a WHERE lower(a.email)=lower(p.email)) AS zuletzt
             FROM public.platform_admins p ORDER BY 1 LOOP
    RAISE NOTICE '  % | Anmeldekonto % | zuletzt %', rpad(r.email,26), r.konto, coalesce(r.zuletzt,'nie');
  END LOOP;
END $$;
