-- Geschwister und Familiennamen als angemeldeter Administrator erproben --
-- der Weg, den die Anwendung tatsaechlich nimmt.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text;
        v_a text; v_b text; v_n int; v_name text;
BEGIN
  DELETE FROM public.families; DELETE FROM public.family_links;

  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT id INTO v_a FROM public.users WHERE "tenantId"='koretini' ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "tenantId"='koretini' AND id<>v_a ORDER BY id LIMIT 1;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    INSERT INTO public.family_links (von, nach, art) VALUES (v_a, v_b, 'GESCHWISTER');
    RAISE NOTICE 'Geschwister angelegt -- richtig';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Geschwister ABGEWIESEN -- Fehler: %', left(SQLERRM, 70);
  END;

  BEGIN
    INSERT INTO public.family_links (von, nach, art) VALUES (v_b, v_a, 'GESCHWISTER');
    RAISE NOTICE 'Geschwister in Gegenrichtung angelegt -- Fehler (doppelt)';
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Gegenrichtung abgewiesen -- richtig';
  WHEN OTHERS THEN
    RAISE NOTICE 'Gegenrichtung abgewiesen (%) -- richtig', SQLSTATE;
  END;

  BEGIN
    INSERT INTO public.families (anker, name) VALUES (v_a, 'Familie Probe');
    RAISE NOTICE 'Familie benannt -- richtig';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Benennen ABGEWIESEN -- Fehler: %', left(SQLERRM, 70);
  END;

  SELECT count(*), max(familienname) INTO v_n, v_name
    FROM public.familien_uebersicht() WHERE familienname IS NOT NULL;
  RAISE NOTICE 'Uebersicht meldet Namen "%" bei % Personen -- %',
    coalesce(v_name,'(keiner)'), v_n, CASE WHEN v_n = 2 THEN 'richtig' ELSE 'FEHLER' END;

  SELECT count(*) INTO v_n FROM public.familien_uebersicht()
   WHERE person = v_a AND jsonb_array_length(geschwister) = 1;
  RAISE NOTICE 'Geschwister erscheint in der Uebersicht: % -- %', v_n,
    CASE WHEN v_n = 1 THEN 'richtig' ELSE 'FEHLER' END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.families; DELETE FROM public.family_links;
  RAISE NOTICE 'Proben entfernt.';
END $$;
