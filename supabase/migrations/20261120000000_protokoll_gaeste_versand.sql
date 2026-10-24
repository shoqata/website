-- Vorstandsprotokoll: Protokollfuehrer, Gaeste, Versand als PDF.
--
-- Gaeste stehen mit Namen im Protokoll (attendees, wie die Vorstands-
-- mitglieder). Ihre E-Mail-Adresse aber NICHT: ein freigegebenes
-- Protokoll lesen alle Mitglieder (board_meetings_published_read), und
-- die Adresse eines Gastes geht sie nichts an. Sie liegt darum in einer
-- eigenen Tabelle, die nur der Vorstand liest.

ALTER TABLE public.board_meetings ADD COLUMN IF NOT EXISTS protokollfuehrer jsonb;

CREATE TABLE IF NOT EXISTS public.board_meeting_guests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "meetingId" text NOT NULL REFERENCES public.board_meetings(id) ON DELETE CASCADE,
  vorname     text NOT NULL,
  nachname    text NOT NULL DEFAULT '',
  email       text,
  erstellt_am timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS board_meeting_guests_meeting ON public.board_meeting_guests ("meetingId");
ALTER TABLE public.board_meeting_guests ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS board_meeting_guests_set_tenant ON public.board_meeting_guests;
CREATE TRIGGER board_meeting_guests_set_tenant BEFORE INSERT ON public.board_meeting_guests
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_on_insert();

DROP POLICY IF EXISTS board_meeting_guests_staff ON public.board_meeting_guests;
CREATE POLICY board_meeting_guests_staff ON public.board_meeting_guests FOR ALL TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
  WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant()
              AND EXISTS (SELECT 1 FROM public.board_meetings m
                           WHERE m.id = "meetingId" AND m."tenantId" = public.current_tenant()));
-- Schreibentzug des Vorstands gilt auch hier.
DROP POLICY IF EXISTS schreibschranke_ins ON public.board_meeting_guests;
CREATE POLICY schreibschranke_ins ON public.board_meeting_guests AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (public.darf_schreiben());
DROP POLICY IF EXISTS schreibschranke_upd ON public.board_meeting_guests;
CREATE POLICY schreibschranke_upd ON public.board_meeting_guests AS RESTRICTIVE FOR UPDATE TO authenticated USING (public.darf_schreiben());
DROP POLICY IF EXISTS schreibschranke_del ON public.board_meeting_guests;
CREATE POLICY schreibschranke_del ON public.board_meeting_guests AS RESTRICTIVE FOR DELETE TO authenticated USING (public.darf_schreiben());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.board_meeting_guests TO authenticated;

-- Protokoll per E-Mail, mit dem PDF im Anhang.
--
-- Absender und Antwortadresse wie im Postausgang des Vorstands: aus der
-- Zeile des Aufrufers, nicht aus der Eingabe. Hoechstens 30 Empfaenger,
-- und alles zaehlt auf die Tagesgrenze. Im Demoverein simuliert der
-- Mailversand (send-mail-queue).
CREATE OR REPLACE FUNCTION public.protokoll_mail_einreihen(
  p_meeting text, p_an text[], p_betreff text, p_html text, p_pdf text, p_dateiname text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich text := public.current_user_row_id();
  v_an text[]; v_falsch text; v_antwort text; v_name text; v_vereinsname text;
  v_grenze jsonb; v_rest int; a text; n int := 0;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() OR v_verein IS NULL OR v_ich IS NULL THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung verschickt Protokolle.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.board_meetings m WHERE m.id = p_meeting AND m."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Protokoll nicht gefunden.';
  END IF;
  IF coalesce(btrim(p_betreff), '') = '' OR coalesce(btrim(p_pdf), '') = '' THEN
    RAISE EXCEPTION 'Betreff und PDF fehlen.' USING ERRCODE = 'check_violation';
  END IF;
  IF length(p_pdf) > 8000000 THEN
    RAISE EXCEPTION 'Das PDF ist zu gross.' USING ERRCODE = 'check_violation';
  END IF;

  SELECT array_agg(DISTINCT lower(btrim(x))) INTO v_an FROM unnest(coalesce(p_an, '{}')) x WHERE btrim(x) <> '';
  SELECT string_agg(x, ', ') INTO v_falsch FROM unnest(coalesce(v_an, '{}')) x
   WHERE x !~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$';
  IF v_falsch IS NOT NULL THEN RAISE EXCEPTION 'Keine gültige Adresse: %', v_falsch USING ERRCODE = 'check_violation'; END IF;
  IF coalesce(array_length(v_an, 1), 0) = 0 THEN RAISE EXCEPTION 'Es ist niemand ausgewählt.' USING ERRCODE = 'check_violation'; END IF;
  IF array_length(v_an, 1) > 30 THEN RAISE EXCEPTION 'Höchstens 30 Empfänger.' USING ERRCODE = 'check_violation'; END IF;

  v_grenze := public.mail_grenze_heute();
  v_rest := (v_grenze ->> 'rest')::int;
  IF array_length(v_an, 1) > v_rest THEN
    RAISE EXCEPTION 'Heute gehen nur noch % Nachrichten hinaus (Tagesgrenze).', v_rest USING ERRCODE = 'check_violation';
  END IF;

  SELECT a2.adresse INTO v_antwort FROM public.vorstand_adressen a2
   WHERE a2."tenantId" = v_verein AND a2."userId" = v_ich AND a2.aktiv AND a2.bestaetigt_am IS NOT NULL;
  SELECT coalesce(nullif(btrim(u."displayName"),''), btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         coalesce(v_antwort, u.email)
    INTO v_name, v_antwort FROM public.users u WHERE u.id = v_ich;
  SELECT t.name INTO v_vereinsname FROM public.tenants t WHERE t.id = v_verein;

  FOREACH a IN ARRAY v_an LOOP
    INSERT INTO public.mail_queue
      ("tenantId", recipient, subject, html, text, kind, antwort_an, absender_name, absender_id,
       status, "scheduledFor", attachments)
    VALUES (v_verein, a, p_betreff, coalesce(p_html, ''), regexp_replace(coalesce(p_html, ''), '<[^>]*>', '', 'g'),
            'VORSTAND', v_antwort,
            CASE WHEN coalesce(v_vereinsname,'') = '' THEN v_name ELSE v_name || ' · ' || v_vereinsname END,
            v_ich, 'PENDING', now(),
            jsonb_build_array(jsonb_build_object('filename', left(coalesce(nullif(btrim(p_dateiname), ''), 'protokoll.pdf'), 120),
                                                 'content', p_pdf)));
    n := n + 1;
  END LOOP;
  RETURN jsonb_build_object('eingereiht', n, 'antwort_an', v_antwort);
END $$;
REVOKE ALL ON FUNCTION public.protokoll_mail_einreihen(text, text[], text, text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.protokoll_mail_einreihen(text, text[], text, text, text, text) TO authenticated;

-- Selbsttest: Mitglied liest keine Gast-Adressen, Vorstand schon. Zurueckgerollt.
DO $$
DECLARE v_eigen text := current_user; v_board text; v_mitglied text; v_m text; n int; r jsonb;
BEGIN
  SELECT "authUserId" INTO v_board FROM public.users WHERE id = 'demo-u02';
  SELECT "authUserId" INTO v_mitglied FROM public.users WHERE id = 'demo-u05';
  SELECT id INTO v_m FROM public.board_meetings WHERE "tenantId" = 'demo' LIMIT 1;
  IF v_board IS NULL OR v_mitglied IS NULL OR v_m IS NULL THEN RETURN; END IF;
  BEGIN
    UPDATE public.board_meetings SET "publishedToMembers" = true WHERE id = v_m;
    INSERT INTO public.board_meeting_guests ("tenantId", "meetingId", vorname, nachname, email)
    VALUES ('demo', v_m, 'Gast', 'Test', 'gast@example.org');

    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_mitglied, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    SELECT count(*) INTO n FROM public.board_meeting_guests;
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF n <> 0 THEN RAISE EXCEPTION 'Selbsttest: Mitglied sieht Gast-Adressen'; END IF;

    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_board, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    SELECT count(*) INTO n FROM public.board_meeting_guests;
    r := public.protokoll_mail_einreihen(v_m, ARRAY['gast@example.org'], 'Protokoll Test', '<p>x</p>', 'JVBERi0=', 'p.pdf');
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    IF n < 1 OR (r ->> 'eingereiht')::int <> 1 THEN RAISE EXCEPTION 'Selbsttest: Vorstand % / Versand %', n, r; END IF;
    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
END $$;
