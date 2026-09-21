-- Ein Verein wird angelegt, arbeitet, und wird wieder entfernt.
-- Die Probe schlaegt fehl, wenn irgendetwas fehlt -- dann rollt alles
-- zurueck, und das Ergebnis ist trotzdem sichtbar.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text; r record;
        v_fehler int := 0; v_vorher int; v_spende uuid;
BEGIN
  SELECT count(*) INTO v_vorher FROM public.accounting_journal;
  SELECT p.email, a.id::text INTO v_mail, v_uid FROM public.platform_admins p
    JOIN auth.users a ON lower(a.email)=lower(p.email) LIMIT 1;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  SELECT public.create_tenant('Probeverein Musterdorf','probeverein',
         'probe.example.invalid','admin@probe.example.invalid') INTO v_id;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
  RAISE NOTICE 'Angelegt: %', v_id;

  FOR r IN
    SELECT 'Administrator' AS t, (SELECT count(*) FROM public.users WHERE "tenantId"=v_id) AS n, 1 AS soll
    UNION ALL SELECT 'Domain', (SELECT count(*) FROM public.tenant_domains WHERE "tenantId"=v_id), 1
    UNION ALL SELECT 'Einstellungen', (SELECT count(*) FROM public.settings WHERE "tenantId"=v_id), 3
    UNION ALL SELECT 'Kontenplan', (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"=v_id), 14
    UNION ALL SELECT 'Geschaeftsjahr', (SELECT count(*) FROM public.fiscal_years WHERE "tenantId"=v_id), 1
  LOOP
    RAISE NOTICE '  % % von %  %', rpad(r.t,16), lpad(r.n::text,3), lpad(r.soll::text,3),
      CASE WHEN r.n >= r.soll THEN 'gut' ELSE 'FEHLT' END;
    IF r.n < r.soll THEN v_fehler := v_fehler + 1; END IF;
  END LOOP;

  RAISE NOTICE '--- Kann er arbeiten? ---';
  BEGIN
    INSERT INTO public.accounting_journal
      (id,"tenantId",date,description,amount,"debitCode","creditCode","isSystemEntry","createdAt")
    VALUES (gen_random_uuid()::text, v_id, current_date::text,'Probebuchung',10,'1020','3200',true,now());
    RAISE NOTICE '  Buchung 1020/3200: angelegt';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Buchung scheitert: % -- FEHLER', left(SQLERRM,70); v_fehler := v_fehler+1; END;

  -- Und bucht er wirklich auf SEIN Konto, nicht auf Koretinis?
  BEGIN
    INSERT INTO public.accounting_journal
      (id,"tenantId",date,description,amount,"debitCode","creditCode","isSystemEntry","createdAt")
    VALUES (gen_random_uuid()::text, v_id, current_date::text,'Fremdes Konto',10,'3400','3200',true,now());
    RAISE NOTICE '  Buchung auf Koretinis Konto 3400: DURCHGELASSEN -- LOCH';
    v_fehler := v_fehler + 1;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Buchung auf Koretinis Konto 3400: abgewiesen -- richtig'; END;

  -- Sieht Koretini etwas vom neuen Verein?
  RAISE NOTICE '  Konten bei Koretini weiterhin: % (soll 21)',
    (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"='koretini');

  DELETE FROM public.accounting_journal WHERE "tenantId"=v_id;
  DELETE FROM public.accounting_accounts WHERE "tenantId"=v_id;
  DELETE FROM public.fiscal_years WHERE "tenantId"=v_id;
  DELETE FROM public.settings WHERE "tenantId"=v_id;
  DELETE FROM public.users WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_domains WHERE "tenantId"=v_id;
  DELETE FROM public.tenant_modules WHERE "tenantId"=v_id;
  DELETE FROM public.tenants WHERE id=v_id;

  RAISE NOTICE 'Entfernt. Vereine %, Journal % (vorher %)',
    (SELECT count(*) FROM public.tenants),
    (SELECT count(*) FROM public.accounting_journal), v_vorher;
  IF v_fehler > 0 THEN RAISE EXCEPTION '% Maengel', v_fehler; END IF;
  RAISE NOTICE 'Keine Maengel.';
END $$;
