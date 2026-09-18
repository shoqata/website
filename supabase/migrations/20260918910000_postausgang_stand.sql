DO $$
DECLARE r record; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.mail_settings;
  RAISE NOTICE 'Eintraege im Postausgang: %', v_n;
  FOR r IN SELECT "tenantId", host, port, benutzer, absender, tls, aktiv,
                  coalesce(btrim(kennwort),'') <> '' AS kennwort_da, geaendert_am
             FROM public.mail_settings LOOP
    RAISE NOTICE '  Verein % | Host % | Port % | TLS % | aktiv % | Kennwort %',
      r."tenantId", coalesce(r.host,'(leer)'), r.port, r.tls, r.aktiv, r.kennwort_da;
  END LOOP;
END $$;
