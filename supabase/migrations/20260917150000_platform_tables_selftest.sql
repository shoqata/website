-- Nachweis der Rechte: nur der Plattformbetreiber sieht Interessenten und
-- Plattformrechnungen. Ein Vereinsadministrator darf nichts davon sehen.
DO $$
DECLARE
  v_back text := current_user;
  v_owner uuid; v_owner_mail text; v_admin uuid; v_admin_mail text;
  v_cnt int; v_lead uuid;
BEGIN
  SELECT u."authUserId", u.email INTO v_owner, v_owner_mail
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email) = lower(u.email)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;
  IF v_owner IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Betreiber.'; RETURN; END IF;
  RAISE NOTICE 'Betreiber: %', v_owner_mail;

  -- als Betreiber
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_owner::text,'role','authenticated','email',v_owner_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  INSERT INTO public.platform_leads (name, "contactName", stage, "expectedMembers", note)
  VALUES ('Selbsttest Verein','Testperson','LEAD',120,'Von der Migration angelegt')
  RETURNING id INTO v_lead;
  RAISE NOTICE '1 Betreiber legt Interessenten an: ok (%)', v_lead;

  UPDATE public.platform_leads SET stage='TALKS' WHERE id = v_lead;
  RAISE NOTICE '2 Betreiber verschiebt in Gespraeche: ok';

  INSERT INTO public.platform_invoices ("tenantId", kind, amount, year, status)
  VALUES ('koretini','SETUP', 900, 2026, 'DRAFT');
  RAISE NOTICE '3 Betreiber legt Einrichtungsgebuehr an: ok';

  SELECT count(*) INTO v_cnt FROM public.platform_invoices;
  RAISE NOTICE '4 Betreiber sieht Plattformrechnungen: %', v_cnt;

  EXECUTE format('SET ROLE %I', v_back);

  -- Gegenprobe: Vereinsadministrator ohne Betreiberrechte
  SELECT u."authUserId", u.email INTO v_admin, v_admin_mail
    FROM public.users u
   WHERE u.role IN ('ADMIN','BOARD') AND u."authUserId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.platform_admins pa WHERE lower(pa.email)=lower(u.email))
   LIMIT 1;

  IF v_admin IS NULL THEN
    RAISE NOTICE '5 Gegenprobe: kein Vereinsadministrator ohne Betreiberrechte vorhanden, nicht pruefbar.';
  ELSE
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_admin::text,'role','authenticated','email',v_admin_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT count(*) INTO v_cnt FROM public.platform_leads;
    RAISE NOTICE '5 Vereinsadmin (%) sieht Interessenten: % -- erwartet 0', v_admin_mail, v_cnt;
    SELECT count(*) INTO v_cnt FROM public.platform_invoices;
    RAISE NOTICE '6 Vereinsadmin sieht Plattformrechnungen: % -- erwartet 0', v_cnt;
    EXECUTE format('SET ROLE %I', v_back);
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.platform_leads WHERE name='Selbsttest Verein';
  DELETE FROM public.platform_invoices WHERE note IS NULL AND kind='SETUP' AND amount=900 AND year=2026;
  RAISE NOTICE 'Testdaten entfernt.';
END $$;
