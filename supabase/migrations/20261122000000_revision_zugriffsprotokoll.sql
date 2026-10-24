-- Revisionszugang: jeder Zugriff einzeln protokolliert, 30 Tage Gueltigkeit.
--
-- Bisher standen am Zugang nur ein Zaehler und der letzte Zeitpunkt. Wer
-- wann wie oft hineingeschaut hat, liess sich nicht nachvollziehen. Jetzt
-- eine Zeile je Abruf: Zeitpunkt, Geschaeftsjahr, IP-Adresse, Browser,
-- Ergebnis. Auch abgewiesene Versuche mit einem bekannten Link (abgelaufen,
-- widerrufen, falsches Jahr) -- gerade die will ein Verein sehen. Versuche
-- mit einem unbekannten Token werden nicht protokolliert: sie gehoeren zu
-- keinem Verein.

CREATE TABLE IF NOT EXISTS public.revisionszugriffe (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId" text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  zugang     uuid NOT NULL REFERENCES public.revisionszugaenge(id) ON DELETE CASCADE,
  am         timestamptz NOT NULL DEFAULT now(),
  jahr       int,
  ergebnis   text NOT NULL,      -- OK | ABGELAUFEN | WIDERRUFEN | FALSCHES_JAHR
  ip         text,
  browser    text
);
CREATE INDEX IF NOT EXISTS revisionszugriffe_zugang ON public.revisionszugriffe (zugang, am DESC);
ALTER TABLE public.revisionszugriffe ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS revisionszugriffe_lesen ON public.revisionszugriffe;
CREATE POLICY revisionszugriffe_lesen ON public.revisionszugriffe FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());
GRANT SELECT ON public.revisionszugriffe TO authenticated;
-- Geschrieben wird nur aus revisionsdaten(); kein Zugriff zum Aendern.

-- Eine Abweisung wird als Ergebnis zurueckgegeben statt geworfen: eine
-- geworfene Ausnahme rollte auch die Protokollzeile zurueck.
CREATE OR REPLACE FUNCTION public.revisionsdaten(p_token text, p_jahr integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  z public.revisionszugaenge%ROWTYPE;
  v_kopf jsonb := coalesce(nullif(current_setting('request.headers', true), '')::jsonb, '{}'::jsonb);
  v_ip text := nullif(btrim(split_part(coalesce(v_kopf ->> 'x-forwarded-for', v_kopf ->> 'x-real-ip', ''), ',', 1)), '');
  v_browser text := left(v_kopf ->> 'user-agent', 200);
  v_ergebnis text := 'OK';
BEGIN
  SELECT * INTO z FROM public.revisionszugaenge
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  -- Unbekannt: dieselbe Meldung wie abgelaufen oder widerrufen. Wer ein
  -- Token erraet, soll nicht auch noch erfahren, ob es einmal gueltig war.
  IF z.id IS NULL THEN
    RETURN jsonb_build_object('fehler', 'Dieser Zugang ist nicht (mehr) gueltig.');
  END IF;

  IF z.widerrufen_am IS NOT NULL THEN v_ergebnis := 'WIDERRUFEN';
  ELSIF z.gueltig_bis < current_date THEN v_ergebnis := 'ABGELAUFEN';
  ELSIF z.jahr IS NOT NULL AND z.jahr <> p_jahr THEN v_ergebnis := 'FALSCHES_JAHR';
  END IF;

  INSERT INTO public.revisionszugriffe ("tenantId", zugang, jahr, ergebnis, ip, browser)
  VALUES (z."tenantId", z.id, p_jahr, v_ergebnis, v_ip, v_browser);

  IF v_ergebnis IN ('WIDERRUFEN', 'ABGELAUFEN') THEN
    RETURN jsonb_build_object('fehler', 'Dieser Zugang ist nicht (mehr) gueltig.');
  END IF;
  IF v_ergebnis = 'FALSCHES_JAHR' THEN
    RETURN jsonb_build_object('fehler', format('Dieser Zugang gilt nur fuer das Geschaeftsjahr %s.', z.jahr),
                              'nur_jahr', z.jahr);
  END IF;

  UPDATE public.revisionszugaenge
     SET zuletzt_gesehen = now(), zugriffe = zugriffe + 1
   WHERE id = z.id;

  RETURN public.revisionsbericht_fuer(z."tenantId", p_jahr)
         || jsonb_build_object('zugang', jsonb_build_object(
              'fuer', z.bezeichnung, 'gueltig_bis', z.gueltig_bis));
END $function$;

-- Gueltigkeit: hoechstens 30 Tage (bisher "ein Monat").
DO $$
DECLARE v_def text; v_neu text;
BEGIN
  SELECT pg_get_functiondef('public.revisionszugang_erstellen(text, date, integer)'::regprocedure) INTO v_def;
  v_neu := replace(replace(v_def,
    'p_gueltig_bis > current_date + interval ''1 month''', 'p_gueltig_bis > current_date + 30'),
    'Hoechstens ein Monat Gueltigkeit', 'Hoechstens 30 Tage Gueltigkeit');
  IF v_neu = v_def THEN RAISE EXCEPTION 'Gueltigkeitspruefung in revisionszugang_erstellen nicht gefunden'; END IF;
  EXECUTE v_neu;
END $$;
