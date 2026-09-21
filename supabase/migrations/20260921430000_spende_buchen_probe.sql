DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text;
        v_id uuid; v_t text; v_vorher int; v_nachher int; r record;
BEGIN
  DELETE FROM public.donations WHERE "tenantId"='koretini';
  SELECT count(*) INTO v_vorher FROM public.accounting_journal;

  -- Eine Spende ueber den oeffentlichen Weg anlegen
  SET LOCAL ROLE anon;
  PERFORM set_config('request.headers', json_build_object('origin','https://koretini.me')::text, true);
  SELECT id INTO v_id FROM public.spende_anlegen(120,'CHF','Fitore Berisha','f.b@example.ch',
    'Weg 1','8000','Zürich','CH','Für die Schule','Bildung',false);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);
  RAISE NOTICE 'Spende angelegt: %', left(v_id::text, 8);

  -- Ein gewoehnliches Mitglied darf nicht buchen
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    PERFORM public.spende_bezahlt(v_id,'QR');
    RAISE NOTICE 'Mitglied bucht: DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Mitglied bucht: abgewiesen -- richtig'; END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Die Verwaltung schon
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.spende_bezahlt(v_id,'QR') INTO v_t;
  RAISE NOTICE 'Verwaltung bucht: %', v_t;
  BEGIN
    PERFORM public.spende_bezahlt(v_id,'QR');
    RAISE NOTICE 'zweimal buchen: DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'zweimal buchen: abgewiesen -- richtig'; END;
  SELECT public.spende_bescheinigt(v_id) INTO v_t;
  RAISE NOTICE 'Bescheinigung: %', v_t;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT count(*) INTO v_nachher FROM public.accounting_journal;
  RAISE NOTICE 'Journal: % -> % Buchungen', v_vorher, v_nachher;
  FOR r IN SELECT description, amount, "debitCode", "creditCode" FROM public.accounting_journal
            WHERE "referenceId" = v_id::text LOOP
    RAISE NOTICE '  % | % CHF | S%/H%', r.description, r.amount, r."debitCode", r."creditCode";
  END LOOP;

  DELETE FROM public.accounting_journal WHERE "referenceId" = v_id::text;
  DELETE FROM public.donations WHERE "tenantId"='koretini';
  RAISE NOTICE 'Aufgeraeumt, Journal wieder % Buchungen', (SELECT count(*) FROM public.accounting_journal);
END $$;
