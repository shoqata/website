-- Nachweis, dass eine eingegangene Sponsorenanfrage im Vorstand ankommt.
--
-- Das oeffentliche Absenden ist im Browser durchgespielt. Offen war die
-- andere Haelfte: darf der Vorstand die Zeile lesen und bearbeiten, und
-- bleibt sie fuer einen fremden Verein unsichtbar?
--
-- Zwei Fallstricke aus dem ersten Anlauf sind hier beruecksichtigt:
--   * RESET ROLE nicht verwenden. Es faellt auf den Login-Benutzer zurueck,
--     nicht auf die erhoehte Rolle des Migrationslaufs -- jede nachfolgende
--     Anweisung scheitert dann an fehlenden Rechten. Stattdessen wird die
--     Ausgangsrolle gemerkt und ausdruecklich wiederhergestellt.
--   * Die Rollenbezeichnungen und die Verknuepfung zur Anmeldung erst
--     nachsehen, statt sie zu raten.

DO $$
DECLARE
  v_back       text := current_user;
  v_admin_uid  uuid;
  v_admin_mail text;
  v_id         uuid;
  v_cnt        int;
  v_status     text;
  v_other      uuid;
  v_other_ten  text;
  r            record;
BEGIN
  -- ---------------------------------------------------- Bestandsaufnahme
  RAISE NOTICE '--- Rollen im Verein koretini ---';
  FOR r IN
    SELECT role, count(*) AS anzahl,
           count(*) FILTER (WHERE "authUserId" IS NOT NULL) AS mit_anmeldung
      FROM public.users WHERE "tenantId" = 'koretini'
     GROUP BY role ORDER BY 2 DESC
  LOOP
    RAISE NOTICE '  % : % Personen, davon % mit Anmeldung', r.role, r.anzahl, r.mit_anmeldung;
  END LOOP;

  SELECT u."authUserId", u.email INTO v_admin_uid, v_admin_mail
    FROM public.users u
   WHERE u."tenantId" = 'koretini'
     AND u.role IN ('ADMIN','BOARD','SUPER_ADMIN')
     AND u."authUserId" IS NOT NULL
   ORDER BY CASE u.role WHEN 'ADMIN' THEN 1 WHEN 'SUPER_ADMIN' THEN 2 ELSE 3 END
   LIMIT 1;

  IF v_admin_uid IS NULL THEN
    RAISE NOTICE 'PRUEFUNG NICHT MOEGLICH: kein Vorstand mit verknuepfter Anmeldung.';
    RETURN;
  END IF;
  RAISE NOTICE 'Geprueft in der Rolle von: %', v_admin_mail;

  -- ------------------------------------------- Anfrage wie aus dem Formular
  PERFORM set_config('request.headers', '{"origin":"https://www.koretini.me"}', false);
  EXECUTE 'SET ROLE anon';
  v_id := public.submit_sponsor('STANDARD', 500, 'Lesetest AG', 'Lesetest',
                                'lesetest@example.invalid', NULL, NULL, NULL,
                                NULL, NULL, NULL, 'Pruefung der Sicht im Vorstand');
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Anfrage angelegt: %', v_id;

  -- ------------------------------------------------ als angemeldeter Vorstand
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin_uid::text, 'role', 'authenticated')::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT count(*) INTO v_cnt FROM public.sponsors WHERE id = v_id;
  RAISE NOTICE 'ERGEBNIS 1 Vorstand sieht die Anfrage: % -- erwartet 1', v_cnt;

  BEGIN
    UPDATE public.sponsors SET status = 'CONFIRMED' WHERE id = v_id;
    SELECT status INTO v_status FROM public.sponsors WHERE id = v_id;
    RAISE NOTICE 'ERGEBNIS 2 Vorstand setzt den Status: % -- erwartet CONFIRMED', v_status;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERGEBNIS 2 Vorstand setzt den Status: ABGEWIESEN % -- falsch', SQLSTATE;
  END;

  EXECUTE format('SET ROLE %I', v_back);

  -- --------------------------------------------------------- Gegenprobe
  SELECT u."authUserId", u."tenantId" INTO v_other, v_other_ten
    FROM public.users u
   WHERE u."tenantId" <> 'koretini'
     AND u.role IN ('ADMIN','BOARD')
     AND u."authUserId" IS NOT NULL
   LIMIT 1;

  IF v_other IS NULL THEN
    RAISE NOTICE 'ERGEBNIS 3 Gegenprobe: kein zweiter Verein mit Vorstand, nicht pruefbar.';
  ELSE
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_other::text, 'role', 'authenticated')::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT count(*) INTO v_cnt FROM public.sponsors;
    RAISE NOTICE 'ERGEBNIS 3 fremder Verein (%) sieht: % -- erwartet 0', v_other_ten, v_cnt;
    EXECUTE format('SET ROLE %I', v_back);
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, false);
  PERFORM set_config('request.headers', NULL, false);

  DELETE FROM public.sponsors WHERE email = 'lesetest@example.invalid';
  RAISE NOTICE 'Testzeile entfernt.';
END $$;
