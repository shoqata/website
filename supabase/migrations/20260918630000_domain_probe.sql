-- Was entscheidet die Domain?
--
-- Die Frage ist, ob eine eigene Adresse fuer den Betreiber etwas an den
-- Rechten aendert. Entscheidend ist, woran is_platform_admin() haengt und was
-- request_tenant() aus der Domain macht.
DO $$
DECLARE r record; z text; v_n int;
BEGIN
  RAISE NOTICE '=== Hinterlegte Domains ===';
  FOR r IN SELECT d.domain, d."tenantId", t.name FROM public.tenant_domains d
             LEFT JOIN public.tenants t ON t.id = d."tenantId" ORDER BY d.domain LOOP
    RAISE NOTICE '  % -> % (%)', r.domain, r."tenantId", coalesce(r.name,'<Verein fehlt>');
  END LOOP;

  RAISE NOTICE '=== request_tenant() ===';
  FOR r IN SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='request_tenant' LOOP
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', btrim(z); END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE '=== Wo wird request_tenant() ueberhaupt herangezogen? ===';
  v_n := 0;
  FOR r IN SELECT tablename, policyname FROM pg_policies
            WHERE schemaname='public'
              AND (coalesce(qual,'') LIKE '%request_tenant%' OR coalesce(with_check,'') LIKE '%request_tenant%')
            ORDER BY tablename LOOP
    RAISE NOTICE '  %.%', r.tablename, r.policyname;
    v_n := v_n + 1;
  END LOOP;
  RAISE NOTICE '  insgesamt % Regeln -- nur dort wirkt die Domain', v_n;

  RAISE NOTICE '=== Und woran haengen die Betreiberrechte? ===';
  FOR r IN SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='is_platform_admin' LOOP
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', btrim(z); END IF;
    END LOOP;
  END LOOP;
END $$;
