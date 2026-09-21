-- Stufe 1 des Modulmarktplatzes: der Schalter, der wirklich schaltet.
--
-- Bisher gab es Modulschalter in den Einstellungen (settings/system.modules).
-- Gemessen: sie werden an keiner einzigen Stelle ausgewertet -- "Events aus"
-- liess die Seite erreichbar, den Verweis stehen und die Daten ueber die
-- Schnittstelle abrufbar. Ein Schalter, der nur die Oberflaeche verbirgt,
-- traegt keine Abrechnung: wer die Entwicklerkonsole oeffnet, nutzt das
-- Modul weiter.
--
-- Deshalb sitzt der Schalter hier in den Zeilenregeln.

-- --- Der Katalog. Gehoert dem Betreiber. ---------------------------------
CREATE TABLE IF NOT EXISTS public.modules (
  schluessel          text PRIMARY KEY,
  name_de             text NOT NULL,
  name_sq             text NOT NULL,
  name_en             text NOT NULL,
  beschreibung_de     text,
  beschreibung_sq     text,
  beschreibung_en     text,
  -- NULL = im Grundpreis enthalten. 0 = ausdruecklich gratis.
  preis_monat         numeric(10,2),
  preis_einmalig      numeric(10,2),
  braucht_einrichtung boolean NOT NULL DEFAULT false,
  status              text NOT NULL DEFAULT 'VERFUEGBAR',
  -- Kernmodule lassen sich nicht abschalten: ohne sie ist die Plattform
  -- kein Vereinsprogramm.
  ist_kern            boolean NOT NULL DEFAULT false,
  reihenfolge         integer NOT NULL DEFAULT 100,
  CONSTRAINT modules_status_gueltig CHECK (status IN ('VERFUEGBAR','BETA','EINGESTELLT'))
);

-- --- Was ein Verein gebucht hat. ----------------------------------------
CREATE TABLE IF NOT EXISTS public.tenant_modules (
  "tenantId"   text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  modul        text NOT NULL REFERENCES public.modules(schluessel) ON DELETE CASCADE,
  -- AN/AUS gehoert dem Verein, GESPERRT dem Betreiber. Der Unterschied ist
  -- wichtig: bei GESPERRT bleiben die Daten stehen, nur der Zugriff endet --
  -- wer nachzahlt, findet alles vor.
  zustand      text NOT NULL DEFAULT 'AUS',
  seit         timestamptz NOT NULL DEFAULT now(),
  testet_bis   date,
  geaendert_von text,
  PRIMARY KEY ("tenantId", modul),
  CONSTRAINT tenant_modules_zustand_gueltig
    CHECK (zustand IN ('AN','AUS','TESTPHASE','GESPERRT'))
);
CREATE INDEX IF NOT EXISTS tenant_modules_verein_idx ON public.tenant_modules ("tenantId");

-- --- Vereine, die nichts zahlen ------------------------------------------
-- Shoqata Humanitare Koretini hat dauerhaft alles offen. Als Regel, nicht
-- als hundert einzeln gesetzte Zeilen: so gilt sie auch fuer Module, die es
-- heute noch gar nicht gibt.
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS alle_module_frei boolean NOT NULL DEFAULT false;

UPDATE public.tenants SET alle_module_frei = true WHERE id = 'koretini';

-- --- Die Frage, die jede Zeilenregel stellt ------------------------------
CREATE OR REPLACE FUNCTION public.modul_aktiv(p_modul text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT true FROM public.tenants t
      WHERE t.id = public.current_tenant() AND t.alle_module_frei),
    (SELECT true FROM public.modules m
      WHERE m.schluessel = p_modul AND m.ist_kern),
    (SELECT tm.zustand IN ('AN','TESTPHASE')
       AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date)
       FROM public.tenant_modules tm
      WHERE tm."tenantId" = public.current_tenant() AND tm.modul = p_modul),
    false);
$$;

REVOKE ALL ON FUNCTION public.modul_aktiv(text) FROM public;
GRANT EXECUTE ON FUNCTION public.modul_aktiv(text) TO anon, authenticated;

-- --- Zugriff auf die beiden Tabellen -------------------------------------
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_modules ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.modules FROM anon;
REVOKE ALL ON public.tenant_modules FROM anon;
GRANT SELECT ON public.modules TO authenticated;
GRANT SELECT ON public.tenant_modules TO authenticated;

-- Den Katalog darf jede angemeldete Person sehen -- er ist ein Angebot,
-- kein Geheimnis.
CREATE POLICY modules_lesen ON public.modules
  FOR SELECT TO authenticated USING (true);

-- Die eigenen Buchungen sieht der Verein; aendern darf sie nur der
-- Betreiber. Selbst zubuchen wird in Stufe 2 entschieden -- bis dahin
-- bleibt es bei der engeren Regel.
CREATE POLICY tenant_modules_lesen ON public.tenant_modules
  FOR SELECT TO authenticated
  USING ("tenantId" = public.current_tenant() OR public.is_platform_admin());

CREATE POLICY tenant_modules_schreiben ON public.tenant_modules
  FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

DO $$ BEGIN RAISE NOTICE 'Marktplatz-Grundlage angelegt.'; END $$;
