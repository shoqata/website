-- Wer darf den Marktplatz sehen, wer umschalten?
DO $$
DECLARE v_back text := current_user; r record; v_n int; v_t text;
BEGIN
  FOR r IN SELECT u."authUserId" AS uid, u.email, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL
            ORDER BY 3, 2 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';

    BEGIN
      SELECT count(*) INTO v_n FROM public.marktplatz_uebersicht();
      v_t := v_n || ' Module';
    EXCEPTION WHEN OTHERS THEN v_t := 'abgewiesen'; END;

    DECLARE v_schalt text;
    BEGIN
      BEGIN
        PERFORM public.modul_umschalten('koretini','STAMMBAUM','AUS');
        v_schalt := 'DURCHGELASSEN';
      EXCEPTION WHEN OTHERS THEN v_schalt := 'abgewiesen'; END;
      RAISE NOTICE '  % (%) | sehen: % | umschalten: %',
        rpad(left(r.email,26),26), rpad(r.rolle,11), rpad(v_t,12), v_schalt;
    END;

    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END LOOP;

  -- anonym
  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.marktplatz_uebersicht();
    RAISE NOTICE '  anon: % Module -- LOCH', v_n;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  anon: abgewiesen (richtig)'; END;
  EXECUTE format('SET ROLE %I', v_back);

  -- Aufraeumen: falls jemand durchkam, den Stand zuruecksetzen
  DELETE FROM public.tenant_modules WHERE "tenantId"='koretini';
  RAISE NOTICE 'Aufgeraeumt: % Buchungen', (SELECT count(*) FROM public.tenant_modules);
END $$;
