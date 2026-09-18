-- Was kann ein anonymer Besucher tatsaechlich ausloesen?
-- Die Ausfuehrungsrechte allein sagen wenig -- entscheidend ist, ob die
-- Funktion selbst prueft. Also wird sie aufgerufen.
DO $$
DECLARE v_back text := current_user; v_n int;
BEGIN
  SET LOCAL ROLE anon;

  BEGIN
    PERFORM public.create_tenant('probe-anon', 'Probe', 'probe@example.invalid');
    RAISE NOTICE 'create_tenant            : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'create_tenant            : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.mark_payment_paid((SELECT id FROM public.payments LIMIT 1));
    RAISE NOTICE 'mark_payment_paid        : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'mark_payment_paid        : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.claim_my_profile('probe@example.invalid');
    RAISE NOTICE 'claim_my_profile         : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'claim_my_profile         : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.start_tenant_support('koretini');
    RAISE NOTICE 'start_tenant_support     : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'start_tenant_support     : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.decide_payment_report(
      (SELECT id FROM public.payment_reports LIMIT 1), true, 'probe');
    RAISE NOTICE 'decide_payment_report    : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'decide_payment_report    : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.board_meeting_freigabe((SELECT id FROM public.board_meetings LIMIT 1), true);
    RAISE NOTICE 'board_meeting_freigabe   : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'board_meeting_freigabe   : abgewiesen (%)', left(SQLERRM, 46);
  END;

  BEGIN
    PERFORM public.book_payment_entries((SELECT id FROM public.payments LIMIT 1));
    RAISE NOTICE 'book_payment_entries     : DURCHGELASSEN -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'book_payment_entries     : abgewiesen (%)', left(SQLERRM, 46);
  END;

  EXECUTE format('SET ROLE %I', v_back);

  SELECT count(*) INTO v_n FROM public.tenants WHERE id = 'probe-anon';
  RAISE NOTICE 'Probeverein angelegt? % (soll 0)', v_n;
  DELETE FROM public.tenants WHERE id = 'probe-anon';
END $$;
