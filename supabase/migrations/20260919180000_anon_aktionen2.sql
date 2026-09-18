-- Diesmal richtig: Kennungen VOR dem Rollenwechsel beschaffen, sonst
-- scheitert schon das Argument und die Funktion wird nie erreicht.
DO $$
DECLARE v_back text := current_user; r record;
        v_zahlung text; v_meldung uuid; v_vorher text; v_nachher text; v_n int;
BEGIN
  RAISE NOTICE '--- Sind die argumentlosen wirklich nur Ausloeser? ---';
  FOR r IN SELECT p.proname, pg_get_function_result(p.oid) AS erg
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.prosecdef
              AND pg_get_function_identity_arguments(p.oid) = ''
              AND has_function_privilege('anon', p.oid, 'EXECUTE')
            ORDER BY 1 LOOP
    RAISE NOTICE '   % -> %', rpad(r.proname, 28), r.erg;
  END LOOP;

  SELECT id, status INTO v_zahlung, v_vorher FROM public.payments
   WHERE status <> 'PAID' LIMIT 1;
  SELECT id INTO v_meldung FROM public.payment_reports LIMIT 1;
  RAISE NOTICE '--- Probezahlung % (Stand %) ---', left(coalesce(v_zahlung,'-'),10), coalesce(v_vorher,'-');

  SET LOCAL ROLE anon;
  BEGIN
    PERFORM public.mark_payment_paid(v_zahlung, 'BAR', current_date);
    RAISE NOTICE 'anon mark_payment_paid     : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon mark_payment_paid     : abgewiesen (%)', left(SQLERRM, 52);
  END;
  IF v_meldung IS NOT NULL THEN
    BEGIN
      PERFORM public.decide_payment_report(v_meldung, true, 'probe');
      RAISE NOTICE 'anon decide_payment_report : DURCHGELASSEN -- LOCH';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'anon decide_payment_report : abgewiesen (%)', left(SQLERRM, 52);
    END;
  ELSE
    RAISE NOTICE 'anon decide_payment_report : keine Meldung vorhanden, nicht pruefbar';
  END IF;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT status INTO v_nachher FROM public.payments WHERE id = v_zahlung;
  RAISE NOTICE 'Stand der Zahlung nachher: % -- %', coalesce(v_nachher,'-'),
    CASE WHEN v_nachher IS NOT DISTINCT FROM v_vorher THEN 'unveraendert, richtig' ELSE 'VERAENDERT -- LOCH' END;

  -- Und als gewoehnliches Mitglied?
  SELECT u."authUserId", u.email INTO v_vorher, v_nachher FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='MEMBER' AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_vorher,'role','authenticated','email',v_nachher)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    PERFORM public.mark_payment_paid(v_zahlung, 'BAR', current_date);
    RAISE NOTICE 'Mitglied mark_payment_paid : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Mitglied mark_payment_paid : abgewiesen (%)', left(SQLERRM, 52);
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT count(*) INTO v_n FROM public.payments WHERE id = v_zahlung AND status = 'PAID';
  RAISE NOTICE 'Zahlung steht jetzt auf PAID? % (soll 0)', v_n;
END $$;
