DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== settings/company und branding (koretini) ===';
  FOR r IN SELECT jsonb_pretty(coalesce(company,'{}'::jsonb)) AS c,
                  jsonb_pretty(coalesce(branding,'{}'::jsonb)) AS b
             FROM public.settings WHERE "tenantId"='koretini' AND id IN ('company','global','system') LOOP
    RAISE NOTICE 'company: %', replace(left(r.c, 400), E'\n', ' ');
    RAISE NOTICE 'branding: %', replace(left(r.b, 400), E'\n', ' ');
  END LOOP;

  RAISE NOTICE '=== events: Spalten und Bilder ===';
  FOR r IN SELECT string_agg(column_name,', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns WHERE table_schema='public' AND table_name='events' LOOP
    RAISE NOTICE '%', r.s;
  END LOOP;
  FOR r IN SELECT count(*) AS n, count(*) FILTER (WHERE coalesce(image,'')<>'') AS mit_bild
             FROM public.events WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  % Veranstaltungen, % mit Bild', r.n, r.mit_bild;
  END LOOP;

  RAISE NOTICE '=== Mitglieder mit Foto ===';
  FOR r IN SELECT count(*) FILTER (WHERE coalesce("photoFileName",'')<>'') AS mit_foto, count(*) AS n
             FROM public.users WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  % von %', r.mit_foto, r.n;
  END LOOP;
END $$;
