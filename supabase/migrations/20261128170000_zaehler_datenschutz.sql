-- Besucherzaehler: keine Zugaenge in der Statistik, und nichts fuer immer.
--
-- 1. ZUGAENGE KUERZEN. /treffen/<token>, /heft/<token>, /ausweis/<id>
--    und /drucksachen/<id> landeten mit dem Token im Pfad. Die Statistik
--    liest die Vereinsadministration -- ein Token darin oeffnet die Seite
--    ohne Anmeldung, und /ausweis/<id> verraet, wessen Ausweis gezeigt
--    wurde. Der Browser kuerzt seit lib/zaehler.ts:pfadKuerzen selbst;
--    der Ausloeser hier gilt auch fuer jeden anderen Aufrufer der
--    oeffentlichen Funktion. Dieselbe Liste wie im Browser.
--
-- 2. AUFBEWAHREN, NICHT SAMMELN.
--    Salz     nur der heutige Tag. Mit dem Salz eines vergangenen Tages
--             liesse sich der Besucherwert durch Durchprobieren aller
--             IPv4-Adressen zurueckrechnen -- solange es liegt, ist der
--             Wert pseudonym, erst ohne es anonym.
--    Aufrufe  400 Tage. Die Auswertung reicht 90 Tage zurueck; ein Jahr
--             plus Rand erlaubt den Vergleich mit dem Vorjahresmonat.

CREATE OR REPLACE FUNCTION public.seitenaufrufe_pfad_kuerzen()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.pfad := regexp_replace(split_part(split_part(NEW.pfad, '?', 1), '#', 1),
                             '^/(treffen|heft|ausweis|drucksachen)/.+$', '/\1/*');
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS seitenaufrufe_pfad_kuerzen ON public.seitenaufrufe;
CREATE TRIGGER seitenaufrufe_pfad_kuerzen
  BEFORE INSERT OR UPDATE OF pfad ON public.seitenaufrufe
  FOR EACH ROW EXECUTE FUNCTION public.seitenaufrufe_pfad_kuerzen();

DO $$
DECLARE n int;
BEGIN
  UPDATE public.seitenaufrufe SET pfad = pfad
   WHERE pfad ~ '^/(treffen|heft|ausweis|drucksachen)/.+$' AND pfad !~ '/\*$'
      OR pfad ~ '[?#]';
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Pfade gekuerzt: %', n;
END $$;


-- ------------------------------------------------------- Aufraeumen
CREATE OR REPLACE FUNCTION public.zaehler_aufraeumen()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.zaehler_salz
   WHERE tag < (now() AT TIME ZONE 'Europe/Zurich')::date;
  DELETE FROM public.seitenaufrufe
   WHERE gesehen_am < now() - interval '400 days';
END $$;

REVOKE ALL ON FUNCTION public.zaehler_aufraeumen() FROM public, anon, authenticated;

-- Taeglich 00:15 UTC, also 01:15 bzw. 02:15 Zuercher Zeit: nach dem
-- Zuercher Tageswechsel. Geloescht wird nur, was vor "heute" liegt --
-- das Salz des laufenden Tages bleibt immer.
DO $$
BEGIN
  PERFORM cron.unschedule('zaehler_aufraeumen') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'zaehler_aufraeumen');
  PERFORM cron.schedule('zaehler_aufraeumen', '15 0 * * *', 'SELECT public.zaehler_aufraeumen()');
END $$;

SELECT public.zaehler_aufraeumen();

DO $$
DECLARE s int; z int;
BEGIN
  SELECT count(*) INTO s FROM public.zaehler_salz;
  SELECT count(*) INTO z FROM public.seitenaufrufe WHERE pfad ~ '^/(treffen|heft|ausweis|drucksachen)/[^*]';
  RAISE NOTICE 'Salze uebrig: %, Pfade mit Zugang uebrig: %', s, z;
  IF z <> 0 THEN RAISE EXCEPTION 'Es stehen noch % Zugaenge in der Statistik', z; END IF;
END $$;
