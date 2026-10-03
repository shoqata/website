-- Die alte Wahl mitnehmen.
--
-- Bis zur Vorlagen-Umstellung hiess der Schluessel in settings/system
-- "startseiteVariante" und kannte zwei Werte: STANDARD und PREMIUM. Der
-- neue heisst "startseitenVorlage" und traegt einen von sechs Namen.
--
-- Wer auf PREMIUM stand, faellt damit stillschweigend auf KLASSISCH
-- zurueck -- die Funktion liest den neuen Schluessel, findet nichts und
-- nimmt den Rueckfall. Das ist kein Fehler im Ablauf, sondern eine
-- Umbenennung ohne Umzug. Hier der Umzug.
--
-- PREMIUM wird zu ERZAEHLUNG: das WAR die Premium-Seite, es gab keine
-- andere. Ein Verein, der sie hatte, bekommt also genau das zurueck, was
-- er vorher sah -- und kann danach wechseln.
--
-- Der alte Schluessel bleibt stehen. Er wird von nichts mehr gelesen, aber
-- solange er da ist, laesst sich dieser Umzug wiederholen, falls etwas
-- schiefging. Loeschen kann man ihn, wenn die Umstellung ein paar Wochen
-- gehalten hat.

DO $$
DECLARE
  v_premium int;
  v_schon   int;
  v_umgezogen int;
  r RECORD;
BEGIN
  SELECT count(*) INTO v_premium FROM public.settings
   WHERE id='system' AND upper(coalesce(system ->> 'startseiteVariante','')) = 'PREMIUM';
  SELECT count(*) INTO v_schon FROM public.settings
   WHERE id='system' AND upper(coalesce(system ->> 'startseiteVariante','')) = 'PREMIUM'
     AND system ? 'startseitenVorlage';

  RAISE NOTICE 'Vereine mit altem PREMIUM: %, davon schon neu gesetzt: %', v_premium, v_schon;

  -- Nur dort, wo noch nichts Neues steht. Eine bereits getroffene neue
  -- Wahl darf der Umzug nicht ueberschreiben.
  WITH bewegt AS (
    UPDATE public.settings
       SET system = system || '{"startseitenVorlage":"ERZAEHLUNG"}'::jsonb
     WHERE id = 'system'
       AND upper(coalesce(system ->> 'startseiteVariante','')) = 'PREMIUM'
       AND NOT (system ? 'startseitenVorlage')
    RETURNING "tenantId"
  )
  SELECT count(*) INTO v_umgezogen FROM bewegt;

  RAISE NOTICE 'Umgezogen auf ERZAEHLUNG: %', v_umgezogen;

  -- Und zeigen, was jetzt wirklich herauskommt -- je Verein, der etwas
  -- gewaehlt hat. Behaupten genuegt nicht.
  FOR r IN
    SELECT s."tenantId" AS verein, s.system ->> 'startseitenVorlage' AS gewaehlt
      FROM public.settings s
     WHERE s.id='system' AND s.system ? 'startseitenVorlage'
     ORDER BY 1
  LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('app_metadata', json_build_object('tenant', r.verein))::text, true);
    RAISE NOTICE '  % : gewaehlt=%  bekommt=%',
      r.verein, r.gewaehlt, public.startseiten_vorlage();
  END LOOP;
  PERFORM set_config('request.jwt.claims', NULL, true);
END $$;
