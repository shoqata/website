-- Nachweis, dass der Vorstand eine Nachbarschaft tatsaechlich aendern darf.
-- Der neue Dialog ruft updateDoc auf 'neighborhoods' auf; ohne passende
-- Zeilenregel waere er wirkungslos -- und genau das war der urspruengliche
-- Fehler an dieser Stelle (ein Knopf ohne Wirkung).

DO $$
DECLARE
  v_back  text := current_user;
  v_uid   uuid;
  v_mail  text;
  v_nb    text;
  v_name  text;
  v_neu   text;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail
    FROM public.users u
   WHERE u."tenantId" = 'koretini' AND u.role IN ('ADMIN','SUPER_ADMIN','BOARD')
     AND u."authUserId" IS NOT NULL LIMIT 1;
  IF v_uid IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Vorstand.'; RETURN; END IF;

  SELECT id, name INTO v_nb, v_name FROM public.neighborhoods
   WHERE "tenantId" = 'koretini' ORDER BY name LIMIT 1;
  IF v_nb IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: keine Nachbarschaft vorhanden.'; RETURN; END IF;

  RAISE NOTICE 'Rolle: % | Nachbarschaft: %', v_mail, v_name;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role', 'authenticated')::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    UPDATE public.neighborhoods SET description = 'Pruefung Schreibrecht' WHERE id = v_nb;
    SELECT description INTO v_neu FROM public.neighborhoods WHERE id = v_nb;
    RAISE NOTICE 'ERGEBNIS Vorstand aendert die Nachbarschaft: "%" -- erwartet "Pruefung Schreibrecht"', v_neu;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERGEBNIS Vorstand aendert die Nachbarschaft: ABGEWIESEN % -- Dialog waere wirkungslos', SQLSTATE;
  END;

  EXECUTE format('SET ROLE %I', v_back);

  -- Testaenderung zuruecknehmen
  UPDATE public.neighborhoods SET description = NULL
   WHERE id = v_nb AND description = 'Pruefung Schreibrecht';
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE 'Testaenderung zurueckgenommen.';
END $$;
