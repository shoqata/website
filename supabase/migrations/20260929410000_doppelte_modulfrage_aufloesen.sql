-- Zwei Funktionen, die dasselbe beantworten -- eine davon war nie noetig.
--
-- Am 27.09.2026 legte ich modul_aktiv_oeffentlich() an, mit der Begruendung,
-- modul_aktiv() frage nur current_tenant() und gebe einem nicht angemeldeten
-- Besucher deshalb immer false. Das stimmte -- fuer die ERSTE Fassung von
-- modul_aktiv (20260921200000). Drei Migrationen spaeter, am 21.09., war sie
-- laengst um den Rueckfall auf request_tenant() ergaenzt. Ich hatte die alte
-- Datei gelesen statt der zuletzt gueltigen.
--
-- Seither beantworten beide dieselbe Frage, mit demselben Rumpf und denselben
-- Rechten (anon, authenticated). Zwei Stellen, die dasselbe ausrechnen, laufen
-- frueher oder spaeter auseinander -- und dann entscheidet bei einer
-- kostenpflichtigen Vorlage die eine anders als die andere.
--
-- Hier wird nicht gelöscht und gehofft. Zuerst wird fuer JEDE Kombination aus
-- Verein und Modul geprueft, ob beide wirklich dasselbe sagen. Erst wenn das
-- lueckenlos stimmt, werden die Aufrufer umgehaengt und das Duplikat entfernt.

DO $$
DECLARE
  v_zurueck text := current_user;
  r RECORD;
  v_a boolean; v_b boolean;
  v_geprueft int := 0;
  v_ungleich int := 0;
BEGIN
  RAISE NOTICE '--- Sagen beide dasselbe? ---';
  FOR r IN
    SELECT t.id AS verein, m.schluessel AS modul
      FROM public.tenants t CROSS JOIN public.modules m
  LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('app_metadata', json_build_object('tenant', r.verein))::text, true);
    v_a := public.modul_aktiv(r.modul);
    v_b := public.modul_aktiv_oeffentlich(r.modul);
    v_geprueft := v_geprueft + 1;
    IF v_a IS DISTINCT FROM v_b THEN
      v_ungleich := v_ungleich + 1;
      RAISE WARNING '  UNGLEICH  % / %  modul_aktiv=%  _oeffentlich=%',
        r.verein, r.modul, v_a, v_b;
    END IF;
  END LOOP;
  -- Auf gueltiges leeres JSON zuruecksetzen, nicht auf NULL: set_config
  -- schreibt dafuer leeren TEXT, und ''::jsonb wirft beim naechsten Leser.
  PERFORM set_config('request.jwt.claims', '{}', true);

  RAISE NOTICE '  % Kombinationen geprueft, % ungleich', v_geprueft, v_ungleich;

  IF v_geprueft = 0 THEN
    RAISE EXCEPTION 'Nichts geprueft -- keine Vereine oder keine Module. Abbruch, bevor etwas entfernt wird.';
  END IF;
  IF v_ungleich > 0 THEN
    RAISE EXCEPTION 'Die beiden Funktionen antworten verschieden. Nichts wurde geaendert.';
  END IF;
  EXECUTE format('SET ROLE %I', v_zurueck);
END $$;


-- Die Aufrufer umhaengen. Beide Stellen sind oeffentlich erreichbar und
-- muessen deshalb weiter fuer anon funktionieren -- modul_aktiv() tut das,
-- seit sie auf request_tenant() zurueckfaellt.

CREATE OR REPLACE FUNCTION public.startseiten_vorlage()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT v.schluessel
       FROM public.startseiten_vorlagen v
      WHERE v.aktiv
        AND v.schluessel = upper(coalesce(
              (SELECT s.system ->> 'startseitenVorlage' FROM public.settings s
                WHERE s."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
                  AND s.id = 'system'), ''))
        AND (v.modul IS NULL OR public.modul_aktiv(v.modul))),
    'KLASSISCH');
$$;

DROP POLICY IF EXISTS videos_public_read ON public.videos;
CREATE POLICY videos_public_read ON public.videos FOR SELECT TO anon, authenticated
USING (
  status = 'OEFFENTLICH'
  AND "tenantId" = coalesce(public.current_tenant(), public.request_tenant())
  AND public.modul_aktiv('VIDEOS')
);


-- Nichts darf uebrig bleiben, das noch darauf zeigt.
DO $$
DECLARE r RECORD; v_rest int := 0;
BEGIN
  FOR r IN
    SELECT 'Funktion ' || p.proname AS wo FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.proname <> 'modul_aktiv_oeffentlich'
       AND p.prosrc LIKE '%modul_aktiv_oeffentlich%'
    UNION ALL
    SELECT 'Regel ' || polname || ' auf ' || polrelid::regclass FROM pg_policy
     WHERE coalesce(pg_get_expr(polqual, polrelid),'') LIKE '%modul_aktiv_oeffentlich%'
        OR coalesce(pg_get_expr(polwithcheck, polrelid),'') LIKE '%modul_aktiv_oeffentlich%'
  LOOP
    v_rest := v_rest + 1;
    RAISE WARNING '  zeigt noch darauf: %', r.wo;
  END LOOP;

  IF v_rest > 0 THEN
    RAISE EXCEPTION '% Stelle(n) benutzen modul_aktiv_oeffentlich noch. Nicht entfernt.', v_rest;
  END IF;

  DROP FUNCTION IF EXISTS public.modul_aktiv_oeffentlich(text);
  RAISE NOTICE 'modul_aktiv_oeffentlich entfernt -- es gibt wieder eine Stelle, die ueber Module entscheidet.';
END $$;


-- Gegenprobe nach dem Umbau: der Besucher bekommt, was er vorher bekam.
DO $$
DECLARE v text;
BEGIN
  PERFORM set_config('request.jwt.claims', '{}', true);
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, true);
  v := public.startseiten_vorlage();
  RAISE NOTICE 'koretini.me bekommt nach dem Umbau: %', v;
  PERFORM set_config('request.headers', '{}', true);
END $$;
