-- Die beiden uebrigen Stapelschreibungen in je eine Transaktion.
--
-- writeBatch im Browser ist kein Stapel: die Schreibvorgaenge laufen
-- nacheinander, ohne Transaktion. Beim Jahresabschluss war das bereits
-- behoben; hier die beiden anderen Stellen.
--
-- Die zweite ist dabei schlimmer, als ich zuerst gesagt hatte. Ich hielt
-- sie fuer selbstheilend -- das ist falsch. Je Zahlung werden ZWEI Dinge
-- geschrieben: die Buchung ins Journal und das Haekchen bookedInJournal
-- an der Zahlung. Bricht es dazwischen ab, steht die Buchung da, die
-- Zahlung gilt aber weiter als unverbucht -- und der naechste Lauf bucht
-- sie ein ZWEITES Mal. Nicht ein Ausfall, sondern eine Doppelbuchung.

-- ---------------------------------------------------------------- Konten
-- Der Standardkontenplan gehoert in die Datenbank.
--
-- Bisher stand er im Browser (DEFAULT_ACCOUNTS) und wurde von dort Zeile
-- fuer Zeile geschrieben. Brach es in der Mitte ab, hatte der Verein einen
-- halben Kontenplan -- und weil die Aussaat nur bei LEERER Tabelle laeuft,
-- waere sie nie wieder angesprungen.
CREATE OR REPLACE FUNCTION public.kontenplan_anlegen()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_vorher int;
  v_nachher int;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf den Kontenplan anlegen.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT count(*) INTO v_vorher FROM public.accounting_accounts WHERE "tenantId"=v_verein;

  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category, "systemAccount")
  SELECT k.code, v_verein, k.code, k.name, k.klasse, k.gruppe, k.system
    FROM (VALUES
      ('1000','Kasse CHF','ASSET','Flüssige Mittel',false),
      ('1001','Kasse EUR','ASSET','Flüssige Mittel',false),
      ('1020','Bank','ASSET','Flüssige Mittel',true),
      ('1021','PayPal','ASSET','Flüssige Mittel',false),
      ('1100','Forderungen (Mitglieder)','ASSET','Forderungen',false),
      ('1500','Mobile Sachanlagen','ASSET','Anlagevermögen',false),
      ('2000','Kreditoren (VLL)','LIABILITY','Kurzfr. Fremdkapital',false),
      ('2200','Übrige kurzfr. Verbindlichkeiten','LIABILITY','Kurzfr. Fremdkapital',false),
      ('2900','Vereinsvermögen (Eigenkapital)','LIABILITY','Eigenkapital',false),
      ('9100','Eröffnungsbilanz (Vortragskonto)','LIABILITY','Eigenkapital',true),
      ('3000','Mitgliederbeiträge','REVENUE','Betrieblicher Ertrag',false),
      ('3200','Dienstleistungserlöse','REVENUE','Betrieblicher Ertrag',false),
      ('3400','Spenden / Zuwendungen','REVENUE','Betrieblicher Ertrag',false),
      ('3600','Erträge aus Veranstaltungen','REVENUE','Betrieblicher Ertrag',false),
      ('3805','Verluste aus Forderungen','EXPENSE','Erlösminderungen',false),
      ('4000','Materialaufwand','EXPENSE','Materialaufwand',false),
      ('6000','Raumaufwand','EXPENSE','Betriebsaufwand',false),
      ('6200','Fahrzeuge / Transport','EXPENSE','Betriebsaufwand',false),
      ('6500','Informatik & Admin','EXPENSE','Verwaltungsaufwand',false),
      ('6570','Porti & Gebühren','EXPENSE','Verwaltungsaufwand',false),
      ('6700','Werbung & PR','EXPENSE','Werbeaufwand',false),
      ('6900','Bankspesen','EXPENSE','Finanzaufwand',false),
      ('6950','Abschreibungen','EXPENSE','Abschreibungen',false)
    ) AS k(code, name, klasse, gruppe, system)
  -- Der Konflikt gehoert auf den KONTOCODE, nicht auf die Kennung.
  --
  -- Koretinis Konten tragen gemischte Kennungen: teils 'acc-1000', teils
  -- '1001'. Mit ON CONFLICT auf (tenantId, id) haette der Einfuegeversuch
  -- fuer Code 1000 die bestehende Zeile 'acc-1000' nicht erkannt -- und
  -- waere am eindeutigen Index accounting_accounts_code_je_verein
  -- gescheitert. Die ganze Funktion haette dort einen Fehler geworfen.
  --
  -- Der Code ist ohnehin der fachliche Schluessel: darauf zeigen die
  -- Fremdschluessel aus accounting_journal und expenses.
  ON CONFLICT ("tenantId", code) DO NOTHING;

  SELECT count(*) INTO v_nachher FROM public.accounting_accounts WHERE "tenantId"=v_verein;
  RETURN jsonb_build_object('vorher', v_vorher, 'nachher', v_nachher,
                            'ergaenzt', v_nachher - v_vorher);
END $$;
REVOKE ALL ON FUNCTION public.kontenplan_anlegen() FROM public;
GRANT EXECUTE ON FUNCTION public.kontenplan_anlegen() TO authenticated;


-- ------------------------------------------------------------- Zahlungen
CREATE OR REPLACE FUNCTION public.zahlungen_verbuchen(p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_gebucht int := 0;
  v_uebersprungen int := 0;
  r RECORD;
  v_soll text;
BEGIN
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
  LOOP
    -- Zweiter Riegel gegen Doppelbuchung: liegt zu dieser Zahlung schon
    -- eine Buchung vor, wird nur das Haekchen nachgezogen. Genau dieser
    -- Fall entstand, wenn der alte Stapel zwischen Buchung und Haekchen
    -- abbrach.
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
REVOKE ALL ON FUNCTION public.zahlungen_verbuchen(int) FROM public;
GRANT EXECUTE ON FUNCTION public.zahlungen_verbuchen(int) TO authenticated;
