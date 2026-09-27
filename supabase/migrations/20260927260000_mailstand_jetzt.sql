DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT to_jsonb(m) - 'kennwort' - 'zeitplan_token' AS j FROM public.mail_settings m LOOP
    RAISE NOTICE 'Einstellung: %', r.j;
  END LOOP;
  FOR r IN SELECT status, "tenantId", attempts, left(coalesce("lastError",'-'),80) AS grund
             FROM public.mail_queue ORDER BY "tenantId" LOOP
    RAISE NOTICE '  % | % | Versuche % | %', rpad(r.status,8), rpad(r."tenantId",10), r.attempts, r.grund;
  END LOOP;
END $$;
