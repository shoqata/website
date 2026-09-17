-- Kommt der Vorstand an alles, was seine Ansicht braucht?
--
-- Die Ansicht liest payments, users, neighborhoods, inquiries und
-- board_meetings. Alle fuenf haengen an is_member_manager(), und diese
-- Funktion wurde vor kurzem eingeengt. Ob BOARD dabei unbeschadet geblieben
-- ist, gehoert gemessen und nicht angenommen.
--
-- Kein Vorstandsmitglied hat bisher ein Anmeldekonto. Fuer die Pruefung wird
-- einer Zeile voruebergehend eine Kennung gegeben und danach wieder entzogen
-- -- genau das, was claim_my_profile bei der ersten Anmeldung ohnehin tut.
DO $$
DECLARE
  v_back  text := current_user;
  v_row   text; v_mail text; v_name text;
  v_fake  uuid := gen_random_uuid();
  v_vorher text;
  n_pay int; n_usr int; n_nb int; n_inq int; n_meet int; n_rep int; n_mail int;
  v_err text; v_rolle text;
BEGIN
  SELECT u.id, u.email, u."displayName", u."authUserId"
    INTO v_row, v_mail, v_name, v_vorher
    FROM public.users u WHERE u.role = 'BOARD' LIMIT 1;

  IF v_row IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: kein Vorstandsmitglied vorhanden.'; RETURN;
  END IF;
  RAISE NOTICE 'Geprueft an: % (%) -- Kennung vorher %', v_name, v_mail, coalesce(v_vorher,'<keine>');

  UPDATE public.users SET "authUserId" = v_fake::text WHERE id = v_row;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_fake::text, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT public.app_role() INTO v_rolle;
  RAISE NOTICE '1 app_role(): %  -- erwartet BOARD', v_rolle;
  RAISE NOTICE '2 gilt als Geschaeftsfuehrung: %  -- erwartet t', public.is_member_manager();

  SELECT count(*) INTO n_usr  FROM public.users;
  SELECT count(*) INTO n_pay  FROM public.payments;
  SELECT count(*) INTO n_nb   FROM public.neighborhoods;
  SELECT count(*) INTO n_inq  FROM public.inquiries;
  SELECT count(*) INTO n_meet FROM public.board_meetings;
  RAISE NOTICE '3 Mitglieder %, Rechnungen %, Nachbarschaften %', n_usr, n_pay, n_nb;
  RAISE NOTICE '4 Anfragen %, Sitzungsprotokolle %', n_inq, n_meet;

  SELECT count(*) INTO n_rep FROM public.payment_reports;
  RAISE NOTICE '5 Zahlungsmeldungen sichtbar: %', n_rep;

  SELECT count(*) INTO n_mail FROM public.mail_queue;
  RAISE NOTICE '6 Warteschlange sichtbar: %', n_mail;

  -- Der Vorstand soll buchen koennen -- das ist der Unterschied zur Betreuung.
  BEGIN
    UPDATE public.payments SET status = status WHERE "tenantId" = 'koretini';
    GET DIAGNOSTICS n_pay = ROW_COUNT;
    RAISE NOTICE '7 Rechnungen schreibbar: % Zeilen -- erwartet > 0', n_pay;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '7 Rechnungen schreibbar: abgewiesen -- % (unerwartet)', v_err;
  END;

  -- Ein Protokoll anlegen und wieder entfernen.
  BEGIN
    INSERT INTO public.board_meetings (id, "tenantId", title, date)
    VALUES ('selbsttest-protokoll', 'koretini', 'Selbsttest', now()::text);
    RAISE NOTICE '8 Protokoll anlegen: moeglich';
    DELETE FROM public.board_meetings WHERE id = 'selbsttest-protokoll';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '8 Protokoll anlegen: abgewiesen -- %', v_err;
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  UPDATE public.users SET "authUserId" = v_vorher WHERE id = v_row;
  RAISE NOTICE 'Kennung zurueckgesetzt auf %', coalesce(v_vorher,'<keine>');
END $$;
