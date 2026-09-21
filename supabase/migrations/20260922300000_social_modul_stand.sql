-- Die Beschreibung sagte "Das Veroeffentlichen ist noch nicht angebunden".
-- Der Weg steht jetzt. Was fehlt, ist nichts Technisches mehr, sondern die
-- Meta-App des Betreibers und deren Pruefung durch Meta -- und genau das
-- soll dastehen, statt es entweder zu verschweigen oder zu viel zu
-- versprechen.
UPDATE public.modules SET
  beschreibung_de = 'Beitraege schreiben, planen und auf die Facebook-Seite und das Instagram-Konto des Vereins senden. Der Verein meldet sich einmal bei Facebook an; Zugangsdaten werden nicht von Hand eingetragen. Setzt voraus, dass der Betreiber die Meta-App hinterlegt hat.',
  beschreibung_en = 'Write, schedule and send posts to the association''s Facebook page and Instagram account. The association signs in with Facebook once; no access tokens are entered by hand. Requires the operator to have registered the Meta app.',
  beschreibung_sq = 'Shkruani, planifikoni dhe dergoni postime ne faqen e Facebook dhe llogarine e Instagram te shoqates. Shoqata kycet nje here me Facebook; nuk futen token me dore. Kerkon qe operatori ta kete regjistruar aplikacionin Meta.'
 WHERE schluessel = 'SOCIAL';

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Zeitplan ===';
  FOR r IN SELECT jobname, schedule, active FROM cron.job WHERE jobname='social_veroeffentlichen' LOOP
    RAISE NOTICE '  % | % | aktiv=%', r.jobname, r.schedule, r.active;
  END LOOP;

  RAISE NOTICE '=== Was der Betreiber noch eintragen muss ===';
  FOR r IN SELECT schluessel, CASE WHEN coalesce(btrim(wert),'')='' THEN 'LEER' ELSE 'gesetzt' END AS stand
             FROM public.platform_secrets ORDER BY schluessel LOOP
    RAISE NOTICE '  % -> %', rpad(r.schluessel,20), r.stand;
  END LOOP;

  RAISE NOTICE '=== Modulzustand ===';
  FOR r IN SELECT schluessel, status, braucht_einrichtung FROM public.modules WHERE schluessel='SOCIAL' LOOP
    RAISE NOTICE '  % | % | Einrichtung noetig=%', r.schluessel, r.status, r.braucht_einrichtung;
  END LOOP;
END $$;
