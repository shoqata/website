DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Bedingungen auf payments.status ===';
  FOR r IN SELECT conname, pg_get_constraintdef(oid) AS def FROM pg_constraint
            WHERE conrelid='public.payments'::regclass AND contype='c' LOOP
    RAISE NOTICE '  %: %', r.conname, r.def;
  END LOOP;
  RAISE NOTICE '=== Vorkommende Werte ===';
  FOR r IN SELECT status, count(*) AS n FROM public.payments GROUP BY 1 ORDER BY 2 DESC LOOP
    RAISE NOTICE '  % -> %', rpad(r.status,12), r.n;
  END LOOP;
  RAISE NOTICE '=== Gebuchte Journaleintraege zu dieser Rechnung? ===';
  -- accounting_journal hat keine Spalte reference; geraten, und der Block
  -- brach ab. Die Beschreibung reicht fuer die Frage.
  FOR r IN SELECT count(*) AS n FROM public.accounting_journal
            WHERE coalesce(description,'') ILIKE '%18027322%' LOOP
    RAISE NOTICE '  %', r.n;
  END LOOP;
END $$;
