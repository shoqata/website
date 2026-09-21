DO $$
DECLARE v_back text := current_user; r record; v_t text; v_frei boolean; v_n int;
BEGIN
  DELETE FROM public.donations WHERE "tenantId"='koretini';

  SET LOCAL ROLE anon;
  PERFORM set_config('request.headers',
    json_build_object('origin','https://koretini.me')::text, true);

  -- Der normale Fall
  BEGIN
    SELECT * INTO r FROM public.spende_anlegen(50, 'CHF', 'Arben Krasniqi',
      'a.k@example.ch', 'Weg 4', '8400', 'Winterthur', 'CH', 'Für die Ambulanz', 'Gesundheit', false);
    RAISE NOTICE 'anon spendet: % CHF, Referenz % (% Stellen)',
      r.betrag, r.referenz, length(r.referenz);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon spendet: ABGEWIESEN -- % ', left(SQLERRM,60);
  END;

  -- Anonym ohne Namen: erlaubt
  BEGIN
    SELECT * INTO r FROM public.spende_anlegen(20, 'CHF', NULL, NULL, NULL, NULL, NULL,
      'CH', NULL, NULL, true);
    RAISE NOTICE 'anonyme Spende: Referenz %', r.referenz;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anonyme Spende: abgewiesen -- %', left(SQLERRM,50);
  END;

  -- Nicht anonym, aber ohne Namen: abgewiesen
  BEGIN
    PERFORM public.spende_anlegen(20, 'CHF', NULL, NULL, NULL, NULL, NULL, 'CH', NULL, NULL, false);
    RAISE NOTICE 'ohne Namen, nicht anonym: DURCHGELASSEN -- Fehler';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ohne Namen, nicht anonym: abgewiesen -- richtig';
  END;

  -- Unsinnige Betraege
  FOR v_t IN SELECT unnest(ARRAY['0','-5','200000']) LOOP
    BEGIN
      PERFORM public.spende_anlegen(v_t::numeric, 'CHF', 'Probe', NULL, NULL, NULL, NULL, 'CH', NULL, NULL, false);
      RAISE NOTICE 'Betrag %: DURCHGELASSEN -- Fehler', v_t;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Betrag %: abgewiesen -- richtig', v_t;
    END;
  END LOOP;

  -- Kann anon die Tabelle direkt lesen?
  BEGIN
    SELECT count(*) INTO v_n FROM public.donations;
    RAISE NOTICE 'anon liest donations: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon liest donations: kein Zugriff -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);

  -- Referenzen eindeutig?
  SELECT count(*), count(DISTINCT referenz) INTO v_n, r.betrag FROM public.donations;
  RAISE NOTICE 'Spenden angelegt: %, verschiedene Referenzen: %', v_n, r.betrag;

  -- Modul aus -> keine Spende mehr moeglich
  SELECT alle_module_frei INTO v_frei FROM public.tenants WHERE id='koretini';
  UPDATE public.tenants SET alle_module_frei = false WHERE id='koretini';
  SET LOCAL ROLE anon;
  PERFORM set_config('request.headers',
    json_build_object('origin','https://koretini.me')::text, true);
  BEGIN
    PERFORM public.spende_anlegen(10,'CHF','Probe',NULL,NULL,NULL,NULL,'CH',NULL,NULL,false);
    RAISE NOTICE 'Modul aus: DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Modul aus: abgewiesen -- richtig';
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);
  UPDATE public.tenants SET alle_module_frei = v_frei WHERE id='koretini';

  DELETE FROM public.donations WHERE "tenantId"='koretini';
  RAISE NOTICE 'Aufgeraeumt, Freistellung = %', v_frei;
END $$;
