DO $$
DECLARE r record; v_back text := current_user; v_erg jsonb;
BEGIN
  RAISE NOTICE '=== Stellung je Verein ===';
  FOR r IN SELECT s."tenantId", coalesce(s.system ->> 'beitraegeOeffentlich','(nicht gesetzt = AUS)') AS stellung
             FROM public.settings s WHERE s.id='system' LOOP
    RAISE NOTICE '  % -> %', rpad(r."tenantId",12), r.stellung;
  END LOOP;

  RAISE NOTICE '=== Widersprueche ===';
  FOR r IN SELECT "tenantId", count(*) FILTER (WHERE nicht_oeffentlich) AS wid, count(*) AS gesamt
             FROM public.users GROUP BY 1 LOOP
    RAISE NOTICE '  % -> % von % Mitgliedern', rpad(r."tenantId",12), r.wid, r.gesamt;
  END LOOP;

  RAISE NOTICE '=== Was ein Besucher von koretini.me heute sieht ===';
  PERFORM set_config('request.headers', json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  v_erg := public.beitragsstand_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '  %', v_erg;
END $$;
