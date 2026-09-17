-- Woran genau scheitert das Speichern?
--
-- Die INSERT-Regel kennt nur id = auth.uid(). Bevor sie angefasst wird, muss
-- geklaert sein, ob der Weg ueber UPDATE ueberhaupt offensteht -- dort haengt
-- alles an app_role() und daran, ob die Zeile dem Konto zugeordnet ist.
DO $$
DECLARE r record; v_def text;
BEGIN
  FOR r IN SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE n.nspname='public' AND p.proname IN ('app_role','claimable_role','is_staff','is_member_manager')
            ORDER BY p.proname LOOP
    SELECT pg_get_functiondef((quote_ident('public')||'.'||quote_ident(r.proname))::regproc) INTO v_def;
    RAISE NOTICE '--- % ---', r.proname;
    RAISE NOTICE '%', regexp_replace(v_def, '^.*?AS \$function\$', '', 'n');
  END LOOP;

  RAISE NOTICE '=== Zuordnung der Zeilen zum Anmeldekonto ===';
  FOR r IN SELECT count(*) AS n,
                  ("authUserId" IS NOT NULL) AS hat_konto,
                  (id ~ '^[0-9a-f]{8}-[0-9a-f]{4}') AS id_ist_uuid
             FROM public.users GROUP BY 2,3 ORDER BY 2,3 LOOP
    RAISE NOTICE '  Zeilen %: authUserId gesetzt %, id sieht aus wie Auth-UID %',
      r.n, r.hat_konto, r.id_ist_uuid;
  END LOOP;

  RAISE NOTICE '=== Rollen, die nicht MEMBER sind ===';
  FOR r IN SELECT role, count(*) AS n FROM public.users
            WHERE role IS DISTINCT FROM 'MEMBER' GROUP BY role ORDER BY role LOOP
    RAISE NOTICE '  %: %', r.role, r.n;
  END LOOP;
END $$;
