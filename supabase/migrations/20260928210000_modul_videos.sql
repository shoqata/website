-- Modul "Videos".
--
-- Zur Einordnung, weil der Name des Werkzeugs etwas anderes vermuten laesst:
-- hyperframes-student-kit ist ein Videoschnitt-Werkzeugkasten, der auf einem
-- Rechner mit Node, FFmpeg und Chrome laeuft und MP4-Dateien erzeugt. Er
-- laeuft nicht in der Website und laesst sich dort auch nicht einbauen --
-- anders als der Kern von scroll-craft, der im Browser arbeitet.
--
-- Was in die Anwendung gehoert, ist die andere Haelfte: ein Ort, an dem ein
-- Verein seine Videos zeigt. Erzeugt werden sie ausserhalb, veroeffentlicht
-- werden sie hier.

CREATE TABLE IF NOT EXISTS public.videos (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "tenantId"   text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  titel        text NOT NULL,
  beschreibung text,
  quelle       text NOT NULL,          -- Adresse der Videodatei
  vorschaubild text,
  dauer_s      int,
  status       text NOT NULL DEFAULT 'ENTWURF'
               CHECK (status IN ('ENTWURF','OEFFENTLICH')),
  reihenfolge  int NOT NULL DEFAULT 100,
  erstellt_am  timestamptz NOT NULL DEFAULT now(),
  erstellt_von text
);

ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.videos FROM anon, authenticated;
GRANT SELECT ON public.videos TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.videos TO authenticated;

-- Oeffentlich sichtbar ist, was der Verein freigegeben hat -- und nur, wenn
-- das Modul fuer ihn laeuft. Die Regel entscheidet das, nicht die
-- Oberflaeche: sonst holte sich jeder die Entwuerfe ueber die Schnittstelle.
DROP POLICY IF EXISTS videos_public_read ON public.videos;
CREATE POLICY videos_public_read ON public.videos FOR SELECT TO anon, authenticated
USING (
  status = 'OEFFENTLICH'
  AND "tenantId" = coalesce(public.current_tenant(), public.request_tenant())
  AND public.modul_aktiv_oeffentlich('VIDEOS')
);

DROP POLICY IF EXISTS videos_staff_all ON public.videos;
CREATE POLICY videos_staff_all ON public.videos FOR ALL TO authenticated
USING (public.is_staff() AND "tenantId" = public.current_tenant()
       AND public.modul_aktiv('VIDEOS'))
WITH CHECK (public.is_staff() AND "tenantId" = public.current_tenant()
       AND public.modul_aktiv('VIDEOS'));

INSERT INTO public.modules (schluessel, name_de, name_en, name_sq,
                            beschreibung_de, beschreibung_en, beschreibung_sq,
                            ist_kern, status, braucht_einrichtung,
                            preis_monat, reihenfolge)
SELECT 'VIDEOS',
  'Videos', 'Videos', 'Videot',
  'Eine Videoseite fuer den Verein: Rueckblicke, Aufrufe, kurze Filme aus dem Dorf. Die Filme entstehen ausserhalb der Anwendung und werden hier veroeffentlicht.',
  'A video page for the association: recaps, appeals, short films from the village. The films are produced outside the application and published here.',
  'Nje faqe videosh per shoqaten: retrospektiva, thirrje, filma te shkurter nga fshati. Filmat prodhohen jashte aplikacionit dhe publikohen ketu.',
  false, 'VERFUEGBAR', false, 5.00, 115
 WHERE NOT EXISTS (SELECT 1 FROM public.modules WHERE schluessel='VIDEOS');

-- Fuer Koretini ausdruecklich gebucht. alle_module_frei wuerde es ohnehin
-- oeffnen; ein ausdruecklicher Eintrag ist trotzdem besser, weil er auch
-- dann noch gilt, wenn diese Regel einmal anders lautet.
INSERT INTO public.tenant_modules ("tenantId", modul, zustand, geaendert_von)
VALUES ('koretini', 'VIDEOS', 'AN', 'system')
ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand='AN';

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schluessel, name_de, preis_monat, status FROM public.modules
            WHERE schluessel='VIDEOS' LOOP
    RAISE NOTICE 'Modul % | % | % im Monat | %', r.schluessel, r.name_de, r.preis_monat, r.status;
  END LOOP;
  FOR r IN SELECT zustand FROM public.tenant_modules
            WHERE "tenantId"='koretini' AND modul='VIDEOS' LOOP
    RAISE NOTICE 'Koretini: %', r.zustand;
  END LOOP;
END $$;
