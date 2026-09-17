-- Kommt ein Mitglied beim Speichern des eigenen Profils durch?
--
-- Geprueft wird in der Rolle authenticated mit dem Token des Mitglieds -- also
-- unter genau denselben Regeln wie in der Anwendung. Der Vergleich UPDATE
-- gegen UPSERT ist der Kern: die Anwendung nutzte bisher den zweiten Weg.
DO $$
DECLARE
  v_back  text := current_user;
  v_uid   text; v_mail text; v_row text; v_rolle text;
  v_tel_alt text; v_err text; v_n int;
BEGIN
  -- Ein Mitglied, dessen Zeile einem Konto zugeordnet ist -- der Normalfall
  -- nach der Anmeldung.
  SELECT u."authUserId", u.email, u.id, u.role, u.phone
    INTO v_uid, v_mail, v_row, v_rolle, v_tel_alt
    FROM public.users u
   WHERE u."authUserId" IS NOT NULL AND u.role NOT IN ('ADMIN','SUPER_ADMIN')
   LIMIT 1;

  IF v_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: kein zugeordnetes Mitglied ohne Adminrolle.';
    RETURN;
  END IF;
  RAISE NOTICE 'Geprueft an: % (Rolle %, Zeile %)', v_mail, v_rolle, v_row;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  RAISE NOTICE '1 app_role() sieht: %  -- erwartet %', public.app_role(), v_rolle;
  RAISE NOTICE '2 eigene Zeile gefunden: %', coalesce(public.current_user_row_id(), '<keine>');

  -- Der alte Weg: Upsert. Genau hier scheiterte das Speichern.
  BEGIN
    INSERT INTO public.users (id, "tenantId", email, role, "displayName", phone)
    VALUES (v_row, 'koretini', v_mail, v_rolle, 'Selbsttest', '+41 00 000 00 00')
    ON CONFLICT (id) DO UPDATE SET phone = EXCLUDED.phone;
    RAISE NOTICE '3 Upsert (alter Weg): DURCHGELASSEN';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '3 Upsert (alter Weg): abgewiesen -- %', v_err;
  END;

  -- Der neue Weg: Update auf die vorhandene Zeile.
  BEGIN
    UPDATE public.users SET phone = '+41 11 111 11 11' WHERE id = v_row;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '4 Update (neuer Weg): % Zeile geaendert -- erwartet 1', v_n;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '4 Update (neuer Weg): abgewiesen -- %', v_err;
  END;

  -- Gegenprobe: eine fremde Zeile darf dieses Mitglied nicht anfassen.
  BEGIN
    UPDATE public.users SET phone = '+41 99 999 99 99'
     WHERE id <> v_row AND "tenantId" = 'koretini';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN
      RAISE NOTICE '5 fremde Zeilen geaendert: % -- SCHWERER FEHLER', v_n;
    ELSE
      RAISE NOTICE '5 fremde Zeilen geaendert: 0 -- richtig';
    END IF;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '5 fremde Zeilen: abgewiesen -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Die Testaenderung zuruecknehmen.
  UPDATE public.users SET phone = v_tel_alt WHERE id = v_row;
  RAISE NOTICE 'Telefonnummer wiederhergestellt: %', coalesce(v_tel_alt, '<leer>');
END $$;
