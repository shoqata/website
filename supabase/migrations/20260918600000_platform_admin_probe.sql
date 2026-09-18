-- Funktioniert is_platform_admin() ohne Mitgliedszeile?
--
-- Der Betreiber soll kuenftig in keinem Verein Mitglied sein. Wenn die
-- Pruefung aber ueber die Mitgliedertabelle laeuft, wuerde er sich damit selbst
-- aussperren. Das gehoert geklaert, bevor umgestellt wird.
DO $$
DECLARE r record; z text;
BEGIN
  FOR r IN SELECT p.proname, p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname IN ('is_platform_admin','app_role','current_tenant')
            ORDER BY p.proname LOOP
    RAISE NOTICE '--- % ---', r.proname;
    FOREACH z IN ARRAY string_to_array(btrim(r.prosrc), E'\n') LOOP
      IF btrim(z) <> '' THEN RAISE NOTICE '   %', btrim(z); END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE '=== Was haengt an den beiden Zeilen? ===';
  FOR r IN SELECT u.id, u.email, u.role,
                  (SELECT count(*) FROM public.board_members b WHERE b."userId"=u.id) AS vorstand,
                  (SELECT count(*) FROM public.payments p WHERE p."userId"=u.id) AS zahlungen,
                  (SELECT count(*) FROM public.neighborhoods n
                    WHERE n."contactPersonIds" @> to_jsonb(u.id) OR n."representativeId"=u.id
                       OR n."managerId"=u.id) AS betreut,
                  (SELECT count(*) FROM public.board_meetings m WHERE m."updatedBy"=u.id OR m."publishedBy"=u.id) AS protokolle,
                  (SELECT count(*) FROM public.security_logs s WHERE s."userId"=u.id) AS protokolleintraege,
                  (u."authUserId" IS NOT NULL) AS konto
             FROM public.users u
            WHERE u.email IN ('burim@dervishi.ch','email@dervishi.ch','burim_roPmU@dervishi.ch')
            ORDER BY u.email LOOP
    RAISE NOTICE '  % (%) Rolle %', r.email, r.id, r.role;
    RAISE NOTICE '     Vorstandsliste % | Zahlungen % | betreute Nachbarschaften % | Protokolle % | Sicherheitseintraege % | Konto %',
      r.vorstand, r.zahlungen, r.betreut, r.protokolle, r.protokolleintraege, r.konto;
  END LOOP;
END $$;
