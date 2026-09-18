-- Sicherheitspruefung, mit Blick auf die Plattformebene.
--
-- Die beunruhigende Frage zuerst: reset_member_password laesst jeden aus der
-- Geschaeftsfuehrung eines Vereins ein Passwort im eigenen Verein setzen. Der
-- Betreiber der Plattform ist aber zugleich Mitglied seines eigenen Vereins.
-- Koennte ein Vorstandsmitglied damit sein Konto uebernehmen -- und ueber
-- is_platform_admin() alle Vereine?
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Wer betreibt die Plattform? ===';
  FOR r IN SELECT pa.email,
                  (SELECT count(*) FROM public.users u WHERE lower(u.email) = lower(pa.email)) AS als_mitglied,
                  (SELECT string_agg(u.role || ' in ' || u."tenantId", ', ')
                     FROM public.users u WHERE lower(u.email) = lower(pa.email)) AS rollen
             FROM public.platform_admins pa LOOP
    RAISE NOTICE '  % -- als Mitglied erfasst: % | %', r.email, r.als_mitglied, coalesce(r.rollen,'-');
  END LOOP;

  RAISE NOTICE '=== Wer koennte im selben Verein Passwoerter setzen? ===';
  FOR r IN SELECT u."displayName", u.email, u.role, u."tenantId"
             FROM public.users u
            WHERE u.role IN ('ADMIN','SUPER_ADMIN','BOARD')
            ORDER BY u.role LOOP
    RAISE NOTICE '  % (%) -- % in %', r."displayName", r.email, r.role, r."tenantId";
  END LOOP;

  SELECT count(*) INTO v_n
    FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN','BOARD')
     AND EXISTS (SELECT 1 FROM public.users z
                  JOIN public.platform_admins pa ON lower(pa.email) = lower(z.email)
                 WHERE z."tenantId" = u."tenantId"
                   AND lower(z.email) <> lower(u.email));
  RAISE NOTICE 'Personen, die im Verein eines Betreibers Passwoerter setzen duerfen: %', v_n;

  RAISE NOTICE '=== Erreichbarkeit der Plattformtabellen ===';
  FOR r IN SELECT tablename, policyname, cmd, coalesce(qual,'-') AS q
             FROM pg_policies
            WHERE schemaname='public'
              AND tablename IN ('platform_admins','admin_emails','platform_leads',
                                'platform_invoices','platform_support','tenants','tenant_domains')
            ORDER BY tablename, cmd LOOP
    RAISE NOTICE '  %.% [%]', r.tablename, r.policyname, r.cmd;
    RAISE NOTICE '      USING %', left(r.q, 160);
  END LOOP;

  RAISE NOTICE '=== Funktionen mit erhoehten Rechten ===';
  FOR r IN SELECT p.proname,
                  (p.prosrc LIKE '%is_platform_admin%') AS prueft_betreiber,
                  (p.prosrc LIKE '%is_member_manager%' OR p.prosrc LIKE '%is_staff%') AS prueft_rolle,
                  (p.prosrc LIKE '%current_tenant%') AS prueft_verein
             FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname='public' AND p.prosecdef
            ORDER BY p.proname LOOP
    RAISE NOTICE '  %: Betreiber % | Rolle % | Verein %',
      rpad(r.proname, 30), r.prueft_betreiber, r.prueft_rolle, r.prueft_verein;
  END LOOP;
END $$;
