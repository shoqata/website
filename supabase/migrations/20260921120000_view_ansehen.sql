DO $$
DECLARE v_def text;
BEGIN
  SELECT pg_get_viewdef('public.public_settings'::regclass, true) INTO v_def;
  RAISE NOTICE 'public_settings:';
  RAISE NOTICE '%', v_def;
END $$;
