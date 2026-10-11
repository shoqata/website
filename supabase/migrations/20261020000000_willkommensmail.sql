-- Die Willkommensmail.
--
-- Soll hinausgehen, wenn jemand neu dazukommt -- bei der Selbstanmeldung
-- und wenn Vorstand oder Administration jemanden erfassen.
--
-- Serverseitig und nicht in der Anwendung, aus drei Gruenden:
--
--   Bei der Selbstanmeldung ist der Aufrufer gerade erst angemeldet und
--   darf textbausteine nicht lesen und in mail_queue nichts schreiben.
--   Die Anwendung koennte den Brief also gar nicht bauen.
--
--   Eine Funktion mit festem Text kann nicht missbraucht werden, um
--   beliebige Post an beliebige Adressen zu schicken. Eine offene
--   Einreihfunktion koennte das.
--
--   Und sie laeuft an genau einer Stelle. Heute gibt es die Erfassung an
--   drei Stellen (Selbstanmeldung, Wizard, Adminbereich); drei Kopien
--   eines Briefs laufen auseinander, so wie es bei Rechnungsnummern und
--   Zustellwegen schon geschehen ist.
--
-- Eingereiht, nicht verschickt. Den Versand macht der Postausgang, mit
-- allem, was dort haengt: Microsoft ueber Brevo, der Rest ueber Postal,
-- Wiederholung mit Abstand.

-- ------------------------------------------------------- Der Text
--
-- Zweisprachig, Albanisch zuerst -- so wie es im Konzept steht und wie
-- es die uebrigen Bausteine halten. Wer beim Mitglied keine Sprache
-- hinterlegt hat, bekommt beide; eine geratene Sprache ist schlechter
-- als zwei richtige.
INSERT INTO public.textbausteine ("tenantId", schluessel, sprache, betreff, text, aktiv)
SELECT t.id, 'WILLKOMMEN', s.sprache, s.betreff, s.text, true
  FROM public.tenants t
  CROSS JOIN (VALUES
    ('sq',
     'Mirë se vini në {{verein}}',
     E'Përshëndetje {{name}},\n\n'
     || E'Mirë se vini në {{verein}}. Regjistrimi juaj është kryer.\n\n'
     || E'Në faqen tonë mund të shikoni të dhënat e tuaja, kontributin e tij '
     || E'vjetor dhe ngjarjet e ardhshme. Nëse ndryshon adresa ose numri i '
     || E'telefonit, mund ta korrigjoni vetë — ose të lajmëroni përgjegjësin '
     || E'e lagjes tuaj.\n\n'
     || E'Nëse ndonjë e dhënë nuk është e saktë, shkruani thjesht si '
     || E'përgjigje e kësaj poste.\n\n'
     || E'Me respekt\n{{verein}}'),
    ('de',
     'Willkommen bei {{verein}}',
     E'Guten Tag {{name}}\n\n'
     || E'Willkommen bei {{verein}}. Ihre Aufnahme ist erfasst.\n\n'
     || E'Auf unserer Seite sehen Sie Ihre Angaben, Ihren Jahresbeitrag und '
     || E'die nächsten Anlässe. Ändert sich Ihre Adresse oder Telefonnummer, '
     || E'können Sie das selbst berichtigen — oder Sie melden es der '
     || E'verantwortlichen Person Ihrer Nachbarschaft.\n\n'
     || E'Stimmt eine Angabe nicht, antworten Sie einfach auf diese Nachricht.\n\n'
     || E'Freundliche Grüsse\n{{verein}}')
  ) AS s(sprache, betreff, text)
 WHERE NOT EXISTS (
   SELECT 1 FROM public.textbausteine b
    WHERE b."tenantId" = t.id AND b.schluessel = 'WILLKOMMEN' AND b.sprache = s.sprache);


-- ------------------------------------------------- Einreihen
CREATE OR REPLACE FUNCTION public.willkommen_einreihen(p_member text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  m record;
  v_verein text;
  v_sprachen text[];
  v_s text;
  v_betreff text := '';
  v_text text := '';
  v_html text := '';
  v_b record;
  v_jahr int := extract(year from (now() AT TIME ZONE 'Europe/Zurich'))::int;
  v_id uuid;
BEGIN
  SELECT u.* INTO m FROM public.users u WHERE u.id = p_member;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  -- Wer darf: das Mitglied selbst (Selbstanmeldung), die Vereinsleitung
  -- (Wizard und Adminbereich), der Betreiber. Sonst niemand -- sonst
  -- koennte jedes angemeldete Konto Post an jedes Mitglied ausloesen.
  IF NOT (
       public.is_platform_admin()
    OR (m."tenantId" = public.current_tenant() AND public.is_member_manager())
    OR p_member = public.current_user_row_id()
  ) THEN
    RAISE EXCEPTION 'Nicht berechtigt, diese Nachricht auszuloesen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ohne brauchbare Adresse kein Brief, und zwar ohne Fehler: beim
  -- Erfassen eines Mitglieds ohne E-Mail soll die Erfassung nicht
  -- scheitern. Gemessen haben 241 von 348 Rechnungen keinen Mailweg --
  -- der Fall ist hier die Regel, nicht die Ausnahme.
  IF m.email IS NULL OR btrim(m.email) = ''
     OR m.email LIKE '%@koretini.legacy' THEN
    RETURN jsonb_build_object('eingereiht', false, 'grund', 'keine brauchbare E-Mail-Adresse');
  END IF;

  SELECT t.name INTO v_verein FROM public.tenants t WHERE t.id = m."tenantId";

  -- Sprache des Mitglieds, sonst beide -- Albanisch zuerst.
  v_sprachen := CASE
    WHEN lower(coalesce(m.sprache,'')) IN ('de','sq','en') THEN ARRAY[lower(m.sprache)]
    ELSE ARRAY['sq','de'] END;

  FOREACH v_s IN ARRAY v_sprachen LOOP
    SELECT b.betreff, b.text INTO v_b
      FROM public.textbausteine b
     WHERE b."tenantId" = m."tenantId" AND b.schluessel = 'WILLKOMMEN'
       AND b.sprache = v_s AND b.aktiv IS NOT FALSE;
    IF NOT FOUND THEN CONTINUE; END IF;

    v_betreff := CASE WHEN v_betreff = '' THEN replace(v_b.betreff, '{{verein}}', coalesce(v_verein,''))
                      ELSE v_betreff || ' · ' || replace(v_b.betreff, '{{verein}}', coalesce(v_verein,'')) END;
    v_text := CASE WHEN v_text = '' THEN '' ELSE v_text || E'\n\n— — —\n\n' END
      || replace(replace(v_b.text, '{{name}}', coalesce(m."displayName", '')),
                 '{{verein}}', coalesce(v_verein, ''));
  END LOOP;

  IF v_text = '' THEN
    -- Kein Baustein, kein erfundener Brief. Lieber nichts als ein Text,
    -- den der Verein nie gelesen hat.
    RETURN jsonb_build_object('eingereiht', false, 'grund', 'kein Textbaustein WILLKOMMEN');
  END IF;

  -- Absaetze zu HTML, mit Schutz der Sonderzeichen. Der Text kommt aus
  -- einem Textfeld, nicht aus einem Editor -- ihn als HTML zu behandeln
  -- hiesse, dem Verein versehentlich Markup unterzuschieben.
  SELECT string_agg('<p style="margin:0 0 1em">' ||
           replace(replace(replace(replace(abs, '&','&amp;'), '<','&lt;'), '>','&gt;'),
                   E'\n', '<br/>') || '</p>', '')
    INTO v_html
    FROM regexp_split_to_table(v_text, E'\n{2,}') AS abs;

  -- kind/memberId/refYear sind eindeutig. Ein zweiter Aufruf fuer
  -- dasselbe Mitglied im selben Jahr legt keine zweite Nachricht an --
  -- und loest auch keinen Fehler aus, denn der Aufrufer hat nichts
  -- falsch gemacht.
  INSERT INTO public.mail_queue
    ("tenantId", recipient, subject, html, text, kind, "memberId", "refYear", status)
  VALUES (m."tenantId", btrim(m.email), v_betreff, v_html, v_text,
          'WILLKOMMEN', p_member, v_jahr, 'PENDING')
  -- Der Index ist PARTIELL (WHERE memberId IS NOT NULL AND refYear IS
  -- NOT NULL), darum muss ON CONFLICT dieselbe Bedingung nennen -- sonst
  -- findet PostgreSQL ihn nicht. Der Selbsttest hat das gemeldet, bevor
  -- die Funktion in Gebrauch war.
  ON CONFLICT (kind, "memberId", "refYear")
    WHERE ("memberId" IS NOT NULL AND "refYear" IS NOT NULL) DO NOTHING
  RETURNING id INTO v_id;

  RETURN jsonb_build_object(
    'eingereiht', v_id IS NOT NULL,
    'grund', CASE WHEN v_id IS NULL THEN 'bereits eingereiht' ELSE null END,
    'empfaenger', btrim(m.email),
    'sprachen', v_sprachen);
END $$;

REVOKE ALL ON FUNCTION public.willkommen_einreihen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.willkommen_einreihen(text) TO authenticated;

COMMENT ON FUNCTION public.willkommen_einreihen(text) IS
  'Reiht die Willkommensnachricht fuer ein Mitglied ein. Verschickt nichts '
  '-- das tut der Postausgang. Mehrfachaufruf ist unschaedlich.';


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_verein text; v_mitglied text := 'selbsttest-willkommen';
  v_erg jsonb; v_vorher int; v_nachher int; v_quelle text;
BEGIN
  SELECT id INTO v_verein FROM public.tenants ORDER BY id LIMIT 1;

  -- Der Baustein muss in beiden Sprachen stehen, sonst geht die Haelfte
  -- der Mitglieder leer aus.
  IF (SELECT count(DISTINCT sprache) FROM public.textbausteine
       WHERE schluessel='WILLKOMMEN' AND "tenantId"=v_verein) < 2 THEN
    RAISE EXCEPTION 'Der Willkommenstext fehlt in einer Sprache.';
  END IF;

  -- Die Berechtigungspruefung muss drin sein.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='willkommen_einreihen';
  IF v_quelle !~ 'is_member_manager' OR v_quelle !~ 'current_user_row_id' THEN
    RAISE EXCEPTION 'In willkommen_einreihen fehlt die Berechtigungspruefung -- '
                    'damit koennte jedes Konto Post an jedes Mitglied ausloesen.';
  END IF;

  SELECT count(*) INTO v_vorher FROM public.mail_queue;

  -- Ein Mitglied ohne Adresse darf die Erfassung nicht scheitern lassen.
  INSERT INTO public.users (id,"tenantId","displayName",role,email)
  VALUES (v_mitglied, v_verein, 'Selbsttest Ohne Mail', 'MEMBER', NULL);
  v_erg := public.willkommen_einreihen(v_mitglied);
  IF (v_erg->>'eingereiht')::boolean THEN
    RAISE EXCEPTION 'Ohne Adresse wurde eine Nachricht eingereiht: %', v_erg;
  END IF;

  -- Mit Adresse: genau eine, und ein zweiter Aufruf legt keine zweite an.
  UPDATE public.users SET email = 'selbsttest@example.invalid' WHERE id = v_mitglied;
  v_erg := public.willkommen_einreihen(v_mitglied);
  IF NOT (v_erg->>'eingereiht')::boolean THEN
    RAISE EXCEPTION 'Mit Adresse wurde nichts eingereiht: %', v_erg;
  END IF;
  v_erg := public.willkommen_einreihen(v_mitglied);
  IF (v_erg->>'eingereiht')::boolean THEN
    RAISE EXCEPTION 'Der zweite Aufruf hat eine zweite Nachricht angelegt.';
  END IF;

  SELECT count(*) INTO v_nachher FROM public.mail_queue;
  IF v_nachher <> v_vorher + 1 THEN
    RAISE EXCEPTION 'Erwartet eine neue Nachricht, gefunden %.', v_nachher - v_vorher;
  END IF;

  -- Und der Inhalt: kein unaufgeloester Platzhalter.
  IF EXISTS (SELECT 1 FROM public.mail_queue
              WHERE "memberId" = v_mitglied AND (text LIKE '%{{%' OR subject LIKE '%{{%')) THEN
    RAISE EXCEPTION 'Im Willkommensbrief steht ein unaufgeloester Platzhalter.';
  END IF;

  DELETE FROM public.mail_queue WHERE "memberId" = v_mitglied;
  DELETE FROM public.users WHERE id = v_mitglied;

  SELECT count(*) INTO v_nachher FROM public.mail_queue;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Nachricht(en) hinterlassen.', v_nachher - v_vorher;
  END IF;

  RAISE NOTICE 'Willkommensmail bereit: zweisprachig, einmal je Mitglied, '
               'ohne Adresse kein Brief, Selbsttest ohne Rueckstand.';
END $$;
