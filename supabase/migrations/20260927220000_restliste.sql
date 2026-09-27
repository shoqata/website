DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Warteschlange Postausgang ===';
  FOR r IN SELECT status, "tenantId", count(*) AS n FROM public.mail_queue
            GROUP BY 1,2 ORDER BY 1,2 LOOP
    RAISE NOTICE '  % | % | %', rpad(r.status,10), rpad(coalesce(r."tenantId",'(keiner)'),12), r.n;
  END LOOP;

  RAISE NOTICE '=== Datenschutztext je Verein ===';
  FOR r IN SELECT s."tenantId",
                  coalesce(length(s.branding ->> 'privacyText'),0) AS laenge
             FROM public.settings s WHERE s.id='branding' LOOP
    RAISE NOTICE '  % -> % Zeichen', rpad(r."tenantId",12), r.laenge;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM public.settings WHERE id='branding') THEN
    RAISE NOTICE '  (kein Verein hat eine branding-Zeile -- also auch keinen Text)';
  END IF;

  RAISE NOTICE '=== Mitgliederdaten, die nur der Verein fuellen kann ===';
  FOR r IN SELECT count(*) AS gesamt,
                  count(*) FILTER (WHERE email LIKE '%@koretini.legacy') AS ohne_mail,
                  count(*) FILTER (WHERE birthdate IS NULL) AS ohne_geburtstag,
                  count(*) FILTER (WHERE "authUserId" IS NOT NULL) AS mit_konto
             FROM public.users WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  % Mitglieder | % ohne echte E-Mail | % ohne Geburtsdatum | % mit Anmeldekonto',
      r.gesamt, r.ohne_mail, r.ohne_geburtstag, r.mit_konto;
  END LOOP;
  FOR r IN SELECT count(*) AS nb,
                  count(*) FILTER (WHERE NOT EXISTS (
                    SELECT 1 FROM public.users u WHERE u."neighborhoodId"=n.id
                      AND u.role='NEIGHBORHOOD_MANAGER'
                      AND coalesce(u."membershipStatus",'')<>'INACTIVE')) AS ohne_betreuung
             FROM public.neighborhoods n LOOP
    RAISE NOTICE '  % Nachbarschaften, % ohne aktive Betreuung', r.nb, r.ohne_betreuung;
  END LOOP;
END $$;
