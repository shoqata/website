-- Ein Postausgang fuer alle, bei unityhub.
--
-- Bisher trug jeder Verein seinen eigenen ein. Das bedeutete: jeder Verein
-- muss einen Anbieter finden, einrichten und pflegen -- und bei Koretini
-- scheiterte genau das. Gemessen:
--
--   mail.helvico.ch:587 antwortet von einem gewoehnlichen Anschluss in
--   0,1 s ("220 mail.helvico.ch ESMTP Postal"), aus Supabases
--   Rechenzentrum laeuft es ins Zeitlimit (Connection timed out,
--   os error 110). Zwei der drei Fehlschlaege liegen NACH der
--   Einrichtung -- es lag nie an der Konfiguration.
--
-- Dazu kam ein zweiter Befund: fuer die Plattform selbst war gar kein
-- Postausgang hinterlegt. Die Lead-Benachrichtigung vom 18.09. hat 0
-- Versuche -- sie wurde nie angefasst. Anfragen von Vereinen kamen also
-- nie an.

-- ------------------------------------------------- Die zentrale Zeile
-- Leer und inaktiv angelegt: die Zugangsdaten traegt der Betreiber selbst
-- ein, sie gehoeren nicht in eine Migration.
INSERT INTO public.mail_settings ("tenantId", host, port, benutzer, kennwort,
                                  absender, absendername, tls, aktiv)
VALUES ('plattform', NULL, 587, NULL, NULL, NULL, 'unityhub', 'starttls', false)
ON CONFLICT ("tenantId") DO NOTHING;

-- Koretinis eigener Postausgang wird nicht mehr gelesen. Die Zeile bleibt
-- stehen -- sie zu loeschen wuerde Zugangsdaten vernichten, die vielleicht
-- noch anderswo gebraucht werden -- aber sie wird abgeschaltet, damit die
-- Oberflaeche nicht laenger behauptet, es sei einer eingerichtet.
UPDATE public.mail_settings SET aktiv = false
 WHERE "tenantId" <> 'plattform' AND aktiv IS DISTINCT FROM false;


-- -------------------------------------- Vereine tragen keinen mehr ein
-- Die Wache wird in die bestehende Fassung eingehaengt, nicht durch eine
-- Kopie ersetzt: die Funktion traegt Vorgabewerte, die CREATE OR REPLACE
-- nicht entfernen darf, und ihr Rumpf gehoert dorthin, wo er entstanden ist.
DO $$
DECLARE quelle text; neu text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO quelle
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname='mail_einstellungen_speichern';
  IF quelle IS NULL THEN RAISE EXCEPTION 'mail_einstellungen_speichern fehlt.'; END IF;

  neu := replace(quelle,
    'DECLARE v_ziel text; v_wer text; v_eigen text := public.current_tenant();
BEGIN',
    'DECLARE v_ziel text; v_wer text; v_eigen text := public.current_tenant();
BEGIN
  -- Der Postausgang laeuft zentral ueber unityhub. Ein Verein traegt
  -- keinen eigenen mehr ein -- und kann es auch nicht, denn eine
  -- Oberflaeche, die etwas verbirgt, ist keine Berechtigung.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION ''Der Postausgang laeuft zentral ueber unityhub. Ein eigener Postausgang je Verein wird nicht mehr verwendet.''
      USING ERRCODE = ''insufficient_privilege'';
  END IF;
  p_verein := ''plattform'';');

  IF neu = quelle THEN
    RAISE EXCEPTION 'Der erwartete Kopf stand nicht in mail_einstellungen_speichern -- '
                    'nicht angefasst, statt ihn blind zu ueberschreiben.';
  END IF;
  EXECUTE neu;
  RAISE NOTICE 'mail_einstellungen_speichern auf den zentralen Postausgang begrenzt';
END $$;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE z int; aktive int; wache boolean;
BEGIN
  SELECT count(*) INTO z FROM public.mail_settings WHERE "tenantId"='plattform';
  IF z <> 1 THEN RAISE EXCEPTION 'Keine zentrale Postausgangszeile.'; END IF;

  SELECT count(*) INTO aktive FROM public.mail_settings
   WHERE "tenantId" <> 'plattform' AND aktiv;
  IF aktive > 0 THEN
    RAISE EXCEPTION '% Vereins-Postausgang/-ausgaenge sind noch aktiv.', aktive;
  END IF;

  SELECT (p.prosrc ~ 'zentral ueber unityhub') INTO wache
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname='mail_einstellungen_speichern';
  IF NOT coalesce(wache,false) THEN
    RAISE EXCEPTION 'Die Wache steht nicht in mail_einstellungen_speichern.';
  END IF;

  RAISE NOTICE 'Ein Postausgang: zentrale Zeile vorhanden, Vereinszeilen abgeschaltet, Speichern begrenzt.';
END $$;
