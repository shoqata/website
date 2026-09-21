-- Diesmal wird gezaehlt, nicht auf einen Fehler gewartet: ein UPDATE, das
-- durch die Zeilenregel keine Zeile trifft, laeuft ohne Fehler durch.
DO $$
DECLARE v_back text := current_user; r record; v_n int; v_staff boolean;
BEGIN
  FOR r IN SELECT u."authUserId" AS uid, u.email, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL ORDER BY 3,2 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT public.is_staff() INTO v_staff;
    UPDATE public.settings SET payment = payment WHERE id='payment';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
    RAISE NOTICE '  % (%) | is_staff % | geschriebene Zeilen %',
      rpad(left(r.email,26),26), rpad(r.rolle,11), v_staff, v_n;
  END LOOP;
END $$;
