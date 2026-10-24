-- Kontaktformular auf der oeffentlichen Website.
--
-- Eine Nachricht wird eine Anfrage (inquiries, type KONTAKT) -- dieselbe
-- Liste, die der Vorstand schon bearbeitet, mit Status, Verlauf und
-- naechsten Schritten. Ein zweiter Posteingang waere ein zweiter Ort, an
-- dem etwas liegen bleibt.
--
-- Dazu eine Benachrichtigung an die Kontaktadresse des Vereins, mit der
-- Adresse des Absenders als Antwortadresse: "Antworten" im Mailprogramm
-- erreicht die Person direkt. Keine Bestaetigung an den Absender -- sonst
-- koennte jeder ueber das Formular Mails an beliebige Adressen ausloesen.
--
-- Gegen Skripte: ein unsichtbares Feld (Falle), eine Mindestzeit zwischen
-- Oeffnen und Senden und eine Obergrenze je Adresse und je Verein.

CREATE TABLE IF NOT EXISTS public.kontakt_einstellung (
  "tenantId"   text PRIMARY KEY REFERENCES public.tenants(id) ON DELETE CASCADE,
  aktiv        boolean NOT NULL DEFAULT true,
  empfaenger   text,
  geaendert_am timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kontakt_einstellung ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kontakt_einstellung FROM anon, authenticated, public;

-- Fuer die Website: ist das Formular offen? Die Empfaengeradresse geht
-- nicht hinaus.
CREATE OR REPLACE FUNCTION public.kontakt_offen()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce((SELECT k.aktiv FROM public.kontakt_einstellung k
                    WHERE k."tenantId" = coalesce(public.current_tenant(), public.request_tenant())), true)
     AND public.modul_aktiv('WEBSITE');
$$;
REVOKE ALL ON FUNCTION public.kontakt_offen() FROM public;
GRANT EXECUTE ON FUNCTION public.kontakt_offen() TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.kontakt_einstellung_lesen()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); k record; v_vorgabe text;
BEGIN
  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur fuer die Verwaltung.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO k FROM public.kontakt_einstellung WHERE "tenantId" = v_verein;
  SELECT t."contactEmail" INTO v_vorgabe FROM public.tenants t WHERE t.id = v_verein;
  RETURN jsonb_build_object('aktiv', coalesce(k.aktiv, true), 'empfaenger', k.empfaenger, 'vorgabe', v_vorgabe);
END $$;
REVOKE ALL ON FUNCTION public.kontakt_einstellung_lesen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.kontakt_einstellung_lesen() TO authenticated;

CREATE OR REPLACE FUNCTION public.kontakt_einstellung_setzen(p_aktiv boolean, p_empfaenger text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_e text := nullif(btrim(coalesce(p_empfaenger, '')), '');
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur fuer die Verwaltung.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_e IS NOT NULL AND v_e !~* '^[^@\s]+@[^@\s]+\.[a-z]{2,}$' THEN
    RAISE EXCEPTION 'Das ist keine E-Mail-Adresse.' USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO public.kontakt_einstellung ("tenantId", aktiv, empfaenger)
  VALUES (v_verein, coalesce(p_aktiv, true), v_e)
  ON CONFLICT ("tenantId") DO UPDATE SET aktiv = EXCLUDED.aktiv, empfaenger = EXCLUDED.empfaenger, geaendert_am = now();
END $$;
REVOKE ALL ON FUNCTION public.kontakt_einstellung_setzen(boolean, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.kontakt_einstellung_setzen(boolean, text) TO authenticated;


CREATE OR REPLACE FUNCTION public.kontakt_senden(
  p_name text, p_email text, p_telefon text, p_betreff text, p_nachricht text,
  p_falle text DEFAULT NULL, p_dauer_ms int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := coalesce(public.current_tenant(), public.request_tenant());
  v_name text := left(btrim(coalesce(p_name, '')), 120);
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_tel text := left(btrim(coalesce(p_telefon, '')), 40);
  v_betreff text := left(btrim(coalesce(p_betreff, '')), 200);
  v_text text := btrim(coalesce(p_nachricht, ''));
  v_an text; v_vereinsname text; v_id text := gen_random_uuid()::text;
  v_html text; v_esc text;
BEGIN
  IF v_verein IS NULL OR NOT public.kontakt_offen() THEN
    RAISE EXCEPTION 'Das Kontaktformular ist nicht verfuegbar.' USING ERRCODE = 'check_violation';
  END IF;
  -- Die Falle: Menschen sehen das Feld nicht. Wer es fuellt, ist ein
  -- Skript -- und bekommt dieselbe Antwort wie ein Mensch, damit es nicht
  -- lernt, woran es gescheitert ist.
  IF coalesce(btrim(p_falle), '') <> '' THEN
    RETURN jsonb_build_object('ok', true);
  END IF;
  IF p_dauer_ms IS NOT NULL AND p_dauer_ms < 3000 THEN
    RAISE EXCEPTION 'Das ging sehr schnell -- bitte senden Sie noch einmal.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_name = '' THEN RAISE EXCEPTION 'Bitte Ihren Namen angeben.' USING ERRCODE = 'check_violation'; END IF;
  IF v_email !~* '^[^@\s]+@[^@\s]+\.[a-z]{2,}$' THEN
    RAISE EXCEPTION 'Bitte eine gueltige E-Mail-Adresse angeben.' USING ERRCODE = 'check_violation';
  END IF;
  IF length(v_text) < 10 THEN RAISE EXCEPTION 'Die Nachricht ist zu kurz.' USING ERRCODE = 'check_violation'; END IF;
  IF length(v_text) > 5000 THEN RAISE EXCEPTION 'Die Nachricht ist zu lang (hoechstens 5000 Zeichen).' USING ERRCODE = 'check_violation'; END IF;

  IF (SELECT count(*) FROM public.inquiries i WHERE i.type = 'KONTAKT' AND lower(i.email) = v_email
        AND i."createdAt" > now() - interval '1 hour') >= 3
     OR (SELECT count(*) FROM public.inquiries i WHERE i.type = 'KONTAKT' AND i."tenantId" = v_verein
        AND i."createdAt" > now() - interval '1 hour') >= 30 THEN
    RAISE EXCEPTION 'Es sind gerade viele Nachrichten eingegangen. Bitte versuchen Sie es spaeter noch einmal.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.inquiries (id, "tenantId", subject, message, email, status, "createdAt",
                                "userId", "userName", type)
  VALUES (v_id, v_verein, coalesce(nullif(v_betreff, ''), 'Kontaktformular'),
          v_text || CASE WHEN v_tel <> '' THEN E'\n\nTelefon: ' || v_tel ELSE '' END,
          v_email, 'OPEN', now(), public.current_user_row_id(), v_name, 'KONTAKT');

  -- Benachrichtigung an den Verein.
  SELECT coalesce(k.empfaenger, t."contactEmail"), t.name INTO v_an, v_vereinsname
    FROM public.tenants t LEFT JOIN public.kontakt_einstellung k ON k."tenantId" = t.id
   WHERE t.id = v_verein;
  IF v_an IS NOT NULL AND v_an LIKE '%@%' THEN
    v_esc := replace(replace(replace(v_text, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    v_html := '<p style="margin:0 0 1em">Neue Nachricht über das Kontaktformular der Website.</p>'
      || '<p style="margin:0 0 1em"><b>Von:</b> ' || replace(replace(v_name, '<', '&lt;'), '>', '&gt;')
      || ' &lt;' || v_email || '&gt;'
      || CASE WHEN v_tel <> '' THEN '<br/><b>Telefon:</b> ' || replace(replace(v_tel, '<', '&lt;'), '>', '&gt;') ELSE '' END
      || CASE WHEN v_betreff <> '' THEN '<br/><b>Betreff:</b> ' || replace(replace(v_betreff, '<', '&lt;'), '>', '&gt;') ELSE '' END
      || '</p><p style="margin:0 0 1em;white-space:pre-line">' || replace(v_esc, E'\n', '<br/>') || '</p>'
      || '<p style="margin:1.5em 0 0;color:#777;font-size:12px">Mit „Antworten“ erreichen Sie die Person direkt. '
      || 'Die Nachricht steht auch in der Verwaltung unter Kommunikation → Anfragen.</p>';
    INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, text, kind, antwort_an)
    VALUES (v_verein, v_an,
            'Kontaktformular: ' || coalesce(nullif(v_betreff, ''), v_name),
            v_html,
            'Von: ' || v_name || ' <' || v_email || '>' || CASE WHEN v_tel <> '' THEN E'\nTelefon: ' || v_tel ELSE '' END
              || E'\n\n' || v_text,
            'KONTAKT', v_email);
  END IF;

  RETURN jsonb_build_object('ok', true);
END $$;
REVOKE ALL ON FUNCTION public.kontakt_senden(text, text, text, text, text, text, int) FROM public;
GRANT EXECUTE ON FUNCTION public.kontakt_senden(text, text, text, text, text, text, int) TO anon, authenticated;

-- Die Seite /kontakt gibt es jetzt: eine eigene Seite darf sie nicht verdecken.
CREATE OR REPLACE FUNCTION public.pfad_belegt(p_pfad text)
RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(btrim(coalesce(p_pfad,''))) = ANY (ARRAY[
    '', 'about', 'live', 'events', 'news', 'fussball', 'futsal', 'spenden',
    'videos', 'gdpr', 'privacy', 'login', 'register', 'dashboard', 'admin',
    'super-admin', 'nachbarschaft', 'setup-profile', 'revision', 'treffen',
    'vorstellen', 'heft', 'drucksachen', 'api', 'assets', 'static',
    'beitraege', 'chronik', 'kontakt']);
$$;

DO $$
BEGIN
  IF has_table_privilege('anon', 'public.kontakt_einstellung', 'SELECT') THEN
    RAISE EXCEPTION 'Selbsttest: Empfaengeradresse lesbar';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
