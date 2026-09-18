DO $$
DECLARE r record; v_n int;
BEGIN
  FOR r IN SELECT status, count(*) AS n FROM public.mail_queue GROUP BY 1 LOOP
    RAISE NOTICE 'Warteschlange %: %', rpad(coalesce(r.status,'(leer)'),9), r.n;
  END LOOP;

  FOR r IN SELECT id::text AS id, "tenantId", recipient, status,
                  coalesce("lastError",'') AS fehler, coalesce(attempts,0) AS versuche
             FROM public.mail_queue ORDER BY "createdAt" DESC LIMIT 4 LOOP
    RAISE NOTICE '  Verein % | an % | % | %. Versuch | %',
      coalesce(nullif(r."tenantId",''), '>>>LEER<<<'), rpad(left(r.recipient,26),26),
      rpad(r.status,8), r.versuche, left(r.fehler, 90);
  END LOOP;

  RAISE NOTICE '--- Rechte auf mail_settings ---';
  FOR r IN SELECT grantee, string_agg(privilege_type, '/' ORDER BY privilege_type) AS rechte
             FROM information_schema.role_table_grants
            WHERE table_schema='public' AND table_name='mail_settings'
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  % darf %', rpad(r.grantee,16), r.rechte;
  END LOOP;

  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='mail_settings' AND grantee='service_role';
  IF v_n = 0 THEN
    RAISE NOTICE '>>> service_role hat keinerlei Recht -- die Funktion sieht die Zeile nicht.';
  END IF;
END $$;
