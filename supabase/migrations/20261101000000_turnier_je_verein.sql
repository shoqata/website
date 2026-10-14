-- Das Turnier gehoert dem Verein, nicht dem Programm.
--
-- FutsalPage las branding.tournamentEmbedUrl und tournamentDetailUrl --
-- und fiel, wenn sie fehlten, auf Koretinis Turnier zurueck:
--
--   const DEFAULT_EMBED  = '.../veranstaltung/embed/758/'
--   const DEFAULT_DETAIL = '.../veranstaltung/detail/758'
--
-- Die Felder waren NIRGENDS einzugeben. Die Vorgabe griff also immer, und
-- jeder weitere Verein, der das Modul Turnier bucht, haette unter seiner
-- eigenen Adresse Koretinis Spielplan gezeigt und dessen Anmeldung
-- verlinkt. Ein Sponsor haette sich beim falschen Verein gemeldet.
--
-- Die Vorgabe ist jetzt weg, und es gibt eine Maske dafuer (Website ->
-- Turnier). Damit sich fuer Koretini NICHTS aendert, wandern die beiden
-- Adressen hier an ihren Platz: in das Branding des Vereins, dem sie
-- gehoeren.
--
-- Demo bekommt sie bewusst NICHT. Die Musterseite soll zeigen, was das
-- Modul kann -- Titel, Einleitung, Sponsorenpakete -- und nicht das
-- Turnier eines fremden Vereins. Ohne Spielplan steht dort der ehrliche
-- Satz, dass er noch nicht veroeffentlicht ist. Wer ihn fuer Demo
-- moechte, traegt ihn in der Maske ein.

UPDATE public.settings
   SET branding = coalesce(branding, '{}'::jsonb)
     || jsonb_build_object(
          'tournamentEmbedUrl',  'https://www.turnierplanung.ch/veranstaltung/embed/758/',
          'tournamentDetailUrl', 'https://www.turnierplanung.ch/veranstaltung/detail/758')
 WHERE "tenantId" = 'koretini' AND id = 'branding'
   -- Nur setzen, was fehlt. Hat der Verein inzwischen eigene Adressen
   -- eingetragen, sind sie richtiger als diese hier.
   AND coalesce(branding ->> 'tournamentEmbedUrl', '') = '';

DO $$
DECLARE v_embed text; v_detail text; v_demo text;
BEGIN
  SELECT branding ->> 'tournamentEmbedUrl', branding ->> 'tournamentDetailUrl'
    INTO v_embed, v_detail
    FROM public.settings WHERE "tenantId" = 'koretini' AND id = 'branding';

  IF coalesce(v_embed, '') = '' THEN
    RAISE EXCEPTION 'Koretini hat keine Spielplanadresse -- die Turnierseite waere leer, '
                    'obwohl sie es vorher nicht war.';
  END IF;
  IF coalesce(v_detail, '') = '' THEN
    RAISE EXCEPTION 'Koretini hat keine Anmeldeadresse -- der Knopf "Team anmelden" waere fort.';
  END IF;

  -- Und die Vorgabe darf nicht bei einem anderen Verein gelandet sein.
  SELECT string_agg("tenantId", ', ') INTO v_demo
    FROM public.settings
   WHERE id = 'branding' AND "tenantId" <> 'koretini'
     AND branding ->> 'tournamentEmbedUrl' LIKE '%/758%';
  IF v_demo IS NOT NULL THEN
    RAISE EXCEPTION 'Koretinis Turnier steht auch bei: %', v_demo;
  END IF;

  RAISE NOTICE 'Turnier: Koretini behaelt seine Adressen, kein anderer Verein hat sie.';
END $$;
