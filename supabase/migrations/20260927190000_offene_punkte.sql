DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Postausgang je Verein (ohne Kennwort) ===';
  -- Die Spaltennamen nicht raten: beim ersten Anlauf gab es
  -- "verschluesselung" nicht und der ganze Block brach ab.
  FOR r IN SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='mail_settings' LOOP
    RAISE NOTICE '  Spalten: %', r.s;
  END LOOP;
  FOR r IN SELECT to_jsonb(m) - 'kennwort' - 'zeitplan_token' AS j FROM public.mail_settings m LOOP
    RAISE NOTICE '  %', r.j;
  END LOOP;

  RAISE NOTICE '=== Spendenkonten im Kontenplan ===';
  FOR r IN SELECT code, name, class FROM public.accounting_accounts
            WHERE "tenantId"='koretini' AND (code LIKE '32%' OR code LIKE '34%') ORDER BY code LOOP
    RAISE NOTICE '  % | % | %', r.code, rpad(r.name,46), r.class;
  END LOOP;
  FOR r IN SELECT k.code, count(j.*) AS buchungen FROM (VALUES ('3200'),('3400')) k(code)
             LEFT JOIN public.accounting_journal j
               ON j."tenantId"='koretini' AND (j."debitCode"=k.code OR j."creditCode"=k.code)
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  Konto % -> % Buchungen', r.code, r.buchungen;
  END LOOP;

  RAISE NOTICE '=== anon-Schreibrechte, die nur Zeilenregeln abhalten ===';
  FOR r IN SELECT table_name, string_agg(privilege_type, ',' ORDER BY privilege_type) AS rechte
             FROM information_schema.role_table_grants
            WHERE grantee='anon' AND table_schema='public'
              AND privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE')
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  % -> %', rpad(r.table_name,24), r.rechte;
  END LOOP;
END $$;
