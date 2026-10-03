-- Befristeter, widerrufbarer Lesezugang fuer die Revisionsstelle.
--
-- Sie bekommt einen Verweis und sieht damit die Buchhaltung und die
-- Ausgaben des vereinbarten Jahres -- nur lesend, bis zu einem Datum, und
-- jederzeit entziehbar. Kein Konto, kein Passwort, keine Rolle im System.
--
-- Zwei Entscheidungen, die den Entwurf bestimmen:
--
-- 1. Gespeichert wird NUR der Hash des Tokens, nie das Token selbst.
--    Haette jemand Lesezugriff auf die Datenbank, bekaeme er sonst mit den
--    Tokens zugleich die Finanzen aller Vereine. Das Token wird genau
--    einmal angezeigt -- beim Erstellen. Danach ist es nicht mehr
--    herstellbar, nur noch ersetzbar.
--
-- 2. Der Verein wird aus dem TOKEN abgeleitet, nicht aus der Sitzung. Die
--    Revisionsstelle ist nicht angemeldet; current_tenant() waere leer.
--    Eine Funktion, die den Verein als Parameter naehme, liesse sich
--    dagegen von aussen auf jeden Verein richten.

CREATE TABLE IF NOT EXISTS public.revisionszugaenge (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  bezeichnung   text NOT NULL,
  token_hash    text NOT NULL UNIQUE,
  jahr          int,                      -- NULL = alle Jahre
  gueltig_bis   date NOT NULL,
  erstellt_von  text,
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  widerrufen_am timestamptz,
  zuletzt_gesehen timestamptz,
  zugriffe      int NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS revisionszugaenge_verein
  ON public.revisionszugaenge ("tenantId", erstellt_am DESC);

ALTER TABLE public.revisionszugaenge ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS revisionszugaenge_lesen ON public.revisionszugaenge;
CREATE POLICY revisionszugaenge_lesen ON public.revisionszugaenge
  FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());
REVOKE ALL ON public.revisionszugaenge FROM authenticated, anon;
GRANT SELECT ON public.revisionszugaenge TO authenticated;


-- Den Bericht einmal bauen, zwei Wege hinein.
--
-- Vorher rechnete revisionsbericht() mit current_tenant(). Die
-- Revisionsstelle ist aber nicht angemeldet. Also wandert die Rechnung
-- hierher; wer sie aufruft, hat den Verein bereits nachgewiesen -- der
-- Vorstand ueber seine Sitzung, die Revisionsstelle ueber ihr Token.
-- Diese Funktion ist bewusst NICHT fuer anon oder authenticated
-- freigegeben; nur die beiden Wrapper rufen sie.
CREATE OR REPLACE FUNCTION public.revisionsbericht_fuer(p_verein text, p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ergebnis jsonb;
BEGIN
  WITH salden AS (
    SELECT a.code, a.name, a.class, a.category,
           coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
           coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
      FROM public.accounting_accounts a
      LEFT JOIN public.accounting_journal j
             ON j."tenantId" = a."tenantId"
            AND substr(j.date,1,4) = p_jahr::text
            AND (j."debitCode" = a.code OR j."creditCode" = a.code)
     WHERE a."tenantId" = p_verein
     GROUP BY a.code, a.name, a.class, a.category
  ), mit_saldo AS (
    SELECT *, CASE WHEN class IN ('ASSET','EXPENSE') THEN soll - haben
                   ELSE haben - soll END AS saldo FROM salden
  )
  SELECT jsonb_build_object(
    'verein',  (SELECT jsonb_build_object('id', t.id, 'name', t.name)
                  FROM public.tenants t WHERE t.id = p_verein),
    'jahr', p_jahr, 'erstellt', now(),
    'abschluss', (SELECT jsonb_build_object('status', f.status, 'geschlossen_am', f."closedAt",
                                            'ergebnis', f."netProfit")
                    FROM public.fiscal_years f
                   WHERE f."tenantId" = p_verein AND f.year = p_jahr),
    'saldenliste', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'konto', code, 'name', name, 'klasse', class, 'gruppe', category,
                      'soll', round(soll,2), 'haben', round(haben,2), 'saldo', round(saldo,2))
                      ORDER BY code), '[]'::jsonb) FROM mit_saldo),
    'bilanz', (SELECT jsonb_build_object(
                 'aktiven',  round(coalesce(sum(saldo) FILTER (WHERE class='ASSET'),0),2),
                 'passiven', round(coalesce(sum(saldo) FILTER (WHERE class='LIABILITY'),0),2))
                 FROM mit_saldo),
    'erfolgsrechnung', (SELECT jsonb_build_object(
                 'ertrag',  round(coalesce(sum(saldo) FILTER (WHERE class='REVENUE'),0),2),
                 'aufwand', round(coalesce(sum(saldo) FILTER (WHERE class='EXPENSE'),0),2),
                 'ergebnis', round(coalesce(sum(saldo) FILTER (WHERE class='REVENUE'),0)
                                 - coalesce(sum(saldo) FILTER (WHERE class='EXPENSE'),0),2))
                 FROM mit_saldo),
    'journal', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'beleg', j.belegnr, 'datum', j.date, 'text', j.description,
                  'soll', j."debitCode", 'haben', j."creditCode", 'betrag', round(j.amount,2),
                  'systembuchung', coalesce(j."isSystemEntry", false),
                  'erfasst_am', j."createdAt", 'bezug', j."referenceId")
                  ORDER BY j.belegnr), '[]'::jsonb)
                  FROM public.accounting_journal j
                 WHERE j."tenantId" = p_verein AND substr(j.date,1,4) = p_jahr::text),

    -- Die Ausgaben mit Belegverweis. Eine Revision prueft nicht nur, ob
    -- gebucht wurde, sondern ob ein Beleg dahintersteht.
    'ausgaben', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'datum', e.date, 'titel', e.title, 'lieferant', e.vendor,
                  'betrag', round(e.amount,2), 'waehrung', e.currency,
                  'kategorie', e.category, 'aufwandkonto', e."categoryAccountCode",
                  'zahlkonto', e."paymentAccountCode", 'status', e.status,
                  'bewilligt', e.approved, 'bezahlt', e.paid,
                  'verbucht', coalesce(e."bookedInJournal", false),
                  'beleg_vorhanden', (e."receiptUrl" IS NOT NULL AND e."receiptUrl" <> ''))
                  ORDER BY e.date), '[]'::jsonb)
                  FROM public.expenses e
                 WHERE e."tenantId" = p_verein AND substr(e.date,1,4) = p_jahr::text),

    'aenderungen', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'wann', b.wann, 'vorgang', b.vorgang, 'buchung', b.buchung_id,
                  'wer', coalesce(b.wer_email, b.wer, 'unbekannt'),
                  'vorher', b.vorher, 'nachher', b.nachher)
                  ORDER BY b.wann), '[]'::jsonb)
                  FROM public.buchungsprotokoll b
                 WHERE b."tenantId" = p_verein
                   AND (substr(b.vorher->>'date',1,4) = p_jahr::text
                     OR substr(b.nachher->>'date',1,4) = p_jahr::text)),
    'frueher_entfernt', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'entfernt_am', ar.entfernt_am, 'grund', ar.grund, 'zeile', ar.zeile)
                  ORDER BY ar.entfernt_am), '[]'::jsonb)
                  FROM public.accounting_journal_archiv ar
                 WHERE ar."tenantId" = p_verein
                   AND substr(ar.zeile->>'date',1,4) = p_jahr::text)
  ) INTO v_ergebnis;
  RETURN v_ergebnis;
END $$;
REVOKE ALL ON FUNCTION public.revisionsbericht_fuer(text,int) FROM public, anon, authenticated;

-- Weg 1: der Vorstand, ueber seine Sitzung.
CREATE OR REPLACE FUNCTION public.revisionsbericht(p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF public.current_tenant() IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf den Revisionsbericht abrufen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.revisionsbericht_fuer(public.current_tenant(), p_jahr);
END $$;
REVOKE ALL ON FUNCTION public.revisionsbericht(int) FROM public;
GRANT EXECUTE ON FUNCTION public.revisionsbericht(int) TO authenticated;


-- Einen Zugang ausstellen. Das Token wird hier erzeugt und GENAU EINMAL
-- zurueckgegeben; gespeichert wird nur sein Hash.
CREATE OR REPLACE FUNCTION public.revisionszugang_erstellen(
  p_bezeichnung text, p_gueltig_bis date, p_jahr int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_token text;
  v_id uuid;
BEGIN
  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf einen Revisionszugang ausstellen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_gueltig_bis IS NULL OR p_gueltig_bis <= current_date THEN
    RAISE EXCEPTION 'Das Ablaufdatum muss in der Zukunft liegen.';
  END IF;
  -- Ein Zugang ohne Ende ist kein befristeter Zugang. Ein Jahr ist die
  -- Obergrenze: eine Revision dauert Wochen, nicht Jahre.
  IF p_gueltig_bis > current_date + interval '1 year' THEN
    RAISE EXCEPTION 'Hoechstens ein Jahr Gueltigkeit.';
  END IF;
  IF coalesce(btrim(p_bezeichnung),'') = '' THEN
    RAISE EXCEPTION 'Bitte benennen, fuer wen der Zugang ist.';
  END IF;

  -- 32 zufaellige Bytes, als URL-tauglicher Text. Lang genug, dass Raten
  -- ausgeschlossen ist, kurz genug fuer einen Verweis in einer E-Mail.
  --
  -- gen_random_bytes und digest kommen aus pgcrypto, und das liegt bei
  -- Supabase im Schema "extensions". Deshalb steht es oben im search_path;
  -- ohne das fand die Funktion sie nicht.
  v_token := replace(replace(replace(
               encode(gen_random_bytes(32), 'base64'), '+','-'), '/','_'), '=','');

  INSERT INTO public.revisionszugaenge
    ("tenantId", bezeichnung, token_hash, jahr, gueltig_bis, erstellt_von)
  VALUES (v_verein, btrim(p_bezeichnung),
          encode(digest(v_token, 'sha256'), 'hex'),
          p_jahr, p_gueltig_bis,
          (SELECT u.email FROM public.users u
            WHERE u."authUserId" = nullif(current_setting('request.jwt.claims',true),'')::jsonb ->> 'sub'
            LIMIT 1))
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('id', v_id, 'token', v_token,
                            'gueltig_bis', p_gueltig_bis, 'jahr', p_jahr);
END $$;
REVOKE ALL ON FUNCTION public.revisionszugang_erstellen(text,date,int) FROM public;
GRANT EXECUTE ON FUNCTION public.revisionszugang_erstellen(text,date,int) TO authenticated;


CREATE OR REPLACE FUNCTION public.revisionszugang_widerrufen(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_zeilen int;
BEGIN
  IF public.current_tenant() IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf widerrufen.' USING ERRCODE='insufficient_privilege';
  END IF;
  UPDATE public.revisionszugaenge
     SET widerrufen_am = now()
   WHERE id = p_id AND "tenantId" = public.current_tenant() AND widerrufen_am IS NULL;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  -- Ein UPDATE, das null Zeilen trifft, wirft keinen Fehler. Ohne diese
  -- Pruefung meldete die Oberflaeche einen Widerruf, der nie stattfand.
  IF v_zeilen <> 1 THEN
    RAISE EXCEPTION 'Zugang nicht gefunden oder bereits widerrufen.';
  END IF;
  RETURN jsonb_build_object('widerrufen', true);
END $$;
REVOKE ALL ON FUNCTION public.revisionszugang_widerrufen(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.revisionszugang_widerrufen(uuid) TO authenticated;


-- Was die Revisionsstelle sieht. Ohne Anmeldung, allein ueber das Token.
CREATE OR REPLACE FUNCTION public.revisionsdaten(p_token text, p_jahr int)
RETURNS jsonb
-- extensions mit im Pfad: pgcrypto liegt bei Supabase dort, nicht in
-- public. Mit search_path = public allein fand die Funktion weder
-- gen_random_bytes noch digest -- und brach beim ersten echten Aufruf ab.
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  z public.revisionszugaenge%ROWTYPE;
BEGIN
  SELECT * INTO z FROM public.revisionszugaenge
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  -- Dieselbe Meldung fuer "gibt es nicht", "widerrufen" und "abgelaufen".
  -- Wer ein Token errät, soll nicht auch noch erfahren, ob es einmal
  -- gueltig war.
  IF z.id IS NULL OR z.widerrufen_am IS NOT NULL OR z.gueltig_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF z.jahr IS NOT NULL AND z.jahr <> p_jahr THEN
    RAISE EXCEPTION 'Dieser Zugang gilt nur fuer das Geschaeftsjahr %.', z.jahr
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Jeder Abruf wird vermerkt. Der Verein soll sehen koennen, ob und wann
  -- sein Zugang benutzt wurde.
  UPDATE public.revisionszugaenge
     SET zuletzt_gesehen = now(), zugriffe = zugriffe + 1
   WHERE id = z.id;

  RETURN public.revisionsbericht_fuer(z."tenantId", p_jahr)
         || jsonb_build_object('zugang', jsonb_build_object(
              'fuer', z.bezeichnung, 'gueltig_bis', z.gueltig_bis));
END $$;
REVOKE ALL ON FUNCTION public.revisionsdaten(text,int) FROM public;
GRANT EXECUTE ON FUNCTION public.revisionsdaten(text,int) TO anon, authenticated;
