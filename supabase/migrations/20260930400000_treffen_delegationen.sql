-- Vereinstreffen, Stufe 2: wer kommt, und mit wem.
--
-- Stufe 1 konnte ein Treffen ankuendigen. Damit es die WhatsApp-Liste
-- ersetzt, muss der Teilnehmer sich SELBST eintragen koennen -- sonst
-- tippt der Gastgeber acht Vereine mal dreissig Personen ab, und genau
-- dann wird das Modul nicht benutzt.
--
-- Drei Wege hinein, und sie unterscheiden sich nur im Zugang:
--   VEREIN      meldet sich an seinem Admin an
--   GASTVEREIN  ueber einen Link ohne Konto
--   GAST        traegt der Gastgeber ein
--
-- Der Link traegt dieselbe Ueberlegung wie der Revisionszugang:
-- gespeichert wird nur der Hash. Laege das Token im Klartext, waere ein
-- Leseblick in die Datenbank gleichbedeutend mit Zugriff auf jede
-- Teilnehmerliste.

CREATE TABLE IF NOT EXISTS public.treffen_delegation (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  teilnehmer_id uuid NOT NULL REFERENCES public.treffen_teilnehmer(id) ON DELETE CASCADE,
  name          text NOT NULL,
  rolle         text NOT NULL DEFAULT 'TEILNEHMER'
                CHECK (rolle IN ('LEITUNG','TEILNEHMER')),
  bemerkung     text,          -- Essenswunsch, Anreise, was der Verein mitgibt
  erfasst_am    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS treffen_delegation_teilnehmer
  ON public.treffen_delegation (teilnehmer_id);

ALTER TABLE public.treffen_delegation ENABLE ROW LEVEL SECURITY;

-- Der Gastgeber sieht alles. Ein Verein sieht und pflegt NUR seine
-- eigene Delegation -- nicht die der anderen. Das ist der Kern: ein
-- Treffen darf nie der Weg werden, ueber den ein Verein die Namensliste
-- eines anderen liest.
DROP POLICY IF EXISTS treffen_delegation_betreiber ON public.treffen_delegation;
CREATE POLICY treffen_delegation_betreiber ON public.treffen_delegation FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS treffen_delegation_eigene ON public.treffen_delegation;
CREATE POLICY treffen_delegation_eigene ON public.treffen_delegation FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.treffen_teilnehmer t
                  WHERE t.id = teilnehmer_id AND t.art = 'VEREIN'
                    AND t."tenantId" = public.current_tenant() AND public.is_staff()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.treffen_teilnehmer t
                  WHERE t.id = teilnehmer_id AND t.art = 'VEREIN'
                    AND t."tenantId" = public.current_tenant() AND public.is_staff()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.treffen_delegation TO authenticated;


-- ------------------------------------------------ Link fuer Gastvereine
-- Erzeugt das Token, gibt es GENAU EINMAL zurueck und speichert nur den
-- Hash. Gueltig bis zum Anmeldeschluss, hoechstens aber bis zum Treffen
-- selbst -- danach gibt es nichts mehr einzutragen.
CREATE OR REPLACE FUNCTION public.treffen_zugang_erstellen(p_teilnehmer uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_token text;
  v_bis   date;
  r RECORD;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber darf Zugaenge ausstellen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT te.*, t.datum, t.ende, t.anmeldeschluss, t.titel
    INTO r
    FROM public.treffen_teilnehmer te
    JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'Teilnehmer nicht gefunden.';
  END IF;
  IF r.art <> 'GASTVEREIN' THEN
    RAISE EXCEPTION 'Ein Link ist nur fuer Gastvereine noetig. Vereine der Plattform melden sich an ihrem Admin an.';
  END IF;

  v_bis := least(coalesce(r.anmeldeschluss, coalesce(r.ende, r.datum)),
                 coalesce(r.ende, r.datum));
  IF v_bis < current_date THEN
    RAISE EXCEPTION 'Das Treffen liegt in der Vergangenheit.';
  END IF;

  v_token := replace(replace(replace(
               encode(gen_random_bytes(32), 'base64'), '+','-'), '/','_'), '=','');

  UPDATE public.treffen_teilnehmer
     SET token_hash = encode(digest(v_token, 'sha256'), 'hex'),
         gueltig_bis = v_bis
   WHERE id = p_teilnehmer;

  RETURN jsonb_build_object('token', v_token, 'gueltig_bis', v_bis,
                            'fuer', r.name, 'treffen', r.titel);
END $$;
REVOKE ALL ON FUNCTION public.treffen_zugang_erstellen(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_zugang_erstellen(uuid) TO authenticated;


CREATE OR REPLACE FUNCTION public.treffen_zugang_widerrufen(p_teilnehmer uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_zeilen int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber darf widerrufen.' USING ERRCODE='insufficient_privilege';
  END IF;
  UPDATE public.treffen_teilnehmer
     SET token_hash = NULL, gueltig_bis = NULL
   WHERE id = p_teilnehmer AND token_hash IS NOT NULL;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  -- Ein UPDATE, das null Zeilen trifft, wirft keinen Fehler.
  IF v_zeilen <> 1 THEN
    RAISE EXCEPTION 'Kein gueltiger Zugang gefunden.';
  END IF;
  RETURN jsonb_build_object('widerrufen', true);
END $$;
REVOKE ALL ON FUNCTION public.treffen_zugang_widerrufen(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_zugang_widerrufen(uuid) TO authenticated;


-- ------------------------------------------- Was ein Teilnehmer sieht
-- Eine Rechnung, zwei Wege hinein: der Gastverein ueber sein Token, der
-- Verein der Plattform ueber seine Sitzung. Zwei Fassungen desselben
-- Berichts liefen frueher oder spaeter auseinander.
--
-- Diese Funktion ist bewusst NICHT fuer anon oder authenticated
-- freigegeben; nur die Wrapper rufen sie, und die haben den Teilnehmer
-- vorher nachgewiesen.
CREATE OR REPLACE FUNCTION public.treffen_sicht(p_teilnehmer uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'teilnehmer_id', te.id,
    'wer',   coalesce(te.name, tn.name, te."tenantId"),
    'art',   te.art,
    'zugesagt', te.zugesagt,
    'personen', te.personen,
    'bemerkung', te.bemerkung,
    'gueltig_bis', te.gueltig_bis,
    'treffen', jsonb_build_object(
      'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
      'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
      'ort', t.ort, 'adresse', t.adresse, 'status', t.status,
      'anmeldeschluss', t.anmeldeschluss,
      'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung),
    -- Nur die EIGENE Delegation. Ein Treffen darf nie der Weg werden,
    -- ueber den ein Verein die Namensliste eines anderen liest.
    'delegation', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                     'id', d.id, 'name', d.name, 'rolle', d.rolle, 'bemerkung', d.bemerkung)
                     ORDER BY d.rolle, d.name), '[]'::jsonb)
                    FROM public.treffen_delegation d WHERE d.teilnehmer_id = te.id),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                    'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                    'spur', p.spur, 'fuer', p.fuer)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = t.id AND p.freigegeben)
  )
  FROM public.treffen_teilnehmer te
  JOIN public.treffen t ON t.id = te.treffen_id
  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
 WHERE te.id = p_teilnehmer;
$$;
REVOKE ALL ON FUNCTION public.treffen_sicht(uuid) FROM public, anon, authenticated;


-- Das Token einloesen. Dieselbe Meldung fuer "gibt es nicht", "widerrufen"
-- und "abgelaufen": wer ein Token erraet, soll nicht auch noch erfahren,
-- ob es einmal gueltig war.
CREATE OR REPLACE FUNCTION public.treffen_token_pruefen(p_token text)
RETURNS uuid
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_id uuid; v_bis date;
BEGIN
  SELECT id, gueltig_bis INTO v_id, v_bis
    FROM public.treffen_teilnehmer
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_id IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.treffen_token_pruefen(text) FROM public, anon, authenticated;


CREATE OR REPLACE FUNCTION public.treffen_gast_lesen(p_token text)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.treffen_sicht(public.treffen_token_pruefen(p_token));
$$;
REVOKE ALL ON FUNCTION public.treffen_gast_lesen(text) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_gast_lesen(text) TO anon, authenticated;


-- Die Antwort speichern: zusagen oder absagen, und wer mitkommt.
--
-- Die Delegation wird ERSETZT, nicht ergaenzt. Der Teilnehmer schickt
-- immer die ganze Liste; sonst muesste die Oberflaeche einzelne Zeilen
-- nachhalten, und beim naechsten Oeffnen stuenden Namen doppelt da.
CREATE OR REPLACE FUNCTION public.treffen_antwort_speichern(
  p_teilnehmer uuid, p_zugesagt boolean, p_bemerkung text, p_delegation jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_treffen uuid;
  v_schluss date;
  v_anzahl int;
BEGIN
  SELECT te.treffen_id, coalesce(t.anmeldeschluss, coalesce(t.ende, t.datum))
    INTO v_treffen, v_schluss
    FROM public.treffen_teilnehmer te JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Teilnehmer nicht gefunden.'; END IF;

  -- Nach dem Anmeldeschluss ist Schluss. Das steht hier und nicht in der
  -- Oberflaeche: eine Maske laesst sich umgehen.
  IF v_schluss < current_date THEN
    RAISE EXCEPTION 'Der Anmeldeschluss am % ist vorbei.', to_char(v_schluss,'DD.MM.YYYY');
  END IF;

  DELETE FROM public.treffen_delegation WHERE teilnehmer_id = p_teilnehmer;

  INSERT INTO public.treffen_delegation (teilnehmer_id, name, rolle, bemerkung)
  SELECT p_teilnehmer,
         btrim(x->>'name'),
         CASE WHEN upper(coalesce(x->>'rolle','')) = 'LEITUNG' THEN 'LEITUNG' ELSE 'TEILNEHMER' END,
         nullif(btrim(coalesce(x->>'bemerkung','')),'')
    FROM jsonb_array_elements(coalesce(p_delegation,'[]'::jsonb)) x
   WHERE coalesce(btrim(x->>'name'),'') <> '';

  SELECT count(*) INTO v_anzahl FROM public.treffen_delegation WHERE teilnehmer_id = p_teilnehmer;

  UPDATE public.treffen_teilnehmer
     SET zugesagt = p_zugesagt,
         bemerkung = nullif(btrim(coalesce(p_bemerkung,'')),''),
         -- Die Kopfzahl ergibt sich aus der Liste. Zwei Zahlen, die
         -- dasselbe meinen, laufen auseinander.
         personen = CASE WHEN p_zugesagt THEN v_anzahl ELSE 0 END,
         geantwortet_am = now()
   WHERE id = p_teilnehmer;

  RETURN jsonb_build_object('gespeichert', true, 'personen', CASE WHEN p_zugesagt THEN v_anzahl ELSE 0 END);
END $$;
REVOKE ALL ON FUNCTION public.treffen_antwort_speichern(uuid,boolean,text,jsonb) FROM public, anon, authenticated;


-- Weg 1: der Gastverein ueber sein Token.
CREATE OR REPLACE FUNCTION public.treffen_gast_antworten(
  p_token text, p_zugesagt boolean, p_bemerkung text, p_delegation jsonb)
RETURNS jsonb
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT public.treffen_antwort_speichern(
    public.treffen_token_pruefen(p_token), p_zugesagt, p_bemerkung, p_delegation);
$$;
REVOKE ALL ON FUNCTION public.treffen_gast_antworten(text,boolean,text,jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_gast_antworten(text,boolean,text,jsonb) TO anon, authenticated;


-- Weg 2: der Verein der Plattform ueber seine Sitzung.
CREATE OR REPLACE FUNCTION public.treffen_meine()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL OR NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(public.treffen_sicht(te.id) ORDER BY t.datum), '[]'::jsonb)
            FROM public.treffen_teilnehmer te
            JOIN public.treffen t ON t.id = te.treffen_id
           WHERE te.art = 'VEREIN' AND te."tenantId" = v_verein
             AND t.status <> 'ENTWURF'
             AND coalesce(t.ende, t.datum) >= current_date - 1);
END $$;
REVOKE ALL ON FUNCTION public.treffen_meine() FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_meine() TO authenticated;


CREATE OR REPLACE FUNCTION public.treffen_mein_antworten(
  p_teilnehmer uuid, p_zugesagt boolean, p_bemerkung text, p_delegation jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Nachweisen, dass dieser Teilnehmer dem eigenen Verein gehoert. Ohne
  -- diese Pruefung koennte jeder Vorstand fuer jeden anderen antworten.
  IF NOT EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = p_teilnehmer AND te.art = 'VEREIN'
                    AND te."tenantId" = public.current_tenant() AND public.is_staff()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.treffen_antwort_speichern(p_teilnehmer, p_zugesagt, p_bemerkung, p_delegation);
END $$;
REVOKE ALL ON FUNCTION public.treffen_mein_antworten(uuid,boolean,text,jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_mein_antworten(uuid,boolean,text,jsonb) TO authenticated;
