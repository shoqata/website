DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_n int; r record;
BEGIN
  -- Eine Probezeile mit einem erkennbaren Token.
  INSERT INTO public.social_connections ("tenantId", plattform, konto_id, konto_name,
                                         zugriffstoken, zustand, verbunden_am)
  VALUES ('koretini','FACEBOOK','111','Probe-Seite','GEHEIM-PROBE-TOKEN','AKTIV', now())
  ON CONFLICT ("tenantId", plattform) DO UPDATE SET zugriffstoken='GEHEIM-PROBE-TOKEN';

  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    SELECT count(*) INTO v_n FROM public.social_connections;
    RAISE NOTICE '  Administrator liest die Tabelle direkt: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  Administrator liest die Tabelle direkt: nein (%)', left(SQLERRM,44);
  END;

  FOR r IN SELECT * FROM public.social_verbindungen() LOOP
    RAISE NOTICE '  ueber social_verbindungen(): % / % / %', r.plattform, r.konto_name, r.zustand;
  END LOOP;

  -- Steht der Token irgendwo in der Ausgabe?
  SELECT count(*) INTO v_n FROM public.social_verbindungen() v
   WHERE v::text ILIKE '%GEHEIM-PROBE%';
  RAISE NOTICE '  Token in der Ausgabe enthalten: %', CASE WHEN v_n>0 THEN 'JA -- LOCH' ELSE 'nein' END;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.social_connections WHERE zugriffstoken = 'GEHEIM-PROBE-TOKEN';
  RAISE NOTICE '  Probezeile entfernt.';
END $$;
