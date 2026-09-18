-- Nachweis: Versionierung und Buchung.
--
-- Geprueft in der Rolle authenticated -- einmal als Vorstand, einmal als
-- gewoehnliches Mitglied. Alles Angelegte wird am Ende wieder entfernt.
DO $$
DECLARE
  v_back  text := current_user;
  v_vor_uid text; v_vor_mail text;
  v_mit_uid text; v_mit_mail text;
  v_id    text := 'selbsttest-protokoll';
  v_ver   int; v_n int; v_err text; v_titel text;
  r record;
BEGIN
  SELECT u."authUserId", u.email INTO v_vor_uid, v_vor_mail FROM public.users u
   WHERE u.role IN ('BOARD','ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT u."authUserId", u.email INTO v_mit_uid, v_mit_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER') = 'MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;

  IF v_vor_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Vorstand.'; RETURN;
  END IF;
  RAISE NOTICE 'Vorstand: %  |  Mitglied: %', v_vor_mail, coalesce(v_mit_mail, '<keines>');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_vor_uid, 'role','authenticated','email', v_vor_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  -- Neues Protokoll
  BEGIN
    INSERT INTO public.board_meetings (id, "tenantId", title, date, status, "agendaItems", decisions)
    VALUES (v_id, 'koretini', 'Selbsttest Fassung 1', current_date::text, 'PLANNED',
            '[]'::jsonb, '[]'::jsonb);
    RAISE NOTICE '1 Vorstand legt ein Protokoll an: ja';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '1 Vorstand legt ein Protokoll an: abgewiesen -- %', v_err;
    EXECUTE format('SET ROLE %I', v_back); RETURN;
  END;

  SELECT version INTO v_ver FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE '2 Version nach dem Anlegen: % -- erwartet 1', v_ver;

  -- Erste Ueberarbeitung
  UPDATE public.board_meetings SET title = 'Selbsttest Fassung 2' WHERE id = v_id;
  SELECT version INTO v_ver FROM public.board_meetings WHERE id = v_id;
  SELECT count(*) INTO v_n FROM public.board_meeting_versions WHERE "meetingId" = v_id;
  RAISE NOTICE '3 nach der ersten Ueberarbeitung: Version %, % Fassung(en) im Verlauf -- erwartet 2 / 1',
    v_ver, v_n;

  -- Zweite Ueberarbeitung
  UPDATE public.board_meetings SET title = 'Selbsttest Fassung 3' WHERE id = v_id;
  SELECT version INTO v_ver FROM public.board_meetings WHERE id = v_id;
  SELECT count(*) INTO v_n FROM public.board_meeting_versions WHERE "meetingId" = v_id;
  RAISE NOTICE '4 nach der zweiten: Version %, % Fassungen -- erwartet 3 / 2', v_ver, v_n;

  -- Speichern ohne Aenderung darf keine Fassung erzeugen
  UPDATE public.board_meetings SET title = 'Selbsttest Fassung 3' WHERE id = v_id;
  SELECT count(*) INTO v_n FROM public.board_meeting_versions WHERE "meetingId" = v_id;
  RAISE NOTICE '5 Speichern ohne Unterschied: % Fassungen -- erwartet weiterhin 2', v_n;

  -- Der Verlauf muss den alten Wortlaut enthalten
  SELECT snapshot ->> 'title' INTO v_titel FROM public.board_meeting_versions
   WHERE "meetingId" = v_id AND version = 1;
  RAISE NOTICE '6 im Verlauf steht als Fassung 1: "%" -- erwartet "Selbsttest Fassung 1"', v_titel;

  -- Eine Fassung nachtraeglich veraendern darf nicht gehen
  BEGIN
    UPDATE public.board_meeting_versions SET snapshot = '{}'::jsonb WHERE "meetingId" = v_id;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '7 Vorstand aendert eine alte Fassung: % Zeilen -- SCHWERER FEHLER', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '7 Vorstand aendert eine alte Fassung: abgewiesen -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);

  -- ------------------------------------------------- Gegenprobe: Mitglied
  IF v_mit_uid IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_mit_uid, 'role','authenticated','email', v_mit_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';

    SELECT count(*) INTO v_n FROM public.board_meetings;
    RAISE NOTICE '8 Mitglied sieht Protokolle: % -- erwartet 0', v_n;

    BEGIN
      UPDATE public.board_meetings SET title = 'Vom Mitglied geaendert' WHERE id = v_id;
      GET DIAGNOSTICS v_n = ROW_COUNT;
      IF v_n > 0 THEN RAISE NOTICE '9 Mitglied aendert ein Protokoll: % -- SCHWERER FEHLER', v_n;
      ELSE RAISE NOTICE '9 Mitglied aendert ein Protokoll: 0 Zeilen -- richtig'; END IF;
    EXCEPTION WHEN others THEN
      RAISE NOTICE '9 Mitglied aendert ein Protokoll: abgewiesen -- richtig';
    END;

    SELECT count(*) INTO v_n FROM public.board_meeting_versions;
    RAISE NOTICE '10 Mitglied sieht den Verlauf: % -- erwartet 0', v_n;

    EXECUTE format('SET ROLE %I', v_back);
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.board_meeting_versions WHERE "meetingId" = v_id;
  DELETE FROM public.board_meetings WHERE id = v_id;
  RAISE NOTICE 'Testprotokoll und Fassungen entfernt.';
END $$;
