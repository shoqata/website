-- Drei Rollen, drei Erwartungen. Die vorige Probe hatte ein Mitglied
-- erwischt, das zugleich fuer eine Nachbarschaft verantwortlich ist -- die
-- Erwartung war falsch, nicht die Regel. Hier wird ausdruecklich getrennt.
DO $$
DECLARE v_back text := current_user;
        v_uid text; v_mail text; v_id text; v_n int;
        v_a text; v_b text; v_c text; v_d text; v_lagje text;
BEGIN
  -- Eine Beziehung in der Nachbarschaft der verantwortlichen Person, und
  -- eine ausserhalb.
  SELECT u."authUserId", u.email, u.id INTO v_uid, v_mail, v_id
    FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.neighborhoods n
                  WHERE n."contactPersonIds" @> to_jsonb(u.id)
                     OR n."representativeId" = u.id OR n."managerId" = u.id)
   LIMIT 1;
  SELECT n.id INTO v_lagje FROM public.neighborhoods n
   WHERE n."contactPersonIds" @> to_jsonb(v_id) OR n."representativeId" = v_id
      OR n."managerId" = v_id LIMIT 1;

  SELECT id INTO v_a FROM public.users WHERE "neighborhoodId" = v_lagje ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "neighborhoodId" = v_lagje AND id <> v_a ORDER BY id LIMIT 1;
  SELECT id INTO v_c FROM public.users WHERE "neighborhoodId" <> v_lagje AND "neighborhoodId" IS NOT NULL ORDER BY id LIMIT 1;
  SELECT id INTO v_d FROM public.users WHERE "neighborhoodId" <> v_lagje AND "neighborhoodId" IS NOT NULL AND id <> v_c ORDER BY id LIMIT 1;

  INSERT INTO public.family_links ("tenantId", von, nach, art) VALUES
    ('koretini', v_a, v_b, 'ELTERNTEIL'), ('koretini', v_c, v_d, 'ELTERNTEIL');
  RAISE NOTICE 'Zwei Proben angelegt: eine in der eigenen Nachbarschaft, eine ausserhalb.';

  -- 1. Verantwortliche Person: sieht nur die eigene.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE '1 Verantwortliche Person sieht % von 2 -- %', v_n,
    CASE WHEN v_n = 1 THEN 'richtig' ELSE 'FEHLER' END;
  BEGIN
    INSERT INTO public.family_links (von, nach, art) VALUES (v_b, v_a, 'PARTNER');
    RAISE NOTICE '1 Verantwortliche Person legt an: DURCHGELASSEN -- Fehler';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '1 Verantwortliche Person legt an: abgewiesen -- richtig';
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- 2. Gewoehnliches Mitglied ohne jede Verantwortung: sieht nichts.
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.neighborhoods n
                      WHERE n."contactPersonIds" @> to_jsonb(u.id)
                         OR n."representativeId" = u.id OR n."managerId" = u.id)
   LIMIT 1;
  IF v_uid IS NULL THEN
    RAISE NOTICE '2 Kein Mitglied ohne Verantwortung mit Konto vorhanden -- nicht pruefbar.';
  ELSE
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT count(*) INTO v_n FROM public.family_links;
    RAISE NOTICE '2 Gewoehnliches Mitglied sieht % von 2 -- %', v_n,
      CASE WHEN v_n = 0 THEN 'richtig' ELSE 'FEHLER' END;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END IF;

  -- 3. Verwaltung: sieht beide.
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE '3 Verwaltung sieht % von 2 -- %', v_n,
    CASE WHEN v_n = 2 THEN 'richtig' ELSE 'FEHLER' END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.family_links;
  RAISE NOTICE 'Proben entfernt, % bleiben.', (SELECT count(*) FROM public.family_links);
END $$;
