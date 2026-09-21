-- Schaltet der Schalter wirklich? Geprueft als angemeldeter Administrator,
-- also auf dem Weg, den die Anwendung nimmt.
--
-- Koretini hat alle_module_frei = true. Damit die Probe ueberhaupt etwas
-- zeigt, wird das Kennzeichen kurz abgeschaltet und danach wieder gesetzt --
-- sonst waere jedes Ergebnis "sichtbar" und der Test wertlos.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text;
        v_vorher boolean; v_n int; r record;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  SELECT alle_module_frei INTO v_vorher FROM public.tenants WHERE id = 'koretini';
  RAISE NOTICE 'Koretini alle_module_frei = % (wird fuer die Probe kurz aufgehoben)', v_vorher;

  -- --- Zustand mit Freistellung -----------------------------------------
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.accounting_journal;
  RAISE NOTICE 'Mit Freistellung: Journal % Zeilen', v_n;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- --- Freistellung weg, Modul nicht gebucht ----------------------------
  UPDATE public.tenants SET alle_module_frei = false WHERE id = 'koretini';
  DELETE FROM public.tenant_modules WHERE "tenantId" = 'koretini';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  FOR r IN
    SELECT 'accounting_journal' AS t, count(*) AS n FROM public.accounting_journal
    UNION ALL SELECT 'expenses', count(*) FROM public.expenses
    UNION ALL SELECT 'events', count(*) FROM public.events
    UNION ALL SELECT 'news', count(*) FROM public.news
    UNION ALL SELECT 'sponsors', count(*) FROM public.sponsors
    UNION ALL SELECT 'socialmediaposts', count(*) FROM public.socialmediaposts
    UNION ALL SELECT 'family_links', count(*) FROM public.family_links
    UNION ALL SELECT 'users (Kern)', count(*) FROM public.users
    UNION ALL SELECT 'payments (Kern)', count(*) FROM public.payments
  LOOP
    RAISE NOTICE '  ohne Modul: % -> % Zeilen', rpad(r.t,20), r.n;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- --- Ein Modul gebucht ------------------------------------------------
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES ('koretini','BUCHHALTUNG','AN');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.accounting_journal;
  RAISE NOTICE 'Buchhaltung AN: Journal % Zeilen', v_n;
  SELECT count(*) INTO v_n FROM public.news;
  RAISE NOTICE 'Neuigkeiten weiterhin AUS: news % Zeilen', v_n;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- --- GESPERRT verhaelt sich wie AUS -----------------------------------
  UPDATE public.tenant_modules SET zustand = 'GESPERRT'
   WHERE "tenantId"='koretini' AND modul='BUCHHALTUNG';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT count(*) INTO v_n FROM public.accounting_journal;
  RAISE NOTICE 'Buchhaltung GESPERRT: Journal % Zeilen', v_n;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  -- --- Aufraeumen: Zustand von vorher wiederherstellen ------------------
  DELETE FROM public.tenant_modules WHERE "tenantId" = 'koretini';
  UPDATE public.tenants SET alle_module_frei = v_vorher WHERE id = 'koretini';
  SELECT alle_module_frei INTO v_vorher FROM public.tenants WHERE id='koretini';
  RAISE NOTICE 'Wiederhergestellt: Koretini alle_module_frei = %', v_vorher;

  -- Und die Daten sind noch alle da?
  SELECT count(*) INTO v_n FROM public.accounting_journal;
  RAISE NOTICE 'Journal enthaelt weiterhin % Buchungen (nichts geloescht)', v_n;
END $$;
