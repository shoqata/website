DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT jobname, schedule, active FROM cron.job ORDER BY jobname LOOP
    RAISE NOTICE '  % | % | aktiv=%', rpad(r.jobname,26), rpad(r.schedule,14), r.active;
  END LOOP;
END $$;
