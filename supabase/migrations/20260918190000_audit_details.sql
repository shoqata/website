-- Den drei Auffaelligkeiten nachgehen.
DO $$
DECLARE r record; v_n int; v_da boolean;
BEGIN
  RAISE NOTICE '=== polls: alle Regeln im Wortlaut ===';
  FOR r IN SELECT policyname, cmd, coalesce(qual,'-') AS q, coalesce(with_check,'-') AS w
             FROM pg_policies WHERE schemaname='public' AND tablename='polls' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%]', r.policyname, r.cmd;
    RAISE NOTICE '      USING %', r.q;
    RAISE NOTICE '      CHECK %', r.w;
  END LOOP;
  SELECT count(*) INTO v_n FROM public.polls;
  RAISE NOTICE '  Umfragen vorhanden: %', v_n;

  RAISE NOTICE '=== Zwei Tabellen fuer Social-Media-Beitraege? ===';
  FOR r IN SELECT c.relname, c.relkind, c.relrowsecurity,
                  (SELECT count(*) FROM pg_policies p
                    WHERE p.schemaname='public' AND p.tablename=c.relname) AS regeln
             FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND lower(c.relname) = 'socialmediaposts'
            ORDER BY c.relname LOOP
    RAISE NOTICE '  "%" (Art %, Schutz %, % Regeln)', r.relname, r.relkind, r.relrowsecurity, r.regeln;
  END LOOP;

  RAISE NOTICE '=== fiscal_years: Regeln und Bestand ===';
  FOR r IN SELECT policyname, cmd, roles::text AS rollen, coalesce(qual,'-') AS q
             FROM pg_policies WHERE schemaname='public' AND tablename='fiscal_years' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%] fuer % USING %', r.policyname, r.cmd, r.rollen, r.q;
  END LOOP;
  SELECT count(*) INTO v_n FROM public.fiscal_years;
  RAISE NOTICE '  Geschaeftsjahre erfasst: %', v_n;

  RAISE NOTICE '=== Sind public_* Tabellen oder Sichten? ===';
  FOR r IN SELECT c.relname, CASE c.relkind WHEN 'r' THEN 'Tabelle' WHEN 'v' THEN 'Sicht'
                                            WHEN 'm' THEN 'materialisierte Sicht' ELSE c.relkind::text END AS art,
                  c.relrowsecurity AS schutz
             FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relname LIKE 'public\_%' ORDER BY c.relname LOOP
    RAISE NOTICE '  %: % (Schutz %)', r.relname, r.art, r.schutz;
  END LOOP;
END $$;
