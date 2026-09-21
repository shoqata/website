DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Journaleintraege, die 18027322 nennen ===';
  FOR r IN SELECT to_jsonb(j) AS d FROM public.accounting_journal j
            WHERE coalesce(j.description,'') ILIKE '%18027322%' LOOP
    RAISE NOTICE '  %', r.d;
  END LOOP;
  RAISE NOTICE '=== Zum Vergleich: die bezahlte INV-18027321 ===';
  FOR r IN SELECT to_jsonb(j) AS d FROM public.accounting_journal j
            WHERE coalesce(j.description,'') ILIKE '%18027321%' LOOP
    RAISE NOTICE '  %', r.d;
  END LOOP;
END $$;
