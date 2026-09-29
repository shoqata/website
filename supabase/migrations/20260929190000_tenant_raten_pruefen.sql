-- Der Ausloeser setzt COALESCE(current_tenant(), 'koretini'). Solange es
-- einen Verein gab, war das harmlos. Mit mehreren ist es ein Loch: anon darf
-- auf event_registrations schreiben, und dort ist current_tenant() immer
-- NULL -- eine Anmeldung auf der Seite eines anderen Vereins landete damit
-- bei Koretini. Das wird hier gemessen, nicht behauptet.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_wo text; v_ev text;
BEGIN
  SELECT pa.email INTO v_mail FROM public.platform_admins pa LIMIT 1;
  SELECT u."authUserId" INTO v_uid FROM public.users u WHERE lower(u.email)=lower(v_mail) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  PERFORM public.create_tenant('Probe Fremdverein', NULL, 'probe-fremd.example.org', NULL);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Ein Anlass beim fremden Verein
  INSERT INTO public.events (id, "tenantId", title, date, status)
  VALUES ('probe-fremd-anlass','probe-fremdverein','Probeanlass', (current_date+10)::text, 'PUBLISHED');

  -- Ein Besucher auf dessen Domain meldet sich an
  PERFORM set_config('request.headers',
    json_build_object('origin','https://probe-fremd.example.org')::text, false);
  EXECUTE 'SET ROLE anon';
  BEGIN
    INSERT INTO public.event_registrations (id, "eventId", name, email)
    VALUES ('probe-anmeldung','probe-fremd-anlass','Probe Gast','gast@example.org');
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  (Anmeldung abgewiesen: %)', left(SQLERRM,60);
  END;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT "tenantId" INTO v_wo FROM public.event_registrations WHERE id='probe-anmeldung';
  RAISE NOTICE 'Anmeldung auf probe-fremd.example.org landete bei: %', coalesce(v_wo,'(keine Zeile)');
  RAISE NOTICE '  -> erwartet waere probe-fremdverein';

  DELETE FROM public.event_registrations WHERE id='probe-anmeldung';
  DELETE FROM public.events WHERE id='probe-fremd-anlass';
  PERFORM set_config('request.headers', NULL, false);
END $$;
