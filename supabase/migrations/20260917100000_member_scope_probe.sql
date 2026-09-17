-- Was darf ein gewoehnliches Mitglied wirklich lesen und aendern?
-- Gemessen in seiner Rolle, nicht aus der Oberflaeche geschlossen.
DO $$
DECLARE
  v_back text := current_user;
  v_uid uuid; v_row text; v_mail text; v_nb text; v_cnt int; v_role text;
BEGIN
  SELECT u."authUserId", u.id, u.email, u."neighborhoodId"
    INTO v_uid, v_row, v_mail, v_nb
    FROM public.users u
   WHERE u."tenantId"='koretini' AND u.role='MEMBER' AND u."authUserId" IS NOT NULL
   LIMIT 1;
  IF v_uid IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: kein Mitglied mit Anmeldung.'; RETURN; END IF;
  RAISE NOTICE 'Mitglied: % (Zeile %, Lagje %)', v_mail, v_row, COALESCE(v_nb,'keine');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT count(*) INTO v_cnt FROM public.users;
  RAISE NOTICE '1 sieht Mitglieder insgesamt: % (von 350)', v_cnt;

  IF v_nb IS NOT NULL THEN
    SELECT count(*) INTO v_cnt FROM public.users WHERE "neighborhoodId" = v_nb;
    RAISE NOTICE '2 sieht Mitglieder der eigenen Lagje: %', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM public.payments;
  RAISE NOTICE '3 sieht Zahlungen: % (nur eigene?)', v_cnt;

  SELECT count(*) INTO v_cnt FROM public.payments WHERE "userId" <> v_row;
  RAISE NOTICE '4 sieht FREMDE Zahlungen: % -- erwartet 0', v_cnt;

  SELECT count(*) INTO v_cnt FROM public.neighborhoods;
  RAISE NOTICE '5 sieht Nachbarschaften: % (oeffentlicher Inhalt)', v_cnt;

  -- eigene Daten aendern
  BEGIN
    UPDATE public.users SET phone = COALESCE(phone,'') WHERE id = v_row;
    RAISE NOTICE '6 aendert eigene Daten: erlaubt';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '6 aendert eigene Daten: ABGEWIESEN %', SQLSTATE;
  END;

  -- fremde Daten aendern
  BEGIN
    UPDATE public.users SET phone = 'xx' WHERE id <> v_row AND "tenantId"='koretini';
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    RAISE NOTICE '7 aendert FREMDE Daten: % Zeilen -- erwartet 0', v_cnt;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '7 aendert FREMDE Daten: abgewiesen %, richtig', SQLSTATE;
  END;

  -- sich selbst befoerdern
  BEGIN
    UPDATE public.users SET role='ADMIN' WHERE id = v_row;
    SELECT role INTO v_role FROM public.users WHERE id = v_row;
    RAISE NOTICE '8 macht sich zum ADMIN: DURCHGELASSEN (%) -- schwerer Fehler', v_role;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '8 macht sich zum ADMIN: abgewiesen, richtig';
  END;

  -- Sponsorenanfragen
  BEGIN
    SELECT count(*) INTO v_cnt FROM public.sponsors;
    RAISE NOTICE '9 sieht Sponsorenanfragen: % -- erwartet 0', v_cnt;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '9 sieht Sponsorenanfragen: abgewiesen, richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
