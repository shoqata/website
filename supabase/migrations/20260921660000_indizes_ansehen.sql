DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT indexname, indexdef FROM pg_indexes
            WHERE schemaname='public'
              AND indexname IN ('accounting_accounts_code_key','mail_queue_once_per_year',
                                'payment_reports_one_open','board_meeting_versions_eindeutig') LOOP
    RAISE NOTICE '  %', r.indexdef;
  END LOOP;
END $$;
