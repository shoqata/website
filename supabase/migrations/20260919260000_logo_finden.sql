DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT id, branding FROM public.settings WHERE branding IS NOT NULL LOOP
    RAISE NOTICE 'settings/%: logoUrl=%', r.id, coalesce(r.branding ->> 'logoUrl', '(keiner)');
    RAISE NOTICE '            faviconUrl=%', coalesce(r.branding ->> 'faviconUrl', '(keiner)');
  END LOOP;
  FOR r IN SELECT name, id FROM storage.buckets LOOP
    RAISE NOTICE 'Ablage: % (%)', r.name, r.id;
  END LOOP;
  FOR r IN SELECT name FROM storage.objects WHERE name ILIKE '%logo%' LIMIT 10 LOOP
    RAISE NOTICE '  Datei mit "logo": %', r.name;
  END LOOP;
END $$;
