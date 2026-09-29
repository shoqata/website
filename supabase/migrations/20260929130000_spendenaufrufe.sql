-- Spendenaufrufe.
--
-- Bisher gab es sie nicht: der Spender tippte selbst einen freien Zweck ins
-- Formular, und der Verein konnte weder einen Aufruf anlegen noch sehen,
-- wieviel auf ein Anliegen zusammengekommen ist. Genau danach wurde gefragt.
--
-- Ein Aufruf ist ein Anliegen mit Titel, Text, Ziel und Frist. Spenden
-- haengen daran; eine Spende ohne Aufruf bleibt moeglich und zaehlt als
-- allgemeine Spende.

CREATE TABLE IF NOT EXISTS public.spendenaufrufe (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  titel         text NOT NULL,
  text          text,
  bild          text,
  ziel_betrag   numeric(12,2),
  waehrung      text NOT NULL DEFAULT 'CHF' CHECK (waehrung IN ('CHF','EUR')),
  beginnt_am    date,
  endet_am      date,
  status        text NOT NULL DEFAULT 'ENTWURF'
                CHECK (status IN ('ENTWURF','OEFFENTLICH','BEENDET')),
  reihenfolge   int NOT NULL DEFAULT 100,
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  erstellt_von  text
);

ALTER TABLE public.spendenaufrufe ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.spendenaufrufe FROM anon, authenticated;
GRANT SELECT ON public.spendenaufrufe TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.spendenaufrufe TO authenticated;

DROP POLICY IF EXISTS aufrufe_public_read ON public.spendenaufrufe;
CREATE POLICY aufrufe_public_read ON public.spendenaufrufe FOR SELECT TO anon, authenticated
USING (
  status = 'OEFFENTLICH'
  AND "tenantId" = coalesce(public.current_tenant(), public.request_tenant())
  AND public.modul_aktiv('SPENDEN')
  AND (beginnt_am IS NULL OR beginnt_am <= current_date)
  AND (endet_am   IS NULL OR endet_am   >= current_date)
);

DROP POLICY IF EXISTS aufrufe_staff_all ON public.spendenaufrufe;
CREATE POLICY aufrufe_staff_all ON public.spendenaufrufe FOR ALL TO authenticated
USING (public.is_staff() AND "tenantId" = public.current_tenant() AND public.modul_aktiv('SPENDEN'))
WITH CHECK (public.is_staff() AND "tenantId" = public.current_tenant() AND public.modul_aktiv('SPENDEN'));

-- Die Spende haengt am Aufruf. Ohne Aufruf bleibt sie gueltig.
ALTER TABLE public.donations
  ADD COLUMN IF NOT EXISTS aufruf text REFERENCES public.spendenaufrufe(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS donations_aufruf_idx ON public.donations (aufruf);


-- Was die oeffentliche Seite braucht: die Aufrufe samt Stand.
--
-- Der Stand wird hier gerechnet und nicht im Browser: sonst muesste die
-- Seite alle Spenden lesen duerfen, um sie zu summieren -- und damit auch
-- Namen und Betraege einzelner Spender.
CREATE OR REPLACE FUNCTION public.spendenaufrufe_oeffentlich()
RETURNS TABLE (id text, titel text, text text, bild text,
               ziel_betrag numeric, waehrung text, endet_am date,
               gesammelt numeric, anzahl int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id, a.titel, a.text, a.bild, a.ziel_betrag, a.waehrung, a.endet_am,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status = 'BEZAHLT'), 0)::numeric,
         coalesce((SELECT count(*) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status = 'BEZAHLT'), 0)::int
    FROM public.spendenaufrufe a
   WHERE a.status = 'OEFFENTLICH'
     AND a."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
     AND public.modul_aktiv('SPENDEN')
     AND (a.beginnt_am IS NULL OR a.beginnt_am <= current_date)
     AND (a.endet_am   IS NULL OR a.endet_am   >= current_date)
   ORDER BY a.reihenfolge, a.erstellt_am DESC;
$$;
REVOKE ALL ON FUNCTION public.spendenaufrufe_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.spendenaufrufe_oeffentlich() TO anon, authenticated;

-- Fuer die Verwaltung: derselbe Stand, aber auch fuer Entwuerfe.
CREATE OR REPLACE FUNCTION public.spendenaufrufe_stand()
RETURNS TABLE (id text, gesammelt numeric, anzahl int, offen numeric)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='BEZAHLT'),0)::numeric,
         coalesce((SELECT count(*) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='BEZAHLT'),0)::int,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='OFFEN'),0)::numeric
    FROM public.spendenaufrufe a
   WHERE a."tenantId" = public.current_tenant() AND public.is_staff();
$$;
REVOKE ALL ON FUNCTION public.spendenaufrufe_stand() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.spendenaufrufe_stand() TO authenticated;

DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT policyname, cmd FROM pg_policies
            WHERE schemaname='public' AND tablename='spendenaufrufe' ORDER BY 1 LOOP
    RAISE NOTICE '  Regel % (%)', r.policyname, r.cmd;
  END LOOP;
END $$;
