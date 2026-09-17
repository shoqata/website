-- Was gibt es fuer Nachbarschafts-Verantwortliche bereits?
DO $$
DECLARE r record; v text := '';
BEGIN
  FOR r IN SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema='public' AND table_name='neighborhoods' ORDER BY ordinal_position LOOP
    v := v || r.column_name || '(' || r.data_type || ') ';
  END LOOP;
  RAISE NOTICE 'neighborhoods: %', v;

  v := '';
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='payments' ORDER BY ordinal_position LOOP
    v := v || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'payments: %', v;

  RAISE NOTICE '=== Nachbarschaften und ihre Verantwortlichen ===';
  FOR r IN SELECT n.id, n.name,
                  (SELECT count(*) FROM public.users u WHERE u."neighborhoodId" = n.id) AS mitglieder
             FROM public.neighborhoods n ORDER BY n.name LOOP
    RAISE NOTICE '  % (%) -- % Mitglieder', r.name, r.id, r.mitglieder;
  END LOOP;

  RAISE NOTICE '=== Wer hat die Rolle REPRESENTATIVE / NEIGHBORHOOD_MANAGER ===';
  FOR r IN SELECT u."displayName", u.role, coalesce(u."neighborhoodId",'<keine>') AS nb, u.email
             FROM public.users u
            WHERE u.role IN ('REPRESENTATIVE','NEIGHBORHOOD_MANAGER') ORDER BY u.role LOOP
    RAISE NOTICE '  % [%] Nachbarschaft % -- %', r."displayName", r.role, r.nb, r.email;
  END LOOP;

  RAISE NOTICE '=== Regeln auf payments ===';
  FOR r IN SELECT policyname, cmd, coalesce(qual,'-') AS q, coalesce(with_check,'-') AS w
             FROM pg_policies WHERE schemaname='public' AND tablename='payments' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%]', r.policyname, r.cmd;
    RAISE NOTICE '      USING %', r.q;
    RAISE NOTICE '      CHECK %', r.w;
  END LOOP;
END $$;
