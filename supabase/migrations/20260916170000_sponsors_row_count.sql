-- Kontrolle: keine Testzeilen mehr in sponsors.
DO $$
DECLARE v_cnt int; r record;
BEGIN
  SELECT count(*) INTO v_cnt FROM public.sponsors;
  RAISE NOTICE 'Sponsorenanfragen insgesamt: %', v_cnt;
  FOR r IN SELECT company, email, status, "createdAt" FROM public.sponsors ORDER BY "createdAt" DESC LIMIT 10 LOOP
    RAISE NOTICE '  % | % | % | %', r.company, r.email, r.status, r."createdAt";
  END LOOP;
END $$;
