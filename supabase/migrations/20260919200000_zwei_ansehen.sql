DO $$
DECLARE v_t text;
BEGIN
  SELECT prosrc INTO v_t FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='claim_my_profile';
  RAISE NOTICE '--- claim_my_profile ---';
  RAISE NOTICE '%', left(v_t, 900);

  SELECT prosrc INTO v_t FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='decide_payment_report';
  RAISE NOTICE '--- decide_payment_report (erste Zeilen) ---';
  RAISE NOTICE '%', left(v_t, 700);
END $$;
