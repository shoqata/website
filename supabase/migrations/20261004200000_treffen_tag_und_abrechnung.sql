-- Zwei Dinge, die am Tag selbst und danach gebraucht werden.

-- ================================================ 1. Programm verschieben
--
-- Ein Programm verschiebt sich. Der Empfang zieht sich, das Halbfinale
-- geht in die Verlaengerung. Dann will der Gastgeber nicht sieben Felder
-- von Hand aendern, sondern sagen: "ab hier alles zwanzig Minuten
-- spaeter".
--
-- Sobald zwei Spuren laufen, ist das aber nicht mehr eindeutig:
-- verschiebt sich die andere Spur mit? Meistens nicht -- das Essen im
-- Festzelt wartet nicht, weil das Halbfinale laenger dauert. Darum
-- verschiebt diese Funktion standardmaessig NUR die eigene Spur, und das
-- Mitnehmen der anderen ist eine ausdrueckliche Entscheidung.
--
-- Verschoben wird der angegebene Punkt und alles, was in derselben Spur
-- SPAETER beginnt. Was vorher liegt, bleibt -- es ist ja schon gelaufen.
CREATE OR REPLACE FUNCTION public.treffen_programm_verschieben(
  p_punkt uuid, p_minuten int, p_alle_spuren boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_treffen uuid; v_tag date; v_beginn time; v_spur text;
  v_zeilen int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_minuten = 0 THEN
    RAISE EXCEPTION 'Um null Minuten verschieben aendert nichts.';
  END IF;

  SELECT treffen_id, tag, beginn, spur INTO v_treffen, v_tag, v_beginn, v_spur
    FROM public.treffen_programm WHERE id = p_punkt;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Programmpunkt nicht gefunden.'; END IF;

  UPDATE public.treffen_programm
     SET beginn = beginn + make_interval(mins => p_minuten)
   WHERE treffen_id = v_treffen
     AND coalesce(tag, '0001-01-01'::date) = coalesce(v_tag, '0001-01-01'::date)
     AND beginn >= v_beginn
     AND (p_alle_spuren OR spur = v_spur);
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;

  -- Ein UPDATE, das null Zeilen trifft, wirft keinen Fehler. Ohne diese
  -- Pruefung meldete die Oberflaeche ein Verschieben, das nie stattfand.
  IF v_zeilen = 0 THEN
    RAISE EXCEPTION 'Kein Programmpunkt verschoben.';
  END IF;

  RETURN jsonb_build_object('verschoben', v_zeilen, 'minuten', p_minuten,
                            'spur', CASE WHEN p_alle_spuren THEN 'alle' ELSE v_spur END);
END $$;
REVOKE ALL ON FUNCTION public.treffen_programm_verschieben(uuid,int,boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_programm_verschieben(uuid,int,boolean) TO authenticated;


-- ================================================= 2. Teilnahmebeitraege
--
-- Verrechnet wird ueber platform_invoices -- dieselbe Tabelle, in der der
-- Betreiber ohnehin den Vereinen Rechnung stellt. Ein zweites
-- Rechnungswesen daneben waere ein zweiter Ort, an dem eine Zahlung
-- vergessen wird.
--
-- Die Spalte treffen_id macht den Bezug sichtbar und verhindert, dass
-- dasselbe Treffen zweimal verrechnet wird.
ALTER TABLE public.platform_invoices
  ADD COLUMN IF NOT EXISTS treffen_id uuid REFERENCES public.treffen(id) ON DELETE SET NULL;

-- Die Art TREFFEN ergaenzen. Erlaubt waren bisher SETUP, ANNUAL und
-- OTHER; ein Teilnahmebeitrag ist keines davon, und ihn als OTHER zu
-- fuehren hiesse, ihn spaeter nicht wiederzufinden.
ALTER TABLE public.platform_invoices DROP CONSTRAINT IF EXISTS platform_invoices_kind_check;
ALTER TABLE public.platform_invoices ADD CONSTRAINT platform_invoices_kind_check
  CHECK (kind = ANY (ARRAY['SETUP','ANNUAL','TREFFEN','OTHER']));
CREATE UNIQUE INDEX IF NOT EXISTS platform_invoices_treffen_je_verein
  ON public.platform_invoices (treffen_id, "tenantId") WHERE treffen_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.treffen_verrechnen(p_treffen uuid, p_faellig_in_tagen int DEFAULT 30)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  t RECORD; r RECORD;
  v_betrag numeric; v_nr text; v_n int := 0;
  v_gaeste jsonb := '[]'::jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT * INTO t FROM public.treffen WHERE id = p_treffen;
  IF t.id IS NULL THEN RAISE EXCEPTION 'Treffen nicht gefunden.'; END IF;
  IF t.preis_art = 'KEINE' THEN
    RAISE EXCEPTION 'Fuer dieses Treffen ist kein Beitrag vorgesehen.';
  END IF;

  FOR r IN
    SELECT te.*, coalesce(te.name, tn.name, te."tenantId") AS wer
      FROM public.treffen_teilnehmer te
      LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
     WHERE te.treffen_id = p_treffen
       AND te.art IN ('VEREIN','GASTVEREIN')
       AND coalesce(te.zugesagt,false)
  LOOP
    v_betrag := CASE t.preis_art
                  WHEN 'PRO_VEREIN' THEN t.preis_betrag
                  WHEN 'PRO_KOPF'   THEN t.preis_betrag * r.personen
                END;
    CONTINUE WHEN coalesce(v_betrag,0) <= 0;

    -- Ein Gastverein hat keine Vereinszeile auf der Plattform; ihm laesst
    -- sich hier keine Rechnung stellen. Er wird ausgewiesen statt
    -- stillschweigend uebersprungen -- sonst fehlt am Ende Geld, und
    -- niemand weiss warum.
    IF r.art = 'GASTVEREIN' OR r."tenantId" IS NULL THEN
      v_gaeste := v_gaeste || jsonb_build_object(
        'wer', r.wer, 'kontakt', r.kontakt_name, 'email', r.kontakt_email,
        'personen', r.personen, 'betrag', round(v_betrag,2));
      CONTINUE;
    END IF;

    v_nr := 'TR-' || to_char(t.datum,'YYYY') || '-' ||
            lpad((coalesce((SELECT count(*) FROM public.platform_invoices
                             WHERE kind='TREFFEN' AND year = extract(year FROM t.datum)),0)+v_n+1)::text, 4, '0');

    INSERT INTO public.platform_invoices
      ("tenantId", kind, amount, currency, year, status, "invoiceNumber",
       "issuedAt", "dueDate", note, treffen_id)
    VALUES (r."tenantId", 'TREFFEN', round(v_betrag,2), t.waehrung,
            -- DRAFT, nicht "OPEN": erlaubt sind DRAFT, SENT, PAID,
            -- CANCELLED. Und DRAFT ist auch sachlich richtig -- gestellt
            -- ist die Rechnung erst, wenn sie verschickt wurde.
            extract(year FROM t.datum)::int, 'DRAFT', v_nr,
            current_date, current_date + p_faellig_in_tagen,
            t.titel || CASE WHEN t.preis_art='PRO_KOPF'
                            THEN ' — ' || r.personen || ' Personen à ' || t.preis_betrag
                            ELSE ' — Teilnahmebeitrag' END,
            p_treffen)
    -- Die Bedingung des TEILWEISEN Index muss mit genannt werden. Ohne
    -- sie findet Postgres keine passende Eindeutigkeit und bricht ab:
    -- "there is no unique or exclusion constraint matching the ON CONFLICT
    -- specification". Gemessen, nicht vermutet.
    ON CONFLICT (treffen_id, "tenantId") WHERE treffen_id IS NOT NULL DO NOTHING;

    IF FOUND THEN v_n := v_n + 1; END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'gestellt', v_n,
    'ausserhalb', v_gaeste,
    'hinweis', CASE WHEN jsonb_array_length(v_gaeste) > 0
                    THEN 'Gastvereine haben keine Vereinszeile auf der Plattform. Ihre Beitraege sind hier aufgefuehrt und muessen ausserhalb gestellt werden.'
                    ELSE NULL END);
END $$;
REVOKE ALL ON FUNCTION public.treffen_verrechnen(uuid,int) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_verrechnen(uuid,int) TO authenticated;
