-- Eine Vereinsadresse gilt erst, wenn sie empfaengt.
--
-- Die fuenf Adressen stehen in vorstand_adressen, und
-- vorstand_mail_einreihen setzt sie als Antwortadresse. Nur: die
-- WEITERLEITUNG richtet der Mailhost ein, nicht diese Software -- und
-- solange sie dort fehlt, ist valton.rexha@koretini.me eine Adresse, die
-- niemand liest.
--
-- Das ist der schlimmste der moeglichen Zustaende. Nicht weil etwas
-- scheitert, sondern weil nichts scheitert: das Mitglied antwortet, die
-- Antwort geht an eine Adresse ohne Empfaenger, und niemand erfaehrt es.
-- Weder der Absender noch der Antwortende. Eine private Adresse im
-- Kopf der Mail ist dagegen nur unschoen.
--
-- Darum zwei Zustaende statt einem:
--
--   EINGETRAGEN   die Adresse ist vorgesehen, die Maske zeigt sie als
--                 Auftrag fuer den Mailhost -- sie wirkt noch NICHT
--   BESTAETIGT    die Weiterleitung ist eingerichtet und geprueft --
--                 erst jetzt steht sie als Antwortadresse in der Post
--
-- Bis zur Bestaetigung faellt die Antwortadresse auf die private Adresse
-- des Vorstandsmitglieds zurueck. Damit kommt jede Antwort an, von der
-- ersten Nachricht an.

ALTER TABLE public.vorstand_adressen
  ADD COLUMN IF NOT EXISTS bestaetigt_am  timestamptz,
  ADD COLUMN IF NOT EXISTS bestaetigt_von text;

COMMENT ON COLUMN public.vorstand_adressen.bestaetigt_am IS
  'Wann bestaetigt wurde, dass der Mailhost diese Adresse weiterleitet. '
  'Leer = die Adresse ist vorgesehen, wirkt aber nicht als Antwortadresse -- '
  'sonst gingen Antworten an ein Postfach, das es nicht gibt.';


-- Bestaetigen. Nur die Verwaltung, und nur mit hinterlegtem Ziel: eine
-- Weiterleitung ohne Ziel ist keine.
CREATE OR REPLACE FUNCTION public.vorstand_adresse_bestaetigen(
  p_user text, p_an boolean DEFAULT true
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_ziel text; v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration bestaetigt eine Weiterleitung.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT weiterleitung INTO v_ziel FROM public.vorstand_adressen
   WHERE "tenantId" = v_verein AND "userId" = p_user AND aktiv;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Fuer diese Person ist keine aktive Vereinsadresse hinterlegt.'
      USING ERRCODE = 'check_violation';
  END IF;
  -- Ohne Ziel gibt es nichts zu bestaetigen. Das zu erlauben hiesse,
  -- eine Adresse fuer gueltig zu erklaeren, die ins Leere fuehrt.
  IF p_an AND coalesce(btrim(coalesce(v_ziel,'')),'') = '' THEN
    RAISE EXCEPTION 'Diese Adresse hat kein Weiterleitungsziel. Erst das Ziel, dann die Bestaetigung.'
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.vorstand_adressen
     SET bestaetigt_am  = CASE WHEN p_an THEN now() ELSE NULL END,
         bestaetigt_von = CASE WHEN p_an THEN public.current_user_row_id() ELSE NULL END,
         geaendert_am = now(), geaendert_von = public.current_user_row_id()
   WHERE "tenantId" = v_verein AND "userId" = p_user AND aktiv;
  GET DIAGNOSTICS v_n = ROW_COUNT;

  RETURN jsonb_build_object('geaendert', v_n, 'bestaetigt', p_an, 'ziel', v_ziel);
END $$;

REVOKE ALL ON FUNCTION public.vorstand_adresse_bestaetigen(text,boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_adresse_bestaetigen(text,boolean) TO authenticated;


-- Eine Aenderung an Adresse oder Ziel nimmt die Bestaetigung zurueck.
-- Bestaetigt wurde die ALTE Weiterleitung, nicht die neue -- dieselbe
-- Regel wie beim Gegenlesen der Textbausteine.
CREATE OR REPLACE FUNCTION public.vorstand_adresse_neu_pruefen()
RETURNS trigger
LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.adresse IS DISTINCT FROM OLD.adresse
     OR NEW.weiterleitung IS DISTINCT FROM OLD.weiterleitung THEN
    NEW.bestaetigt_am := NULL;
    NEW.bestaetigt_von := NULL;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS vorstand_adressen_neu_pruefen ON public.vorstand_adressen;
CREATE TRIGGER vorstand_adressen_neu_pruefen
  BEFORE UPDATE OF adresse, weiterleitung ON public.vorstand_adressen
  FOR EACH ROW EXECUTE FUNCTION public.vorstand_adresse_neu_pruefen();


-- Die Liste nennt den Zustand mit.
DROP FUNCTION IF EXISTS public.vorstand_adressen_liste();
CREATE OR REPLACE FUNCTION public.vorstand_adressen_liste()
RETURNS TABLE (
  r_user text, r_name text, r_privat text, r_rolle text,
  r_adresse text, r_weiterleitung text, r_aktiv boolean, r_bestaetigt timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id,
         coalesce(nullif(btrim(u."displayName"),''),
                  btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         u.email,
         coalesce(b.role, u.role),
         a.adresse, a.weiterleitung, coalesce(a.aktiv, false), a.bestaetigt_am
    FROM public.users u
    LEFT JOIN public.board_members b
           ON b."userId" = u.id AND b."tenantId" = u."tenantId"
    LEFT JOIN public.vorstand_adressen a
           ON a."userId" = u.id AND a."tenantId" = u."tenantId" AND a.aktiv
   WHERE public.is_member_manager()
     AND u."tenantId" = public.current_tenant()
     AND (b."userId" IS NOT NULL OR u.role IN ('ADMIN','SUPER_ADMIN','BOARD'))
   ORDER BY 2;
$$;

REVOKE ALL ON FUNCTION public.vorstand_adressen_liste() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_adressen_liste() TO authenticated;


-- Und die beiden Stellen, die die Antwortadresse lesen, achten den
-- Zustand: ohne Bestaetigung gilt die private Adresse.
CREATE OR REPLACE FUNCTION public.vorstand_absender()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ich text := public.current_user_row_id();
  v_name text; v_privat text; v_adresse text; v_bestaetigt timestamptz;
BEGIN
  IF NOT public.is_member_manager() OR v_verein IS NULL OR v_ich IS NULL THEN
    RETURN jsonb_build_object('darf', false);
  END IF;
  SELECT coalesce(nullif(btrim(u."displayName"),''),
                  btrim(coalesce(u."firstName",'') || ' ' || coalesce(u."lastName",''))),
         u.email
    INTO v_name, v_privat
    FROM public.users u WHERE u.id = v_ich;
  SELECT a.adresse, a.bestaetigt_am INTO v_adresse, v_bestaetigt
    FROM public.vorstand_adressen a
   WHERE a."tenantId" = v_verein AND a."userId" = v_ich AND a.aktiv;
  RETURN jsonb_build_object(
    'darf', true,
    'name', v_name,
    'verein', (SELECT t.name FROM public.tenants t WHERE t.id = v_verein),
    'adresse', v_adresse,
    'bestaetigt', v_bestaetigt IS NOT NULL,
    -- Was WIRKLICH als Antwortadresse gelten wird. Ohne bestaetigte
    -- Weiterleitung die private: eine Antwort, die ankommt, ist mehr
    -- wert als eine Adresse, die gut aussieht.
    'antwort_an', CASE WHEN v_bestaetigt IS NOT NULL THEN v_adresse ELSE v_privat END,
    'eigene_adresse', v_adresse IS NOT NULL AND v_bestaetigt IS NOT NULL,
    'adresse_wartet', v_adresse IS NOT NULL AND v_bestaetigt IS NULL,
    'darf_schreiben', public.darf_schreiben());
END $$;

REVOKE ALL ON FUNCTION public.vorstand_absender() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vorstand_absender() TO authenticated;


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
  -- Nur eine BESTAETIGTE Adresse gilt. Ohne eingerichtete Weiterleitung
  -- waere sie eine Antwortadresse ohne Postfach -- und die Antwort des
  -- Mitglieds verschwaende still.
  SELECT a.adresse INTO v_antwort
    FROM public.vorstand_adressen a
   WHERE a."tenantId" = v_verein AND a."userId" = v_ich AND a.aktiv
     AND a.bestaetigt_am IS NOT NULL;

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
-- Vier Dinge, und das erste ist das wichtigste:
--
--   ohne Bestaetigung gilt die PRIVATE Adresse   -- die Antwort kommt an
--   mit Bestaetigung gilt die Vereinsadresse
--   eine Aenderung nimmt die Bestaetigung zurueck
--   ohne Ziel laesst sich nichts bestaetigen
DO $$
DECLARE
  v_verein text := '_bestprobe_' || substr(replace(gen_random_uuid()::text,'-',''),1,8);
  v_dom text; v_adm text; v_chef text; v_mit text;
  v_uid uuid := gen_random_uuid();
  v_uida uuid := gen_random_uuid();
  v_j jsonb; v_antwort text;
BEGIN
  v_dom := replace(v_verein,'_','-') || '.probe.test';
  v_adm := v_verein || '_adm'; v_chef := v_verein || '_chef'; v_mit := v_verein || '_mit';

  INSERT INTO public.tenants (id, name) VALUES (v_verein, 'Bestaetigungsprobe');
  INSERT INTO public.tenant_domains (domain, "tenantId", "isPrimary")
    VALUES (v_dom, v_verein, true);
  INSERT INTO public.users (id, "tenantId", "displayName", email, role,
                            "membershipStatus", "authUserId")
    VALUES (v_chef, v_verein, 'Probe Chef', 'chef.privat@beispiel.test', 'BOARD',
            'ACTIVE', v_uid::text),
           (v_adm, v_verein, 'Probe Verwaltung', 'adm@' || v_dom, 'ADMIN',
            'ACTIVE', v_uida::text);
  INSERT INTO public.users (id, "tenantId", "displayName", email, role, "membershipStatus")
    VALUES (v_mit, v_verein, 'Probe Mitglied', 'mitglied@' || v_dom, 'MEMBER', 'ACTIVE');

  -- Als Verwaltung eine Adresse MIT Ziel setzen.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uida::text, 'role', 'authenticated')::text, true);
  IF public.current_user_row_id() IS DISTINCT FROM v_adm THEN
    RAISE EXCEPTION 'Verkoerperung der Verwaltung misslungen.';
  END IF;
  PERFORM public.vorstand_adresse_setzen(
    v_chef, 'chef@' || regexp_replace(v_dom,'^www\.',''), 'chef.privat@beispiel.test');

  -- 1. NOCH NICHT bestaetigt -> die private Adresse gilt.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role', 'authenticated')::text, true);
  v_j := public.vorstand_absender();
  IF (v_j ->> 'antwort_an') IS DISTINCT FROM 'chef.privat@beispiel.test' THEN
    RAISE EXCEPTION 'Ohne Bestaetigung muesste die private Adresse gelten, nicht %.',
      v_j ->> 'antwort_an';
  END IF;
  IF (v_j ->> 'adresse_wartet')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Die wartende Adresse wird nicht gemeldet: %', v_j;
  END IF;

  -- Und auch die eingereihte Nachricht traegt die private Adresse. Das
  -- ist der Punkt: eine Antwort muss ankommen.
  PERFORM public.vorstand_mail_einreihen(ARRAY[v_mit], 'Probe unbestaetigt', '<p>x</p>');
  SELECT antwort_an INTO v_antwort FROM public.mail_queue
   WHERE "tenantId" = v_verein AND subject = 'Probe unbestaetigt';
  IF v_antwort IS DISTINCT FROM 'chef.privat@beispiel.test' THEN
    RAISE EXCEPTION 'Die Nachricht traegt % als Antwortadresse — Antworten gingen ins Leere.',
      coalesce(v_antwort,'(keine)');
  END IF;

  -- 2. Bestaetigen darf nur die Verwaltung.
  BEGIN
    PERFORM public.vorstand_adresse_bestaetigen(v_chef);
    RAISE EXCEPTION 'Ein Vorstandsmitglied konnte seine eigene Weiterleitung bestaetigen.';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uida::text, 'role', 'authenticated')::text, true);
  PERFORM public.vorstand_adresse_bestaetigen(v_chef);

  -- 3. Jetzt gilt die Vereinsadresse.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uid::text, 'role', 'authenticated')::text, true);
  v_j := public.vorstand_absender();
  IF (v_j ->> 'antwort_an') IS DISTINCT FROM 'chef@' || regexp_replace(v_dom,'^www\.','') THEN
    RAISE EXCEPTION 'Nach der Bestaetigung muesste die Vereinsadresse gelten, nicht %.',
      v_j ->> 'antwort_an';
  END IF;
  PERFORM public.vorstand_mail_einreihen(ARRAY[v_mit], 'Probe bestaetigt', '<p>x</p>');
  SELECT antwort_an INTO v_antwort FROM public.mail_queue
   WHERE "tenantId" = v_verein AND subject = 'Probe bestaetigt';
  IF v_antwort IS DISTINCT FROM 'chef@' || regexp_replace(v_dom,'^www\.','') THEN
    RAISE EXCEPTION 'Die bestaetigte Adresse steht nicht in der Nachricht: %',
      coalesce(v_antwort,'(keine)');
  END IF;

  -- 4. Eine Aenderung am Ziel nimmt die Bestaetigung zurueck. Bestaetigt
  --    wurde die alte Weiterleitung.
  UPDATE public.vorstand_adressen SET weiterleitung = 'anders@beispiel.test'
   WHERE "tenantId" = v_verein AND "userId" = v_chef AND aktiv;
  IF (SELECT bestaetigt_am FROM public.vorstand_adressen
       WHERE "tenantId" = v_verein AND "userId" = v_chef AND aktiv) IS NOT NULL THEN
    RAISE EXCEPTION 'Ein geaendertes Ziel bleibt bestaetigt — die Bestaetigung galt der alten Adresse.';
  END IF;

  -- 5. Ohne Ziel laesst sich nichts bestaetigen.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_uida::text, 'role', 'authenticated')::text, true);
  UPDATE public.vorstand_adressen SET weiterleitung = NULL
   WHERE "tenantId" = v_verein AND "userId" = v_chef AND aktiv;
  BEGIN
    PERFORM public.vorstand_adresse_bestaetigen(v_chef);
    RAISE EXCEPTION 'Eine Adresse ohne Weiterleitungsziel wurde bestaetigt.';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  PERFORM set_config('request.jwt.claims', '', true);
  DELETE FROM public.mail_queue WHERE "tenantId" = v_verein;
  DELETE FROM public.vorstand_adressen WHERE "tenantId" = v_verein;
  DELETE FROM public.users WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;

  IF (SELECT count(*) FROM public.mail_queue
       WHERE subject IN ('Probe unbestaetigt','Probe bestaetigt')) > 0 THEN
    RAISE EXCEPTION 'Probenachrichten bleiben in der Warteschlange — sie gingen hinaus.';
  END IF;

  RAISE NOTICE 'Adressnachweis: ohne Bestaetigung gilt die private Adresse, mit Bestaetigung die Vereinsadresse, eine Aenderung setzt zurueck.';
EXCEPTION WHEN OTHERS THEN
  PERFORM set_config('request.jwt.claims', '', true);
  DELETE FROM public.mail_queue WHERE "tenantId" = v_verein;
  DELETE FROM public.vorstand_adressen WHERE "tenantId" = v_verein;
  DELETE FROM public.users WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;
  RAISE;
END $$;
