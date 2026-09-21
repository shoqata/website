DO $$
DECLARE v_n int; v_g int; v_chf numeric; r record;
BEGIN
  RAISE NOTICE '=== Erreichbarkeit der Mitglieder ===';
  SELECT count(*) INTO v_g FROM public.users;
  SELECT count(*) INTO v_n FROM public.users WHERE "authUserId" IS NOT NULL;
  RAISE NOTICE '  koennen sich anmelden        % von %', v_n, v_g;
  SELECT count(*) INTO v_n FROM public.users
   WHERE coalesce(email,'')<>'' AND email NOT ILIKE '%@koretini.legacy' AND email NOT ILIKE '%no-email-%';
  RAISE NOTICE '  echte E-Mail-Adresse         % von %', v_n, v_g;
  SELECT count(*) INTO v_n FROM public.users WHERE birthdate IS NULL OR btrim(birthdate)='';
  RAISE NOTICE '  ohne Geburtsdatum            % von %', v_n, v_g;

  RAISE NOTICE '=== Post ===';
  SELECT count(*) FILTER (WHERE status='PENDING'), count(*) FILTER (WHERE status='SENT')
    INTO v_n, v_g FROM public.mail_queue;
  RAISE NOTICE '  Warteschlange                % offen, % versandt', v_n, v_g;
  FOR r IN SELECT "tenantId", host, port, tls, coalesce(btrim(kennwort),'')<>'' AS kw, aktiv
             FROM public.mail_settings LOOP
    RAISE NOTICE '  Postausgang % : % : % / % | Kennwort % | aktiv %',
      rpad(r."tenantId",10), r.host, r.port, r.tls, r.kw, r.aktiv;
  END LOOP;
  SELECT count(*) INTO v_n FROM public.mail_queue q
   WHERE q.status='PENDING' AND NOT EXISTS (
     SELECT 1 FROM public.mail_settings m WHERE m."tenantId"=q."tenantId"
       AND m.aktiv AND coalesce(btrim(m.kennwort),'')<>'');
  RAISE NOTICE '  ohne Postausgang liegen      % Nachrichten', v_n;

  RAISE NOTICE '=== Rechnungen und Spenden ===';
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_chf FROM public.payments WHERE status='PENDING';
  RAISE NOTICE '  offene Rechnungen            % ueber % CHF', v_n, v_chf;
  SELECT count(*) INTO v_n FROM public.payments WHERE coalesce(btrim(reference),'')='';
  RAISE NOTICE '  ohne Referenznummer          %', v_n;
  SELECT count(*) INTO v_n FROM public.donations;
  RAISE NOTICE '  Spenden erfasst              %', v_n;

  RAISE NOTICE '=== Marktplatz ===';
  FOR r IN SELECT status, count(*) AS n FROM public.modules GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  Module %: %', rpad(r.status,12), r.n;
  END LOOP;

  RAISE NOTICE '=== Soziale Medien ===';
  SELECT count(*) INTO v_n FROM public.socialmediaposts WHERE status='SCHEDULED';
  RAISE NOTICE '  geplante Beitraege, die niemand abholt  %', v_n;

  RAISE NOTICE '=== Kontenplan ===';
  SELECT count(*) INTO v_n FROM public.accounting_accounts WHERE name ILIKE '%spende%';
  RAISE NOTICE '  Konten mit "Spende" im Namen  % (Dublette 3200/3400)', v_n;

  RAISE NOTICE '=== Nachbarschaften ===';
  SELECT count(*) INTO v_n FROM public.neighborhoods n
   WHERE NOT EXISTS (SELECT 1 FROM public.users u
                      WHERE n."contactPersonIds" @> to_jsonb(u.id)
                         OR n."representativeId"=u.id OR n."managerId"=u.id);
  RAISE NOTICE '  ohne verantwortliche Person   % von %', v_n, (SELECT count(*) FROM public.neighborhoods);

  RAISE NOTICE '=== Zeitplaene ===';
  FOR r IN SELECT jobname, schedule, active FROM cron.job ORDER BY jobname LOOP
    RAISE NOTICE '  % | % | aktiv %', rpad(r.jobname,24), rpad(r.schedule,14), r.active;
  END LOOP;
END $$;
