DO $$
DECLARE v text; r record;
BEGIN
  RAISE NOTICE 'Vereine: %', (SELECT count(*) FROM public.tenants);
  FOR r IN SELECT id, name FROM public.tenants ORDER BY id LOOP
    RAISE NOTICE '  %', r.id;
  END LOOP;
  RAISE NOTICE 'Probe-Anmeldekonten: %',
    (SELECT count(*) FROM auth.users WHERE email LIKE '%probe.example.invalid');

  -- Was gibt reset_member_password zurueck?
  SELECT prosrc INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='reset_member_password';
  FOR r IN SELECT unnest(string_to_array(v, E'\n')) AS z LOOP
    IF r.z ILIKE '%RETURN%' THEN RAISE NOTICE 'Rueckgabe: %', btrim(r.z); END IF;
  END LOOP;
END $$;
