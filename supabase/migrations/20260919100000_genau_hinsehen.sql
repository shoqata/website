DO $$
DECLARE v_back text := current_user; r record;
        v_uid text; v_mail text; v_id text; v_lagje text; v_n int;
        v_a text; v_b text; v_c text; v_d text;
BEGIN
  RAISE NOTICE 'Zeilen zu Beginn: %', (SELECT count(*) FROM public.family_links);

  SELECT u."authUserId", u.email, u.id INTO v_uid, v_mail, v_id FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.neighborhoods n
                  WHERE n."contactPersonIds" @> to_jsonb(u.id)
                     OR n."representativeId" = u.id OR n."managerId" = u.id) LIMIT 1;
  SELECT n.id INTO v_lagje FROM public.neighborhoods n
   WHERE n."contactPersonIds" @> to_jsonb(v_id) OR n."representativeId" = v_id
      OR n."managerId" = v_id LIMIT 1;
  RAISE NOTICE 'Verantwortliche Person % fuer Nachbarschaft %', v_mail, v_lagje;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  FOR r IN SELECT public.my_neighborhoods() AS n LOOP
    RAISE NOTICE '  my_neighborhoods liefert: %', r.n;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT id INTO v_a FROM public.users WHERE "neighborhoodId" = v_lagje ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "neighborhoodId" = v_lagje AND id <> v_a ORDER BY id LIMIT 1;
  SELECT id INTO v_c FROM public.users WHERE "neighborhoodId" <> v_lagje AND "neighborhoodId" IS NOT NULL ORDER BY id LIMIT 1;
  SELECT id INTO v_d FROM public.users WHERE "neighborhoodId" <> v_lagje AND "neighborhoodId" IS NOT NULL AND id <> v_c ORDER BY id LIMIT 1;
  RAISE NOTICE 'innen: %/% (Nachbarschaft %/%)', left(v_a,6), left(v_b,6),
    (SELECT "neighborhoodId" FROM public.users WHERE id=v_a),
    (SELECT "neighborhoodId" FROM public.users WHERE id=v_b);
  RAISE NOTICE 'aussen: %/% (Nachbarschaft %/%)', left(v_c,6), left(v_d,6),
    (SELECT "neighborhoodId" FROM public.users WHERE id=v_c),
    (SELECT "neighborhoodId" FROM public.users WHERE id=v_d);

  INSERT INTO public.family_links ("tenantId", von, nach, art) VALUES ('koretini', v_a, v_b, 'ELTERNTEIL');
  INSERT INTO public.family_links ("tenantId", von, nach, art) VALUES ('koretini', v_c, v_d, 'ELTERNTEIL');
  RAISE NOTICE 'Nach dem Anlegen: % Zeilen', (SELECT count(*) FROM public.family_links);

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  FOR r IN SELECT f.von, f.nach,
                  (SELECT "neighborhoodId" FROM public.users WHERE id=f.von) AS lv,
                  (SELECT "neighborhoodId" FROM public.users WHERE id=f.nach) AS ln
             FROM public.family_links f LOOP
    RAISE NOTICE '  sichtbar: %/% aus %/%', left(r.von,6), left(r.nach,6), r.lv, r.ln;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.family_links;
END $$;
