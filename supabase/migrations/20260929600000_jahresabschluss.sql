-- Der Jahresabschluss gehoert in die Datenbank, nicht in den Browser.
--
-- Bisher lief er als "writeBatch" im Frontend. Das ist kein Stapel: die
-- Schreibvorgaenge laufen nacheinander, ohne Transaktion --
--
--   commit: async () => { for (const op of operations) { await op(); } }
--
-- und zwar in dieser Reihenfolge: erst wird das Jahr auf CLOSED gesetzt,
-- danach werden die Vortraege gebucht. Bricht etwas dazwischen ab -- ein
-- Netzwerkfehler, ein geschlossener Deckel, eine Zeilenregel --, ist das
-- Geschaeftsjahr gesperrt und der Vortrag unvollstaendig. Das ist der
-- schlechteste denkbare Ausgang: die Buecher sind zu, und die Eroeffnung
-- des Folgejahres stimmt nicht.
--
-- Hier laeuft alles in einer Transaktion. Geht etwas schief, ist nichts
-- geschehen.
--
-- Dazu zwei Dinge, die vorher fehlten:
--
-- 1. Eine Bilanzpruefung als SPERRE. Die Oberflaeche zeigte eine
--    Bilanzdifferenz zwar rot an, hinderte aber niemanden am Abschluss.
--    Die Differenz landete dann still auf 9100 und wurde ins naechste Jahr
--    getragen, wo sie niemandem mehr auffaellt.
--
-- 2. Richtige Buchungsrichtung bei negativen Saldi. Vorher wurde der Saldo
--    als Betrag geschrieben, auch wenn er negativ war -- eine Buchung ueber
--    minus 300 Franken statt einer Gegenbuchung ueber 300.

CREATE OR REPLACE FUNCTION public.jahresabschluss(p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein   text := public.current_tenant();
  v_naechst  int  := p_jahr + 1;
  v_ertrag   numeric := 0;
  v_aufwand  numeric := 0;
  v_gewinn   numeric;
  v_aktiva   numeric := 0;
  v_passiva  numeric := 0;
  v_differenz numeric;
  v_gebucht  int := 0;
  r RECORD;
  v_betrag numeric;
  v_soll text; v_haben text;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf abschliessen.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('BUCHHALTUNG') THEN
    RAISE EXCEPTION 'Das Modul Buchhaltung ist fuer diesen Verein nicht aktiv.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Riegel 1: schon abgeschlossen?
  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId" = v_verein AND year = p_jahr AND status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist bereits abgeschlossen.', p_jahr;
  END IF;

  -- Riegel 2: bestehen die Eroeffnungsbuchungen schon? Ein zweiter Lauf
  -- wuerde die Vortraege verdoppeln.
  IF EXISTS (SELECT 1 FROM public.accounting_journal
              WHERE "tenantId" = v_verein
                AND date = (v_naechst::text || '-01-01')
                AND "isSystemEntry") THEN
    RAISE EXCEPTION 'Fuer % bestehen bereits Eroeffnungsbuchungen.', v_naechst;
  END IF;

  -- Ergebnis und Bilanzsummen des Jahres.
  SELECT
    coalesce(sum(CASE WHEN a.class='REVENUE' THEN s.haben - s.soll END), 0),
    coalesce(sum(CASE WHEN a.class='EXPENSE' THEN s.soll - s.haben END), 0),
    coalesce(sum(CASE WHEN a.class='ASSET'   THEN s.soll - s.haben END), 0),
    coalesce(sum(CASE WHEN a.class='LIABILITY' THEN s.haben - s.soll END), 0)
  INTO v_ertrag, v_aufwand, v_aktiva, v_passiva
  FROM public.accounting_accounts a
  JOIN LATERAL (
    SELECT coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
           coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
      FROM public.accounting_journal j
     WHERE j."tenantId" = v_verein AND substr(j.date, 1, 4) = p_jahr::text
  ) s ON true
  WHERE a."tenantId" = v_verein;

  v_gewinn := v_ertrag - v_aufwand;
  v_differenz := v_aktiva - (v_passiva + v_gewinn);

  -- Riegel 3: die Bilanz muss aufgehen. Vorher war das nur ein roter
  -- Hinweis in der Oberflaeche -- abschliessen konnte man trotzdem.
  IF abs(v_differenz) > 0.05 THEN
    RAISE EXCEPTION
      'Bilanzdifferenz % CHF (Aktiven % , Passiven % , Ergebnis %). Nicht abgeschlossen.',
      round(v_differenz,2), round(v_aktiva,2), round(v_passiva,2), round(v_gewinn,2);
  END IF;

  -- Vortraege. Je Bilanzkonto eine Buchung gegen 9100.
  FOR r IN
    SELECT a.code, a.class,
           CASE WHEN a.class='ASSET' THEN s.soll - s.haben ELSE s.haben - s.soll END
             + CASE WHEN a.code = '2900' THEN v_gewinn ELSE 0 END AS saldo
      FROM public.accounting_accounts a
      JOIN LATERAL (
        SELECT coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
               coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
          FROM public.accounting_journal j
         WHERE j."tenantId" = v_verein AND substr(j.date, 1, 4) = p_jahr::text
      ) s ON true
     WHERE a."tenantId" = v_verein AND a.class IN ('ASSET','LIABILITY')
       AND a.code <> '9100'       -- das Vortragskonto traegt sich nicht selbst vor
  LOOP
    CONTINUE WHEN abs(r.saldo) <= 0.005;

    -- Richtung aus dem VORZEICHEN, nicht aus der Kontoklasse allein. Ein
    -- ueberzogenes Bankkonto hat als Aktivum einen negativen Saldo; vorher
    -- wurde daraus eine Buchung ueber einen negativen Betrag.
    v_betrag := abs(r.saldo);
    IF (r.class = 'ASSET') = (r.saldo > 0) THEN
      v_soll := r.code; v_haben := '9100';
    ELSE
      v_soll := '9100'; v_haben := r.code;
    END IF;
    -- KEIN zusaetzlicher Tausch fuer Passivkonten. Die Bedingung oben
    -- deckt alle vier Faelle bereits ab; ein Tausch danach drehte die
    -- Passivseite wieder falsch herum. Durchgerechnet:
    --   Aktiv  +  -> Soll Konto / Haben 9100
    --   Aktiv  -  -> Soll 9100  / Haben Konto
    --   Passiv +  -> Soll 9100  / Haben Konto
    --   Passiv -  -> Soll Konto / Haben 9100

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "createdAt", "isSystemEntry")
    VALUES (gen_random_uuid()::text, v_verein, v_naechst::text || '-01-01',
            'Eröffnungsbilanz (Vortrag aus ' || p_jahr || ')',
            v_soll, v_haben, v_betrag, now(), true);
    v_gebucht := v_gebucht + 1;
  END LOOP;

  -- Erst jetzt den Abschluss vermerken. In einer Transaktion ist die
  -- Reihenfolge zwar gleichgueltig -- aber sie sagt, was gemeint ist.
  INSERT INTO public.fiscal_years (id, "tenantId", year, status, "closedAt", "netProfit")
  VALUES (p_jahr::text, v_verein, p_jahr, 'CLOSED', now()::text, v_gewinn)
  ON CONFLICT ("tenantId", id) DO UPDATE
    SET status = 'CLOSED', "closedAt" = now()::text, "netProfit" = v_gewinn;

  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  VALUES (v_naechst::text, v_verein, v_naechst, 'OPEN')
  ON CONFLICT ("tenantId", id) DO NOTHING;

  RETURN jsonb_build_object(
    'jahr', p_jahr, 'ertrag', round(v_ertrag,2), 'aufwand', round(v_aufwand,2),
    'ergebnis', round(v_gewinn,2), 'aktiven', round(v_aktiva,2),
    'passiven', round(v_passiva,2), 'vortraege', v_gebucht);
END $$;

REVOKE ALL ON FUNCTION public.jahresabschluss(int) FROM public;
GRANT EXECUTE ON FUNCTION public.jahresabschluss(int) TO authenticated;
