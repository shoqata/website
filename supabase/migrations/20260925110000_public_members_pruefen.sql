DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Definition von public_members ===';
  FOR r IN SELECT pg_get_viewdef('public.public_members'::regclass, true) AS d LOOP
    RAISE NOTICE '%', r.d;
  END LOOP;

  RAISE NOTICE '=== Zeilenschutz auf fiscal_years ===';
  FOR r IN SELECT relrowsecurity AS an, relforcerowsecurity AS erzwungen
             FROM pg_class WHERE oid='public.fiscal_years'::regclass LOOP
    RAISE NOTICE '  RLS an=% erzwungen=%', r.an, r.erzwungen;
  END LOOP;
  FOR r IN SELECT policyname, cmd, left(coalesce(qual::text,'-'),70) AS q
             FROM pg_policies WHERE schemaname='public' AND tablename='fiscal_years' LOOP
    RAISE NOTICE '  % (%): %', rpad(r.policyname,24), r.cmd, r.q;
  END LOOP;
END $$;
