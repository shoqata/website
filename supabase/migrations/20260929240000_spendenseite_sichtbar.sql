-- Wann die Spendenseite ueberhaupt erscheint.
--
-- Gewuenscht: sie soll sich ausblenden lassen, wenn gerade nichts laeuft.
-- Automatisch an einen Aufruf zu koppeln waere aber falsch: eine allgemeine
-- Spende ohne Aufruf bleibt sinnvoll, und bis heute war das der Normalfall
-- -- Koretini hat noch keinen Aufruf und nimmt trotzdem Spenden an.
--
-- Deshalb drei Stellungen statt ein/aus:
--   IMMER       die Seite steht immer offen (Vorgabe, Stand bisher)
--   BEI_AUFRUF  nur solange mindestens ein Aufruf laeuft
--   AUS         gar nicht
--
-- Entschieden wird das hier und nicht in der Navigation: sonst waere die
-- Seite ueber die eingetippte Adresse weiter erreichbar, und "ausgeblendet"
-- hiesse nur "schwerer zu finden".
CREATE OR REPLACE FUNCTION public.spendenseite_sichtbar()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH v AS (SELECT coalesce(public.current_tenant(), public.request_tenant()) AS verein),
       s AS (SELECT upper(coalesce(
               (SELECT st.system ->> 'spendenseite' FROM public.settings st, v
                 WHERE st."tenantId" = v.verein AND st.id='system'), 'IMMER')) AS stellung)
  SELECT public.modul_aktiv('SPENDEN')
     AND (SELECT stellung FROM s) <> 'AUS'
     AND ((SELECT stellung FROM s) <> 'BEI_AUFRUF'
          OR EXISTS (SELECT 1 FROM public.spendenaufrufe a, v
                      WHERE a."tenantId" = v.verein AND a.status='OEFFENTLICH'
                        AND (a.beginnt_am IS NULL OR a.beginnt_am <= current_date)
                        AND (a.endet_am   IS NULL OR a.endet_am   >= current_date)));
$$;
REVOKE ALL ON FUNCTION public.spendenseite_sichtbar() FROM public;
GRANT EXECUTE ON FUNCTION public.spendenseite_sichtbar() TO anon, authenticated;

DO $$
DECLARE v_back text := current_user; v_ergebnis boolean; v_alt text;
  PROCEDURE_dummy int;
BEGIN
  SELECT system ->> 'spendenseite' INTO v_alt FROM public.settings
   WHERE "tenantId"='koretini' AND id='system';

  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);

  FOR v_ergebnis IN SELECT true LOOP END LOOP;  -- Platzhalter, damit die Schleife unten klar liest

  -- Vorgabe: sichtbar
  EXECUTE 'SET ROLE anon'; SELECT public.spendenseite_sichtbar() INTO v_ergebnis;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '1. ohne Einstellung (Vorgabe IMMER): %', v_ergebnis;

  UPDATE public.settings SET system = jsonb_set(coalesce(system,'{}'::jsonb),'{spendenseite}','"AUS"')
   WHERE "tenantId"='koretini' AND id='system';
  EXECUTE 'SET ROLE anon'; SELECT public.spendenseite_sichtbar() INTO v_ergebnis;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '2. auf AUS: % (erwartet f)', v_ergebnis;

  UPDATE public.settings SET system = jsonb_set(coalesce(system,'{}'::jsonb),'{spendenseite}','"BEI_AUFRUF"')
   WHERE "tenantId"='koretini' AND id='system';
  EXECUTE 'SET ROLE anon'; SELECT public.spendenseite_sichtbar() INTO v_ergebnis;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '3. BEI_AUFRUF, ohne laufenden Aufruf: % (erwartet f)', v_ergebnis;

  INSERT INTO public.spendenaufrufe (id,"tenantId",titel,status)
  VALUES ('probe-sichtbar','koretini','Probeaufruf','OEFFENTLICH');
  EXECUTE 'SET ROLE anon'; SELECT public.spendenseite_sichtbar() INTO v_ergebnis;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '4. BEI_AUFRUF, mit laufendem Aufruf: % (erwartet t)', v_ergebnis;

  DELETE FROM public.spendenaufrufe WHERE id='probe-sichtbar';
  UPDATE public.settings SET system = system - 'spendenseite'
   WHERE "tenantId"='koretini' AND id='system';
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '5. zurueckgesetzt auf die Vorgabe (vorher: %)', coalesce(v_alt,'nicht gesetzt');
END $$;
