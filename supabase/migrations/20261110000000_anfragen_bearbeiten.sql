-- Anfragen & Feedback: Bearbeitung durch den Vorstand.
--
-- Bisher hatte eine Anfrage nur einen Status, den man frei umstellen konnte,
-- und eine Notiz. Wer was entschieden hat, warum, und was als Naechstes zu
-- tun ist, stand nirgends. Jetzt:
--
--   OPEN         neu eingegangen
--   IN_PROGRESS  angenommen, jemand vom Vorstand ist zustaendig
--   WAITING      wartet -- worauf (Text) und bis wann (Datum)
--   APPROVED     genehmigt, mit Entscheid
--   REJECTED     abgelehnt, Begruendung ist Pflicht
--   DONE         erledigt
--
-- Jede Aktion laeuft ueber anfrage_aktion() und hinterlaesst einen Eintrag im
-- Verlauf (wer, wann, was). Der Verlauf und die naechsten Schritte sind
-- intern: das Mitglied liest seine Anfrage (Zeilenregel auf inquiries) und
-- sieht Status, Antwort und Entscheid -- aber keine Vorstandsnotizen. Darum
-- liegen die in eigenen Tabellen und nicht in der Anfrage selbst.

ALTER TABLE public.inquiries
  ADD COLUMN IF NOT EXISTS zustaendig   text,
  ADD COLUMN IF NOT EXISTS "wartenAuf"  text,
  ADD COLUMN IF NOT EXISTS "wartenBis"  date,
  ADD COLUMN IF NOT EXISTS entscheid    text,
  ADD COLUMN IF NOT EXISTS "entscheidVon" text,
  ADD COLUMN IF NOT EXISTS "entscheidAm"  timestamptz;

CREATE TABLE IF NOT EXISTS public.anfrage_verlauf (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId" text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  anfrage    text NOT NULL REFERENCES public.inquiries(id) ON DELETE CASCADE,
  art        text NOT NULL,          -- Aktion: ANNEHMEN, WARTEN, ..., NOTIZ, SCHRITT
  status     text,                   -- Status nach der Aktion
  text       text,
  von        text,                   -- users.id
  von_name   text,
  am         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anfrage_verlauf_anfrage ON public.anfrage_verlauf (anfrage, am);
ALTER TABLE public.anfrage_verlauf ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anfrage_verlauf_lesen ON public.anfrage_verlauf;
CREATE POLICY anfrage_verlauf_lesen ON public.anfrage_verlauf FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());
GRANT SELECT ON public.anfrage_verlauf TO authenticated;

CREATE TABLE IF NOT EXISTS public.anfrage_schritte (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  anfrage     text NOT NULL REFERENCES public.inquiries(id) ON DELETE CASCADE,
  text        text NOT NULL,
  zustaendig  text,                  -- users.id
  faellig     date,
  erledigt_am timestamptz,
  erstellt_am timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anfrage_schritte_anfrage ON public.anfrage_schritte (anfrage, erstellt_am);
ALTER TABLE public.anfrage_schritte ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anfrage_schritte_lesen ON public.anfrage_schritte;
CREATE POLICY anfrage_schritte_lesen ON public.anfrage_schritte FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());
GRANT SELECT ON public.anfrage_schritte TO authenticated;

-- Ein Mitglied legt seine Anfrage selbst an. Die Einfuegeregel erlaubt ihm
-- die eigene Zeile -- aber nicht, sie gleich als genehmigt anzulegen.
CREATE OR REPLACE FUNCTION public.anfrage_neu_bereinigen()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- email ist Pflicht, das Formular im Mitgliederbereich schickt sie aber
  -- nicht mit -- jede Anfrage von dort scheiterte. Sie kommt aus dem Profil.
  IF nullif(btrim(coalesce(NEW.email, '')), '') IS NULL THEN
    SELECT coalesce(u.email, '') INTO NEW.email FROM public.users u
     WHERE u.id = coalesce(NEW."userId", public.current_user_row_id());
    NEW.email := coalesce(NEW.email, '');
  END IF;
  IF NOT public.is_member_manager() THEN
    NEW.status := 'OPEN';
    NEW."adminNote" := NULL; NEW.zustaendig := NULL; NEW.entscheid := NULL;
    NEW."entscheidVon" := NULL; NEW."entscheidAm" := NULL;
    NEW."wartenAuf" := NULL; NEW."wartenBis" := NULL;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS inquiries_neu_bereinigen ON public.inquiries;
CREATE TRIGGER inquiries_neu_bereinigen BEFORE INSERT ON public.inquiries
  FOR EACH ROW EXECUTE FUNCTION public.anfrage_neu_bereinigen();

-- Gemeinsame Pruefung: Vorstand dieses Vereins, darf schreiben, Anfrage gehoert
-- dem Verein. Gibt die Anfrage zurueck.
CREATE OR REPLACE FUNCTION public.anfrage_pruefen(p_id text)
RETURNS public.inquiries
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE r public.inquiries;
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration bearbeitet Anfragen.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO r FROM public.inquiries i WHERE i.id = p_id AND i."tenantId" = public.current_tenant();
  IF NOT FOUND THEN RAISE EXCEPTION 'Anfrage nicht gefunden.'; END IF;
  RETURN r;
END $$;
REVOKE ALL ON FUNCTION public.anfrage_pruefen(text) FROM public;

CREATE OR REPLACE FUNCTION public.anfrage_protokoll(p_anfrage text, p_art text, p_status text, p_text text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  INSERT INTO public.anfrage_verlauf ("tenantId", anfrage, art, status, text, von, von_name)
  SELECT public.current_tenant(), p_anfrage, p_art, p_status, nullif(btrim(p_text), ''), u.id,
         coalesce(nullif(btrim(u."displayName"), ''), btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",'')))
    FROM (SELECT public.current_user_row_id() AS id) me
    LEFT JOIN public.users u ON u.id = me.id;
$$;
REVOKE ALL ON FUNCTION public.anfrage_protokoll(text, text, text, text) FROM public;

-- p_aktion: ANNEHMEN | WARTEN | GENEHMIGEN | ABLEHNEN | ERLEDIGT | WIEDER_OEFFNEN
--           | ANTWORT (Antwort an das Mitglied) | NOTIZ (nur intern)
--           | ZUSTAENDIG (p_text = users.id, leer = niemand)
CREATE OR REPLACE FUNCTION public.anfrage_aktion(p_id text, p_aktion text, p_text text DEFAULT NULL, p_bis date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r      public.inquiries;
  v_ich  text := public.current_user_row_id();
  v_text text := nullif(btrim(coalesce(p_text, '')), '');
  v_akt  text := upper(coalesce(p_aktion, ''));
  v_neu  text;
  v_log  text := v_text;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  r := public.anfrage_pruefen(p_id);
  v_neu := r.status;

  CASE v_akt
  WHEN 'ANNEHMEN' THEN
    v_neu := 'IN_PROGRESS';
    UPDATE public.inquiries SET status = v_neu, zustaendig = coalesce(zustaendig, v_ich),
           "wartenAuf" = NULL, "wartenBis" = NULL WHERE id = r.id;
  WHEN 'WARTEN' THEN
    IF v_text IS NULL THEN RAISE EXCEPTION 'Bitte angeben, worauf gewartet wird.'; END IF;
    v_neu := 'WAITING';
    UPDATE public.inquiries SET status = v_neu, "wartenAuf" = v_text, "wartenBis" = p_bis,
           zustaendig = coalesce(zustaendig, v_ich) WHERE id = r.id;
    IF p_bis IS NOT NULL THEN v_log := v_text || ' (bis ' || to_char(p_bis, 'DD.MM.YYYY') || ')'; END IF;
  WHEN 'GENEHMIGEN', 'ABLEHNEN' THEN
    IF v_akt = 'ABLEHNEN' AND v_text IS NULL THEN RAISE EXCEPTION 'Eine Ablehnung braucht eine Begründung.'; END IF;
    v_neu := CASE v_akt WHEN 'GENEHMIGEN' THEN 'APPROVED' ELSE 'REJECTED' END;
    UPDATE public.inquiries SET status = v_neu, entscheid = v_text, "entscheidVon" = v_ich, "entscheidAm" = now(),
           "wartenAuf" = NULL, "wartenBis" = NULL, zustaendig = coalesce(zustaendig, v_ich) WHERE id = r.id;
  WHEN 'ERLEDIGT' THEN
    v_neu := 'DONE';
    UPDATE public.inquiries SET status = v_neu, "wartenAuf" = NULL, "wartenBis" = NULL WHERE id = r.id;
  WHEN 'WIEDER_OEFFNEN' THEN
    v_neu := 'IN_PROGRESS';
    UPDATE public.inquiries SET status = v_neu WHERE id = r.id;
  WHEN 'ANTWORT' THEN
    UPDATE public.inquiries SET "adminNote" = v_text WHERE id = r.id;
  WHEN 'NOTIZ' THEN
    IF v_text IS NULL THEN RAISE EXCEPTION 'Die Notiz ist leer.'; END IF;
  WHEN 'ZUSTAENDIG' THEN
    IF v_text IS NOT NULL AND NOT EXISTS (
         SELECT 1 FROM public.users u WHERE u.id = v_text AND u."tenantId" = r."tenantId"
            AND u.role IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')) THEN
      RAISE EXCEPTION 'Zuständig kann nur jemand aus Vorstand oder Administration sein.';
    END IF;
    UPDATE public.inquiries SET zustaendig = v_text WHERE id = r.id;
    SELECT coalesce(nullif(btrim(u."displayName"), ''), u.id) INTO v_log FROM public.users u WHERE u.id = v_text;
  ELSE
    RAISE EXCEPTION 'Unbekannte Aktion: %', p_aktion;
  END CASE;

  UPDATE public.inquiries SET "updatedAt" = now() WHERE id = r.id;
  PERFORM public.anfrage_protokoll(r.id, v_akt, v_neu, v_log);
  RETURN jsonb_build_object('status', v_neu);
END $$;
REVOKE ALL ON FUNCTION public.anfrage_aktion(text, text, text, date) FROM public;
GRANT EXECUTE ON FUNCTION public.anfrage_aktion(text, text, text, date) TO authenticated;

-- Naechste Schritte: anlegen, abhaken (und wieder oeffnen), loeschen.
CREATE OR REPLACE FUNCTION public.anfrage_schritt(
  p_anfrage text, p_text text, p_zustaendig text DEFAULT NULL, p_faellig date DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r public.inquiries; v_id uuid;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  r := public.anfrage_pruefen(p_anfrage);
  IF nullif(btrim(coalesce(p_text, '')), '') IS NULL THEN RAISE EXCEPTION 'Der Schritt ist leer.'; END IF;
  IF p_zustaendig IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.users u WHERE u.id = p_zustaendig AND u."tenantId" = r."tenantId"
          AND u.role IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')) THEN
    RAISE EXCEPTION 'Zuständig kann nur jemand aus Vorstand oder Administration sein.';
  END IF;
  INSERT INTO public.anfrage_schritte ("tenantId", anfrage, text, zustaendig, faellig)
  VALUES (r."tenantId", r.id, btrim(p_text), p_zustaendig, p_faellig) RETURNING id INTO v_id;
  UPDATE public.inquiries SET "updatedAt" = now() WHERE id = r.id;
  PERFORM public.anfrage_protokoll(r.id, 'SCHRITT', r.status, btrim(p_text));
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.anfrage_schritt(text, text, text, date) FROM public;
GRANT EXECUTE ON FUNCTION public.anfrage_schritt(text, text, text, date) TO authenticated;

-- p_aktion: ERLEDIGT | OFFEN | LOESCHEN
CREATE OR REPLACE FUNCTION public.anfrage_schritt_setzen(p_schritt uuid, p_aktion text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.anfrage_schritte; r public.inquiries;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO s FROM public.anfrage_schritte x WHERE x.id = p_schritt AND x."tenantId" = public.current_tenant();
  IF NOT FOUND THEN RAISE EXCEPTION 'Schritt nicht gefunden.'; END IF;
  r := public.anfrage_pruefen(s.anfrage);
  CASE upper(p_aktion)
  WHEN 'ERLEDIGT' THEN
    UPDATE public.anfrage_schritte SET erledigt_am = now() WHERE id = s.id;
    PERFORM public.anfrage_protokoll(r.id, 'SCHRITT_ERLEDIGT', r.status, s.text);
  WHEN 'OFFEN' THEN
    UPDATE public.anfrage_schritte SET erledigt_am = NULL WHERE id = s.id;
  WHEN 'LOESCHEN' THEN
    DELETE FROM public.anfrage_schritte WHERE id = s.id;
  ELSE
    RAISE EXCEPTION 'Unbekannte Aktion: %', p_aktion;
  END CASE;
  UPDATE public.inquiries SET "updatedAt" = now() WHERE id = r.id;
END $$;
REVOKE ALL ON FUNCTION public.anfrage_schritt_setzen(uuid, text) FROM public;
GRANT EXECUTE ON FUNCTION public.anfrage_schritt_setzen(uuid, text) TO authenticated;

-- Selbsttest im Demoverein, alles zurueckgerollt.
DO $$
DECLARE
  v_eigen text := current_user;
  v_board text; v_mitglied text; v_schritt uuid; r jsonb; n int; v_ok boolean;
BEGIN
  SELECT "authUserId" INTO v_board FROM public.users WHERE id = 'demo-u02';
  SELECT "authUserId" INTO v_mitglied FROM public.users WHERE id = 'demo-u05';
  IF v_board IS NULL OR NOT EXISTS (SELECT 1 FROM public.inquiries WHERE id = 'demo-q1') THEN
    RAISE NOTICE 'Selbsttest uebersprungen (keine Demodaten).'; RETURN;
  END IF;

  BEGIN
    -- Vorstand: annehmen, Schritt, warten, ablehnen ohne Grund (Fehler), genehmigen.
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_board, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    PERFORM public.anfrage_aktion('demo-q1', 'ANNEHMEN');
    v_schritt := public.anfrage_schritt('demo-q1', 'Adresse im Register prüfen', 'demo-u02', current_date + 7);
    PERFORM public.anfrage_aktion('demo-q1', 'WARTEN', 'Bestätigung der Gemeinde', current_date + 14);
    v_ok := false;
    BEGIN PERFORM public.anfrage_aktion('demo-q1', 'ABLEHNEN', '  ');
    EXCEPTION WHEN others THEN v_ok := true; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'Selbsttest: Ablehnung ohne Begründung ging durch'; END IF;
    PERFORM public.anfrage_schritt_setzen(v_schritt, 'ERLEDIGT');
    r := public.anfrage_aktion('demo-q1', 'GENEHMIGEN', 'Adresse übernommen.');
    SELECT count(*) INTO n FROM public.anfrage_verlauf WHERE anfrage = 'demo-q1';
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF r ->> 'status' <> 'APPROVED' OR n < 5 THEN
      RAISE EXCEPTION 'Selbsttest: Ablauf stimmt nicht: % / % Verlaufseintraege', r, n;
    END IF;
    IF (SELECT "entscheidVon" FROM public.inquiries WHERE id = 'demo-q1') <> 'demo-u02' THEN
      RAISE EXCEPTION 'Selbsttest: Entscheid ohne Urheber';
    END IF;

    -- Mitglied: kein Verlauf, keine Schritte, keine Aktion, kein genehmigtes Einfuegen.
    IF v_mitglied IS NOT NULL THEN
      PERFORM set_config('request.jwt.claims', json_build_object('sub', v_mitglied, 'role', 'authenticated')::text, true);
      SET LOCAL ROLE authenticated;
      SELECT count(*) INTO n FROM public.anfrage_verlauf;
      SELECT n + count(*) INTO n FROM public.anfrage_schritte;
      v_ok := false;
      BEGIN PERFORM public.anfrage_aktion('demo-q2', 'GENEHMIGEN', 'selbst');
      EXCEPTION WHEN insufficient_privilege THEN v_ok := true; END;
      INSERT INTO public.inquiries (id, "userId", "userName", type, subject, message, status, entscheid)
      VALUES ('selbsttest-q', 'demo-u05', 'Test', 'GENERAL', 'Test', 'Test', 'APPROVED', 'selbst');
      EXECUTE format('SET LOCAL ROLE %I', v_eigen);
      IF n > 0 OR NOT v_ok THEN RAISE EXCEPTION 'Selbsttest: Mitglied sieht Internes (%) oder darf entscheiden (%)', n, v_ok; END IF;
      IF (SELECT status || coalesce(entscheid, '') FROM public.inquiries WHERE id = 'selbsttest-q') <> 'OPEN' THEN
        RAISE EXCEPTION 'Selbsttest: Mitglied legt Anfrage als genehmigt an';
      END IF;
    END IF;

    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
END $$;
