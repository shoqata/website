DO $$ DECLARE v text; BEGIN
  SELECT wert INTO v FROM public.platform_secrets WHERE schluessel='social_cron_token';
  RAISE NOTICE 'TOKEN=%', v;
END $$;
