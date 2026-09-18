-- Zwei Pruefungen, die ich bisher nicht gemacht habe.
--
-- Erstens: Zugriffsregeln, die zu weit gefasst sind. Dass eine Regel existiert,
-- sagt nichts darueber, ob sie etwas einschraenkt -- USING (true) ist eine
-- Regel und laesst doch jeden durch.
--
-- Zweitens: die Rechnungen selbst. An ihnen haengt Geld; doppelte
-- Rechnungsnummern, Betraege von null oder Rechnungen ohne Empfaenger wuerden
-- sich erst beim Einzahlen zeigen.
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Regeln, die niemanden einschraenken ===';
  v_n := 0;
  FOR r IN SELECT tablename, policyname, cmd, roles::text AS rollen
             FROM pg_policies
            WHERE schemaname='public'
              AND (btrim(coalesce(qual,'')) IN ('true','(true)')
                OR btrim(coalesce(with_check,'')) IN ('true','(true)'))
            ORDER BY tablename, policyname LOOP
    RAISE NOTICE '  %.% [%] fuer %', r.tablename, r.policyname, r.cmd, r.rollen;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; END IF;

  RAISE NOTICE '=== Regeln, die anon einschliessen ===';
  v_n := 0;
  FOR r IN SELECT tablename, policyname, cmd FROM pg_policies
            WHERE schemaname='public' AND roles::text LIKE '%anon%'
            ORDER BY tablename LOOP
    RAISE NOTICE '  %.% [%]', r.tablename, r.policyname, r.cmd;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; END IF;

  RAISE NOTICE '=== Schreibrechte fuer anon auf Tabellen ===';
  v_n := 0;
  FOR r IN SELECT table_name, string_agg(DISTINCT privilege_type, ',') AS rechte
             FROM information_schema.role_table_grants
            WHERE table_schema='public' AND grantee='anon'
              AND privilege_type IN ('INSERT','UPDATE','DELETE')
            GROUP BY table_name ORDER BY table_name LOOP
    RAISE NOTICE '  %: %', r.table_name, r.rechte;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; END IF;

  -- ---------------------------------------------------------- Rechnungen
  RAISE NOTICE '=== Rechnungen: Auffaelligkeiten ===';

  SELECT count(*) INTO v_n FROM (
    SELECT "invoiceNumber" FROM public.payments
     WHERE "invoiceNumber" IS NOT NULL AND btrim("invoiceNumber") <> ''
     GROUP BY 1 HAVING count(*) > 1) x;
  RAISE NOTICE '  doppelte Rechnungsnummern: %', v_n;
  IF v_n > 0 THEN
    FOR r IN SELECT "invoiceNumber", count(*) AS n FROM public.payments
              WHERE "invoiceNumber" IS NOT NULL AND btrim("invoiceNumber") <> ''
              GROUP BY 1 HAVING count(*) > 1 ORDER BY 2 DESC LIMIT 5 LOOP
      RAISE NOTICE '     % kommt % mal vor', r."invoiceNumber", r.n;
    END LOOP;
  END IF;

  SELECT count(*) INTO v_n FROM public.payments WHERE "userId" IS NULL;
  RAISE NOTICE '  ohne Empfaenger (userId leer): %', v_n;

  SELECT count(*) INTO v_n FROM public.payments WHERE amount IS NULL OR amount <= 0;
  RAISE NOTICE '  Betrag null oder negativ: %', v_n;

  SELECT count(*) INTO v_n FROM public.payments
   WHERE "invoiceNumber" IS NULL OR btrim("invoiceNumber") = '';
  RAISE NOTICE '  ohne Rechnungsnummer: %', v_n;

  SELECT count(*) INTO v_n FROM public.payments p
   WHERE p."userId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = p."userId");
  RAISE NOTICE '  verweist auf ein Mitglied, das es nicht gibt: %', v_n;

  SELECT count(*) INTO v_n FROM public.payments WHERE status = 'PAID' AND ("paidAt" IS NULL OR btrim("paidAt") = '');
  RAISE NOTICE '  als bezahlt markiert, aber ohne Zahlungsdatum: %', v_n;

  -- Mehrere Beitragsrechnungen fuer dasselbe Mitglied im selben Jahr waeren
  -- eine Doppelverrechnung.
  SELECT count(*) INTO v_n FROM (
    SELECT "userId", "billingYear" FROM public.payments
     WHERE type = 'FEE' AND "userId" IS NOT NULL AND "billingYear" IS NOT NULL
     GROUP BY 1,2 HAVING count(*) > 1) x;
  RAISE NOTICE '  Mitglieder mit mehr als einer Beitragsrechnung im selben Jahr: %', v_n;
  IF v_n > 0 THEN
    FOR r IN SELECT p."userId", p."billingYear", count(*) AS n,
                    (SELECT u."displayName" FROM public.users u WHERE u.id = p."userId") AS nm
               FROM public.payments p
              WHERE p.type='FEE' AND p."userId" IS NOT NULL AND p."billingYear" IS NOT NULL
              GROUP BY 1,2 HAVING count(*) > 1 ORDER BY 3 DESC LIMIT 5 LOOP
      RAISE NOTICE '     % (%) im Jahr %: % Rechnungen', r.nm, r."userId", r."billingYear", r.n;
    END LOOP;
  END IF;
END $$;
