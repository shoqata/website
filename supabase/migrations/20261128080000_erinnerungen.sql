-- Erinnerungen per E-Mail. Je Verein einzeln einzuschalten, ab Werk aus:
-- es sind Mails an echte Mitglieder, die soll niemand ungefragt bekommen.
--
--   faelligkeit  Mitglied: "Ihre Rechnung ist in N Tagen faellig" (einmal je Rechnung)
--   vorstand     Verwaltung/Vorstand: neue Anmeldungen und gemeldete Aenderungen
--                (taeglich, nur wenn etwas Neues da ist; offene Anmeldungen
--                hoechstens alle drei Tage)
--   vertreter    Vertreter: montags, wer in der Nachbarschaft noch offen ist

CREATE TABLE IF NOT EXISTS public.erinnerung_einstellung (
  "tenantId"   text PRIMARY KEY,
  faelligkeit  boolean NOT NULL DEFAULT false,
  tage_vorher  integer NOT NULL DEFAULT 7 CHECK (tage_vorher BETWEEN 1 AND 60),
  vorstand     boolean NOT NULL DEFAULT false,
  vertreter    boolean NOT NULL DEFAULT false,
  geaendert_am timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.erinnerung_einstellung ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.erinnerung_einstellung FROM anon, authenticated, public;

CREATE OR REPLACE FUNCTION public.erinnerung_einstellung_lesen()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE WHEN public.is_member_manager() THEN coalesce(
    (SELECT to_jsonb(e) - 'tenantId' FROM public.erinnerung_einstellung e WHERE e."tenantId" = public.current_tenant()),
    '{"faelligkeit":false,"tage_vorher":7,"vorstand":false,"vertreter":false}'::jsonb) END;
$$;

CREATE OR REPLACE FUNCTION public.erinnerung_einstellung_setzen(p_faelligkeit boolean, p_tage integer, p_vorstand boolean, p_vertreter boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Erinnerungen stellt die Vereinsadministration ein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  INSERT INTO public.erinnerung_einstellung ("tenantId", faelligkeit, tage_vorher, vorstand, vertreter)
  VALUES (public.current_tenant(), p_faelligkeit, greatest(1, least(60, coalesce(p_tage, 7))), p_vorstand, p_vertreter)
  ON CONFLICT ("tenantId") DO UPDATE SET faelligkeit = EXCLUDED.faelligkeit, tage_vorher = EXCLUDED.tage_vorher,
    vorstand = EXCLUDED.vorstand, vertreter = EXCLUDED.vertreter, geaendert_am = now();
END $$;

REVOKE ALL ON FUNCTION public.erinnerung_einstellung_lesen() FROM public, anon;
REVOKE ALL ON FUNCTION public.erinnerung_einstellung_setzen(boolean, integer, boolean, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.erinnerung_einstellung_lesen() TO authenticated;
GRANT EXECUTE ON FUNCTION public.erinnerung_einstellung_setzen(boolean, integer, boolean, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public._mail_ok(p text) RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT p ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' AND p NOT ILIKE '%.legacy';
$$;

CREATE OR REPLACE FUNCTION public.erinnerungen_einreihen(p_tag date DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tag date := coalesce(p_tag, (now() AT TIME ZONE 'Europe/Zurich')::date);
  e record; r record; v_n integer := 0; v_name text; v_neu int; v_meld int; v_html text; v_liste text;
BEGIN
  FOR e IN SELECT * FROM public.erinnerung_einstellung WHERE faelligkeit OR vorstand OR vertreter LOOP
    SELECT coalesce(t.name, 'Ihr Verein') INTO v_name FROM public.tenants t WHERE t.id = e."tenantId";

    -- 1. Faelligkeit, einmal je Rechnung.
    IF e.faelligkeit THEN
      FOR r IN
        SELECT p.id, p.amount, p.currency, p."invoiceNumber", left(p."dueDate", 10) AS faellig, u.id AS uid, u.email, u."displayName"
          FROM public.payments p JOIN public.users u ON u.id = p."userId"
         WHERE p."tenantId" = e."tenantId" AND p.status = 'PENDING'
           AND left(p."dueDate", 10) = to_char(v_tag + e.tage_vorher, 'YYYY-MM-DD')
           AND coalesce(u."membershipStatus", '') <> 'INACTIVE' AND public._mail_ok(u.email)
           AND NOT EXISTS (SELECT 1 FROM public.mail_queue q WHERE q."paymentId" = p.id AND q.kind = 'ERINNERUNG_FAELLIG')
      LOOP
        INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, text, kind, "memberId", "paymentId", status)
        VALUES (e."tenantId", r.email, 'Erinnerung: Rechnung ' || coalesce(r."invoiceNumber", '') || ' ist bald fällig',
          '<p>Guten Tag ' || coalesce(r."displayName", '') || '</p><p>Ihre Rechnung <b>' || coalesce(r."invoiceNumber", '')
            || '</b> über <b>' || coalesce(r.currency, 'CHF') || ' ' || to_char(r.amount, 'FM999990.00') || '</b> ist am <b>'
            || to_char(r.faellig::date, 'DD.MM.YYYY') || '</b> fällig. Im Mitgliederbereich finden Sie die QR-Rechnung'
            || ' und können melden, wenn Sie schon bezahlt haben.</p><p>Herzlichen Dank<br>' || v_name || '</p>',
          'Ihre Rechnung ' || coalesce(r."invoiceNumber", '') || ' ist am ' || to_char(r.faellig::date, 'DD.MM.YYYY') || ' fällig.',
          'ERINNERUNG_FAELLIG', r.uid, r.id, 'PENDING');
        v_n := v_n + 1;
      END LOOP;
    END IF;

    -- 2. Verwaltung/Vorstand: Neues zum Bearbeiten.
    IF e.vorstand THEN
      SELECT count(*) INTO v_meld FROM public.mitglied_aenderungen a
       WHERE a."tenantId" = e."tenantId" AND a.status = 'OFFEN' AND a.erstellt_am >= v_tag - 1;
      SELECT count(*) INTO v_neu FROM public.users u WHERE u."tenantId" = e."tenantId" AND u."membershipStatus" = 'PENDING';
      IF v_meld > 0 OR (v_neu > 0 AND NOT EXISTS (SELECT 1 FROM public.mail_queue q WHERE q."tenantId" = e."tenantId"
                                                     AND q.kind = 'ERINNERUNG_VORSTAND' AND q."createdAt" >= v_tag - 3)) THEN
        v_html := '<p>Guten Tag</p><p>Im Vorstandsbereich von ' || v_name || ' wartet Arbeit:</p><ul>'
          || CASE WHEN v_neu > 0 THEN '<li><b>' || v_neu || '</b> neue Anmeldung(en) zum Aufnehmen</li>' ELSE '' END
          || CASE WHEN v_meld > 0 THEN '<li><b>' || v_meld || '</b> neu gemeldete Änderung(en) von Mitgliedern</li>' ELSE '' END
          || '</ul><p>Sie finden alles im Cockpit »Heute wichtig«.</p>';
        FOR r IN SELECT u.id, u.email FROM public.users u
                  WHERE u."tenantId" = e."tenantId" AND u.role IN ('ADMIN','BOARD','SUPER_ADMIN') AND public._mail_ok(u.email)
                    AND NOT EXISTS (SELECT 1 FROM public.mail_queue q WHERE q."memberId" = u.id AND q.kind = 'ERINNERUNG_VORSTAND'
                                      AND q."createdAt" >= v_tag::timestamptz)
        LOOP
          INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind, "memberId", status)
          VALUES (e."tenantId", r.email, v_name || ': Neues zum Bearbeiten', v_html, 'ERINNERUNG_VORSTAND', r.id, 'PENDING');
          v_n := v_n + 1;
        END LOOP;
      END IF;
    END IF;

    -- 3. Vertreter, montags: offene Beitraege in der eigenen Nachbarschaft.
    IF e.vertreter AND extract(isodow FROM v_tag) = 1 THEN
      FOR r IN
        SELECT s.id, s.email, string_agg(DISTINCT m."displayName", ', ' ORDER BY m."displayName") AS namen, count(DISTINCT m.id) AS anzahl
          FROM public.neighborhoods n
          JOIN public.users s ON s."tenantId" = n."tenantId"
                             AND (s.id = n."managerId" OR s.id = n."representativeId" OR n."contactPersonIds" ? s.id)
          JOIN public.users m ON m."neighborhoodId" = n.id AND coalesce(m."membershipStatus", '') <> 'INACTIVE'
          JOIN public.payments p ON p."userId" = m.id AND p.status = 'PENDING'
         WHERE n."tenantId" = e."tenantId" AND public._mail_ok(s.email)
           AND NOT EXISTS (SELECT 1 FROM public.mail_queue q WHERE q."memberId" = s.id AND q.kind = 'ERINNERUNG_VERTRETER'
                             AND q."createdAt" >= v_tag::timestamptz)
         GROUP BY s.id, s.email
      LOOP
        v_liste := left(r.namen, 1500);
        INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind, "memberId", status)
        VALUES (e."tenantId", r.email, v_name || ': ' || r.anzahl || ' offene Beiträge in Ihrer Nachbarschaft',
          '<p>Guten Tag</p><p>In Ihrer Nachbarschaft sind noch <b>' || r.anzahl || '</b> Beiträge offen: '
            || replace(replace(v_liste, '<', '&lt;'), '>', '&gt;') || '.</p><p>Im Vertreterbereich sehen Sie unter »Was ist zu tun« alle Details.</p>',
          'ERINNERUNG_VERTRETER', r.id, 'PENDING');
        v_n := v_n + 1;
      END LOOP;
    END IF;
  END LOOP;
  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.erinnerungen_einreihen(date) FROM public, anon, authenticated;

-- Taeglich um 07:20 (UTC 06:20/05:20).
DO $$ BEGIN
  PERFORM cron.unschedule('erinnerungen') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'erinnerungen');
  PERFORM cron.schedule('erinnerungen', '20 5 * * *', 'SELECT public.erinnerungen_einreihen()');
END $$;

-- Probe: ohne Einstellung entsteht nichts.
DO $$ DECLARE v int; BEGIN
  SELECT public.erinnerungen_einreihen() INTO v;
  IF v <> 0 THEN RAISE EXCEPTION 'Erinnerungen ohne Einstellung: %', v; END IF;
END $$;

NOTIFY pgrst, 'reload schema';
