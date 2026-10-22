-- Rechnungen fuer den Verantwortlichen einer Nachbarschaft: sehen und
-- weiterleiten, beides nur mit Freigabe durch die Administration.
--
-- Gemessen am 22.10., bevor etwas geaendert wurde: payments_read liess
-- jeden Verantwortlichen die Rechnungen aller Mitglieder seiner
-- Nachbarschaften lesen -- in Koretini sechs Personen, zusammen 93
-- Rechnungen. Niemand hatte das je freigegeben; es folgte daraus, dass
-- jemand in einer Nachbarschaft als verantwortlich eingetragen wurde.
-- Weiterleiten konnte er nichts: die Warteschlange ist dem Vorstand
-- vorbehalten, und das bleibt so.
--
-- JE PERSON, nicht je Verein. Die Feldrechte (vertreter_felder) gelten
-- fuer alle Verantwortlichen gemeinsam, weil es dort um Datenpflege geht.
-- Rechnungen sind Geld und Vertrauen: dem einen Vertreter gibt man sie,
-- dem anderen nicht.
--
-- WER BISHER SAH, SIEHT WEITER. Die heutigen Verantwortlichen bekommen
-- "sehen" eingetragen, damit am Morgen niemandem etwas fehlt; die
-- Administration nimmt es weg, wo sie es nicht will. "Weiterleiten" ist
-- neu und steht bei allen auf aus. Wer neu verantwortlich wird, hat
-- beides nicht, bis es jemand setzt.
--
-- WEITERLEITEN heisst: die Rechnung geht an die E-Mail-Adresse, die beim
-- Mitglied hinterlegt ist -- bestimmt hier, nicht im Browser. Wer eine
-- eigene Adresse mitgeben koennte, koennte Rechnungen eines Mitglieds an
-- beliebige Dritte schicken.

SET statement_timeout = '300s';

-- ------------------------------------------------- Vorher festhalten
CREATE TEMP TABLE _vorher(ids text[], person text);

DO $vorher$
DECLARE v_eigen text := current_user; v_uid text; a text[]; v_person text;
BEGIN
  -- Ein Vertreter, der sich anmelden kann.
  SELECT u."authUserId", u.id INTO v_uid, v_person
    FROM public.neighborhoods n
    JOIN public.users u ON u."tenantId" = n."tenantId"
     AND (u.id = n."representativeId" OR u.id = n."managerId"
          OR coalesce(n."contactPersonIds",'[]'::jsonb) @> to_jsonb(u.id))
   WHERE n."tenantId" = 'koretini' AND u."authUserId" IS NOT NULL
     AND coalesce(u.role,'MEMBER') NOT IN ('SUPER_ADMIN','ADMIN','BOARD','TREASURER')
   ORDER BY u.id LIMIT 1;
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Kein anmeldbarer Vertreter fuer den Test gefunden.'; END IF;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO a FROM public.payments;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  INSERT INTO _vorher VALUES (a, v_person);
  RAISE NOTICE 'vorher: Vertreter % sieht % Rechnungen', v_person, coalesce(array_length(a,1),0);
END $vorher$;


-- ------------------------------------------------- Die Rechte
CREATE TABLE IF NOT EXISTS public.vertreter_rechte (
  "tenantId"         text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  person             text NOT NULL,
  rechnungen_sehen   boolean NOT NULL DEFAULT false,
  rechnungen_senden  boolean NOT NULL DEFAULT false,
  "geaendertVon"     text,
  "geaendertAm"      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("tenantId", person),
  -- Weiterleiten, was man nicht sehen darf, ergaebe keinen Sinn.
  CONSTRAINT senden_braucht_sehen CHECK (NOT rechnungen_senden OR rechnungen_sehen)
);
-- Keine Regel fuer direkten Zugriff: gelesen und geschrieben wird nur
-- ueber die Funktionen unten, die ihre Pruefung in sich tragen.
ALTER TABLE public.vertreter_rechte ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vertreter_rechte FROM anon, authenticated;

COMMENT ON TABLE public.vertreter_rechte IS
  'Was ein Nachbarschafts-Verantwortlicher mit Rechnungen darf. Je Person; '
  'gesetzt nur durch die Vereinsadministration (vertreter_rechte_setzen).';

-- Wer bisher sah, sieht weiter.
INSERT INTO public.vertreter_rechte ("tenantId", person, rechnungen_sehen, "geaendertVon")
SELECT DISTINCT n."tenantId", u.id, true, 'migration 20261106'
  FROM public.neighborhoods n
  CROSS JOIN LATERAL (
    SELECT n."representativeId" AS p
    UNION SELECT n."managerId"
    UNION SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb))
  ) x
  JOIN public.users u ON u.id = x.p AND u."tenantId" = n."tenantId"
ON CONFLICT DO NOTHING;


CREATE OR REPLACE FUNCTION public.vertreter_darf(p_recht text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.vertreter_rechte r
     WHERE r."tenantId" = public.current_tenant()
       AND r.person = public.current_user_row_id()
       AND CASE p_recht WHEN 'SEHEN'  THEN r.rechnungen_sehen
                        WHEN 'SENDEN' THEN r.rechnungen_senden
                        ELSE false END);
$$;
REVOKE ALL ON FUNCTION public.vertreter_darf(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_darf(text) TO authenticated;


-- Was darf ich? Fuer die Betreuungsmaske.
CREATE OR REPLACE FUNCTION public.meine_vertreter_rechte()
RETURNS TABLE (sehen boolean, senden boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.vertreter_darf('SEHEN'), public.vertreter_darf('SENDEN');
$$;
REVOKE ALL ON FUNCTION public.meine_vertreter_rechte() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.meine_vertreter_rechte() TO authenticated;


-- Die Uebersicht fuer die Administration.
CREATE OR REPLACE FUNCTION public.vertreter_rechte_stand()
RETURNS TABLE (person text, sehen boolean, senden boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT r.person, r.rechnungen_sehen, r.rechnungen_senden
    FROM public.vertreter_rechte r
   WHERE r."tenantId" = public.current_tenant()
     AND (public.is_member_manager() OR public.is_platform_admin());
$$;
REVOKE ALL ON FUNCTION public.vertreter_rechte_stand() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechte_stand() TO authenticated;


CREATE OR REPLACE FUNCTION public.vertreter_rechte_setzen(
  p_person text, p_sehen boolean, p_senden boolean)
RETURNS TABLE (sehen boolean, senden boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  -- Dieselbe Schwelle wie bei den Feldrechten.
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration bestimmt die Rechte der Verantwortlichen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  -- Nur wer in diesem Verein wirklich eine Nachbarschaft betreut. Sonst
  -- laege ein Recht bereit, das wirkt, sobald jemand eingetragen wird --
  -- ohne dass es dann noch jemand sieht.
  IF NOT EXISTS (
    SELECT 1 FROM public.neighborhoods n
     WHERE n."tenantId" = v_verein
       AND (n."representativeId" = p_person OR n."managerId" = p_person
            OR coalesce(n."contactPersonIds",'[]'::jsonb) @> to_jsonb(p_person))) THEN
    RAISE EXCEPTION 'Diese Person betreut keine Nachbarschaft des Vereins.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Weiterleiten schliesst Sehen ein; Sehen wegnehmen nimmt auch das
  -- Weiterleiten.
  p_senden := coalesce(p_senden, false);
  p_sehen  := coalesce(p_sehen, false) OR p_senden;

  INSERT INTO public.vertreter_rechte AS r
         ("tenantId", person, rechnungen_sehen, rechnungen_senden, "geaendertVon", "geaendertAm")
  VALUES (v_verein, p_person, p_sehen, p_senden, public.current_user_row_id(), now())
  ON CONFLICT ("tenantId", person) DO UPDATE
     SET rechnungen_sehen = EXCLUDED.rechnungen_sehen,
         rechnungen_senden = EXCLUDED.rechnungen_senden,
         "geaendertVon" = EXCLUDED."geaendertVon",
         "geaendertAm" = now();

  RETURN QUERY SELECT p_sehen, p_senden;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_rechte_setzen(text, boolean, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechte_setzen(text, boolean, boolean) TO authenticated;


-- ------------------------------------------------- payments_read
-- Wie bisher, nur haengt der Vertreter-Zweig jetzt an der Freigabe.
-- Seine eigenen Rechnungen sieht jeder weiterhin ueber den zweiten Zweig.
DROP POLICY IF EXISTS payments_read ON public.payments;
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
USING (
  ((SELECT public.is_member_manager()) AND "tenantId" = (SELECT public.current_tenant()))
  OR "userId" = (SELECT public.current_user_row_id())
  OR ((SELECT public.is_neighborhood_steward())
      AND (SELECT public.vertreter_darf('SEHEN'))
      AND "tenantId" = (SELECT public.current_tenant())
      AND "userId" IN (SELECT public.vertreter_mitglieder()))
);


-- ------------------------------------------------- Rechnung abrufen
--
-- Was der Vertreter braucht, um die Rechnung zu bauen: die Rechnung, die
-- Anschrift des Mitglieds und die Zahlungsverbindung des Vereins. Die
-- Einstellungen selbst bleiben dem Vorstand vorbehalten -- hier kommen nur
-- die Angaben heraus, die ohnehin auf jeder Rechnung stehen.
CREATE OR REPLACE FUNCTION public.vertreter_rechnung_daten(p_payment text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); p public.payments; m public.users;
        z jsonb; b jsonb;
BEGIN
  IF NOT public.vertreter_darf('SEHEN') THEN
    RAISE EXCEPTION 'Die Rechnungen sind fuer Sie nicht freigegeben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO p FROM public.payments
   WHERE id = p_payment AND "tenantId" = v_verein
     AND "userId" IN (SELECT public.vertreter_mitglieder());
  IF p.id IS NULL THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO m FROM public.users WHERE id = p."userId";
  SELECT s.payment INTO z FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'payment';
  SELECT s.branding INTO b FROM public.settings s WHERE s."tenantId" = v_verein AND s.id = 'branding';

  RETURN jsonb_build_object(
    'payment', jsonb_build_object(
       'id', p.id, 'invoiceNumber', p."invoiceNumber", 'description', p.description,
       'amount', p.amount, 'currency', p.currency, 'dueDate', p."dueDate",
       'reference', p.reference, 'billingYear', p."billingYear", 'status', p.status,
       'issuedAt', p."timestamp"),
    'mitglied', jsonb_build_object(
       'name', coalesce(m."displayName", concat_ws(' ', m."firstName", m."lastName")),
       'email', m.email, 'adresse', coalesce(nullif(btrim(m.street),''), m.address), 'plz', m.zip, 'ort', m.city, 'land', m.country),
    'zahlung', jsonb_build_object(
       'accountHolder', z->>'accountHolder', 'iban', z->>'iban', 'qrIban', z->>'qrIban',
       'bic', z->>'bic', 'bankName', z->>'bankName',
       'street', z->>'street', 'zip', z->>'zip', 'city', z->>'city', 'country', z->>'country',
       'twintNumber', z->>'twintNumber', 'twintUrl', z->>'twintUrl',
       'paypalEmail', z->>'paypalEmail'),
    'verein', coalesce(b->'associationName'->>'de', b->>'associationName',
                       z->>'accountHolder',
                       (SELECT t.name FROM public.tenants t WHERE t.id = v_verein)));
END $$;
REVOKE ALL ON FUNCTION public.vertreter_rechnung_daten(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechnung_daten(text) TO authenticated;


-- ------------------------------------------------- Rechnung weiterleiten
ALTER TABLE public.mail_queue ADD COLUMN IF NOT EXISTS "paymentId" text;

CREATE OR REPLACE FUNCTION public.vertreter_rechnung_senden(
  p_payment text, p_betreff text, p_html text, p_anhaenge jsonb DEFAULT '[]'::jsonb)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_ich text := public.current_user_row_id();
        p public.payments; m public.users; v_von text; v_kopf text;
BEGIN
  IF NOT public.vertreter_darf('SENDEN') THEN
    RAISE EXCEPTION 'Das Weiterleiten von Rechnungen ist fuer Sie nicht freigegeben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO p FROM public.payments
   WHERE id = p_payment AND "tenantId" = v_verein
     AND "userId" IN (SELECT public.vertreter_mitglieder());
  IF p.id IS NULL THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p.status = 'PAID' THEN
    RAISE EXCEPTION 'Diese Rechnung ist bereits bezahlt.' USING ERRCODE = 'check_violation';
  END IF;

  -- Der Empfaenger kommt aus der Datenbank, nie aus dem Aufruf.
  SELECT * INTO m FROM public.users WHERE id = p."userId";
  IF coalesce(btrim(m.email), '') !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'Beim Mitglied ist keine brauchbare E-Mail-Adresse hinterlegt.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Groessen: eine Rechnungsmail mit einem PDF, nicht mehr.
  IF length(coalesce(p_html,'')) > 300000 OR coalesce(btrim(p_html),'') = '' THEN
    RAISE EXCEPTION 'Der Mailtext fehlt oder ist zu gross.' USING ERRCODE = 'check_violation';
  END IF;
  IF jsonb_typeof(coalesce(p_anhaenge,'[]'::jsonb)) <> 'array'
     OR jsonb_array_length(coalesce(p_anhaenge,'[]'::jsonb)) > 1
     OR length(coalesce(p_anhaenge,'[]'::jsonb)::text) > 4000000 THEN
    RAISE EXCEPTION 'Erlaubt ist ein Anhang bis etwa 3 MB.' USING ERRCODE = 'check_violation';
  END IF;

  -- Einmal je Rechnung und Tag. Ein Doppelklick oder eine Ungeduld soll
  -- beim Mitglied nicht als drei gleiche Rechnungen ankommen.
  IF EXISTS (SELECT 1 FROM public.mail_queue q
              WHERE q."tenantId" = v_verein AND q."paymentId" = p.id
                AND q.kind = 'RECHNUNG_VERTRETER'
                AND q."createdAt" > now() - interval '24 hours') THEN
    RAISE EXCEPTION 'Diese Rechnung wurde in den letzten 24 Stunden schon weitergeleitet.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Das Mitglied soll sehen, wer ihm die Rechnung geschickt hat. Der Text
  -- kommt aus dem Browser des Vertreters; diese Zeile nicht.
  SELECT coalesce(u."displayName", concat_ws(' ', u."firstName", u."lastName"))
    INTO v_von FROM public.users u WHERE u.id = v_ich;
  v_kopf := '<p style="font-family:Arial,sans-serif;font-size:12px;color:#666;'
         || 'border-bottom:1px solid #eee;padding-bottom:8px;margin-bottom:16px">'
         || 'Weitergeleitet von '
         || replace(replace(replace(coalesce(v_von,'Ihrer Nachbarschaft'),'&','&amp;'),'<','&lt;'),'>','&gt;')
         || ', verantwortlich f&uuml;r Ihre Nachbarschaft.</p>';

  INSERT INTO public.mail_queue
         ("tenantId", recipient, subject, html, text, attachments, kind,
          "memberId", "refYear", "paymentId", status, "scheduledFor")
  VALUES (v_verein, btrim(m.email), left(coalesce(nullif(btrim(p_betreff),''),
            'Rechnung ' || coalesce(p."invoiceNumber",'')), 200),
          v_kopf || p_html,
          regexp_replace(v_kopf || p_html, '<[^>]*>', '', 'g'),
          coalesce(p_anhaenge,'[]'::jsonb), 'RECHNUNG_VERTRETER',
          m.id, p."billingYear", p.id, 'PENDING', now());

  RETURN btrim(m.email);
END $$;
REVOKE ALL ON FUNCTION public.vertreter_rechnung_senden(text, text, text, jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_rechnung_senden(text, text, text, jsonb) TO authenticated;


-- ------------------------------------------------- Selbsttest
DO $test$
DECLARE v_eigen text := current_user; v_uid text; v_person text; v_vorher text[];
        a text[]; eigen text[]; v_offen text; v_bezahlt text; v_ok boolean; v_an text;
BEGIN
  SELECT ids, person INTO v_vorher, v_person FROM _vorher;
  SELECT "authUserId" INTO v_uid FROM public.users WHERE id = v_person;

  -- 1. Mit der uebernommenen Freigabe: genau dieselben Rechnungen wie vorher.
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO a FROM public.payments;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF a IS DISTINCT FROM v_vorher THEN
    RAISE EXCEPTION 'Mit Freigabe sieht der Vertreter andere Rechnungen als vorher (% statt %).',
      coalesce(array_length(a,1),0), coalesce(array_length(v_vorher,1),0);
  END IF;

  -- 2. Ohne Freigabe: nur noch die eigenen.
  UPDATE public.vertreter_rechte SET rechnungen_sehen = false, rechnungen_senden = false
   WHERE person = v_person;
  SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO eigen
    FROM public.payments WHERE "userId" = v_person;
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO a FROM public.payments;
  BEGIN
    PERFORM public.vertreter_rechnung_daten(v_vorher[1]);
    v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF a IS DISTINCT FROM eigen THEN
    RAISE EXCEPTION 'Ohne Freigabe sieht der Vertreter noch % Rechnungen statt seiner %.',
      coalesce(array_length(a,1),0), coalesce(array_length(eigen,1),0);
  END IF;
  IF NOT v_ok THEN RAISE EXCEPTION 'Rechnungsdaten waren ohne Freigabe abrufbar.'; END IF;

  -- 3. Sehen ja, Senden nein: Weiterleiten wird abgewiesen.
  UPDATE public.vertreter_rechte SET rechnungen_sehen = true WHERE person = v_person;
  SELECT p.id INTO v_offen FROM public.payments p
    JOIN public.users m ON m.id = p."userId"
   WHERE p.id = ANY (v_vorher) AND p."userId" <> v_person
     AND coalesce(p.status,'') <> 'PAID'
     AND coalesce(btrim(m.email),'') ~ '@' LIMIT 1;
  SELECT p.id INTO v_bezahlt FROM public.payments p
   WHERE p.id = ANY (v_vorher) AND p."userId" <> v_person AND p.status = 'PAID' LIMIT 1;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.vertreter_rechnung_senden(v_offen, 'Test', '<p>Test</p>');
    v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT v_ok THEN RAISE EXCEPTION 'Weiterleiten ging ohne Freigabe.'; END IF;

  -- 4. Mit Freigabe: der Empfaenger ist die Adresse des Mitglieds, eine
  --    bezahlte Rechnung wird abgewiesen, ein zweites Mal ebenso. Die
  --    Testzeile wird danach entfernt; sie ist nie sichtbar geworden,
  --    weil alles in dieser Transaktion liegt.
  UPDATE public.vertreter_rechte SET rechnungen_senden = true WHERE person = v_person;
  IF v_offen IS NOT NULL THEN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
    v_an := public.vertreter_rechnung_senden(v_offen, 'Test', '<p>Test</p>');
    BEGIN
      PERFORM public.vertreter_rechnung_senden(v_offen, 'Test', '<p>Test</p>');
      v_ok := false;
    EXCEPTION WHEN check_violation THEN v_ok := true;
    END;
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF NOT v_ok THEN RAISE EXCEPTION 'Dieselbe Rechnung liess sich zweimal am Tag weiterleiten.'; END IF;
    IF v_an IS DISTINCT FROM (SELECT btrim(m.email) FROM public.payments p
                                JOIN public.users m ON m.id = p."userId" WHERE p.id = v_offen) THEN
      RAISE EXCEPTION 'Empfaenger ist nicht die Adresse des Mitglieds.';
    END IF;
    DELETE FROM public.mail_queue WHERE "paymentId" = v_offen AND kind = 'RECHNUNG_VERTRETER';
  ELSE
    RAISE NOTICE 'Keine offene Rechnung mit Adresse beim Testvertreter -- Versand nicht geprueft.';
  END IF;

  IF v_bezahlt IS NOT NULL THEN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
    BEGIN
      PERFORM public.vertreter_rechnung_senden(v_bezahlt, 'Test', '<p>Test</p>');
      v_ok := false;
    EXCEPTION WHEN check_violation THEN v_ok := true;
    END;
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF NOT v_ok THEN RAISE EXCEPTION 'Eine bezahlte Rechnung liess sich weiterleiten.'; END IF;
  END IF;

  -- 5. Ein Vertreter darf sich die Rechte nicht selbst geben.
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.vertreter_rechte_setzen(v_person, true, true);
    v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT v_ok THEN RAISE EXCEPTION 'Ein Vertreter konnte sich selbst Rechte geben.'; END IF;

  -- Zurueck auf den uebernommenen Stand: sehen ja, weiterleiten nein.
  UPDATE public.vertreter_rechte SET rechnungen_senden = false, rechnungen_sehen = true
   WHERE person = v_person;

  RAISE NOTICE 'Vertreterrechte stehen: mit Freigabe % Rechnungen wie vorher, ohne nur die eigenen %, Versand an %.',
    coalesce(array_length(v_vorher,1),0), coalesce(array_length(eigen,1),0), coalesce(v_an,'(nicht geprueft)');
END $test$;

DROP TABLE _vorher;
