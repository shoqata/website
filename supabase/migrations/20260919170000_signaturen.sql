DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args, p.prosecdef
             FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public'
              AND p.proname IN ('claim_my_profile','board_meeting_freigabe','book_payment_entries',
                                'mark_payment_paid','decide_payment_report','end_tenant_support',
                                'board_meeting_versionieren','my_neighborhood_contacts','submit_sponsor')
            ORDER BY 1 LOOP
    RAISE NOTICE '% (%) definer=%', rpad(r.proname,28), r.args, r.prosecdef;
  END LOOP;
END $$;
