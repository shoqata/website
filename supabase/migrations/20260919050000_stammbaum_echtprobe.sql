-- Der eigentliche Weg: legt ein angemeldeter Administrator ueber die
-- Anwendung tatsaechlich eine Beziehung an?
--
-- Die bisherige Selbstpruefung lief als Datenbankrolle und ist damit an der
-- Zeilenregel vorbeigelaufen -- sie hat bewiesen, dass niemand Unbefugtes
-- hereinkommt, aber nicht, dass der Befugte hereinkommt.
DO $$
DECLARE v_back text := current_user;
        v_admin_uid text; v_admin_mail text;
        v_mit_uid text; v_mit_mail text;
        v_a text; v_b text; v_n int;
BEGIN
  SELECT u."authUserId", u.email INTO v_admin_uid, v_admin_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT u."authUserId", u.email INTO v_mit_uid, v_mit_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;

  SELECT id INTO v_a FROM public.users WHERE "tenantId"='koretini' ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "tenantId"='koretini' AND id <> v_a ORDER BY id LIMIT 1;

  IF v_admin_uid IS NULL THEN
    RAISE NOTICE 'Kein Administrator mit Anmeldekonto -- nicht pruefbar.';
  ELSE
    -- Als Administrator: muss gehen, und zwar OHNE tenantId mitzuschicken.
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_admin_uid, 'role','authenticated','email', v_admin_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      INSERT INTO public.family_links (von, nach, art) VALUES (v_a, v_b, 'ELTERNTEIL');
      RAISE NOTICE 'Administrator legt Beziehung an: durchgelassen -- richtig';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Administrator legt Beziehung an: ABGEWIESEN -- Fehler: %', left(SQLERRM, 80);
    END;
    BEGIN
      SELECT count(*) INTO v_n FROM public.familien_uebersicht();
      RAISE NOTICE 'Administrator liest Uebersicht: % Zeilen -- richtig', v_n;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Administrator liest Uebersicht: ABGEWIESEN -- Fehler: %', left(SQLERRM, 80);
    END;
    BEGIN
      SELECT count(*) INTO v_n FROM public.haushalt_vorschlaege();
      RAISE NOTICE 'Administrator liest Haushalte: % -- richtig', v_n;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Administrator liest Haushalte: ABGEWIESEN -- Fehler: %', left(SQLERRM, 80);
    END;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END IF;

  IF v_mit_uid IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    BEGIN
      SELECT count(*) INTO v_n FROM public.family_links;
      RAISE NOTICE 'Gewoehnliches Mitglied sieht % Beziehungen (soll 0)', v_n;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Gewoehnliches Mitglied: kein Zugriff -- auch richtig';
    END;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
  END IF;

  DELETE FROM public.family_links;
  RAISE NOTICE 'Proben entfernt, % Beziehungen bleiben.', (SELECT count(*) FROM public.family_links);
END $$;
