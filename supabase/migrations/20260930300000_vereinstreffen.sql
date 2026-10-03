-- Vereinstreffen auf unityhub.
--
-- Ein Anlass, an dem mehrere Vereine teilnehmen -- dazu Gastvereine ohne
-- Zugang zur Plattform und einzelne Gaeste -- mit einem Tagesprogramm.
--
-- Vier Entscheidungen des Betreibers bestimmen den Entwurf:
--
--   1. Gastgeber ist ausschliesslich der Betreiber. Vereine sind
--      Teilnehmer. Darum liegen diese Tabellen auf Plattformebene und
--      tragen KEINE tenantId: ein Treffen gehoert keinem Verein.
--   2. Gastvereine kommen ueber einen Link ohne Konto.
--   3. Die oeffentliche Seite steht auf unityhub.li.
--   4. Was die Teilnahme kostet, wird JE TREFFEN eingestellt -- gar
--      nichts, pro Verein oder pro Kopf.
--
-- Punkt 4 ist der Grund, weshalb der Preis hier als zwei Felder steht und
-- nicht als Zahl: "50 Franken" beantwortet die Frage nicht, solange
-- unklar ist, ob sie je Verein oder je Person gelten.

CREATE TABLE IF NOT EXISTS public.treffen (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titel         text NOT NULL,
  beschreibung  text,
  datum         date NOT NULL,
  beginn        time,
  ende          date,
  ort           text,
  adresse       text,
  status        text NOT NULL DEFAULT 'ENTWURF'
                CHECK (status IN ('ENTWURF','OEFFENTLICH','BEENDET')),
  anmeldeschluss date,

  -- Was die Teilnahme kostet. Die Art gehoert zum Betrag: "50" allein
  -- sagt nicht, ob je Verein oder je Person.
  preis_art     text NOT NULL DEFAULT 'KEINE'
                CHECK (preis_art IN ('KEINE','PRO_VEREIN','PRO_KOPF')),
  preis_betrag  numeric(10,2) NOT NULL DEFAULT 0
                CHECK (preis_betrag >= 0),
  waehrung      text NOT NULL DEFAULT 'CHF',

  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  erstellt_von  text,
  CONSTRAINT treffen_preis_stimmig
    CHECK ((preis_art = 'KEINE' AND preis_betrag = 0) OR (preis_art <> 'KEINE' AND preis_betrag > 0)),
  CONSTRAINT treffen_ende_nach_datum CHECK (ende IS NULL OR ende >= datum)
);

-- Teilnehmer. Drei Arten, und sie unterscheiden sich im ZUGANG, nicht im
-- Rang: ein Verein der Plattform meldet sich an seinem Admin an, ein
-- Gastverein ueber einen Link, ein Gast gar nicht.
CREATE TABLE IF NOT EXISTS public.treffen_teilnehmer (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treffen_id    uuid NOT NULL REFERENCES public.treffen(id) ON DELETE CASCADE,
  art           text NOT NULL CHECK (art IN ('VEREIN','GASTVEREIN','GAST')),

  -- Nur bei art='VEREIN': der Verein auf der Plattform.
  "tenantId"    text REFERENCES public.tenants(id) ON DELETE SET NULL,
  -- Bei GASTVEREIN und GAST: der Name, denn es gibt keine Vereinszeile.
  name          text,
  kontakt_name  text,
  kontakt_email text,

  -- Der Link fuer Gastvereine. Nur der Hash, nie das Token selbst --
  -- dieselbe Ueberlegung wie beim Revisionszugang.
  token_hash    text UNIQUE,
  gueltig_bis   date,

  zugesagt      boolean,
  personen      int NOT NULL DEFAULT 0 CHECK (personen >= 0),
  bemerkung     text,
  eingeladen_am timestamptz NOT NULL DEFAULT now(),
  geantwortet_am timestamptz,

  CONSTRAINT teilnehmer_verein_oder_name CHECK (
    (art = 'VEREIN'     AND "tenantId" IS NOT NULL) OR
    (art <> 'VEREIN'    AND coalesce(btrim(name),'') <> '')),
  -- Derselbe Verein nicht zweimal am selben Treffen.
  CONSTRAINT teilnehmer_verein_einmal UNIQUE (treffen_id, "tenantId")
);

-- Das Tagesprogramm. Parallele Spuren sind der Grund, weshalb "spur" ein
-- freies Feld ist und keine Nummer: bei einem Turnier heissen sie
-- "Feld A" und "Saal", nicht 1 und 2.
CREATE TABLE IF NOT EXISTS public.treffen_programm (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treffen_id    uuid NOT NULL REFERENCES public.treffen(id) ON DELETE CASCADE,
  tag           date,
  beginn        time NOT NULL,
  dauer_min     int CHECK (dauer_min IS NULL OR dauer_min > 0),
  titel         text NOT NULL,
  ort           text,
  verantwortlich text,
  spur          text NOT NULL DEFAULT 'Alle',
  -- Manches gilt allen, eine Vertreterrunde nur den Delegationsleitungen.
  fuer          text NOT NULL DEFAULT 'ALLE' CHECK (fuer IN ('ALLE','VERTRETER')),
  -- Erst freigegeben, dann sichtbar. Sonst blinkt jede Zwischenfassung
  -- bei zwanzig Vereinen auf dem Telefon auf.
  freigegeben   boolean NOT NULL DEFAULT false,
  reihenfolge   int NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS treffen_programm_zeit
  ON public.treffen_programm (treffen_id, tag, beginn, reihenfolge);
CREATE INDEX IF NOT EXISTS treffen_teilnehmer_treffen
  ON public.treffen_teilnehmer (treffen_id);


-- ---------------------------------------------------------- Zugriff
ALTER TABLE public.treffen             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treffen_teilnehmer  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treffen_programm    ENABLE ROW LEVEL SECURITY;

-- Schreiben darf allein der Betreiber. Vereine sind Teilnehmer, nicht
-- Gastgeber -- so war die Entscheidung, und sie steht hier und nicht in
-- der Oberflaeche.
DROP POLICY IF EXISTS treffen_betreiber ON public.treffen;
CREATE POLICY treffen_betreiber ON public.treffen FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS treffen_teilnehmer_betreiber ON public.treffen_teilnehmer;
CREATE POLICY treffen_teilnehmer_betreiber ON public.treffen_teilnehmer FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS treffen_programm_betreiber ON public.treffen_programm;
CREATE POLICY treffen_programm_betreiber ON public.treffen_programm FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

-- Ein eingeladener Verein sieht das Treffen und darf seine EIGENE Zusage
-- setzen -- nicht die der anderen, und nichts am Treffen selbst.
DROP POLICY IF EXISTS treffen_teilnehmer_lesen ON public.treffen_teilnehmer;
CREATE POLICY treffen_teilnehmer_lesen ON public.treffen_teilnehmer FOR SELECT TO authenticated
  USING (public.is_platform_admin() OR "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS treffen_teilnehmer_eigene_zusage ON public.treffen_teilnehmer;
CREATE POLICY treffen_teilnehmer_eigene_zusage ON public.treffen_teilnehmer FOR UPDATE TO authenticated
  USING (art = 'VEREIN' AND "tenantId" = public.current_tenant() AND public.is_staff())
  WITH CHECK (art = 'VEREIN' AND "tenantId" = public.current_tenant() AND public.is_staff());

DROP POLICY IF EXISTS treffen_lesen ON public.treffen;
CREATE POLICY treffen_lesen ON public.treffen FOR SELECT TO anon, authenticated
  USING (
    status = 'OEFFENTLICH'
    OR public.is_platform_admin()
    OR EXISTS (SELECT 1 FROM public.treffen_teilnehmer t
                WHERE t.treffen_id = id AND t."tenantId" = public.current_tenant())
  );

-- Das Programm erst, wenn es freigegeben ist.
DROP POLICY IF EXISTS treffen_programm_lesen ON public.treffen_programm;
CREATE POLICY treffen_programm_lesen ON public.treffen_programm FOR SELECT TO anon, authenticated
  USING (
    public.is_platform_admin()
    OR (freigegeben AND EXISTS (SELECT 1 FROM public.treffen t
                                 WHERE t.id = treffen_id AND t.status = 'OEFFENTLICH'))
  );

GRANT SELECT ON public.treffen, public.treffen_programm TO anon, authenticated;
GRANT SELECT, UPDATE ON public.treffen_teilnehmer TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.treffen, public.treffen_teilnehmer,
      public.treffen_programm TO authenticated;


-- ------------------------------------------------------ Was es kostet
-- Die Kostenrechnung gehoert an EINE Stelle. Rechnete die Oberflaeche mit,
-- stuende auf der Einladung eine andere Zahl als auf der Rechnung.
CREATE OR REPLACE FUNCTION public.treffen_kosten(p_treffen uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'art', t.preis_art, 'betrag', t.preis_betrag, 'waehrung', t.waehrung,
    'vereine',  (SELECT count(*) FROM public.treffen_teilnehmer x
                  WHERE x.treffen_id = t.id AND x.art IN ('VEREIN','GASTVEREIN')
                    AND coalesce(x.zugesagt,false)),
    'personen', (SELECT coalesce(sum(x.personen),0) FROM public.treffen_teilnehmer x
                  WHERE x.treffen_id = t.id AND coalesce(x.zugesagt,false)),
    'summe', CASE t.preis_art
      WHEN 'KEINE' THEN 0
      WHEN 'PRO_VEREIN' THEN t.preis_betrag *
        (SELECT count(*) FROM public.treffen_teilnehmer x
          WHERE x.treffen_id = t.id AND x.art IN ('VEREIN','GASTVEREIN')
            AND coalesce(x.zugesagt,false))
      WHEN 'PRO_KOPF' THEN t.preis_betrag *
        (SELECT coalesce(sum(x.personen),0) FROM public.treffen_teilnehmer x
          WHERE x.treffen_id = t.id AND coalesce(x.zugesagt,false))
    END)
  FROM public.treffen t WHERE t.id = p_treffen;
$$;
REVOKE ALL ON FUNCTION public.treffen_kosten(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_kosten(uuid) TO authenticated;


-- Was die Oeffentlichkeit auf unityhub.li sieht: das Treffen, das
-- freigegebene Programm und WELCHE Vereine kommen -- aber keine
-- Kontaktdaten und keine Kopfzahlen. Wer dabei ist, ist eine Ankuendigung;
-- wie viele jemand schickt, geht niemanden ausser dem Gastgeber etwas an.
CREATE OR REPLACE FUNCTION public.treffen_oeffentlich()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
    'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
    'ort', t.ort, 'adresse', t.adresse,
    'anmeldeschluss', t.anmeldeschluss,
    'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung,
    'vereine', (SELECT coalesce(jsonb_agg(coalesce(te.name, tn.name) ORDER BY coalesce(te.name, tn.name)), '[]'::jsonb)
                  FROM public.treffen_teilnehmer te
                  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                 WHERE te.treffen_id = t.id AND te.art IN ('VEREIN','GASTVEREIN')
                   AND coalesce(te.zugesagt,false)),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                    'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                    'spur', p.spur, 'fuer', p.fuer)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = t.id AND p.freigegeben)
    ) ORDER BY t.datum), '[]'::jsonb)
  FROM public.treffen t
 WHERE t.status = 'OEFFENTLICH' AND coalesce(t.ende, t.datum) >= current_date - 1;
$$;
REVOKE ALL ON FUNCTION public.treffen_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_oeffentlich() TO anon, authenticated;
