DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT status, "tenantId", attempts, left(coalesce("lastError",'-'),70) AS grund, "sentAt"
             FROM public.mail_queue ORDER BY status LOOP
    RAISE NOTICE '  % | % | Versuche % | gesendet % | %',
      rpad(r.status,8), rpad(coalesce(r."tenantId",'-'),10), r.attempts,
      coalesce(r."sentAt"::text,'nein'), r.grund;
  END LOOP;
END $$;
