-- Haelt die Trennung zwischen Vereinen?
--
-- Bisher gibt es nur einen Verein, weshalb sich das nie pruefen liess -- ich
-- habe mehrfach darauf hingewiesen. Hier wird ein zweiter angelegt, samt
-- Mitglied, Rechnung, Nachbarschaft und Protokoll, und anschliessend
-- gemessen, was die Administration von koretini davon sieht. Danach wird alles
-- wieder entfernt.
--
-- joinedAt ist ein Zeitstempel, kein Text -- das hatte ich zunaechst
-- angenommen und der erste Lauf scheiterte daran.
DO $$
DECLARE
  v_back text := current_user;
  v_admin_uid text; v_admin_mail text;
  v_fremd text := 'pruefverein';
  v_fremd_user text := 'pruefverein-mitglied';
  v_n int; v_err text;
BEGIN
  SELECT u."authUserId", u.email INTO v_admin_uid, v_admin_mail
    FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN','BOARD') AND u."authUserId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.platform_admins pa WHERE lower(pa.email)=lower(u.email))
   LIMIT 1;
  IF v_admin_uid IS NULL THEN
    RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Vereinsverantwortlicher ohne Betreiberrechte.'; RETURN;
  END IF;
  RAISE NOTICE 'Geprueft aus Sicht von % (koretini)', v_admin_mail;

  -- Zweiten Verein anlegen
  INSERT INTO public.tenants (id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt")
  VALUES (v_fremd, 'Pruefverein', v_fremd, 'FREE', 'ACTIVE', now());
  INSERT INTO public.tenant_domains ("tenantId", domain) VALUES (v_fremd, 'pruefverein.invalid');
  INSERT INTO public.neighborhoods (id, "tenantId", name) VALUES ('pruefverein-nb', v_fremd, 'Fremde Nachbarschaft');
  INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
  VALUES (v_fremd_user, v_fremd, 'fremd@pruefverein.invalid', 'MEMBER', 'ACTIVE', 'Fremdes Mitglied', now());
  INSERT INTO public.payments (id, "tenantId", "userId", amount, currency, status, "billingYear", type, "invoiceNumber", "timestamp")
  VALUES ('pruefverein-rechnung', v_fremd, v_fremd_user, 999, 'CHF', 'PENDING', 2026, 'FEE', 'FREMD-1', now());
  INSERT INTO public.board_meetings (id, "tenantId", title, date, "publishedToMembers")
  VALUES ('pruefverein-protokoll', v_fremd, 'Fremdes Protokoll', current_date::text, true);
  INSERT INTO public.settings (id, "tenantId", payment)
  VALUES ('pruefverein-settings', v_fremd, '{"paypalSecret":"GEHEIM-FREMD","iban":"CH99"}'::jsonb)
  ON CONFLICT (id) DO NOTHING;
  RAISE NOTICE 'Zweiter Verein samt Daten angelegt.';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin_uid, 'role','authenticated','email', v_admin_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT count(*) INTO v_n FROM public.users WHERE "tenantId" = v_fremd;
  RAISE NOTICE '1 fremde Mitglieder sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.payments WHERE "tenantId" = v_fremd;
  RAISE NOTICE '2 fremde Rechnungen sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.neighborhoods WHERE "tenantId" = v_fremd;
  RAISE NOTICE '3 fremde Nachbarschaften sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.board_meetings WHERE "tenantId" = v_fremd;
  RAISE NOTICE '4 fremdes Protokoll sichtbar (obwohl freigegeben): % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.settings WHERE "tenantId" = v_fremd;
  RAISE NOTICE '5 fremde Einstellungen sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.tenants WHERE id = v_fremd;
  RAISE NOTICE '6 fremder Verein sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.platform_leads;
  RAISE NOTICE '7 Interessenten der Plattform sichtbar: % -- erwartet 0', v_n;

  SELECT count(*) INTO v_n FROM public.platform_invoices;
  RAISE NOTICE '8 Plattformrechnungen sichtbar: % -- erwartet 0', v_n;

  -- Schreiben in den fremden Verein
  BEGIN
    UPDATE public.users SET "displayName" = 'Uebernommen' WHERE "tenantId" = v_fremd;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '9 fremde Mitglieder geaendert: % -- erwartet 0', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '9 fremde Mitglieder aendern: abgewiesen -- richtig';
  END;

  BEGIN
    PERFORM public.reset_member_password(v_fremd_user);
    RAISE NOTICE '10 Passwort im fremden Verein gesetzt: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '10 Passwort im fremden Verein: abgewiesen -- richtig';
  END;

  BEGIN
    PERFORM public.mark_payment_paid('pruefverein-rechnung');
    RAISE NOTICE '11 fremde Rechnung gebucht: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '11 fremde Rechnung buchen: abgewiesen -- richtig';
  END;

  BEGIN
    PERFORM public.start_tenant_support(v_fremd, 'Versuch');
    RAISE NOTICE '12 Betreuung des fremden Vereins gestartet: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '12 Betreuung des fremden Vereins starten: abgewiesen -- richtig';
  END;

  BEGIN
    PERFORM public.create_tenant('Noch ein Verein', 'noch-einer', 'noch-einer.invalid', NULL);
    RAISE NOTICE '13 eigenen Verein angelegt: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '13 Verein anlegen: abgewiesen -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- Aufraeumen
  DELETE FROM public.board_meeting_versions WHERE "meetingId" = 'pruefverein-protokoll';
  DELETE FROM public.board_meetings WHERE "tenantId" = v_fremd;
  DELETE FROM public.accounting_journal WHERE "tenantId" = v_fremd;
  DELETE FROM public.payments WHERE "tenantId" = v_fremd;
  DELETE FROM public.users WHERE "tenantId" = v_fremd;
  DELETE FROM public.neighborhoods WHERE "tenantId" = v_fremd;
  DELETE FROM public.settings WHERE "tenantId" = v_fremd;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_fremd;
  DELETE FROM public.tenants WHERE id IN (v_fremd, 'noch-einer');
  RAISE NOTICE 'Pruefverein vollstaendig entfernt: % Vereine bleiben.',
    (SELECT count(*) FROM public.tenants);
END $$;
