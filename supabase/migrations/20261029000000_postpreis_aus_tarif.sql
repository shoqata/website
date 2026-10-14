-- Der Briefpreis folgt dem Tarif von Pingen plus zehn Prozent.
--
-- Vorgabe: offizielle Preise von Pingen + 10% fuer unityhub.
--
-- Zuerst stand hier ein eingetippter Verkaufspreis. Das war falsch, und
-- zwar aus einem Grund, der sich erst nach der ersten Tarifaenderung
-- zeigt: ein eingetippter Preis weicht ab, sobald Pingen etwas aendert,
-- und niemand merkt es. Er wuerde zu einem Wert, der einmal richtig war.
--
-- Darum zwei getrennte Angaben und eine gerechnete:
--
--   einkauf_je_brief   was Pingen verlangt -- vom Tarif abgefragt, nicht
--                      geschaetzt. Pingen hat einen Preisrechner, der
--                      genau unsere Briefform kennt (Land, Blattzahl,
--                      simplex/duplex, Farbe, Produkt).
--   aufpreis_prozent   10, aenderbar je Verein
--   preis_je_brief     GERECHNET, nicht gespeichert
--
-- Eine gerechnete Spalte kann nicht von der Regel abweichen. Ein
-- gespeicherter Verkaufspreis neben einem Aufpreis waeren zwei Wahrheiten
-- ueber dieselbe Zahl -- dieselbe Art Fehler wie bei den drei
-- Rechnungsnummern-Schemata.
--
-- preis_fest bleibt als Ausnahme: ein Verein, mit dem etwas anderes
-- abgesprochen ist, bekommt einen festen Preis. Er gewinnt gegen die
-- Rechnung, und dass er gesetzt ist, steht in der Maske.

-- Die alte Spalte weicht der gerechneten. Keine Daten gehen verloren --
-- gemessen 0 Zeilen in post_preise.
ALTER TABLE public.post_preise DROP COLUMN IF EXISTS preis_je_brief;

ALTER TABLE public.post_preise
  ADD COLUMN IF NOT EXISTS aufpreis_prozent numeric(5,2) NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS preis_fest numeric(10,2),
  ADD COLUMN IF NOT EXISTS tarif_abgefragt_am timestamptz,
  ADD COLUMN IF NOT EXISTS tarif_grundlage text;

ALTER TABLE public.post_preise
  ADD COLUMN IF NOT EXISTS preis_je_brief numeric(10,2)
  GENERATED ALWAYS AS (
    coalesce(preis_fest,
             round(einkauf_je_brief * (1 + aufpreis_prozent / 100.0), 2))
  ) STORED;

DO $$ BEGIN
  ALTER TABLE public.post_preise ADD CONSTRAINT post_preise_aufpreis
    CHECK (aufpreis_prozent >= 0 AND aufpreis_prozent <= 200);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

COMMENT ON COLUMN public.post_preise.preis_je_brief IS
  'Gerechnet: Einkauf plus Aufpreis, oder preis_fest. Nicht schreibbar -- '
  'ein gespeicherter Verkaufspreis wuerde von der Regel abweichen, sobald '
  'Pingen den Tarif aendert.';
COMMENT ON COLUMN public.post_preise.tarif_grundlage IS
  'Welche Briefform abgefragt wurde -- Land, Blattzahl, Druckart. Ohne das '
  'ist ein Einkaufspreis eine Zahl ohne Bedeutung.';


-- ----------------------------------------- Den Tarif eintragen
--
-- Nur service_role: den Tarif fragt die Edge Function bei Pingen ab.
-- Waere es fuer angemeldete Konten offen, koennte ein Verein seinen
-- Einkaufspreis auf null setzen und damit auch seinen Verkaufspreis.
CREATE OR REPLACE FUNCTION public.post_einkaufspreis_melden(
  p_verein text, p_preis numeric, p_waehrung text DEFAULT 'CHF',
  p_grundlage text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_neu numeric;
BEGIN
  IF p_preis IS NULL OR p_preis <= 0 THEN
    RAISE EXCEPTION 'Ein Einkaufspreis muss groesser als null sein.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.post_preise
    ("tenantId", einkauf_je_brief, waehrung, tarif_abgefragt_am, tarif_grundlage,
     geaendert_am, geaendert_von)
  VALUES (p_verein, p_preis, coalesce(p_waehrung,'CHF'), now(), p_grundlage,
          now(), 'Tarifabfrage')
  ON CONFLICT ("tenantId") DO UPDATE
     SET einkauf_je_brief = EXCLUDED.einkauf_je_brief,
         waehrung = EXCLUDED.waehrung,
         tarif_abgefragt_am = now(),
         tarif_grundlage = EXCLUDED.tarif_grundlage,
         geaendert_am = now(), geaendert_von = 'Tarifabfrage';

  SELECT preis_je_brief INTO v_neu FROM public.post_preise WHERE "tenantId" = p_verein;
  RETURN jsonb_build_object('verein', p_verein, 'einkauf', p_preis,
                            'verkauf', v_neu, 'grundlage', p_grundlage);
END $$;

REVOKE ALL ON FUNCTION public.post_einkaufspreis_melden(text,numeric,text,text)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_einkaufspreis_melden(text,numeric,text,text)
  TO service_role;


-- --------------------------- Aufpreis und Festpreis, nur fuer den Betreiber
--
-- Die alte Fassung muss weichen, nicht ersetzt werden: sie hiess
-- (p_verein, p_preis, p_einkauf) und nahm einen eingetippten
-- Verkaufspreis an, den es nicht mehr gibt. Dieselbe Signatur mit
-- anderen Parameternamen laesst PostgreSQL bei CREATE OR REPLACE nicht
-- zu -- "cannot change name of input parameter" -- und das ist gut so:
-- ein Aufrufer, der p_preis mitschickt, soll an einem Fehler merken,
-- dass die Bedeutung sich geaendert hat, und nicht stillschweigend
-- einen Aufpreis setzen, wo er einen Preis meinte.
DROP FUNCTION IF EXISTS public.post_preis_setzen(text, numeric, numeric);

CREATE OR REPLACE FUNCTION public.post_preis_setzen(
  p_verein text, p_aufpreis numeric DEFAULT NULL, p_fest numeric DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_vorhanden boolean; v_erg record;
BEGIN
  -- Nur der Betreiber. Der Aufpreis ist sein Ertrag; ein Verein, der ihn
  -- setzen koennte, kaufte zum Selbstkostenpreis.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber legt Aufpreis und Festpreis fest.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_aufpreis IS NOT NULL AND (p_aufpreis < 0 OR p_aufpreis > 200) THEN
    RAISE EXCEPTION 'Der Aufpreis muss zwischen 0 und 200 Prozent liegen.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_fest IS NOT NULL AND p_fest <= 0 THEN
    RAISE EXCEPTION 'Ein Festpreis muss groesser als null sein; zum Loeschen NULL.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT EXISTS (SELECT 1 FROM public.post_preise WHERE "tenantId" = p_verein)
    INTO v_vorhanden;
  IF NOT v_vorhanden THEN
    INSERT INTO public.post_preise ("tenantId", aufpreis_prozent, preis_fest,
                                    geaendert_von)
    VALUES (p_verein, coalesce(p_aufpreis, 10), p_fest,
            public.current_user_row_id());
  ELSE
    UPDATE public.post_preise
       SET aufpreis_prozent = coalesce(p_aufpreis, aufpreis_prozent),
           -- Ein ausdrueckliches NULL muss den Festpreis loeschen
           -- koennen. coalesce allein liesse ihn fuer immer stehen.
           preis_fest = p_fest,
           geaendert_am = now(), geaendert_von = public.current_user_row_id()
     WHERE "tenantId" = p_verein;
  END IF;

  SELECT * INTO v_erg FROM public.post_preise WHERE "tenantId" = p_verein;
  RETURN jsonb_build_object(
    'verein', p_verein,
    'einkauf', v_erg.einkauf_je_brief,
    'aufpreis_prozent', v_erg.aufpreis_prozent,
    'preis_fest', v_erg.preis_fest,
    'preis_je_brief', v_erg.preis_je_brief,
    'tarif_abgefragt_am', v_erg.tarif_abgefragt_am,
    'tarif_grundlage', v_erg.tarif_grundlage);
END $$;

REVOKE ALL ON FUNCTION public.post_preis_setzen(text,numeric,numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_preis_setzen(text,numeric,numeric) TO authenticated;



-- Fuer den Betreiber: Tarif und Marge je Verein, zusammen in einer Sicht.
CREATE OR REPLACE FUNCTION public.post_tarife()
RETURNS TABLE (
  r_verein text, r_name text, r_einkauf numeric, r_aufpreis numeric,
  r_fest numeric, r_verkauf numeric, r_waehrung text,
  r_abgefragt timestamptz, r_grundlage text
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p."tenantId", coalesce(t.name, p."tenantId"),
         p.einkauf_je_brief, p.aufpreis_prozent, p.preis_fest,
         p.preis_je_brief, p.waehrung, p.tarif_abgefragt_am, p.tarif_grundlage
    FROM public.post_preise p
    LEFT JOIN public.tenants t ON t.id = p."tenantId"
   WHERE public.is_platform_admin()
   ORDER BY 2;
$$;

REVOKE ALL ON FUNCTION public.post_tarife() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_tarife() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_verein text := 'selbsttest-tarif'; v_erg jsonb; v_p record;
BEGIN
  DELETE FROM public.post_preise WHERE "tenantId" = v_verein;

  -- Tarif eintragen: 1.60 Einkauf, 10 Prozent -> 1.76
  v_erg := public.post_einkaufspreis_melden(v_verein, 1.60, 'CHF', 'CH, 1 Blatt, duplex, grayscale, cheap');
  IF (v_erg->>'verkauf')::numeric <> 1.76 THEN
    RAISE EXCEPTION 'Zehn Prozent auf 1.60 ergeben 1.76, gerechnet wurde %.',
      v_erg->>'verkauf';
  END IF;

  -- Tarifaenderung bei Pingen: der Verkaufspreis folgt von allein. Das
  -- ist der Punkt der gerechneten Spalte.
  PERFORM public.post_einkaufspreis_melden(v_verein, 2.00, 'CHF', 'CH, 2 Blatt');
  SELECT * INTO v_p FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_p.preis_je_brief <> 2.20 THEN
    RAISE EXCEPTION 'Nach der Tarifaenderung muesste 2.20 stehen, es steht %.',
      v_p.preis_je_brief;
  END IF;

  -- Der Verkaufspreis ist nicht schreibbar. Waere er es, koennte er von
  -- der Regel abweichen.
  BEGIN
    UPDATE public.post_preise SET preis_je_brief = 99 WHERE "tenantId" = v_verein;
    RAISE EXCEPTION 'Der gerechnete Verkaufspreis liess sich ueberschreiben.';
  EXCEPTION WHEN generated_always THEN NULL;
       WHEN syntax_error_or_access_rule_violation THEN NULL;
  END;

  -- Ein Festpreis gewinnt, und NULL loescht ihn wieder.
  UPDATE public.post_preise SET preis_fest = 1.50 WHERE "tenantId" = v_verein;
  SELECT * INTO v_p FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_p.preis_je_brief <> 1.50 THEN
    RAISE EXCEPTION 'Der Festpreis greift nicht (% statt 1.50).', v_p.preis_je_brief;
  END IF;
  UPDATE public.post_preise SET preis_fest = NULL WHERE "tenantId" = v_verein;
  SELECT * INTO v_p FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_p.preis_je_brief <> 2.20 THEN
    RAISE EXCEPTION 'Nach dem Loeschen des Festpreises muesste 2.20 stehen, es steht %.',
      v_p.preis_je_brief;
  END IF;

  -- Und ohne Tarif kein Preis -- statt eines stillen Null.
  UPDATE public.post_preise SET einkauf_je_brief = NULL WHERE "tenantId" = v_verein;
  SELECT * INTO v_p FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_p.preis_je_brief IS NOT NULL THEN
    RAISE EXCEPTION 'Ohne Einkaufspreis entstand ein Verkaufspreis von %.',
      v_p.preis_je_brief;
  END IF;

  -- Den Einkauf darf ein angemeldetes Konto nicht melden.
  IF has_function_privilege('authenticated',
       'public.post_einkaufspreis_melden(text,numeric,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated darf den Einkaufspreis melden -- damit liesse '
                    'sich der eigene Verkaufspreis auf null druecken.';
  END IF;

  DELETE FROM public.post_preise WHERE "tenantId" = v_verein;
  RAISE NOTICE 'Briefpreis folgt dem Tarif: Einkauf + 10%%, gerechnet und nicht '
               'gespeichert, Festpreis als Ausnahme.';
END $$;
