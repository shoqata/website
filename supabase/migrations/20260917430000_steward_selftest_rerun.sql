-- Nachweis der Betreuungsrechte.
--
-- Geprueft wird in der Rolle authenticated mit dem Token einer echten
-- verantwortlichen Person -- also unter genau den Regeln, die auch in der
-- Anwendung gelten. Die Behauptung "sieht nur die eigene Nachbarschaft und
-- kann den Stand einer Rechnung nicht aendern" ist andernfalls wertlos.
DO $$
DECLARE
  v_back   text := current_user;
  v_uid    text; v_mail text; v_row text; v_nb text; v_nbname text;
  v_eigene int; v_alle int; v_fremd int;
  v_zahl_eigen int; v_zahl_fremd int;
  v_payment text; v_fremd_payment text; v_report uuid;
  v_n int; v_err text; v_status text;
BEGIN
  -- Die einzige Nachbarschaft mit hinterlegter verantwortlicher Person.
  SELECT u."authUserId", u.email, u.id, n.id, n.name
    INTO v_uid, v_mail, v_row, v_nb, v_nbname
    FROM public.neighborhoods n
    JOIN public.users u ON n."contactPersonIds" @> to_jsonb(u.id)
   WHERE u."authUserId" IS NOT NULL
   LIMIT 1;

  IF v_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: keine verantwortliche Person mit Anmeldekonto.';
    RETURN;
  END IF;
  RAISE NOTICE 'Geprueft an: % -- verantwortlich fuer %', v_mail, v_nbname;

  SELECT count(*) INTO v_alle FROM public.users;
  SELECT count(*) INTO v_eigene FROM public.users WHERE "neighborhoodId" = v_nb;
  RAISE NOTICE 'Im Verein: % Mitglieder, davon in %: %', v_alle, v_nbname, v_eigene;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  RAISE NOTICE '1 gilt als Geschaeftsfuehrung: %  -- erwartet f', public.is_member_manager();
  RAISE NOTICE '2 gilt als Betreuung: %  -- erwartet t', public.is_neighborhood_steward();

  SELECT count(*) INTO v_n FROM public.users;
  SELECT count(*) INTO v_fremd FROM public.users
   WHERE "neighborhoodId" IS DISTINCT FROM v_nb AND id <> v_row;
  RAISE NOTICE '3 sichtbare Mitglieder: % (erwartet % + die eigene Zeile)', v_n, v_eigene;
  RAISE NOTICE '4 davon ausserhalb der eigenen Nachbarschaft: % -- erwartet 0', v_fremd;

  -- Adresse eines eigenen Mitglieds aendern: soll gehen.
  BEGIN
    UPDATE public.users SET city = city
     WHERE "neighborhoodId" = v_nb AND COALESCE(role,'MEMBER') = 'MEMBER';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '5 Adressen der eigenen Nachbarschaft aenderbar: % Zeilen -- erwartet > 0', v_n;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '5 Adressen der eigenen Nachbarschaft: abgewiesen -- % (unerwartet)', v_err;
  END;

  -- Jemanden hochstufen: darf nicht gehen.
  BEGIN
    UPDATE public.users SET role = 'ADMIN'
     WHERE "neighborhoodId" = v_nb AND COALESCE(role,'MEMBER') = 'MEMBER';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '6 Mitglied zu ADMIN hochgestuft: % Zeilen -- SCHWERER FEHLER', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '6 Hochstufen zu ADMIN: abgewiesen -- richtig';
  END;

  -- Rechnungen: eigene Nachbarschaft sichtbar, fremde nicht.
  SELECT count(*) INTO v_zahl_eigen FROM public.payments p
    JOIN public.users u ON u.id = p."userId" WHERE u."neighborhoodId" = v_nb;
  SELECT count(*) INTO v_zahl_fremd FROM public.payments p
    LEFT JOIN public.users u ON u.id = p."userId"
   WHERE u."neighborhoodId" IS DISTINCT FROM v_nb AND p."userId" IS DISTINCT FROM v_row;
  RAISE NOTICE '7 sichtbare Rechnungen der eigenen Nachbarschaft: %', v_zahl_eigen;
  RAISE NOTICE '8 sichtbare Rechnungen ausserhalb: % -- erwartet 0', v_zahl_fremd;

  -- Status selbst aendern: darf nicht gehen.
  SELECT p.id INTO v_payment FROM public.payments p
    JOIN public.users u ON u.id = p."userId"
   WHERE u."neighborhoodId" = v_nb AND p.status = 'PENDING' LIMIT 1;

  IF v_payment IS NULL THEN
    RAISE NOTICE '9/10 keine offene Rechnung in der Nachbarschaft -- nicht pruefbar.';
  ELSE
    BEGIN
      UPDATE public.payments SET status = 'PAID' WHERE id = v_payment;
      GET DIAGNOSTICS v_n = ROW_COUNT;
      IF v_n > 0 THEN
        RAISE NOTICE '9 Status selbst auf PAID gesetzt: % -- SCHWERER FEHLER', v_n;
      ELSE
        RAISE NOTICE '9 Status selbst aendern: 0 Zeilen -- richtig';
      END IF;
    EXCEPTION WHEN others THEN
      RAISE NOTICE '9 Status selbst aendern: abgewiesen -- richtig';
    END;

    -- Melden: soll gehen.
    BEGIN
      SELECT public.report_payment_paid(v_payment, 'CASH', current_date, 'Selbsttest') INTO v_report;
      RAISE NOTICE '10 Zahlung gemeldet: %', v_report;
    EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
      RAISE NOTICE '10 Melden: abgewiesen -- % (unerwartet)', v_err;
    END;

    -- Die eigene Meldung selbst bestaetigen: darf nicht gehen.
    IF v_report IS NOT NULL THEN
      BEGIN
        PERFORM public.decide_payment_report(v_report, true, 'Selbstbestaetigung');
        RAISE NOTICE '11 eigene Meldung selbst bestaetigt -- SCHWERER FEHLER';
      EXCEPTION WHEN others THEN
        RAISE NOTICE '11 eigene Meldung selbst bestaetigen: abgewiesen -- richtig';
      END;

      BEGIN
        UPDATE public.payment_reports SET status = 'CONFIRMED' WHERE id = v_report;
        GET DIAGNOSTICS v_n = ROW_COUNT;
        IF v_n > 0 THEN
          RAISE NOTICE '12 Meldung direkt umgeschrieben: % -- SCHWERER FEHLER', v_n;
        ELSE
          RAISE NOTICE '12 Meldung direkt umschreiben: 0 Zeilen -- richtig';
        END IF;
      EXCEPTION WHEN others THEN
        RAISE NOTICE '12 Meldung direkt umschreiben: abgewiesen -- richtig';
      END;
    END IF;
  END IF;

  EXECUTE format('SET ROLE %I', v_back);

  -- ------------------------------------------------- Gegenprobe: der Vorstand
  IF v_report IS NOT NULL THEN
    SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
     WHERE u.role IN ('ADMIN','SUPER_ADMIN','BOARD') AND u."authUserId" IS NOT NULL LIMIT 1;

    IF v_uid IS NULL THEN
      RAISE NOTICE '13 Gegenprobe: kein angemeldeter Vorstand vorhanden.';
    ELSE
      PERFORM set_config('request.jwt.claims',
        json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
      EXECUTE 'SET ROLE authenticated';
      BEGIN
        PERFORM public.decide_payment_report(v_report, true, 'Selbsttest bestaetigt');
        SELECT p.status INTO v_status FROM public.payments p WHERE p.id = v_payment;
        RAISE NOTICE '13 Vorstand bestaetigt -- Rechnung steht jetzt auf %', v_status;
      EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
        RAISE NOTICE '13 Vorstand bestaetigt: FEHLGESCHLAGEN -- %', v_err;
      END;
      EXECUTE format('SET ROLE %I', v_back);
    END IF;
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Alles zuruecknehmen: die Testmeldung und der Stand der Rechnung.
  DELETE FROM public.payment_reports WHERE note = 'Selbsttest' OR "decisionNote" = 'Selbsttest bestaetigt';
  IF v_payment IS NOT NULL THEN
    UPDATE public.payments
       SET status = 'PENDING', "paidAt" = NULL, method = 'QR_BILL', "collectedBy" = NULL
     WHERE id = v_payment;
    RAISE NOTICE 'Rechnung % auf PENDING zurueckgesetzt, Testmeldung entfernt.', v_payment;
  END IF;
END $$;
