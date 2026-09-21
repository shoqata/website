-- Drei Karteileichen aus koretini entfernen.
--
-- Gemessen am 21.09.2026: drei Mitglieder standen doppelt. Der Zusatz in der
-- E-Mail ist jeweils der Anfang der Zeilen-id --
--   IzziI1TF... -> valton.rexha_IzziI@gmail.com
--   dIozegHn... -> qazim_dIoze@dervishi.ch
--   w23ECDS4... -> ledion_w23EC@dervishi.ch
-- So macht ein Import eine E-Mail eindeutig, die beim Einspielen schon
-- vergeben war. Telefon, Adresse und Nachbarschaft stimmen mit der echten
-- Zeile ueberein; die Dublette steht auf INACTIVE, die echte auf ACTIVE.
--
-- An den Dubletten haengt nur eine einzige Zeile: Rechnung INV-18027322 ueber
-- CHF 120 auf Valton Rexha, offen. Auf seiner echten Zeile steht fuer
-- dasselbe Jahr INV-18027321, bezahlt. Das ist also keine Forderung, sondern
-- eine Doppelverrechnung. Sie wird nicht geloescht, sondern auf die echte
-- Zeile umgehaengt und storniert: eine Rechnungsnummer, die spurlos
-- verschwindet, hinterlaesst eine Luecke, die spaeter niemand mehr erklaeren
-- kann. Gebucht war nichts (bookedInJournal = false), es ist also keine
-- Gegenbuchung noetig.
DO $$
DECLARE
  v_ids   text[];
  v_valton text;
  v_n     int;
  v_offen_vor int; v_offen_nach int; v_mit_vor int; v_mit_nach int;
  r record;
BEGIN
  SELECT array_agg(id) INTO v_ids FROM public.users
   WHERE "tenantId"='koretini'
     AND email IN ('valton.rexha_IzziI@gmail.com','qazim_dIoze@dervishi.ch','ledion_w23EC@dervishi.ch');
  IF v_ids IS NULL OR array_length(v_ids,1) <> 3 THEN
    RAISE NOTICE 'Nichts zu tun -- gefunden: %', coalesce(array_length(v_ids,1),0);
    RETURN;
  END IF;

  SELECT id INTO v_valton FROM public.users
   WHERE "tenantId"='koretini' AND lower(email)='valton.rexha@gmail.com';
  IF v_valton IS NULL THEN
    RAISE EXCEPTION 'Die echte Zeile von Valton Rexha fehlt -- dann wird hier nichts umgehaengt.';
  END IF;

  SELECT count(*) INTO v_offen_vor FROM public.payments WHERE "tenantId"='koretini' AND status='PENDING';
  SELECT count(*) INTO v_mit_vor   FROM public.users    WHERE "tenantId"='koretini';

  -- 1. Der vollstaendige Inhalt wird festgehalten, bevor er verschwindet.
  FOR r IN SELECT to_jsonb(u) AS j, u.id, coalesce(u."displayName", u.email) AS wer
             FROM public.users u WHERE u.id = ANY(v_ids) LOOP
    INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
    VALUES (gen_random_uuid(), 'koretini', 'DATA_CLEANUP', 'DUPLICATE_REMOVED', r.id,
            jsonb_build_object('grund','Dublette mit id-Zusatz in der E-Mail','zeile', r.j),
            now(), now());
    RAISE NOTICE '  festgehalten: %', r.wer;
  END LOOP;

  -- 2. Die doppelte Rechnung umhaengen und stornieren.
  UPDATE public.payments
     SET "userId" = v_valton,
         status = 'CANCELLED',
         description = coalesce(description,'') ||
           ' -- storniert am 21.09.2026: Doppelverrechnung, INV-18027321 desselben Jahres ist bezahlt'
   WHERE "userId" = ANY(v_ids);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '  Rechnungen umgehaengt und storniert: %', v_n;

  -- 3. Jetzt haengt nichts mehr daran.
  DELETE FROM public.users WHERE id = ANY(v_ids);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '  Zeilen entfernt: %', v_n;

  SELECT count(*) INTO v_offen_nach FROM public.payments WHERE "tenantId"='koretini' AND status='PENDING';
  SELECT count(*) INTO v_mit_nach   FROM public.users    WHERE "tenantId"='koretini';
  RAISE NOTICE '--- Mitglieder % -> % | offene Rechnungen % -> % ---',
    v_mit_vor, v_mit_nach, v_offen_vor, v_offen_nach;

  SELECT count(*) INTO v_n FROM public.users WHERE email ~ '_[A-Za-z0-9]{4,6}@'
     AND email !~ '^[a-z]+_[a-z]+@';
  RAISE NOTICE '--- Zeilen mit id-Zusatz in der E-Mail uebrig: % ---', v_n;
END $$;
