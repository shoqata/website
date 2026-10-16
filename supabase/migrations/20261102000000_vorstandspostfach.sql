-- Der Postausgang des Vorstands.
--
-- Bisher konnte nur die Verwaltung schreiben (AdminCommunication). Ein
-- Vorstandsmitglied, das einem Mitglied etwas mitteilen wollte, nahm
-- sein privates Postfach -- und damit stand seine private Adresse in der
-- Nachricht, die Antwort ging dorthin, und der Verein hatte keine Spur
-- davon.
--
-- Drei Dinge entstehen hier, und jedes hat einen Grund.
--
-- 1. ZWEI SPALTEN AN DER WARTESCHLANGE. antwort_an und absender_name.
--    Der technische Absender bleibt unityhub -- nur dessen Domain ist
--    bei SPF und DKIM hinterlegt; stuende valton.rexha@koretini.me als
--    From, scheiterte die Absenderpruefung und die Nachricht landete im
--    Spam. Der Empfaenger sieht aber den Namen des Vorstandsmitglieds,
--    und seine ANTWORT geht an dessen Vereinsadresse. Bisher war die
--    Antwortadresse je VEREIN hinterlegt (tenants.contactEmail); fuer
--    einen persoenlichen Brief ist das die falsche Ebene.
--
-- 2. EINE TABELLE FUER DIE VEREINSADRESSEN. Je Vorstandsmitglied eine
--    Adresse auf einer Domain des Vereins, dazu die private Adresse, an
--    die der Mailhost weiterleitet. Die Weiterleitung selbst richtet der
--    Mailhost ein, nicht diese Software -- hier steht sie, damit man
--    nachsehen kann, was dort eingetragen sein MUSS, und damit niemand
--    sie im Kopf behalten muss.
--
-- 3. EINE FUNKTION, DIE MITGLIEDS-IDS NIMMT UND KEINE ADRESSEN.
--    Das ist der wichtigste Entschluss. Nimmt man Adressen an, ist der
--    Postausgang ein offenes Relais: wer die Maske erreicht, verschickt
--    ueber den Server des Betreibers an beliebige Empfaenger. Die
--    Funktion loest die Adressen selbst aus users auf, und nur innerhalb
--    des eigenen Vereins. Ebenso wird die ANTWORTADRESSE nicht
--    uebergeben, sondern aus der Zeile des Aufrufers gelesen -- sonst
--    koennte ein Vorstandsmitglied unter dem Namen eines anderen
--    schreiben.

-- ------------------------------------------------- 1. Warteschlange
ALTER TABLE public.mail_queue
  ADD COLUMN IF NOT EXISTS antwort_an    text,
  ADD COLUMN IF NOT EXISTS absender_name text,
  ADD COLUMN IF NOT EXISTS absender_id   text;

COMMENT ON COLUMN public.mail_queue.antwort_an IS
  'Reply-To dieser Nachricht. Leer = die Antwortadresse des Vereins. '
  'Wird NIE aus einer Eingabe uebernommen, sondern aus der Zeile des Absenders.';
COMMENT ON COLUMN public.mail_queue.absender_name IS
  'Anzeigename im From. Der technische Absender bleibt unityhub.';
COMMENT ON COLUMN public.mail_queue.absender_id IS
  'Wer die Nachricht eingereiht hat. Gebraucht fuer die Tagesgrenze je Person '
  '-- ohne sie koennte ein Einzelner das Budget des ganzen Vereins verbrauchen.';

-- Gezaehlt wird nach Tag und Absender. Ohne diesen Index liest jede
-- Pruefung die ganze Warteschlange.
CREATE INDEX IF NOT EXISTS mail_queue_vorstand_tag
  ON public.mail_queue ("tenantId", kind, "scheduledFor");


-- ------------------------------------------------- 2. Vereinsadressen
CREATE TABLE IF NOT EXISTS public.vorstand_adressen (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "userId"      text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  adresse       text NOT NULL,
  -- Nur Dokumentation: wohin der Mailhost weiterleiten soll. Diese
  -- Software leitet nichts weiter.
  weiterleitung text,
  aktiv         boolean NOT NULL DEFAULT true,
  angelegt_am   timestamptz NOT NULL DEFAULT now(),
  geaendert_am  timestamptz,
  geaendert_von text
);

-- Eine Adresse gehoert genau einer Person, vereinsuebergreifend: zwei
-- Personen mit derselben Adresse heisst, dass eine Antwort bei der
-- falschen landet.
CREATE UNIQUE INDEX IF NOT EXISTS vorstand_adressen_adresse
  ON public.vorstand_adressen (lower(adresse));
-- Und je Person eine aktive Adresse. Mehrere waeren nicht falsch, aber
-- dann waere nicht entschieden, welche als Antwortadresse gilt.
CREATE UNIQUE INDEX IF NOT EXISTS vorstand_adressen_je_person
  ON public.vorstand_adressen ("tenantId", "userId") WHERE aktiv;
CREATE INDEX IF NOT EXISTS vorstand_adressen_verein
  ON public.vorstand_adressen ("tenantId");

ALTER TABLE public.vorstand_adressen ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS vorstand_adressen_lesen ON public.vorstand_adressen;
CREATE POLICY vorstand_adressen_lesen ON public.vorstand_adressen
  FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());

-- Geschrieben wird nur ueber die Funktion unten. Keine Regel fuer
-- INSERT/UPDATE/DELETE: eine Adresse ist eine Absenderidentitaet, und
-- die soll nicht am Tisch verteilt werden.

GRANT SELECT ON public.vorstand_adressen TO authenticated;


-- Die Adresse eines Vorstandsmitglieds festlegen.
CREATE OR REPLACE FUNCTION public.vorstand_adresse_setzen(
  p_user text, p_adresse text, p_weiterleitung text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_adresse text := lower(btrim(coalesce(p_adresse,'')));
  v_domain text;
  v_erlaubt text[];
  v_name text;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Eine Absenderidentitaet verteilt die Administration, nicht der
  -- Vorstand sich selbst.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration legt Vereinsadressen fest.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein im Zugriff.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u."displayName" INTO v_name
    FROM public.users u WHERE u.id = p_user AND u."tenantId" = v_verein;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert nicht zu diesem Verein.'
      USING ERRCODE = 'check_violation';
  END IF;

  IF v_adresse !~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' THEN
    RAISE EXCEPTION '"%" ist keine Adresse.', p_adresse USING ERRCODE = 'check_violation';
  END IF;

  -- Die Domain muss dem Verein gehoeren. Sonst waere das hier ein
  -- Werkzeug, um unter fremdem Namen zu schreiben: der Empfaenger sieht
  -- den Namen, und seine Antwort geht an diese Adresse.
  v_domain := split_part(v_adresse, '@', 2);
  SELECT array_agg(DISTINCT regexp_replace(lower(d.domain), '^www\.', ''))
    INTO v_erlaubt
    FROM public.tenant_domains d WHERE d."tenantId" = v_verein;
  IF v_erlaubt IS NULL OR NOT (v_domain = ANY (v_erlaubt)) THEN
    RAISE EXCEPTION '% gehoert nicht zum Verein. Erlaubt: %',
      v_domain, coalesce(array_to_string(v_erlaubt, ', '), '(keine Domain hinterlegt)')
      USING ERRCODE = 'check_violation';
  END IF;

  -- Die bisherige Adresse dieser Person weicht, statt zu einer zweiten
  -- aktiven zu werden.
  UPDATE public.vorstand_adressen
     SET aktiv = false, geaendert_am = now(), geaendert_von = public.current_user_row_id()
   WHERE "tenantId" = v_verein AND "userId" = p_user AND aktiv
     AND lower(adresse) <> v_adresse;

  INSERT INTO public.vorstand_adressen
    ("tenantId", "userId", adresse, weiterleitung, aktiv, geaendert_am, geaendert_von)
  VALUES (v_verein, p_user, v_adresse, nullif(btrim(coalesce(p_weiterleitung,'')),''),
          true, now(), public.current_user_row_id())
  ON CONFLICT (lower(adresse)) DO UPDATE
     SET "userId" = EXCLUDED."userId",
         weiterleitung = coalesce(EXCLUDED.weiterleitung, public.vorstand_adressen.weiterleitung),
         aktiv = true, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;

  RETURN jsonb_build_object('userId', p_user, 'name', v_name,
    'adresse', v_adresse,
    'weiterleitung', nullif(btrim(coalesce(p_weiterleitung,'')),''));
END $$;

REVOKE ALL ON FUNCTION public.vorstand_adresse_setzen(text,text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_adresse_setzen(text,text,text) TO authenticated;


-- Eine Adresse wieder abschalten.
CREATE OR REPLACE FUNCTION public.vorstand_adresse_abschalten(p_user text)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration aendert Vereinsadressen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  UPDATE public.vorstand_adressen
     SET aktiv = false, geaendert_am = now(), geaendert_von = public.current_user_row_id()
   WHERE "tenantId" = public.current_tenant() AND "userId" = p_user AND aktiv;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END $$;

REVOKE ALL ON FUNCTION public.vorstand_adresse_abschalten(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_adresse_abschalten(text) TO authenticated;


-- Wer hat welche Adresse, und wohin soll weitergeleitet werden?
CREATE OR REPLACE FUNCTION public.vorstand_adressen_liste()
RETURNS TABLE (
  r_user text, r_name text, r_privat text, r_rolle text,
  r_adresse text, r_weiterleitung text, r_aktiv boolean
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id,
         coalesce(nullif(btrim(u."displayName"),''),
                  btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         u.email,
         coalesce(b.role, u.role),
         a.adresse, a.weiterleitung, coalesce(a.aktiv, false)
    FROM public.users u
    LEFT JOIN public.board_members b
           ON b."userId" = u.id AND b."tenantId" = u."tenantId"
    LEFT JOIN public.vorstand_adressen a
           ON a."userId" = u.id AND a."tenantId" = u."tenantId" AND a.aktiv
   WHERE public.is_member_manager()
     AND u."tenantId" = public.current_tenant()
     -- Vorstand und Verwaltung: wer im Namen des Vereins schreibt.
     AND (b."userId" IS NOT NULL OR u.role IN ('ADMIN','SUPER_ADMIN','BOARD'))
   ORDER BY 2;
$$;

REVOKE ALL ON FUNCTION public.vorstand_adressen_liste() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_adressen_liste() TO authenticated;


-- ------------------------------------------------- Die Tagesgrenze
--
-- Ein freier Postausgang an dreihundert Adressen ist, von aussen
-- betrachtet, nicht von einem Spamlauf zu unterscheiden. Was dabei
-- Schaden nimmt, ist nicht der Server, sondern der RUF der Absenderdomain
-- -- und der ist geteilt: alle Vereine gehen ueber denselben Postausgang
-- von unityhub. Ein einziger unbedachter Lauf wuerde die Zustellung fuer
-- alle verschlechtern, und das ueber Wochen.
--
-- Darum zwei Grenzen und nicht eine:
--
--   je Verein und Tag    das Budget des Vereins
--   je Person und Tag    damit ein Einzelner es nicht allein verbraucht
--
-- Und eine dritte, die niemand im Verein aendern kann: die Decke des
-- Betreibers. Ein Verein, der seine eigene Grenze beliebig hochsetzen
-- koennte, hat keine.
--
-- Gezaehlt wird nach scheduledFor, nicht nach sentAt: was fuer heute
-- eingereiht ist, zaehlt heute -- auch wenn es noch nicht hinaus ist.
-- Nach sentAt zu zaehlen hiesse, dass man beliebig viel einreihen kann,
-- solange der Versender hinterherhinkt.

-- Die Decke. Kein Verein kommt darueber, auch nicht mit eigener
-- Einstellung.
CREATE OR REPLACE FUNCTION public.mail_decke_betreiber()
RETURNS integer
LANGUAGE sql IMMUTABLE SET search_path = public AS $$ SELECT 400 $$;

-- Kein Grant. Gerufen wird sie nur aus mail_grenze_heute(), und das
-- laeuft als SECURITY DEFINER -- der Aufrufer braucht sie nicht. Eine
-- neue Funktion traegt sonst EXECUTE fuer PUBLIC, und das ist der
-- Standard, der an anderer Stelle schon Loecher gelassen hat.
REVOKE ALL ON FUNCTION public.mail_decke_betreiber() FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.mail_grenze_heute()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich text := public.current_user_row_id();
  v_decke int := public.mail_decke_betreiber();
  v_gv int; v_gp int;
  v_vv int; v_vp int;
BEGIN
  IF v_verein IS NULL THEN
    RETURN jsonb_build_object('darf', false);
  END IF;

  SELECT least(coalesce((s.system ->> 'mailGrenzeVorstandTag')::int, 150), v_decke),
         least(coalesce((s.system ->> 'mailGrenzePersonTag')::int, 60), v_decke)
    INTO v_gv, v_gp
    FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';
  -- Ohne Einstellungszeile gelten die Vorgaben. Sie fehlen zu lassen
  -- hiesse: keine Grenze.
  v_gv := coalesce(v_gv, least(150, v_decke));
  v_gp := coalesce(v_gp, least(60, v_decke));

  SELECT count(*) INTO v_vv FROM public.mail_queue q
   WHERE q."tenantId" = v_verein AND q.kind = 'VORSTAND'
     AND q.status <> 'CANCELLED'
     AND q."scheduledFor"::date = current_date;

  SELECT count(*) INTO v_vp FROM public.mail_queue q
   WHERE q."tenantId" = v_verein AND q.kind = 'VORSTAND'
     AND q.status <> 'CANCELLED'
     AND q.absender_id = v_ich
     AND q."scheduledFor"::date = current_date;

  RETURN jsonb_build_object(
    'darf', true,
    'decke', v_decke,
    'grenze_verein', v_gv, 'verbraucht_verein', v_vv,
    'rest_verein', greatest(v_gv - v_vv, 0),
    'grenze_person', v_gp, 'verbraucht_person', v_vp,
    'rest_person', greatest(v_gp - v_vp, 0),
    -- Was jetzt wirklich noch geht: die kleinere der beiden.
    'rest', least(greatest(v_gv - v_vv, 0), greatest(v_gp - v_vp, 0)));
END $$;

REVOKE ALL ON FUNCTION public.mail_grenze_heute() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mail_grenze_heute() TO authenticated;


-- Wer bin ich, und woran erkennt mich der Empfaenger?
--
-- Die Maske muss das VOR dem Schreiben sagen koennen. Ohne eigene
-- Vereinsadresse geht die Antwort des Mitglieds an die private Adresse
-- des Vorstandsmitglieds -- das ist nicht falsch, aber es muss dastehen,
-- bevor jemand dreihundert Briefe verschickt.
CREATE OR REPLACE FUNCTION public.vorstand_absender()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich text := public.current_user_row_id();
  v_name text; v_privat text; v_adresse text;
BEGIN
  IF NOT public.is_member_manager() OR v_verein IS NULL OR v_ich IS NULL THEN
    RETURN jsonb_build_object('darf', false);
  END IF;
  SELECT coalesce(nullif(btrim(u."displayName"),''),
                  btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         u.email
    INTO v_name, v_privat
    FROM public.users u WHERE u.id = v_ich;
  SELECT a.adresse INTO v_adresse
    FROM public.vorstand_adressen a
   WHERE a."tenantId" = v_verein AND a."userId" = v_ich AND a.aktiv;
  RETURN jsonb_build_object(
    'darf', true,
    'name', v_name,
    'verein', (SELECT t.name FROM public.tenants t WHERE t.id = v_verein),
    'adresse', v_adresse,
    -- Was wirklich als Antwortadresse gelten wird.
    'antwort_an', coalesce(v_adresse, v_privat),
    'eigene_adresse', v_adresse IS NOT NULL,
    'darf_schreiben', public.darf_schreiben());
END $$;

REVOKE ALL ON FUNCTION public.vorstand_absender() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_absender() TO authenticated;


-- ------------------------------------------------- 3. Einreihen
CREATE OR REPLACE FUNCTION public.vorstand_mail_einreihen(
  p_mitglieder text[], p_betreff text, p_html text, p_text text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich text := public.current_user_row_id();
  v_antwort text;
  v_name text;
  v_vereinsname text;
  v_grenze jsonb;
  v_pro_tag int;
  v_heute_frei int;
  v_tag date := current_date;
  v_frei int;
  v_heute int := 0;
  v_spaeter int := 0;
  v_ohne int := 0;
  v_doppelt int := 0;
  r record;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf an Mitglieder schreiben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL OR v_ich IS NULL THEN
    RAISE EXCEPTION 'Kein Verein oder kein Absender im Zugriff.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_betreff),'') = '' OR coalesce(btrim(p_html),'') = '' THEN
    RAISE EXCEPTION 'Betreff und Text fehlen.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_mitglieder IS NULL OR array_length(p_mitglieder, 1) IS NULL THEN
    RAISE EXCEPTION 'Es ist niemand ausgewaehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF array_length(p_mitglieder, 1) > 2000 THEN
    RAISE EXCEPTION 'Mehr als 2000 Empfaenger auf einmal gehen nicht.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Die Antwortadresse kommt NICHT aus der Eingabe, sondern aus der
  -- Zeile des Aufrufers. Sonst koennte ein Vorstandsmitglied unter dem
  -- Namen eines anderen schreiben, und die Antwort ginge dorthin.
  SELECT a.adresse INTO v_antwort
    FROM public.vorstand_adressen a
   WHERE a."tenantId" = v_verein AND a."userId" = v_ich AND a.aktiv;

  SELECT coalesce(nullif(btrim(u."displayName"),''),
                  btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         coalesce(v_antwort, u.email)
    INTO v_name, v_antwort
    FROM public.users u WHERE u.id = v_ich;

  SELECT t.name INTO v_vereinsname FROM public.tenants t WHERE t.id = v_verein;

  -- Die Tagesgrenze. Was heute nicht mehr hineingeht, wird auf die
  -- Folgetage verteilt und NICHT verworfen: ein Rundbrief an alle
  -- Mitglieder ist kein Missbrauch, nur gehoert er nicht an einem Tag
  -- hinaus. Verworfen waere er eine verlorene Nachricht; verteilt ist er
  -- eine verzoegerte, und das steht in der Antwort.
  v_grenze := public.mail_grenze_heute();
  v_pro_tag := least((v_grenze ->> 'grenze_verein')::int,
                     (v_grenze ->> 'grenze_person')::int);
  v_heute_frei := (v_grenze ->> 'rest')::int;
  IF v_pro_tag < 1 THEN
    RAISE EXCEPTION 'Fuer diesen Verein ist die Tagesgrenze auf null gesetzt.'
      USING ERRCODE = 'check_violation';
  END IF;
  v_frei := v_heute_frei;

  FOR r IN
    SELECT u.id, u.email
      FROM public.users u
     WHERE u.id = ANY (p_mitglieder)
       -- Nur eigene Mitglieder. Damit ist der Postausgang kein offenes
       -- Relais: eine fremde Id trifft hier auf keine Zeile.
       AND u."tenantId" = v_verein
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     ORDER BY u.id
  LOOP
    IF coalesce(btrim(r.email),'') = '' OR position('@' in r.email) = 0 THEN
      v_ohne := v_ohne + 1;
      CONTINUE;
    END IF;
    IF EXISTS (SELECT 1 FROM public.mail_queue q
                WHERE q."tenantId" = v_verein AND q.status = 'PENDING'
                  AND q.kind = 'VORSTAND' AND q.recipient = r.email
                  AND q.subject = p_betreff) THEN
      v_doppelt := v_doppelt + 1;
      CONTINUE;
    END IF;

    -- Tag voll? Dann auf den naechsten.
    WHILE v_frei <= 0 LOOP
      v_tag := v_tag + 1;
      v_frei := v_pro_tag;
    END LOOP;

    INSERT INTO public.mail_queue
      ("tenantId", recipient, subject, html, text, kind, "memberId",
       antwort_an, absender_name, absender_id, status, "scheduledFor")
    VALUES (v_verein, r.email, p_betreff, p_html,
            coalesce(p_text, regexp_replace(p_html, '<[^>]*>', '', 'g')),
            'VORSTAND', r.id,
            v_antwort,
            case when coalesce(v_vereinsname,'') = '' then v_name
                 else v_name || ' · ' || v_vereinsname end,
            v_ich, 'PENDING',
            -- Heute sofort, spaeter zur gleichen Stunde.
            case when v_tag = current_date then now()
                 else v_tag::timestamptz + interval '8 hours' end);
    v_frei := v_frei - 1;
    IF v_tag = current_date THEN v_heute := v_heute + 1;
                            ELSE v_spaeter := v_spaeter + 1; END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'eingereiht', v_heute + v_spaeter,
    'heute', v_heute,
    'spaeter', v_spaeter,
    -- Wann der Lauf durch ist. Bei 0 spaeter ist es heute.
    'fertig_am', v_tag,
    'ohne_adresse', v_ohne,
    'schon_offen', v_doppelt,
    'grenze_verein', v_grenze ->> 'grenze_verein',
    'grenze_person', v_grenze ->> 'grenze_person',
    'antwort_an', v_antwort,
    'absender', v_name);
END $$;

REVOKE ALL ON FUNCTION public.vorstand_mail_einreihen(text[],text,text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_mail_einreihen(text[],text,text,text) TO authenticated;


-- ------------------------------------------------- Nachweis
--
-- Geprueft wird mit einem Probeverein und einem verkoerperten
-- Vorstandsmitglied, nicht mit echten Daten. Vier Dinge:
--
--   das Tor haelt            ohne Rechte keine Nachricht
--   kein offenes Relais      eine fremde Mitglieds-Id trifft auf nichts
--   die Antwortadresse       kommt aus der Zeile, nicht aus der Eingabe
--   nichts bleibt liegen     am Ende null Zeilen in der Warteschlange
--
-- Der letzte Punkt ist kein Schoenheitsfehler: eine vergessene Zeile mit
-- status PENDING wird vom naechsten Lauf VERSCHICKT. Alles laeuft darum
-- in einer Transaktion, und am Ende wird gezaehlt.
DO $$
DECLARE
  v_verein text := '_postprobe_' || substr(replace(gen_random_uuid()::text,'-',''),1,8);
  v_dom    text;
  -- Zwei Handelnde mit FESTEN Rollen. Der erste Entwurf hatte einen und
  -- schrieb dessen Rolle zur Laufzeit hoch -- und scheiterte am
  -- Rollentrigger aus 20261015000000, zu Recht: dort steht, dass ein
  -- Vorstandsmitglied sich nicht selbst zur Administration macht, und
  -- dass auch ein Admin die EIGENE Rolle nicht aendert. Ein Test, der
  -- einen Waechter umgehen muss, prueft das Falsche.
  v_adm    text := v_verein || '_adm';     -- setzt Adressen
  v_chef   text := v_verein || '_chef';    -- schreibt, ist nur BOARD
  v_mit    text := v_verein || '_mit';
  v_ohne   text := v_verein || '_ohne';
  v_fremd  text;
  v_uid    uuid := gen_random_uuid();      -- der Vorstand
  v_uida   uuid := gen_random_uuid();      -- die Administration
  v_j      jsonb;
  v_n      int;
BEGIN
  v_dom := replace(v_verein,'_','-') || '.probe.test';
  INSERT INTO public.tenants (id, name) VALUES (v_verein, 'Postprobe');
  INSERT INTO public.tenant_domains (domain, "tenantId", "isPrimary")
    VALUES (v_dom, v_verein, true);

  -- Die Rollen stehen beim INSERT. Der Trigger greift nur bei
  -- UPDATE OF role, und das ist hier auch nicht noetig.
  INSERT INTO public.users (id, "tenantId", "displayName", email, role,
                            "membershipStatus", "authUserId")
    VALUES (v_chef, v_verein, 'Probe Chef', 'chef@' || v_dom, 'BOARD',
            'ACTIVE', v_uid::text),
           (v_adm, v_verein, 'Probe Verwaltung', 'adm@' || v_dom, 'ADMIN',
            'ACTIVE', v_uida::text);
  INSERT INTO public.users (id, "tenantId", "displayName", email, role, "membershipStatus")
    VALUES (v_mit, v_verein, 'Probe Mitglied', 'mitglied@' || v_dom, 'MEMBER', 'ACTIVE');
  -- Ein Mitglied OHNE Adresse: es muss gezaehlt und nicht verschwiegen werden.
  INSERT INTO public.users (id, "tenantId", "displayName", email, role, "membershipStatus")
    VALUES (v_ohne, v_verein, 'Probe Ohne Mail', NULL, 'MEMBER', 'ACTIVE');
  INSERT INTO public.board_members (id, "userId", role, "tenantId")
    VALUES (v_verein || '_bm', v_chef, 'PRESIDENT', v_verein);
  -- Zwei weitere, um den Ueberlauf der Tagesgrenze zu zeigen.
  INSERT INTO public.users (id, "tenantId", "displayName", email, role, "membershipStatus")
    VALUES (v_verein || '_m2', v_verein, 'Probe Zwei', 'zwei@' || v_dom, 'MEMBER', 'ACTIVE'),
           (v_verein || '_m3', v_verein, 'Probe Drei', 'drei@' || v_dom, 'MEMBER', 'ACTIVE');
  -- Eine kuenstlich kleine Grenze: eine je Tag. Mit der Vorgabe von 150
  -- waere der Ueberlauf im Test nicht zu sehen.
  INSERT INTO public.settings (id, "tenantId", system)
    VALUES ('system', v_verein,
            jsonb_build_object('mailGrenzeVorstandTag', 1, 'mailGrenzePersonTag', 1));

  -- Ein Mitglied eines ANDEREN Vereins, als Einbruchsversuch.
  SELECT u.id INTO v_fremd FROM public.users u
   WHERE u."tenantId" <> v_verein AND coalesce(btrim(u.email),'') <> '' LIMIT 1;

  -- 1. Das Tor haelt: ohne Anspruch gar nichts.
  BEGIN
    PERFORM public.vorstand_mail_einreihen(ARRAY[v_mit], 'Probe', '<p>Probe</p>');
    RAISE EXCEPTION 'vorstand_mail_einreihen laeuft OHNE Rechte durch.';
  EXCEPTION
    WHEN insufficient_privilege THEN NULL;   -- so soll es sein
  END;

  -- Jetzt das Vorstandsmitglied verkoerpern.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role', 'authenticated')::text, true);

  -- Und PRUEFEN, dass das ueberhaupt gewirkt hat. Ohne diese Zeile
  -- koennte der ganze Test gruen sein, weil er nichts erreicht --
  -- genau dieser Fehler ist heute schon zweimal passiert.
  IF public.current_user_row_id() IS DISTINCT FROM v_chef THEN
    RAISE EXCEPTION 'Verkoerperung wirkt nicht: current_user_row_id() = %, erwartet %',
      coalesce(public.current_user_row_id(),'(null)'), v_chef;
  END IF;
  IF public.current_tenant() IS DISTINCT FROM v_verein THEN
    RAISE EXCEPTION 'Der Verein wird nicht erkannt: % statt %',
      coalesce(public.current_tenant(),'(null)'), v_verein;
  END IF;

  -- 2. Die Vereinsadresse laesst sich nur von der Verwaltung setzen.
  BEGIN
    PERFORM public.vorstand_adresse_setzen(v_chef, 'chef@' || regexp_replace(v_dom,'^www\.','') );
    RAISE EXCEPTION 'Ein Vorstandsmitglied konnte sich selbst eine Absenderadresse geben.';
  EXCEPTION
    WHEN insufficient_privilege THEN NULL;
  END;

  -- Jetzt die Verwaltung verkoerpern -- eine ANDERE Person, kein
  -- Rollenwechsel.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uida::text, 'role', 'authenticated')::text, true);
  IF public.current_user_row_id() IS DISTINCT FROM v_adm THEN
    RAISE EXCEPTION 'Die Verwaltung wird nicht verkoerpert: %',
      coalesce(public.current_user_row_id(),'(null)');
  END IF;

  -- Eine fremde Domain muss abgelehnt werden.
  BEGIN
    PERFORM public.vorstand_adresse_setzen(v_chef, 'chef@gmail.com');
    RAISE EXCEPTION 'Eine fremde Domain wurde als Absenderadresse angenommen.';
  EXCEPTION
    WHEN check_violation THEN NULL;
  END;
  v_j := public.vorstand_adresse_setzen(
           v_chef,
           'chef@' || regexp_replace(v_dom, '^www\.', ''),
           'chef.privat@gmail.com');
  IF v_j ->> 'adresse' IS NULL THEN
    RAISE EXCEPTION 'Die Vereinsadresse wurde nicht gesetzt.';
  END IF;

  -- Und zurueck zum Vorstandsmitglied: es schreibt, nicht die Verwaltung.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role', 'authenticated')::text, true);
  IF public.current_user_row_id() IS DISTINCT FROM v_chef THEN
    RAISE EXCEPTION 'Zurueck zum Vorstand misslungen: %',
      coalesce(public.current_user_row_id(),'(null)');
  END IF;

  -- 3. Einreihen: eigenes Mitglied, eines ohne Adresse, und eine fremde Id.
  v_j := public.vorstand_mail_einreihen(
           ARRAY[v_mit, v_ohne] || coalesce(ARRAY[v_fremd], ARRAY[]::text[]),
           'Probebetreff', '<p>Probeinhalt</p>');

  IF (v_j ->> 'eingereiht')::int <> 1 THEN
    RAISE EXCEPTION 'Erwartet war genau eine Nachricht, eingereiht wurden %.',
      v_j ->> 'eingereiht';
  END IF;
  IF (v_j ->> 'ohne_adresse')::int <> 1 THEN
    RAISE EXCEPTION 'Das Mitglied ohne Adresse wird nicht gezaehlt (%).',
      v_j ->> 'ohne_adresse';
  END IF;
  -- Der Einbruchsversuch: die fremde Id darf NICHTS erzeugt haben.
  IF v_fremd IS NOT NULL THEN
    SELECT count(*) INTO v_n FROM public.mail_queue q
     WHERE q."memberId" = v_fremd AND q.kind = 'VORSTAND' AND q.subject = 'Probebetreff';
    IF v_n > 0 THEN
      RAISE EXCEPTION 'Eine fremde Mitglieds-Id hat % Nachricht(en) erzeugt — offenes Relais.', v_n;
    END IF;
  END IF;

  -- 4. Die Antwortadresse kommt aus der Zeile, nicht aus der Eingabe.
  SELECT q.antwort_an INTO v_fremd FROM public.mail_queue q
   WHERE q."tenantId" = v_verein AND q.kind = 'VORSTAND' AND q.subject = 'Probebetreff';
  IF v_fremd IS DISTINCT FROM 'chef@' || regexp_replace(v_dom, '^www\.', '') THEN
    RAISE EXCEPTION 'Falsche Antwortadresse: %', coalesce(v_fremd, '(keine)');
  END IF;

  -- 5. Derselbe Brief zweimal ist ein Doppelklick.
  v_j := public.vorstand_mail_einreihen(ARRAY[v_mit], 'Probebetreff', '<p>Probeinhalt</p>');
  IF (v_j ->> 'eingereiht')::int <> 0 OR (v_j ->> 'schon_offen')::int <> 1 THEN
    RAISE EXCEPTION 'Der Doppelklick wurde nicht erkannt: %', v_j;
  END IF;

  -- 6. Die Tagesgrenze. Eine je Tag, zwei Empfaenger: einer heute,
  --    einer morgen -- und keiner verworfen.
  v_j := public.mail_grenze_heute();
  IF (v_j ->> 'grenze_person')::int <> 1 THEN
    RAISE EXCEPTION 'Die Grenze je Person kommt falsch zurueck: %', v_j;
  END IF;
  -- Eine Nachricht liegt schon von oben fuer heute: das Budget ist
  -- bereits verbraucht.
  IF (v_j ->> 'rest')::int <> 0 THEN
    RAISE EXCEPTION 'Nach einer Nachricht bei Grenze 1 muesste der Rest 0 sein: %', v_j;
  END IF;

  v_j := public.vorstand_mail_einreihen(
           ARRAY[v_verein || '_m2', v_verein || '_m3'],
           'Probe Grenze', '<p>Probe</p>');
  IF (v_j ->> 'heute')::int <> 0 THEN
    RAISE EXCEPTION 'Das heutige Budget war voll, trotzdem gehen % heute hinaus.',
      v_j ->> 'heute';
  END IF;
  IF (v_j ->> 'spaeter')::int <> 2 THEN
    RAISE EXCEPTION 'Beide muessten auf Folgetage verteilt sein, nicht %.',
      v_j ->> 'spaeter';
  END IF;
  -- Und sie liegen an VERSCHIEDENEN Tagen, nicht beide morgen: bei
  -- Grenze 1 passt je Tag genau eine.
  SELECT count(DISTINCT q."scheduledFor"::date) INTO v_n
    FROM public.mail_queue q
   WHERE q."tenantId" = v_verein AND q.subject = 'Probe Grenze';
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'Bei Grenze 1 muessten die zwei auf 2 Tage fallen, nicht auf %.', v_n;
  END IF;
  -- Nichts liegt in der Vergangenheit oder heute.
  SELECT count(*) INTO v_n FROM public.mail_queue q
   WHERE q."tenantId" = v_verein AND q.subject = 'Probe Grenze'
     AND q."scheduledFor"::date <= current_date;
  IF v_n > 0 THEN
    RAISE EXCEPTION '% verteilte Nachricht(en) liegen trotzdem auf heute.', v_n;
  END IF;

  -- Aufraeumen. Und zwar vollstaendig: eine vergessene PENDING-Zeile
  -- wuerde beim naechsten Lauf wirklich verschickt.
  PERFORM set_config('request.jwt.claims', '', true);
  DELETE FROM public.mail_queue WHERE "tenantId" = v_verein;
  DELETE FROM public.vorstand_adressen WHERE "tenantId" = v_verein;
  DELETE FROM public.board_members WHERE "tenantId" = v_verein;
  DELETE FROM public.settings WHERE "tenantId" = v_verein;
  DELETE FROM public.users WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;

  SELECT count(*) INTO v_n FROM public.mail_queue
   WHERE kind = 'VORSTAND' AND subject IN ('Probebetreff', 'Probe Grenze');
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Probenachricht(en) bleiben in der Warteschlange — sie gingen hinaus.', v_n;
  END IF;

  RAISE NOTICE 'Vorstandspostausgang: Tor haelt, kein Relais, Antwortadresse aus der Zeile, Tagesgrenze verteilt statt verwirft, Warteschlange leer.';
EXCEPTION WHEN OTHERS THEN
  PERFORM set_config('request.jwt.claims', '', true);
  DELETE FROM public.mail_queue WHERE "tenantId" = v_verein;
  DELETE FROM public.vorstand_adressen WHERE "tenantId" = v_verein;
  DELETE FROM public.board_members WHERE "tenantId" = v_verein;
  DELETE FROM public.settings WHERE "tenantId" = v_verein;
  DELETE FROM public.users WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;
  RAISE;
END $$;
