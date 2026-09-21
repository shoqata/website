-- Beim Auffuellen leerer Felder wurde die Adresse zerlegt behandelt, sie ist
-- aber eine Einheit. Perparim Haxhiu hatte auf der behaltenen Zeile nur
-- "USA" im Ortsfeld und keine Strasse; Strasse und PLZ kamen darauf aus der
-- Platzhalterzeile. Ergebnis: Zelglistrasse 17, 8620 USA -- daran laesst sich
-- keine Rechnung schicken.
--
-- Uebernommen wird die vollstaendige Adresse, also Wetzikon. Der fruehere
-- Eintrag bleibt als Notiz stehen, weil unklar ist, welche die aktuelle ist:
-- beide Zeilen stammen vom selben Tag.
DO $$
DECLARE r record; v_id text;
BEGIN
  SELECT id INTO v_id FROM public.users
   WHERE "tenantId"='koretini' AND lower(email)='gana_pepi@hotmail.com';
  IF v_id IS NULL THEN RAISE NOTICE 'Zeile nicht gefunden.'; RETURN; END IF;

  UPDATE public.users
     SET city = 'Wetzikon', country = 'Switzerland',
         "internalNotes" = trim(coalesce("internalNotes",'') ||
           ' [21.09.2026 Zusammenfuehrung: auf der zweiten Zeile stand als Adresse nur "USA".' ||
           ' Uebernommen wurde die vollstaendige Adresse in Wetzikon -- bitte beim Mitglied bestaetigen.]')
   WHERE id = v_id;

  FOR r IN SELECT coalesce("displayName",'') AS dn, street, zip, city, country,
                  left(coalesce("internalNotes",''),90) AS notiz
             FROM public.users WHERE id = v_id LOOP
    RAISE NOTICE '  % | % | % % | % | %', r.dn, r.street, r.zip, r.city, r.country, r.notiz;
  END LOOP;

  RAISE NOTICE '--- Adressen der fuenf nach der Zusammenfuehrung ---';
  FOR r IN SELECT coalesce(u."displayName",'') AS dn,
                  coalesce(u.street,'-') AS str, coalesce(u.zip,'-') AS plz,
                  coalesce(u.city,'-') AS ort, coalesce(u.country,'-') AS land
             FROM public.users u WHERE u."tenantId"='koretini'
              AND lower(u."firstName")||' '||lower(u."lastName") IN
                  ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
            ORDER BY u."lastName" LOOP
    RAISE NOTICE '  % | % | % % | %', rpad(r.dn,18), rpad(left(r.str,24),24), rpad(r.plz,6), rpad(left(r.ort,12),12), r.land;
  END LOOP;
END $$;
