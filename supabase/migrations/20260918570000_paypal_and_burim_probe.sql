-- Zwei Fragen vor dem Eingriff.
--
-- 1. Sind die Zahlungsangaben je Verein getrennt, oder teilen sich alle
--    dieselben? Bei PayPal geht es um ein Geheimnis und um Geld -- das gehoert
--    belegt, nicht angenommen.
-- 2. Was genau haengt an den drei Zeilen Burim Dervishi?
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Aufbau von settings ===';
  FOR r IN SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema='public' AND table_name='settings' ORDER BY ordinal_position LOOP
    RAISE NOTICE '  % (%)', r.column_name, r.data_type;
  END LOOP;

  RAISE NOTICE '=== Wie viele Einstellungszeilen, und je Verein? ===';
  FOR r IN SELECT id, "tenantId",
                  (payment ? 'paypalClientId') AS hat_client,
                  (payment ? 'paypalSecret')   AS hat_geheimnis,
                  coalesce(payment ->> 'iban', '-') AS iban
             FROM public.settings ORDER BY "tenantId", id LOOP
    RAISE NOTICE '  % | Verein % | PayPal-Kennung % | Geheimnis % | IBAN %',
      r.id, r."tenantId", r.hat_client, r.hat_geheimnis, r.iban;
  END LOOP;

  RAISE NOTICE '=== Regeln auf settings ===';
  FOR r IN SELECT policyname, cmd, roles::text AS rollen, coalesce(qual,'-') AS q
             FROM pg_policies WHERE schemaname='public' AND tablename='settings' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%] fuer %', r.policyname, r.cmd, r.rollen;
    RAISE NOTICE '      USING %', left(r.q, 140);
  END LOOP;

  RAISE NOTICE '=== Die drei Zeilen Burim Dervishi ===';
  FOR r IN
    SELECT u.id, u.email, u.role, u."tenantId",
           (u."authUserId" IS NOT NULL) AS hat_konto,
           (SELECT count(*) FROM public.board_members b WHERE b."userId" = u.id) AS vorstandsliste,
           (SELECT count(*) FROM public.payments p WHERE p."userId" = u.id) AS zahlungen,
           (SELECT string_agg(p."invoiceNumber" || ' (' || p.amount || ' ' || p.status || ')', ', ')
              FROM public.payments p WHERE p."userId" = u.id) AS welche,
           (SELECT count(*) FROM public.accounting_journal j
             WHERE j."referenceId" IN (SELECT p.id FROM public.payments p WHERE p."userId" = u.id)) AS buchungen
      FROM public.users u
     WHERE lower(btrim(u."displayName")) = 'burim dervishi'
     ORDER BY u.email
  LOOP
    RAISE NOTICE '  % | % | % ', r.id, r.email, r.role;
    RAISE NOTICE '     Konto % | Vorstandsliste % | Zahlungen % | Buchungen %',
      r.hat_konto, r.vorstandsliste, r.zahlungen, r.buchungen;
    RAISE NOTICE '     %', coalesce(r.welche, '-');
  END LOOP;

  RAISE NOTICE '=== Betreiber der Plattform ===';
  FOR r IN SELECT email FROM public.platform_admins LOOP
    RAISE NOTICE '  %', r.email;
  END LOOP;
  FOR r IN SELECT email FROM public.admin_emails LOOP
    RAISE NOTICE '  admin_emails: %', r.email;
  END LOOP;
END $$;
