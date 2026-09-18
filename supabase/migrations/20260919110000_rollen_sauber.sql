-- Saubere Wiederholung: vorher leeren, damit keine Reste mitzaehlen.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text;
        v_lagje text; v_a text; v_b text; v_c text; v_d text; v_n int;
BEGIN
  DELETE FROM public.family_links;

  SELECT u."authUserId", u.email, u.id INTO v_uid, v_mail, v_id FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.neighborhoods n
                  WHERE n."contactPersonIds" @> to_jsonb(u.id)
                     OR n."representativeId" = u.id OR n."managerId" = u.id) LIMIT 1;
  SELECT n.id INTO v_lagje FROM public.neighborhoods n
   WHERE n."contactPersonIds" @> to_jsonb(v_id) OR n."representativeId" = v_id
      OR n."managerId" = v_id LIMIT 1;
  SELECT id INTO v_a FROM public.users WHERE "neighborhoodId"=v_lagje ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "neighborhoodId"=v_lagje AND id<>v_a ORDER BY id LIMIT 1;
  SELECT id INTO v_c FROM public.users WHERE "neighborhoodId"<>v_lagje AND "neighborhoodId" IS NOT NULL ORDER BY id LIMIT 1;
  SELECT id INTO v_d FROM public.users WHERE "neighborhoodId"<>v_lagje AND "neighborhoodId" IS NOT NULL AND id<>v_c ORDER BY id LIMIT 1;

  INSERT INTO public.family_links ("tenantId", von, nach, art)
  VALUES ('koretini', v_a, v_b, 'ELTERNTEIL'), ('koretini', v_c, v_d, 'ELTERNTEIL');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE 'Verantwortliche Person: % von 2 -- %', v_n, CASE WHEN v_n=1 THEN 'richtig' ELSE 'FEHLER' END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.neighborhoods n
                      WHERE n."contactPersonIds" @> to_jsonb(u.id)
                         OR n."representativeId"=u.id OR n."managerId"=u.id) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE 'Gewoehnliches Mitglied: % von 2 -- %', v_n, CASE WHEN v_n=0 THEN 'richtig' ELSE 'FEHLER' END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.family_links;
  RAISE NOTICE 'Verwaltung: % von 2 -- %', v_n, CASE WHEN v_n=2 THEN 'richtig' ELSE 'FEHLER' END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.family_links;
  RAISE NOTICE 'Proben entfernt.';
END $$;
