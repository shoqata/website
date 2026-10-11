-- Was wurde tatsaechlich bezahlt?
--
-- Bisher gab es nur amount (Rechnungsbetrag) und paidAt (wann). "Bezahlt"
-- hiess damit zwangsläufig "vollstaendig". Das ist nicht nur eine fehlende
-- Anzeige -- es ist ein Buchungsfehler, und ich habe ihn beim Lesen von
-- book_payment_entries gefunden:
--
--   INSERT INTO accounting_journal (... amount ...)
--   VALUES (..., payment_asset_code(...), '1100', NEW.amount, ...)
--
-- Gebucht wird NEW.amount, also der Rechnungsbetrag. Wer 50 auf eine
-- 40er-Rechnung zahlt, erscheint im Journal mit 40 -- die 10 fehlen in
-- der Kasse, die es tatsaechlich gibt. Wer 30 zahlt, erscheint ebenfalls
-- mit 40: die Buchhaltung behauptet einen Eingang, den es nicht gab, und
-- die Forderung gilt als ausgeglichen, obwohl 10 offen sind. Bei einem
-- Verein, der mit "revisionssicher" wirbt, ist das der schwerere Teil
-- der Anfrage.
--
-- Warum eine eigene Tabelle und nicht ein Feld "bezahlt_betrag":
--
--   Der Verein sammelt ueber Nachbarschaftsverantwortliche Bargeld. Ein
--   Mitglied gibt 20 jetzt und 20 spaeter. Mit einem Feld muesste der
--   Vorstand den Wert ueberschreiben -- und damit ist weg, dass zweimal
--   etwas eingegangen ist, wann, von wem erfasst. Genau das will eine
--   Revision sehen. Eine Zeile je Eingang kann beides: den einfachen
--   Fall (ein Eingang) und den geteilten.
--
-- Der Zustand bleibt bewusst bei PENDING / PAID / CANCELLED. Ein neuer
-- Zustand TEILZAHLUNG haette alle Listen stillschweigend veraendert, die
-- "offen" als status='PENDING' abfragen -- eine halb bezahlte Rechnung
-- waere aus der Mahnliste verschwunden. Teilweise bezahlt ist darum
-- PENDING mit bezahlt > 0: weiter offen, weiter mahnbar, aber sichtbar
-- angezahlt.

-- --------------------------------------------------------- Die Eingaenge
CREATE TABLE IF NOT EXISTS public.zahlungseingaenge (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  "paymentId"   text NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  -- Negativ erlaubt: eine Rueckzahlung an das Mitglied ist ein Eingang
  -- mit umgekehrtem Vorzeichen. Null waere sinnlos und wuerde nur die
  -- Liste verlaengern.
  betrag        numeric NOT NULL CHECK (betrag <> 0),
  waehrung      text NOT NULL DEFAULT 'CHF',
  weg           text,                       -- CASH, TWINT, PAYPAL, QR_BILL …
  eingang       date NOT NULL DEFAULT current_date,
  "erfasstVon"  text,
  "erfasstAm"   timestamptz NOT NULL DEFAULT now(),
  notiz         text,
  -- Eingaenge aus dem Altbestand: fuer sie steht die Buchung schon im
  -- Journal, auf der Zahlung statt auf dem Eingang. Ohne dieses Merkmal
  -- wuerde die Uebernahme 80 Zahlungen doppelt buchen.
  altbestand    boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS zahlungseingaenge_zahlung
  ON public.zahlungseingaenge ("paymentId");
CREATE INDEX IF NOT EXISTS zahlungseingaenge_verein
  ON public.zahlungseingaenge ("tenantId", eingang DESC);

COMMENT ON TABLE public.zahlungseingaenge IS
  'Tatsaechliche Zahlungseingaenge je Rechnung. Eine Zeile je Eingang, '
  'damit Teilzahlungen und Korrekturen nachvollziehbar bleiben.';


-- -------------------------------------------------- Was daraus folgt
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS bezahlt numeric NOT NULL DEFAULT 0;

-- Was die Differenz bedeutet. Der Verein entscheidet das, nicht die
-- Software: ein Mehrbetrag kann eine Spende sein oder ein Guthaben fuers
-- naechste Jahr, ein Minderbetrag bleibt offen oder wird erlassen. Zu
-- raten hiesse, dem Verein eine Buchung unterzuschieben.
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS "differenzArt" text NOT NULL DEFAULT 'OFFEN';

DO $$ BEGIN
  ALTER TABLE public.payments ADD CONSTRAINT payments_differenz_art
    CHECK ("differenzArt" IN ('OFFEN','SPENDE','GUTHABEN','ERLASS'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

COMMENT ON COLUMN public.payments.bezahlt IS
  'Summe der Zahlungseingaenge. Wird aus zahlungseingaenge gepflegt, nie '
  'direkt geschrieben.';
COMMENT ON COLUMN public.payments."differenzArt" IS
  'Was die Abweichung zwischen amount und bezahlt bedeutet. OFFEN = der '
  'Vorstand hat nicht entschieden. SPENDE/GUTHABEN fuer Mehrbetrag, '
  'ERLASS fuer Minderbetrag.';


-- ---------------------------------------------- Summe und Zustand pflegen
--
-- An einer Stelle, ausgeloest von den Eingaengen. Die Anwendung soll
-- bezahlt nie selbst setzen -- zwei Quellen fuer eine Zahl laufen
-- auseinander, und dann stimmt weder Liste noch Buchhaltung.
CREATE OR REPLACE FUNCTION public.zahlung_stand_pflegen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_zahlung text := coalesce(NEW."paymentId", OLD."paymentId");
  v_summe numeric;
  v_soll numeric;
  v_status text;
  v_letzter date;
BEGIN
  SELECT coalesce(sum(e.betrag), 0), max(e.eingang)
    INTO v_summe, v_letzter
    FROM public.zahlungseingaenge e
   WHERE e."paymentId" = v_zahlung;

  SELECT p.amount, p.status INTO v_soll, v_status
    FROM public.payments p WHERE p.id = v_zahlung;

  -- Eine abgeschriebene Rechnung bleibt abgeschrieben. Sie durch einen
  -- Eingang wieder zu oeffnen waere eine stille Entscheidung ueber einen
  -- Vorgang, den jemand ausdruecklich beendet hat.
  IF v_status = 'CANCELLED' THEN
    UPDATE public.payments SET bezahlt = v_summe WHERE id = v_zahlung;
    RETURN NULL;
  END IF;

  UPDATE public.payments
     SET bezahlt = v_summe,
         status = CASE WHEN v_soll > 0 AND v_summe >= v_soll THEN 'PAID'
                       ELSE 'PENDING' END,
         -- paidAt nur setzen, wenn die Rechnung damit gedeckt ist.
         -- Bei einer Teilzahlung bliebe sonst ein Datum stehen, das
         -- "bezahlt am" bedeutet und es nicht ist.
         "paidAt" = CASE WHEN v_soll > 0 AND v_summe >= v_soll
                         THEN coalesce(v_letzter::text, current_date::text)
                         ELSE NULL END
   WHERE id = v_zahlung;

  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS zahlungseingaenge_stand ON public.zahlungseingaenge;
CREATE TRIGGER zahlungseingaenge_stand
  AFTER INSERT OR UPDATE OR DELETE ON public.zahlungseingaenge
  FOR EACH ROW EXECUTE FUNCTION public.zahlung_stand_pflegen();


-- ------------------------------------------------------ Die Buchung
--
-- Je Eingang eine Buchung, mit dem Betrag, der eingegangen ist. Das ist
-- der Kern der Korrektur.
--
-- Der Mehrbetrag wird hier NICHT aufgeteilt. Er laeuft zunaechst
-- vollstaendig gegen die Forderung 1100, die dadurch negativ werden kann
-- -- und eine negative Forderung IST ein Mehrbetrag, sauber in der Bilanz
-- sichtbar. Was daraus wird, entscheidet der Vorstand spaeter mit einer
-- eigenen Buchung (differenz_buchen). Haette die Aufteilung schon hier
-- stattgefunden, haette die Software im Augenblick des Eingangs raten
-- muessen, ob das eine Spende ist.
CREATE OR REPLACE FUNCTION public.eingang_verbuchen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r_zahlung record;
  v_konto text;
  v_text text;
BEGIN
  IF NEW.altbestand THEN
    RETURN NULL;   -- steht schon auf der Zahlung im Journal
  END IF;

  SELECT p.*, coalesce(nullif(p."invoiceNumber", ''), p.id) AS bezeichnung
    INTO r_zahlung FROM public.payments p WHERE p.id = NEW."paymentId";

  v_konto := public.payment_asset_code(
               coalesce(NEW.weg, r_zahlung.method), NEW.waehrung);

  -- Ohne Kontenplan keine Buchung -- aber auch kein Abbruch.
  --
  -- Das Journal hat einen Fremdschluessel auf (tenantId, debitCode). Ein
  -- Verein, der die Buchhaltung nicht eingerichtet hat, haette beim
  -- Erfassen eines Zahlungseingangs eine Fremdschluesselverletzung
  -- bekommen -- und damit den Eingang NICHT speichern koennen. Die
  -- Erfassung des Geldes haengt dann an einer Einstellung, die damit
  -- nichts zu tun hat. Der Selbsttest hat das gemeldet, weil er den
  -- Verein "demo" erwischte, der keinen Kontenplan hat.
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                  WHERE a."tenantId" = r_zahlung."tenantId" AND a.code = v_konto)
     OR NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                     WHERE a."tenantId" = r_zahlung."tenantId" AND a.code = '1100') THEN
    RETURN NULL;
  END IF;
  v_text := CASE WHEN NEW.betrag < 0 THEN 'Rückzahlung ' ELSE 'Zahlungseingang ' END
            || r_zahlung.bezeichnung;

  -- Der Eingang ist der Bezug, nicht die Zahlung. Sonst koennte eine
  -- zweite Teilzahlung nicht von der ersten unterschieden werden, und
  -- die vorhandene Doppelbuchungssperre (referenceId der Zahlung) haette
  -- sie verschluckt.
  INSERT INTO public.accounting_journal
    (id, "tenantId", date, description, "debitCode", "creditCode", amount,
     "referenceId", "isSystemEntry")
  VALUES (gen_random_uuid()::text, r_zahlung."tenantId", NEW.eingang::text,
          v_text, v_konto, '1100', NEW.betrag, NEW.id::text, true);

  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS zahlungseingaenge_buchen ON public.zahlungseingaenge;
CREATE TRIGGER zahlungseingaenge_buchen
  AFTER INSERT ON public.zahlungseingaenge
  FOR EACH ROW EXECUTE FUNCTION public.eingang_verbuchen();


-- -------------------------------------------------- Zeilenrechte
ALTER TABLE public.zahlungseingaenge ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS eingaenge_lesen ON public.zahlungseingaenge;
CREATE POLICY eingaenge_lesen ON public.zahlungseingaenge
  FOR SELECT TO authenticated
  USING (public.is_platform_admin()
         OR ("tenantId" = public.current_tenant() AND public.is_staff())
         -- Das Mitglied sieht die Eingaenge zur eigenen Rechnung. Es
         -- soll nachsehen koennen, ob seine Zahlung angekommen ist,
         -- ohne beim Vorstand anzurufen.
         OR EXISTS (SELECT 1 FROM public.payments p
                     WHERE p.id = "paymentId"
                       AND p."userId" = public.current_user_row_id()));

-- Geschrieben wird nur ueber die Funktionen. Ein direkter Insert aus der
-- Anwendung koennte den Verein, den Erfasser oder das Altbestandsmerkmal
-- frei setzen -- und damit die Buchung umgehen.
REVOKE ALL ON TABLE public.zahlungseingaenge FROM anon, authenticated;
GRANT SELECT ON TABLE public.zahlungseingaenge TO authenticated;


-- =========================================================== Erfassen
--
-- Ueber Funktionen statt ueber Inserts aus der Anwendung: der Verein,
-- der Erfasser und das Altbestandsmerkmal duerfen nicht vom Aufrufer
-- kommen. Wer sie setzen kann, kann die Buchung umgehen oder einen
-- Eingang einem fremden Verein zuschreiben.
CREATE OR REPLACE FUNCTION public.zahlung_eingang_erfassen(
  p_payment text,
  p_betrag  numeric,
  p_weg     text DEFAULT NULL,
  p_eingang date DEFAULT NULL,
  p_notiz   text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r record;
  v_me text := public.current_user_row_id();
  v_id uuid;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf einen Zahlungseingang erfassen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_betrag IS NULL OR p_betrag = 0 THEN
    RAISE EXCEPTION 'Ein Zahlungseingang ohne Betrag ergibt keinen Sinn.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ein abgeschlossenes Geschaeftsjahr nimmt keine Buchung mehr an. Ohne
  -- diese Pruefung waere der Jahresabschluss eine Anzeige und keine
  -- Schranke -- und die Revision haette keinen festen Stand.
  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from coalesce(p_eingang, current_date))::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.',
      extract(year from coalesce(p_eingang, current_date))::int
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.zahlungseingaenge
    ("tenantId", "paymentId", betrag, waehrung, weg, eingang, "erfasstVon", notiz)
  VALUES (r."tenantId", p_payment, p_betrag, coalesce(r.currency, 'CHF'),
          coalesce(p_weg, r.method), coalesce(p_eingang, current_date), v_me, p_notiz)
  RETURNING id INTO v_id;

  -- Eine offene Meldung zu dieser Rechnung gilt damit als erledigt --
  -- derselbe Gedanke wie in mark_payment_paid. Sonst bliebe sie beim
  -- Vorstand als unentschieden stehen, obwohl das Geld erfasst ist.
  UPDATE public.payment_reports
     SET status = 'CONFIRMED', "decidedBy" = v_me, "decidedAt" = now(),
         "decisionNote" = 'Zahlungseingang erfasst'
   WHERE "paymentId" = p_payment AND status = 'OPEN';

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION public.zahlung_eingang_erfassen(text,numeric,text,date,text)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zahlung_eingang_erfassen(text,numeric,text,date,text)
  TO authenticated;


-- Einen falsch erfassten Eingang zuruecknehmen.
--
-- Nicht per DELETE aus der Anwendung: die Gegenbuchung muss mit, und ob
-- das Jahr noch offen ist, entscheidet der Server.
CREATE OR REPLACE FUNCTION public.zahlung_eingang_entfernen(p_eingang uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf das.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.zahlungseingaenge WHERE id = p_eingang;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Eingang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieser Eingang gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from r.eingang)::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.',
      extract(year from r.eingang)::int USING ERRCODE = 'check_violation';
  END IF;

  -- Die Buchung zum Eingang mit entfernen. Sie traegt den Eingang als
  -- Bezug, darum ist sie eindeutig auffindbar.
  DELETE FROM public.accounting_journal
   WHERE "tenantId" = r."tenantId" AND "referenceId" = p_eingang::text;

  DELETE FROM public.zahlungseingaenge WHERE id = p_eingang;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein DELETE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend die Zeile stehenblieb.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Der Eingang wurde nicht entfernt.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.zahlung_eingang_entfernen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zahlung_eingang_entfernen(uuid) TO authenticated;


-- ================================================== Die Differenz deuten
--
-- Der Vorstand entscheidet, was ein Mehr- oder Minderbetrag bedeutet,
-- und erst diese Entscheidung wird gebucht. Vier Faelle:
--
--   OFFEN    nichts gebucht. Der Mehrbetrag steht als negative Forderung,
--            der Minderbetrag als offene Forderung -- beides richtig und
--            beides sichtbar.
--   SPENDE   Mehrbetrag wird Spendenertrag (3200).
--   GUTHABEN Mehrbetrag wird Verbindlichkeit gegenueber dem Mitglied
--            (2000) und kann naechstes Jahr angerechnet werden.
--   ERLASS   Minderbetrag wird erlassen: der Ertrag, der nicht kommt,
--            wird zurueckgenommen.
--
-- Die Buchung traegt einen eigenen Bezug, damit ein Sinneswandel sie
-- ersetzen kann statt eine zweite daneben zu legen.
CREATE OR REPLACE FUNCTION public.zahlung_differenz_setzen(
  p_payment text, p_art text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r record;
  v_me text := public.current_user_row_id();
  v_differenz numeric;
  v_bezug text;
  v_ertragskonto text;
  v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf das entscheiden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_art IS NULL OR p_art NOT IN ('OFFEN','SPENDE','GUTHABEN','ERLASS') THEN
    RAISE EXCEPTION 'Unbekannte Art: %. Erlaubt sind OFFEN, SPENDE, GUTHABEN, ERLASS.', p_art
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_differenz := coalesce(r.bezahlt, 0) - r.amount;
  v_bezug := p_payment || ':differenz';

  -- Die Richtung muss zur Art passen. Einen Mehrbetrag zu "erlassen"
  -- oder einen Minderbetrag zur "Spende" zu machen waere eine Buchung
  -- mit falschem Vorzeichen -- formal durchgelassen, inhaltlich Unsinn,
  -- und in der Bilanz erst beim Abschluss auffaellig.
  IF p_art IN ('SPENDE','GUTHABEN') AND v_differenz <= 0 THEN
    RAISE EXCEPTION 'Es wurde nicht mehr bezahlt als verrechnet (Differenz %).', v_differenz
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_art = 'ERLASS' AND v_differenz >= 0 THEN
    RAISE EXCEPTION 'Es ist nichts offen, was erlassen werden koennte (Differenz %).', v_differenz
      USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from current_date)::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das laufende Geschaeftsjahr ist abgeschlossen.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Ohne Kontenplan wird nur die Art vermerkt, nicht gebucht -- gleicher
  -- Grund wie bei eingang_verbuchen.
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                  WHERE a."tenantId" = r."tenantId" AND a.code = '1100') THEN
    UPDATE public.payments SET "differenzArt" = p_art WHERE id = p_payment;
    RETURN jsonb_build_object('art', p_art, 'differenz', v_differenz,
                              'gebucht', false,
                              'hinweis', 'Kein Kontenplan -- nur vermerkt.');
  END IF;

  -- Eine frühere Entscheidung weicht. Sie stehenzulassen ergaebe zwei
  -- Buchungen fuer denselben Betrag.
  DELETE FROM public.accounting_journal
   WHERE "tenantId" = r."tenantId" AND "referenceId" = v_bezug;

  IF p_art = 'SPENDE' OR p_art = 'GUTHABEN' THEN
    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry")
    VALUES (gen_random_uuid()::text, r."tenantId", current_date::text,
            CASE WHEN p_art = 'SPENDE' THEN 'Mehrbetrag als Spende '
                 ELSE 'Mehrbetrag als Guthaben ' END
              || coalesce(nullif(r."invoiceNumber",''), r.id),
            '1100', CASE WHEN p_art = 'SPENDE' THEN '3200' ELSE '2000' END,
            v_differenz, v_bezug, true);

  ELSIF p_art = 'ERLASS' THEN
    -- Das Ertragskonto aus der Forderungsbuchung nehmen, nicht raten:
    -- der Verein bucht Diaspora auf 3000 und Kosovo auf 3100. Mit einem
    -- festen 3000 waere die Ruecknahme auf dem falschen Konto gelandet
    -- und die beiden Ertragsarten haetten nicht mehr gestimmt.
    SELECT j."creditCode" INTO v_ertragskonto
      FROM public.accounting_journal j
     WHERE j."tenantId" = r."tenantId" AND j."referenceId" = r.id
       AND j."creditCode" IN ('3000','3100')
     ORDER BY j."createdAt" NULLS LAST LIMIT 1;

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry")
    VALUES (gen_random_uuid()::text, r."tenantId", current_date::text,
            'Erlass Restbetrag ' || coalesce(nullif(r."invoiceNumber",''), r.id),
            coalesce(v_ertragskonto, '3000'), '1100', -v_differenz, v_bezug, true);
  END IF;

  UPDATE public.payments SET "differenzArt" = p_art WHERE id = p_payment;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Rechnung wurde nicht geaendert.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN jsonb_build_object('art', p_art, 'differenz', v_differenz,
                            'gebucht', p_art <> 'OFFEN');
END $$;

REVOKE ALL ON FUNCTION public.zahlung_differenz_setzen(text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zahlung_differenz_setzen(text,text) TO authenticated;


-- ============================================ Die alten Wege anschliessen
--
-- Drei Stellen buchen heute Zahlungen, und alle drei muessen ueber die
-- Eingaenge laufen -- sonst entstehen zwei Wahrheiten: eine in
-- payments.status und eine in den Eingaengen.

-- 1. Die Zahlung selbst darf den Eingang nicht mehr buchen, wenn es
--    Eingaenge gibt. Ohne diese Sperre buchte der Trigger auf der
--    Zahlung den Rechnungsbetrag UND der Trigger auf dem Eingang den
--    erhaltenen Betrag -- beides im Journal, der Eingang doppelt.
CREATE OR REPLACE FUNCTION public.book_payment_entries()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_label text;
  v_date  text;
BEGIN
  v_label := COALESCE(NULLIF(NEW."invoiceNumber", ''), NEW.id);

  -- 1. Forderung bei Rechnungsstellung. Unveraendert.
  IF NOT EXISTS (
    SELECT 1 FROM public.accounting_journal
     WHERE "referenceId" = NEW.id AND "creditCode" = '3000'
  ) THEN
    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD'),
      'Rechnung ' || v_label,
      '1100', '3000', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );
  END IF;

  -- 2. Zahlungseingang -- nur noch fuer Zahlungen OHNE erfasste
  --    Eingaenge. Das ist der Altbestand und alles, was ueber einen
  --    aelteren Weg hereinkommt. Wo Eingaenge stehen, bucht deren
  --    eigener Trigger, und zwar den Betrag, der wirklich kam.
  IF NEW.status = 'PAID'
     AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge e
                      WHERE e."paymentId" = NEW.id)
     AND NOT EXISTS (
       SELECT 1 FROM public.accounting_journal
        WHERE "referenceId" = NEW.id AND "creditCode" = '1100'
     ) THEN
    v_date := COALESCE(
      NULLIF(left(NEW."paidAt", 10), ''),
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD')
    );

    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      v_date,
      'Zahlungseingang ' || v_label,
      public.payment_asset_code(NEW.method, NEW.currency), '1100', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );

    IF NEW."bookedInJournal" IS DISTINCT FROM true THEN
      UPDATE public.payments SET "bookedInJournal" = true WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NULL;
END $$;


-- 2. Der Vorstand bucht direkt. Bisher setzte das nur den Zustand;
--    jetzt entsteht ein Eingang, und der Zustand folgt daraus. Der
--    Betrag ist neu und steht hinten mit Vorgabe -- ohne Angabe gilt
--    weiterhin "vollstaendig bezahlt", damit vorhandene Aufrufe
--    unveraendert weiterarbeiten.
DROP FUNCTION IF EXISTS public.mark_payment_paid(text, text, date);
CREATE OR REPLACE FUNCTION public.mark_payment_paid(
  p_payment text,
  p_method  text DEFAULT NULL,
  p_paid_on date DEFAULT NULL,
  p_betrag  numeric DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_offen numeric;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Zahlung buchen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ohne Betragsangabe: den noch offenen Rest. Das ist die bisherige
  -- Bedeutung von "als bezahlt buchen" und bleibt bei einer Zahlung
  -- ohne Eingaenge genau der Rechnungsbetrag.
  v_offen := coalesce(p_betrag, r.amount - coalesce(r.bezahlt, 0));
  IF v_offen = 0 THEN
    RETURN true;   -- schon gedeckt, nichts zu tun
  END IF;

  PERFORM public.zahlung_eingang_erfassen(
    p_payment, v_offen, coalesce(p_method, r.method), p_paid_on, NULL);
  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.mark_payment_paid(text,text,date,numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mark_payment_paid(text,text,date,numeric) TO authenticated;


-- 3. Der Stapellauf ueberspringt, was ueber Eingaenge gebucht ist.
--    Sonst legte er neben die Eingangsbuchungen eine zweite auf die
--    Zahlung -- mit dem Rechnungsbetrag, also genau dem Fehler, den
--    diese Migration behebt.
CREATE OR REPLACE FUNCTION public.zahlungen_verbuchen(p_jahr integer)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_gebucht int := 0;
  v_uebersprungen int := 0;
  r RECORD;
  v_soll text;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf verbuchen.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('BUCHHALTUNG') THEN
    RAISE EXCEPTION 'Das Modul Buchhaltung ist nicht aktiv.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId"=v_verein AND year=p_jahr AND status='CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.', p_jahr;
  END IF;

  FOR r IN
    SELECT p.id, p.amount, p.currency, p.method, p.description, p."invoiceNumber",
           coalesce(p."paidAt", p.timestamp::text) AS datum
      FROM public.payments p
     WHERE p."tenantId" = v_verein
       AND p.status = 'PAID'
       AND coalesce(p."bookedInJournal", false) = false
       AND substr(coalesce(p."paidAt", p.timestamp::text), 1, 4) = p_jahr::text
       -- Neu: Zahlungen mit erfassten Eingaengen sind dort gebucht.
       AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge e
                        WHERE e."paymentId" = p.id AND e.altbestand = false)
  LOOP
    IF EXISTS (SELECT 1 FROM public.accounting_journal j
                WHERE j."tenantId"=v_verein AND j."referenceId"=r.id) THEN
      UPDATE public.payments SET "bookedInJournal" = true WHERE id = r.id AND "tenantId"=v_verein;
      v_uebersprungen := v_uebersprungen + 1;
      CONTINUE;
    END IF;

    v_soll := CASE
      WHEN r.method = 'CASH'   THEN CASE WHEN r.currency = 'EUR' THEN '1001' ELSE '1000' END
      WHEN r.method = 'PAYPAL' THEN '1021'
      ELSE '1020' END;

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "createdAt")
    VALUES (gen_random_uuid()::text, v_verein, substr(r.datum,1,10),
            'Zahlungseingang: ' || coalesce(r.description,'Mitgliederbeitrag')
              || ' (' || coalesce(r."invoiceNumber",'-') || ')',
            v_soll, '1100', r.amount, r.id, now());

    UPDATE public.payments SET "bookedInJournal" = true WHERE id = r.id AND "tenantId" = v_verein;
    v_gebucht := v_gebucht + 1;
  END LOOP;

  RETURN jsonb_build_object('jahr', p_jahr, 'gebucht', v_gebucht,
                            'nachgetragen', v_uebersprungen);
END $$;


-- 4. Der Nachbarschaftsverantwortliche meldet, was er WIRKLICH bekommen hat.
--
-- Bisher stand im Melde-Satz p.amount, also der Rechnungsbetrag -- die
-- Spalte payment_reports.amount gab es schon, sie wurde nur nie mit dem
-- tatsaechlichen Betrag gefuellt. Wer an der Tuer 30 statt 40 bekommt,
-- konnte das nicht melden; der Vorstand bestaetigte anschliessend eine
-- Zahlung, die es so nicht gab.
DROP FUNCTION IF EXISTS public.report_payment_paid(text, text, date, text);
CREATE OR REPLACE FUNCTION public.report_payment_paid(
  p_payment text,
  p_method  text DEFAULT NULL,
  p_paid_on date DEFAULT NULL,
  p_note    text DEFAULT NULL,
  p_betrag  numeric DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_me     text := public.current_user_row_id();
  v_tenant text := public.current_tenant();
  v_betrag numeric;
  v_id     uuid;
BEGIN
  IF v_me IS NULL
     AND public.is_platform_admin()
     AND coalesce(public.current_tenant(), public.request_tenant()) = 'demo' THEN
    v_me := 'demo-v01';
    v_tenant := 'demo';
  END IF;

  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT p.amount INTO v_betrag FROM public.payments p WHERE p.id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht oder sie gehoert nicht zu Ihrer Nachbarschaft.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Angegebener Betrag hat Vorrang; ohne Angabe bleibt es wie bisher
  -- beim Rechnungsbetrag, damit vorhandene Aufrufe gleich wirken.
  IF p_betrag IS NOT NULL THEN
    IF p_betrag <= 0 THEN
      RAISE EXCEPTION 'Ein gemeldeter Betrag muss groesser als null sein.'
        USING ERRCODE = 'check_violation';
    END IF;
    v_betrag := p_betrag;
  END IF;

  INSERT INTO public.payment_reports
    ("tenantId", "paymentId", "reportedBy", method, amount, "paidOn", note)
  VALUES (v_tenant, p_payment, v_me, p_method, v_betrag,
          COALESCE(p_paid_on, current_date), p_note)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION public.report_payment_paid(text,text,date,text,numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.report_payment_paid(text,text,date,text,numeric) TO authenticated;


-- 5. Die Bestaetigung einer Meldung erzeugt einen Eingang mit dem
--    GEMELDETEN Betrag. Vorher setzte sie den Zustand auf PAID, und die
--    Buchung nahm den Rechnungsbetrag -- die Meldung "ich habe 30
--    bekommen" wurde damit zu einem Eingang von 40.
CREATE OR REPLACE FUNCTION public.decide_payment_report(
  p_report uuid, p_approve boolean, p_note text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_me text := public.current_user_row_id(); v_rest numeric;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Meldung entscheiden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payment_reports WHERE id = p_report;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meldung nicht gefunden.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Meldung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF r.status <> 'OPEN' THEN
    RAISE EXCEPTION 'Ueber diese Meldung wurde bereits entschieden.'
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.payment_reports
     SET status = CASE WHEN p_approve THEN 'CONFIRMED' ELSE 'REJECTED' END,
         "decidedBy" = v_me, "decidedAt" = now(), "decisionNote" = p_note
   WHERE id = p_report;

  IF p_approve THEN
    -- Der gemeldete Betrag, nicht der verrechnete. Fehlt er in einer
    -- alten Meldung, bleibt es beim offenen Rest -- das entspricht dem
    -- bisherigen Verhalten.
    SELECT coalesce(r.amount, p.amount - coalesce(p.bezahlt, 0))
      INTO v_rest FROM public.payments p WHERE p.id = r."paymentId";

    IF v_rest <> 0 THEN
      PERFORM public.zahlung_eingang_erfassen(
        r."paymentId", v_rest, r.method, r."paidOn"::date,
        'Meldung bestätigt');
    END IF;

    UPDATE public.payments
       SET "collectedBy" = COALESCE("collectedBy", r."reportedBy")
     WHERE id = r."paymentId";
  END IF;

  RETURN true;
END $$;


-- ====================================== Altbestand uebernehmen
--
-- Fuer die bereits bezahlten Rechnungen entsteht je ein Eingang in Hoehe
-- des Rechnungsbetrags -- das ist genau, was die Daten heute aussagen.
-- Mit altbestand = true, damit die Buchung NICHT wiederholt wird; sie
-- steht schon auf der Zahlung.
--
-- paidAt wird danach wiederhergestellt. Der Trigger setzt es sonst auf
-- das reine Datum des Eingangs, und das waere eine stille Aenderung an
-- 80 bestehenden Zeilen -- richtig im Format, aber niemand hat sie
-- verlangt.
DO $$
DECLARE v_neu int; v_wieder int;
BEGIN
  CREATE TEMP TABLE _paidat_vorher AS
    SELECT id, "paidAt" FROM public.payments
     WHERE status = 'PAID' AND "paidAt" IS NOT NULL;

  INSERT INTO public.zahlungseingaenge
    ("tenantId", "paymentId", betrag, waehrung, weg, eingang, notiz, altbestand)
  SELECT p."tenantId", p.id, p.amount, coalesce(p.currency,'CHF'), p.method,
         coalesce(nullif(left(p."paidAt",10),'')::date, p.timestamp::date),
         'Übernahme bestehender Stand', true
    FROM public.payments p
   WHERE p.status = 'PAID'
     AND p.amount <> 0
     AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge e WHERE e."paymentId" = p.id);
  GET DIAGNOSTICS v_neu = ROW_COUNT;

  UPDATE public.payments p SET "paidAt" = v."paidAt"
    FROM _paidat_vorher v
   WHERE p.id = v.id AND p."paidAt" IS DISTINCT FROM v."paidAt";
  GET DIAGNOSTICS v_wieder = ROW_COUNT;

  DROP TABLE _paidat_vorher;
  RAISE NOTICE 'Altbestand: % Eingaenge angelegt, % Zahlungsdaten wiederhergestellt.',
    v_neu, v_wieder;
END $$;


-- =========================================================== Selbsttest
--
-- Prueft die eigene Wirkung, nicht den Weltzustand -- die Migration darf
-- ein zweites Mal laufen. Vier Migrationen sind an genau diesem Fehler
-- gescheitert, weil sie "es gibt noch keine X" behauptet haben.
DO $$
DECLARE
  v_verein text;
  v_offen int; v_journal_vorher int; v_journal_nachher int;
  v_zahlung text := 'selbsttest-eingang-' || gen_random_uuid()::text;
  v_eingang uuid;
  v_gebucht numeric; v_stand numeric; v_status text; v_paidat text;
  v_rest int;
BEGIN
  -- 1. Uebernahme: jede bezahlte Rechnung hat jetzt einen Stand.
  SELECT count(*) INTO v_offen FROM public.payments
   WHERE status = 'PAID' AND amount <> 0 AND coalesce(bezahlt,0) <> amount;
  IF v_offen > 0 THEN
    RAISE EXCEPTION '% bezahlte Rechnung(en) ohne passenden Stand -- die Uebernahme '
                    'ist unvollstaendig.', v_offen;
  END IF;

  -- 2. Der Kern: bucht ein Eingang den ERHALTENEN Betrag?
  --
  -- Ein kuenstlicher Fall, 100 verrechnet und 130 erhalten. Genau die
  -- Zahl, die vorher falsch im Journal stand: dort haette 100 gestanden.
  -- Ausdruecklich ein Verein MIT Kontenplan. Der erste Versuch nahm den
  -- alphabetisch ersten, das war "demo" ohne Konten -- und damit haette
  -- der Test die Buchung nie geprueft, sondern nur ihr Ausbleiben.
  SELECT a."tenantId" INTO v_verein
    FROM public.accounting_accounts a
   WHERE a.code = '1100'
     AND EXISTS (SELECT 1 FROM public.accounting_accounts b
                  WHERE b."tenantId" = a."tenantId" AND b.code = '1000')
   LIMIT 1;
  IF v_verein IS NULL THEN
    RAISE NOTICE 'Kein Verein mit Kontenplan -- der Buchungstest wird uebersprungen.';
    RETURN;
  END IF;

  SELECT count(*) INTO v_journal_vorher FROM public.accounting_journal
   WHERE "tenantId" = v_verein;

  INSERT INTO public.payments (id, "tenantId", amount, currency, status, method, "invoiceNumber")
  VALUES (v_zahlung, v_verein, 100, 'CHF', 'PENDING', 'CASH', 'SELBSTTEST');

  INSERT INTO public.zahlungseingaenge
    ("tenantId", "paymentId", betrag, waehrung, weg, eingang)
  VALUES (v_verein, v_zahlung, 130, 'CHF', 'CASH', current_date)
  RETURNING id INTO v_eingang;

  SELECT amount INTO v_gebucht FROM public.accounting_journal
   WHERE "referenceId" = v_eingang::text;
  IF v_gebucht IS NULL THEN
    RAISE EXCEPTION 'Der Eingang wurde nicht gebucht.';
  END IF;
  IF v_gebucht <> 130 THEN
    RAISE EXCEPTION 'Gebucht wurden % statt der erhaltenen 130 -- genau der Fehler, '
                    'den diese Migration behebt.', v_gebucht;
  END IF;

  -- 3. Stand und Zustand folgen dem Eingang.
  SELECT bezahlt, status, "paidAt" INTO v_stand, v_status, v_paidat
    FROM public.payments WHERE id = v_zahlung;
  IF v_stand <> 130 THEN RAISE EXCEPTION 'Stand ist % statt 130.', v_stand; END IF;
  IF v_status <> 'PAID' THEN RAISE EXCEPTION 'Zustand ist % statt PAID.', v_status; END IF;
  IF v_paidat IS NULL THEN RAISE EXCEPTION 'Das Zahlungsdatum fehlt.'; END IF;

  -- 4. Keine zweite Buchung auf der Zahlung. Ohne die Sperre in
  --    book_payment_entries stuende hier eine weitere Zeile mit 100.
  IF EXISTS (SELECT 1 FROM public.accounting_journal
              WHERE "referenceId" = v_zahlung AND "creditCode" = '1100') THEN
    RAISE EXCEPTION 'Die Zahlung wurde zusaetzlich gebucht -- Eingang doppelt.';
  END IF;

  -- 5. Teilzahlung bleibt offen und mahnbar.
  DELETE FROM public.accounting_journal WHERE "referenceId" = v_eingang::text;
  DELETE FROM public.zahlungseingaenge WHERE id = v_eingang;
  INSERT INTO public.zahlungseingaenge
    ("tenantId", "paymentId", betrag, waehrung, weg, eingang)
  VALUES (v_verein, v_zahlung, 30, 'CHF', 'CASH', current_date)
  RETURNING id INTO v_eingang;

  SELECT bezahlt, status, "paidAt" INTO v_stand, v_status, v_paidat
    FROM public.payments WHERE id = v_zahlung;
  IF v_stand <> 30 THEN RAISE EXCEPTION 'Teilstand ist % statt 30.', v_stand; END IF;
  IF v_status <> 'PENDING' THEN
    RAISE EXCEPTION 'Eine Teilzahlung steht auf % -- sie waere aus der Mahnliste '
                    'verschwunden.', v_status;
  END IF;
  IF v_paidat IS NOT NULL THEN
    RAISE EXCEPTION 'Eine Teilzahlung traegt ein Zahlungsdatum (%) -- das bedeutet '
                    '"bezahlt am" und ist es nicht.', v_paidat;
  END IF;

  -- 6. Aufraeumen und nachweisen, dass nichts zurueckbleibt.
  DELETE FROM public.accounting_journal
   WHERE "referenceId" IN (v_eingang::text, v_zahlung);
  DELETE FROM public.payments WHERE id = v_zahlung;

  SELECT count(*) INTO v_rest FROM public.zahlungseingaenge WHERE "paymentId" = v_zahlung;
  IF v_rest > 0 THEN
    RAISE EXCEPTION '% Eingang(e) des Selbsttests blieben stehen.', v_rest;
  END IF;
  SELECT count(*) INTO v_journal_nachher FROM public.accounting_journal
   WHERE "tenantId" = v_verein;
  IF v_journal_nachher <> v_journal_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Journalzeile(n) hinterlassen.',
      v_journal_nachher - v_journal_vorher;
  END IF;

  RAISE NOTICE 'Zahlungseingaenge bereit: Buchung nimmt den erhaltenen Betrag, '
               'Teilzahlung bleibt offen, Selbsttest ohne Rueckstand.';
END $$;


-- Und die Schranken, getrennt geprueft: die Anwendung darf nicht direkt
-- schreiben, sonst waere der Weg ueber die Funktionen eine Empfehlung
-- und keine Schranke.
DO $$
BEGIN
  IF has_table_privilege('authenticated', 'public.zahlungseingaenge', 'INSERT') THEN
    RAISE EXCEPTION 'authenticated darf direkt Eingaenge anlegen -- damit liesse sich '
                    'der Verein, der Erfasser und das Altbestandsmerkmal frei setzen.';
  END IF;
  IF has_table_privilege('authenticated', 'public.zahlungseingaenge', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.zahlungseingaenge', 'DELETE') THEN
    RAISE EXCEPTION 'authenticated darf Eingaenge aendern oder loeschen -- die '
                    'Gegenbuchung bliebe dabei stehen.';
  END IF;
  IF NOT has_table_privilege('authenticated', 'public.zahlungseingaenge', 'SELECT') THEN
    RAISE EXCEPTION 'authenticated darf nicht lesen -- dann sieht niemand den Stand.';
  END IF;
  RAISE NOTICE 'Schranken stehen: lesen ja, schreiben nur ueber die Funktionen.';
END $$;
