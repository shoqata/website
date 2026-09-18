-- Darf die verantwortliche Person ein Geburtsdatum nachtragen?
--
-- Die Regel erlaubt ihr das Aendern von Mitgliedern ihrer Nachbarschaft. Ob
-- das auch fuer diese Spalte gilt, wird gemessen und nicht angenommen -- und
-- zugleich, dass sie damit nicht an fremde Zeilen kommt.
DO $$
DECLARE
  v_back  text := current_user;
  v_uid text; v_mail text; v_nb text; v_nbname text;
  v_ziel text; v_zielname text; v_vorher text;
  v_n int; v_err text; v_nachher text;
BEGIN
  SELECT u."authUserId", u.email, n.id, n.name
    INTO v_uid, v_mail, v_nb, v_nbname
    FROM public.neighborhoods n
    JOIN public.users u ON n."contactPersonIds" @> to_jsonb(u.id)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;

  IF v_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: keine verantwortliche Person mit Anmeldekonto.'; RETURN;
  END IF;

  SELECT u.id, u."displayName", u.birthdate INTO v_ziel, v_zielname, v_vorher
    FROM public.users u
   WHERE u."neighborhoodId" = v_nb AND COALESCE(u.role,'MEMBER') = 'MEMBER'
     AND u.birthdate IS NULL LIMIT 1;

  IF v_ziel IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: in % hat jeder schon ein Geburtsdatum.', v_nbname; RETURN;
  END IF;
  RAISE NOTICE 'Betreuung % in %, Ziel: % (vorher %)',
    v_mail, v_nbname, v_zielname, coalesce(v_vorher,'<keines>');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated','email', v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    UPDATE public.users SET birthdate = '1980-01-01' WHERE id = v_ziel;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '1 Geburtsdatum im eigenen Gebiet setzen: % Zeile -- erwartet 1', v_n;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '1 Geburtsdatum setzen: abgewiesen -- % (unerwartet)', v_err;
  END;

  SELECT birthdate INTO v_nachher FROM public.users WHERE id = v_ziel;
  RAISE NOTICE '2 tatsaechlich gespeichert: %', coalesce(v_nachher, '<nichts>');

  -- Gegenprobe: ein Mitglied einer fremden Nachbarschaft.
  BEGIN
    UPDATE public.users SET birthdate = '1980-01-01'
     WHERE "neighborhoodId" IS DISTINCT FROM v_nb AND COALESCE(role,'MEMBER') = 'MEMBER';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN
      RAISE NOTICE '3 fremde Zeilen geaendert: % -- SCHWERER FEHLER', v_n;
    ELSE
      RAISE NOTICE '3 fremde Zeilen geaendert: 0 -- richtig';
    END IF;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '3 fremde Zeilen: abgewiesen -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  UPDATE public.users SET birthdate = v_vorher WHERE id = v_ziel;
  RAISE NOTICE 'Zurueckgesetzt auf %', coalesce(v_vorher, '<keines>');
END $$;
