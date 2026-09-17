-- Woran haengt is_member_manager()? Die Funktion steht in vielen Regeln; sie
-- zu aendern trifft alles auf einmal. Erst die Liste, dann der Eingriff.
DO $$
DECLARE r record; v_n int := 0;
BEGIN
  RAISE NOTICE '=== Regeln, die is_member_manager() verwenden ===';
  FOR r IN SELECT tablename, policyname, cmd FROM pg_policies
            WHERE schemaname='public'
              AND (coalesce(qual,'') LIKE '%is_member_manager%' OR coalesce(with_check,'') LIKE '%is_member_manager%')
            ORDER BY tablename, cmd LOOP
    RAISE NOTICE '  %.% [%]', r.tablename, r.policyname, r.cmd;
    v_n := v_n + 1;
  END LOOP;
  RAISE NOTICE '  insgesamt % Regeln', v_n;

  RAISE NOTICE '=== Funktionen, die is_member_manager() verwenden ===';
  FOR r IN SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.prosrc LIKE '%is_member_manager%' AND p.proname <> 'is_member_manager' LOOP
    RAISE NOTICE '  %', r.proname;
  END LOOP;

  RAISE NOTICE '=== Regeln auf neighborhoods ===';
  FOR r IN SELECT policyname, cmd, coalesce(qual,'-') AS q FROM pg_policies
            WHERE schemaname='public' AND tablename='neighborhoods' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%] USING %', r.policyname, r.cmd, r.q;
  END LOOP;
END $$;
