DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== settings/social je Verein (ohne die Geheimnisse selbst) ===';
  FOR r IN SELECT s."tenantId",
                  coalesce(s.data ->> 'fbPageId','') <> '' AS fb_seite,
                  length(coalesce(s.data ->> 'fbAccessToken','')) AS fb_token_laenge,
                  coalesce(s.data ->> 'igUserId','') <> '' AS ig_konto,
                  length(coalesce(s.data ->> 'igAccessToken','')) AS ig_token_laenge,
                  coalesce(s.data ->> 'autoPostingEnabled','?') AS schalter
             FROM public.settings s WHERE s.id='social' LOOP
    RAISE NOTICE '  % | FB-Seite % Token(%) | IG-Konto % Token(%) | Schalter %',
      rpad(r."tenantId",12), r.fb_seite, r.fb_token_laenge, r.ig_konto, r.ig_token_laenge, r.schalter;
  END LOOP;

  RAISE NOTICE '=== Gibt die oeffentliche Sicht die Token noch heraus? ===';
  FOR r IN SELECT count(*) AS n FROM public.public_settings p
            WHERE p.data::text ILIKE '%AccessToken%' LOOP
    RAISE NOTICE '  Treffer: %', r.n;
  END LOOP;

  RAISE NOTICE '=== Beitraege im Verlauf ===';
  -- socialmediaposts hat keine Spalte autoPosted; die Oberflaeche schreibt
  -- sie trotzdem. Geraten, und der Block brach ab.
  FOR r IN SELECT coalesce(status,'?') AS st, count(*) AS n
             FROM public.socialmediaposts GROUP BY 1 ORDER BY 2 DESC LOOP
    RAISE NOTICE '  % -> %', rpad(r.st,10), r.n;
  END LOOP;
END $$;
