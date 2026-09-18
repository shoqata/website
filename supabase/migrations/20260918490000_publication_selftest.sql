-- Nachweis der Freigabe.
--
-- Die Behauptung "ein Mitglied sieht nur, was freigegeben wurde" ist ohne
-- Messung wertlos. Geprueft in der Rolle authenticated, mit dem Token eines
-- gewoehnlichen Mitglieds.
DO $$
DECLARE
  v_back text := current_user;
  v_vor_uid text; v_vor_mail text;
  v_mit_uid text; v_mit_mail text;
  v_id text := 'selbsttest-freigabe';
  v_n int; v_err text; v_ver int; v_wer text;
BEGIN
  SELECT u."authUserId", u.email INTO v_vor_uid, v_vor_mail FROM public.users u
   WHERE u.role IN ('BOARD','ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT u."authUserId", u.email INTO v_mit_uid, v_mit_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;

  IF v_vor_uid IS NULL OR v_mit_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: Vorstand oder Mitglied mit Anmeldung fehlt.'; RETURN;
  END IF;
  RAISE NOTICE 'Vorstand: %  |  Mitglied: %', v_vor_mail, v_mit_mail;

  INSERT INTO public.board_meetings (id, "tenantId", title, date, status, "agendaItems", decisions)
  VALUES (v_id, 'koretini', 'Selbsttest Freigabe', current_date::text, 'HELD', '[]'::jsonb, '[]'::jsonb);

  -- Noch nicht freigegeben
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '1 Mitglied sieht das nicht freigegebene Protokoll: % -- erwartet 0', v_n;
  SELECT count(*) INTO v_n FROM public.board_meetings;
  RAISE NOTICE '2 Mitglied sieht Protokolle insgesamt: % -- erwartet 0', v_n;
  EXECUTE format('SET ROLE %I', v_back);

  -- Der Vorstand gibt frei
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_vor_uid, 'role','authenticated','email', v_vor_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  UPDATE public.board_meetings SET "publishedToMembers" = true WHERE id = v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '3 Vorstand gibt frei: % Zeile -- erwartet 1', v_n;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT "publishedAt" IS NOT NULL, "publishedBy", version
    INTO v_err, v_wer, v_ver FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '4 Zeitpunkt der Freigabe festgehalten: % | durch % | Fassung %', v_err, v_wer, v_ver;

  -- Jetzt sieht das Mitglied es
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '5 Mitglied sieht das freigegebene Protokoll: % -- erwartet 1', v_n;

  -- Aendern darf es weiterhin nicht
  BEGIN
    UPDATE public.board_meetings SET title = 'Vom Mitglied geaendert' WHERE id = v_id;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN RAISE NOTICE '6 Mitglied aendert das freigegebene Protokoll: % -- SCHWERER FEHLER', v_n;
    ELSE RAISE NOTICE '6 Mitglied aendert das freigegebene Protokoll: 0 Zeilen -- richtig'; END IF;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '6 Mitglied aendert das freigegebene Protokoll: abgewiesen -- richtig';
  END;

  -- Und den Verlauf sieht es auch nicht
  SELECT count(*) INTO v_n FROM public.board_meeting_versions;
  RAISE NOTICE '7 Mitglied sieht frueherere Fassungen: % -- erwartet 0', v_n;
  EXECUTE format('SET ROLE %I', v_back);

  -- Zuruecknehmen
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_vor_uid, 'role','authenticated','email', v_vor_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  UPDATE public.board_meetings SET "publishedToMembers" = false WHERE id = v_id;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT "publishedAt" IS NULL INTO v_err FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '8 nach dem Zuruecknehmen ist der Zeitpunkt geleert: % -- erwartet t', v_err;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '9 Mitglied sieht es danach: % -- erwartet 0', v_n;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.board_meeting_versions WHERE "meetingId" = v_id;
  DELETE FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE 'Testprotokoll entfernt.';
END $$;
