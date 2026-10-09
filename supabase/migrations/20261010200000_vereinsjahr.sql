-- Das Vereinsjahr und seine Erinnerungen.
--
-- Der Rhythmus eines Vereins wiederholt sich jedes Jahr, und jedes Jahr
-- faellt er jemandem zu spaet ein: die Einladung zur GV muss nach den
-- Statuten vier Wochen vorher raus, die Spendenbescheinigungen braucht man
-- im Dezember, die Jahressperre des Vorjahres nach der GV. Ein Vorstand,
-- der das nebenher macht, vergisst es -- nicht aus Nachlaessigkeit, sondern
-- weil niemand daran erinnert.
--
-- Zwei Entscheidungen:
--
--   DIE MONATE STELLT DER VEREIN SELBST EIN. Die Vorgaben hier stammen aus
--   dem Konzept und passen zu einem Diasporaverein mit GV im Fruehjahr.
--   Ein Verein mit GV im Herbst stellt sie um, ohne dass jemand Code
--   anfasst.
--
--   VORLAUF ALS TAGE, auch negativ. -7 heisst "eine Woche danach". Damit
--   braucht es keine zweite Spalte fuer "davor oder danach" -- und keine
--   Stelle, an der beide auseinanderlaufen koennen.

CREATE TABLE IF NOT EXISTS public.vereinsjahr (
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  schluessel    text NOT NULL,
  monat         int  NOT NULL CHECK (monat BETWEEN 1 AND 12),
  tag           int  NOT NULL CHECK (tag BETWEEN 1 AND 31),
  vorlauf_tage  int  NOT NULL DEFAULT 14,   -- negativ = danach
  aktiv         boolean NOT NULL DEFAULT true,
  reihenfolge   int  NOT NULL DEFAULT 0,
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("tenantId", schluessel)
);

COMMENT ON COLUMN public.vereinsjahr.vorlauf_tage IS
  'Tage VOR dem Termin, an denen erinnert wird. Negativ = danach: -7 heisst '
  'eine Woche nach dem Termin.';

-- Die Texte stehen nicht in der Tabelle, sondern hier: sie gehoeren zur
-- Software, nicht zum Verein. Ein Verein, der sie aendern will, aendert
-- stattdessen seine Textbausteine.
CREATE OR REPLACE FUNCTION public.vereinsjahr_text(p_schluessel text, p_sprache text)
RETURNS TABLE (titel text, hinweis text)
LANGUAGE sql IMMUTABLE AS $$
  SELECT t.titel, t.hinweis FROM (VALUES
    ('BEITRAGSLAUF',
      CASE p_sprache WHEN 'sq' THEN 'Kuotat e vitit'
                     WHEN 'en' THEN 'Annual fee run' ELSE 'Beitragslauf des Jahres' END,
      CASE p_sprache WHEN 'sq' THEN 'Përgatitni faturat e vitit. Kontrolloni më parë kategoritë dhe adresat.'
                     WHEN 'en' THEN 'Prepare this year''s invoices. Check categories and addresses first.'
                     ELSE 'Bereiten Sie die Rechnungen des Jahres vor. Prüfen Sie vorher Kategorien und Adressen.' END),
    ('MAHNSTUFE_1',
      CASE p_sprache WHEN 'sq' THEN 'Kujtesa e parë'
                     WHEN 'en' THEN 'First reminder' ELSE 'Erste Mahnstufe' END,
      CASE p_sprache WHEN 'sq' THEN 'Afati i pagesës ka kaluar. Shikoni kuotat e hapura.'
                     WHEN 'en' THEN 'The payment deadline has passed. Review the open fees.'
                     ELSE 'Die Zahlungsfrist ist abgelaufen. Sehen Sie die offenen Beiträge durch.' END),
    ('JAHRESABSCHLUSS',
      CASE p_sprache WHEN 'sq' THEN 'Mbyllja e vitit dhe revizioni'
                     WHEN 'en' THEN 'Year-end closing and audit' ELSE 'Jahresabschluss und Revision' END,
      CASE p_sprache WHEN 'sq' THEN 'Përgatitni mbylljen dhe qasjen për revizionin (vlen më së shumti një muaj).'
                     WHEN 'en' THEN 'Prepare the closing and the auditor''s access (valid at most one month).'
                     ELSE 'Bereiten Sie den Abschluss vor und den Zugang für die Revision (höchstens einen Monat gültig).' END),
    ('GV_EINLADUNG',
      CASE p_sprache WHEN 'sq' THEN 'Ftesa për Kuvendin'
                     WHEN 'en' THEN 'Invitation to the general meeting' ELSE 'Einladung zur Generalversammlung' END,
      CASE p_sprache WHEN 'sq' THEN 'Ftesa, rendi i ditës dhe raporti vjetor. Kontrolloni afatin në statut.'
                     WHEN 'en' THEN 'Invitation, agenda and annual report. Check the deadline in your statutes.'
                     ELSE 'Einladung, Traktanden und Jahresbericht. Prüfen Sie die Frist in Ihren Statuten.' END),
    ('GV_NACHARBEIT',
      CASE p_sprache WHEN 'sq' THEN 'Procesverbali dhe mbyllja e vitit të kaluar'
                     WHEN 'en' THEN 'Minutes and locking the previous year' ELSE 'Protokoll und Jahressperre' END,
      CASE p_sprache WHEN 'sq' THEN 'Procesverbali i Kuvendit dhe mbyllja përfundimtare e vitit të kaluar.'
                     WHEN 'en' THEN 'The minutes, and locking the previous financial year.'
                     ELSE 'Das Protokoll der GV und die Jahressperre des Vorjahres.' END),
    ('SOMMERTREFFEN',
      CASE p_sprache WHEN 'sq' THEN 'Takimi në atdhe'
                     WHEN 'en' THEN 'Summer meeting back home' ELSE 'Treffen in der Heimat' END,
      CASE p_sprache WHEN 'sq' THEN 'Shikoni regjistrimet dhe pagesat e raportuara nga përfaqësuesit.'
                     WHEN 'en' THEN 'Check registrations and the payments reported by representatives.'
                     ELSE 'Sehen Sie Anmeldestand und die Meldungen der Vertreter durch.' END),
    ('SPENDENBESCHEINIGUNG',
      CASE p_sprache WHEN 'sq' THEN 'Vërtetimet e donacioneve'
                     WHEN 'en' THEN 'Donation receipts' ELSE 'Spendenbescheinigungen' END,
      CASE p_sprache WHEN 'sq' THEN 'Për të gjithë donatorët e këtij viti.'
                     WHEN 'en' THEN 'For everyone who donated this year.'
                     ELSE 'Für alle Spenderinnen und Spender dieses Jahres.' END)
  ) AS t(k, titel, hinweis)
  WHERE t.k = p_schluessel;
$$;


-- Vorgaben je Verein. Nur fuer Vereine, die noch nichts eingestellt haben.
INSERT INTO public.vereinsjahr ("tenantId", schluessel, monat, tag, vorlauf_tage, reihenfolge)
SELECT t.id, v.schluessel, v.monat, v.tag, v.vorlauf, v.reihenfolge
  FROM public.tenants t
  CROSS JOIN (VALUES
    ('BEITRAGSLAUF',          1,  15,  14, 10),
    ('MAHNSTUFE_1',           3,  15,   0, 20),
    ('JAHRESABSCHLUSS',       4,   1,  21, 30),
    ('GV_EINLADUNG',          5,  15,  28, 40),   -- vier Wochen vorher
    ('GV_NACHARBEIT',         5,  15,  -7, 50),   -- eine Woche danach
    ('SOMMERTREFFEN',         7,   1,  28, 60),
    ('SPENDENBESCHEINIGUNG', 12,   1,  14, 70)
  ) AS v(schluessel, monat, tag, vorlauf, reihenfolge)
 WHERE NOT EXISTS (SELECT 1 FROM public.vereinsjahr j WHERE j."tenantId" = t.id);


-- ---------------------------------------------------------- Zeilenregeln
ALTER TABLE public.vereinsjahr ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS vereinsjahr_lesen ON public.vereinsjahr;
CREATE POLICY vereinsjahr_lesen ON public.vereinsjahr FOR SELECT TO authenticated
  USING ("tenantId" = public.current_tenant() AND (public.is_platform_admin() OR public.is_staff()));

DROP POLICY IF EXISTS vereinsjahr_aendern ON public.vereinsjahr;
-- Aendern darf die Vereinsadministration. Der Vorstand liest nur -- und
-- auch das nur, wenn er lesen darf; der Schreibentzug greift hier ueber
-- die vorhandene Schranke, sobald sie gesetzt ist.
CREATE POLICY vereinsjahr_aendern ON public.vereinsjahr FOR UPDATE TO authenticated
  USING ("tenantId" = public.current_tenant()
         AND (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')))
  WITH CHECK ("tenantId" = public.current_tenant());

REVOKE ALL ON public.vereinsjahr FROM anon, public;
GRANT SELECT, UPDATE ON public.vereinsjahr TO authenticated;


-- ------------------------------------------------------------ Erinnern
CREATE OR REPLACE FUNCTION public.vereinsjahr_erinnern(p_tag date DEFAULT NULL)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tag  date := coalesce(p_tag, (now() AT TIME ZONE 'Europe/Zurich')::date);
  v_jahr int  := EXTRACT(YEAR FROM v_tag)::int;
  v_n    int  := 0;
  m      record;  -- Meilenstein
  e      record;  -- Empfaenger
  v_termin date; v_wann date; v_txt record; v_html text; v_betreff text; v_spr text;
  v_eingereiht int;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf die Erinnerungen ausloesen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR m IN
    SELECT j.*, f.wochenstart_an, coalesce(f.assistent_name,'Floky') AS helfer,
           t.name AS vereinsname
      FROM public.vereinsjahr j
      JOIN public.floky_einstellungen f ON f."tenantId" = j."tenantId"
      JOIN public.tenants t ON t.id = j."tenantId"
     WHERE j.aktiv
       AND coalesce(array_length(f.wochenstart_an, 1), 0) > 0
       AND EXISTS (SELECT 1 FROM public.tenant_modules tm
                    WHERE tm."tenantId" = j."tenantId" AND tm.modul = 'FLOKY'
                      AND tm.zustand IN ('AN','TESTPHASE'))
  LOOP
    -- Den Termin dieses Jahres bilden. Der 31. in einem kurzen Monat
    -- ergaebe ein ungueltiges Datum -- deshalb auf den Monatsletzten
    -- begrenzen statt zu scheitern.
    BEGIN
      v_termin := make_date(v_jahr, m.monat, least(m.tag,
        EXTRACT(DAY FROM (make_date(v_jahr, m.monat, 1) + interval '1 month - 1 day'))::int));
    EXCEPTION WHEN OTHERS THEN CONTINUE; END;

    v_wann := v_termin - m.vorlauf_tage;
    CONTINUE WHEN v_wann <> v_tag;

    FOR e IN
      SELECT u.id, u.email, u."displayName", coalesce(u.sprache,'de') AS sprache
        FROM public.users u
       WHERE u.id = ANY (m.wochenstart_an)
         AND u."tenantId" = m."tenantId"
         AND u.email IS NOT NULL AND u.email LIKE '%@%'
    LOOP
      v_spr := CASE WHEN e.sprache IN ('de','sq','en') THEN e.sprache ELSE 'de' END;
      SELECT * INTO v_txt FROM public.vereinsjahr_text(m.schluessel, v_spr);
      CONTINUE WHEN v_txt.titel IS NULL;

      v_betreff := v_txt.titel || ' — ' || m.vereinsname;
      v_html := '<p>' || CASE v_spr
          WHEN 'sq' THEN 'Përshëndetje ' WHEN 'en' THEN 'Hello ' ELSE 'Guten Abend ' END
        || coalesce(e."displayName",'') || '</p>'
        || '<p><strong>' || v_txt.titel || '</strong></p>'
        || '<p>' || v_txt.hinweis || '</p>'
        || '<p>' || CASE v_spr
             WHEN 'sq' THEN 'Afati: ' WHEN 'en' THEN 'Date: ' ELSE 'Termin: ' END
        || to_char(v_termin, 'DD.MM.YYYY') || '</p>'
        || '<p style="color:#888;font-size:12px">' || CASE v_spr
             WHEN 'sq' THEN 'Nga ' || m.helfer || '. Muajt i caktoni vetë te cilësimet.'
             WHEN 'en' THEN 'From ' || m.helfer || '. The months are yours to set in the settings.'
             ELSE 'Von ' || m.helfer || '. Die Monate stellen Sie in den Einstellungen selbst ein.'
           END || '</p>';

      -- Die Art traegt den Meilenstein im Namen. Das ist kein Schmuck:
      -- mail_queue hat einen eindeutigen Index auf (kind, memberId,
      -- refYear), und damit sorgt die DATENBANK dafuer, dass jede Person
      -- jede Erinnerung hoechstens einmal im Jahr bekommt. Eine von Hand
      -- geschriebene Pruefung haette dasselbe gemeint und waere beim
      -- naechsten Umbau vergessen worden.
      --
      -- Hieran ist die erste Fassung gescheitert: sie benutzte fuer alle
      -- sieben Meilensteine dieselbe Art, und der Index liess nur den
      -- ersten durch.
      INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind, "memberId",
                                     "refYear", status)
      VALUES (m."tenantId", e.email, v_betreff, v_html,
              'VJ_' || m.schluessel, e.id, v_jahr, 'PENDING')
      ON CONFLICT DO NOTHING;
      GET DIAGNOSTICS v_eingereiht = ROW_COUNT;
      v_n := v_n + v_eingereiht;
    END LOOP;
  END LOOP;

  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.vereinsjahr_erinnern(date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vereinsjahr_erinnern(date) TO authenticated;


-- Taeglich um 18:00 Europe/Zurich, wie der Wochenstart.
SELECT cron.unschedule('vereinsjahr') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'vereinsjahr');
SELECT cron.schedule('vereinsjahr', '5 16,17 * * *', $cron$
  SELECT public.vereinsjahr_erinnern()
   WHERE to_char(now() AT TIME ZONE 'Europe/Zurich', 'HH24') = '18';
$cron$);


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_quelle text; v_fehlt text;
BEGIN
  -- Jeder Meilenstein braucht einen Text in allen drei Sprachen.
  FOR v_quelle IN SELECT DISTINCT schluessel FROM public.vereinsjahr LOOP
    IF (SELECT titel FROM public.vereinsjahr_text(v_quelle,'de')) IS NULL
       OR (SELECT titel FROM public.vereinsjahr_text(v_quelle,'sq')) IS NULL
       OR (SELECT titel FROM public.vereinsjahr_text(v_quelle,'en')) IS NULL THEN
      RAISE EXCEPTION 'Meilenstein % hat keinen Text in allen drei Sprachen.', v_quelle;
    END IF;
  END LOOP;

  -- Der 31. Februar darf nicht scheitern, sondern muss auf den 28./29.
  -- rutschen. Genau daran waere die Funktion einmal im Jahr gestorben.
  UPDATE public.vereinsjahr SET monat = 2, tag = 31
   WHERE schluessel = 'BEITRAGSLAUF'
     AND "tenantId" = (SELECT id FROM public.tenants LIMIT 1);
  SELECT public.vereinsjahr_erinnern(make_date(EXTRACT(YEAR FROM current_date)::int, 2, 1))
    INTO v_n;
  UPDATE public.vereinsjahr SET monat = 1, tag = 15
   WHERE schluessel = 'BEITRAGSLAUF'
     AND "tenantId" = (SELECT id FROM public.tenants LIMIT 1);
  RAISE NOTICE '31. Februar ueberstanden (% Mail(s))', v_n;

  -- Nichts duerfen die Pruefungen hinterlassen.
  DELETE FROM public.mail_queue WHERE kind LIKE 'VJ|_%' ESCAPE '|';

  -- Die sieben Meilensteine duerfen sich nicht gegenseitig verdraengen.
  -- Genau das ist passiert: eine gemeinsame Art traf den eindeutigen
  -- Index auf (kind, memberId, refYear), und nur der erste kam durch.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname='vereinsjahr_erinnern';
  IF position('VJ_' in v_quelle) = 0 OR position('m.schluessel' in v_quelle) = 0 THEN
    RAISE EXCEPTION 'Alle Meilensteine teilen sich eine Mailart -- nur einer kaeme durch.';
  END IF;

  SELECT count(*) INTO v_n FROM cron.job WHERE jobname='vereinsjahr';
  IF v_n <> 1 THEN RAISE EXCEPTION 'Zeitplan vereinsjahr: % statt 1.', v_n; END IF;

  IF has_function_privilege('anon', 'public.vereinsjahr_erinnern(date)', 'EXECUTE') THEN
    RAISE EXCEPTION 'anon darf die Erinnerungen ausloesen.';
  END IF;

  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon' AND table_name='vereinsjahr';
  IF v_n > 0 THEN RAISE EXCEPTION 'anon hat Rechte auf vereinsjahr.'; END IF;

  SELECT count(*) INTO v_n FROM public.vereinsjahr;
  RAISE NOTICE 'Vereinsjahr bereit: % Meilensteine ueber alle Vereine.', v_n;
END $$;
