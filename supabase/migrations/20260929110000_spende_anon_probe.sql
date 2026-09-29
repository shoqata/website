DO $$
DECLARE v_back text := current_user; r record;
BEGIN
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  BEGIN
    SELECT * INTO r FROM public.spende_anlegen(
      50, 'CHF', 'Probe Spender', 'probe@example.org',
      'Musterweg 1', '8000', 'Zürich', 'CH', NULL, 'Probe', false);
    RAISE NOTICE 'Spende ging durch: Referenz %', r.referenz;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Spende abgewiesen: %', SQLERRM;
  END;
  EXECUTE format('SET ROLE %I', v_back);

  -- Was sehen die beiden Modulpruefungen aus dieser Sicht?
  EXECUTE 'SET ROLE anon';
  RAISE NOTICE '  modul_aktiv(SPENDEN)             = %', public.modul_aktiv('SPENDEN');
  RAISE NOTICE '  modul_aktiv_oeffentlich(SPENDEN) = %', public.modul_aktiv_oeffentlich('SPENDEN');
  RAISE NOTICE '  current_tenant = % | request_tenant = %',
    coalesce(public.current_tenant(),'(keiner)'), coalesce(public.request_tenant(),'(keiner)');
  EXECUTE format('SET ROLE %I', v_back);

  DELETE FROM public.donations WHERE email='probe@example.org';
  PERFORM set_config('request.headers', NULL, false);
END $$;
