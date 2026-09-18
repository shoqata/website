-- Braucht es wirklich mehrere Rollen?
--
-- SUPER_ADMIN steht in jeder Pruefung ueber BOARD. Wenn das so ist, deckt die
-- eine Zeile die andere ohnehin ab, und es braucht keine Mehrfachrolle -- nur
-- das Loeschen der ueberzaehligen Zeilen. Zugleich: woran haengen die Zeilen?
DO $$
DECLARE r record; z text; v_n int;
BEGIN
  RAISE NOTICE '=== is_staff() ===';
  FOR r IN SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname='is_staff' LOOP
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', z; END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE '=== Wo taucht die Rolle BOARD im Code der Datenbank auf? ===';
  FOR r IN SELECT tablename, policyname FROM pg_policies
            WHERE schemaname='public'
              AND (coalesce(qual,'') LIKE '%BOARD%' OR coalesce(with_check,'') LIKE '%BOARD%')
            ORDER BY tablename LOOP
    RAISE NOTICE '   %.%', r.tablename, r.policyname;
  END LOOP;

  RAISE NOTICE '=== Woher kommt die oeffentliche Vorstandsliste? ===';
  SELECT count(*) INTO v_n FROM public.board_members;
  RAISE NOTICE '   board_members: % Eintraege', v_n;
  FOR r IN SELECT bm.* FROM public.board_members bm LIMIT 8 LOOP
    RAISE NOTICE '   %', to_jsonb(r)::text;
  END LOOP;

  RAISE NOTICE '=== Die drei Zeilen Burim Dervishi und ihre Rechnungen ===';
  FOR r IN
    SELECT u.id, u.email, u.role,
           p.id AS zahlung, p."invoiceNumber", p.amount, p.currency,
           p.status, p."billingYear", p.type, coalesce(p."paidAt",'-') AS bezahlt_am,
           p."bookedInJournal"
      FROM public.users u
      LEFT JOIN public.payments p ON p."userId" = u.id
     WHERE lower(btrim(u."displayName")) = 'burim dervishi'
     ORDER BY u.email
  LOOP
    RAISE NOTICE '   % [%]', r.email, r.role;
    RAISE NOTICE '      Zahlung % | Nr % | % % | % | Jahr % | Art % | bezahlt am % | verbucht %',
      r.zahlung, r."invoiceNumber", r.amount, r.currency, r.status,
      r."billingYear", r.type, r.bezahlt_am, r."bookedInJournal";
  END LOOP;

  -- Der urspruenglich hier stehende Block scheiterte an einer Spalte, deren
  -- Typ ich angenommen statt nachgesehen hatte. Die Auswertung der
  -- Verweise steht jetzt in 20260918300000_references_probe.sql.
END $$;
