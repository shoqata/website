-- Sechs Vorlagen fuer die Vereinswebsite statt zwei.
--
-- Bisher gab es genau eine Entscheidung: Standard oder Premium. Das war
-- eine Umschaltung, keine Auswahl -- und der Schalter stand in den
-- Einstellungen, also nicht dort, wo ein Verein seine Website macht.
--
-- Welche Schluessel es gibt, steht hier und nicht allein im Code: der
-- Marktplatz und der Admin muessen wissen, welche Vorlage etwas kostet,
-- ohne das Frontend zu fragen. Gezeichnet werden sie natuerlich im Code --
-- eine Vorlage ist ein Bauplan, kein Datensatz. Die Tabelle sagt, was es
-- gibt und was es kostet; der Code sagt, wie es aussieht. Weicht beides
-- voneinander ab, gewinnt die Tabelle: eine unbekannte Vorlage faellt auf
-- die erste Standardvorlage zurueck, statt eine leere Seite zu zeigen.

CREATE TABLE IF NOT EXISTS public.startseiten_vorlagen (
  schluessel    text PRIMARY KEY,
  name_de       text NOT NULL,
  name_en       text NOT NULL,
  name_sq       text NOT NULL,
  beschreibung_de text NOT NULL,
  beschreibung_en text NOT NULL,
  beschreibung_sq text NOT NULL,
  ist_premium   boolean NOT NULL DEFAULT false,
  -- Welches Modul die Vorlage freischaltet. NULL heisst: im Grundpreis.
  modul         text REFERENCES public.modules(schluessel),
  reihenfolge   int  NOT NULL DEFAULT 100,
  aktiv         boolean NOT NULL DEFAULT true
);

-- Der Katalog ist fuer jeden lesbar: ein Besucher sieht ihn nie, aber der
-- Admin eines jeden Vereins muss ihn sehen, auch ohne gebuchtes Modul --
-- sonst koennte er nicht erkennen, was er bekaeme.
ALTER TABLE public.startseiten_vorlagen ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS vorlagen_lesen ON public.startseiten_vorlagen;
CREATE POLICY vorlagen_lesen ON public.startseiten_vorlagen
  FOR SELECT TO anon, authenticated USING (aktiv);
GRANT SELECT ON public.startseiten_vorlagen TO anon, authenticated;

INSERT INTO public.startseiten_vorlagen
  (schluessel, name_de, name_en, name_sq,
   beschreibung_de, beschreibung_en, beschreibung_sq,
   ist_premium, modul, reihenfolge)
VALUES
  ('KLASSISCH','Klassisch','Classic','Klasike',
   'Text links, Bilder rechts. Die Seite, die jeder Verein kennt -- ruhig, vertraut, auf dem Telefon so gut wie am Schreibtisch.',
   'Text on the left, images on the right. The page every association knows -- calm, familiar, as good on a phone as on a desk.',
   'Teksti majtas, imazhet djathtas. Faqja qe cdo shoqate e njeh -- e qete, e njohur, po aq e mire ne telefon sa ne tavoline.',
   false, NULL, 10),

  ('MAGAZIN','Magazin','Magazine','Revista',
   'Wie eine Zeitungsseite: grosser Titel, Anlaesse und Neuigkeiten nebeneinander statt untereinander. Fuer Vereine, die viel zu erzaehlen haben.',
   'Like a newspaper page: a large masthead, events and news side by side rather than stacked. For associations with a lot to tell.',
   'Si nje faqe gazete: titull i madh, ngjarjet dhe lajmet krah per krah. Per shoqatat qe kane shume per te treguar.',
   false, NULL, 20),

  ('KOMPAKT','Kompakt','Compact','Kompakte',
   'Eine Spalte, eine Aussage, ein Bild. Fuer Vereine, die gerade anfangen -- eine fast leere Seite wirkt hier absichtlich, nicht unfertig.',
   'One column, one statement, one picture. For associations just starting out -- a nearly empty page looks deliberate here, not unfinished.',
   'Nje kolone, nje pohim, nje fotografi. Per shoqatat qe sapo nisin -- nje faqe thuajse e zbrazet duket e qellimshme, jo e papërfunduar.',
   false, NULL, 30),

  ('ERZAEHLUNG','Erzählung','Narrative','Rrefim',
   'Die Seite entfaltet sich beim Scrollen: Bilder stehen still, Text zieht vorbei, Zahlen zaehlen hoch. Fuenf Bilder nacheinander statt alles auf einmal.',
   'The page unfolds as you scroll: images hold still, text moves past, figures count up. Five scenes in turn instead of everything at once.',
   'Faqja shpaloset teksa rreshqitni: imazhet qendrojne, teksti kalon, shifrat numerojne. Pese skena me radhe ne vend qe gjithcka njeheresh.',
   true, 'LANDINGPAGE', 40),

  ('BUEHNE','Bühne','Stage','Skene',
   'Ein einziges Bild ueber die ganze Breite, darueber die Zahlen des Vereins. Die Anlaesse ziehen seitlich vorbei statt nach unten.',
   'A single full-bleed image with the association''s figures over it. Events pan sideways instead of running downward.',
   'Nje imazh i vetem ne tere gjeresine, mbi te shifrat e shoqates. Ngjarjet kalojne anash, jo poshte.',
   true, 'LANDINGPAGE', 50),

  ('JOURNAL','Journal','Journal','Journal',
   'Das Jahr des Vereins als Band von oben nach unten: was war, was kommt, wer dabei ist. Fuer Vereine mit Geschichte.',
   'The association''s year as a ribbon from top to bottom: what happened, what is coming, who is part of it. For associations with a history.',
   'Viti i shoqates si nje shirit nga lart poshte: cfare ndodhi, cfare vjen, kush eshte pjese. Per shoqatat me histori.',
   true, 'LANDINGPAGE', 60)
ON CONFLICT (schluessel) DO UPDATE SET
  name_de = EXCLUDED.name_de, name_en = EXCLUDED.name_en, name_sq = EXCLUDED.name_sq,
  beschreibung_de = EXCLUDED.beschreibung_de, beschreibung_en = EXCLUDED.beschreibung_en,
  beschreibung_sq = EXCLUDED.beschreibung_sq,
  ist_premium = EXCLUDED.ist_premium, modul = EXCLUDED.modul,
  reihenfolge = EXCLUDED.reihenfolge;


-- Welche Vorlage bekommt dieser Besucher?
--
-- Zwei Dinge muessen stimmen, und zwar beide hier und nicht im Browser:
-- der Verein hat die Vorlage gewaehlt, UND bei einer Premium-Vorlage ist
-- das zugehoerige Modul fuer ihn aktiv. Stimmte nur das erste, koennte ein
-- Verein die bezahlten Designs durch einen Eintrag in settings bekommen.
--
-- Faellt eines der beiden aus, kommt KLASSISCH zurueck -- nicht ein Fehler
-- und keine leere Seite. Eine Vereinswebsite, die nichts zeigt, ist
-- schlimmer als eine, die schlicht aussieht.
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
        AND (v.modul IS NULL OR public.modul_aktiv_oeffentlich(v.modul))),
    'KLASSISCH');
$$;
REVOKE ALL ON FUNCTION public.startseiten_vorlage() FROM public;
GRANT EXECUTE ON FUNCTION public.startseiten_vorlage() TO anon, authenticated;


-- Die alte Frage bleibt beantwortbar.
--
-- Zwischen dem Ausliefern der Datenbank und dem des Frontends liegen
-- Minuten, in denen der alte Browserstand noch startseite_variante() ruft.
-- Faellt die Funktion in dieser Zeit weg, zeigt jeder Verein eine leere
-- Seite. Sie bleibt also -- und sagt jetzt nur noch, ob die gewaehlte
-- Vorlage eine bezahlte ist.
CREATE OR REPLACE FUNCTION public.startseite_variante()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE WHEN (SELECT v.ist_premium FROM public.startseiten_vorlagen v
                     WHERE v.schluessel = public.startseiten_vorlage())
              THEN 'PREMIUM' ELSE 'STANDARD' END;
$$;
REVOKE ALL ON FUNCTION public.startseite_variante() FROM public;
GRANT EXECUTE ON FUNCTION public.startseite_variante() TO anon, authenticated;


-- Was der Admin zur Auswahl sieht -- samt der Frage, ob er sie nehmen darf.
--
-- "gesperrt" rechnet die Datenbank aus und nicht das Frontend: sonst
-- muesste der Browser die Modulbuchung kennen, und zwei Stellen, die
-- dasselbe ausrechnen, laufen auseinander.
CREATE OR REPLACE FUNCTION public.startseiten_vorlagen_auswahl()
RETURNS TABLE (schluessel text, name_de text, name_en text, name_sq text,
               beschreibung_de text, beschreibung_en text, beschreibung_sq text,
               ist_premium boolean, modul text, preis_monat numeric,
               gesperrt boolean, gewaehlt boolean, reihenfolge int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT v.schluessel, v.name_de, v.name_en, v.name_sq,
         v.beschreibung_de, v.beschreibung_en, v.beschreibung_sq,
         v.ist_premium, v.modul, m.preis_monat,
         NOT (v.modul IS NULL OR public.modul_aktiv(v.modul)) AS gesperrt,
         v.schluessel = public.startseiten_vorlage() AS gewaehlt,
         v.reihenfolge
    FROM public.startseiten_vorlagen v
    LEFT JOIN public.modules m ON m.schluessel = v.modul
   WHERE v.aktiv AND public.current_tenant() IS NOT NULL
   ORDER BY v.reihenfolge;
$$;
REVOKE ALL ON FUNCTION public.startseiten_vorlagen_auswahl() FROM public;
GRANT EXECUTE ON FUNCTION public.startseiten_vorlagen_auswahl() TO authenticated;


-- Das Modul heisst jetzt nach dem, was es wirklich enthaelt: drei Designs,
-- nicht eines. Der Preis bleibt, wie er gesetzt wurde.
UPDATE public.modules SET
  name_de = 'Premium-Designs',
  name_en = 'Premium designs',
  name_sq = 'Dizajne premium',
  beschreibung_de = 'Drei erzaehlende Website-Vorlagen, die sich beim Scrollen entfalten: Erzählung, Bühne und Journal. Der Verein waehlt unter Website, welche er nimmt -- die drei Standardvorlagen bleiben daneben bestehen.',
  beschreibung_en = 'Three narrative website templates that unfold as you scroll: Narrative, Stage and Journal. The association picks one under Website -- the three standard templates remain available alongside.',
  beschreibung_sq = 'Tri shabllone rrefyese faqesh qe shpalosen teksa rreshqitni: Rrefim, Skene dhe Journal. Shoqata zgjedh nen Website -- tri shabllonet standarde mbeten gjithashtu.'
WHERE schluessel = 'LANDINGPAGE';


-- Nachweis statt Zuversicht: ein Verein ohne das Modul traegt eine
-- Premium-Vorlage ein. Bekommt er sie, ist die Sperre ein Schaufenster.
--
-- Der Test prueft sich zuerst selbst. Ein UPDATE, das null Zeilen trifft,
-- wirft keinen Fehler -- faende der Verein keine settings-Zeile, liefe der
-- Test durch, ohne etwas gemessen zu haben. Diese Falle hat uns in diesem
-- Projekt schon einmal eine falsche Entwarnung gegeben.
DO $$
DECLARE
  v_verein  text;
  v_vorher  text;
  v_hatte   boolean;
  v_zeilen  int;
  v_bekommt text;
  v_frei    boolean;
BEGIN
  -- Einen Verein nehmen, der NICHT alles frei hat, das Modul nicht gebucht
  -- hat UND eine settings-Zeile besitzt -- sonst misst der Test nichts.
  SELECT t.id INTO v_verein
    FROM public.tenants t
    JOIN public.settings s ON s."tenantId" = t.id AND s.id = 'system'
   WHERE NOT coalesce(t.alle_module_frei, false)
     AND NOT EXISTS (SELECT 1 FROM public.tenant_modules tm
                      WHERE tm."tenantId" = t.id AND tm.modul = 'LANDINGPAGE'
                        AND tm.zustand IN ('AN','TESTPHASE')
                        AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date))
   LIMIT 1;

  IF v_verein IS NULL THEN
    RAISE WARNING 'PRUEFUNG UEBERSPRUNGEN: kein Verein ohne LANDINGPAGE mit settings/system vorhanden. Die Sperre ist damit NICHT gemessen.';
  ELSE
    SELECT s.system ? 'startseitenVorlage', s.system ->> 'startseitenVorlage'
      INTO v_hatte, v_vorher
      FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'system';

    UPDATE public.settings
       SET system = coalesce(system, '{}'::jsonb) || '{"startseitenVorlage":"BUEHNE"}'::jsonb
     WHERE "tenantId" = v_verein AND id = 'system';
    GET DIAGNOSTICS v_zeilen = ROW_COUNT;
    IF v_zeilen <> 1 THEN
      RAISE EXCEPTION 'Pruefung unbrauchbar: % Zeilen geaendert statt 1.', v_zeilen;
    END IF;

    PERFORM set_config('request.jwt.claims',
      json_build_object('app_metadata', json_build_object('tenant', v_verein))::text, true);
    v_bekommt := public.startseiten_vorlage();

    RAISE NOTICE 'Verein % waehlt BUEHNE ohne Modul -> bekommt: %', v_verein, v_bekommt;
    IF v_bekommt <> 'KLASSISCH' THEN
      RAISE EXCEPTION 'SPERRE WIRKT NICHT: % statt KLASSISCH. Nichts wurde angewandt.', v_bekommt;
    END IF;

    -- Zuruecksetzen; der Test darf nichts hinterlassen.
    UPDATE public.settings
       SET system = CASE WHEN v_hatte
                         THEN system || jsonb_build_object('startseitenVorlage', v_vorher)
                         ELSE system - 'startseitenVorlage' END
     WHERE "tenantId" = v_verein AND id = 'system';
    PERFORM set_config('request.jwt.claims', NULL, true);
    RAISE NOTICE 'Sperre nachgewiesen und Ausgangszustand wiederhergestellt.';
  END IF;

  -- Gegenprobe: Koretini hat alles frei, darf also jede Vorlage.
  SELECT coalesce(alle_module_frei, false) INTO v_frei
    FROM public.tenants WHERE id = 'koretini';
  RAISE NOTICE 'Koretini alle_module_frei=% -> Premium-Vorlagen stehen offen', v_frei;
END $$;
