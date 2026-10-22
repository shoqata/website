-- Vertreter vor Ort: Barinkasso, Handkasse, Ausgaben, Neuerfassung, Aufgaben.
--
-- Nachbau des urspruenglichen Beschriebs "Vertreter vor Ort", aber auf der
-- heutigen Grundlage:
--   * Wer Vertreter ist, steht in der Nachbarschaft (my_neighborhoods), nicht
--     an der Rolle. Die Vertreter bei Koretini sind gewoehnliche Mitglieder.
--   * Jede Faehigkeit gibt die Administration je Person frei, wie schon das
--     Sehen und Weiterleiten der Rechnungen (vertreter_rechte).
--   * Alles laeuft ueber Funktionen. Der Vertreter bekommt keine Schreibrechte
--     auf payments, expenses, users oder tasks -- die Funktionen pruefen
--     Recht und Nachbarschaft und schreiben genau das, was der Vorgang
--     verlangt.
--
-- Entscheid der Vereinsfuehrung: Bar kassiert heisst sofort bezahlt. Der
-- Vorstand prueft hinterher. Dafuer fuehrt jeder Vertreter eine Handkasse
-- (vertreter_kasse): Einnahmen, Ausgaben, Bankeinzahlungen. Der Bestand ist
-- das Geld, das er dem Verein schuldet. Eine Bankeinzahlung gilt erst, wenn
-- der Vorstand sie bestaetigt -- dann wird sie auch gebucht (Kasse an Bank).
--
-- Gebucht wird ueber die vorhandenen Wege: Ein Bareingang ist ein
-- Zahlungseingang mit weg CASH. Dessen Trigger setzt die Rechnung auf
-- bezahlt und bucht auf 1001 Kasse EUR bzw. 1000 Kasse CHF.

-- ------------------------------------------------------------ Rechte
ALTER TABLE public.vertreter_rechte
  ADD COLUMN IF NOT EXISTS kassieren boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ausgaben  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS erfassen  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS aufgaben  boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.vertreter_darf(p_recht text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_neighborhood_steward() AND EXISTS (
    SELECT 1 FROM public.vertreter_rechte r
     WHERE r."tenantId" = public.current_tenant()
       AND r.person = public.current_user_row_id()
       AND CASE p_recht WHEN 'SEHEN'     THEN r.rechnungen_sehen
                        WHEN 'SENDEN'    THEN r.rechnungen_senden
                        WHEN 'KASSIEREN' THEN r.kassieren
                        WHEN 'AUSGABEN'  THEN r.ausgaben
                        WHEN 'ERFASSEN'  THEN r.erfassen
                        WHEN 'AUFGABEN'  THEN r.aufgaben
                        ELSE false END);
$$;

DROP FUNCTION IF EXISTS public.meine_vertreter_rechte();
CREATE FUNCTION public.meine_vertreter_rechte()
RETURNS TABLE (sehen boolean, senden boolean, kassieren boolean, ausgaben boolean,
               erfassen boolean, aufgaben boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.vertreter_darf('SEHEN'), public.vertreter_darf('SENDEN'),
         public.vertreter_darf('KASSIEREN'), public.vertreter_darf('AUSGABEN'),
         public.vertreter_darf('ERFASSEN'), public.vertreter_darf('AUFGABEN');
$$;
REVOKE ALL ON FUNCTION public.meine_vertreter_rechte() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.meine_vertreter_rechte() TO authenticated;

DROP FUNCTION IF EXISTS public.vertreter_rechte_stand();
CREATE FUNCTION public.vertreter_rechte_stand()
RETURNS TABLE (person text, sehen boolean, senden boolean, kassieren boolean,
               ausgaben boolean, erfassen boolean, aufgaben boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT r.person, r.rechnungen_sehen, r.rechnungen_senden, r.kassieren,
         r.ausgaben, r.erfassen, r.aufgaben
    FROM public.vertreter_rechte r
   WHERE r."tenantId" = public.current_tenant()
     AND (public.is_member_manager() OR public.is_platform_admin());
$$;
REVOKE ALL ON FUNCTION public.vertreter_rechte_stand() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechte_stand() TO authenticated;

DROP FUNCTION IF EXISTS public.vertreter_rechte_setzen(text, boolean, boolean);
CREATE FUNCTION public.vertreter_rechte_setzen(
  p_person text, p_sehen boolean, p_senden boolean,
  p_kassieren boolean DEFAULT NULL, p_ausgaben boolean DEFAULT NULL,
  p_erfassen boolean DEFAULT NULL, p_aufgaben boolean DEFAULT NULL)
RETURNS TABLE (sehen boolean, senden boolean, kassieren boolean, ausgaben boolean,
               erfassen boolean, aufgaben boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_alt public.vertreter_rechte;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration bestimmt die Rechte der Verantwortlichen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.neighborhoods n
     WHERE n."tenantId" = v_verein
       AND (n."representativeId" = p_person OR n."managerId" = p_person
            OR coalesce(n."contactPersonIds",'[]'::jsonb) @> to_jsonb(p_person))) THEN
    RAISE EXCEPTION 'Diese Person betreut keine Nachbarschaft des Vereins.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_alt FROM public.vertreter_rechte r WHERE r."tenantId" = v_verein AND r.person = p_person;
  -- NULL heisst: unveraendert. So bleibt ein aelterer Aufruf mit nur zwei
  -- Rechten gueltig, ohne die neuen still zurueckzusetzen.
  p_kassieren := coalesce(p_kassieren, v_alt.kassieren, false);
  p_ausgaben  := coalesce(p_ausgaben,  v_alt.ausgaben,  false);
  p_erfassen  := coalesce(p_erfassen,  v_alt.erfassen,  false);
  p_aufgaben  := coalesce(p_aufgaben,  v_alt.aufgaben,  false);
  p_senden := coalesce(p_senden, false);
  -- Weiterleiten und Kassieren setzen voraus, dass er die Rechnungen sieht.
  p_sehen  := coalesce(p_sehen, false) OR p_senden OR p_kassieren;

  INSERT INTO public.vertreter_rechte AS r
         ("tenantId", person, rechnungen_sehen, rechnungen_senden, kassieren, ausgaben,
          erfassen, aufgaben, "geaendertVon", "geaendertAm")
  VALUES (v_verein, p_person, p_sehen, p_senden, p_kassieren, p_ausgaben,
          p_erfassen, p_aufgaben, public.current_user_row_id(), now())
  ON CONFLICT ("tenantId", person) DO UPDATE
     SET rechnungen_sehen = EXCLUDED.rechnungen_sehen,
         rechnungen_senden = EXCLUDED.rechnungen_senden,
         kassieren = EXCLUDED.kassieren, ausgaben = EXCLUDED.ausgaben,
         erfassen = EXCLUDED.erfassen, aufgaben = EXCLUDED.aufgaben,
         "geaendertVon" = EXCLUDED."geaendertVon",
         "geaendertAm" = now();

  RETURN QUERY SELECT p_sehen, p_senden, p_kassieren, p_ausgaben, p_erfassen, p_aufgaben;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_rechte_setzen(text, boolean, boolean, boolean, boolean, boolean, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechte_setzen(text, boolean, boolean, boolean, boolean, boolean, boolean) TO authenticated;

-- Der Feldschutz an users darf die Funktionen dieser Datei durchlassen: sie
-- setzen beim Kassieren den Mitgliedsstatus, der dem Vertreter sonst
-- gesperrt ist. Die Marke ist transaktionslokal und laesst sich vom Browser
-- aus nicht setzen (set_config ist ueber die Schnittstelle nicht erreichbar).
CREATE OR REPLACE FUNCTION public.users_vertreter_spalten_pruefen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text; v_verboten text; v_erlaubt text[];
  v_nur_eigenes_konto boolean;
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF current_setting('unityhub.vertreter_vorgang', true) = '1' THEN RETURN NEW; END IF;
  IF public.is_member_manager() OR public.is_platform_admin() THEN RETURN NEW; END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW; END IF;

  v_nur_eigenes_konto :=
       OLD."authUserId" IS NULL
   AND NEW."authUserId" = auth.uid()::text;

  SELECT t.vertreter_felder INTO v_erlaubt
    FROM public.tenants t WHERE t.id = NEW."tenantId";
  v_erlaubt := coalesce(v_erlaubt, '{}');

  SELECT string_agg(n.key, ', ' ORDER BY n.key) INTO v_verboten
    FROM jsonb_each(to_jsonb(NEW)) n
    LEFT JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
   WHERE n.value IS DISTINCT FROM o.value
     AND NOT (n.key = 'authUserId' AND v_nur_eigenes_konto)
     AND (NOT (n.key = ANY (v_erlaubt))
          OR n.key = ANY (public.vertreter_felder_gesperrt()));

  IF v_verboten IS NOT NULL THEN
    RAISE EXCEPTION 'Als Verantwortlicher einer Nachbarschaft koennen Sie diese Felder '
                    'nicht aendern: %. Die Vereinsadministration bestimmt, was Sie '
                    'pflegen duerfen.', v_verboten
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;

-- Den Trigger auf die neue Fassung umhaengen, Zeitpunkt wie bisher.
DROP TRIGGER IF EXISTS users_vertreter_spalten ON public.users;
CREATE TRIGGER users_vertreter_spalten BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.users_vertreter_spalten_pruefen();

-- ------------------------------------------------------------ Handkasse
CREATE TABLE IF NOT EXISTS public.vertreter_kasse (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"     text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  person         text NOT NULL,
  art            text NOT NULL CHECK (art IN ('EINNAHME','AUSGABE','BANKEINZAHLUNG')),
  betrag         numeric NOT NULL CHECK (betrag > 0),
  waehrung       text NOT NULL DEFAULT 'EUR' CHECK (waehrung IN ('EUR','CHF')),
  "paymentId"    text,
  "eingangId"    uuid,
  "expenseId"    text,
  mitglied       text,
  notiz          text,
  beleg          text,
  erfasst_am     timestamptz NOT NULL DEFAULT now(),
  bestaetigt_am  timestamptz,
  bestaetigt_von text
);
CREATE INDEX IF NOT EXISTS vertreter_kasse_person ON public.vertreter_kasse ("tenantId", person, erfasst_am DESC);
ALTER TABLE public.vertreter_kasse ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vertreter_kasse FROM anon, authenticated;

-- Bestand je Waehrung: Einnahmen minus Ausgaben minus Einzahlungen. Eine
-- noch nicht bestaetigte Einzahlung zaehlt schon -- das Geld hat die Kasse
-- verlassen. Ob es auf der Bank ankam, ist die Pruefung des Vorstands.
CREATE OR REPLACE FUNCTION public._kasse_bestand(p_verein text, p_person text)
RETURNS TABLE (waehrung text, bestand numeric, offen_einzahlung numeric)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT k.waehrung,
         sum(CASE k.art WHEN 'EINNAHME' THEN k.betrag ELSE -k.betrag END),
         coalesce(sum(k.betrag) FILTER (WHERE k.art = 'BANKEINZAHLUNG' AND k.bestaetigt_am IS NULL), 0)
    FROM public.vertreter_kasse k
   WHERE k."tenantId" = p_verein AND k.person = p_person
   GROUP BY k.waehrung;
$$;
REVOKE ALL ON FUNCTION public._kasse_bestand(text, text) FROM public, anon, authenticated;

-- Konto im Kontenplan vorhanden? Ohne Konto keine Kontierung -- aber auch
-- kein Abbruch, wie beim Zahlungseingang.
CREATE OR REPLACE FUNCTION public._konto_oder_null(p_verein text, p_code text)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.code FROM public.accounting_accounts a WHERE a."tenantId" = p_verein AND a.code = p_code;
$$;
REVOKE ALL ON FUNCTION public._konto_oder_null(text, text) FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public._kassenkonto(p_waehrung text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$ SELECT CASE WHEN p_waehrung = 'EUR' THEN '1001' ELSE '1000' END $$;

-- Meine Kasse: Bestand und die letzten Bewegungen.
CREATE OR REPLACE FUNCTION public.vertreter_kasse_lesen()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_ich text := public.current_user_row_id();
BEGIN
  IF NOT (public.vertreter_darf('KASSIEREN') OR public.vertreter_darf('AUSGABEN')) THEN
    RAISE EXCEPTION 'Die Handkasse ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN jsonb_build_object(
    'bestand', coalesce((SELECT jsonb_agg(to_jsonb(b)) FROM public._kasse_bestand(v_verein, v_ich) b), '[]'),
    'eintraege', coalesce((
      SELECT jsonb_agg(to_jsonb(x) ORDER BY x.erfasst_am DESC) FROM (
        SELECT k.id, k.art, k.betrag, k.waehrung, k.notiz, k.beleg, k.erfasst_am, k.bestaetigt_am,
               k."paymentId", k."expenseId",
               (SELECT coalesce(u."displayName", concat_ws(' ', u."firstName", u."lastName"))
                  FROM public.users u WHERE u.id = k.mitglied) AS mitglied_name,
               (SELECT e.status FROM public.expenses e WHERE e.id = k."expenseId") AS ausgabe_status
          FROM public.vertreter_kasse k
         WHERE k."tenantId" = v_verein AND k.person = v_ich
         ORDER BY k.erfasst_am DESC LIMIT 200) x), '[]'));
END $$;
REVOKE ALL ON FUNCTION public.vertreter_kasse_lesen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_kasse_lesen() TO authenticated;

-- ------------------------------------------------------------ Kassieren
--
-- Nimmt den Beitrag eines Mitglieds bar entgegen. Gibt es fuer das Jahr
-- eine offene Rechnung, wird sie (ganz oder teilweise) bezahlt; gibt es
-- keine, entsteht sie hier -- wie im Beschrieb: der Vertreter kassiert an
-- der Tuer, auch wenn nie eine Rechnung verschickt wurde.
CREATE OR REPLACE FUNCTION public.vertreter_kassieren(
  p_mitglied text, p_betrag numeric, p_waehrung text DEFAULT NULL, p_notiz text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich    text := public.current_user_row_id();
  v_jahr   int  := extract(year FROM now())::int;
  m public.users; p public.payments;
  v_gebuehr jsonb; v_soll numeric; v_waehrung text;
  v_eingang uuid; v_kasse uuid;
BEGIN
  IF NOT public.vertreter_darf('KASSIEREN') THEN
    RAISE EXCEPTION 'Kassieren ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > 10000 THEN
    RAISE EXCEPTION 'Der Betrag muss zwischen 0 und 10000 liegen.' USING ERRCODE = 'check_violation';
  END IF;
  SELECT * INTO m FROM public.users u
   WHERE u.id = p_mitglied AND u."tenantId" = v_verein
     AND u.id IN (SELECT public.vertreter_mitglieder());
  IF m.id IS NULL THEN
    RAISE EXCEPTION 'Diese Person gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Offene Rechnung des laufenden Jahres, die aelteste zuerst.
  SELECT * INTO p FROM public.payments x
   WHERE x."userId" = m.id AND x."tenantId" = v_verein
     AND coalesce(x."billingYear", extract(year FROM x."timestamp")::int) = v_jahr
     AND coalesce(x.status, 'PENDING') NOT IN ('PAID', 'CANCELLED')
   ORDER BY x."timestamp" NULLS LAST, x.id LIMIT 1;

  IF p.id IS NULL THEN
    IF EXISTS (SELECT 1 FROM public.payments x
                WHERE x."userId" = m.id AND x."tenantId" = v_verein AND x.status = 'PAID'
                  AND coalesce(x."billingYear", extract(year FROM x."timestamp")::int) = v_jahr) THEN
      RAISE EXCEPTION '% hat den Beitrag % bereits bezahlt.',
        coalesce(m."displayName", m."firstName"), v_jahr USING ERRCODE = 'check_violation';
    END IF;
    SELECT s.payment -> 'fees' -> coalesce(nullif(m."billingGroup", ''), 'STANDARD') INTO v_gebuehr
      FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'payment';
    v_waehrung := coalesce(p_waehrung, v_gebuehr ->> 'currency', m.currency, 'CHF');
    v_soll := coalesce(m."customAnnualFee", (v_gebuehr ->> 'amount')::numeric, p_betrag);
    INSERT INTO public.payments (id, "userId", "tenantId", "neighborhoodId", amount, currency, type,
           "invoiceType", "billingYear", method, status, "deliveryMethod", "timestamp", "dueDate",
           "invoiceNumber", description, "collectedBy", bezahlt)
    VALUES ('bar-' || replace(gen_random_uuid()::text, '-', ''), m.id, v_verein, m."neighborhoodId",
            v_soll, v_waehrung, 'FEE', 'MEMBERSHIP', v_jahr, 'CASH', 'PENDING', 'POST', now(),
            to_char(now(), 'YYYY-MM-DD'),
            'INV-' || v_jahr || '-' || upper(substr(md5(random()::text), 1, 6)),
            'Mitgliederbeitrag ' || v_jahr, v_ich, 0)
    RETURNING * INTO p;
  END IF;

  v_waehrung := coalesce(p.currency, 'CHF');
  IF p_waehrung IS NOT NULL AND p_waehrung <> v_waehrung THEN
    RAISE EXCEPTION 'Die Rechnung lautet auf %, nicht auf %.', v_waehrung, p_waehrung
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.zahlungseingaenge ("tenantId", "paymentId", betrag, waehrung, weg, eingang,
         "erfasstVon", notiz)
  VALUES (v_verein, p.id, p_betrag, v_waehrung, 'CASH', current_date, v_ich,
          coalesce(nullif(btrim(p_notiz), ''), 'Bar kassiert'))
  RETURNING id INTO v_eingang;

  UPDATE public.payments SET method = 'CASH', "collectedBy" = v_ich WHERE id = p.id;

  PERFORM set_config('unityhub.vertreter_vorgang', '1', true);
  UPDATE public.users SET "membershipStatus" = 'ACTIVE'
   WHERE id = m.id AND coalesce("membershipStatus", '') <> 'ACTIVE'
     AND (SELECT status FROM public.payments WHERE id = p.id) = 'PAID';
  PERFORM set_config('unityhub.vertreter_vorgang', '0', true);

  INSERT INTO public.vertreter_kasse ("tenantId", person, art, betrag, waehrung, "paymentId",
         "eingangId", mitglied, notiz)
  VALUES (v_verein, v_ich, 'EINNAHME', p_betrag, v_waehrung, p.id, v_eingang, m.id,
          nullif(btrim(p_notiz), ''))
  RETURNING id INTO v_kasse;

  RETURN (SELECT jsonb_build_object('kasse', v_kasse, 'payment', x.id, 'status', x.status,
                                    'bezahlt', x.bezahlt, 'soll', x.amount, 'waehrung', x.currency)
            FROM public.payments x WHERE x.id = p.id);
END $$;
REVOKE ALL ON FUNCTION public.vertreter_kassieren(text, numeric, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_kassieren(text, numeric, text, text) TO authenticated;

-- Was der Vertreter beim Kassieren vorbelegt sieht: offene Rechnung oder
-- der Jahresbeitrag der Beitragsgruppe. Die Einstellungen bleiben sonst dem
-- Vorstand vorbehalten.
CREATE OR REPLACE FUNCTION public.vertreter_kassier_vorschlag(p_mitglied text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_jahr int := extract(year FROM now())::int;
        m public.users; p public.payments; v_gebuehr jsonb;
BEGIN
  IF NOT public.vertreter_darf('KASSIEREN') THEN
    RAISE EXCEPTION 'Kassieren ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO m FROM public.users u WHERE u.id = p_mitglied AND u."tenantId" = v_verein
     AND u.id IN (SELECT public.vertreter_mitglieder());
  IF m.id IS NULL THEN
    RAISE EXCEPTION 'Diese Person gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO p FROM public.payments x
   WHERE x."userId" = m.id AND x."tenantId" = v_verein
     AND coalesce(x."billingYear", extract(year FROM x."timestamp")::int) = v_jahr
     AND coalesce(x.status, 'PENDING') NOT IN ('PAID', 'CANCELLED')
   ORDER BY x."timestamp" NULLS LAST, x.id LIMIT 1;
  IF p.id IS NOT NULL THEN
    RETURN jsonb_build_object('jahr', v_jahr, 'rechnung', p.id, 'betrag', p.amount - coalesce(p.bezahlt, 0),
                              'waehrung', p.currency, 'beschreibung', p.description);
  END IF;
  SELECT s.payment -> 'fees' -> coalesce(nullif(m."billingGroup", ''), 'STANDARD') INTO v_gebuehr
    FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'payment';
  RETURN jsonb_build_object('jahr', v_jahr, 'rechnung', NULL,
    'betrag', coalesce(m."customAnnualFee", (v_gebuehr ->> 'amount')::numeric),
    'waehrung', coalesce(v_gebuehr ->> 'currency', m.currency, 'CHF'),
    'beschreibung', 'Mitgliederbeitrag ' || v_jahr,
    'bereits_bezahlt', EXISTS (SELECT 1 FROM public.payments x
        WHERE x."userId" = m.id AND x."tenantId" = v_verein AND x.status = 'PAID'
          AND coalesce(x."billingYear", extract(year FROM x."timestamp")::int) = v_jahr));
END $$;
REVOKE ALL ON FUNCTION public.vertreter_kassier_vorschlag(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_kassier_vorschlag(text) TO authenticated;

-- Versehen rueckgaengig machen: nur eigene Einnahmen, nur am selben Tag.
-- Spaeter ist es Sache des Vorstands.
CREATE OR REPLACE FUNCTION public.vertreter_kassieren_rueckgaengig(p_kasse uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); k public.vertreter_kasse;
BEGIN
  IF NOT public.vertreter_darf('KASSIEREN') THEN
    RAISE EXCEPTION 'Kassieren ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO k FROM public.vertreter_kasse x
   WHERE x.id = p_kasse AND x."tenantId" = v_verein AND x.person = public.current_user_row_id()
     AND x.art = 'EINNAHME';
  IF k.id IS NULL THEN
    RAISE EXCEPTION 'Diesen Eintrag gibt es in Ihrer Kasse nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF k.erfasst_am::date <> current_date THEN
    RAISE EXCEPTION 'Nur am selben Tag. Melden Sie den Fehler dem Vorstand.' USING ERRCODE = 'check_violation';
  END IF;
  -- Den Zahlungseingang entfernen; dessen Trigger stellt die Rechnung
  -- wieder auf offen. Die Buchung im Journal wird storniert, nicht geloescht.
  DELETE FROM public.zahlungseingaenge WHERE id = k."eingangId";
  IF EXISTS (SELECT 1 FROM public.accounting_journal j WHERE j."referenceId" = k."eingangId"::text) THEN
    INSERT INTO public.accounting_journal (id, "tenantId", date, description, "debitCode", "creditCode",
           amount, "referenceId", "isSystemEntry")
    SELECT gen_random_uuid()::text, j."tenantId", current_date::text, 'Storno ' || j.description,
           j."creditCode", j."debitCode", j.amount, j."referenceId", true
      FROM public.accounting_journal j WHERE j."referenceId" = k."eingangId"::text
       AND j.description NOT LIKE 'Storno %';
  END IF;
  DELETE FROM public.vertreter_kasse WHERE id = k.id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_kassieren_rueckgaengig(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_kassieren_rueckgaengig(uuid) TO authenticated;

-- ------------------------------------------------------------ Bankeinzahlung
CREATE OR REPLACE FUNCTION public.vertreter_bankeinzahlung(
  p_betrag numeric, p_waehrung text DEFAULT 'EUR', p_notiz text DEFAULT NULL, p_beleg text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_ich text := public.current_user_row_id();
        v_bestand numeric; v_id uuid;
BEGIN
  IF NOT (public.vertreter_darf('KASSIEREN') OR public.vertreter_darf('AUSGABEN')) THEN
    RAISE EXCEPTION 'Die Handkasse ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT b.bestand INTO v_bestand FROM public._kasse_bestand(v_verein, v_ich) b WHERE b.waehrung = p_waehrung;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > coalesce(v_bestand, 0) THEN
    RAISE EXCEPTION 'Einzahlen lassen sich hoechstens % % (Kassenbestand).',
      coalesce(v_bestand, 0), p_waehrung USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO public.vertreter_kasse ("tenantId", person, art, betrag, waehrung, notiz, beleg)
  VALUES (v_verein, v_ich, 'BANKEINZAHLUNG', p_betrag, p_waehrung, nullif(btrim(p_notiz), ''),
          nullif(btrim(p_beleg), ''))
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_bankeinzahlung(numeric, text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_bankeinzahlung(numeric, text, text, text) TO authenticated;

-- ------------------------------------------------------------ Ausgaben
CREATE OR REPLACE FUNCTION public.vertreter_ausgabe(
  p_empfaenger text, p_betrag numeric, p_waehrung text DEFAULT 'EUR',
  p_beschreibung text DEFAULT NULL, p_datum date DEFAULT NULL, p_beleg text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_ich text := public.current_user_row_id();
        v_id text := 'vor-ort-' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  IF NOT public.vertreter_darf('AUSGABEN') THEN
    RAISE EXCEPTION 'Ausgaben erfassen ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_empfaenger), '') = '' THEN
    RAISE EXCEPTION 'Wo wurde eingekauft? Der Empfaenger fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > 5000 THEN
    RAISE EXCEPTION 'Der Betrag muss zwischen 0 und 5000 liegen.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_waehrung NOT IN ('EUR', 'CHF') THEN
    RAISE EXCEPTION 'Waehrung EUR oder CHF.' USING ERRCODE = 'check_violation';
  END IF;

  -- Bar aus der Handkasse bezahlt, also schon bezahlt -- aber noch nicht
  -- genehmigt und nicht gebucht. Genehmigen und Buchen bleibt beim Vorstand.
  INSERT INTO public.expenses (id, title, vendor, description, amount, currency, category, date,
         "categoryAccountCode", "paymentAccountCode", status, approved, paid, "bookedInJournal",
         "receiptUrl", "createdBy", timestamp, "createdAt", "tenantId")
  VALUES (v_id, btrim(p_empfaenger), btrim(p_empfaenger), nullif(btrim(p_beschreibung), ''),
          p_betrag, p_waehrung, 'Vor Ort', coalesce(p_datum, current_date)::text,
          public._konto_oder_null(v_verein, '4000'),
          public._konto_oder_null(v_verein, public._kassenkonto(p_waehrung)),
          'PENDING', false, true, false, nullif(btrim(p_beleg), ''), v_ich, now(), now(), v_verein);

  INSERT INTO public.vertreter_kasse ("tenantId", person, art, betrag, waehrung, "expenseId", notiz, beleg)
  VALUES (v_verein, v_ich, 'AUSGABE', p_betrag, p_waehrung, v_id,
          btrim(p_empfaenger) || coalesce(' — ' || nullif(btrim(p_beschreibung), ''), ''),
          nullif(btrim(p_beleg), ''));
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_ausgabe(text, numeric, text, text, date, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_ausgabe(text, numeric, text, text, date, text) TO authenticated;

-- Eigene Ausgabe zurueckziehen, solange der Vorstand sie nicht genehmigt
-- oder gebucht hat.
CREATE OR REPLACE FUNCTION public.vertreter_ausgabe_loeschen(p_ausgabe text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); e public.expenses;
BEGIN
  IF NOT public.vertreter_darf('AUSGABEN') THEN
    RAISE EXCEPTION 'Ausgaben erfassen ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO e FROM public.expenses x
   WHERE x.id = p_ausgabe AND x."tenantId" = v_verein AND x."createdBy" = public.current_user_row_id();
  IF e.id IS NULL THEN
    RAISE EXCEPTION 'Diese Ausgabe haben nicht Sie erfasst.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF e.status <> 'PENDING' OR coalesce(e.approved, false) OR coalesce(e."bookedInJournal", false) THEN
    RAISE EXCEPTION 'Der Vorstand hat diese Ausgabe schon bearbeitet. Aendern kann sie nur noch er.'
      USING ERRCODE = 'check_violation';
  END IF;
  DELETE FROM public.vertreter_kasse WHERE "expenseId" = e.id AND "tenantId" = v_verein;
  DELETE FROM public.expenses WHERE id = e.id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_ausgabe_loeschen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_ausgabe_loeschen(text) TO authenticated;

-- ------------------------------------------------------------ Neuerfassung
CREATE OR REPLACE FUNCTION public.vertreter_mitglied_anlegen(
  p_vorname text, p_nachname text, p_telefon text, p_strasse text, p_plz text, p_ort text,
  p_nachbarschaft text, p_gruppe text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_id text := gen_random_uuid()::text;
        v_gruppe text; v_land text; v_waehrung text; v_doppelt text;
BEGIN
  IF NOT public.vertreter_darf('ERFASSEN') THEN
    RAISE EXCEPTION 'Mitglieder erfassen ist fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_vorname), '') = '' OR coalesce(btrim(p_nachname), '') = '' THEN
    RAISE EXCEPTION 'Vor- und Nachname sind noetig.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_strasse), '') = '' OR coalesce(btrim(p_ort), '') = '' THEN
    RAISE EXCEPTION 'Strasse und Ort sind noetig.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_nachbarschaft IS NULL OR p_nachbarschaft NOT IN (SELECT public.my_neighborhoods()) THEN
    RAISE EXCEPTION 'In diese Nachbarschaft koennen Sie niemanden aufnehmen.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Dieselbe Person zweimal waere eine zweite Rechnung im Jahr.
  SELECT u.id INTO v_doppelt FROM public.users u
   WHERE u."tenantId" = v_verein
     AND lower(btrim(u."firstName")) = lower(btrim(p_vorname))
     AND lower(btrim(u."lastName"))  = lower(btrim(p_nachname))
     AND lower(btrim(coalesce(u.street, ''))) = lower(btrim(p_strasse))
   LIMIT 1;
  IF v_doppelt IS NOT NULL THEN
    RAISE EXCEPTION '% % an dieser Adresse ist schon erfasst.', btrim(p_vorname), btrim(p_nachname)
      USING ERRCODE = 'unique_violation';
  END IF;

  -- Gruppe, Land und Waehrung wie die meisten in derselben Nachbarschaft.
  SELECT coalesce(p_gruppe, mode() WITHIN GROUP (ORDER BY coalesce(u."billingGroup", 'STANDARD'))),
         mode() WITHIN GROUP (ORDER BY u.country),
         mode() WITHIN GROUP (ORDER BY u.currency)
    INTO v_gruppe, v_land, v_waehrung
    FROM public.users u WHERE u."tenantId" = v_verein AND u."neighborhoodId" = p_nachbarschaft;
  v_gruppe := coalesce(v_gruppe, 'STANDARD');
  IF v_gruppe NOT IN ('STANDARD', 'KOSOVO', 'REDUCED') THEN
    RAISE EXCEPTION 'Unbekannte Beitragsgruppe.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.users (id, "tenantId", role, "membershipStatus", "firstName", "lastName",
         "displayName", phone, street, zip, city, country, currency, "neighborhoodId", "billingGroup",
         "joinedAt", "profileComplete", "invoiceDeliveryMethod", "internalNotes")
  VALUES (v_id, v_verein, 'MEMBER', 'PENDING', btrim(p_vorname), btrim(p_nachname),
          btrim(p_vorname) || ' ' || btrim(p_nachname), nullif(btrim(p_telefon), ''),
          btrim(p_strasse), nullif(btrim(p_plz), ''), btrim(p_ort), v_land, v_waehrung,
          p_nachbarschaft, v_gruppe, now(), true, 'POST',
          'Vor Ort erfasst von ' || coalesce((SELECT coalesce(u."displayName", u."firstName")
                                                FROM public.users u WHERE u.id = public.current_user_row_id()), 'Vertreter')
          || ' am ' || to_char(now(), 'DD.MM.YYYY'));
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_mitglied_anlegen(text, text, text, text, text, text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_mitglied_anlegen(text, text, text, text, text, text, text, text) TO authenticated;

-- ------------------------------------------------------------ Aufgaben
CREATE OR REPLACE FUNCTION public.vertreter_aufgaben()
RETURNS SETOF public.tasks
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id();
BEGIN
  IF NOT public.vertreter_darf('AUFGABEN') THEN
    RAISE EXCEPTION 'Aufgaben sind fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY SELECT * FROM public.tasks t
   WHERE t."tenantId" = public.current_tenant()
     AND (t."createdBy" = v_ich OR coalesce(t."assignedTo", '[]'::jsonb) @> to_jsonb(v_ich))
   ORDER BY (t.status = 'DONE'), t."dueDate" NULLS LAST, t."createdAt" DESC;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_aufgaben() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_aufgaben() TO authenticated;

CREATE OR REPLACE FUNCTION public.vertreter_aufgabe_anlegen(
  p_titel text, p_beschreibung text DEFAULT NULL, p_prioritaet text DEFAULT 'MEDIUM', p_faellig date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id(); v_id text := 'vor-ort-' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  IF NOT public.vertreter_darf('AUFGABEN') THEN
    RAISE EXCEPTION 'Aufgaben sind fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_titel), '') = '' THEN
    RAISE EXCEPTION 'Was ist zu tun? Der Titel fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_prioritaet NOT IN ('LOW', 'MEDIUM', 'HIGH') THEN
    RAISE EXCEPTION 'Prioritaet LOW, MEDIUM oder HIGH.' USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO public.tasks (id, title, description, status, priority, "assignedTo", "assignedToName",
         "dueDate", "createdBy", "createdAt", "tenantId")
  VALUES (v_id, btrim(p_titel), nullif(btrim(p_beschreibung), ''), 'TODO', p_prioritaet,
          jsonb_build_array(v_ich),
          (SELECT coalesce(u."displayName", concat_ws(' ', u."firstName", u."lastName")) FROM public.users u WHERE u.id = v_ich),
          p_faellig::text, v_ich, now(), public.current_tenant());
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_aufgabe_anlegen(text, text, text, date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_aufgabe_anlegen(text, text, text, date) TO authenticated;

CREATE OR REPLACE FUNCTION public.vertreter_aufgabe_status(p_aufgabe text, p_status text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id();
BEGIN
  IF NOT public.vertreter_darf('AUFGABEN') THEN
    RAISE EXCEPTION 'Aufgaben sind fuer Sie nicht freigegeben.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_status NOT IN ('TODO', 'IN_PROGRESS', 'DONE') THEN
    RAISE EXCEPTION 'Unbekannter Status.' USING ERRCODE = 'check_violation';
  END IF;
  UPDATE public.tasks t SET status = p_status
   WHERE t.id = p_aufgabe AND t."tenantId" = public.current_tenant()
     AND (t."createdBy" = v_ich OR coalesce(t."assignedTo", '[]'::jsonb) @> to_jsonb(v_ich));
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Aufgabe ist nicht Ihnen zugewiesen.' USING ERRCODE = 'insufficient_privilege';
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_aufgabe_status(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_aufgabe_status(text, text) TO authenticated;

-- ------------------------------------------------------------ Pruefung durch den Vorstand
CREATE OR REPLACE FUNCTION public.vertreter_kassen_uebersicht()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT (public.is_member_manager() OR public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Nur fuer Vorstand und Administration.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'person', p.person,
      'name', (SELECT coalesce(u."displayName", concat_ws(' ', u."firstName", u."lastName")) FROM public.users u WHERE u.id = p.person),
      'bestand', (SELECT coalesce(jsonb_agg(to_jsonb(b)), '[]') FROM public._kasse_bestand(v_verein, p.person) b),
      'eintraege', (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.erfasst_am DESC), '[]') FROM (
          SELECT k.id, k.art, k.betrag, k.waehrung, k.notiz, k.beleg, k.erfasst_am, k.bestaetigt_am,
                 k.bestaetigt_von, k."expenseId",
                 (SELECT coalesce(u."displayName", concat_ws(' ', u."firstName", u."lastName")) FROM public.users u WHERE u.id = k.mitglied) AS mitglied_name
            FROM public.vertreter_kasse k
           WHERE k."tenantId" = v_verein AND k.person = p.person
           ORDER BY k.erfasst_am DESC LIMIT 100) x)
    ) ORDER BY p.person)
      FROM (SELECT DISTINCT k.person FROM public.vertreter_kasse k WHERE k."tenantId" = v_verein) p), '[]');
END $$;
REVOKE ALL ON FUNCTION public.vertreter_kassen_uebersicht() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_kassen_uebersicht() TO authenticated;

-- Eine Bankeinzahlung als angekommen bestaetigen und buchen (Bank an Kasse).
CREATE OR REPLACE FUNCTION public.vertreter_einzahlung_bestaetigen(p_kasse uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); k public.vertreter_kasse;
        v_kasse text; v_bank text;
BEGIN
  IF NOT (public.is_member_manager() OR public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Nur fuer Vorstand und Administration.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO k FROM public.vertreter_kasse x
   WHERE x.id = p_kasse AND x."tenantId" = v_verein AND x.art = 'BANKEINZAHLUNG' AND x.bestaetigt_am IS NULL;
  IF k.id IS NULL THEN
    RAISE EXCEPTION 'Keine offene Einzahlung.' USING ERRCODE = 'check_violation';
  END IF;
  IF k.person = public.current_user_row_id() THEN
    RAISE EXCEPTION 'Die eigene Einzahlung bestaetigt eine andere Person.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  UPDATE public.vertreter_kasse
     SET bestaetigt_am = now(), bestaetigt_von = coalesce(public.current_user_row_id(), auth.jwt() ->> 'email')
   WHERE id = k.id;

  v_kasse := public._konto_oder_null(v_verein, public._kassenkonto(k.waehrung));
  v_bank  := public._konto_oder_null(v_verein, '1020');
  IF v_kasse IS NOT NULL AND v_bank IS NOT NULL THEN
    INSERT INTO public.accounting_journal (id, "tenantId", date, description, "debitCode", "creditCode",
           amount, "referenceId", "isSystemEntry")
    VALUES (gen_random_uuid()::text, v_verein, current_date::text,
            'Bankeinzahlung Handkasse ' || coalesce((SELECT coalesce(u."displayName", u."firstName") FROM public.users u WHERE u.id = k.person), k.person),
            v_bank, v_kasse, k.betrag, k.id::text, true);
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_einzahlung_bestaetigen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_einzahlung_bestaetigen(uuid) TO authenticated;
