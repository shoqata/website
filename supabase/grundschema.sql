


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."app_neighborhood"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT "neighborhoodId" FROM public.users WHERE id = public.current_user_row_id()
$$;


ALTER FUNCTION "public"."app_neighborhood"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT 'SUPER_ADMIN'
       WHERE auth.jwt() ->> 'email' IS NOT NULL
         AND EXISTS (SELECT 1 FROM public.admin_emails
                      WHERE lower(email) = lower(auth.jwt() ->> 'email'))),
    (SELECT role FROM public.users WHERE id = public.current_user_row_id()),
    'GUEST'
  )
$$;


ALTER FUNCTION "public"."app_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ausfluege_fuer"("p_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE v_person uuid; v_treffen uuid; v_bis date;
BEGIN
  SELECT d.id, te.treffen_id, d.gueltig_bis INTO v_person, v_treffen, v_bis
    FROM public.treffen_delegation d
    JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
   WHERE d.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_person IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id, 'titel', p.titel, 'ziel', p.ziel, 'treffpunkt', p.treffpunkt,
      'anreise', p.anreise, 'beginn', p.beginn, 'rueckkehr', p.rueckkehr,
      'plaetze', p.plaetze, 'kosten', p.kosten,
      'frei', public.ausflug_plaetze_frei(p.id),
      'dabei', EXISTS (SELECT 1 FROM public.treffen_ausflug_anmeldung a
                        WHERE a.programm_id = p.id AND a.delegation_id = v_person))
      ORDER BY p.tag NULLS FIRST, p.beginn), '[]'::jsonb)
    FROM public.treffen_programm p
   WHERE p.treffen_id = v_treffen AND p.art = 'AUSFLUG' AND p.freigegeben);
END $$;


ALTER FUNCTION "public"."ausfluege_fuer"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
  v_person uuid; v_bis date; v_treffen uuid;
  v_plaetze int; v_belegt int; v_art text;
BEGIN
  SELECT id, gueltig_bis INTO v_person, v_bis FROM public.treffen_delegation
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_person IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  -- Zeile sperren, dann zaehlen.
  SELECT art, plaetze, treffen_id INTO v_art, v_plaetze, v_treffen
    FROM public.treffen_programm WHERE id = p_programm FOR UPDATE;
  IF v_art IS NULL THEN RAISE EXCEPTION 'Programmpunkt nicht gefunden.'; END IF;
  IF v_art <> 'AUSFLUG' THEN RAISE EXCEPTION 'Dafuer gibt es keine Anmeldung.'; END IF;

  -- Der Ausflug muss zum selben Treffen gehoeren wie die Person. Ohne
  -- diese Pruefung koennte sich jemand mit seinem Link auf den Ausflug
  -- eines fremden Treffens setzen.
  IF NOT EXISTS (SELECT 1 FROM public.treffen_delegation d
                   JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                  WHERE d.id = v_person AND te.treffen_id = v_treffen) THEN
    RAISE EXCEPTION 'Dieser Ausflug gehoert zu einem anderen Treffen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  IF NOT p_dabei THEN
    DELETE FROM public.treffen_ausflug_anmeldung
     WHERE programm_id = p_programm AND delegation_id = v_person;
    RETURN jsonb_build_object('dabei', false,
      'frei', public.ausflug_plaetze_frei(p_programm));
  END IF;

  IF v_plaetze IS NOT NULL THEN
    SELECT count(*) INTO v_belegt FROM public.treffen_ausflug_anmeldung
     WHERE programm_id = p_programm AND delegation_id <> v_person;
    IF v_belegt >= v_plaetze THEN
      RAISE EXCEPTION 'Dieser Ausflug ist ausgebucht (% Plaetze).', v_plaetze;
    END IF;
  END IF;

  INSERT INTO public.treffen_ausflug_anmeldung (programm_id, delegation_id)
  VALUES (p_programm, v_person)
  ON CONFLICT (programm_id, delegation_id) DO NOTHING;

  RETURN jsonb_build_object('dabei', true, 'frei', public.ausflug_plaetze_frei(p_programm));
END $$;


ALTER FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT CASE WHEN p.plaetze IS NULL THEN NULL
              ELSE greatest(0, p.plaetze -
                   (SELECT count(*) FROM public.treffen_ausflug_anmeldung a
                     WHERE a.programm_id = p.id)) END
    FROM public.treffen_programm p WHERE p.id = p_programm;
$$;


ALTER FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."baustein_gegengelesen"("p_id" "uuid", "p_an" boolean DEFAULT true) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_wer text; v_name text; v_text text; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_staff()) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf einen Text als gegengelesen vermerken.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_wer := public.current_user_row_id();
  SELECT u."displayName" INTO v_name FROM public.users u WHERE u.id = v_wer;

  SELECT b.text INTO v_text FROM public.textbausteine b
   WHERE b.id = p_id AND b."tenantId" = public.current_tenant();
  IF v_text IS NULL THEN
    RAISE EXCEPTION 'Diesen Textbaustein gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.textbausteine SET
    geprueft_am   = CASE WHEN p_an THEN now() ELSE NULL END,
    geprueft_von  = CASE WHEN p_an THEN coalesce(v_name, 'unbekannt') ELSE NULL END,
    geprueft_text = CASE WHEN p_an THEN v_text ELSE NULL END
   WHERE id = p_id AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Nicht vermerkt.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN p_an;
END $$;


ALTER FUNCTION "public"."baustein_gegengelesen"("p_id" "uuid", "p_an" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."beitragsjahre_oeffentlich"() RETURNS integer[]
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := coalesce(public.current_tenant(), public.request_tenant());
  v_stellung text;
BEGIN
  IF v_verein IS NULL THEN RETURN '{}'; END IF;

  SELECT upper(coalesce(s.system ->> 'beitraegeOeffentlich','AUS'))
    INTO v_stellung FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';
  IF coalesce(v_stellung,'AUS') NOT IN ('ZAHL','NAMEN','BETRAEGE') THEN
    RETURN '{}';
  END IF;

  RETURN coalesce((
    SELECT array_agg(DISTINCT p."billingYear" ORDER BY p."billingYear" DESC)
      FROM public.payments p
     WHERE p."tenantId" = v_verein AND p.status = 'PAID'
       AND p."billingYear" IS NOT NULL), '{}');
END $$;


ALTER FUNCTION "public"."beitragsjahre_oeffentlich"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer DEFAULT NULL::integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein   text := coalesce(public.current_tenant(), public.request_tenant());
  v_stellung text;
  v_jahr     int  := coalesce(p_jahr, extract(year FROM current_date)::int);
  v_anzahl   int;
  v_gesamt   int;
  v_namen    jsonb;
  v_zeilen   jsonb;
  v_summe    numeric;
  v_waehrung text;
BEGIN
  IF v_verein IS NULL THEN
    RETURN jsonb_build_object('stellung','AUS');
  END IF;

  SELECT upper(coalesce(s.system ->> 'beitraegeOeffentlich','AUS'))
    INTO v_stellung
    FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';

  IF coalesce(v_stellung,'AUS') NOT IN ('ZAHL','NAMEN','BETRAEGE') THEN
    RETURN jsonb_build_object('stellung','AUS');
  END IF;

  -- Die Zahl umfasst alle, die bezahlt haben. Sie ist eine Summe und
  -- benennt niemanden; ein Widerspruch aendert daran nichts.
  SELECT count(DISTINCT p."userId")
    INTO v_anzahl
    FROM public.payments p
   WHERE p."tenantId" = v_verein
     AND p."billingYear" = v_jahr
     AND p.status = 'PAID'
     AND p."userId" IS NOT NULL;

  SELECT count(*) INTO v_gesamt
    FROM public.users u
   WHERE u."tenantId" = v_verein
     AND coalesce(u."membershipStatus",'') = 'ACTIVE';

  IF v_stellung = 'ZAHL' THEN
    RETURN jsonb_build_object('stellung','ZAHL','jahr',v_jahr,
                              'anzahl',v_anzahl,'gesamt',v_gesamt);
  END IF;

  IF v_stellung = 'NAMEN' THEN
    SELECT jsonb_agg(x.name ORDER BY x.name)
      INTO v_namen
      FROM (SELECT DISTINCT coalesce(nullif(btrim(u."displayName"),''),
                                     btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",''))) AS name
              FROM public.payments p
              JOIN public.users u ON u.id = p."userId"
             WHERE p."tenantId" = v_verein
               AND p."billingYear" = v_jahr
               AND p.status = 'PAID'
               AND coalesce(u.nicht_oeffentlich,false) = false
               AND coalesce(u."membershipStatus",'') <> 'INACTIVE') x
     WHERE coalesce(btrim(x.name),'') <> '';

    RETURN jsonb_build_object('stellung','NAMEN','jahr',v_jahr,
                              'anzahl',v_anzahl,'gesamt',v_gesamt,
                              'namen', coalesce(v_namen,'[]'::jsonb));
  END IF;

  -- BETRAEGE: Name und Betrag, je Mitglied zusammengefasst.
  --
  -- Zusammengefasst, weil ein Mitglied mehrere Rechnungen im Jahr haben
  -- kann -- Beitrag und eine Nachforderung etwa. Zwei Zeilen fuer eine
  -- Person saehen auf der Website wie zwei Personen aus.
  --
  -- coalesce(bezahlt, amount): Zahlungen aus der Zeit vor den
  -- Zahlungseingaengen haben bezahlt = 0 und stehen auf PAID. Fuer sie
  -- ist der Rechnungsbetrag die beste verfuegbare Auskunft; bei allen
  -- neueren steht der erhaltene Betrag.
  SELECT jsonb_agg(jsonb_build_object('name', y.name, 'betrag', y.betrag)
                   ORDER BY y.betrag DESC, y.name),
         sum(y.betrag)
    INTO v_zeilen, v_summe
    FROM (
      SELECT coalesce(nullif(btrim(u."displayName"),''),
                      btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",''))) AS name,
             sum(CASE WHEN coalesce(p.bezahlt,0) > 0 THEN p.bezahlt ELSE p.amount END) AS betrag
        FROM public.payments p
        JOIN public.users u ON u.id = p."userId"
       WHERE p."tenantId" = v_verein
         AND p."billingYear" = v_jahr
         AND p.status = 'PAID'
         AND coalesce(u.nicht_oeffentlich,false) = false
         AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
       GROUP BY 1
      HAVING coalesce(btrim(coalesce(nullif(btrim(u."displayName"),''),
                      btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",'')))),'') <> ''
    ) y;

  SELECT currency INTO v_waehrung FROM public.payments
   WHERE "tenantId" = v_verein AND "billingYear" = v_jahr AND status = 'PAID'
   LIMIT 1;

  RETURN jsonb_build_object('stellung','BETRAEGE','jahr',v_jahr,
                            'anzahl',v_anzahl,'gesamt',v_gesamt,
                            'waehrung', coalesce(v_waehrung,'CHF'),
                            'summe', coalesce(v_summe, 0),
                            'zeilen', coalesce(v_zeilen,'[]'::jsonb));
END $$;


ALTER FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."belegnummer_vergeben"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NEW.belegnr IS NULL THEN
    SELECT coalesce(max(belegnr), 0) + 1 INTO NEW.belegnr
      FROM public.accounting_journal
     WHERE "tenantId" = NEW."tenantId" AND substr(date,1,4) = substr(NEW.date,1,4);
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."belegnummer_vergeben"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."board_meeting_freigabe"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NEW."publishedToMembers" IS DISTINCT FROM coalesce(OLD."publishedToMembers", false) THEN
    IF NEW."publishedToMembers" THEN
      NEW."publishedAt" := now();
      NEW."publishedBy" := coalesce(public.current_user_row_id(), auth.jwt() ->> 'email', 'unbekannt');
    ELSE
      NEW."publishedAt" := NULL;
      NEW."publishedBy" := NULL;
    END IF;
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."board_meeting_freigabe"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."board_meeting_versionieren"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_wer text;
BEGIN
  -- Nur echte inhaltliche Aenderungen zaehlen. Ein Speichern ohne Unterschied
  -- soll keine Version erzeugen, sonst ist die Liste nach kurzer Zeit
  -- unbrauchbar.
  IF to_jsonb(OLD) - 'version' - 'updatedAt' - 'updatedBy'
     IS NOT DISTINCT FROM
     to_jsonb(NEW) - 'version' - 'updatedAt' - 'updatedBy' THEN
    RETURN NEW;
  END IF;

  v_wer := coalesce(public.current_user_row_id(), auth.jwt() ->> 'email', 'unbekannt');

  -- Festgehalten wird der Stand VOR der Aenderung, unter seiner Versionsnummer.
  INSERT INTO public.board_meeting_versions
    ("tenantId", "meetingId", version, snapshot, "changedBy")
  VALUES (OLD."tenantId", OLD.id, OLD.version, to_jsonb(OLD), v_wer)
  ON CONFLICT ("meetingId", version) DO NOTHING;

  NEW.version    := OLD.version + 1;
  NEW."updatedAt" := now();
  NEW."updatedBy" := v_wer;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."board_meeting_versionieren"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."book_payment_entries"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_label text;
  v_date  text;
BEGIN
  v_label := COALESCE(NULLIF(NEW."invoiceNumber", ''), NEW.id);

  -- 1. Forderung bei Rechnungsstellung. Unveraendert.
  IF NOT EXISTS (
    SELECT 1 FROM public.accounting_journal
     WHERE "referenceId" = NEW.id AND "creditCode" = '3000'
  ) THEN
    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD'),
      'Rechnung ' || v_label,
      '1100', '3000', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );
  END IF;

  -- 2. Zahlungseingang -- nur noch fuer Zahlungen OHNE erfasste
  --    Eingaenge. Das ist der Altbestand und alles, was ueber einen
  --    aelteren Weg hereinkommt. Wo Eingaenge stehen, bucht deren
  --    eigener Trigger, und zwar den Betrag, der wirklich kam.
  IF NEW.status = 'PAID'
     AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge e
                      WHERE e."paymentId" = NEW.id)
     AND NOT EXISTS (
       SELECT 1 FROM public.accounting_journal
        WHERE "referenceId" = NEW.id AND "creditCode" = '1100'
     ) THEN
    v_date := COALESCE(
      NULLIF(left(NEW."paidAt", 10), ''),
      to_char(COALESCE(NEW."timestamp", now()), 'YYYY-MM-DD')
    );

    INSERT INTO public.accounting_journal
      (id, date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry", "tenantId")
    VALUES (
      gen_random_uuid()::text,
      v_date,
      'Zahlungseingang ' || v_label,
      public.payment_asset_code(NEW.method, NEW.currency), '1100', NEW.amount,
      NEW.id, true, NEW."tenantId"
    );

    IF NEW."bookedInJournal" IS DISTINCT FROM true THEN
      UPDATE public.payments SET "bookedInJournal" = true WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NULL;
END $$;


ALTER FUNCTION "public"."book_payment_entries"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."buchung_protokollieren"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_wer text;
  v_mail text;
BEGIN
  -- Wer es war. Ueber die Benutzerzeile, nicht ueber auth.uid() allein:
  -- die Zeilenkennung ist das, was anderswo in den Daten steht.
  SELECT u.id, u.email INTO v_wer, v_mail
    FROM public.users u
   WHERE u."authUserId" = nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
   LIMIT 1;

  INSERT INTO public.buchungsprotokoll
    ("tenantId", buchung_id, vorgang, vorher, nachher, wer, wer_email)
  VALUES (OLD."tenantId", OLD.id,
          CASE WHEN TG_OP = 'DELETE' THEN 'LOESCHUNG' ELSE 'AENDERUNG' END,
          to_jsonb(OLD),
          CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
          v_wer, v_mail);
  RETURN NULL;   -- AFTER-Ausloeser
END $$;


ALTER FUNCTION "public"."buchung_protokollieren"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claim_my_profile"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_uid    text := auth.uid()::text;
  v_email  text := lower(auth.jwt() ->> 'email');
  v_verein text := public.request_tenant();
  v_id     text;
BEGIN
  IF v_uid IS NULL THEN RETURN NULL; END IF;

  SELECT public.current_user_row_id() INTO v_id;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  IF v_email IS NULL THEN RETURN NULL; END IF;

  -- Nur gewoehnliche Zeilen. Eine bevorrechtigte Rolle bekommt ihr
  -- Anmeldekonto von der Administration gesetzt -- ueber
  -- reset_member_password, das protokolliert wird. Unveraendert: dieser
  -- Riegel hat sich bewaehrt, als jemand mit der Rolle REPRESENTATIVE
  -- sich selbst anmelden wollte.
  --
  -- Neu ist allein die Einschraenkung auf den Verein der Herkunft.
  SELECT u.id INTO v_id
    FROM public.users u
   WHERE lower(u.email) = v_email
     AND u."authUserId" IS NULL
     AND coalesce(u.role, 'MEMBER') IN ('MEMBER', 'GUEST')
     AND (v_verein IS NULL OR u."tenantId" = v_verein)
   ORDER BY (u."tenantId" IS NOT DISTINCT FROM v_verein) DESC,
            u."joinedAt" NULLS LAST, u.id
   LIMIT 1;

  IF v_id IS NULL THEN RETURN NULL; END IF;

  UPDATE public.users SET "authUserId" = v_uid WHERE id = v_id;
  RETURN v_id;
END $$;


ALTER FUNCTION "public"."claim_my_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claimable_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT role FROM public.users
      WHERE auth.jwt() ->> 'email' IS NOT NULL
        AND lower(email) = lower(auth.jwt() ->> 'email')
        AND id <> auth.uid()::text
      LIMIT 1),
    'MEMBER')
$$;


ALTER FUNCTION "public"."claimable_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_tenant"("p_name" "text", "p_slug" "text" DEFAULT NULL::"text", "p_domain" "text" DEFAULT NULL::"text", "p_admin_email" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_id     text;
  v_domain text := lower(btrim(p_domain));
  v_email  text := lower(btrim(coalesce(p_admin_email, '')));
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf Vereine anlegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_name), '') = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_domain = '' THEN
    RAISE EXCEPTION 'Domain fehlt -- ohne sie ist die Website des Vereins nicht auffindbar.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tenant_domains WHERE domain = v_domain) THEN
    RAISE EXCEPTION 'Die Domain % ist bereits einem Verein zugeordnet.', v_domain
      USING ERRCODE = 'unique_violation';
  END IF;

  IF v_email <> '' THEN
    IF position('@' in v_email) = 0 THEN
      RAISE EXCEPTION 'E-Mail des Administrators ist unvollstaendig.' USING ERRCODE='check_violation';
    END IF;
    IF EXISTS (SELECT 1 FROM public.users WHERE lower(email) = v_email) THEN
      RAISE EXCEPTION 'Die Adresse % ist bereits vergeben. Lassen Sie das Feld leer, wenn Sie den Verein zunaechst selbst einrichten wollen.', v_email
        USING ERRCODE='unique_violation';
    END IF;
  END IF;

  v_id := coalesce(nullif(btrim(p_slug), ''), regexp_replace(lower(p_name), '[^a-z0-9]+', '-', 'g'));
  v_id := btrim(regexp_replace(lower(v_id), '[^a-z0-9-]+', '-', 'g'), '-');
  IF v_id = '' THEN
    RAISE EXCEPTION 'Aus Name und Kurzform laesst sich keine Kennung bilden.'
      USING ERRCODE='check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tenants WHERE id = v_id) THEN
    v_id := v_id || '-' || substr(md5(random()::text), 1, 4);
  END IF;

  INSERT INTO public.tenants (id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt")
  VALUES (v_id, btrim(p_name), v_id, 'FREE', 'ACTIVE', now());

  INSERT INTO public.tenant_domains ("tenantId", domain) VALUES (v_id, v_domain);

  IF v_email <> '' THEN
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (gen_random_uuid()::text, v_id, v_email, 'ADMIN', 'ACTIVE', v_email, now());
  END IF;

  PERFORM public.verein_einrichten(v_id);

  RETURN v_id;
END $$;


ALTER FUNCTION "public"."create_tenant"("p_name" "text", "p_slug" "text", "p_domain" "text", "p_admin_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_tenant"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT s."tenantId"
       FROM public.platform_support s
      WHERE s."endedAt" IS NULL
        AND s."startedAt" > now() - interval '8 hours'
        AND public.is_platform_admin()
        AND auth.jwt() ->> 'email' IS NOT NULL
        AND lower(s.email) = lower(auth.jwt() ->> 'email')
      ORDER BY s."startedAt" DESC
      LIMIT 1),
    (SELECT u."tenantId" FROM public.users u WHERE u.id = public.current_user_row_id())
  )
$$;


ALTER FUNCTION "public"."current_tenant"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_user_row_id"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT u.id FROM public.users u
   WHERE u."authUserId" = auth.uid()::text OR u.id = auth.uid()::text
   ORDER BY
     -- Die Zeile des Vereins, auf dessen Seite ich gerade bin, gewinnt.
     (u."tenantId" IS NOT DISTINCT FROM public.request_tenant()) DESC,
     -- Danach wie bisher: die ueber das Konto verknuepfte vor der, die
     -- nur zufaellig die Auth-Kennung als id traegt.
     (u."authUserId" = auth.uid()::text) DESC,
     -- Und zuletzt etwas Festes, damit die Antwort sich nicht von
     -- Aufruf zu Aufruf aendert. Ohne das koennte dieselbe Person bei
     -- zwei Abfragen zwei verschiedene Zeilen sein.
     u.id
   LIMIT 1;
$$;


ALTER FUNCTION "public"."current_user_row_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."darf_schreiben"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT CASE
    -- Betreiber und Vereinsadministration immer.
    WHEN public.is_platform_admin() THEN true
    WHEN public.app_role() IN ('SUPER_ADMIN','ADMIN') THEN true
    -- Der Vorstand nur, solange sein Verein es zulaesst.
    WHEN public.app_role() = 'BOARD' THEN
      coalesce((SELECT t.vorstand_schreibt FROM public.tenants t
                 WHERE t.id = public.current_tenant()), true)
    -- Alle uebrigen Rollen schreiben ohnehin nur ueber eigene Regeln
    -- (eigenes Profil, eigene Zusage); die bleiben unberuehrt, weil
    -- diese Schranke nur greift, wo bereits eine Erlaubnis besteht.
    ELSE true
  END;
$$;


ALTER FUNCTION "public"."darf_schreiben"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decide_payment_report"("p_report" "uuid", "p_approve" boolean, "p_note" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE r record; v_me text := public.current_user_row_id(); v_rest numeric;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Meldung entscheiden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payment_reports WHERE id = p_report;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meldung nicht gefunden.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Meldung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF r.status <> 'OPEN' THEN
    RAISE EXCEPTION 'Ueber diese Meldung wurde bereits entschieden.'
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.payment_reports
     SET status = CASE WHEN p_approve THEN 'CONFIRMED' ELSE 'REJECTED' END,
         "decidedBy" = v_me, "decidedAt" = now(), "decisionNote" = p_note
   WHERE id = p_report;

  IF p_approve THEN
    -- Der gemeldete Betrag, nicht der verrechnete. Fehlt er in einer
    -- alten Meldung, bleibt es beim offenen Rest -- das entspricht dem
    -- bisherigen Verhalten.
    SELECT coalesce(r.amount, p.amount - coalesce(p.bezahlt, 0))
      INTO v_rest FROM public.payments p WHERE p.id = r."paymentId";

    IF v_rest <> 0 THEN
      PERFORM public.zahlung_eingang_erfassen(
        r."paymentId", v_rest, r.method, r."paidOn"::date,
        'Meldung bestätigt');
    END IF;

    UPDATE public.payments
       SET "collectedBy" = COALESCE("collectedBy", r."reportedBy")
     WHERE id = r."paymentId";
  END IF;

  RETURN true;
END $$;


ALTER FUNCTION "public"."decide_payment_report"("p_report" "uuid", "p_approve" boolean, "p_note" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."eingang_verbuchen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r_zahlung record;
  v_konto text;
  v_text text;
BEGIN
  IF NEW.altbestand THEN
    RETURN NULL;   -- steht schon auf der Zahlung im Journal
  END IF;

  SELECT p.*, coalesce(nullif(p."invoiceNumber", ''), p.id) AS bezeichnung
    INTO r_zahlung FROM public.payments p WHERE p.id = NEW."paymentId";

  v_konto := public.payment_asset_code(
               coalesce(NEW.weg, r_zahlung.method), NEW.waehrung);

  -- Ohne Kontenplan keine Buchung -- aber auch kein Abbruch.
  --
  -- Das Journal hat einen Fremdschluessel auf (tenantId, debitCode). Ein
  -- Verein, der die Buchhaltung nicht eingerichtet hat, haette beim
  -- Erfassen eines Zahlungseingangs eine Fremdschluesselverletzung
  -- bekommen -- und damit den Eingang NICHT speichern koennen. Die
  -- Erfassung des Geldes haengt dann an einer Einstellung, die damit
  -- nichts zu tun hat. Der Selbsttest hat das gemeldet, weil er den
  -- Verein "demo" erwischte, der keinen Kontenplan hat.
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                  WHERE a."tenantId" = r_zahlung."tenantId" AND a.code = v_konto)
     OR NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                     WHERE a."tenantId" = r_zahlung."tenantId" AND a.code = '1100') THEN
    RETURN NULL;
  END IF;
  v_text := CASE WHEN NEW.betrag < 0 THEN 'Rückzahlung ' ELSE 'Zahlungseingang ' END
            || r_zahlung.bezeichnung;

  -- Der Eingang ist der Bezug, nicht die Zahlung. Sonst koennte eine
  -- zweite Teilzahlung nicht von der ersten unterschieden werden, und
  -- die vorhandene Doppelbuchungssperre (referenceId der Zahlung) haette
  -- sie verschluckt.
  INSERT INTO public.accounting_journal
    (id, "tenantId", date, description, "debitCode", "creditCode", amount,
     "referenceId", "isSystemEntry")
  VALUES (gen_random_uuid()::text, r_zahlung."tenantId", NEW.eingang::text,
          v_text, v_konto, '1100', NEW.betrag, NEW.id::text, true);

  RETURN NULL;
END $$;


ALTER FUNCTION "public"."eingang_verbuchen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."end_tenant_support"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_mail text := lower(auth.jwt() ->> 'email'); v_n int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf eine Betreuung beenden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  UPDATE public.platform_support SET "endedAt" = now()
   WHERE lower(email) = v_mail AND "endedAt" IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END $$;


ALTER FUNCTION "public"."end_tenant_support"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_event_capacity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_limit int;
  v_taken int;
BEGIN
  SELECT e."limit" INTO v_limit FROM public.events e WHERE e.id = NEW."eventId";

  IF v_limit IS NULL OR v_limit <= 0 THEN
    RETURN NEW; -- keine Begrenzung hinterlegt
  END IF;

  SELECT count(*) INTO v_taken
    FROM public.event_registrations r
   WHERE r."eventId" = NEW."eventId"
     AND COALESCE(r.status, 'PENDING') <> 'CANCELLED';

  IF v_taken >= v_limit THEN
    RAISE EXCEPTION 'Die Veranstaltung ist ausgebucht (% von % Plätzen belegt).', v_taken, v_limit
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION "public"."enforce_event_capacity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."familien_uebersicht"() RETURNS TABLE("familie" "text", "familienname" "text", "familie_id" "uuid", "person" "text", "name" "text", "nachname" "text", "nachbarschaft" "text", "strasse" "text", "plz" "text", "ort" "text", "geburtsdatum" "text", "eltern" "jsonb", "partner" "jsonb", "kinder" "jsonb", "geschwister" "jsonb")
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE
  kanten AS (
    SELECT von AS a, nach AS b FROM public.family_links
    UNION ALL
    SELECT nach, von FROM public.family_links
  ),
  lauf(start, erreicht) AS (
    SELECT u.id, u.id FROM public.users u
    UNION
    SELECT l.start, k.b FROM lauf l JOIN kanten k ON k.a = l.erreicht
  ),
  gruppe AS (
    SELECT start AS person, min(erreicht) AS familie FROM lauf GROUP BY start
  ),
  -- Der Name haengt an einer Ankerperson; er gilt fuer die ganze Gruppe, in
  -- der diese Person steht. Stehen zwei benannte Familien nach einer
  -- Verknuepfung in derselben Gruppe, gewinnt die zuletzt geaenderte -- und
  -- die Verwaltung sieht es, weil beide Namen weiterhin in families stehen.
  benannt AS (
    SELECT g.familie, f.name, f.id,
           row_number() OVER (PARTITION BY g.familie ORDER BY f.geaendert_am DESC) AS rang
      FROM public.families f JOIN gruppe g ON g.person = f.anker
  )
  SELECT
    g.familie, b.name, b.id,
    u.id, u."displayName", u."lastName",
    n.name, u.street, u.zip, u.city, u.birthdate,
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', e.von, 'name', eu."displayName"))
                FROM public.family_links e JOIN public.users eu ON eu.id = e.von
               WHERE e.nach = u.id AND e.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', p.id, 'name', p."displayName"))
                FROM public.family_links f2
                JOIN public.users p ON p.id = CASE WHEN f2.von = u.id THEN f2.nach ELSE f2.von END
               WHERE f2.art = 'PARTNER' AND (f2.von = u.id OR f2.nach = u.id)), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', k.nach, 'name', ku."displayName"))
                FROM public.family_links k JOIN public.users ku ON ku.id = k.nach
               WHERE k.von = u.id AND k.art = 'ELTERNTEIL'), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object('id', gs.id, 'name', gs."displayName"))
                FROM public.family_links f3
                JOIN public.users gs ON gs.id = CASE WHEN f3.von = u.id THEN f3.nach ELSE f3.von END
               WHERE f3.art = 'GESCHWISTER' AND (f3.von = u.id OR f3.nach = u.id)), '[]'::jsonb)
    FROM gruppe g
    JOIN public.users u ON u.id = g.person
    LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
    LEFT JOIN benannt b ON b.familie = g.familie AND b.rang = 1
   ORDER BY g.familie, u."displayName";
END $$;


ALTER FUNCTION "public"."familien_uebersicht"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."families_verein_setzen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ankerverein text;
BEGIN
  SELECT "tenantId" INTO v_ankerverein FROM public.users WHERE id = NEW.anker;
  IF v_ankerverein IS NULL THEN
    RAISE EXCEPTION 'Die Ankerperson gibt es nicht.';
  END IF;
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN
    NEW."tenantId" := v_ankerverein;
  END IF;
  IF NEW."tenantId" <> v_ankerverein THEN
    RAISE EXCEPTION 'Die Ankerperson gehoert zu einem anderen Verein.';
  END IF;
  IF NEW.geaendert_von IS NULL THEN
    SELECT coalesce(u.email, auth.uid()::text) INTO NEW.geaendert_von
      FROM public.users u WHERE u.id = public.current_user_row_id();
  END IF;
  NEW.geaendert_am := now();
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."families_verein_setzen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."family_links_pruefen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_a text; v_b text;
BEGIN
  SELECT "tenantId" INTO v_a FROM public.users WHERE id = NEW.von;
  SELECT "tenantId" INTO v_b FROM public.users WHERE id = NEW.nach;
  IF v_a IS NULL OR v_b IS NULL THEN
    RAISE EXCEPTION 'Mindestens eine der beiden Personen gibt es nicht.';
  END IF;
  IF v_a <> v_b OR v_a <> NEW."tenantId" THEN
    RAISE EXCEPTION 'Beide Personen muessen zum selben Verein gehoeren.';
  END IF;

  -- Ein Kind kann nicht Vorfahre seines eigenen Elternteils sein. Ohne diese
  -- Pruefung liesse sich ein Kreis anlegen, an dem jede Darstellung des
  -- Baums haengen bleibt.
  IF NEW.art = 'ELTERNTEIL' THEN
    IF EXISTS (
      WITH RECURSIVE vorfahren(person) AS (
        SELECT NEW.von
        UNION
        SELECT f.von FROM public.family_links f
          JOIN vorfahren v ON f.nach = v.person
         WHERE f.art = 'ELTERNTEIL'
      )
      SELECT 1 FROM vorfahren WHERE person = NEW.nach
    ) THEN
      RAISE EXCEPTION 'Das ergaebe einen Kreis: % ist bereits Vorfahre von %.',
        NEW.nach, NEW.von;
    END IF;
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION "public"."family_links_pruefen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."family_links_verein_setzen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN
    NEW."tenantId" := public.current_tenant();
  END IF;
  IF NEW.erfasst_von IS NULL THEN
    SELECT coalesce(u.email, auth.uid()::text) INTO NEW.erfasst_von
      FROM public.users u WHERE u.id = public.current_user_row_id();
  END IF;
  IF NEW."tenantId" IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.';
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."family_links_verein_setzen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_anfrage_zaehlen"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant();
        v_k int; v_a int;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.floky_darf() THEN
    RAISE EXCEPTION 'Floky ist fuer diesen Verein nicht gebucht oder fuer diese Rolle nicht vorgesehen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce(kontingent_monat, 300) INTO v_k
    FROM public.floky_einstellungen WHERE "tenantId" = v_verein;
  v_k := coalesce(v_k, 300);

  INSERT INTO public.floky_verbrauch AS vb ("tenantId", monat, anfragen)
  VALUES (v_verein, date_trunc('month', current_date)::date, 1)
  ON CONFLICT ("tenantId", monat) DO UPDATE SET anfragen = vb.anfragen + 1
  RETURNING vb.anfragen INTO v_a;

  IF v_a > v_k THEN
    -- Die Zeile bleibt stehen: der Versuch hat stattgefunden. Aber der
    -- Aufrufer bekommt einen Fehler und damit keine Antwort.
    RAISE EXCEPTION 'Das Kontingent fuer diesen Monat ist aufgebraucht (% von %).', v_a - 1, v_k
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN v_k - v_a;
END $$;


ALTER FUNCTION "public"."floky_anfrage_zaehlen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_darf"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.modul_aktiv('FLOKY')
     AND public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD','MEMBER','REPRESENTATIVE');
  -- Revisionsstelle und Gastvereine haben kein Konto und damit keine
  -- app_role -- sie fallen hier heraus, ohne dass es aufgezaehlt werden muss.
$$;


ALTER FUNCTION "public"."floky_darf"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_gespraech_ablegen"("p_id" "uuid", "p_archiv" boolean DEFAULT true) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  UPDATE public.floky_gespraeche
     SET archiviert = coalesce(p_archiv, true), geaendert_am = now()
   WHERE id = p_id AND "userId" = public.current_user_row_id()
     AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce(p_archiv, true);
END $$;


ALTER FUNCTION "public"."floky_gespraech_ablegen"("p_id" "uuid", "p_archiv" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_gespraech_beginnen"("p_titel" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text := public.current_user_row_id(); v_verein text := public.current_tenant();
        v_id uuid;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.floky_darf() THEN
    RAISE EXCEPTION 'Floky ist fuer diesen Verein nicht gebucht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  INSERT INTO public.floky_gespraeche ("tenantId", "userId", titel)
  VALUES (v_verein, v_ich, nullif(btrim(coalesce(p_titel,'')), ''))
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;


ALTER FUNCTION "public"."floky_gespraech_beginnen"("p_titel" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_gespraech_loeschen"("p_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  DELETE FROM public.floky_gespraeche
   WHERE id = p_id AND "userId" = public.current_user_row_id()
     AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Die Nachrichten gehen per ON DELETE CASCADE mit. Das Protokoll
  -- bleibt: was im Verein geschehen ist, loescht niemand mit seinem
  -- Gespraechsverlauf.
  RETURN true;
END $$;


ALTER FUNCTION "public"."floky_gespraech_loeschen"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_kontingent"() RETURNS TABLE("kontingent" integer, "verbraucht" integer, "uebrig" integer, "assistent_name" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH v AS (SELECT public.current_tenant() AS id),
       e AS (SELECT coalesce(f.kontingent_monat, 300) AS k,
                    coalesce(f.assistent_name, 'Floky') AS n
               FROM v LEFT JOIN public.floky_einstellungen f ON f."tenantId" = v.id),
       b AS (SELECT coalesce(sum(vb.anfragen), 0)::int AS a
               FROM v LEFT JOIN public.floky_verbrauch vb
                 ON vb."tenantId" = v.id AND vb.monat = date_trunc('month', current_date)::date)
  SELECT e.k, b.a, greatest(e.k - b.a, 0), e.n FROM e, b;
$$;


ALTER FUNCTION "public"."floky_kontingent"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_kontingent_setzen"("p_verein" "text", "p_anfragen" integer) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Ausdruecklich NUR der Betreiber. Duerfte der Verein sein eigenes
  -- Kontingent heraufsetzen, waere es keines.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber setzt das Kontingent.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_anfragen IS NULL OR p_anfragen < 0 THEN
    RAISE EXCEPTION 'Ein Kontingent kann nicht negativ sein.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.floky_einstellungen ("tenantId", kontingent_monat)
  VALUES (p_verein, p_anfragen)
  ON CONFLICT ("tenantId") DO UPDATE
    SET kontingent_monat = excluded.kontingent_monat, geaendert_am = now();
  RETURN p_anfragen;
END $$;


ALTER FUNCTION "public"."floky_kontingent_setzen"("p_verein" "text", "p_anfragen" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_nachricht_ablegen"("p_gespraech" "uuid", "p_rolle" "text", "p_text" "text", "p_werkzeuge" "text"[] DEFAULT NULL::"text"[], "p_karten" "jsonb" DEFAULT NULL::"jsonb", "p_kuerzel" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text := public.current_user_row_id(); v_id uuid; v_titel text;
BEGIN
  -- Nur in eigene Gespraeche. Ohne diese Pruefung koennte jemand mit
  -- einer fremden Kennung in ein fremdes Gespraech schreiben.
  IF NOT EXISTS (SELECT 1 FROM public.floky_gespraeche g
                  WHERE g.id = p_gespraech AND g."userId" = v_ich
                    AND g."tenantId" = public.current_tenant()) THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  INSERT INTO public.floky_nachrichten (gespraech_id, rolle, text, werkzeuge, karten, kuerzel)
  VALUES (p_gespraech, p_rolle, p_text, p_werkzeuge, p_karten, p_kuerzel)
  RETURNING id INTO v_id;

  -- Der Titel ist die erste Frage, gekuerzt. Eine Liste aus
  -- "Gespraech vom 9.10., 08:33" sagt nichts; die erste Frage schon.
  SELECT titel INTO v_titel FROM public.floky_gespraeche WHERE id = p_gespraech;
  UPDATE public.floky_gespraeche
     SET geaendert_am = now(),
         titel = CASE WHEN v_titel IS NULL AND p_rolle = 'mensch'
                      THEN left(btrim(p_text), 70) ELSE titel END
   WHERE id = p_gespraech;

  RETURN v_id;
END $$;


ALTER FUNCTION "public"."floky_nachricht_ablegen"("p_gespraech" "uuid", "p_rolle" "text", "p_text" "text", "p_werkzeuge" "text"[], "p_karten" "jsonb", "p_kuerzel" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_name_setzen"("p_name" "text", "p_du" boolean DEFAULT NULL::boolean) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_name text;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf den Namen aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  v_name := nullif(btrim(coalesce(p_name, '')), '');
  IF v_name IS NULL THEN v_name := 'Floky'; END IF;

  INSERT INTO public.floky_einstellungen AS f ("tenantId", assistent_name, anrede_du)
  VALUES (v_verein, v_name, coalesce(p_du, false))
  ON CONFLICT ("tenantId") DO UPDATE
    SET assistent_name = excluded.assistent_name,
        anrede_du      = coalesce(p_du, f.anrede_du),
        geaendert_am   = now();
  RETURN v_name;
END $$;


ALTER FUNCTION "public"."floky_name_setzen"("p_name" "text", "p_du" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_protokollieren"("p_art" "text", "p_werkzeug" "text" DEFAULT NULL::"text", "p_zusammenfassung" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL THEN RETURN; END IF;
  INSERT INTO public.floky_protokoll ("tenantId", "userId", rolle, art, werkzeug, zusammenfassung)
  VALUES (v_verein, public.current_user_row_id(), public.app_role(),
          p_art, p_werkzeug, left(coalesce(p_zusammenfassung, ''), 300));
END $$;


ALTER FUNCTION "public"."floky_protokollieren"("p_art" "text", "p_werkzeug" "text", "p_zusammenfassung" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_wochenstart_empfaenger"() RETURNS "text"[]
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT coalesce((SELECT f.wochenstart_an FROM public.floky_einstellungen f
                    WHERE f."tenantId" = public.current_tenant()), '{}'::text[]);
$$;


ALTER FUNCTION "public"."floky_wochenstart_empfaenger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_wochenstart_setzen"("p_ids" "text"[]) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_gueltig text[]; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration waehlt die Empfaenger.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Nur Personen aus DIESEM Verein, nur mit Adresse, nur Vorstand oder
  -- Verwaltung. Eine fremde id in der Liste waere eine Mail an jemanden,
  -- der mit diesem Verein nichts zu tun hat.
  SELECT coalesce(array_agg(u.id ORDER BY u."displayName"), '{}')
    INTO v_gueltig
    FROM public.users u
   WHERE u.id = ANY (coalesce(p_ids, '{}'))
     AND u."tenantId" = v_verein
     AND u.email IS NOT NULL AND u.email LIKE '%@%'
     AND u.role IN ('BOARD','ADMIN','SUPER_ADMIN');

  INSERT INTO public.floky_einstellungen AS f ("tenantId", wochenstart_an)
  VALUES (v_verein, v_gueltig)
  ON CONFLICT ("tenantId") DO UPDATE
    SET wochenstart_an = excluded.wochenstart_an, geaendert_am = now();

  v_n := coalesce(array_length(v_gueltig, 1), 0);
  RETURN v_n;
END $$;


ALTER FUNCTION "public"."floky_wochenstart_setzen"("p_ids" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."floky_wochenstart_waehlbar"() RETURNS TABLE("id" "text", "name" "text", "email" "text", "rolle" "text", "ausgewaehlt" boolean)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT u.id, u."displayName", u.email, u.role,
         u.id = ANY (public.floky_wochenstart_empfaenger())
    FROM public.users u
   WHERE u."tenantId" = public.current_tenant()
     AND u.email IS NOT NULL AND u.email LIKE '%@%'
     AND u.role IN ('BOARD','ADMIN','SUPER_ADMIN')
   ORDER BY u.role, u."displayName";
$$;


ALTER FUNCTION "public"."floky_wochenstart_waehlbar"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."geschlossenes_jahr_schuetzen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_zeile record;
  v_jahr int;
BEGIN
  v_zeile := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  v_jahr := substr(v_zeile.date, 1, 4)::int;

  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId" = v_zeile."tenantId" AND year = v_jahr AND status = 'CLOSED') THEN
    RAISE EXCEPTION
      'Das Geschaeftsjahr % ist abgeschlossen. Buchungen koennen nicht mehr geaendert werden.', v_jahr
      USING ERRCODE = 'restrict_violation';
  END IF;

  -- Bei einer Aenderung zaehlt auch das ALTE Jahr: sonst liesse sich eine
  -- Buchung aus einem geschlossenen Jahr herausdatieren und damit doch
  -- noch anfassen.
  IF TG_OP = 'UPDATE' AND substr(OLD.date,1,4) <> substr(NEW.date,1,4) THEN
    IF EXISTS (SELECT 1 FROM public.fiscal_years
                WHERE "tenantId" = OLD."tenantId"
                  AND year = substr(OLD.date,1,4)::int AND status = 'CLOSED') THEN
      RAISE EXCEPTION
        'Die Buchung gehoert ins abgeschlossene Jahr %. Sie laesst sich nicht umdatieren.',
        substr(OLD.date,1,4) USING ERRCODE = 'restrict_violation';
    END IF;
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;


ALTER FUNCTION "public"."geschlossenes_jahr_schuetzen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."haushalt_vorschlaege"() RETURNS TABLE("strasse" "text", "plz" "text", "ort" "text", "anzahl" bigint, "nachbarschaft" "text", "personen" "jsonb", "schon_verknuepft" boolean)
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  WITH haushalte AS (
    SELECT btrim(u.street) AS s, btrim(u.zip) AS z, btrim(u.city) AS o,
           count(*) AS n,
           min(coalesce(nb.name, '')) AS nachb,
           jsonb_agg(jsonb_build_object(
             'id', u.id, 'name', u."displayName",
             'nachname', u."lastName", 'geburtsdatum', u.birthdate)
             ORDER BY u."displayName") AS leute,
           array_agg(u.id) AS ids
      FROM public.users u
      LEFT JOIN public.neighborhoods nb ON nb.id = u."neighborhoodId"
     WHERE coalesce(btrim(u.street),'') <> '' AND coalesce(btrim(u.zip),'') <> ''
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
     GROUP BY 1,2,3 HAVING count(*) > 1
  )
  SELECT h.s, h.z, h.o, h.n, h.nachb, h.leute,
         EXISTS (SELECT 1 FROM public.family_links f
                  WHERE f.von = ANY(h.ids) AND f.nach = ANY(h.ids))
    FROM haushalte h
   ORDER BY h.n DESC, h.s;
END $$;


ALTER FUNCTION "public"."haushalt_vorschlaege"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE v_treffen uuid; v_ab date; v_bis date;
BEGIN
  SELECT te.treffen_id, t.datum, d.gueltig_bis
    INTO v_treffen, v_ab, v_bis
    FROM public.treffen_delegation d
    JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
    JOIN public.treffen t ON t.id = te.treffen_id
   WHERE d.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  IF v_treffen IS NULL OR v_bis IS NULL THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF current_date < v_ab THEN
    RAISE EXCEPTION 'Das Heft gibt es ab dem %.', to_char(v_ab,'DD.MM.YYYY');
  END IF;
  RETURN public.treffen_heft_inhalt(v_treffen);
END $$;


ALTER FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."herkunft_vermerken"("p_ip" "text") RETURNS TABLE("r_ip" "text", "r_anzahl" integer, "r_zuerst" timestamp with time zone, "r_zuletzt" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF p_ip IS NULL OR btrim(p_ip) = '' THEN
    RAISE EXCEPTION 'Keine Adresse uebergeben.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.versand_herkunft AS v (ip, art)
       VALUES (btrim(p_ip), CASE WHEN p_ip LIKE '%:%' THEN 'ipv6' ELSE 'ipv4' END)
  ON CONFLICT (ip) DO UPDATE
     SET zuletzt = now(), anzahl = v.anzahl + 1;

  RETURN QUERY
    SELECT v.ip, v.anzahl, v.zuerst, v.zuletzt
      FROM public.versand_herkunft v
     WHERE v.art = (CASE WHEN p_ip LIKE '%:%' THEN 'ipv6' ELSE 'ipv4' END)
     ORDER BY v.zuletzt DESC;
END $$;


ALTER FUNCTION "public"."herkunft_vermerken"("p_ip" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_member_manager"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')
$$;


ALTER FUNCTION "public"."is_member_manager"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_member_manager"() IS 'Wer Mitglieder pflegen darf: SUPER_ADMIN, ADMIN, BOARD. Siehe is_staff().';



CREATE OR REPLACE FUNCTION "public"."is_neighborhood_steward"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (SELECT 1 FROM public.my_neighborhoods())
$$;


ALTER FUNCTION "public"."is_neighborhood_steward"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_platform_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT auth.jwt() ->> 'email' IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.platform_admins
                  WHERE lower(email) = lower(auth.jwt() ->> 'email'))
$$;


ALTER FUNCTION "public"."is_platform_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_staff"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')
$$;


ALTER FUNCTION "public"."is_staff"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_staff"() IS 'Vereinsverwaltung: SUPER_ADMIN, ADMIN, BOARD.

Entscheidung vom 08.10.2026: der VORSTAND behaelt ausdruecklich
Schreibrechte auf Finanzen und Mitglieder. Das Floky-Konzept hatte sie
ihm entzogen; der Betreiber hat sich dagegen entschieden. Wer BOARD
hier herausnimmt, aendert damit praktisch jede Zeilenregel der
Datenbank -- und nicht nur die Oberflaeche.';



CREATE OR REPLACE FUNCTION "public"."jahresabschluss"("p_jahr" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein   text := public.current_tenant();
  v_naechst  int  := p_jahr + 1;
  v_ertrag   numeric := 0;
  v_aufwand  numeric := 0;
  v_gewinn   numeric;
  v_aktiva   numeric := 0;
  v_passiva  numeric := 0;
  v_differenz numeric;
  v_gebucht  int := 0;
  r RECORD;
  v_betrag numeric;
  v_soll text; v_haben text;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf abschliessen.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('BUCHHALTUNG') THEN
    RAISE EXCEPTION 'Das Modul Buchhaltung ist fuer diesen Verein nicht aktiv.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Riegel 1: schon abgeschlossen?
  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId" = v_verein AND year = p_jahr AND status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist bereits abgeschlossen.', p_jahr;
  END IF;

  -- Riegel 2: bestehen die Eroeffnungsbuchungen schon? Ein zweiter Lauf
  -- wuerde die Vortraege verdoppeln.
  IF EXISTS (SELECT 1 FROM public.accounting_journal
              WHERE "tenantId" = v_verein
                AND date = (v_naechst::text || '-01-01')
                AND "isSystemEntry") THEN
    RAISE EXCEPTION 'Fuer % bestehen bereits Eroeffnungsbuchungen.', v_naechst;
  END IF;

  -- Ergebnis und Bilanzsummen des Jahres.
  SELECT
    coalesce(sum(CASE WHEN a.class='REVENUE' THEN s.haben - s.soll END), 0),
    coalesce(sum(CASE WHEN a.class='EXPENSE' THEN s.soll - s.haben END), 0),
    coalesce(sum(CASE WHEN a.class='ASSET'   THEN s.soll - s.haben END), 0),
    coalesce(sum(CASE WHEN a.class='LIABILITY' THEN s.haben - s.soll END), 0)
  INTO v_ertrag, v_aufwand, v_aktiva, v_passiva
  FROM public.accounting_accounts a
  JOIN LATERAL (
    SELECT coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
           coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
      FROM public.accounting_journal j
     WHERE j."tenantId" = v_verein AND substr(j.date, 1, 4) = p_jahr::text
  ) s ON true
  WHERE a."tenantId" = v_verein;

  v_gewinn := v_ertrag - v_aufwand;
  v_differenz := v_aktiva - (v_passiva + v_gewinn);

  -- Riegel 3: die Bilanz muss aufgehen. Vorher war das nur ein roter
  -- Hinweis in der Oberflaeche -- abschliessen konnte man trotzdem.
  IF abs(v_differenz) > 0.05 THEN
    RAISE EXCEPTION
      'Bilanzdifferenz % CHF (Aktiven % , Passiven % , Ergebnis %). Nicht abgeschlossen.',
      round(v_differenz,2), round(v_aktiva,2), round(v_passiva,2), round(v_gewinn,2);
  END IF;

  -- Vortraege. Je Bilanzkonto eine Buchung gegen 9100.
  FOR r IN
    SELECT a.code, a.class,
           CASE WHEN a.class='ASSET' THEN s.soll - s.haben ELSE s.haben - s.soll END
             + CASE WHEN a.code = '2900' THEN v_gewinn ELSE 0 END AS saldo
      FROM public.accounting_accounts a
      JOIN LATERAL (
        SELECT coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
               coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
          FROM public.accounting_journal j
         WHERE j."tenantId" = v_verein AND substr(j.date, 1, 4) = p_jahr::text
      ) s ON true
     WHERE a."tenantId" = v_verein AND a.class IN ('ASSET','LIABILITY')
       AND a.code <> '9100'       -- das Vortragskonto traegt sich nicht selbst vor
  LOOP
    CONTINUE WHEN abs(r.saldo) <= 0.005;

    -- Richtung aus dem VORZEICHEN, nicht aus der Kontoklasse allein. Ein
    -- ueberzogenes Bankkonto hat als Aktivum einen negativen Saldo; vorher
    -- wurde daraus eine Buchung ueber einen negativen Betrag.
    v_betrag := abs(r.saldo);
    IF (r.class = 'ASSET') = (r.saldo > 0) THEN
      v_soll := r.code; v_haben := '9100';
    ELSE
      v_soll := '9100'; v_haben := r.code;
    END IF;
    -- KEIN zusaetzlicher Tausch fuer Passivkonten. Die Bedingung oben
    -- deckt alle vier Faelle bereits ab; ein Tausch danach drehte die
    -- Passivseite wieder falsch herum. Durchgerechnet:
    --   Aktiv  +  -> Soll Konto / Haben 9100
    --   Aktiv  -  -> Soll 9100  / Haben Konto
    --   Passiv +  -> Soll 9100  / Haben Konto
    --   Passiv -  -> Soll Konto / Haben 9100

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "createdAt", "isSystemEntry")
    VALUES (gen_random_uuid()::text, v_verein, v_naechst::text || '-01-01',
            'Eröffnungsbilanz (Vortrag aus ' || p_jahr || ')',
            v_soll, v_haben, v_betrag, now(), true);
    v_gebucht := v_gebucht + 1;
  END LOOP;

  -- Erst jetzt den Abschluss vermerken. In einer Transaktion ist die
  -- Reihenfolge zwar gleichgueltig -- aber sie sagt, was gemeint ist.
  INSERT INTO public.fiscal_years (id, "tenantId", year, status, "closedAt", "netProfit")
  VALUES (p_jahr::text, v_verein, p_jahr, 'CLOSED', now()::text, v_gewinn)
  ON CONFLICT ("tenantId", id) DO UPDATE
    SET status = 'CLOSED', "closedAt" = now()::text, "netProfit" = v_gewinn;

  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  VALUES (v_naechst::text, v_verein, v_naechst, 'OPEN')
  ON CONFLICT ("tenantId", id) DO NOTHING;

  RETURN jsonb_build_object(
    'jahr', p_jahr, 'ertrag', round(v_ertrag,2), 'aufwand', round(v_aufwand,2),
    'ergebnis', round(v_gewinn,2), 'aktiven', round(v_aktiva,2),
    'passiven', round(v_passiva,2), 'vortraege', v_gebucht);
END $$;


ALTER FUNCTION "public"."jahresabschluss"("p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."jahresrechnung_betrag"("p_verein" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_grund numeric;
  v_frei  boolean;
  v_posten jsonb;
  v_summe numeric;
BEGIN
  IF NOT (public.is_platform_admin() OR p_verein = public.current_tenant()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT coalesce(t."annualFee", 0), coalesce(t.alle_module_frei, false)
    INTO v_grund, v_frei
    FROM public.tenants t WHERE t.id = p_verein;
  IF v_grund IS NULL THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein USING ERRCODE='check_violation';
  END IF;

  IF v_frei THEN
    RETURN jsonb_build_object('grundpreis', v_grund, 'module', '[]'::jsonb,
                              'modulsumme', 0, 'summe', v_grund, 'alles_frei', true);
  END IF;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'schluessel', m.schluessel, 'name', m.name_de,
           'monat', m.preis_monat, 'jahr', round(m.preis_monat * 12, 2))
         ORDER BY m.reihenfolge), '[]'::jsonb),
         coalesce(sum(round(m.preis_monat * 12, 2)), 0)
    INTO v_posten, v_summe
    FROM public.tenant_modules tm
    JOIN public.modules m ON m.schluessel = tm.modul
   WHERE tm."tenantId" = p_verein
     AND tm.zustand = 'AN'
     AND NOT m.ist_kern
     AND coalesce(m.preis_monat, 0) > 0;

  RETURN jsonb_build_object('grundpreis', v_grund, 'module', v_posten,
                            'modulsumme', v_summe, 'summe', v_grund + v_summe,
                            'alles_frei', false);
END $$;


ALTER FUNCTION "public"."jahresrechnung_betrag"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."konten_ohne_verbindung"() RETURNS TABLE("r_email" "text", "r_mitglied" "text", "r_name" "text", "r_rolle" "text", "r_konto_da" boolean, "r_konto_bestaetigt" boolean, "r_grund" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN QUERY
  SELECT coalesce(u.email, a.email),
         u.id,
         coalesce(u."displayName", u.email, '—'),
         coalesce(u.role, '—'),
         a.id IS NOT NULL,
         a.email_confirmed_at IS NOT NULL,
         CASE
           WHEN u.id IS NULL THEN 'Konto ohne Mitgliedseintrag'
           WHEN a.id IS NULL THEN 'noch kein Anmeldekonto'
           WHEN a.email_confirmed_at IS NULL THEN 'Konto nicht bestätigt'
           WHEN coalesce(u.role,'MEMBER') NOT IN ('MEMBER','GUEST')
             THEN 'bevorrechtigte Rolle — muss verbunden werden'
           ELSE 'wird bei der nächsten Anmeldung selbst verbunden'
         END
    FROM auth.users a
    FULL JOIN public.users u
      ON lower(u.email) = lower(a.email)
     AND (public.is_platform_admin() OR u."tenantId" = public.current_tenant())
   WHERE a.id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.users x
                      WHERE x."authUserId" = a.id::text OR x.id = a.id::text)
   ORDER BY 7, 1;
END $$;


ALTER FUNCTION "public"."konten_ohne_verbindung"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."kontenplan_anlegen"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_vorher int;
  v_nachher int;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf den Kontenplan anlegen.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT count(*) INTO v_vorher FROM public.accounting_accounts WHERE "tenantId"=v_verein;

  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category, "systemAccount")
  SELECT k.code, v_verein, k.code, k.name, k.klasse, k.gruppe, k.system
    FROM (VALUES
      ('1000','Kasse CHF','ASSET','Flüssige Mittel',false),
      ('1001','Kasse EUR','ASSET','Flüssige Mittel',false),
      ('1020','Bank','ASSET','Flüssige Mittel',true),
      ('1021','PayPal','ASSET','Flüssige Mittel',false),
      ('1100','Forderungen (Mitglieder)','ASSET','Forderungen',false),
      ('1500','Mobile Sachanlagen','ASSET','Anlagevermögen',false),
      ('2000','Kreditoren (VLL)','LIABILITY','Kurzfr. Fremdkapital',false),
      ('2200','Übrige kurzfr. Verbindlichkeiten','LIABILITY','Kurzfr. Fremdkapital',false),
      ('2900','Vereinsvermögen (Eigenkapital)','LIABILITY','Eigenkapital',false),
      ('9100','Eröffnungsbilanz (Vortragskonto)','LIABILITY','Eigenkapital',true),
      ('3000','Mitgliederbeiträge','REVENUE','Betrieblicher Ertrag',false),
      ('3200','Dienstleistungserlöse','REVENUE','Betrieblicher Ertrag',false),
      ('3400','Spenden / Zuwendungen','REVENUE','Betrieblicher Ertrag',false),
      ('3600','Erträge aus Veranstaltungen','REVENUE','Betrieblicher Ertrag',false),
      ('3805','Verluste aus Forderungen','EXPENSE','Erlösminderungen',false),
      ('4000','Materialaufwand','EXPENSE','Materialaufwand',false),
      ('6000','Raumaufwand','EXPENSE','Betriebsaufwand',false),
      ('6200','Fahrzeuge / Transport','EXPENSE','Betriebsaufwand',false),
      ('6500','Informatik & Admin','EXPENSE','Verwaltungsaufwand',false),
      ('6570','Porti & Gebühren','EXPENSE','Verwaltungsaufwand',false),
      ('6700','Werbung & PR','EXPENSE','Werbeaufwand',false),
      ('6900','Bankspesen','EXPENSE','Finanzaufwand',false),
      ('6950','Abschreibungen','EXPENSE','Abschreibungen',false)
    ) AS k(code, name, klasse, gruppe, system)
  -- Der Konflikt gehoert auf den KONTOCODE, nicht auf die Kennung.
  --
  -- Koretinis Konten tragen gemischte Kennungen: teils 'acc-1000', teils
  -- '1001'. Mit ON CONFLICT auf (tenantId, id) haette der Einfuegeversuch
  -- fuer Code 1000 die bestehende Zeile 'acc-1000' nicht erkannt -- und
  -- waere am eindeutigen Index accounting_accounts_code_je_verein
  -- gescheitert. Die ganze Funktion haette dort einen Fehler geworfen.
  --
  -- Der Code ist ohnehin der fachliche Schluessel: darauf zeigen die
  -- Fremdschluessel aus accounting_journal und expenses.
  ON CONFLICT ("tenantId", code) DO NOTHING;

  SELECT count(*) INTO v_nachher FROM public.accounting_accounts WHERE "tenantId"=v_verein;
  RETURN jsonb_build_object('vorher', v_vorher, 'nachher', v_nachher,
                            'ergaenzt', v_nachher - v_vorher);
END $$;


ALTER FUNCTION "public"."kontenplan_anlegen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."konto_verbinden"("p_member" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  m record;
  v_sub text;
  v_belegt text;
  v_n int;
BEGIN
  -- Nur die Administration. Wer Konten verbinden kann, kann einer Zeile
  -- mit Vorstandsrechten ein beliebiges Konto anhaengen -- das ist
  -- dasselbe wie Rechte vergeben.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf Konten verbinden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO m FROM public.users WHERE id = p_member;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.is_platform_admin() AND m."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF m."authUserId" IS NOT NULL THEN
    RETURN jsonb_build_object('verbunden', false, 'grund', 'bereits verbunden');
  END IF;
  IF coalesce(btrim(m.email), '') = '' THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'keine E-Mail-Adresse hinterlegt — ohne sie gibt es kein Konto');
  END IF;

  -- Das Konto wird ueber die Adresse gefunden, nicht uebergeben. Ein
  -- Aufrufer, der die Kontokennung mitschicken koennte, koennte ein
  -- fremdes Konto anhaengen.
  SELECT a.id::text INTO v_sub FROM auth.users a
   WHERE lower(a.email) = lower(btrim(m.email))
   ORDER BY a.created_at LIMIT 1;

  IF v_sub IS NULL THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'zu dieser Adresse gibt es noch kein Anmeldekonto — die Person '
            || 'muss sich zuerst registrieren, oder Sie setzen ein Passwort');
  END IF;

  -- Haengt dieses Konto schon an einer anderen Zeile DESSELBEN Vereins,
  -- waere die Verbindung nicht mehr eindeutig. Ueber Vereine hinweg ist
  -- es erlaubt -- eine Person darf in mehreren Vereinen Mitglied sein.
  SELECT x.id INTO v_belegt FROM public.users x
   WHERE x."authUserId" = v_sub AND x."tenantId" = m."tenantId" AND x.id <> m.id
   LIMIT 1;
  IF v_belegt IS NOT NULL THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'dieses Konto haengt in diesem Verein schon an ' || v_belegt);
  END IF;

  UPDATE public.users SET "authUserId" = v_sub WHERE id = m.id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend nichts verbunden waere.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Verbindung wurde nicht gespeichert.' USING ERRCODE = 'check_violation';
  END IF;

  -- Festhalten, wer das getan hat. Eine Kontoverbindung vergibt
  -- faktisch Rechte; sie gehoert ins Protokoll.
  BEGIN
    INSERT INTO public.security_logs ("tenantId", art, beschreibung, "memberId")
    VALUES (m."tenantId", 'KONTO_VERBUNDEN',
            'Konto zu ' || m.email || ' verbunden durch '
              || coalesce(public.current_user_row_id(), 'Betreiber'), m.id);
  EXCEPTION WHEN undefined_column OR undefined_table THEN
    -- Das Protokoll hat in aelteren Staenden andere Spalten. Die
    -- Verbindung soll nicht daran scheitern; sie ist das Wesentliche.
    NULL;
  END;

  RETURN jsonb_build_object('verbunden', true, 'mitglied', m.id,
                            'name', coalesce(m."displayName", m.email));
END $$;


ALTER FUNCTION "public"."konto_verbinden"("p_member" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mail_einstellungen_lesen"("p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("verein" "text", "host" "text", "port" integer, "benutzer" "text", "absender" "text", "absendername" "text", "tls" "text", "aktiv" boolean, "kennwort_gesetzt" boolean, "geaendert_am" timestamp with time zone, "geaendert_von" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ziel text; v_eigen text := public.current_tenant();
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge einsehen.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang einsehen.';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen,
                       CASE WHEN public.is_platform_admin() THEN 'plattform' END);
  END IF;

  RETURN QUERY
    SELECT m."tenantId", m.host, m.port, m.benutzer, m.absender, m.absendername,
           m.tls, m.aktiv, coalesce(btrim(m.kennwort), '') <> '',
           m.geaendert_am, m.geaendert_von
      FROM public.mail_settings m
     WHERE m."tenantId" = v_ziel;
END $$;


ALTER FUNCTION "public"."mail_einstellungen_lesen"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mail_einstellungen_speichern"("p_host" "text", "p_port" integer, "p_benutzer" "text", "p_absender" "text", "p_absendername" "text", "p_tls" "text", "p_aktiv" boolean, "p_kennwort" "text" DEFAULT NULL::"text", "p_verein" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE v_ziel text; v_wer text; v_eigen text := public.current_tenant();
BEGIN
  -- Der Postausgang laeuft zentral ueber unityhub. Ein Verein traegt
  -- keinen eigenen mehr ein -- und kann es auch nicht, denn eine
  -- Oberflaeche, die etwas verbirgt, ist keine Berechtigung.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Der Postausgang laeuft zentral ueber unityhub. Ein eigener Postausgang je Verein wird nicht mehr verwendet.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  p_verein := 'plattform';
  -- Der Postausgang laeuft zentral ueber unityhub. Ein Verein traegt
  -- keinen eigenen mehr ein -- und kann es auch nicht, denn eine
  -- Oberflaeche, die etwas verbirgt, ist keine Berechtigung.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Der Postausgang laeuft zentral ueber unityhub. Ein eigener Postausgang je Verein wird nicht mehr verwendet.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  p_verein := 'plattform';
  -- Der Postausgang laeuft zentral ueber unityhub. Ein Verein traegt
  -- keinen eigenen mehr ein -- und kann es auch nicht, denn eine
  -- Oberflaeche, die etwas verbirgt, ist keine Berechtigung.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Der Postausgang laeuft zentral ueber unityhub. Ein eigener Postausgang je Verein wird nicht mehr verwendet.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  p_verein := 'plattform';
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge aendern.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen,
                       CASE WHEN public.is_platform_admin() THEN 'plattform' END);
  END IF;
  IF v_ziel IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.';
  END IF;
  IF coalesce(p_tls,'') NOT IN ('starttls','tls','keine') THEN
    RAISE EXCEPTION 'Verschluesselung muss starttls, tls oder keine sein.';
  END IF;
  IF coalesce(btrim(p_absender),'') <> '' AND p_absender !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Die Absenderadresse ist keine gueltige E-Mail-Adresse.';
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.mail_settings AS m
         ("tenantId", host, port, benutzer, absender, absendername, tls, aktiv,
          kennwort, geaendert_am, geaendert_von)
  VALUES (v_ziel, nullif(btrim(p_host),''), coalesce(p_port, 587),
          nullif(btrim(p_benutzer),''), nullif(btrim(p_absender),''),
          nullif(btrim(p_absendername),''), p_tls, coalesce(p_aktiv, true),
          nullif(btrim(p_kennwort),''), now(), v_wer)
  ON CONFLICT ("tenantId") DO UPDATE SET
    host = excluded.host, port = excluded.port, benutzer = excluded.benutzer,
    absender = excluded.absender, absendername = excluded.absendername,
    tls = excluded.tls, aktiv = excluded.aktiv,
    kennwort = coalesce(excluded.kennwort, m.kennwort),
    geaendert_am = now(), geaendert_von = excluded.geaendert_von;

  RETURN 'gespeichert fuer ' || v_ziel;
END $_$;


ALTER FUNCTION "public"."mail_einstellungen_speichern"("p_host" "text", "p_port" integer, "p_benutzer" "text", "p_absender" "text", "p_absendername" "text", "p_tls" "text", "p_aktiv" boolean, "p_kennwort" "text", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mail_kennwort_loeschen"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
  END IF;
  UPDATE public.mail_settings SET kennwort = NULL, geaendert_am = now()
   WHERE "tenantId" = v_verein;
  RETURN 'geloescht';
END $$;


ALTER FUNCTION "public"."mail_kennwort_loeschen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_payment_paid"("p_payment" "text", "p_method" "text" DEFAULT NULL::"text", "p_paid_on" "date" DEFAULT NULL::"date", "p_betrag" numeric DEFAULT NULL::numeric) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE r record; v_offen numeric;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Zahlung buchen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ohne Betragsangabe: den noch offenen Rest. Das ist die bisherige
  -- Bedeutung von "als bezahlt buchen" und bleibt bei einer Zahlung
  -- ohne Eingaenge genau der Rechnungsbetrag.
  v_offen := coalesce(p_betrag, r.amount - coalesce(r.bezahlt, 0));
  IF v_offen = 0 THEN
    RETURN true;   -- schon gedeckt, nichts zu tun
  END IF;

  PERFORM public.zahlung_eingang_erfassen(
    p_payment, v_offen, coalesce(p_method, r.method), p_paid_on, NULL);
  RETURN true;
END $$;


ALTER FUNCTION "public"."mark_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_betrag" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."marktplatz_uebersicht"("p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("schluessel" "text", "name" "text", "beschreibung" "text", "ist_kern" boolean, "status" "text", "braucht_einrichtung" boolean, "preis_monat" numeric, "preis_einmalig" numeric, "zustand" "text", "testet_bis" "date", "seit" timestamp with time zone, "aktiv" boolean, "frei_fuer_verein" boolean, "reihenfolge" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ziel text; v_eigen text := public.current_tenant();
        v_sprache text := coalesce(nullif(current_setting('request.headers', true)::json ->> 'accept-language',''), 'de');
        v_frei boolean;
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Vereine einsehen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Marktplatz einsehen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen);
  END IF;
  IF v_ziel IS NULL THEN RETURN; END IF;

  SELECT t.alle_module_frei INTO v_frei FROM public.tenants t WHERE t.id = v_ziel;

  RETURN QUERY
  SELECT m.schluessel,
         CASE WHEN v_sprache LIKE 'sq%' THEN m.name_sq
              WHEN v_sprache LIKE 'en%' THEN m.name_en ELSE m.name_de END,
         CASE WHEN v_sprache LIKE 'sq%' THEN m.beschreibung_sq
              WHEN v_sprache LIKE 'en%' THEN m.beschreibung_en ELSE m.beschreibung_de END,
         m.ist_kern, m.status, m.braucht_einrichtung,
         m.preis_monat, m.preis_einmalig,
         coalesce(tm.zustand, CASE WHEN m.ist_kern THEN 'AN' ELSE 'AUS' END),
         tm.testet_bis, tm.seit,
         -- Genau die Rechnung, die auch die Zeilenregeln anstellen.
         (coalesce(v_frei, false)
          OR m.ist_kern
          OR (tm.zustand IN ('AN','TESTPHASE')
              AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date))),
         coalesce(v_frei, false),
         m.reihenfolge
    FROM public.modules m
    LEFT JOIN public.tenant_modules tm
      ON tm.modul = m.schluessel AND tm."tenantId" = v_ziel
   WHERE m.status <> 'EINGESTELLT' OR tm.zustand IS NOT NULL
   ORDER BY m.reihenfolge;
END $$;


ALTER FUNCTION "public"."marktplatz_uebersicht"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mitglied_melden"("p_member" "text", "p_art" "text", "p_bemerkung" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text := public.current_user_row_id(); v_verein text := public.current_tenant();
        v_id uuid;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE='insufficient_privilege';
  END IF;

  -- Nur ueber Mitglieder der eigenen Nachbarschaft -- und nur, wer
  -- ueberhaupt eine betreut. Die Verwaltung braucht keine Meldung, sie
  -- kann es selbst setzen.
  IF NOT EXISTS (
    SELECT 1 FROM public.users u
     WHERE u.id = p_member AND u."tenantId" = v_verein
       AND u."neighborhoodId" IN (SELECT public.my_neighborhoods())
       AND coalesce(u.role,'MEMBER') = 'MEMBER') THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  -- Zweimal dasselbe offen zu melden hilft niemandem.
  SELECT id INTO v_id FROM public.mitglied_meldungen
   WHERE "tenantId"=v_verein AND "memberId"=p_member AND art=p_art AND status='OFFEN';
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  INSERT INTO public.mitglied_meldungen ("tenantId","memberId",art,bemerkung,"reportedBy")
  VALUES (v_verein, p_member, p_art, nullif(btrim(coalesce(p_bemerkung,'')),''), v_ich)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;


ALTER FUNCTION "public"."mitglied_melden"("p_member" "text", "p_art" "text", "p_bemerkung" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mitglied_meldung_entscheiden"("p_id" "uuid", "p_uebernehmen" boolean, "p_notiz" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE r record; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung entscheidet ueber Meldungen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.mitglied_meldungen
   WHERE id = p_id AND "tenantId" = public.current_tenant() AND status = 'OFFEN';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Meldung gibt es nicht oder sie ist schon entschieden.'
      USING ERRCODE='check_violation';
  END IF;

  IF p_uebernehmen THEN
    -- Uebernommen heisst: der Vorstand setzt den Status. Nicht der
    -- Vertreter, und auch nicht dieser Ausloeser hinter dessen Ruecken.
    UPDATE public.users SET "membershipStatus" = 'INACTIVE'
     WHERE id = r."memberId" AND "tenantId" = r."tenantId";
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n = 0 THEN
      RAISE EXCEPTION 'Das Mitglied liess sich nicht aendern.' USING ERRCODE='check_violation';
    END IF;
  END IF;

  UPDATE public.mitglied_meldungen
     SET status = CASE WHEN p_uebernehmen THEN 'UEBERNOMMEN' ELSE 'ABGELEHNT' END,
         "decidedBy" = public.current_user_row_id(), "decidedAt" = now(),
         entscheidung = nullif(btrim(coalesce(p_notiz,'')),'')
   WHERE id = p_id;
  RETURN true;
END $$;


ALTER FUNCTION "public"."mitglied_meldung_entscheiden"("p_id" "uuid", "p_uebernehmen" boolean, "p_notiz" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mod10_pruefziffer"("p_ziffern" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE tabelle int[] := ARRAY[0,9,4,6,8,2,7,1,3,5];
        uebertrag int := 0; i int;
BEGIN
  FOR i IN 1..length(p_ziffern) LOOP
    uebertrag := tabelle[((uebertrag + substr(p_ziffern, i, 1)::int) % 10) + 1];
  END LOOP;
  RETURN ((10 - uebertrag) % 10)::text;
END $$;


ALTER FUNCTION "public"."mod10_pruefziffer"("p_ziffern" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mod97_pruefziffern"("p_ref" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE v text := ''; c text; i int; rest int := 0;
BEGIN
  -- Referenz + "RF00", Buchstaben als Zahlen (A=10 … Z=35).
  FOR i IN 1..length(p_ref || 'RF00') LOOP
    c := upper(substr(p_ref || 'RF00', i, 1));
    IF c ~ '[0-9]' THEN v := v || c;
    ELSIF c ~ '[A-Z]' THEN v := v || (ascii(c) - 55)::text;
    END IF;
  END LOOP;
  -- Stueckweise rechnen: die Zahl ist zu gross fuer bigint.
  FOR i IN 1..length(v) LOOP
    rest := (rest * 10 + substr(v, i, 1)::int) % 97;
  END LOOP;
  RETURN lpad((98 - rest)::text, 2, '0');
END $$;


ALTER FUNCTION "public"."mod97_pruefziffern"("p_ref" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."modul_aktiv"("p_modul" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH v AS (SELECT COALESCE(public.current_tenant(), public.request_tenant()) AS verein)
  SELECT COALESCE(
    (SELECT true FROM public.tenants t, v WHERE t.id = v.verein AND t.alle_module_frei),
    (SELECT true FROM public.modules m WHERE m.schluessel = p_modul AND m.ist_kern),
    (SELECT tm.zustand IN ('AN','TESTPHASE')
       AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date)
       FROM public.tenant_modules tm, v
      WHERE tm."tenantId" = v.verein AND tm.modul = p_modul),
    false);
$$;


ALTER FUNCTION "public"."modul_aktiv"("p_modul" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."modul_katalog_speichern"("p_schluessel" "text", "p_preis_monat" numeric DEFAULT NULL::numeric, "p_preis_einmalig" numeric DEFAULT NULL::numeric, "p_status" "text" DEFAULT NULL::"text", "p_beschreibung_de" "text" DEFAULT NULL::"text", "p_beschreibung_sq" "text" DEFAULT NULL::"text", "p_beschreibung_en" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Katalog pflegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_status IS NOT NULL AND p_status NOT IN ('VERFUEGBAR','BETA','EINGESTELLT') THEN
    RAISE EXCEPTION 'Unbekannter Status: %', p_status;
  END IF;
  IF p_preis_monat IS NOT NULL AND p_preis_monat < 0 THEN
    RAISE EXCEPTION 'Ein Preis kann nicht negativ sein.';
  END IF;

  UPDATE public.modules SET
    preis_monat     = CASE WHEN p_preis_monat    IS NULL THEN preis_monat    ELSE nullif(p_preis_monat, -1) END,
    preis_einmalig  = CASE WHEN p_preis_einmalig IS NULL THEN preis_einmalig ELSE nullif(p_preis_einmalig, -1) END,
    status          = coalesce(p_status, status),
    beschreibung_de = coalesce(p_beschreibung_de, beschreibung_de),
    beschreibung_sq = coalesce(p_beschreibung_sq, beschreibung_sq),
    beschreibung_en = coalesce(p_beschreibung_en, beschreibung_en)
  WHERE schluessel = p_schluessel;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN RAISE EXCEPTION 'Unbekanntes Modul: %', p_schluessel; END IF;
  RETURN p_schluessel;
END $$;


ALTER FUNCTION "public"."modul_katalog_speichern"("p_schluessel" "text", "p_preis_monat" numeric, "p_preis_einmalig" numeric, "p_status" "text", "p_beschreibung_de" "text", "p_beschreibung_sq" "text", "p_beschreibung_en" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."modul_umschalten"("p_modul" "text", "p_zustand" "text", "p_verein" "text" DEFAULT NULL::"text", "p_testet_bis" "date" DEFAULT NULL::"date") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_kern boolean; v_status text; v_wer text;
        v_betreiber boolean := public.is_platform_admin();
        v_eigen text := public.current_tenant();
        v_ziel text := coalesce(p_verein, public.current_tenant());
        v_bisher text;
BEGIN
  IF v_ziel IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT ist_kern, status INTO v_kern, v_status
    FROM public.modules WHERE schluessel = p_modul;
  IF v_kern IS NULL THEN RAISE EXCEPTION 'Unbekanntes Modul: %', p_modul; END IF;
  IF p_zustand NOT IN ('AN','AUS','TESTPHASE','GESPERRT') THEN
    RAISE EXCEPTION 'Unbekannter Zustand: %', p_zustand;
  END IF;
  IF v_kern AND p_zustand <> 'AN' THEN
    RAISE EXCEPTION 'Kernmodule lassen sich nicht abschalten.' USING ERRCODE='check_violation';
  END IF;

  SELECT zustand INTO v_bisher FROM public.tenant_modules
   WHERE "tenantId" = v_ziel AND modul = p_modul;

  IF NOT v_betreiber THEN
    IF v_ziel IS DISTINCT FROM v_eigen THEN
      RAISE EXCEPTION 'Nur der eigene Verein.' USING ERRCODE='insufficient_privilege';
    END IF;
    IF public.app_role() NOT IN ('SUPER_ADMIN','ADMIN') THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf Module buchen.'
        USING ERRCODE='insufficient_privilege';
    END IF;
    IF p_zustand = 'GESPERRT' OR v_bisher = 'GESPERRT' THEN
      RAISE EXCEPTION 'Dieses Modul ist gesperrt. Bitte wenden Sie sich an den Betreiber.'
        USING ERRCODE='insufficient_privilege';
    END IF;
    IF p_zustand = 'TESTPHASE' THEN
      RAISE EXCEPTION 'Eine Testphase vergibt der Betreiber.' USING ERRCODE='insufficient_privilege';
    END IF;
    IF v_status = 'EINGESTELLT' THEN
      RAISE EXCEPTION 'Dieses Modul ist noch nicht verfuegbar.' USING ERRCODE='check_violation';
    END IF;
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand, testet_bis, seit, geaendert_von)
  VALUES (v_ziel, p_modul, p_zustand,
          CASE WHEN v_betreiber THEN p_testet_bis ELSE NULL END, now(), v_wer)
  ON CONFLICT ("tenantId", modul) DO UPDATE SET
    zustand = excluded.zustand,
    testet_bis = CASE WHEN v_betreiber THEN excluded.testet_bis
                      ELSE public.tenant_modules.testet_bis END,
    seit = now(), geaendert_von = excluded.geaendert_von;

  RETURN p_modul || ' -> ' || p_zustand;
END $$;


ALTER FUNCTION "public"."modul_umschalten"("p_modul" "text", "p_zustand" "text", "p_verein" "text", "p_testet_bis" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."modul_verbreitung"() RETURNS TABLE("schluessel" "text", "name" "text", "status" "text", "ist_kern" boolean, "preis_monat" numeric, "vereine_an" bigint, "vereine_gesperrt" bigint, "vereine_gesamt" bigint, "reihenfolge" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT m.schluessel, m.name_de, m.status, m.ist_kern, m.preis_monat,
         count(*) FILTER (WHERE tm.zustand IN ('AN','TESTPHASE') OR m.ist_kern OR t.alle_module_frei),
         count(*) FILTER (WHERE tm.zustand = 'GESPERRT'),
         (SELECT count(*) FROM public.tenants),
         m.reihenfolge
    FROM public.modules m
    CROSS JOIN public.tenants t
    LEFT JOIN public.tenant_modules tm
      ON tm.modul = m.schluessel AND tm."tenantId" = t.id
   GROUP BY m.schluessel, m.name_de, m.status, m.ist_kern, m.preis_monat, m.reihenfolge
   ORDER BY m.reihenfolge;
END $$;


ALTER FUNCTION "public"."modul_verbreitung"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."module_oeffentlich"() RETURNS TABLE("schluessel" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT m.schluessel FROM public.modules m
   WHERE m.status <> 'EINGESTELLT'
     AND public.modul_aktiv(m.schluessel)
   ORDER BY m.reihenfolge;
$$;


ALTER FUNCTION "public"."module_oeffentlich"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."my_neighborhood_contacts"() RETURNS TABLE("id" "text", "displayName" "text", "phone" "text", "email" "text", "neighborhoodId" "text", "neighborhoodName" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH meine AS (
    SELECT u."neighborhoodId" AS nb
      FROM public.users u
     WHERE u.id = public.current_user_row_id()
  )
  SELECT k.id, k."displayName", k.phone, k.email, n.id, n.name
    FROM public.neighborhoods n
    JOIN meine m ON m.nb = n.id
    JOIN public.users k
      ON k.id IN (
           SELECT jsonb_array_elements_text(n."contactPersonIds")
            WHERE n."contactPersonIds" IS NOT NULL
         )
      OR k.id = n."representativeId"
      OR k.id = n."managerId"
   WHERE k."tenantId" = n."tenantId"
$$;


ALTER FUNCTION "public"."my_neighborhood_contacts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."my_neighborhoods"() RETURNS TABLE("id" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT n.id
    FROM public.neighborhoods n
   WHERE public.current_user_row_id() IS NOT NULL
     AND n."tenantId" = public.current_tenant()
     AND (
          (n."contactPersonIds" IS NOT NULL
             AND n."contactPersonIds" @> to_jsonb(public.current_user_row_id()))
       OR n."representativeId" = public.current_user_row_id()
       OR n."managerId"        = public.current_user_row_id()
     )
  UNION
  -- Nur zum Vorfuehren: der Betreiber im Demo-Verein.
  SELECT n.id
    FROM public.neighborhoods n
   WHERE n."tenantId" = 'demo'
     AND public.is_platform_admin()
     AND coalesce(public.current_tenant(), public.request_tenant()) = 'demo';
$$;


ALTER FUNCTION "public"."my_neighborhoods"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nachbarschaft_puls"("p_jahr" integer DEFAULT NULL::integer) RETURNS TABLE("nachbarschaft" "text", "name" "text", "mitglieder" bigint, "aktiv" bigint, "bezahlt" bigint, "offen" bigint, "ohne_rechnung" bigint, "jahr" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text := public.current_user_row_id();
        v_lagje text; v_verein text := public.current_tenant(); v_jahr integer;
BEGIN
  IF v_ich IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u."neighborhoodId" INTO v_lagje FROM public.users u WHERE u.id = v_ich;
  IF v_lagje IS NULL THEN RETURN; END IF;   -- ohne Nachbarschaft kein Puls

  v_jahr := coalesce(p_jahr, extract(year FROM current_date)::integer);

  RETURN QUERY
  WITH leute AS (
    SELECT u.id FROM public.users u
     WHERE u."neighborhoodId" = v_lagje
       AND u."tenantId" = v_verein
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
  ),
  -- Derselbe Massstab wie in lib/memberQuality.ts: massgeblich ist
  -- billingYear, ersatzweise das Jahr des Zeitstempels. Eine Rechnung gilt
  -- als bezahlt, sobald irgendeine Zahlung des Jahres auf PAID steht.
  stand AS (
    SELECT l.id,
           bool_or(p.status = 'PAID') AS hat_bezahlt,
           count(p.id) AS rechnungen
      FROM leute l
      LEFT JOIN public.payments p
        ON p."userId" = l.id
       AND coalesce(
             nullif(p."billingYear", 0),
             extract(year FROM p."timestamp")::integer
           ) = v_jahr
     GROUP BY l.id
  )
  SELECT v_lagje, n.name,
         (SELECT count(*) FROM leute),
         (SELECT count(*) FROM public.users u
           WHERE u."neighborhoodId" = v_lagje AND u."tenantId" = v_verein
             AND u."membershipStatus" = 'ACTIVE'),
         count(*) FILTER (WHERE s.hat_bezahlt),
         count(*) FILTER (WHERE s.rechnungen > 0 AND NOT s.hat_bezahlt),
         count(*) FILTER (WHERE s.rechnungen = 0),
         v_jahr
    FROM stand s
    LEFT JOIN public.neighborhoods n ON n.id = v_lagje
   GROUP BY n.name;
END $$;


ALTER FUNCTION "public"."nachbarschaft_puls"("p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nachbarschaften_ohne_verantwortlichen"() RETURNS TABLE("r_id" "text", "r_name" "text", "r_mitglieder" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT n.id, n.name,
         (SELECT count(*)::int FROM public.users m
           WHERE m."tenantId" = n."tenantId" AND m."neighborhoodId" = n.id
             AND coalesce(m."membershipStatus",'ACTIVE') <> 'INACTIVE')
    FROM public.neighborhoods n
   WHERE n."tenantId" = public.current_tenant()
     AND coalesce(jsonb_array_length(n."contactPersonIds"), 0) = 0
     AND coalesce(btrim(n."representativeId"), '') = ''
     AND coalesce(btrim(n."managerId"), '') = ''
     AND (public.is_member_manager() OR public.is_platform_admin())
   ORDER BY 3 DESC, 2;
$$;


ALTER FUNCTION "public"."nachbarschaften_ohne_verantwortlichen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."oeffentliche_module"() RETURNS TABLE("schluessel" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT m.schluessel FROM public.modules m
   WHERE public.modul_aktiv(m.schluessel)
     AND m.status <> 'EINGESTELLT';
$$;


ALTER FUNCTION "public"."oeffentliche_module"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."payment_asset_code"("p_method" "text", "p_currency" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT CASE
    WHEN p_method = 'CASH'   THEN CASE WHEN p_currency = 'EUR' THEN '1001' ELSE '1000' END
    WHEN p_method = 'PAYPAL' THEN '1021'
    ELSE '1020'
  END
$$;


ALTER FUNCTION "public"."payment_asset_code"("p_method" "text", "p_currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pfad_belegt"("p_pfad" "text") RETURNS boolean
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT lower(btrim(coalesce(p_pfad,''))) = ANY (ARRAY[
    '', 'about', 'live', 'events', 'news', 'fussball', 'futsal', 'spenden',
    'videos', 'gdpr', 'privacy', 'login', 'register', 'dashboard', 'admin',
    'super-admin', 'nachbarschaft', 'setup-profile', 'revision', 'treffen',
    'vorstellen', 'heft', 'drucksachen', 'api', 'assets', 'static']);
$$;


ALTER FUNCTION "public"."pfad_belegt"("p_pfad" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."plattform_geheimnis_setzen"("p_schluessel" "text", "p_wert" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_schluessel NOT IN ('meta_app_id','meta_redirect_uri') THEN
    RAISE EXCEPTION 'Dieser Schluessel laesst sich hier nicht setzen: %', p_schluessel
      USING ERRCODE='check_violation';
  END IF;

  INSERT INTO public.platform_secrets (schluessel, wert)
  VALUES (p_schluessel, btrim(coalesce(p_wert,'')))
  ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert;
  RETURN 'gesetzt';
END $$;


ALTER FUNCTION "public"."plattform_geheimnis_setzen"("p_schluessel" "text", "p_wert" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."plattform_geheimnisse"() RETURNS TABLE("schluessel" "text", "wert" "text", "notiz" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT s.schluessel, s.wert, s.notiz FROM public.platform_secrets s
   WHERE public.is_platform_admin()
     AND s.schluessel IN ('meta_app_id','meta_redirect_uri');
$$;


ALTER FUNCTION "public"."plattform_geheimnisse"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_abbrechen"("p_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.darf_schreiben() OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  UPDATE public.post_ausgang
     SET zustand = 'ABGEBROCHEN', erledigt_am = now(),
         -- Das Dokument mit wegwerfen. Ein abgebrochener Brief muss
         -- nicht als base64 in der Datenbank liegenbleiben.
         pdf = ''
   WHERE id = p_id
     AND "tenantId" = public.current_tenant()
     -- Nur was noch nicht draussen ist. Ein uebergebener Brief laesst
     -- sich nicht zurueckholen, und ihn hier als abgebrochen zu fuehren
     -- waere eine Unwahrheit in der Uebersicht.
     AND zustand = 'WARTEND';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieser Brief ist nicht mehr zurueckziehbar -- er ist schon '
                    'uebergeben oder gehoert zu einem anderen Verein.'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN true;
END $$;


ALTER FUNCTION "public"."post_abbrechen"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_einkaufspreis_melden"("p_verein" "text", "p_preis" numeric, "p_waehrung" "text" DEFAULT 'CHF'::"text", "p_grundlage" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_neu numeric;
BEGIN
  IF p_preis IS NULL OR p_preis <= 0 THEN
    RAISE EXCEPTION 'Ein Einkaufspreis muss groesser als null sein.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.post_preise
    ("tenantId", einkauf_je_brief, waehrung, tarif_abgefragt_am, tarif_grundlage,
     geaendert_am, geaendert_von)
  VALUES (p_verein, p_preis, coalesce(p_waehrung,'CHF'), now(), p_grundlage,
          now(), 'Tarifabfrage')
  ON CONFLICT ("tenantId") DO UPDATE
     SET einkauf_je_brief = EXCLUDED.einkauf_je_brief,
         waehrung = EXCLUDED.waehrung,
         tarif_abgefragt_am = now(),
         tarif_grundlage = EXCLUDED.tarif_grundlage,
         geaendert_am = now(), geaendert_von = 'Tarifabfrage';

  SELECT preis_je_brief INTO v_neu FROM public.post_preise WHERE "tenantId" = p_verein;
  RETURN jsonb_build_object('verein', p_verein, 'einkauf', p_preis,
                            'verkauf', v_neu, 'grundlage', p_grundlage);
END $$;


ALTER FUNCTION "public"."post_einkaufspreis_melden"("p_verein" "text", "p_preis" numeric, "p_waehrung" "text", "p_grundlage" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_einreihen"("p_payment" "text", "p_dateiname" "text", "p_pdf" "text", "p_produkt" "text" DEFAULT 'cheap'::"text", "p_farbe" "text" DEFAULT 'grayscale'::"text", "p_duplex" boolean DEFAULT true, "p_adresslage" "text" DEFAULT 'left'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r record; m record; v_id uuid; v_name text; v_vorhanden record;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf Post aufgeben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_pdf), '') = '' THEN
    RAISE EXCEPTION 'Ohne Dokument kein Brief.' USING ERRCODE = 'check_violation';
  END IF;

  -- Schon unterwegs? Dann nicht ein zweites Mal. Der eindeutige Index
  -- faengt es ohnehin, aber eine Meldung ist besser als ein Fehler.
  SELECT * INTO v_vorhanden FROM public.post_ausgang
   WHERE "paymentId" = p_payment AND zustand <> 'ABGEBROCHEN';
  IF FOUND THEN
    RETURN jsonb_build_object('eingereiht', false, 'zustand', v_vorhanden.zustand,
      'grund', 'Für diese Rechnung ist schon ein Brief erfasst ('
               || v_vorhanden.zustand || ').');
  END IF;

  SELECT u.* INTO m FROM public.users u WHERE u.id = r."userId";
  v_name := coalesce(
    nullif(btrim(coalesce(m."displayName", '')), ''),
    r."customRecipient" ->> 'name',
    'Unbekannt');

  INSERT INTO public.post_ausgang
    ("tenantId", "paymentId", "memberId", empfaenger, dateiname, pdf,
     produkt, farbe, duplex, adresslage)
  VALUES (r."tenantId", p_payment, m.id,
          v_name || coalesce(' · ' || nullif(btrim(coalesce(m.city,'')), ''), ''),
          left(coalesce(nullif(btrim(p_dateiname),''), 'rechnung.pdf'), 120),
          p_pdf,
          coalesce(nullif(p_produkt,''), 'cheap'),
          coalesce(nullif(p_farbe,''), 'grayscale'),
          coalesce(p_duplex, true),
          CASE WHEN lower(coalesce(p_adresslage,'')) = 'right' THEN 'right' ELSE 'left' END)
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('eingereiht', true, 'id', v_id, 'empfaenger', v_name);
END $$;


ALTER FUNCTION "public"."post_einreihen"("p_payment" "text", "p_dateiname" "text", "p_pdf" "text", "p_produkt" "text", "p_farbe" "text", "p_duplex" boolean, "p_adresslage" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_kontingent_buch"("p_grenze" integer DEFAULT 100) RETURNS TABLE("r_art" "text", "r_menge" integer, "r_preis" numeric, "r_waehrung" "text", "r_grund" "text", "r_rechnung" "text", "r_am" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT k.art, k.menge, k.preis_je_brief, k.waehrung, k.grund,
         (SELECT i."invoiceNumber" FROM public.platform_invoices i
           WHERE i.id = k."rechnungId"),
         k.erstellt_am
    FROM public.post_kontingent k
   WHERE (public.is_platform_admin()
          OR (k."tenantId" = public.current_tenant() AND public.is_member_manager()))
     AND (public.is_platform_admin() OR k."tenantId" = public.current_tenant())
   ORDER BY k.erstellt_am DESC
   LIMIT greatest(1, least(coalesce(p_grenze, 100), 500));
$$;


ALTER FUNCTION "public"."post_kontingent_buch"("p_grenze" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_kontingent_kaufen"("p_menge" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_preis numeric; v_einkauf numeric; v_waehrung text;
  v_betrag numeric; v_nummer text; v_rechnung uuid; v_id uuid;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Kaufen heisst Geld ausgeben. Das ist Sache der Administration, nicht
  -- jedes Vorstandsmitglieds.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf ein Kontingent kaufen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_menge IS NULL OR p_menge < 1 OR p_menge > 10000 THEN
    RAISE EXCEPTION 'Bitte zwischen 1 und 10000 Briefen kaufen.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = v_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')) THEN
    RAISE EXCEPTION 'Das Modul Briefversand ist fuer diesen Verein nicht aktiv.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT preis_je_brief, einkauf_je_brief, waehrung
    INTO v_preis, v_einkauf, v_waehrung
    FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_preis IS NULL OR v_preis <= 0 THEN
    RAISE EXCEPTION 'Fuer diesen Verein ist noch kein Briefpreis festgelegt. '
                    'Der Plattformbetreiber legt ihn fest.'
      USING ERRCODE = 'check_violation';
  END IF;

  v_betrag := round(v_preis * p_menge, 2);
  v_nummer := 'POST-' || to_char(now(), 'YYYYMM') || '-'
              || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 5));
  v_rechnung := gen_random_uuid();

  -- Die Rechnung von unityhub an den Verein. Dieselbe Tabelle wie bei
  -- den Treffen; eine zweite Rechnungsstelle waere eine zweite Wahrheit
  -- ueber dieselbe Forderung.
  INSERT INTO public.platform_invoices
    (id, "tenantId", kind, amount, currency, year, status, "invoiceNumber",
     "issuedAt", "dueDate", note)
  -- Zustand DRAFT, nicht 'OPEN': die Bedingung erlaubt nur DRAFT, SENT,
  -- PAID, CANCELLED. Und die Datumsfelder sind date, nicht text -- mein
  -- erster Versuch schrieb beides falsch und scheiterte mit
  -- "operator does not exist: uuid = text", also an einer dritten
  -- Stelle. Drei Annahmen ueber eine Tabelle, die ich haette nachsehen
  -- koennen.
  VALUES (v_rechnung, v_verein, 'POSTKONTINGENT', v_betrag,
          coalesce(v_waehrung, 'CHF'),
          extract(year from now())::int, 'DRAFT', v_nummer,
          current_date, current_date + 30,
          p_menge || ' Briefe à ' || v_preis || ' ' || coalesce(v_waehrung,'CHF'));

  INSERT INTO public.post_kontingent
    ("tenantId", art, menge, preis_je_brief, einkauf_je_brief, waehrung,
     "rechnungId", grund, erstellt_von)
  VALUES (v_verein, 'KAUF', p_menge, v_preis, v_einkauf, coalesce(v_waehrung,'CHF'),
          v_rechnung, 'Kontingent gekauft', public.current_user_row_id())
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('gekauft', p_menge, 'betrag', v_betrag,
    'waehrung', coalesce(v_waehrung,'CHF'), 'rechnungsnummer', v_nummer,
    'stand', (public.post_kontingent_stand() -> 'stand'));
END $$;


ALTER FUNCTION "public"."post_kontingent_kaufen"("p_menge" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_kontingent_stand"("p_verein" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text;
  v_stand int; v_gekauft int; v_verbraucht int;
  v_preis numeric; v_waehrung text; v_modul boolean;
BEGIN
  -- Der Betreiber darf nach einem Verein fragen; ein Verein sieht nur
  -- den eigenen Stand, unabhaengig davon, was er mitschickt.
  v_verein := CASE
    WHEN public.is_platform_admin() THEN coalesce(p_verein, public.current_tenant())
    WHEN public.is_member_manager() THEN public.current_tenant()
    ELSE NULL END;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce(sum(menge), 0),
         coalesce(sum(menge) FILTER (WHERE menge > 0), 0),
         coalesce(-sum(menge) FILTER (WHERE menge < 0), 0)
    INTO v_stand, v_gekauft, v_verbraucht
    FROM public.post_kontingent WHERE "tenantId" = v_verein;

  SELECT preis_je_brief, waehrung INTO v_preis, v_waehrung
    FROM public.post_preise WHERE "tenantId" = v_verein;

  SELECT EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = v_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')) INTO v_modul;

  RETURN jsonb_build_object(
    'verein', v_verein,
    'modul_aktiv', v_modul,
    'stand', v_stand,
    'gekauft', v_gekauft,
    'verbraucht', v_verbraucht,
    'preis_je_brief', v_preis,
    'waehrung', coalesce(v_waehrung, 'CHF'),
    -- Kein Preis heisst: der Betreiber hat noch keinen festgelegt. Dann
    -- kann nichts gekauft werden, und das soll dastehen statt stillem
    -- Nichtfunktionieren.
    'kaufbar', v_preis IS NOT NULL AND v_preis > 0);
END $$;


ALTER FUNCTION "public"."post_kontingent_stand"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_kontingent_verbrauchen"("p_post" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE b record; v_stand int; v_preis numeric; v_einkauf numeric;
BEGIN
  SELECT * INTO b FROM public.post_ausgang WHERE id = p_post;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Brief gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  -- Schon abgebucht? Dann nichts tun und das auch sagen. Der eindeutige
  -- Index faengt es ohnehin; eine Meldung ist besser als ein Fehler.
  IF EXISTS (SELECT 1 FROM public.post_kontingent WHERE "postId" = p_post) THEN
    RETURN jsonb_build_object('verbraucht', false, 'grund', 'bereits abgebucht');
  END IF;

  SELECT coalesce(sum(menge), 0) INTO v_stand
    FROM public.post_kontingent WHERE "tenantId" = b."tenantId";
  IF v_stand < 1 THEN
    RETURN jsonb_build_object('verbraucht', false, 'stand', v_stand,
      'grund', 'Kontingent aufgebraucht');
  END IF;

  SELECT preis_je_brief, einkauf_je_brief INTO v_preis, v_einkauf
    FROM public.post_preise WHERE "tenantId" = b."tenantId";

  INSERT INTO public.post_kontingent
    ("tenantId", art, menge, preis_je_brief, einkauf_je_brief, "postId", grund)
  VALUES (b."tenantId", 'VERBRAUCH', -1, v_preis, v_einkauf, p_post,
          'Brief an ' || left(coalesce(b.empfaenger, '?'), 80));

  RETURN jsonb_build_object('verbraucht', true, 'stand', v_stand - 1);
END $$;


ALTER FUNCTION "public"."post_kontingent_verbrauchen"("p_post" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_marge"() RETURNS TABLE("r_verein" "text", "r_name" "text", "r_gekauft" bigint, "r_verbraucht" bigint, "r_stand" bigint, "r_erloes" numeric, "r_einkauf" numeric, "r_marge" numeric, "r_preis" numeric)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT k."tenantId", coalesce(t.name, k."tenantId"),
         coalesce(sum(k.menge) FILTER (WHERE k.menge > 0), 0)::bigint,
         coalesce(-sum(k.menge) FILTER (WHERE k.menge < 0), 0)::bigint,
         coalesce(sum(k.menge), 0)::bigint,
         -- Erloes aus Kaeufen, Kosten aus VERBRAUCH: gekauft wird bei
         -- Pingen erst, wenn der Brief wirklich hinausgeht. Ein
         -- Kontingent, das niemand verbraucht, kostet uns nichts.
         coalesce(sum(k.menge * k.preis_je_brief) FILTER (WHERE k.menge > 0), 0),
         coalesce(-sum(k.menge * k.einkauf_je_brief) FILTER (WHERE k.menge < 0), 0),
         coalesce(sum(k.menge * k.preis_je_brief) FILTER (WHERE k.menge > 0), 0)
           - coalesce(-sum(k.menge * k.einkauf_je_brief) FILTER (WHERE k.menge < 0), 0),
         (SELECT p.preis_je_brief FROM public.post_preise p WHERE p."tenantId" = k."tenantId")
    FROM public.post_kontingent k
    LEFT JOIN public.tenants t ON t.id = k."tenantId"
   WHERE public.is_platform_admin()
   GROUP BY k."tenantId", t.name
   ORDER BY 8 DESC;
$$;


ALTER FUNCTION "public"."post_marge"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_preis_setzen"("p_verein" "text", "p_aufpreis" numeric DEFAULT NULL::numeric, "p_fest" numeric DEFAULT NULL::numeric) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_vorhanden boolean; v_erg record;
BEGIN
  -- Nur der Betreiber. Der Aufpreis ist sein Ertrag; ein Verein, der ihn
  -- setzen koennte, kaufte zum Selbstkostenpreis.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber legt Aufpreis und Festpreis fest.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_aufpreis IS NOT NULL AND (p_aufpreis < 0 OR p_aufpreis > 200) THEN
    RAISE EXCEPTION 'Der Aufpreis muss zwischen 0 und 200 Prozent liegen.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_fest IS NOT NULL AND p_fest <= 0 THEN
    RAISE EXCEPTION 'Ein Festpreis muss groesser als null sein; zum Loeschen NULL.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT EXISTS (SELECT 1 FROM public.post_preise WHERE "tenantId" = p_verein)
    INTO v_vorhanden;
  IF NOT v_vorhanden THEN
    INSERT INTO public.post_preise ("tenantId", aufpreis_prozent, preis_fest,
                                    geaendert_von)
    VALUES (p_verein, coalesce(p_aufpreis, 10), p_fest,
            public.current_user_row_id());
  ELSE
    UPDATE public.post_preise
       SET aufpreis_prozent = coalesce(p_aufpreis, aufpreis_prozent),
           -- Ein ausdrueckliches NULL muss den Festpreis loeschen
           -- koennen. coalesce allein liesse ihn fuer immer stehen.
           preis_fest = p_fest,
           geaendert_am = now(), geaendert_von = public.current_user_row_id()
     WHERE "tenantId" = p_verein;
  END IF;

  SELECT * INTO v_erg FROM public.post_preise WHERE "tenantId" = p_verein;
  RETURN jsonb_build_object(
    'verein', p_verein,
    'einkauf', v_erg.einkauf_je_brief,
    'aufpreis_prozent', v_erg.aufpreis_prozent,
    'preis_fest', v_erg.preis_fest,
    'preis_je_brief', v_erg.preis_je_brief,
    'tarif_abgefragt_am', v_erg.tarif_abgefragt_am,
    'tarif_grundlage', v_erg.tarif_grundlage);
END $$;


ALTER FUNCTION "public"."post_preis_setzen"("p_verein" "text", "p_aufpreis" numeric, "p_fest" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_tarife"() RETURNS TABLE("r_verein" "text", "r_name" "text", "r_einkauf" numeric, "r_aufpreis" numeric, "r_fest" numeric, "r_verkauf" numeric, "r_waehrung" "text", "r_abgefragt" timestamp with time zone, "r_grundlage" "text", "r_modul" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH beteiligte AS (
    -- Freigeschaltet, mit oder ohne Preis.
    SELECT tm."tenantId" AS id, tm.zustand AS modul
      FROM public.tenant_modules tm
     WHERE tm.modul = 'POSTVERSAND' AND tm.zustand IN ('AN','TESTPHASE')
    UNION
    -- Hat einen Preis, auch wenn das Modul inzwischen aus ist.
    SELECT p."tenantId", NULL
      FROM public.post_preise p
  ), zusammen AS (
    SELECT b.id,
           -- Bei zwei Zeilen je Verein (beide Zweige) gewinnt der
           -- Modulzustand; max() nimmt ihn, weil NULL dabei verliert.
           max(b.modul) AS modul
      FROM beteiligte b GROUP BY b.id
  )
  SELECT z.id,
         coalesce(t.name, z.id),
         p.einkauf_je_brief, p.aufpreis_prozent, p.preis_fest,
         p.preis_je_brief, coalesce(p.waehrung, 'CHF'),
         p.tarif_abgefragt_am, p.tarif_grundlage,
         coalesce(z.modul, 'AUS')
    FROM zusammen z
    LEFT JOIN public.tenants t ON t.id = z.id
    LEFT JOIN public.post_preise p ON p."tenantId" = z.id
   WHERE public.is_platform_admin()
   ORDER BY 2;
$$;


ALTER FUNCTION "public"."post_tarife"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_uebersicht"("p_grenze" integer DEFAULT 200) RETURNS TABLE("r_id" "uuid", "r_rechnung" "text", "r_empfaenger" "text", "r_zustand" "text", "r_produkt" "text", "r_pingen_id" "text", "r_status" "text", "r_meldung" "text", "r_versuche" integer, "r_fehler" "text", "r_erstellt" timestamp with time zone, "r_uebergeben" timestamp with time zone, "r_erledigt" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT p.id, p."paymentId", p.empfaenger, p.zustand, p.produkt,
         p.pingen_id, p.pingen_status, p.pingen_meldung,
         p.versuche, p.letzter_fehler, p.erstellt_am, p.uebergeben_am, p.erledigt_am
    FROM public.post_ausgang p
   WHERE (public.is_platform_admin()
          OR (p."tenantId" = public.current_tenant() AND public.is_member_manager()))
   ORDER BY p.erstellt_am DESC
   LIMIT greatest(1, least(coalesce(p_grenze, 200), 1000));
$$;


ALTER FUNCTION "public"."post_uebersicht"("p_grenze" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_zustand_melden"("p_id" "uuid" DEFAULT NULL::"uuid", "p_pingen_id" "text" DEFAULT NULL::"text", "p_zustand" "text" DEFAULT NULL::"text", "p_status" "text" DEFAULT NULL::"text", "p_meldung" "text" DEFAULT NULL::"text", "p_fehler" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int; v_id uuid;
BEGIN
  IF p_id IS NULL AND p_pingen_id IS NULL THEN
    RAISE EXCEPTION 'Ohne Kennung kein Zustand.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.post_ausgang
     SET zustand = coalesce(p_zustand, zustand),
         pingen_id = coalesce(p_pingen_id, pingen_id),
         pingen_status = coalesce(p_status, pingen_status),
         pingen_meldung = coalesce(p_meldung, pingen_meldung),
         letzter_fehler = CASE WHEN p_fehler IS NULL THEN letzter_fehler ELSE p_fehler END,
         versuche = CASE WHEN p_fehler IS NULL THEN versuche ELSE versuche + 1 END,
         -- Abstand zwischen den Versuchen, wie beim Mailversand: 10
         -- Minuten, eine Stunde, vier, zwoelf. Fuenf Versuche in fuenfzig
         -- Minuten haben dort waehrend eines wochenlangen Ausfalls sechs
         -- Mails verbrannt.
         naechster_versuch = CASE
           WHEN p_fehler IS NULL THEN naechster_versuch
           ELSE now() + (CASE versuche
                           WHEN 0 THEN interval '10 minutes'
                           WHEN 1 THEN interval '1 hour'
                           WHEN 2 THEN interval '4 hours'
                           ELSE interval '12 hours' END)
         END,
         uebergeben_am = CASE WHEN p_zustand = 'UEBERGEBEN' THEN now() ELSE uebergeben_am END,
         erledigt_am = CASE WHEN p_zustand IN ('VERSENDET','ZUGESTELLT','UNZUSTELLBAR')
                            THEN now() ELSE erledigt_am END
   WHERE (p_id IS NOT NULL AND id = p_id)
      OR (p_id IS NULL AND pingen_id = p_pingen_id)
  RETURNING id INTO v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;

  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Eine Statusmeldung zu
  -- einem Brief, den wir nicht kennen, ist aber eine Nachricht wert:
  -- sie bedeutet, dass Pingen etwas weiss, was wir nicht haben.
  RETURN jsonb_build_object('getroffen', v_n, 'id', v_id);
END $$;


ALTER FUNCTION "public"."post_zustand_melden"("p_id" "uuid", "p_pingen_id" "text", "p_zustand" "text", "p_status" "text", "p_meldung" "text", "p_fehler" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."postausgang_bereit"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT
    -- Eine brauchbare Zeile in mail_settings ...
    EXISTS (SELECT 1 FROM public.mail_settings m
             WHERE m.aktiv AND coalesce(btrim(m.kennwort), '') <> '')
    -- ... oder der Versand hat zuletzt gemeldet, dass er kann. Aelter als
    -- zwei Tage gilt nicht: ein Geheimnis kann zurueckgezogen worden sein,
    -- und eine veraltete Zusage ist schlimmer als keine.
    OR EXISTS (SELECT 1 FROM public.postausgang_zustand z
                WHERE z.bereit AND z.geprueft_am > now() - interval '2 days');
$$;


ALTER FUNCTION "public"."postausgang_bereit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."postausgang_luecken"() RETURNS TABLE("verein" "text", "offen" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nicht berechtigt.';
  END IF;
  RETURN QUERY
    SELECT q."tenantId", count(*)
      FROM public.mail_queue q
     WHERE q.status = 'PENDING'
       AND NOT EXISTS (SELECT 1 FROM public.mail_settings m
                        WHERE m."tenantId" = q."tenantId" AND m.aktiv
                          AND coalesce(btrim(m.host),'') <> ''
                          AND coalesce(btrim(m.benutzer),'') <> ''
                          AND coalesce(btrim(m.kennwort),'') <> ''
                          AND coalesce(btrim(m.absender),'') <> '')
     GROUP BY 1 ORDER BY 2 DESC;
END $$;


ALTER FUNCTION "public"."postausgang_luecken"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."postausgang_melden"("p_bereit" boolean, "p_quelle" "text", "p_fehler" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE public.postausgang_zustand
     SET bereit = coalesce(p_bereit, false), quelle = p_quelle,
         geprueft_am = now(), letzter_fehler = left(coalesce(p_fehler,''), 300)
   WHERE id;
END $$;


ALTER FUNCTION "public"."postausgang_melden"("p_bereit" boolean, "p_quelle" "text", "p_fehler" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."postausgang_stau"() RETURNS TABLE("wartend" integer, "aeltestes" timestamp with time zone, "gescheitert" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT count(*) FILTER (WHERE status = 'PENDING')::int,
         min("createdAt") FILTER (WHERE status = 'PENDING'),
         count(*) FILTER (WHERE status = 'FAILED')::int
    FROM public.mail_queue
   WHERE "tenantId" = public.current_tenant();
$$;


ALTER FUNCTION "public"."postausgang_stau"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."queue_birthday_greetings"("p_day" "date" DEFAULT NULL::"date") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_tag   date := COALESCE(p_day, current_date);
  v_jahr  int  := EXTRACT(YEAR FROM v_tag)::int;
  v_n     int  := 0;
  r       record;
  v_anrede text;
  v_html  text;
BEGIN
  -- Der taegliche Auftrag laeuft ohne Anmeldung; dann ist auth.uid() leer und
  -- die Pruefung entfaellt. Ein angemeldeter Aufrufer muss zur
  -- Geschaeftsfuehrung gehoeren.
  IF auth.uid() IS NOT NULL AND NOT (public.is_member_manager() OR public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Geburtstagsgruesse einreihen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR r IN
    SELECT u.id, u."tenantId", u.email,
           COALESCE(NULLIF(btrim(u."firstName"), ''), u."displayName") AS name,
           t.name AS verein
      FROM public.users u
      LEFT JOIN public.tenants t ON t.id = u."tenantId"
     WHERE u.birthdate IS NOT NULL
       AND btrim(u.birthdate::text) <> ''
       AND EXTRACT(MONTH FROM u.birthdate::date) = EXTRACT(MONTH FROM v_tag)
       AND EXTRACT(DAY   FROM u.birthdate::date) = EXTRACT(DAY   FROM v_tag)
       AND u.email IS NOT NULL
       AND btrim(u.email) <> ''
       AND u.email NOT ILIKE '%@koretini.legacy'
       AND u.email NOT ILIKE '%no-email-%'
       AND u.email LIKE '%@%.%'
       AND COALESCE(u."membershipStatus", 'ACTIVE') <> 'INACTIVE'
  LOOP
    v_anrede := COALESCE(NULLIF(btrim(r.name), ''), 'mik i dashur');
    v_html :=
      '<div style="font-family:Georgia,serif;max-width:520px;margin:0 auto;padding:32px;color:#1c1917">'
      || '<p style="font-size:26px;font-weight:bold;margin:0 0 20px">Gëzuar ditëlindjen, ' || v_anrede || '!</p>'
      || '<p style="font-size:15px;line-height:1.7;margin:0 0 24px">'
      || 'Të urojmë shëndet, gëzim dhe shumë ditë të bukura. Faleminderit që je pjesë e '
      || COALESCE(r.verein, 'shoqatës sonë') || '.</p>'
      || '<hr style="border:none;border-top:1px solid #e7e5e4;margin:28px 0">'
      || '<p style="font-size:22px;font-weight:bold;margin:0 0 16px">Herzlichen Glückwunsch zum Geburtstag, ' || v_anrede || '!</p>'
      || '<p style="font-size:14px;line-height:1.7;color:#57534e;margin:0 0 24px">'
      || 'Wir wünschen dir Gesundheit, Freude und viele schöne Tage. Danke, dass du Teil von '
      || COALESCE(r.verein, 'unserem Verein') || ' bist.</p>'
      || '<p style="font-size:12px;color:#a8a29e;margin:32px 0 0">' || COALESCE(r.verein, '') || '</p>'
      || '</div>';

    BEGIN
      INSERT INTO public.mail_queue
        ("tenantId", recipient, subject, html, kind, "memberId", "refYear")
      VALUES (r."tenantId", r.email,
              'Gëzuar ditëlindjen, ' || v_anrede || '! · Alles Gute zum Geburtstag!',
              v_html, 'BIRTHDAY', r.id, v_jahr);
      v_n := v_n + 1;
    EXCEPTION WHEN unique_violation THEN
      NULL;
    END;
  END LOOP;

  RETURN v_n;
END $$;


ALTER FUNCTION "public"."queue_birthday_greetings"("p_day" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rechnung_referenz_setzen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF coalesce(btrim(NEW.reference),'') = '' THEN
    NEW.reference := public.referenz_fuer_rechnung(NEW."invoiceNumber", NEW."tenantId");
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."rechnung_referenz_setzen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") RETURNS "text"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_art text; v_kern text; v_ref text;
BEGIN
  IF coalesce(btrim(p_rechnungsnummer),'') = '' THEN RETURN NULL; END IF;
  -- Nur Ziffern aus der Rechnungsnummer; "INV-180210" wird zu "180210".
  v_kern := regexp_replace(p_rechnungsnummer, '\D', '', 'g');
  IF v_kern = '' THEN RETURN NULL; END IF;

  v_art := public.referenzart(p_verein);
  IF v_art = 'QRR' THEN
    v_ref := lpad(v_kern, 26, '0');
    RETURN v_ref || public.mod10_pruefziffer(v_ref);
  ELSE
    -- Creditor Reference nach ISO 11649. MB fuer Mitgliederbeitrag, damit
    -- sich eine Rechnung im Kontoauszug von einer Spende (SP) unterscheidet.
    RETURN public.scor_referenz('MB' || lpad(v_kern, 12, '0'));
  END IF;
END $$;


ALTER FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."referenzart"("p_verein" "text") RETURNS "text"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_iban text; v_iid int;
BEGIN
  SELECT replace(coalesce(payment ->> 'qrIban', payment ->> 'iban', ''), ' ', '')
    INTO v_iban FROM public.settings WHERE id = 'payment' AND "tenantId" = p_verein;
  IF v_iban IS NULL OR length(v_iban) < 9 THEN RETURN 'NON'; END IF;
  v_iid := substr(v_iban, 5, 5)::int;
  RETURN CASE WHEN v_iid BETWEEN 30000 AND 31999 THEN 'QRR' ELSE 'SCOR' END;
END $$;


ALTER FUNCTION "public"."referenzart"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."report_payment_paid"("p_payment" "text", "p_method" "text" DEFAULT NULL::"text", "p_paid_on" "date" DEFAULT NULL::"date", "p_note" "text" DEFAULT NULL::"text", "p_betrag" numeric DEFAULT NULL::numeric) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_me     text := public.current_user_row_id();
  v_tenant text := public.current_tenant();
  v_betrag numeric;
  v_id     uuid;
BEGIN
  IF v_me IS NULL
     AND public.is_platform_admin()
     AND coalesce(public.current_tenant(), public.request_tenant()) = 'demo' THEN
    v_me := 'demo-v01';
    v_tenant := 'demo';
  END IF;

  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT p.amount INTO v_betrag FROM public.payments p WHERE p.id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht oder sie gehoert nicht zu Ihrer Nachbarschaft.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Angegebener Betrag hat Vorrang; ohne Angabe bleibt es wie bisher
  -- beim Rechnungsbetrag, damit vorhandene Aufrufe gleich wirken.
  IF p_betrag IS NOT NULL THEN
    IF p_betrag <= 0 THEN
      RAISE EXCEPTION 'Ein gemeldeter Betrag muss groesser als null sein.'
        USING ERRCODE = 'check_violation';
    END IF;
    v_betrag := p_betrag;
  END IF;

  INSERT INTO public.payment_reports
    ("tenantId", "paymentId", "reportedBy", method, amount, "paidOn", note)
  VALUES (v_tenant, p_payment, v_me, p_method, v_betrag,
          COALESCE(p_paid_on, current_date), p_note)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;


ALTER FUNCTION "public"."report_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_note" "text", "p_betrag" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_tenant"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
  SELECT d."tenantId"
    FROM public.tenant_domains d
   WHERE d.domain = regexp_replace(
           coalesce(
             current_setting('request.headers', true)::json ->> 'origin',
             current_setting('request.headers', true)::json ->> 'referer',
             ''),
           '^https?://([^/:]+).*$', '\1')
   LIMIT 1
$_$;


ALTER FUNCTION "public"."request_tenant"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_tenant_probe"() RETURNS json
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT json_build_object(
    'origin',      current_setting('request.headers', true)::json ->> 'origin',
    'referer',     current_setting('request.headers', true)::json ->> 'referer',
    'host',        current_setting('request.headers', true)::json ->> 'host',
    'erkannt',     public.request_tenant(),
    'sitzung',     public.current_tenant()
  )
$$;


ALTER FUNCTION "public"."request_tenant_probe"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_member_password"("p_member" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  v_mail   text;
  v_name   text;
  v_verein text;
  v_rolle  text;
  v_uid    uuid;
  v_neu    boolean := false;
  v_pw     text := '';
  v_wer    text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_betreiber boolean := public.is_platform_admin();
  v_eigener_rang int;
  v_ziel_rang    int;
  v_ziel_betreiber boolean;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  i int;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT (public.is_member_manager() OR v_betreiber) THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Passwoerter zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u.email, u."displayName", u."tenantId", u.role, u."authUserId"::uuid
    INTO v_mail, v_name, v_verein, v_rolle, v_uid
    FROM public.users u WHERE u.id = p_member;

  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  IF NOT v_betreiber AND v_verein <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- ------------------------------------------------ Wen darf man sich vornehmen?
  SELECT EXISTS (SELECT 1 FROM public.platform_admins pa
                  WHERE lower(pa.email) = lower(coalesce(v_mail, '')))
    INTO v_ziel_betreiber;

  IF v_ziel_betreiber AND NOT v_betreiber THEN
    RAISE EXCEPTION 'Dieses Konto gehoert dem Betreiber der Plattform. Nur er selbst kann es zuruecksetzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT v_betreiber THEN
    v_eigener_rang := public.rollen_rang(public.app_role());
    v_ziel_rang    := public.rollen_rang(v_rolle);
    IF v_ziel_rang >= v_eigener_rang THEN
      RAISE EXCEPTION
        'Sie koennen das Passwort von % (%) nicht zuruecksetzen -- diese Person hat dieselben oder mehr Rechte als Sie.',
        coalesce(v_name, v_mail), coalesce(v_rolle, 'MEMBER')
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  -- --------------------------------------------------------------- Adresse
  v_mail := lower(btrim(coalesce(v_mail, '')));
  IF v_mail = '' OR v_mail LIKE '%@koretini.legacy' OR v_mail LIKE '%no-email-%'
     OR v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Dieses Mitglied hat keine echte E-Mail-Adresse. Ohne sie gibt es kein Konto, dessen Passwort sich setzen liesse.'
      USING ERRCODE = 'check_violation';
  END IF;

  FOR i IN 1..14 LOOP
    v_pw := v_pw || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  END LOOP;

  IF v_uid IS NULL THEN
    SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_mail LIMIT 1;
  END IF;

  IF v_uid IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    UPDATE auth.users
       SET encrypted_password = extensions.crypt(v_pw, extensions.gen_salt('bf')),
           updated_at = now(),
           email_confirmed_at = coalesce(email_confirmed_at, now()),
           confirmation_token     = coalesce(confirmation_token, ''),
           recovery_token         = coalesce(recovery_token, ''),
           email_change_token_new = coalesce(email_change_token_new, ''),
           email_change           = coalesce(email_change, '')
     WHERE id = v_uid;
  ELSE
    v_neu := true;
    v_uid := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      is_sso_user, is_anonymous,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
      v_mail, extensions.crypt(v_pw, extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"email_verified":true}'::jsonb,
      false, false, '', '', '', ''
    );

    INSERT INTO auth.identities (
      id, user_id, provider_id, identity_data, provider, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::text,
      jsonb_build_object('sub', v_uid::text, 'email', v_mail,
                         'email_verified', true, 'phone_verified', false),
      'email', now(), now()
    );
  END IF;

  UPDATE public.users SET "authUserId" = v_uid::text WHERE id = p_member;

  INSERT INTO public.security_logs (id, "tenantId", type, action, "userId", details, "timestamp", "createdAt")
  VALUES (gen_random_uuid(), v_verein, 'PASSWORD_RESET',
          CASE WHEN v_neu THEN 'ACCOUNT_CREATED' ELSE 'PASSWORD_SET' END,
          p_member,
          to_jsonb(format('durch %s fuer %s (%s, Rolle %s)', coalesce(nullif(v_wer,''),'unbekannt'),
                          coalesce(v_name, v_mail), v_mail, coalesce(v_rolle,'MEMBER'))),
          now(), now());

  RETURN jsonb_build_object(
    'ok', true, 'created', v_neu, 'email', v_mail,
    'displayName', v_name, 'password', v_pw
  );
END $_$;


ALTER FUNCTION "public"."reset_member_password"("p_member" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revisionsbericht"("p_jahr" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF public.current_tenant() IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf den Revisionsbericht abrufen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.revisionsbericht_fuer(public.current_tenant(), p_jahr);
END $$;


ALTER FUNCTION "public"."revisionsbericht"("p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revisionsbericht_fuer"("p_verein" "text", "p_jahr" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."revisionsbericht_fuer"("p_verein" "text", "p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
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


ALTER FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revisionszugang_erstellen"("p_bezeichnung" "text", "p_gueltig_bis" "date", "p_jahr" integer DEFAULT NULL::integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_token text;
  v_id uuid;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf einen Revisionszugang ausstellen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_gueltig_bis IS NULL OR p_gueltig_bis <= current_date THEN
    RAISE EXCEPTION 'Das Ablaufdatum muss in der Zukunft liegen.';
  END IF;
  -- Ein Zugang ohne Ende ist kein befristeter Zugang. Ein Monat ist die
  -- Obergrenze: eine Revision dauert Tage bis Wochen. Braucht sie laenger,
  -- soll der Verein bewusst neu ausstellen -- und dabei noch einmal
  -- hinsehen, wem er Einblick in seine Finanzen gibt.
  IF p_gueltig_bis > current_date + interval '1 month' THEN
    RAISE EXCEPTION 'Hoechstens ein Monat Gueltigkeit (gewuenscht: %).', p_gueltig_bis;
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


ALTER FUNCTION "public"."revisionszugang_erstellen"("p_bezeichnung" "text", "p_gueltig_bis" "date", "p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revisionszugang_widerrufen"("p_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."revisionszugang_widerrufen"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rolle_setzen"("p_user" "text", "p_rolle" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Rollen vergibt nur die Vereinsadministration.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_rolle NOT IN ('MEMBER','REPRESENTATIVE','BOARD','ADMIN','SUPER_ADMIN') THEN
    RAISE EXCEPTION 'Unbekannte Rolle: %', p_rolle USING ERRCODE='check_violation';
  END IF;

  -- Der Ausloeser prueft den Rest; hier geht es nur darum, dass die
  -- Aenderung ueberhaupt die richtige Zeile trifft.
  UPDATE public.users SET role = p_rolle
   WHERE id = p_user AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Person gehoert nicht zu Ihrem Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN p_rolle;
END $$;


ALTER FUNCTION "public"."rolle_setzen"("p_user" "text", "p_rolle" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rollen_rang"("p_rolle" "text") RETURNS integer
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT CASE upper(coalesce(p_rolle, 'MEMBER'))
           WHEN 'SUPER_ADMIN'          THEN 4
           WHEN 'ADMIN'                THEN 3
           WHEN 'BOARD'                THEN 2
           WHEN 'NEIGHBORHOOD_MANAGER' THEN 1
           WHEN 'REPRESENTATIVE'       THEN 1
           ELSE 0
         END
$$;


ALTER FUNCTION "public"."rollen_rang"("p_rolle" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rollenwechsel_pruefen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text; v_uebrig int;
BEGIN
  IF NEW.role IS NOT DISTINCT FROM OLD.role THEN RETURN NEW; END IF;

  -- Zeitplaene, Migrationen, Dienstschluessel.
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  -- Der Betreiber setzt den ersten Administrator eines Vereins und darf
  -- auch sonst eingreifen -- sonst gaebe es keinen Weg zurueck.
  IF public.is_platform_admin() THEN RETURN NEW; END IF;

  IF public.app_role() NOT IN ('SUPER_ADMIN','ADMIN') THEN
    RAISE EXCEPTION 'Rollen vergibt nur die Vereinsadministration.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN
    RAISE EXCEPTION 'Die eigene Rolle koennen Sie nicht aendern. Bestimmen Sie zuerst '
                    'eine andere Person zur Administration; diese kann Sie dann herabstufen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Der letzte Administrator bleibt.
  IF coalesce(OLD.role,'MEMBER') IN ('SUPER_ADMIN','ADMIN')
     AND coalesce(NEW.role,'MEMBER') NOT IN ('SUPER_ADMIN','ADMIN') THEN
    SELECT count(*) INTO v_uebrig FROM public.users u
     WHERE u."tenantId" = NEW."tenantId" AND u.id <> NEW.id
       AND u.role IN ('SUPER_ADMIN','ADMIN');
    IF v_uebrig = 0 THEN
      RAISE EXCEPTION 'Das ist die letzte Administration dieses Vereins. Bestimmen Sie '
                      'zuerst eine andere, sonst kann niemand mehr verwalten.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION "public"."rollenwechsel_pruefen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."scor_referenz"("p_kern" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT 'RF' || public.mod97_pruefziffern(p_kern) || p_kern;
$$;


ALTER FUNCTION "public"."scor_referenz"("p_kern" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seite_loeschen"("p_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf Seiten loeschen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  DELETE FROM public.seiten WHERE id = p_id AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Seite gehoert nicht zu Ihrem Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN true;
END $$;


ALTER FUNCTION "public"."seite_loeschen"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seite_speichern"("p_id" "uuid", "p_pfad" "text", "p_titel" "jsonb", "p_bloecke" "jsonb", "p_status" "text", "p_im_menue" boolean, "p_reihenfolge" integer) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_pfad text; v_id uuid; v_wer text;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf Seiten bearbeiten.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Der Pfad wird hier gebildet, nicht in der Maske: Umlaute, Leerzeichen
  -- und Schraegstriche in einer URL sind eine Fehlerquelle, die niemand
  -- sucht, wenn sie erst beim Besucher auffaellt.
  v_pfad := lower(btrim(coalesce(p_pfad, '')));
  v_pfad := translate(v_pfad, 'äöüàéèêçë', 'aouaeeece');
  v_pfad := regexp_replace(v_pfad, '[^a-z0-9]+', '-', 'g');
  v_pfad := btrim(v_pfad, '-');
  IF v_pfad = '' THEN
    RAISE EXCEPTION 'Die Seite braucht eine Adresse.' USING ERRCODE = 'check_violation';
  END IF;
  IF public.pfad_belegt(v_pfad) THEN
    RAISE EXCEPTION 'Die Adresse "%" ist bereits vergeben -- sie wuerde eine bestehende Seite verdecken.', v_pfad
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT u."displayName" INTO v_wer FROM public.users u
   WHERE u.id = public.current_user_row_id();

  IF p_id IS NULL THEN
    INSERT INTO public.seiten ("tenantId", pfad, titel, bloecke, status, im_menue,
                               reihenfolge, geaendert_von)
    VALUES (v_verein, v_pfad, coalesce(p_titel,'{}'::jsonb), coalesce(p_bloecke,'[]'::jsonb),
            coalesce(p_status,'ENTWURF'), coalesce(p_im_menue,false),
            coalesce(p_reihenfolge,100), v_wer)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.seiten SET
      pfad = v_pfad, titel = coalesce(p_titel, titel), bloecke = coalesce(p_bloecke, bloecke),
      status = coalesce(p_status, status), im_menue = coalesce(p_im_menue, im_menue),
      reihenfolge = coalesce(p_reihenfolge, reihenfolge),
      geaendert_am = now(), geaendert_von = v_wer
     WHERE id = p_id AND "tenantId" = v_verein
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Diese Seite gehoert nicht zu Ihrem Verein.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  RETURN v_id;
END $$;


ALTER FUNCTION "public"."seite_speichern"("p_id" "uuid", "p_pfad" "text", "p_titel" "jsonb", "p_bloecke" "jsonb", "p_status" "text", "p_im_menue" boolean, "p_reihenfolge" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF p_id IS NULL OR p_sekunden IS NULL OR p_sekunden < 0 THEN RETURN; END IF;
  UPDATE public.seitenaufrufe
     -- Nach oben begrenzt: ein offener Reiter ueber Nacht ergaebe sonst
     -- eine Durchschnittsdauer von Stunden und machte die Zahl wertlos.
     -- Zwei Stunden ist grosszuegig und noch glaubhaft.
     SET dauer_s = least(p_sekunden, 7200)
   WHERE id = p_id
     -- Nur solange der Aufruf frisch ist. Sonst koennte jemand alte
     -- Zeilen nachtraeglich verbiegen.
     AND gesehen_am > now() - interval '12 hours';
END $$;


ALTER FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text" DEFAULT NULL::"text", "p_verweis" "text" DEFAULT NULL::"text", "p_ziel" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  k jsonb := coalesce(current_setting('request.headers', true)::jsonb, '{}'::jsonb);
  v_tag date := (now() AT TIME ZONE 'Europe/Zurich')::date;
  v_salz text;
  v_ip text := split_part(coalesce(k->>'x-forwarded-for', ''), ',', 1);
  v_ua text := coalesce(k->>'user-agent', '');
  v_verein text := public.request_tenant();
  v_besucher text;
  v_geraet text;
  v_quelle text;
  v_art text;
  v_eigen text;
  v_id uuid;
  v_letzter uuid;
BEGIN
  IF p_pfad IS NULL OR btrim(p_pfad) = '' THEN
    RETURN NULL;   -- nichts zu zaehlen, und kein Grund zu scheitern
  END IF;

  -- Salz des Tages, bei Bedarf angelegt. Das ON CONFLICT ist nicht
  -- Zierde: am Tageswechsel treffen mehrere Aufrufe gleichzeitig ein.
  INSERT INTO public.zaehler_salz (tag, salz)
  -- Mit Schema: pgcrypto liegt in "extensions", und diese Funktion
  -- pinnt search_path = public. Das Pinnen ist richtig -- es verhindert,
  -- dass jemand ueber einen eigenen Suchpfad eine falsche Funktion
  -- unterschiebt --, also werden die beiden Aufrufe qualifiziert statt
  -- den Pfad aufzuweichen.
  VALUES (v_tag, encode(extensions.gen_random_bytes(32), 'hex'))
  ON CONFLICT (tag) DO NOTHING;
  SELECT salz INTO v_salz FROM public.zaehler_salz WHERE tag = v_tag;

  v_besucher := encode(extensions.digest(v_salz || v_ip || v_ua, 'sha256'), 'hex');

  -- Geraeteart aus dem User-Agent. Grob und absichtlich: fuer die Frage
  -- "muss die Seite auf dem Telefon taugen" genuegen drei Klassen, und
  -- eine feinere Erkennung waere eine Bibliothek, die veraltet.
  v_geraet := CASE
    WHEN v_ua ~* 'iPad|Tablet|PlayBook|Silk' THEN 'TABLET'
    WHEN v_ua ~* 'Mobi|iPhone|Android.*Mobile|Windows Phone' THEN 'HANDY'
    WHEN v_ua = '' THEN 'UNBEKANNT'
    ELSE 'RECHNER' END;

  -- Herkunft: der Verweis vom Browser hat Vorrang, weil er bei einem
  -- Wechsel innerhalb der Seite richtiger ist als die Kopfzeile.
  v_quelle := coalesce(nullif(btrim(p_verweis), ''), k->>'referer', '');
  v_quelle := lower(regexp_replace(v_quelle, '^https?://(www\.)?([^/:]+).*$', '\2'));
  v_eigen := lower(regexp_replace(coalesce(k->>'origin',''), '^https?://(www\.)?([^/:]+).*$', '\2'));

  v_art := CASE
    WHEN v_quelle = '' THEN 'DIREKT'
    -- Ein Wechsel innerhalb der eigenen Seite ist keine Herkunft.
    WHEN v_eigen <> '' AND v_quelle = v_eigen THEN 'INTERN'
    WHEN v_quelle ~ '(google|bing|duckduckgo|ecosia|yahoo|yandex|startpage|qwant)\.' THEN 'SUCHE'
    WHEN v_quelle ~ '(facebook|instagram|tiktok|twitter|^x\.com|linkedin|youtube|whatsapp|t\.co|telegram)' THEN 'SOZIAL'
    ELSE 'VERWEIS' END;

  -- Doppelt zaehlen vermeiden. Eine Einzelseiten-Anwendung ruft bei
  -- jedem Rendern auf; ohne diese Sperre stiegen die Zahlen mit der
  -- Anzahl der Neuzeichnungen und nicht mit der der Besucher.
  SELECT a.id INTO v_letzter FROM public.seitenaufrufe a
   WHERE a.besucher = v_besucher AND a.pfad = p_pfad
     AND a.gesehen_am > now() - interval '15 seconds'
   ORDER BY a.gesehen_am DESC LIMIT 1;
  IF v_letzter IS NOT NULL THEN
    RETURN v_letzter;
  END IF;

  INSERT INTO public.seitenaufrufe
    ("tenantId", pfad, titel, besucher, herkunft, herkunft_art, geraet,
     sprache, land, stunde, ziel)
  VALUES (v_verein, left(btrim(p_pfad), 300), left(coalesce(p_titel,''), 200),
          v_besucher, nullif(v_quelle,''), v_art, v_geraet,
          left(split_part(coalesce(k->>'accept-language',''), ',', 1), 10),
          upper(left(coalesce(k->>'cf-ipcountry',''), 2)),
          extract(hour from (now() AT TIME ZONE 'Europe/Zurich'))::smallint,
          nullif(btrim(coalesce(p_ziel,'')), ''))
  RETURNING id INTO v_id;

  RETURN v_id;
END $_$;


ALTER FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text", "p_verweis" "text", "p_ziel" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_bereich"("p_verein" "text") RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT CASE
    -- Der Betreiber: was er verlangt, oder alles.
    WHEN public.is_platform_admin() THEN p_verein
    -- Der Verein: immer der eigene, unabhaengig von der Anfrage.
    WHEN public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD') THEN public.current_tenant()
    ELSE '\x00'   -- niemand sonst; ein Wert, der auf nichts passt
  END;
$$;


ALTER FUNCTION "public"."seo_bereich"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_herkunft"("p_von" "date" DEFAULT NULL::"date", "p_bis" "date" DEFAULT NULL::"date", "p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("r_art" "text", "r_quelle" "text", "r_aufrufe" bigint, "r_besucher" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein)
  SELECT s.herkunft_art, coalesce(s.herkunft, '—'),
         count(*)::bigint, count(DISTINCT s.besucher)::bigint
    FROM public.seitenaufrufe s, b
   WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
     AND b.verein IS DISTINCT FROM '\x00'
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
     AND s.herkunft_art <> 'INTERN'
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;


ALTER FUNCTION "public"."seo_herkunft"("p_von" "date", "p_bis" "date", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_je_verein"("p_von" "date" DEFAULT NULL::"date", "p_bis" "date" DEFAULT NULL::"date") RETURNS TABLE("r_verein" "text", "r_name" "text", "r_aufrufe" bigint, "r_besucher" bigint, "r_dauer_s" numeric, "r_seiten" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT coalesce(s."tenantId", '—'),
         coalesce(t.name, CASE WHEN s."tenantId" IS NULL
                               THEN 'Betreiberseite' ELSE s."tenantId" END),
         count(*)::bigint, count(DISTINCT s.besucher)::bigint,
         round(avg(s.dauer_s)::numeric, 1), count(DISTINCT s.pfad)::bigint
    FROM public.seitenaufrufe s
    LEFT JOIN public.tenants t ON t.id = s."tenantId"
   WHERE public.is_platform_admin()
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
     AND s.herkunft_art <> 'INTERN'
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;


ALTER FUNCTION "public"."seo_je_verein"("p_von" "date", "p_bis" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_kennzahlen"("p_von" "date" DEFAULT NULL::"date", "p_bis" "date" DEFAULT NULL::"date", "p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("r_pfad" "text", "r_aufrufe" bigint, "r_besucher" bigint, "r_dauer_s" numeric, "r_absprung" numeric)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein),
  a AS (
    SELECT s.* FROM public.seitenaufrufe s, b
     WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
       AND b.verein IS DISTINCT FROM '\x00'
       AND s.gesehen_am >= coalesce(p_von, current_date - 29)
       AND s.gesehen_am < coalesce(p_bis, current_date) + 1
       AND s.herkunft_art <> 'INTERN'
  ),
  -- Ein Besuch gilt als Absprung, wenn dieser Besucher in derselben
  -- halben Stunde nur EINE Seite gesehen hat. Ohne Zeitfenster waere
  -- jeder Wiederkehrer am selben Tag kein Absprung mehr, und die Zahl
  -- saehe besser aus, als sie ist.
  sitzungen AS (
    SELECT besucher,
           div(extract(epoch from gesehen_am)::bigint, 1800) AS fenster,
           count(*) AS seiten,
           min(pfad) AS erste
      FROM a GROUP BY 1, 2
  )
  SELECT a.pfad,
         count(*)::bigint,
         count(DISTINCT a.besucher)::bigint,
         round(avg(a.dauer_s)::numeric, 1),
         round(100.0 * coalesce(
           (SELECT count(*) FROM sitzungen s
             WHERE s.erste = a.pfad AND s.seiten = 1), 0)
           / greatest((SELECT count(*) FROM sitzungen s WHERE s.erste = a.pfad), 1), 1)
    FROM a GROUP BY a.pfad ORDER BY 2 DESC;
$$;


ALTER FUNCTION "public"."seo_kennzahlen"("p_von" "date", "p_bis" "date", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_verteilung"("p_von" "date" DEFAULT NULL::"date", "p_bis" "date" DEFAULT NULL::"date", "p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("r_art" "text", "r_wert" "text", "r_aufrufe" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  -- Geraet, Stunde, Sprache, Land und Tag in einer Abfrage. Fuenf
  -- Funktionen fuer fuenf Gruppierungen waeren fuenfmal dieselbe
  -- Zugriffspruefung und fuenf Gelegenheiten, sie verschieden zu
  -- schreiben.
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein),
  a AS (
    SELECT s.* FROM public.seitenaufrufe s, b
     WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
       AND b.verein IS DISTINCT FROM '\x00'
       AND s.gesehen_am >= coalesce(p_von, current_date - 29)
       AND s.gesehen_am < coalesce(p_bis, current_date) + 1
       AND s.herkunft_art <> 'INTERN'
  )
  SELECT 'GERAET', geraet, count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'STUNDE', lpad(stunde::text, 2, '0'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'SPRACHE', coalesce(nullif(sprache,''), '—'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'LAND', coalesce(nullif(land,''), '—'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'TAG', (gesehen_am AT TIME ZONE 'Europe/Zurich')::date::text,
         count(*)::bigint FROM a GROUP BY 2
  ORDER BY 1, 2;
$$;


ALTER FUNCTION "public"."seo_verteilung"("p_von" "date", "p_bis" "date", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seo_ziele"("p_von" "date" DEFAULT NULL::"date", "p_bis" "date" DEFAULT NULL::"date", "p_verein" "text" DEFAULT NULL::"text") RETURNS TABLE("r_ziel" "text", "r_pfad" "text", "r_anzahl" bigint, "r_besucher" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein)
  SELECT s.ziel, s.pfad, count(*)::bigint, count(DISTINCT s.besucher)::bigint
    FROM public.seitenaufrufe s, b
   WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
     AND b.verein IS DISTINCT FROM '\x00'
     AND s.ziel IS NOT NULL
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;


ALTER FUNCTION "public"."seo_ziele"("p_von" "date", "p_bis" "date", "p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_registration_tenant"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_tenant text;
BEGIN
  SELECT e."tenantId" INTO v_tenant FROM public.events e WHERE e.id = NEW."eventId";
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Anmeldung ohne zuordenbare Veranstaltung (%).', NEW."eventId"
      USING ERRCODE = 'check_violation';
  END IF;
  NEW."tenantId" := v_tenant;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."set_registration_tenant"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_tenant_on_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NEW."tenantId" IS NULL THEN
    NEW."tenantId" := COALESCE(public.current_tenant(), public.request_tenant());
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."set_tenant_on_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_einrichtung"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_app    boolean;
  v_ziel   boolean;
  v_modul  boolean;
  v_aktiv  int;
  v_fehler text;
BEGIN
  IF v_verein IS NULL OR NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT coalesce(btrim(wert),'') <> '' INTO v_app
    FROM public.platform_secrets WHERE schluessel='meta_app_id';
  SELECT coalesce(btrim(wert),'') <> '' INTO v_ziel
    FROM public.platform_secrets WHERE schluessel='meta_redirect_uri';
  v_modul := public.modul_aktiv('SOCIAL');

  SELECT count(*) FILTER (WHERE zustand='AKTIV'),
         max(letzter_fehler)
    INTO v_aktiv, v_fehler
    FROM public.social_connections WHERE "tenantId" = v_verein;

  RETURN jsonb_build_object(
    'modul_aktiv',      v_modul,
    -- Beides muss stehen, sonst fuehrt der Verweis zu Meta ins Leere.
    'plattform_bereit', coalesce(v_app,false) AND coalesce(v_ziel,false),
    'app_hinterlegt',   coalesce(v_app,false),
    'ziel_hinterlegt',  coalesce(v_ziel,false),
    'verbunden',        coalesce(v_aktiv,0) > 0,
    'anzahl_kanaele',   coalesce(v_aktiv,0),
    'letzter_fehler',   v_fehler
  );
END $$;


ALTER FUNCTION "public"."social_einrichtung"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_jetzt_senden"("p_beitrag" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text; v_status text; v_n int;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf veroeffentlichen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT "tenantId", status INTO v_verein, v_status
    FROM public.socialmediaposts WHERE id = p_beitrag;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Diesen Beitrag gibt es nicht.' USING ERRCODE='check_violation';
  END IF;
  IF v_verein <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieser Beitrag gehoert zu einem anderen Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF v_status = 'PUBLISHED' THEN
    RAISE EXCEPTION 'Dieser Beitrag ist bereits veroeffentlicht.' USING ERRCODE='check_violation';
  END IF;

  SELECT count(*) INTO v_n FROM public.social_connections
   WHERE "tenantId" = v_verein AND zustand = 'AKTIV';
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieser Verein ist mit keinem Kanal verbunden. Erst verbinden, dann senden.'
      USING ERRCODE='check_violation';
  END IF;

  UPDATE public.socialmediaposts
     SET status = 'QUEUED', "lastError" = NULL, "scheduledTime" = NULL
   WHERE id = p_beitrag;

  PERFORM net.http_post(
    url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/social-publish',
    headers := jsonb_build_object('Content-Type','application/json',
                 'x-cron-token', (SELECT wert FROM public.platform_secrets
                                   WHERE schluessel='social_cron_token')),
    body    := jsonb_build_object('beitrag', p_beitrag));

  RETURN 'in die Warteschlange gestellt';
END $$;


ALTER FUNCTION "public"."social_jetzt_senden"("p_beitrag" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_seite_waehlen"("p_konto_id" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_k jsonb; v_n int := 0;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf das.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  FOR v_k IN SELECT k FROM public.social_connections c,
                  LATERAL jsonb_array_elements(coalesce(c.kandidaten,'[]'::jsonb)) AS k
              WHERE c."tenantId"=v_verein AND c.plattform='FACEBOOK' AND c.zustand='WAEHLEN'
  LOOP
    IF v_k->>'id' = p_konto_id THEN
      UPDATE public.social_connections
         SET konto_id = v_k->>'id', konto_name = v_k->>'name',
             zugriffstoken = v_k->>'token', zustand='AKTIV',
             kandidaten = NULL, verbunden_am = now()
       WHERE "tenantId"=v_verein AND plattform='FACEBOOK';

      -- Das verknuepfte Instagram-Konto haengt an derselben Seite.
      IF coalesce(v_k->>'ig_id','') <> '' THEN
        INSERT INTO public.social_connections ("tenantId", plattform, konto_id, konto_name,
                                               zugriffstoken, zustand, verbunden_am)
        VALUES (v_verein,'INSTAGRAM', v_k->>'ig_id', coalesce(v_k->>'ig_name', v_k->>'name'),
                v_k->>'token','AKTIV', now())
        ON CONFLICT ("tenantId", plattform) DO UPDATE
          SET konto_id=EXCLUDED.konto_id, konto_name=EXCLUDED.konto_name,
              zugriffstoken=EXCLUDED.zugriffstoken, zustand='AKTIV',
              verbunden_am=now(), letzter_fehler=NULL;
      END IF;
      v_n := 1;
    END IF;
  END LOOP;

  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Seite steht nicht zur Wahl.' USING ERRCODE='check_violation';
  END IF;
  RETURN 'verbunden';
END $$;


ALTER FUNCTION "public"."social_seite_waehlen"("p_konto_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_trennen"("p_plattform" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf die Verbindung trennen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  DELETE FROM public.social_connections
   WHERE "tenantId" = public.current_tenant()
     AND (p_plattform IS NULL OR plattform = p_plattform);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n || ' Verbindung(en) getrennt';
END $$;


ALTER FUNCTION "public"."social_trennen"("p_plattform" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_verbinden_starten"("p_zurueck" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_app    text;
  v_ziel   text;
  v_nonce  text;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Kanaele verbinden.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE='check_violation';
  END IF;

  SELECT wert INTO v_app  FROM public.platform_secrets WHERE schluessel='meta_app_id';
  SELECT wert INTO v_ziel FROM public.platform_secrets WHERE schluessel='meta_redirect_uri';
  IF coalesce(btrim(v_app),'') = '' THEN
    RAISE EXCEPTION 'Die Meta-App ist noch nicht hinterlegt. Der Betreiber muss sie zuerst eintragen.'
      USING ERRCODE='check_violation';
  END IF;

  -- Alte Kennungen aufraeumen, damit die Tabelle nicht waechst.
  DELETE FROM public.social_oauth_state WHERE laeuft_ab < now();

  v_nonce := encode(extensions.gen_random_bytes(24), 'hex');
  INSERT INTO public.social_oauth_state (nonce, "tenantId", benutzer, zurueck, laeuft_ab)
  VALUES (v_nonce, v_verein, public.current_user_row_id(),
          nullif(btrim(coalesce(p_zurueck,'')),''), now() + interval '15 minutes');

  RETURN 'https://www.facebook.com/v21.0/dialog/oauth'
      || '?client_id='     || v_app
      || '&redirect_uri='  || replace(replace(replace(v_ziel,':','%3A'),'/','%2F'),'?','%3F')
      || '&state='         || v_nonce
      || '&response_type=code'
      || '&scope='         || 'pages_show_list,pages_read_engagement,pages_manage_posts,'
                           || 'instagram_basic,instagram_content_publish,business_management';
END $$;


ALTER FUNCTION "public"."social_verbinden_starten"("p_zurueck" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."social_verbindungen"() RETURNS TABLE("plattform" "text", "konto_name" "text", "zustand" "text", "token_laeuft_ab" timestamp with time zone, "verbunden_am" timestamp with time zone, "letzter_fehler" "text", "kandidaten" "jsonb")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT c.plattform, c.konto_name, c.zustand, c.token_laeuft_ab,
         c.verbunden_am, c.letzter_fehler,
         -- Aus den Kandidaten nur Nummer und Name, nie deren Token.
         (SELECT jsonb_agg(jsonb_build_object('id', k->>'id', 'name', k->>'name'))
            FROM jsonb_array_elements(coalesce(c.kandidaten,'[]'::jsonb)) AS k)
    FROM public.social_connections c
   WHERE c."tenantId" = public.current_tenant()
     AND public.is_staff();
$$;


ALTER FUNCTION "public"."social_verbindungen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spende_anlegen"("p_betrag" numeric, "p_waehrung" "text" DEFAULT 'CHF'::"text", "p_name" "text" DEFAULT NULL::"text", "p_email" "text" DEFAULT NULL::"text", "p_strasse" "text" DEFAULT NULL::"text", "p_plz" "text" DEFAULT NULL::"text", "p_ort" "text" DEFAULT NULL::"text", "p_land" "text" DEFAULT 'CH'::"text", "p_nachricht" "text" DEFAULT NULL::"text", "p_zweck" "text" DEFAULT NULL::"text", "p_anonym" boolean DEFAULT false) RETURNS TABLE("id" "uuid", "referenz" "text", "betrag" numeric, "waehrung" "text", "art" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := COALESCE(public.current_tenant(), public.request_tenant());
        v_ref text; v_nummer bigint; v_offen int; v_id uuid; v_art text;
        v_ich text := public.current_user_row_id();
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE='check_violation'; END IF;
  IF NOT public.modul_aktiv('SPENDEN') THEN
    RAISE EXCEPTION 'Spenden sind bei diesem Verein nicht eingerichtet.'
      USING ERRCODE='check_violation'; END IF;
  IF p_betrag IS NULL OR p_betrag <= 0 OR p_betrag > 100000 THEN
    RAISE EXCEPTION 'Der Betrag muss zwischen 0 und 100000 liegen.'
      USING ERRCODE='check_violation'; END IF;
  IF coalesce(p_waehrung,'CHF') NOT IN ('CHF','EUR') THEN
    RAISE EXCEPTION 'Nur CHF oder EUR.' USING ERRCODE='check_violation'; END IF;
  IF NOT coalesce(p_anonym,false) AND coalesce(btrim(p_name),'') = '' THEN
    RAISE EXCEPTION 'Bitte einen Namen angeben, oder ausdruecklich anonym spenden.'
      USING ERRCODE='check_violation'; END IF;

  SELECT count(*) INTO v_offen FROM public.donations d
   WHERE d."tenantId" = v_verein AND d.status='OFFEN'
     AND d.erfasst_am > now() - interval '1 hour';
  IF v_offen >= 30 THEN
    RAISE EXCEPTION 'Zu viele offene Spenden in kurzer Zeit. Bitte spaeter erneut versuchen.'
      USING ERRCODE='check_violation'; END IF;

  v_nummer := nextval('public.spenden_nummer');
  v_art := public.referenzart(v_verein);

  IF v_art = 'QRR' THEN
    -- 27 Ziffern: Jahr, Kennzeichen 9 fuer Spenden, laufende Nummer, Pruefziffer.
    v_ref := extract(year FROM current_date)::text || '9' || lpad(v_nummer::text, 21, '0');
    v_ref := v_ref || public.mod10_pruefziffer(v_ref);
  ELSE
    -- Creditor Reference nach ISO 11649. Mit einer normalen IBAN ist das die
    -- zulaessige Art; QRR verlangt eine QR-IBAN, die dieser Verein nicht hat.
    v_ref := public.scor_referenz('SP' || extract(year FROM current_date)::text
                                  || lpad(v_nummer::text, 10, '0'));
  END IF;

  INSERT INTO public.donations
    ("tenantId", betrag, waehrung, name, email, strasse, plz, ort, land,
     anonym, nachricht, zweck, referenz, status, "userId", erfasst_von)
  VALUES
    (v_verein, p_betrag, coalesce(p_waehrung,'CHF'),
     nullif(btrim(p_name),''), nullif(btrim(p_email),''), nullif(btrim(p_strasse),''),
     nullif(btrim(p_plz),''), nullif(btrim(p_ort),''), coalesce(nullif(btrim(p_land),''),'CH'),
     coalesce(p_anonym,false), nullif(btrim(p_nachricht),''), nullif(btrim(p_zweck),''),
     v_ref, 'OFFEN', v_ich,
     CASE WHEN v_ich IS NULL THEN 'oeffentliche Seite' ELSE 'angemeldet' END)
  RETURNING donations.id INTO v_id;

  RETURN QUERY SELECT v_id, v_ref, p_betrag, coalesce(p_waehrung,'CHF'), v_art;
END $$;


ALTER FUNCTION "public"."spende_anlegen"("p_betrag" numeric, "p_waehrung" "text", "p_name" "text", "p_email" "text", "p_strasse" "text", "p_plz" "text", "p_ort" "text", "p_land" "text", "p_nachricht" "text", "p_zweck" "text", "p_anonym" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := coalesce(public.current_tenant(), public.request_tenant());
        v_n int;
BEGIN
  IF v_verein IS NULL THEN RETURN false; END IF;

  UPDATE public.donations d
     SET aufruf = p_aufruf
   WHERE d.id = p_spende
     AND d."tenantId" = v_verein
     AND d.status = 'OFFEN'
     AND d.aufruf IS NULL
     AND d.erfasst_am > now() - interval '10 minutes'
     AND EXISTS (SELECT 1 FROM public.spendenaufrufe a
                  WHERE a.id = p_aufruf AND a."tenantId" = v_verein
                    AND a.status = 'OEFFENTLICH');
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END $$;


ALTER FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spende_bescheinigt"("p_spende" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE d record;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung.' USING ERRCODE='insufficient_privilege';
  END IF;
  SELECT * INTO d FROM public.donations WHERE id = p_spende;
  IF NOT FOUND OR d."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Spende nicht gefunden.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF d.anonym THEN
    RAISE EXCEPTION 'Eine Bescheinigung muss auf einen Namen lauten; diese Spende ist anonym.'
      USING ERRCODE='check_violation';
  END IF;
  IF d.status <> 'BEZAHLT' THEN
    RAISE EXCEPTION 'Erst bescheinigen, wenn die Zahlung eingegangen ist.'
      USING ERRCODE='check_violation';
  END IF;
  UPDATE public.donations SET bescheinigt_am = now() WHERE id = p_spende;
  RETURN 'bescheinigt';
END $$;


ALTER FUNCTION "public"."spende_bescheinigt"("p_spende" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spende_bezahlt"("p_spende" "uuid", "p_weg" "text", "p_datum" "date" DEFAULT NULL::"date") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE d record; v_soll text; v_datum date := coalesce(p_datum, current_date);
        v_ertrag text := '3200'; v_wer text;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf eine Spende buchen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('SPENDEN') THEN
    RAISE EXCEPTION 'Das Spendenmodul ist nicht aktiv.' USING ERRCODE='check_violation';
  END IF;
  IF coalesce(p_weg,'') NOT IN ('QR','TWINT','PAYPAL','BAR','UEBERWEISUNG') THEN
    RAISE EXCEPTION 'Unbekannter Zahlweg: %', p_weg;
  END IF;

  SELECT * INTO d FROM public.donations WHERE id = p_spende;
  IF NOT FOUND THEN RAISE EXCEPTION 'Spende nicht gefunden.'; END IF;
  IF d."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Spende gehoert zu einem anderen Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF d.status = 'BEZAHLT' THEN
    RAISE EXCEPTION 'Diese Spende ist bereits gebucht.' USING ERRCODE='check_violation';
  END IF;

  -- Wo das Geld ankommt, haengt am Weg.
  v_soll := CASE p_weg
    WHEN 'BAR' THEN '1000'
    WHEN 'PAYPAL' THEN '1021'
    ELSE '1020' END;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  UPDATE public.donations
     SET status = 'BEZAHLT', weg = p_weg, eingegangen_am = v_datum, gebucht = true
   WHERE id = p_spende;

  INSERT INTO public.accounting_journal
    (id, "tenantId", date, description, amount, "debitCode", "creditCode",
     "referenceId", "isSystemEntry", "createdAt")
  VALUES
    (gen_random_uuid()::text, d."tenantId", v_datum::text,
     'Spende ' || coalesce(nullif(d.name,''), 'anonym')
       || CASE WHEN d.zweck IS NOT NULL THEN ' — ' || d.zweck ELSE '' END,
     d.betrag, v_soll, v_ertrag, p_spende::text, true, now());

  RETURN 'gebucht: ' || v_soll || ' / ' || v_ertrag;
END $$;


ALTER FUNCTION "public"."spende_bezahlt"("p_spende" "uuid", "p_weg" "text", "p_datum" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spendenaufrufe_oeffentlich"() RETURNS TABLE("id" "text", "titel" "text", "text" "text", "bild" "text", "ziel_betrag" numeric, "waehrung" "text", "endet_am" "date", "gesammelt" numeric, "anzahl" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT a.id, a.titel, a.text, a.bild, a.ziel_betrag, a.waehrung, a.endet_am,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status = 'BEZAHLT'), 0)::numeric,
         coalesce((SELECT count(*) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status = 'BEZAHLT'), 0)::int
    FROM public.spendenaufrufe a
   WHERE a.status = 'OEFFENTLICH'
     AND a."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
     AND public.modul_aktiv('SPENDEN')
     AND (a.beginnt_am IS NULL OR a.beginnt_am <= current_date)
     AND (a.endet_am   IS NULL OR a.endet_am   >= current_date)
   ORDER BY a.reihenfolge, a.erstellt_am DESC;
$$;


ALTER FUNCTION "public"."spendenaufrufe_oeffentlich"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spendenaufrufe_stand"() RETURNS TABLE("id" "text", "gesammelt" numeric, "anzahl" integer, "offen" numeric)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT a.id,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='BEZAHLT'),0)::numeric,
         coalesce((SELECT count(*) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='BEZAHLT'),0)::int,
         coalesce((SELECT sum(d.betrag) FROM public.donations d
                    WHERE d.aufruf = a.id AND d.status='OFFEN'),0)::numeric
    FROM public.spendenaufrufe a
   WHERE a."tenantId" = public.current_tenant() AND public.is_staff();
$$;


ALTER FUNCTION "public"."spendenaufrufe_stand"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."spendenseite_sichtbar"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH v AS (SELECT coalesce(public.current_tenant(), public.request_tenant()) AS verein),
       s AS (SELECT upper(coalesce(
               (SELECT st.system ->> 'spendenseite' FROM public.settings st, v
                 WHERE st."tenantId" = v.verein AND st.id='system'), 'IMMER')) AS stellung)
  SELECT public.modul_aktiv('SPENDEN')
     AND (SELECT stellung FROM s) <> 'AUS'
     AND ((SELECT stellung FROM s) <> 'BEI_AUFRUF'
          OR EXISTS (SELECT 1 FROM public.spendenaufrufe a, v
                      WHERE a."tenantId" = v.verein AND a.status='OEFFENTLICH'
                        AND (a.beginnt_am IS NULL OR a.beginnt_am <= current_date)
                        AND (a.endet_am   IS NULL OR a.endet_am   >= current_date)));
$$;


ALTER FUNCTION "public"."spendenseite_sichtbar"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_tenant_support"("p_tenant" "text", "p_reason" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_mail text := lower(auth.jwt() ->> 'email'); v_id uuid;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf einen Verein betreuen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_tenant) THEN
    RAISE EXCEPTION 'Verein % gibt es nicht.', p_tenant USING ERRCODE = 'check_violation';
  END IF;

  -- Immer nur ein Verein gleichzeitig, sonst waere unklar, worin man arbeitet.
  UPDATE public.platform_support SET "endedAt" = now()
   WHERE lower(email) = v_mail AND "endedAt" IS NULL;

  INSERT INTO public.platform_support (email, "tenantId", reason)
  VALUES (v_mail, p_tenant, p_reason)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;


ALTER FUNCTION "public"."start_tenant_support"("p_tenant" "text", "p_reason" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."startseite_variante"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT CASE WHEN (SELECT v.ist_premium FROM public.startseiten_vorlagen v
                     WHERE v.schluessel = public.startseiten_vorlage())
              THEN 'PREMIUM' ELSE 'STANDARD' END;
$$;


ALTER FUNCTION "public"."startseite_variante"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."startseiten_vorlage"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT v.schluessel
       FROM public.startseiten_vorlagen v
      WHERE v.aktiv
        AND v.schluessel = upper(coalesce(
              (SELECT s.system ->> 'startseitenVorlage' FROM public.settings s
                WHERE s."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
                  AND s.id = 'system'), ''))
        AND (v.modul IS NULL OR public.modul_aktiv(v.modul))),
    'KLASSISCH');
$$;


ALTER FUNCTION "public"."startseiten_vorlage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."startseiten_vorlagen_auswahl"() RETURNS TABLE("schluessel" "text", "name_de" "text", "name_en" "text", "name_sq" "text", "beschreibung_de" "text", "beschreibung_en" "text", "beschreibung_sq" "text", "ist_premium" boolean, "modul" "text", "preis_monat" numeric, "gesperrt" boolean, "gewaehlt" boolean, "reihenfolge" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT v.schluessel, v.name_de, v.name_en, v.name_sq,
         v.beschreibung_de, v.beschreibung_en, v.beschreibung_sq,
         v.ist_premium, v.modul, m.preis_monat,
         NOT (v.modul IS NULL OR public.modul_aktiv(v.modul)) AS gesperrt,
         v.schluessel = public.startseiten_vorlage() AS gewaehlt,
         v.reihenfolge
    FROM public.startseiten_vorlagen v
    LEFT JOIN public.modules m ON m.schluessel = v.modul
   WHERE v.aktiv AND public.current_tenant() IS NOT NULL
   ORDER BY v.reihenfolge;
$$;


ALTER FUNCTION "public"."startseiten_vorlagen_auswahl"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text" DEFAULT NULL::"text", "p_city" "text" DEFAULT NULL::"text", "p_members" integer DEFAULT NULL::integer, "p_note" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  v_name    text := btrim(coalesce(p_name, ''));
  v_kontakt text := btrim(coalesce(p_contact, ''));
  v_mail    text := lower(btrim(coalesce(p_email, '')));
  v_ort     text := btrim(coalesce(p_city, ''));
  v_tel     text := btrim(coalesce(p_phone, ''));
  v_notiz   text := btrim(coalesce(p_note, ''));
  v_empfaenger text := 'email@trifti.ch';
  v_zuletzt int;
  v_html    text;
BEGIN
  IF v_name = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_kontakt = '' THEN
    RAISE EXCEPTION 'Ansprechperson fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'E-Mail-Adresse ist unvollstaendig.' USING ERRCODE = 'check_violation';
  END IF;

  SELECT count(*) INTO v_zuletzt FROM public.platform_leads
   WHERE lower(coalesce(email, '')) = v_mail
     AND "createdAt" > now() - interval '5 minutes';
  IF v_zuletzt > 0 THEN
    RETURN true;
  END IF;

  INSERT INTO public.platform_leads
    (name, "contactName", email, phone, city, "expectedMembers", note, stage, "createdAt")
  VALUES (
    left(v_name, 200), left(v_kontakt, 200), left(v_mail, 200),
    left(v_tel, 60), left(v_ort, 120),
    CASE WHEN p_members IS NULL THEN NULL ELSE greatest(0, least(p_members, 100000)) END,
    left(v_notiz, 2000), 'LEAD', now()
  );

  -- Der Text enthaelt nur, was der Absender selbst angegeben hat.
  v_html :=
       '<div style="font-family:Georgia,serif;max-width:560px;margin:0 auto;padding:28px;color:#1c1917">'
    || '<p style="font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#78716c;margin:0 0 6px">'
    || 'Neue Anfrage</p>'
    || '<p style="font-size:24px;font-weight:bold;margin:0 0 20px">' || v_name || '</p>'
    || '<table style="font-size:14px;line-height:1.7;border-collapse:collapse">'
    || '<tr><td style="color:#78716c;padding-right:16px">Ansprechperson</td><td><b>' || v_kontakt || '</b></td></tr>'
    || '<tr><td style="color:#78716c;padding-right:16px">E-Mail</td><td><a href="mailto:' || v_mail || '">' || v_mail || '</a></td></tr>'
    || CASE WHEN v_tel <> '' THEN '<tr><td style="color:#78716c;padding-right:16px">Telefon</td><td>' || v_tel || '</td></tr>' ELSE '' END
    || CASE WHEN v_ort <> '' THEN '<tr><td style="color:#78716c;padding-right:16px">Ort</td><td>' || v_ort || '</td></tr>' ELSE '' END
    || CASE WHEN p_members IS NOT NULL THEN '<tr><td style="color:#78716c;padding-right:16px">Mitglieder</td><td>' || p_members || '</td></tr>' ELSE '' END
    || '</table>'
    || CASE WHEN v_notiz <> '' THEN
         '<p style="font-size:14px;line-height:1.7;margin:20px 0 0;padding:16px;background:#faf9f6;border-radius:12px">'
         || replace(left(v_notiz, 2000), E'\n', '<br>') || '</p>'
       ELSE '' END
    || '<p style="font-size:12px;color:#a8a29e;margin:28px 0 0">'
    || 'Die Anfrage steht im Betreiberbereich unter Interessenten.</p></div>';

  BEGIN
    INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind)
    VALUES ('plattform', v_empfaenger,
            'Neue Anfrage: ' || left(v_name, 120), v_html, 'LEAD');
  EXCEPTION WHEN others THEN
    -- Die Anfrage ist gespeichert. Sollte die Benachrichtigung scheitern, darf
    -- das nicht dazu fuehren, dass der Absender eine Fehlermeldung sieht und
    -- es noch einmal versucht.
    NULL;
  END;

  RETURN true;
END $_$;


ALTER FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_city" "text", "p_members" integer, "p_note" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."submit_sponsor"("p_package" "text", "p_amount" numeric, "p_company" "text", "p_contact" "text", "p_email" "text", "p_phone" "text" DEFAULT NULL::"text", "p_street" "text" DEFAULT NULL::"text", "p_zip" "text" DEFAULT NULL::"text", "p_city" "text" DEFAULT NULL::"text", "p_country" "text" DEFAULT NULL::"text", "p_website" "text" DEFAULT NULL::"text", "p_message" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  v_tenant text;
  v_id     uuid;
  v_pkg    text;
BEGIN
  v_tenant := COALESCE(public.current_tenant(), public.request_tenant());
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Sponsorenanfrage ohne erkennbaren Verein.'
      USING ERRCODE = 'check_violation';
  END IF;

  IF coalesce(btrim(p_company), '') = '' THEN
    RAISE EXCEPTION 'Firmenname fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_contact), '') = '' THEN
    RAISE EXCEPTION 'Ansprechperson fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_email), '') !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'E-Mail-Adresse ist ungueltig.' USING ERRCODE = 'check_violation';
  END IF;

  v_pkg := upper(coalesce(btrim(p_package), 'BASIC'));
  IF v_pkg NOT IN ('BASIC','STANDARD','GOLD','TOURNAMENT','CUSTOM') THEN
    v_pkg := 'CUSTOM';
  END IF;

  -- Ein eigener Betrag muss plausibel sein; Paketbetraege setzt ohnehin
  -- der Server nicht, sie dienen nur der Einordnung im Vorstand.
  IF p_amount IS NOT NULL AND (p_amount < 0 OR p_amount > 1000000) THEN
    RAISE EXCEPTION 'Betrag ist ausserhalb des zulaessigen Bereichs.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.sponsors (
    "tenantId", "packageKey", amount, currency,
    company, "contactName", email, phone,
    street, zip, city, country, website, message, status
  ) VALUES (
    v_tenant, v_pkg, p_amount, 'CHF',
    btrim(p_company), btrim(p_contact), lower(btrim(p_email)), nullif(btrim(coalesce(p_phone,'')), ''),
    nullif(btrim(coalesce(p_street,'')), ''), nullif(btrim(coalesce(p_zip,'')), ''),
    nullif(btrim(coalesce(p_city,'')), ''), nullif(btrim(coalesce(p_country,'')), ''),
    nullif(btrim(coalesce(p_website,'')), ''), nullif(btrim(coalesce(p_message,'')), ''),
    'NEW'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END $_$;


ALTER FUNCTION "public"."submit_sponsor"("p_package" "text", "p_amount" numeric, "p_company" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_street" "text", "p_zip" "text", "p_city" "text", "p_country" "text", "p_website" "text", "p_message" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_antwort_speichern"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_treffen uuid;
  v_schluss date;
  v_anzahl int;
BEGIN
  SELECT te.treffen_id, coalesce(t.anmeldeschluss, coalesce(t.ende, t.datum))
    INTO v_treffen, v_schluss
    FROM public.treffen_teilnehmer te JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Teilnehmer nicht gefunden.'; END IF;

  -- Nach dem Anmeldeschluss ist Schluss. Das steht hier und nicht in der
  -- Oberflaeche: eine Maske laesst sich umgehen.
  IF v_schluss < current_date THEN
    RAISE EXCEPTION 'Der Anmeldeschluss am % ist vorbei.', to_char(v_schluss,'DD.MM.YYYY');
  END IF;

  DELETE FROM public.treffen_delegation WHERE teilnehmer_id = p_teilnehmer;

  INSERT INTO public.treffen_delegation (teilnehmer_id, name, rolle, bemerkung)
  SELECT p_teilnehmer,
         btrim(x->>'name'),
         CASE WHEN upper(coalesce(x->>'rolle','')) = 'LEITUNG' THEN 'LEITUNG' ELSE 'TEILNEHMER' END,
         nullif(btrim(coalesce(x->>'bemerkung','')),'')
    FROM jsonb_array_elements(coalesce(p_delegation,'[]'::jsonb)) x
   WHERE coalesce(btrim(x->>'name'),'') <> '';

  SELECT count(*) INTO v_anzahl FROM public.treffen_delegation WHERE teilnehmer_id = p_teilnehmer;

  UPDATE public.treffen_teilnehmer
     SET zugesagt = p_zugesagt,
         bemerkung = nullif(btrim(coalesce(p_bemerkung,'')),''),
         -- Die Kopfzahl ergibt sich aus der Liste. Zwei Zahlen, die
         -- dasselbe meinen, laufen auseinander.
         personen = CASE WHEN p_zugesagt THEN v_anzahl ELSE 0 END,
         geantwortet_am = now()
   WHERE id = p_teilnehmer;

  RETURN jsonb_build_object('gespeichert', true, 'personen', CASE WHEN p_zugesagt THEN v_anzahl ELSE 0 END);
END $$;


ALTER FUNCTION "public"."treffen_antwort_speichern"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_ausflugslisten"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.treffen_gastgeber(p_treffen) THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id, 'titel', p.titel, 'ziel', p.ziel, 'treffpunkt', p.treffpunkt,
      'anreise', p.anreise, 'beginn', p.beginn, 'rueckkehr', p.rueckkehr,
      'plaetze', p.plaetze, 'kosten', p.kosten,
      'angemeldet', (SELECT count(*) FROM public.treffen_ausflug_anmeldung a
                      WHERE a.programm_id = p.id),
      'frei', public.ausflug_plaetze_frei(p.id),
      'leute', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                   'name', d.name,
                   'verein', coalesce(te.name, tn.name, te."tenantId"))
                   ORDER BY coalesce(te.name, tn.name, te."tenantId"), d.name), '[]'::jsonb)
                  FROM public.treffen_ausflug_anmeldung a
                  JOIN public.treffen_delegation d ON d.id = a.delegation_id
                  JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                 WHERE a.programm_id = p.id))
      ORDER BY p.tag NULLS FIRST, p.beginn), '[]'::jsonb)
    FROM public.treffen_programm p
   WHERE p.treffen_id = p_treffen AND p.art = 'AUSFLUG');
END $$;


ALTER FUNCTION "public"."treffen_ausflugslisten"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_darf_anlegen"("p_gastgeber" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT CASE
    -- Die Plattform richtet aus: nur der Betreiber.
    WHEN p_gastgeber IS NULL THEN public.is_platform_admin()
    -- Ein Verein richtet aus: der Betreiber darf es fuer ihn tun,
    -- sonst nur der Verein selbst und nur mit gebuchtem Modul.
    ELSE public.is_platform_admin()
      OR (p_gastgeber = public.current_tenant()
          AND public.is_staff()
          AND public.modul_aktiv('TREFFEN'))
  END;
$$;


ALTER FUNCTION "public"."treffen_darf_anlegen"("p_gastgeber" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_essenszahlen"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.treffen_gastgeber(p_treffen) THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (
    WITH leute AS (
      SELECT d.* FROM public.treffen_delegation d
        JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
       WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false)
    )
    SELECT jsonb_build_object(
      'gesamt', (SELECT count(*) FROM leute),
      'nach_art', (SELECT coalesce(jsonb_object_agg(essen, n), '{}'::jsonb)
                     FROM (SELECT essen, count(*) AS n FROM leute GROUP BY essen) x),
      'hinweise', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'name', name, 'essen', essen, 'hinweis', essen_hinweis)
                      ORDER BY name), '[]'::jsonb)
                     FROM leute WHERE coalesce(btrim(essen_hinweis),'') <> ''),
      'ohne_angabe', (SELECT count(*) FROM leute WHERE essen = 'KEINE_ANGABE')
    ));
END $$;


ALTER FUNCTION "public"."treffen_essenszahlen"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.treffen_antwort_speichern(
    public.treffen_token_pruefen(p_token), p_zugesagt, p_bemerkung, p_delegation);
$$;


ALTER FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_gast_lesen"("p_token" "text") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.treffen_sicht(public.treffen_token_pruefen(p_token));
$$;


ALTER FUNCTION "public"."treffen_gast_lesen"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.is_platform_admin()
      OR EXISTS (SELECT 1 FROM public.treffen t
                  WHERE t.id = p_treffen
                    AND t.gastgeber IS NOT NULL
                    AND t.gastgeber = public.current_tenant()
                    AND public.is_staff()
                    AND public.modul_aktiv('TREFFEN'));
$$;


ALTER FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_heft"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.treffen_gastgeber(p_treffen) THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.treffen_heft_inhalt(p_treffen);
END $$;


ALTER FUNCTION "public"."treffen_heft"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_heft_inhalt"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT jsonb_build_object(
    'treffen', (SELECT jsonb_build_object('titel', t.titel, 'beschreibung', t.beschreibung,
                  'datum', t.datum, 'ende', t.ende, 'ort', t.ort, 'adresse', t.adresse)
                  FROM public.treffen t WHERE t.id = p_treffen),
    'vereine', (SELECT coalesce(jsonb_agg(v ORDER BY v->>'name'), '[]'::jsonb) FROM (
        SELECT jsonb_build_object(
          'name', coalesce(te.name, tn.name, te."tenantId"),
          'art', te.art,
          'leute', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                       'name', d.name, 'funktion', d.funktion, 'rolle', d.rolle,
                       'vorstellung', d.vorstellung, 'interessen', d.interessen)
                       ORDER BY d.rolle, d.name), '[]'::jsonb)
                      FROM public.treffen_delegation d
                     WHERE d.teilnehmer_id = te.id AND d.im_heft IS TRUE),
          'stille', (SELECT count(*) FROM public.treffen_delegation d
                      WHERE d.teilnehmer_id = te.id AND coalesce(d.im_heft,false) = false)
        ) AS v
        FROM public.treffen_teilnehmer te
        LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
       WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false)
    ) y),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'titel', p.titel,
                    'ort', p.ort, 'spur', p.spur,
                    'art', p.art, 'ziel', p.ziel, 'rueckkehr', p.rueckkehr)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = p_treffen AND p.freigegeben),
    'stimmen', (SELECT count(*) FROM public.treffen_delegation d
                  JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                 WHERE te.treffen_id = p_treffen AND d.im_heft IS TRUE),
    'gesamt', (SELECT count(*) FROM public.treffen_delegation d
                 JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false))
  );
$$;


ALTER FUNCTION "public"."treffen_heft_inhalt"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_kosten"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT jsonb_build_object(
    'art', t.preis_art, 'betrag', t.preis_betrag, 'waehrung', t.waehrung,
    'vereine',  (SELECT count(*) FROM public.treffen_teilnehmer x
                  WHERE x.treffen_id = t.id AND x.art IN ('VEREIN','GASTVEREIN')
                    AND coalesce(x.zugesagt,false)),
    'personen', (SELECT coalesce(sum(x.personen),0) FROM public.treffen_teilnehmer x
                  WHERE x.treffen_id = t.id AND coalesce(x.zugesagt,false)),
    'summe', CASE t.preis_art
      WHEN 'KEINE' THEN 0
      WHEN 'PRO_VEREIN' THEN t.preis_betrag *
        (SELECT count(*) FROM public.treffen_teilnehmer x
          WHERE x.treffen_id = t.id AND x.art IN ('VEREIN','GASTVEREIN')
            AND coalesce(x.zugesagt,false))
      WHEN 'PRO_KOPF' THEN t.preis_betrag *
        (SELECT coalesce(sum(x.personen),0) FROM public.treffen_teilnehmer x
          WHERE x.treffen_id = t.id AND coalesce(x.zugesagt,false))
    END)
  FROM public.treffen t WHERE t.id = p_treffen;
$$;


ALTER FUNCTION "public"."treffen_kosten"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_mein_antworten"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Nachweisen, dass dieser Teilnehmer dem eigenen Verein gehoert. Ohne
  -- diese Pruefung koennte jeder Vorstand fuer jeden anderen antworten.
  IF NOT EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = p_teilnehmer AND te.art = 'VEREIN'
                    AND te."tenantId" = public.current_tenant() AND public.is_staff()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.treffen_antwort_speichern(p_teilnehmer, p_zugesagt, p_bemerkung, p_delegation);
END $$;


ALTER FUNCTION "public"."treffen_mein_antworten"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_meine"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL OR NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(public.treffen_sicht(te.id) ORDER BY t.datum), '[]'::jsonb)
            FROM public.treffen_teilnehmer te
            JOIN public.treffen t ON t.id = te.treffen_id
           WHERE te.art = 'VEREIN' AND te."tenantId" = v_verein
             AND t.status <> 'ENTWURF'
             AND coalesce(t.ende, t.datum) >= current_date - 1);
END $$;


ALTER FUNCTION "public"."treffen_meine"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_namensschilder"("p_treffen" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.treffen_gastgeber(p_treffen) THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
            'name', d.name, 'funktion', d.funktion, 'rolle', d.rolle,
            'verein', coalesce(te.name, tn.name, te."tenantId"))
            ORDER BY coalesce(te.name, tn.name, te."tenantId"), d.rolle, d.name), '[]'::jsonb)
            FROM public.treffen_delegation d
            JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
            LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
           WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false));
END $$;


ALTER FUNCTION "public"."treffen_namensschilder"("p_treffen" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_oeffentlich"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT coalesce(jsonb_agg(j ORDER BY j->>'datum'), '[]'::jsonb) FROM (
    SELECT jsonb_build_object(
      'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
      'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
      'ort', t.ort, 'adresse', t.adresse,
      'anmeldeschluss', t.anmeldeschluss,
      'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung,
      'gastgeber', coalesce((SELECT tn.name FROM public.tenants tn WHERE tn.id = t.gastgeber),
                            'unityhub'),
      'vereine', (SELECT coalesce(jsonb_agg(coalesce(te.name, tn.name) ORDER BY coalesce(te.name, tn.name)), '[]'::jsonb)
                    FROM public.treffen_teilnehmer te
                    LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                   WHERE te.treffen_id = t.id AND te.art IN ('VEREIN','GASTVEREIN')
                     AND coalesce(te.zugesagt,false)),
      'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                      'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                      'spur', p.spur, 'fuer', p.fuer,
                      'art', p.art, 'ziel', p.ziel, 'rueckkehr', p.rueckkehr)
                      ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                     FROM public.treffen_programm p
                    WHERE p.treffen_id = t.id AND p.freigegeben)
    ) AS j
    FROM public.treffen t
   WHERE t.status = 'OEFFENTLICH'
     -- Jede Seite zeigt ihre eigenen: der Verein seine, unityhub die der
     -- Plattform. Ohne diese Zeile stuenden Koretinis Treffen auf jeder
     -- anderen Vereinsseite.
     AND t.gastgeber IS NOT DISTINCT FROM public.request_tenant()
  ) y;
$$;


ALTER FUNCTION "public"."treffen_oeffentlich"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_programm_verschieben"("p_punkt" "uuid", "p_minuten" integer, "p_alle_spuren" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_treffen uuid; v_tag date; v_beginn time; v_spur text;
  v_zeilen int;
BEGIN
  IF NOT public.treffen_gastgeber((SELECT p.treffen_id FROM public.treffen_programm p WHERE p.id = p_punkt)) THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_minuten = 0 THEN
    RAISE EXCEPTION 'Um null Minuten verschieben aendert nichts.';
  END IF;

  SELECT treffen_id, tag, beginn, spur INTO v_treffen, v_tag, v_beginn, v_spur
    FROM public.treffen_programm WHERE id = p_punkt;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Programmpunkt nicht gefunden.'; END IF;

  UPDATE public.treffen_programm
     SET beginn = beginn + make_interval(mins => p_minuten)
   WHERE treffen_id = v_treffen
     AND coalesce(tag, '0001-01-01'::date) = coalesce(v_tag, '0001-01-01'::date)
     AND beginn >= v_beginn
     AND (p_alle_spuren OR spur = v_spur);
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;

  -- Ein UPDATE, das null Zeilen trifft, wirft keinen Fehler. Ohne diese
  -- Pruefung meldete die Oberflaeche ein Verschieben, das nie stattfand.
  IF v_zeilen = 0 THEN
    RAISE EXCEPTION 'Kein Programmpunkt verschoben.';
  END IF;

  RETURN jsonb_build_object('verschoben', v_zeilen, 'minuten', p_minuten,
                            'spur', CASE WHEN p_alle_spuren THEN 'alle' ELSE v_spur END);
END $$;


ALTER FUNCTION "public"."treffen_programm_verschieben"("p_punkt" "uuid", "p_minuten" integer, "p_alle_spuren" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_sicht"("p_teilnehmer" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT jsonb_build_object(
    'teilnehmer_id', te.id,
    'wer',   coalesce(te.name, tn.name, te."tenantId"),
    'art',   te.art,
    'zugesagt', te.zugesagt,
    'personen', te.personen,
    'bemerkung', te.bemerkung,
    'gueltig_bis', te.gueltig_bis,
    'treffen', jsonb_build_object(
      'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
      'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
      'ort', t.ort, 'adresse', t.adresse, 'status', t.status,
      'anmeldeschluss', t.anmeldeschluss,
      'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung),
    -- Nur die EIGENE Delegation. Ein Treffen darf nie der Weg werden,
    -- ueber den ein Verein die Namensliste eines anderen liest.
    'delegation', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                     'id', d.id, 'name', d.name, 'rolle', d.rolle, 'bemerkung', d.bemerkung)
                     ORDER BY d.rolle, d.name), '[]'::jsonb)
                    FROM public.treffen_delegation d WHERE d.teilnehmer_id = te.id),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                    'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                    'spur', p.spur, 'fuer', p.fuer)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = t.id AND p.freigegeben)
  )
  FROM public.treffen_teilnehmer te
  JOIN public.treffen t ON t.id = te.treffen_id
  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
 WHERE te.id = p_teilnehmer;
$$;


ALTER FUNCTION "public"."treffen_sicht"("p_teilnehmer" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_token_pruefen"("p_token" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE v_id uuid; v_bis date;
BEGIN
  SELECT id, gueltig_bis INTO v_id, v_bis
    FROM public.treffen_teilnehmer
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_id IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN v_id;
END $$;


ALTER FUNCTION "public"."treffen_token_pruefen"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_verrechnen"("p_treffen" "uuid", "p_faellig_in_tagen" integer DEFAULT 30) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  t RECORD; r RECORD;
  v_betrag numeric; v_nr text; v_n int := 0;
  v_gaeste jsonb := '[]'::jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber darf ueber die Plattform verrechnen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF (SELECT gastgeber FROM public.treffen WHERE id = p_treffen) IS NOT NULL THEN
    RAISE EXCEPTION 'Dieses Treffen richtet ein Verein aus. Die Teilnahmebeitraege sind seine Sache, nicht die der Plattform.'
      USING ERRCODE='check_violation';
  END IF;

  SELECT * INTO t FROM public.treffen WHERE id = p_treffen;
  IF t.id IS NULL THEN RAISE EXCEPTION 'Treffen nicht gefunden.'; END IF;
  IF t.preis_art = 'KEINE' THEN
    RAISE EXCEPTION 'Fuer dieses Treffen ist kein Beitrag vorgesehen.';
  END IF;

  FOR r IN
    SELECT te.*, coalesce(te.name, tn.name, te."tenantId") AS wer
      FROM public.treffen_teilnehmer te
      LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
     WHERE te.treffen_id = p_treffen
       AND te.art IN ('VEREIN','GASTVEREIN')
       AND coalesce(te.zugesagt,false)
  LOOP
    v_betrag := CASE t.preis_art
                  WHEN 'PRO_VEREIN' THEN t.preis_betrag
                  WHEN 'PRO_KOPF'   THEN t.preis_betrag * r.personen
                END;
    CONTINUE WHEN coalesce(v_betrag,0) <= 0;

    -- Ein Gastverein hat keine Vereinszeile auf der Plattform; ihm laesst
    -- sich hier keine Rechnung stellen. Er wird ausgewiesen statt
    -- stillschweigend uebersprungen -- sonst fehlt am Ende Geld, und
    -- niemand weiss warum.
    IF r.art = 'GASTVEREIN' OR r."tenantId" IS NULL THEN
      v_gaeste := v_gaeste || jsonb_build_object(
        'wer', r.wer, 'kontakt', r.kontakt_name, 'email', r.kontakt_email,
        'personen', r.personen, 'betrag', round(v_betrag,2));
      CONTINUE;
    END IF;

    v_nr := 'TR-' || to_char(t.datum,'YYYY') || '-' ||
            lpad((coalesce((SELECT count(*) FROM public.platform_invoices
                             WHERE kind='TREFFEN' AND year = extract(year FROM t.datum)),0)+v_n+1)::text, 4, '0');

    INSERT INTO public.platform_invoices
      ("tenantId", kind, amount, currency, year, status, "invoiceNumber",
       "issuedAt", "dueDate", note, treffen_id)
    VALUES (r."tenantId", 'TREFFEN', round(v_betrag,2), t.waehrung,
            -- DRAFT, nicht "OPEN": erlaubt sind DRAFT, SENT, PAID,
            -- CANCELLED. Und DRAFT ist auch sachlich richtig -- gestellt
            -- ist die Rechnung erst, wenn sie verschickt wurde.
            extract(year FROM t.datum)::int, 'DRAFT', v_nr,
            current_date, current_date + p_faellig_in_tagen,
            t.titel || CASE WHEN t.preis_art='PRO_KOPF'
                            THEN ' — ' || r.personen || ' Personen à ' || t.preis_betrag
                            ELSE ' — Teilnahmebeitrag' END,
            p_treffen)
    -- Die Bedingung des TEILWEISEN Index muss mit genannt werden. Ohne
    -- sie findet Postgres keine passende Eindeutigkeit und bricht ab:
    -- "there is no unique or exclusion constraint matching the ON CONFLICT
    -- specification". Gemessen, nicht vermutet.
    ON CONFLICT (treffen_id, "tenantId") WHERE treffen_id IS NOT NULL DO NOTHING;

    IF FOUND THEN v_n := v_n + 1; END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'gestellt', v_n,
    'ausserhalb', v_gaeste,
    'hinweis', CASE WHEN jsonb_array_length(v_gaeste) > 0
                    THEN 'Gastvereine haben keine Vereinszeile auf der Plattform. Ihre Beitraege sind hier aufgefuehrt und muessen ausserhalb gestellt werden.'
                    ELSE NULL END);
END $$;


ALTER FUNCTION "public"."treffen_verrechnen"("p_treffen" "uuid", "p_faellig_in_tagen" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_vorstellung_links"("p_teilnehmer" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
  v_bis date; v_treffen uuid; v_darf boolean; r RECORD;
  v_token text; v_liste jsonb := '[]'::jsonb;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT te.treffen_id, coalesce(t.ende, t.datum)
    INTO v_treffen, v_bis
    FROM public.treffen_teilnehmer te JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Teilnehmer nicht gefunden.'; END IF;

  -- Ausstellen darf der Gastgeber -- oder der eingeladene Verein fuer
  -- seine EIGENE Delegation. Niemand sonst.
  SELECT public.treffen_gastgeber(v_treffen)
      OR EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = p_teilnehmer AND te.art = 'VEREIN'
                    AND te."tenantId" = public.current_tenant() AND public.is_staff())
    INTO v_darf;
  IF NOT coalesce(v_darf,false) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;

  FOR r IN SELECT id, name, email FROM public.treffen_delegation
            WHERE teilnehmer_id = p_teilnehmer AND token_hash IS NULL
            ORDER BY name
  LOOP
    v_token := replace(replace(replace(
                 encode(gen_random_bytes(24), 'base64'), '+','-'), '/','_'), '=','');
    UPDATE public.treffen_delegation
       SET token_hash = encode(digest(v_token, 'sha256'), 'hex'), gueltig_bis = v_bis
     WHERE id = r.id;
    v_liste := v_liste || jsonb_build_object(
      'id', r.id, 'name', r.name, 'email', r.email, 'token', v_token);
  END LOOP;

  RETURN jsonb_build_object('gueltig_bis', v_bis, 'neue', v_liste,
    'ohne_link', (SELECT count(*) FROM public.treffen_delegation
                   WHERE teilnehmer_id = p_teilnehmer AND token_hash IS NULL));
END $$;


ALTER FUNCTION "public"."treffen_vorstellung_links"("p_teilnehmer" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_zugang_erstellen"("p_teilnehmer" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
  v_token text;
  v_bis   date;
  r RECORD;
BEGIN
  IF NOT public.treffen_gastgeber((SELECT te.treffen_id FROM public.treffen_teilnehmer te WHERE te.id = p_teilnehmer)) THEN
    RAISE EXCEPTION 'Nur der Gastgeber darf Zugaenge ausstellen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT te.*, t.datum, t.ende, t.anmeldeschluss, t.titel
    INTO r
    FROM public.treffen_teilnehmer te
    JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'Teilnehmer nicht gefunden.';
  END IF;
  IF r.art <> 'GASTVEREIN' THEN
    RAISE EXCEPTION 'Ein Link ist nur fuer Gastvereine noetig. Vereine der Plattform melden sich an ihrem Admin an.';
  END IF;

  v_bis := least(coalesce(r.anmeldeschluss, coalesce(r.ende, r.datum)),
                 coalesce(r.ende, r.datum));
  IF v_bis < current_date THEN
    RAISE EXCEPTION 'Das Treffen liegt in der Vergangenheit.';
  END IF;

  v_token := replace(replace(replace(
               encode(gen_random_bytes(32), 'base64'), '+','-'), '/','_'), '=','');

  UPDATE public.treffen_teilnehmer
     SET token_hash = encode(digest(v_token, 'sha256'), 'hex'),
         gueltig_bis = v_bis
   WHERE id = p_teilnehmer;

  RETURN jsonb_build_object('token', v_token, 'gueltig_bis', v_bis,
                            'fuer', r.name, 'treffen', r.titel);
END $$;


ALTER FUNCTION "public"."treffen_zugang_erstellen"("p_teilnehmer" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."treffen_zugang_widerrufen"("p_teilnehmer" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_zeilen int;
BEGIN
  IF NOT public.treffen_gastgeber((SELECT te.treffen_id FROM public.treffen_teilnehmer te WHERE te.id = p_teilnehmer)) THEN
    RAISE EXCEPTION 'Nur der Gastgeber darf widerrufen.' USING ERRCODE='insufficient_privilege';
  END IF;
  UPDATE public.treffen_teilnehmer
     SET token_hash = NULL, gueltig_bis = NULL
   WHERE id = p_teilnehmer AND token_hash IS NOT NULL;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  -- Ein UPDATE, das null Zeilen trifft, wirft keinen Fehler.
  IF v_zeilen <> 1 THEN
    RAISE EXCEPTION 'Kein gueltiger Zugang gefunden.';
  END IF;
  RETURN jsonb_build_object('widerrufen', true);
END $$;


ALTER FUNCTION "public"."treffen_zugang_widerrufen"("p_teilnehmer" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."users_normalise_email"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.email := NULLIF(btrim(NEW.email), '');
  RETURN NEW;
END $$;


ALTER FUNCTION "public"."users_normalise_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."users_vertreter_spalten_pruefen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_ich text; v_verboten text; v_erlaubt text[];
  v_nur_eigenes_konto boolean;
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF public.is_member_manager() OR public.is_platform_admin() THEN RETURN NEW; END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW; END IF;

  -- Die Selbstzuordnung: eine noch unverbundene Zeile bekommt MEIN
  -- Konto. Beide Bedingungen zusammen machen es unbedenklich -- eine
  -- allein nicht. Ohne die erste koennte man eine fremde Verbindung
  -- umbiegen, ohne die zweite ein fremdes Konto anhaengen.
  v_nur_eigenes_konto :=
       OLD."authUserId" IS NULL
   AND NEW."authUserId" = auth.uid()::text;

  SELECT t.vertreter_felder INTO v_erlaubt
    FROM public.tenants t WHERE t.id = NEW."tenantId";
  v_erlaubt := coalesce(v_erlaubt, '{}');

  SELECT string_agg(n.key, ', ' ORDER BY n.key) INTO v_verboten
    FROM jsonb_each(to_jsonb(NEW)) n
    LEFT JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
   WHERE n.value IS DISTINCT FROM o.value
     -- authUserId ist erlaubt, SOLANGE es die eigene Zuordnung ist.
     -- Alle uebrigen Felder bleiben unberuehrt von dieser Ausnahme:
     -- wer bei der Gelegenheit auch die Rolle aendern wollte, scheitert
     -- weiterhin an dieser Zeile.
     AND NOT (n.key = 'authUserId' AND v_nur_eigenes_konto)
     AND (NOT (n.key = ANY (v_erlaubt))
          OR n.key = ANY (public.vertreter_felder_gesperrt()));

  IF v_verboten IS NOT NULL THEN
    RAISE EXCEPTION 'Als Verantwortlicher einer Nachbarschaft koennen Sie diese Felder '
                    'nicht aendern: %. Die Vereinsadministration bestimmt, was Sie '
                    'pflegen duerfen.', v_verboten
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION "public"."users_vertreter_spalten_pruefen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verantwortliche_stand"() RETURNS TABLE("r_nachbarschaft" "text", "r_name" "text", "r_person" "text", "r_person_name" "text", "r_email" "text", "r_hat_zugang" boolean, "r_rolle" "text", "r_mitglieder" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH zustaendig AS (
    -- Alle drei Wege, auf denen jemand verantwortlich sein kann. Genau
    -- dieselben, die my_neighborhoods() auswertet -- sonst zeigte diese
    -- Uebersicht jemanden als zustaendig, der es nicht ist, oder
    -- umgekehrt.
    SELECT n.id AS nb, n.name AS nb_name, p AS person
      FROM public.neighborhoods n
      CROSS JOIN LATERAL (
        SELECT n."representativeId" AS p
        UNION SELECT n."managerId"
        UNION SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb))
      ) x
     WHERE n."tenantId" = public.current_tenant()
       AND p IS NOT NULL AND btrim(p) <> ''
  )
  SELECT z.nb, z.nb_name, z.person,
         coalesce(u."displayName", u.email, z.person),
         u.email,
         -- Das Ja oder Nein, nicht die Kennung.
         u."authUserId" IS NOT NULL,
         coalesce(u.role, '—'),
         (SELECT count(*)::int FROM public.users m
           WHERE m."tenantId" = public.current_tenant()
             AND m."neighborhoodId" = z.nb
             AND coalesce(m."membershipStatus",'ACTIVE') <> 'INACTIVE')
    FROM zustaendig z
    LEFT JOIN public.users u ON u.id = z.person
   WHERE public.is_member_manager() OR public.is_platform_admin()
   ORDER BY z.nb_name, coalesce(u."displayName", z.person);
$$;


ALTER FUNCTION "public"."verantwortliche_stand"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."verantwortliche_stand"() IS 'Je Nachbarschaft die hinterlegten Verantwortlichen und ob sie sich anmelden koennen. Gibt bewusst nur ein Ja/Nein zurueck, nicht die Kennung des Anmeldekontos.';



CREATE OR REPLACE FUNCTION "public"."verein_einrichten"("p_verein" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_n int := 0; v_jahr int := extract(year FROM current_date)::int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_verein) THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein;
  END IF;

  -- --- Kontenplan -------------------------------------------------------
  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category, "systemAccount")
  SELECT gen_random_uuid()::text, p_verein, k.code, k.name, k.klasse, k.kategorie, true
    FROM (VALUES
      ('1000','Kasse','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1020','Bankguthaben','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1021','Zahlungsdienst (PayPal, TWINT)','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1100','Forderungen Mitgliederbeitraege','AKTIVEN','UMLAUFVERMOEGEN'),
      ('2000','Verbindlichkeiten','PASSIVEN','FREMDKAPITAL'),
      ('2900','Vereinsvermoegen','PASSIVEN','EIGENKAPITAL'),
      ('3000','Ertrag Mitgliederbeitraege','ERTRAG','BETRIEBSERTRAG'),
      ('3200','Ertrag Spenden','ERTRAG','BETRIEBSERTRAG'),
      ('3600','Ertrag Veranstaltungen','ERTRAG','BETRIEBSERTRAG'),
      ('4200','Aufwand Projekte','AUFWAND','BETRIEBSAUFWAND'),
      ('4400','Aufwand Veranstaltungen','AUFWAND','BETRIEBSAUFWAND'),
      ('6000','Raumaufwand','AUFWAND','BETRIEBSAUFWAND'),
      ('6500','Verwaltungsaufwand','AUFWAND','BETRIEBSAUFWAND'),
      ('6700','Werbeaufwand','AUFWAND','BETRIEBSAUFWAND')
    ) AS k(code, name, klasse, kategorie)
   WHERE NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId" = p_verein AND a.code = k.code);
  GET DIAGNOSTICS v_n = ROW_COUNT;

  -- --- Einstellungen ----------------------------------------------------
  -- Leere Geruste, keine erfundenen Werte: eine falsche IBAN waere
  -- schlimmer als gar keine, weil der Verein sie nicht bemerkt.
  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'payment', p_verein,
         jsonb_build_object('currency','CHF','fees',
           jsonb_build_object('STANDARD', jsonb_build_object('label','Standard','amount',0,'currency','CHF'))),
         '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='payment');

  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'system', p_verein, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
         jsonb_build_object('allowRegistration', true, 'maintenanceMode', false),
         '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='system');

  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'company', p_verein, '{}'::jsonb,
         jsonb_build_object('name', (SELECT name FROM public.tenants WHERE id=p_verein)),
         '{}'::jsonb, '{}'::jsonb, '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='company');

  -- --- Geschaeftsjahr ---------------------------------------------------
  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  SELECT gen_random_uuid()::text, p_verein, v_jahr, 'OPEN'
   WHERE NOT EXISTS (SELECT 1 FROM public.fiscal_years
                      WHERE "tenantId"=p_verein AND year=v_jahr);

  RETURN p_verein || ': ' || v_n || ' Konten, Einstellungen und Geschaeftsjahr ' || v_jahr;
END $$;


ALTER FUNCTION "public"."verein_einrichten"("p_verein" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vereins_administrator_setzen"("p_verein" "text", "p_email" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  v_mail  text := lower(btrim(coalesce(p_email, '')));
  v_id    text;
  v_rolle text;
  v_fremd text;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf den Administrator eines Vereins setzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_verein) THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein USING ERRCODE = 'check_violation';
  END IF;
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Ohne echte E-Mail-Adresse gibt es kein Anmeldekonto.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT "tenantId" INTO v_fremd FROM public.users
   WHERE lower(email) = v_mail AND "tenantId" <> p_verein LIMIT 1;
  IF v_fremd IS NOT NULL THEN
    RAISE EXCEPTION 'Die Adresse % gehoert bereits zum Verein %.', v_mail, v_fremd
      USING ERRCODE = 'unique_violation';
  END IF;

  SELECT id, coalesce(role,'MEMBER') INTO v_id, v_rolle FROM public.users
   WHERE "tenantId" = p_verein AND lower(email) = v_mail LIMIT 1;

  IF v_id IS NULL THEN
    v_id := gen_random_uuid()::text;
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (v_id, p_verein, v_mail, 'ADMIN', 'ACTIVE', v_mail, now());
  ELSIF v_rolle <> 'ADMIN' THEN
    -- Der Betreiber setzt hier bewusst. Eine SUPER_ADMIN-Zeile wird nicht
    -- heruntergestuft, alles andere wird zur Administration erhoben.
    IF v_rolle <> 'SUPER_ADMIN' THEN
      UPDATE public.users SET role = 'ADMIN' WHERE id = v_id;
    END IF;
  END IF;

  -- Legt das Anmeldekonto an, verknuepft es und protokolliert. Der Betreiber
  -- darf das vereinsuebergreifend; das prueft die Funktion selbst.
  RETURN public.reset_member_password(v_id) || jsonb_build_object('tenantId', p_verein);
END $_$;


ALTER FUNCTION "public"."vereins_administrator_setzen"("p_verein" "text", "p_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vereinsjahr_erinnern"("p_tag" "date" DEFAULT NULL::"date") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."vereinsjahr_erinnern"("p_tag" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vereinsjahr_text"("p_schluessel" "text", "p_sprache" "text") RETURNS TABLE("titel" "text", "hinweis" "text")
    LANGUAGE "sql" IMMUTABLE
    AS $$
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


ALTER FUNCTION "public"."vereinsjahr_text"("p_schluessel" "text", "p_sprache" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vertreter_felder_gesperrt"() RETURNS "text"[]
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT ARRAY['id','tenantId','authUserId','role','neighborhoodId','membershipStatus'];
$$;


ALTER FUNCTION "public"."vertreter_felder_gesperrt"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vertreter_felder_setzen"("p_felder" "text"[]) RETURNS "text"[]
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_gut text[]; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration bestimmt die Rechte der Verantwortlichen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Nur Spalten, die es gibt, und keine gesperrte. Die Pruefung steht
  -- HIER und nicht in der Maske: eine Oberflaeche, die etwas weglaesst,
  -- ist keine Schranke -- genau daran ist die erste Fassung gescheitert.
  SELECT coalesce(array_agg(DISTINCT f ORDER BY f), '{}') INTO v_gut
    FROM unnest(coalesce(p_felder, '{}')) AS f
   WHERE f = ANY (SELECT column_name FROM information_schema.columns
                   WHERE table_schema='public' AND table_name='users')
     AND NOT (f = ANY (public.vertreter_felder_gesperrt()));

  UPDATE public.tenants SET vertreter_felder = v_gut WHERE id = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Verein % nicht gefunden.', v_verein USING ERRCODE='check_violation';
  END IF;
  RETURN v_gut;
END $$;


ALTER FUNCTION "public"."vertreter_felder_setzen"("p_felder" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vertreter_spalten_schuetzen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_ich text; v_verboten text; v_erlaubt text[];
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF public.is_member_manager() OR public.is_platform_admin() THEN RETURN NEW; END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW; END IF;

  SELECT t.vertreter_felder INTO v_erlaubt
    FROM public.tenants t WHERE t.id = NEW."tenantId";
  v_erlaubt := coalesce(v_erlaubt, '{}');

  -- Gesperrtes bleibt gesperrt, auch wenn es jemand in die Liste
  -- geschrieben haette. Zwei Stellen, die dasselbe pruefen, laufen sonst
  -- auseinander -- diese hier ist die letzte vor der Zeile.
  SELECT string_agg(n.key, ', ' ORDER BY n.key) INTO v_verboten
    FROM jsonb_each(to_jsonb(NEW)) n
    LEFT JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
   WHERE n.value IS DISTINCT FROM o.value
     AND (NOT (n.key = ANY (v_erlaubt))
          OR n.key = ANY (public.vertreter_felder_gesperrt()));

  IF v_verboten IS NOT NULL THEN
    RAISE EXCEPTION 'Als Verantwortlicher einer Nachbarschaft koennen Sie diese Felder '
                    'nicht aendern: %. Die Vereinsadministration bestimmt, was Sie '
                    'pflegen duerfen.', v_verboten
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION "public"."vertreter_spalten_schuetzen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vorstand_schreibrecht"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT coalesce((SELECT t.vorstand_schreibt FROM public.tenants t
                    WHERE t.id = public.current_tenant()), true);
$$;


ALTER FUNCTION "public"."vorstand_schreibrecht"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vorstand_schreibrecht_setzen"("p_an" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_n int;
BEGIN
  -- Der Betreiber darf immer; im Verein nur die Administration.
  -- BOARD steht bewusst NICHT in der Liste: wer sich das Recht selbst
  -- zurueckgeben kann, hat es nie verloren.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf das Schreibrecht des Vorstands aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.tenants SET vorstand_schreibt = coalesce(p_an, true)
   WHERE id = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend sich nichts geaendert haette.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Verein % nicht gefunden.', v_verein USING ERRCODE = 'check_violation';
  END IF;

  RETURN coalesce(p_an, true);
END $$;


ALTER FUNCTION "public"."vorstand_schreibrecht_setzen"("p_an" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vorstellung_lesen"("p_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE d RECORD;
BEGIN
  SELECT dg.*, te.art, coalesce(te.name, tn.name, te."tenantId") AS verein,
         t.id AS treffen_id, t.titel, t.datum, t.ende, t.ort, t.beschreibung
    INTO d
    FROM public.treffen_delegation dg
    JOIN public.treffen_teilnehmer te ON te.id = dg.teilnehmer_id
    JOIN public.treffen t ON t.id = te.treffen_id
    LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
   WHERE dg.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  -- Dieselbe Meldung fuer "gibt es nicht" und "abgelaufen".
  IF d.id IS NULL OR d.gueltig_bis IS NULL OR d.gueltig_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  RETURN jsonb_build_object(
    'name', d.name, 'verein', d.verein, 'rolle', d.rolle,
    'email', d.email, 'funktion', d.funktion,
    'vorstellung', d.vorstellung, 'interessen', d.interessen,
    'essen', d.essen, 'essen_hinweis', d.essen_hinweis,
    'im_heft', d.im_heft, 'vorgestellt_am', d.vorgestellt_am,
    'treffen', jsonb_build_object('titel', d.titel, 'datum', d.datum,
                                  'ende', d.ende, 'ort', d.ort,
                                  'beschreibung', d.beschreibung));
END $$;


ALTER FUNCTION "public"."vorstellung_lesen"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE v_id uuid; v_bis date; v_zeilen int;
BEGIN
  SELECT id, gueltig_bis INTO v_id, v_bis FROM public.treffen_delegation
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_id IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  UPDATE public.treffen_delegation
     SET name        = coalesce(nullif(btrim(coalesce(p_name,'')),''), name),
         funktion    = nullif(btrim(coalesce(p_funktion,'')),''),
         vorstellung = nullif(btrim(coalesce(p_vorstellung,'')),''),
         interessen  = nullif(btrim(coalesce(p_interessen,'')),''),
         essen       = coalesce(nullif(p_essen,''), 'KEINE_ANGABE'),
         essen_hinweis = nullif(btrim(coalesce(p_essen_hinweis,'')),''),
         im_heft     = p_im_heft,
         vorgestellt_am = now()
   WHERE id = v_id;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  IF v_zeilen <> 1 THEN RAISE EXCEPTION 'Nicht gespeichert.'; END IF;

  RETURN jsonb_build_object('gespeichert', true);
END $$;


ALTER FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wer_bin_ich"() RETURNS TABLE("ist_betreiber" boolean, "verein" "text", "vereinsname" "text", "vereinsdomain" "text", "rolle" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_ich text := public.current_user_row_id();
        v_verein text;
BEGIN
  SELECT u."tenantId" INTO v_verein FROM public.users u WHERE u.id = v_ich;

  RETURN QUERY
  SELECT
    public.is_platform_admin(),
    v_verein,
    (SELECT t.name FROM public.tenants t WHERE t.id = v_verein),
    -- Die Adresse, unter der dieser Verein erreichbar ist. Ohne "www.",
    -- weil sie als Verweis angezeigt wird.
    (SELECT d.domain FROM public.tenant_domains d
      WHERE d."tenantId" = v_verein AND d.domain NOT LIKE 'localhost%'
      ORDER BY (d.domain LIKE 'www.%'), length(d.domain) LIMIT 1),
    coalesce((SELECT u.role FROM public.users u WHERE u.id = v_ich), 'MEMBER');
END $$;


ALTER FUNCTION "public"."wer_bin_ich"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."widersprueche_zaehlen"() RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT count(*)::int FROM public.users u
   WHERE u."tenantId" = public.current_tenant()
     AND coalesce(u.nicht_oeffentlich,false)
     AND public.is_staff();
$$;


ALTER FUNCTION "public"."widersprueche_zaehlen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."willkommen_einreihen"("p_member" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."willkommen_einreihen"("p_member" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."willkommen_einreihen"("p_member" "text") IS 'Reiht die Willkommensnachricht fuer ein Mitglied ein. Verschickt nichts -- das tut der Postausgang. Mehrfachaufruf ist unschaedlich.';



CREATE OR REPLACE FUNCTION "public"."wochenstart_einreihen"("p_tag" "date" DEFAULT NULL::"date") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  v_tag    date := coalesce(p_tag, (now() AT TIME ZONE 'Europe/Zurich')::date);
  v_n      int  := 0;
  v        record;   -- Verein
  e        record;   -- Empfaenger
  v_offen_n   int; v_offen_s numeric;
  v_meld_n    int; v_meld_s  numeric;
  v_anl    text; v_anl_n int;
  v_block  text; v_html text; v_betreff text;
  v_sprache text;
BEGIN
  -- Der Zeitplan laeuft ohne Anmeldung. Ein angemeldeter Aufrufer muss der
  -- Betreiber sein -- sonst koennte jemand den Versand von Hand ausloesen.
  IF auth.uid() IS NOT NULL AND NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Wochenstart ausloesen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR v IN
    SELECT f."tenantId", f.wochenstart_an, coalesce(f.assistent_name,'Floky') AS helfer,
           t.name AS vereinsname
      FROM public.floky_einstellungen f
      JOIN public.tenants t ON t.id = f."tenantId"
     WHERE coalesce(array_length(f.wochenstart_an, 1), 0) > 0
       -- Nur wo das Modul laeuft. Ohne das bekaeme ein Verein Post fuer
       -- etwas, das er nicht gebucht hat.
       AND EXISTS (SELECT 1 FROM public.tenant_modules tm
                    WHERE tm."tenantId" = f."tenantId" AND tm.modul = 'FLOKY'
                      AND tm.zustand IN ('AN','TESTPHASE'))
  LOOP
    -- Offene Beitraege
    SELECT count(*), coalesce(sum(p.amount), 0) INTO v_offen_n, v_offen_s
      FROM public.payments p
     WHERE p."tenantId" = v."tenantId"
       AND p.status NOT IN ('PAID','CANCELLED','WRITTEN_OFF');

    -- Meldungen der Vertreter, die auf Entscheid warten
    SELECT count(*), coalesce(sum(r.amount), 0) INTO v_meld_n, v_meld_s
      FROM public.payment_reports r
     WHERE r."tenantId" = v."tenantId" AND r.status = 'OPEN';

    -- Anlaesse der naechsten 14 Tage
    SELECT count(*), string_agg(
             '<li>' || to_char(x.date, 'DD.MM.YYYY') || ' — ' ||
             replace(replace(x.title, '&', '&amp;'), '<', '&lt;') ||
             ' (' || x.koepfe || ' Personen)</li>', '')
      INTO v_anl_n, v_anl
      FROM (
        -- events.date ist TEXT, nicht date. Gemessen: alle 5 Eintraege im
        -- Muster JJJJ-MM-TT. Trotzdem wird geprueft statt gecastet -- ein
        -- einziger abweichender Eintrag liesse sonst den ganzen Versand
        -- scheitern, und zwar fuer alle Vereine.
        SELECT ev.date::date AS date, ev.title,
               (SELECT coalesce(sum(coalesce(reg.tickets, 1)), 0)
                  FROM public.event_registrations reg
                 WHERE reg."eventId" = ev.id
                   AND coalesce(reg.status,'') <> 'CANCELLED') AS koepfe
          FROM public.events ev
         WHERE ev."tenantId" = v."tenantId"
           AND ev.date ~ '^\d{4}-\d{2}-\d{2}$'
           AND ev.date::date >= v_tag AND ev.date::date <= v_tag + 14
         ORDER BY ev.date
      ) x;

    -- Nichts zu sagen? Dann auch nichts verschicken.
    CONTINUE WHEN v_offen_n = 0 AND v_meld_n = 0 AND coalesce(v_anl_n,0) = 0;

    FOR e IN
      SELECT u.id, u.email, u."displayName", coalesce(u.sprache, 'de') AS sprache
        FROM public.users u
       WHERE u.id = ANY (v.wochenstart_an)
         AND u."tenantId" = v."tenantId"
         AND u.email IS NOT NULL AND u.email LIKE '%@%'
    LOOP
      v_sprache := CASE WHEN e.sprache IN ('de','sq','en') THEN e.sprache ELSE 'de' END;
      v_block := '';

      IF v_offen_n > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Kuota të hapura'
                         WHEN 'en' THEN 'Open fees'
                         ELSE 'Offene Beiträge' END ||
          ':</strong> ' || v_offen_n || ' × CHF ' ||
          replace(to_char(v_offen_s, 'FM999,999,990.00'), ',', '''') || '</p>';
      END IF;

      IF v_meld_n > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Pagesa të raportuara, në pritje'
                         WHEN 'en' THEN 'Reported payments awaiting a decision'
                         ELSE 'Gemeldete Zahlungen, noch offen' END ||
          ':</strong> ' || v_meld_n || ' × CHF ' ||
          replace(to_char(v_meld_s, 'FM999,999,990.00'), ',', '''') || '</p>';
      END IF;

      IF coalesce(v_anl_n,0) > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Ngjarjet e 14 ditëve të ardhshme'
                         WHEN 'en' THEN 'Events in the next 14 days'
                         ELSE 'Anlässe der nächsten 14 Tage' END ||
          ':</strong></p><ul>' || v_anl || '</ul>';
      END IF;

      v_betreff := CASE v_sprache
        WHEN 'sq' THEN 'Fillimi i javës — ' || v.vereinsname
        WHEN 'en' THEN 'Week start — ' || v.vereinsname
        ELSE 'Wochenstart — ' || v.vereinsname END;

      v_html :=
        '<p>' || CASE v_sprache
          WHEN 'sq' THEN 'Përshëndetje ' WHEN 'en' THEN 'Hello ' ELSE 'Guten Abend ' END
        || coalesce(e."displayName",'') || '</p>' || v_block ||
        '<p style="color:#888;font-size:12px">' ||
        CASE v_sprache
          WHEN 'sq' THEN 'Këtë përmbledhje e dërgon ' || v.helfer ||
               '. Mund ta çaktivizoni te cilësimet e shoqatës.'
          WHEN 'en' THEN 'This digest comes from ' || v.helfer ||
               '. It can be switched off in the association settings.'
          ELSE 'Diese Übersicht kommt von ' || v.helfer ||
               '. Sie lässt sich in den Vereinseinstellungen abbestellen.'
        END || '</p>';

      -- Zweimal am selben Tag waere ein Fehler, keine Erinnerung.
      CONTINUE WHEN EXISTS (
        SELECT 1 FROM public.mail_queue q
         WHERE q."tenantId" = v."tenantId" AND q.recipient = e.email
           AND q.kind = 'WOCHENSTART'
           AND q."createdAt" >= v_tag::timestamptz);

      INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind, "memberId", status)
      VALUES (v."tenantId", e.email, v_betreff, v_html, 'WOCHENSTART', e.id, 'PENDING');
      v_n := v_n + 1;
    END LOOP;
  END LOOP;

  RETURN v_n;
END $_$;


ALTER FUNCTION "public"."wochenstart_einreihen"("p_tag" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlung_differenz_setzen"("p_payment" "text", "p_art" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r record;
  v_me text := public.current_user_row_id();
  v_differenz numeric;
  v_bezug text;
  v_ertragskonto text;
  v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf das entscheiden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_art IS NULL OR p_art NOT IN ('OFFEN','SPENDE','GUTHABEN','ERLASS') THEN
    RAISE EXCEPTION 'Unbekannte Art: %. Erlaubt sind OFFEN, SPENDE, GUTHABEN, ERLASS.', p_art
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_differenz := coalesce(r.bezahlt, 0) - r.amount;
  v_bezug := p_payment || ':differenz';

  -- Die Richtung muss zur Art passen. Einen Mehrbetrag zu "erlassen"
  -- oder einen Minderbetrag zur "Spende" zu machen waere eine Buchung
  -- mit falschem Vorzeichen -- formal durchgelassen, inhaltlich Unsinn,
  -- und in der Bilanz erst beim Abschluss auffaellig.
  IF p_art IN ('SPENDE','GUTHABEN') AND v_differenz <= 0 THEN
    RAISE EXCEPTION 'Es wurde nicht mehr bezahlt als verrechnet (Differenz %).', v_differenz
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_art = 'ERLASS' AND v_differenz >= 0 THEN
    RAISE EXCEPTION 'Es ist nichts offen, was erlassen werden koennte (Differenz %).', v_differenz
      USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from current_date)::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das laufende Geschaeftsjahr ist abgeschlossen.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Ohne Kontenplan wird nur die Art vermerkt, nicht gebucht -- gleicher
  -- Grund wie bei eingang_verbuchen.
  IF NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                  WHERE a."tenantId" = r."tenantId" AND a.code = '1100') THEN
    UPDATE public.payments SET "differenzArt" = p_art WHERE id = p_payment;
    RETURN jsonb_build_object('art', p_art, 'differenz', v_differenz,
                              'gebucht', false,
                              'hinweis', 'Kein Kontenplan -- nur vermerkt.');
  END IF;

  -- Eine frühere Entscheidung weicht. Sie stehenzulassen ergaebe zwei
  -- Buchungen fuer denselben Betrag.
  DELETE FROM public.accounting_journal
   WHERE "tenantId" = r."tenantId" AND "referenceId" = v_bezug;

  IF p_art = 'SPENDE' OR p_art = 'GUTHABEN' THEN
    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry")
    VALUES (gen_random_uuid()::text, r."tenantId", current_date::text,
            CASE WHEN p_art = 'SPENDE' THEN 'Mehrbetrag als Spende '
                 ELSE 'Mehrbetrag als Guthaben ' END
              || coalesce(nullif(r."invoiceNumber",''), r.id),
            '1100', CASE WHEN p_art = 'SPENDE' THEN '3200' ELSE '2000' END,
            v_differenz, v_bezug, true);

  ELSIF p_art = 'ERLASS' THEN
    -- Das Ertragskonto aus der Forderungsbuchung nehmen, nicht raten:
    -- der Verein bucht Diaspora auf 3000 und Kosovo auf 3100. Mit einem
    -- festen 3000 waere die Ruecknahme auf dem falschen Konto gelandet
    -- und die beiden Ertragsarten haetten nicht mehr gestimmt.
    SELECT j."creditCode" INTO v_ertragskonto
      FROM public.accounting_journal j
     WHERE j."tenantId" = r."tenantId" AND j."referenceId" = r.id
       AND j."creditCode" IN ('3000','3100')
     ORDER BY j."createdAt" NULLS LAST LIMIT 1;

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "isSystemEntry")
    VALUES (gen_random_uuid()::text, r."tenantId", current_date::text,
            'Erlass Restbetrag ' || coalesce(nullif(r."invoiceNumber",''), r.id),
            coalesce(v_ertragskonto, '3000'), '1100', -v_differenz, v_bezug, true);
  END IF;

  UPDATE public.payments SET "differenzArt" = p_art WHERE id = p_payment;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Rechnung wurde nicht geaendert.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN jsonb_build_object('art', p_art, 'differenz', v_differenz,
                            'gebucht', p_art <> 'OFFEN');
END $$;


ALTER FUNCTION "public"."zahlung_differenz_setzen"("p_payment" "text", "p_art" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlung_eingang_entfernen"("p_eingang" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE r record; v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf das.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.zahlungseingaenge WHERE id = p_eingang;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Eingang gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieser Eingang gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from r.eingang)::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.',
      extract(year from r.eingang)::int USING ERRCODE = 'check_violation';
  END IF;

  -- Die Buchung zum Eingang mit entfernen. Sie traegt den Eingang als
  -- Bezug, darum ist sie eindeutig auffindbar.
  DELETE FROM public.accounting_journal
   WHERE "tenantId" = r."tenantId" AND "referenceId" = p_eingang::text;

  DELETE FROM public.zahlungseingaenge WHERE id = p_eingang;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein DELETE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend die Zeile stehenblieb.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Der Eingang wurde nicht entfernt.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN true;
END $$;


ALTER FUNCTION "public"."zahlung_eingang_entfernen"("p_eingang" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlung_eingang_erfassen"("p_payment" "text", "p_betrag" numeric, "p_weg" "text" DEFAULT NULL::"text", "p_eingang" "date" DEFAULT NULL::"date", "p_notiz" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r record;
  v_me text := public.current_user_row_id();
  v_id uuid;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf einen Zahlungseingang erfassen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_betrag IS NULL OR p_betrag = 0 THEN
    RAISE EXCEPTION 'Ein Zahlungseingang ohne Betrag ergibt keinen Sinn.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Ein abgeschlossenes Geschaeftsjahr nimmt keine Buchung mehr an. Ohne
  -- diese Pruefung waere der Jahresabschluss eine Anzeige und keine
  -- Schranke -- und die Revision haette keinen festen Stand.
  IF EXISTS (SELECT 1 FROM public.fiscal_years f
              WHERE f."tenantId" = r."tenantId"
                AND f.year = extract(year from coalesce(p_eingang, current_date))::int
                AND f.status = 'CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.',
      extract(year from coalesce(p_eingang, current_date))::int
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.zahlungseingaenge
    ("tenantId", "paymentId", betrag, waehrung, weg, eingang, "erfasstVon", notiz)
  VALUES (r."tenantId", p_payment, p_betrag, coalesce(r.currency, 'CHF'),
          coalesce(p_weg, r.method), coalesce(p_eingang, current_date), v_me, p_notiz)
  RETURNING id INTO v_id;

  -- Eine offene Meldung zu dieser Rechnung gilt damit als erledigt --
  -- derselbe Gedanke wie in mark_payment_paid. Sonst bliebe sie beim
  -- Vorstand als unentschieden stehen, obwohl das Geld erfasst ist.
  UPDATE public.payment_reports
     SET status = 'CONFIRMED', "decidedBy" = v_me, "decidedAt" = now(),
         "decisionNote" = 'Zahlungseingang erfasst'
   WHERE "paymentId" = p_payment AND status = 'OPEN';

  RETURN v_id;
END $$;


ALTER FUNCTION "public"."zahlung_eingang_erfassen"("p_payment" "text", "p_betrag" numeric, "p_weg" "text", "p_eingang" "date", "p_notiz" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlung_stand_pflegen"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_zahlung text := coalesce(NEW."paymentId", OLD."paymentId");
  v_summe numeric;
  v_soll numeric;
  v_status text;
  v_letzter date;
BEGIN
  SELECT coalesce(sum(e.betrag), 0), max(e.eingang)
    INTO v_summe, v_letzter
    FROM public.zahlungseingaenge e
   WHERE e."paymentId" = v_zahlung;

  SELECT p.amount, p.status INTO v_soll, v_status
    FROM public.payments p WHERE p.id = v_zahlung;

  -- Eine abgeschriebene Rechnung bleibt abgeschrieben. Sie durch einen
  -- Eingang wieder zu oeffnen waere eine stille Entscheidung ueber einen
  -- Vorgang, den jemand ausdruecklich beendet hat.
  IF v_status = 'CANCELLED' THEN
    UPDATE public.payments SET bezahlt = v_summe WHERE id = v_zahlung;
    RETURN NULL;
  END IF;

  UPDATE public.payments
     SET bezahlt = v_summe,
         status = CASE WHEN v_soll > 0 AND v_summe >= v_soll THEN 'PAID'
                       ELSE 'PENDING' END,
         -- paidAt nur setzen, wenn die Rechnung damit gedeckt ist.
         -- Bei einer Teilzahlung bliebe sonst ein Datum stehen, das
         -- "bezahlt am" bedeutet und es nicht ist.
         "paidAt" = CASE WHEN v_soll > 0 AND v_summe >= v_soll
                         THEN coalesce(v_letzter::text, current_date::text)
                         ELSE NULL END
   WHERE id = v_zahlung;

  RETURN NULL;
END $$;


ALTER FUNCTION "public"."zahlung_stand_pflegen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlungen_verbuchen"("p_jahr" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_gebucht int := 0;
  v_uebersprungen int := 0;
  r RECORD;
  v_soll text;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf verbuchen.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('BUCHHALTUNG') THEN
    RAISE EXCEPTION 'Das Modul Buchhaltung ist nicht aktiv.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId"=v_verein AND year=p_jahr AND status='CLOSED') THEN
    RAISE EXCEPTION 'Das Geschaeftsjahr % ist abgeschlossen.', p_jahr;
  END IF;

  FOR r IN
    SELECT p.id, p.amount, p.currency, p.method, p.description, p."invoiceNumber",
           coalesce(p."paidAt", p.timestamp::text) AS datum
      FROM public.payments p
     WHERE p."tenantId" = v_verein
       AND p.status = 'PAID'
       AND coalesce(p."bookedInJournal", false) = false
       AND substr(coalesce(p."paidAt", p.timestamp::text), 1, 4) = p_jahr::text
       -- Neu: Zahlungen mit erfassten Eingaengen sind dort gebucht.
       AND NOT EXISTS (SELECT 1 FROM public.zahlungseingaenge e
                        WHERE e."paymentId" = p.id AND e.altbestand = false)
  LOOP
    IF EXISTS (SELECT 1 FROM public.accounting_journal j
                WHERE j."tenantId"=v_verein AND j."referenceId"=r.id) THEN
      UPDATE public.payments SET "bookedInJournal" = true WHERE id = r.id AND "tenantId"=v_verein;
      v_uebersprungen := v_uebersprungen + 1;
      CONTINUE;
    END IF;

    v_soll := CASE
      WHEN r.method = 'CASH'   THEN CASE WHEN r.currency = 'EUR' THEN '1001' ELSE '1000' END
      WHEN r.method = 'PAYPAL' THEN '1021'
      ELSE '1020' END;

    INSERT INTO public.accounting_journal
      (id, "tenantId", date, description, "debitCode", "creditCode", amount,
       "referenceId", "createdAt")
    VALUES (gen_random_uuid()::text, v_verein, substr(r.datum,1,10),
            'Zahlungseingang: ' || coalesce(r.description,'Mitgliederbeitrag')
              || ' (' || coalesce(r."invoiceNumber",'-') || ')',
            v_soll, '1100', r.amount, r.id, now());

    UPDATE public.payments SET "bookedInJournal" = true WHERE id = r.id AND "tenantId" = v_verein;
    v_gebucht := v_gebucht + 1;
  END LOOP;

  RETURN jsonb_build_object('jahr', p_jahr, 'gebucht', v_gebucht,
                            'nachgetragen', v_uebersprungen);
END $$;


ALTER FUNCTION "public"."zahlungen_verbuchen"("p_jahr" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlungsgeheimnis_setzen"("p_client_id" "text", "p_secret" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Zugangsdaten sind Sache der Administration, nicht des Vorstands.
  -- Wer das Geheimnis setzen kann, kann Zahlungen umleiten.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf Zahlungszugangsdaten setzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.zahlungsgeheimnisse
    ("tenantId", paypal_client_id, paypal_secret, geaendert_am, geaendert_von)
  VALUES (v_verein, nullif(btrim(coalesce(p_client_id,'')), ''),
          nullif(btrim(coalesce(p_secret,'')), ''), now(),
          public.current_user_row_id())
  ON CONFLICT ("tenantId") DO UPDATE
     SET paypal_client_id = EXCLUDED.paypal_client_id,
         paypal_secret = EXCLUDED.paypal_secret,
         geaendert_am = now(),
         geaendert_von = EXCLUDED.geaendert_von;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Zugangsdaten wurden nicht gespeichert.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Gibt den STAND zurueck, nicht den Wert. Ein Rueckgabewert mit dem
  -- Geheimnis darin waere derselbe Fehler eine Ebene weiter: er stuende
  -- in der Antwort, im Protokoll des Browsers und womoeglich in einer
  -- Fehlermeldung.
  RETURN public.zahlungsgeheimnis_stand();
END $$;


ALTER FUNCTION "public"."zahlungsgeheimnis_setzen"("p_client_id" "text", "p_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zahlungsgeheimnis_stand"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_verein text := public.current_tenant(); g record;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO g FROM public.zahlungsgeheimnisse WHERE "tenantId" = v_verein;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('hinterlegt', false);
  END IF;

  RETURN jsonb_build_object(
    'hinterlegt', coalesce(g.paypal_secret, '') <> '',
    'client_id_hinterlegt', coalesce(g.paypal_client_id, '') <> '',
    -- Die letzten vier Zeichen, damit man zwei Schluessel unterscheiden
    -- kann, ohne einen davon zu kennen. Vier aus etwa achtzig lassen
    -- sich nicht zurueckrechnen.
    'endet_auf', CASE WHEN length(coalesce(g.paypal_secret,'')) > 8
                      THEN right(g.paypal_secret, 4) ELSE NULL END,
    'geaendert_am', g.geaendert_am,
    'geaendert_von', (SELECT coalesce(u."displayName", u.id) FROM public.users u
                       WHERE u.id = g.geaendert_von));
END $$;


ALTER FUNCTION "public"."zahlungsgeheimnis_stand"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zeitplan_token_gueltig"("p_token" "text") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.mail_settings
     WHERE zeitplan_token = p_token AND btrim(coalesce(p_token,'')) <> ''
  );
$$;


ALTER FUNCTION "public"."zeitplan_token_gueltig"("p_token" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."accounting_accounts" (
    "id" "text" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "class" "text" NOT NULL,
    "category" "text",
    "systemAccount" boolean DEFAULT false,
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."accounting_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."accounting_journal" (
    "id" "text" NOT NULL,
    "date" "text" NOT NULL,
    "description" "text" NOT NULL,
    "debit" "text",
    "credit" "text",
    "amount" numeric NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "debitCode" "text",
    "creditCode" "text",
    "referenceId" "text",
    "createdAt" timestamp with time zone DEFAULT "now"(),
    "isSystemEntry" boolean DEFAULT false,
    "belegnr" integer
);


ALTER TABLE "public"."accounting_journal" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."accounting_journal_archiv" (
    "id" "text" NOT NULL,
    "tenantId" "text",
    "zeile" "jsonb" NOT NULL,
    "entfernt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "grund" "text" NOT NULL
);


ALTER TABLE "public"."accounting_journal_archiv" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_emails" (
    "email" "text" NOT NULL
);


ALTER TABLE "public"."admin_emails" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."board_meeting_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "meetingId" "text" NOT NULL,
    "version" integer NOT NULL,
    "snapshot" "jsonb" NOT NULL,
    "changedBy" "text",
    "changedAt" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."board_meeting_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."board_meetings" (
    "id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "date" "text" NOT NULL,
    "boardMembers" "jsonb" DEFAULT '[]'::"jsonb",
    "decisions" "jsonb" DEFAULT '[]'::"jsonb",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "location" "text",
    "attendees" "jsonb" DEFAULT '[]'::"jsonb",
    "agendaItems" "jsonb" DEFAULT '[]'::"jsonb",
    "status" "text" DEFAULT 'PLANNED'::"text",
    "documents" "jsonb" DEFAULT '[]'::"jsonb",
    "version" integer DEFAULT 1 NOT NULL,
    "updatedAt" timestamp with time zone,
    "updatedBy" "text",
    "publishedToMembers" boolean DEFAULT false NOT NULL,
    "publishedAt" timestamp with time zone,
    "publishedBy" "text"
);


ALTER TABLE "public"."board_meetings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."board_members" (
    "id" "text" NOT NULL,
    "userId" "text" NOT NULL,
    "role" "text" DEFAULT 'MEMBER'::"text",
    "joinedAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "quote" "text",
    "image" "text",
    "createdAt" timestamp with time zone DEFAULT "now"(),
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."board_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."buchungsprotokoll" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "buchung_id" "text" NOT NULL,
    "vorgang" "text" NOT NULL,
    "vorher" "jsonb" NOT NULL,
    "nachher" "jsonb",
    "wer" "text",
    "wer_email" "text",
    "wann" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "buchungsprotokoll_vorgang_check" CHECK (("vorgang" = ANY (ARRAY['AENDERUNG'::"text", 'LOESCHUNG'::"text"])))
);


ALTER TABLE "public"."buchungsprotokoll" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."donations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "betrag" numeric(10,2) NOT NULL,
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "name" "text",
    "email" "text",
    "strasse" "text",
    "plz" "text",
    "ort" "text",
    "land" "text",
    "anonym" boolean DEFAULT false NOT NULL,
    "nachricht" "text",
    "zweck" "text",
    "referenz" "text",
    "status" "text" DEFAULT 'OFFEN'::"text" NOT NULL,
    "weg" "text",
    "userId" "text",
    "eingegangen_am" "date",
    "bescheinigt_am" timestamp with time zone,
    "gebucht" boolean DEFAULT false NOT NULL,
    "erfasst_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erfasst_von" "text",
    "aufruf" "text",
    CONSTRAINT "donations_betrag_check" CHECK (("betrag" > (0)::numeric)),
    CONSTRAINT "donations_status_check" CHECK (("status" = ANY (ARRAY['OFFEN'::"text", 'BEZAHLT'::"text", 'STORNIERT'::"text"]))),
    CONSTRAINT "donations_waehrung_check" CHECK (("waehrung" = ANY (ARRAY['CHF'::"text", 'EUR'::"text"]))),
    CONSTRAINT "donations_weg_check" CHECK (("weg" = ANY (ARRAY['QR'::"text", 'TWINT'::"text", 'PAYPAL'::"text", 'BAR'::"text", 'UEBERWEISUNG'::"text"])))
);


ALTER TABLE "public"."donations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."event_registrations" (
    "id" "text" NOT NULL,
    "eventId" "text" NOT NULL,
    "userId" "text",
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tickets" integer DEFAULT 1,
    "name" "text",
    "email" "text",
    "eventTitle" "text",
    "phone" "text",
    "type" "text" DEFAULT 'MEMBER'::"text",
    "registeredAt" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'PENDING'::"text",
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."event_registrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "date" "text" NOT NULL,
    "location" "text",
    "image" "text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "limit" integer,
    "tenantId" "text" NOT NULL,
    "time" "text",
    "images" "jsonb" DEFAULT '[]'::"jsonb",
    "category" "text" DEFAULT 'SOCIAL'::"text",
    "status" "text" DEFAULT 'DRAFT'::"text",
    "isFeatured" boolean DEFAULT false,
    "isRegistrable" boolean DEFAULT false
);


ALTER TABLE "public"."events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expenses" (
    "id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "amount" numeric NOT NULL,
    "category" "text",
    "date" "text" NOT NULL,
    "approved" boolean DEFAULT false,
    "paid" boolean DEFAULT false,
    "receiptUrl" "text",
    "approvedBy" "text",
    "createdBy" "text",
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "vendor" "text",
    "description" "text",
    "currency" "text" DEFAULT 'CHF'::"text",
    "dueDate" "text",
    "categoryAccountCode" "text",
    "paymentAccountCode" "text",
    "status" "text" DEFAULT 'PENDING'::"text",
    "bookedInJournal" boolean DEFAULT false,
    "createdAt" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."expenses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."families" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "name" "text" NOT NULL,
    "notiz" "text",
    "anker" "text" NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text",
    CONSTRAINT "families_name_nicht_leer" CHECK (("btrim"("name") <> ''::"text"))
);


ALTER TABLE "public"."families" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."family_links" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text",
    "von" "text" NOT NULL,
    "nach" "text" NOT NULL,
    "art" "text" NOT NULL,
    "notiz" "text",
    "erfasst_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erfasst_von" "text",
    CONSTRAINT "family_links_art_gueltig" CHECK (("art" = ANY (ARRAY['ELTERNTEIL'::"text", 'PARTNER'::"text", 'GESCHWISTER'::"text"]))),
    CONSTRAINT "family_links_nicht_selbst" CHECK (("von" <> "nach"))
);


ALTER TABLE "public"."family_links" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fiscal_budgets" (
    "id" "text" NOT NULL,
    "year" integer,
    "entries" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "tenantId" "text" NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."fiscal_budgets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fiscal_years" (
    "id" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "year" integer,
    "status" "text" DEFAULT 'OPEN'::"text",
    "closedAt" "text",
    "netProfit" numeric
);


ALTER TABLE "public"."fiscal_years" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."floky_einstellungen" (
    "tenantId" "text" NOT NULL,
    "assistent_name" "text" DEFAULT 'Floky'::"text" NOT NULL,
    "anrede_du" boolean DEFAULT false NOT NULL,
    "wochenstart" boolean DEFAULT true NOT NULL,
    "kontingent_monat" integer DEFAULT 300 NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "wochenstart_an" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    CONSTRAINT "floky_einstellungen_kontingent_monat_check" CHECK (("kontingent_monat" >= 0))
);


ALTER TABLE "public"."floky_einstellungen" OWNER TO "postgres";


COMMENT ON COLUMN "public"."floky_einstellungen"."kontingent_monat" IS 'KI-Anfragen je Monat. Nur der Plattformbetreiber aendert diesen Wert; der Verein sieht ihn und seinen Verbrauch.';



COMMENT ON COLUMN "public"."floky_einstellungen"."wochenstart_an" IS 'users.id derjenigen, die den Wochenstart am Montagabend erhalten. Leer = niemand; es wird dann nichts verschickt.';



CREATE TABLE IF NOT EXISTS "public"."floky_gespraeche" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "userId" "text" NOT NULL,
    "titel" "text",
    "archiviert" boolean DEFAULT false NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."floky_gespraeche" OWNER TO "postgres";


COMMENT ON TABLE "public"."floky_gespraeche" IS 'Gespraeche mit dem Assistenten. Gehoeren der Person, nicht dem Verein: auch die Administration liest fremde Gespraeche nicht. Was im Verein geschehen ist, steht in floky_protokoll.';



CREATE TABLE IF NOT EXISTS "public"."floky_nachrichten" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gespraech_id" "uuid" NOT NULL,
    "rolle" "text" NOT NULL,
    "text" "text" NOT NULL,
    "werkzeuge" "text"[],
    "karten" "jsonb",
    "kuerzel" "jsonb",
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "floky_nachrichten_rolle_check" CHECK (("rolle" = ANY (ARRAY['mensch'::"text", 'floky'::"text"])))
);


ALTER TABLE "public"."floky_nachrichten" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."floky_protokoll" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "userId" "text",
    "rolle" "text",
    "art" "text" NOT NULL,
    "werkzeug" "text",
    "zusammenfassung" "text",
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "floky_protokoll_art_check" CHECK (("art" = ANY (ARRAY['ANFRAGE'::"text", 'KARTE'::"text", 'BESTAETIGT'::"text", 'ABGELEHNT'::"text"])))
);


ALTER TABLE "public"."floky_protokoll" OWNER TO "postgres";


COMMENT ON TABLE "public"."floky_protokoll" IS 'Wer hat Floky was aufgetragen und welche Karte wurde bestaetigt. Bewusst nur eine Zusammenfassung je Zeile -- ein vollstaendiges Gespraechsprotokoll waere eine Mitgliederdatensammlung ohne Zweck.';



CREATE TABLE IF NOT EXISTS "public"."floky_verbrauch" (
    "tenantId" "text" NOT NULL,
    "monat" "date" NOT NULL,
    "anfragen" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."floky_verbrauch" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."glossar" (
    "tenantId" "text" NOT NULL,
    "begriff" "text" NOT NULL,
    "de" "text",
    "sq" "text",
    "en" "text",
    "hinweis" "text",
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."glossar" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inquiries" (
    "id" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "message" "text" NOT NULL,
    "email" "text" NOT NULL,
    "status" "text" DEFAULT 'OPEN'::"text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "userId" "text",
    "userName" "text",
    "type" "text" DEFAULT 'GENERAL'::"text",
    "adminNote" "text",
    "updatedAt" timestamp with time zone,
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."inquiries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mail_domain_weg" (
    "domain" "text" NOT NULL,
    "weg" "text" NOT NULL,
    "grund" "text",
    "geprueft_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "mail_domain_weg_weg_check" CHECK (("weg" = ANY (ARRAY['postal'::"text", 'brevo'::"text"])))
);


ALTER TABLE "public"."mail_domain_weg" OWNER TO "postgres";


COMMENT ON TABLE "public"."mail_domain_weg" IS 'Gemerkte Zuordnung Empfaengerdomain -> Versandweg, ermittelt am MX-Eintrag. Aelter als 30 Tage wird neu geprueft: eine Domain kann den Anbieter wechseln.';



CREATE TABLE IF NOT EXISTS "public"."mail_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "recipient" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "html" "text" NOT NULL,
    "text" "text",
    "attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "kind" "text" DEFAULT 'GENERIC'::"text" NOT NULL,
    "memberId" "text",
    "refYear" integer,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "attempts" integer DEFAULT 0 NOT NULL,
    "lastError" "text",
    "scheduledFor" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sentAt" timestamp with time zone,
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "mail_queue_status_chk" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'SENT'::"text", 'FAILED'::"text", 'CANCELLED'::"text"])))
);


ALTER TABLE "public"."mail_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mail_settings" (
    "tenantId" "text" NOT NULL,
    "host" "text",
    "port" integer DEFAULT 587 NOT NULL,
    "benutzer" "text",
    "kennwort" "text",
    "absender" "text",
    "absendername" "text",
    "tls" "text" DEFAULT 'starttls'::"text" NOT NULL,
    "aktiv" boolean DEFAULT true NOT NULL,
    "zeitplan_token" "text" DEFAULT "encode"("extensions"."gen_random_bytes"(24), 'hex'::"text") NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text",
    CONSTRAINT "mail_settings_port_gueltig" CHECK ((("port" > 0) AND ("port" < 65536))),
    CONSTRAINT "mail_settings_tls_gueltig" CHECK (("tls" = ANY (ARRAY['starttls'::"text", 'tls'::"text", 'keine'::"text"])))
);


ALTER TABLE "public"."mail_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mitglied_meldungen" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "memberId" "text" NOT NULL,
    "art" "text" NOT NULL,
    "bemerkung" "text",
    "reportedBy" "text",
    "status" "text" DEFAULT 'OFFEN'::"text" NOT NULL,
    "decidedBy" "text",
    "decidedAt" timestamp with time zone,
    "entscheidung" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "mitglied_meldungen_art_check" CHECK (("art" = ANY (ARRAY['INAKTIV'::"text", 'VERSTORBEN'::"text", 'WEGGEZOGEN'::"text", 'SONSTIGES'::"text"]))),
    CONSTRAINT "mitglied_meldungen_status_check" CHECK (("status" = ANY (ARRAY['OFFEN'::"text", 'UEBERNOMMEN'::"text", 'ABGELEHNT'::"text"])))
);


ALTER TABLE "public"."mitglied_meldungen" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."modules" (
    "schluessel" "text" NOT NULL,
    "name_de" "text" NOT NULL,
    "name_sq" "text" NOT NULL,
    "name_en" "text" NOT NULL,
    "beschreibung_de" "text",
    "beschreibung_sq" "text",
    "beschreibung_en" "text",
    "preis_monat" numeric(10,2),
    "preis_einmalig" numeric(10,2),
    "braucht_einrichtung" boolean DEFAULT false NOT NULL,
    "status" "text" DEFAULT 'VERFUEGBAR'::"text" NOT NULL,
    "ist_kern" boolean DEFAULT false NOT NULL,
    "reihenfolge" integer DEFAULT 100 NOT NULL,
    CONSTRAINT "modules_status_gueltig" CHECK (("status" = ANY (ARRAY['VERFUEGBAR'::"text", 'BETA'::"text", 'EINGESTELLT'::"text"])))
);


ALTER TABLE "public"."modules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."neighborhoods" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "city" "text",
    "representativeId" "text",
    "description" "text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "location" "jsonb",
    "managerId" "text",
    "memberCount" integer DEFAULT 0,
    "contactPerson" "text",
    "contactPersonIds" "jsonb" DEFAULT '[]'::"jsonb",
    "contactEmail" "text",
    "contactPhone" "text",
    "website" "text",
    "image" "text",
    "status" "text" DEFAULT 'ACTIVE'::"text",
    "lastActivity" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."neighborhoods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."news" (
    "id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "image" "text",
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "author" "text",
    "tenantId" "text" NOT NULL,
    "category" "text",
    "subcategory" "text",
    "location" "text",
    "status" "text" DEFAULT 'DRAFT'::"text",
    "publishAt" timestamp with time zone,
    "gradientColors" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."news" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "paymentId" "text" NOT NULL,
    "reportedBy" "text" NOT NULL,
    "method" "text",
    "amount" numeric,
    "paidOn" "date",
    "note" "text",
    "status" "text" DEFAULT 'OPEN'::"text" NOT NULL,
    "decidedBy" "text",
    "decidedAt" timestamp with time zone,
    "decisionNote" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "payment_reports_status_chk" CHECK (("status" = ANY (ARRAY['OPEN'::"text", 'CONFIRMED'::"text", 'REJECTED'::"text"])))
);


ALTER TABLE "public"."payment_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "text" NOT NULL,
    "userId" "text",
    "tenantId" "text" NOT NULL,
    "neighborhoodId" "text",
    "amount" numeric NOT NULL,
    "currency" "text" DEFAULT 'CHF'::"text",
    "type" "text" DEFAULT 'FEE'::"text",
    "invoiceType" "text" DEFAULT 'MEMBERSHIP'::"text",
    "billingYear" integer,
    "customRecipient" "jsonb",
    "method" "text" DEFAULT 'QR_BILL'::"text",
    "status" "text" DEFAULT 'PENDING'::"text",
    "deliveryMethod" "text" DEFAULT 'EMAIL'::"text",
    "scheduledDate" "text",
    "dunningLevel" integer DEFAULT 0,
    "lastDunningDate" "text",
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "dueDate" "text",
    "paidAt" "text",
    "invoiceNumber" "text",
    "description" "text",
    "reference" "text",
    "pdfUrl" "text",
    "bookedInJournal" boolean DEFAULT false,
    "collectedBy" "text",
    "bezahlt" numeric DEFAULT 0 NOT NULL,
    "differenzArt" "text" DEFAULT 'OFFEN'::"text" NOT NULL,
    CONSTRAINT "payments_differenz_art" CHECK (("differenzArt" = ANY (ARRAY['OFFEN'::"text", 'SPENDE'::"text", 'GUTHABEN'::"text", 'ERLASS'::"text"])))
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."payments"."bezahlt" IS 'Summe der Zahlungseingaenge. Wird aus zahlungseingaenge gepflegt, nie direkt geschrieben.';



COMMENT ON COLUMN "public"."payments"."differenzArt" IS 'Was die Abweichung zwischen amount und bezahlt bedeutet. OFFEN = der Vorstand hat nicht entschieden. SPENDE/GUTHABEN fuer Mehrbetrag, ERLASS fuer Minderbetrag.';



CREATE TABLE IF NOT EXISTS "public"."platform_admins" (
    "email" "text" NOT NULL,
    "note" "text",
    "createdAt" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."platform_admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "kind" "text" DEFAULT 'ANNUAL'::"text" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "currency" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "year" integer,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "invoiceNumber" "text",
    "issuedAt" "date" DEFAULT CURRENT_DATE NOT NULL,
    "dueDate" "date",
    "paidAt" "date",
    "note" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    "treffen_id" "uuid",
    CONSTRAINT "platform_invoices_kind_check" CHECK (("kind" = ANY (ARRAY['SETUP'::"text", 'ANNUAL'::"text", 'TREFFEN'::"text", 'POSTKONTINGENT'::"text", 'OTHER'::"text"]))),
    CONSTRAINT "platform_invoices_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'SENT'::"text", 'PAID'::"text", 'CANCELLED'::"text"])))
);


ALTER TABLE "public"."platform_invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "contactName" "text",
    "email" "text",
    "phone" "text",
    "city" "text",
    "stage" "text" DEFAULT 'LEAD'::"text" NOT NULL,
    "expectedMembers" integer,
    "note" "text",
    "tenantId" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updatedAt" timestamp with time zone,
    CONSTRAINT "platform_leads_stage_check" CHECK (("stage" = ANY (ARRAY['LEAD'::"text", 'TALKS'::"text", 'ONBOARDING'::"text", 'WON'::"text", 'LOST'::"text"])))
);


ALTER TABLE "public"."platform_leads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_secrets" (
    "schluessel" "text" NOT NULL,
    "wert" "text" NOT NULL,
    "notiz" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."platform_secrets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_support" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "reason" "text",
    "startedAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    "endedAt" timestamp with time zone
);


ALTER TABLE "public"."platform_support" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."polls" (
    "id" "text" NOT NULL,
    "question" "text" NOT NULL,
    "options" "jsonb" NOT NULL,
    "expiresAt" "text",
    "status" "text" DEFAULT 'ACTIVE'::"text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "active" boolean DEFAULT true,
    "allowMultiple" boolean DEFAULT false,
    "createdBy" "text",
    "userVotes" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."polls" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_ausgang" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "paymentId" "text",
    "memberId" "text",
    "empfaenger" "text" NOT NULL,
    "dateiname" "text" NOT NULL,
    "pdf" "text" NOT NULL,
    "produkt" "text" DEFAULT 'cheap'::"text" NOT NULL,
    "farbe" "text" DEFAULT 'grayscale'::"text" NOT NULL,
    "duplex" boolean DEFAULT true NOT NULL,
    "adresslage" "text" DEFAULT 'left'::"text" NOT NULL,
    "zustand" "text" DEFAULT 'WARTEND'::"text" NOT NULL,
    "pingen_id" "text",
    "pingen_status" "text",
    "pingen_meldung" "text",
    "versuche" integer DEFAULT 0 NOT NULL,
    "letzter_fehler" "text",
    "naechster_versuch" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "uebergeben_am" timestamp with time zone,
    "erledigt_am" timestamp with time zone,
    CONSTRAINT "post_ausgang_farbe" CHECK (("farbe" = ANY (ARRAY['color'::"text", 'grayscale'::"text"]))),
    CONSTRAINT "post_ausgang_produkt" CHECK (("produkt" = ANY (ARRAY['cheap'::"text", 'fast'::"text", 'bulk'::"text", 'premium'::"text", 'registered'::"text"]))),
    CONSTRAINT "post_ausgang_zustand" CHECK (("zustand" = ANY (ARRAY['WARTEND'::"text", 'UEBERGEBEN'::"text", 'VERSENDET'::"text", 'ZUGESTELLT'::"text", 'UNZUSTELLBAR'::"text", 'PROBLEM'::"text", 'ABGEBROCHEN'::"text"])))
);


ALTER TABLE "public"."post_ausgang" OWNER TO "postgres";


COMMENT ON TABLE "public"."post_ausgang" IS 'Briefe fuer den Postversand ueber Pingen. Eine Zeile = ein PDF = ein Kuvert. Nicht direkt lesbar; Uebersicht ueber post_uebersicht().';



CREATE TABLE IF NOT EXISTS "public"."post_kontingent" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "art" "text" NOT NULL,
    "menge" integer NOT NULL,
    "preis_je_brief" numeric(10,2),
    "einkauf_je_brief" numeric(10,2),
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "postId" "uuid",
    "rechnungId" "uuid",
    "grund" "text",
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erstellt_von" "text",
    CONSTRAINT "post_kontingent_art" CHECK (("art" = ANY (ARRAY['KAUF'::"text", 'VERBRAUCH'::"text", 'GUTSCHRIFT'::"text", 'STORNO'::"text"]))),
    CONSTRAINT "post_kontingent_vorzeichen" CHECK (((("art" = ANY (ARRAY['KAUF'::"text", 'GUTSCHRIFT'::"text"])) AND ("menge" > 0)) OR (("art" = ANY (ARRAY['VERBRAUCH'::"text", 'STORNO'::"text"])) AND ("menge" < 0))))
);


ALTER TABLE "public"."post_kontingent" OWNER TO "postgres";


COMMENT ON TABLE "public"."post_kontingent" IS 'Bewegungsbuch des Briefkontingents. Der Stand ist die Summe der Mengen -- kein eigener Zaehler, der auseinanderlaufen koennte.';



CREATE TABLE IF NOT EXISTS "public"."post_preise" (
    "tenantId" "text" NOT NULL,
    "einkauf_je_brief" numeric(10,2),
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text",
    "aufpreis_prozent" numeric(5,2) DEFAULT 10 NOT NULL,
    "preis_fest" numeric(10,2),
    "tarif_abgefragt_am" timestamp with time zone,
    "tarif_grundlage" "text",
    "preis_je_brief" numeric(10,2) GENERATED ALWAYS AS (COALESCE("preis_fest", "round"(("einkauf_je_brief" * ((1)::numeric + ("aufpreis_prozent" / 100.0))), 2))) STORED,
    CONSTRAINT "post_preise_aufpreis" CHECK ((("aufpreis_prozent" >= (0)::numeric) AND ("aufpreis_prozent" <= (200)::numeric)))
);


ALTER TABLE "public"."post_preise" OWNER TO "postgres";


COMMENT ON TABLE "public"."post_preise" IS 'Briefpreis je Verein, inklusive Aufpreis. einkauf_je_brief ist der Einkaufspreis bei Pingen und darf einem Verein nie angezeigt werden.';



COMMENT ON COLUMN "public"."post_preise"."tarif_grundlage" IS 'Welche Briefform abgefragt wurde -- Land, Blattzahl, Druckart. Ohne das ist ein Einkaufspreis eine Zahl ohne Bedeutung.';



COMMENT ON COLUMN "public"."post_preise"."preis_je_brief" IS 'Gerechnet: Einkauf plus Aufpreis, oder preis_fest. Nicht schreibbar -- ein gespeicherter Verkaufspreis wuerde von der Regel abweichen, sobald Pingen den Tarif aendert.';



CREATE TABLE IF NOT EXISTS "public"."postausgang_zustand" (
    "id" boolean DEFAULT true NOT NULL,
    "bereit" boolean DEFAULT false NOT NULL,
    "quelle" "text",
    "geprueft_am" timestamp with time zone,
    "letzter_fehler" "text",
    CONSTRAINT "postausgang_zustand_id_check" CHECK ("id")
);


ALTER TABLE "public"."postausgang_zustand" OWNER TO "postgres";


COMMENT ON TABLE "public"."postausgang_zustand" IS 'Was der Versand ueber sich selbst meldet. Nur Zustand und Zeitpunkt -- niemals Zugangsdaten; die bleiben im Geheimnis der Funktion.';



CREATE TABLE IF NOT EXISTS "public"."pruefstand_referenzen" (
    "was" "text" NOT NULL,
    "wert" numeric,
    "erfasst" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."pruefstand_referenzen" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "text" NOT NULL,
    "email" "text",
    "displayName" "text",
    "role" "text" DEFAULT 'MEMBER'::"text",
    "membershipStatus" "text" DEFAULT 'ACTIVE'::"text",
    "phone" "text",
    "street" "text",
    "zip" "text",
    "city" "text",
    "birthdate" "text",
    "neighborhoodId" "text",
    "tenantId" "text" NOT NULL,
    "joinedAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "billingGroup" "text",
    "customAnnualFee" numeric,
    "familyId" "text",
    "isLegacyEmail" boolean DEFAULT false,
    "profileComplete" boolean DEFAULT false,
    "isBoardMember" boolean DEFAULT false,
    "firstName" "text",
    "lastName" "text",
    "salutation" "text",
    "membershipCategory" "text" DEFAULT 'INDIVIDUAL'::"text",
    "invoiceDeliveryMethod" "text" DEFAULT 'EMAIL'::"text",
    "migrationRequired" "text",
    "livesInKoretin" boolean DEFAULT false,
    "dataUpdateRequested" boolean DEFAULT false,
    "address" "text",
    "country" "text",
    "phoneSecondary" "text",
    "currency" "text" DEFAULT 'CHF'::"text",
    "photoFileName" "text",
    "internalNotes" "text",
    "reminders" "jsonb" DEFAULT '[]'::"jsonb",
    "authUserId" "text",
    "nicht_oeffentlich" boolean DEFAULT false NOT NULL,
    "sprache" "text",
    CONSTRAINT "users_sprache_check" CHECK ((("sprache" IS NULL) OR ("sprache" = ANY (ARRAY['de'::"text", 'sq'::"text", 'en'::"text"]))))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON COLUMN "public"."users"."nicht_oeffentlich" IS 'Mitglied moechte auf der oeffentlichen Website nicht erscheinen -- weder im Mitgliederlauf noch in einer Zahlerliste.';



COMMENT ON COLUMN "public"."users"."sprache" IS 'Sprache fuer Schreiben an dieses Mitglied. NULL = unbekannt; dann zweisprachig vorschlagen statt raten.';



CREATE OR REPLACE VIEW "public"."public_members" AS
 SELECT "id",
    "tenantId",
    "displayName",
    "photoFileName",
    "city",
    "country",
    "membershipStatus",
    "livesInKoretin"
   FROM "public"."users"
  WHERE (("membershipStatus" IS DISTINCT FROM 'INACTIVE'::"text") AND (COALESCE("nicht_oeffentlich", false) = false) AND ("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())));


ALTER VIEW "public"."public_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."settings" (
    "id" "text" NOT NULL,
    "payment" "jsonb",
    "company" "jsonb",
    "branding" "jsonb",
    "system" "jsonb",
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."settings" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."public_settings" WITH ("security_invoker"='off') AS
 SELECT "id",
    "tenantId",
    (("payment" - 'paypalSecret'::"text") - 'paypalClientId'::"text") AS "payment",
    "company",
    "branding",
    "system",
    ( SELECT "jsonb_object_agg"("e"."k", "e"."v") AS "jsonb_object_agg"
           FROM "jsonb_each"(COALESCE("settings"."data", '{}'::"jsonb")) "e"("k", "v")
          WHERE ("e"."k" = ANY (ARRAY['qrIban'::"text", 'iban'::"text", 'bic'::"text", 'bankName'::"text", 'accountHolder'::"text", 'twintUrl'::"text", 'paypalEmail'::"text", 'street'::"text", 'zip'::"text", 'city'::"text", 'country'::"text", 'currency'::"text", 'fees'::"text", 'annualFeeAmount'::"text"]))) AS "data"
   FROM "public"."settings"
  WHERE ("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"()));


ALTER VIEW "public"."public_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenant_domains" (
    "domain" "text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "isPrimary" boolean DEFAULT false,
    "createdAt" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."tenant_domains" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenants" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "domain" "text",
    "logo" "text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "status" "text" DEFAULT 'ACTIVE'::"text",
    "slug" "text",
    "logoUrl" "text",
    "primaryColor" "text",
    "secondaryColor" "text",
    "subscriptionPlan" "text" DEFAULT 'FREE'::"text",
    "subscriptionStatus" "text" DEFAULT 'ACTIVE'::"text",
    "stripeCustomerId" "text",
    "contactEmail" "text",
    "memberCount" integer DEFAULT 0,
    "annualFee" numeric(10,2),
    "setupFee" numeric(10,2),
    "currency" "text" DEFAULT 'CHF'::"text",
    "contractStart" "date",
    "billingNote" "text",
    "contactName" "text",
    "phone" "text",
    "alle_module_frei" boolean DEFAULT false NOT NULL,
    "vorstand_schreibt" boolean DEFAULT true NOT NULL,
    "vertreter_felder" "text"[] DEFAULT ARRAY['firstName'::"text", 'lastName'::"text", 'displayName'::"text", 'salutation'::"text", 'birthdate'::"text", 'street'::"text", 'zip'::"text", 'city'::"text", 'country'::"text", 'address'::"text", 'phone'::"text", 'phoneSecondary'::"text", 'email'::"text", 'nicht_oeffentlich'::"text", 'sprache'::"text", 'membershipCategory'::"text", 'familyId'::"text", 'invoiceDeliveryMethod'::"text"] NOT NULL
);


ALTER TABLE "public"."tenants" OWNER TO "postgres";


COMMENT ON COLUMN "public"."tenants"."vorstand_schreibt" IS 'Darf die Rolle BOARD Daten aendern? true (Vorgabe) = wie bisher. false = der Vorstand sieht alles, aendert aber nichts. SUPER_ADMIN und ADMIN sind davon nie betroffen.';



COMMENT ON COLUMN "public"."tenants"."vertreter_felder" IS 'Welche Felder eines Mitglieds ein Nachbarschafts-Verantwortlicher aendern darf. role, neighborhoodId, membershipStatus, tenantId, authUserId und id sind nie waehlbar -- siehe vertreter_felder_setzen().';



CREATE OR REPLACE VIEW "public"."public_tenant_domains" WITH ("security_barrier"='true') AS
 SELECT "d"."domain",
    "d"."tenantId",
    "t"."slug",
    "t"."name",
    "t"."logoUrl",
    "t"."primaryColor",
    "t"."secondaryColor"
   FROM ("public"."tenant_domains" "d"
     JOIN "public"."tenants" "t" ON (("t"."id" = "d"."tenantId")));


ALTER VIEW "public"."public_tenant_domains" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."public_tenants" WITH ("security_barrier"='true') AS
 SELECT "id",
    "slug",
    "domain",
    "name",
    "logoUrl",
    "primaryColor",
    "secondaryColor"
   FROM "public"."tenants";


ALTER VIEW "public"."public_tenants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."revisionszugaenge" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "bezeichnung" "text" NOT NULL,
    "token_hash" "text" NOT NULL,
    "jahr" integer,
    "gueltig_bis" "date" NOT NULL,
    "erstellt_von" "text",
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "widerrufen_am" timestamp with time zone,
    "zuletzt_gesehen" timestamp with time zone,
    "zugriffe" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."revisionszugaenge" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."security_logs" (
    "id" "text" NOT NULL,
    "ipAddress" "text",
    "userAgent" "text",
    "type" "text",
    "violation" "text",
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "userId" "text",
    "action" "text",
    "details" "jsonb",
    "createdAt" timestamp with time zone DEFAULT "now"(),
    "tenantId" "text" NOT NULL
);


ALTER TABLE "public"."security_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."seiten" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "pfad" "text" NOT NULL,
    "titel" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "bloecke" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'ENTWURF'::"text" NOT NULL,
    "im_menue" boolean DEFAULT false NOT NULL,
    "reihenfolge" integer DEFAULT 100 NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text",
    CONSTRAINT "seiten_status_check" CHECK (("status" = ANY (ARRAY['ENTWURF'::"text", 'OEFFENTLICH'::"text"])))
);


ALTER TABLE "public"."seiten" OWNER TO "postgres";


COMMENT ON COLUMN "public"."seiten"."bloecke" IS 'Liste von Bausteinen: {art, ...}. Arten: ueberschrift, text, bild, knopf, trenner, zitat. Kein freies HTML -- was im Browser des Besuchers laeuft, entscheidet die Anwendung, nicht der Inhalt.';



CREATE TABLE IF NOT EXISTS "public"."seitenaufrufe" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text",
    "pfad" "text" NOT NULL,
    "titel" "text",
    "besucher" "text" NOT NULL,
    "herkunft" "text",
    "herkunft_art" "text" DEFAULT 'DIREKT'::"text" NOT NULL,
    "geraet" "text" DEFAULT 'UNBEKANNT'::"text" NOT NULL,
    "sprache" "text",
    "land" "text",
    "stunde" smallint NOT NULL,
    "dauer_s" integer,
    "ziel" "text",
    "gesehen_am" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."seitenaufrufe" OWNER TO "postgres";


COMMENT ON TABLE "public"."seitenaufrufe" IS 'Seitenaufrufe ohne IP-Adresse. besucher ist ein taeglich wechselnder Hashwert. Nicht direkt lesbar -- Auswertung ueber seo_* Funktionen.';



CREATE TABLE IF NOT EXISTS "public"."settings_archiv" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "kennung" "text" NOT NULL,
    "inhalt" "jsonb" NOT NULL,
    "grund" "text",
    "gelegt_am" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."settings_archiv" OWNER TO "postgres";


COMMENT ON TABLE "public"."settings_archiv" IS 'Weggeraeumte Einstellungszeilen, datiert. Damit "nichts geht verloren" nicht bedeutet, dass veraltete Kopien im Betrieb stehenbleiben.';



CREATE TABLE IF NOT EXISTS "public"."social_connections" (
    "id" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "plattform" "text" NOT NULL,
    "konto_id" "text",
    "konto_name" "text",
    "zugriffstoken" "text",
    "token_laeuft_ab" timestamp with time zone,
    "zustand" "text" DEFAULT 'OFFEN'::"text" NOT NULL,
    "kandidaten" "jsonb",
    "letzter_fehler" "text",
    "verbunden_am" timestamp with time zone,
    "verbunden_von" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "social_connections_plattform_check" CHECK (("plattform" = ANY (ARRAY['FACEBOOK'::"text", 'INSTAGRAM'::"text"]))),
    CONSTRAINT "social_connections_zustand_check" CHECK (("zustand" = ANY (ARRAY['OFFEN'::"text", 'WAEHLEN'::"text", 'AKTIV'::"text", 'ABGELAUFEN'::"text", 'FEHLER'::"text"])))
);


ALTER TABLE "public"."social_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."social_oauth_state" (
    "nonce" "text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "benutzer" "text",
    "zurueck" "text",
    "laeuft_ab" timestamp with time zone NOT NULL,
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."social_oauth_state" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."socialmediaposts" (
    "id" "text" NOT NULL,
    "content" "text" NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "platform" "text",
    "status" "text" DEFAULT 'DRAFT'::"text",
    "tenantId" "text" NOT NULL,
    "platforms" "jsonb" DEFAULT '[]'::"jsonb",
    "scheduledTime" "text",
    "aiGenerated" boolean DEFAULT false,
    "imagePrompt" "text",
    "image" "text",
    "publishedAt" timestamp with time zone,
    "externalIds" "jsonb",
    "lastError" "text",
    "attempts" integer DEFAULT 0 NOT NULL,
    "autoPosted" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."socialmediaposts" OWNER TO "postgres";


COMMENT ON COLUMN "public"."socialmediaposts"."status" IS 'DRAFT, SCHEDULED, QUEUED, PUBLISHING, PUBLISHED, FAILED';



CREATE SEQUENCE IF NOT EXISTS "public"."spenden_nummer"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."spenden_nummer" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spendenaufrufe" (
    "id" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "titel" "text" NOT NULL,
    "text" "text",
    "bild" "text",
    "ziel_betrag" numeric(12,2),
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "beginnt_am" "date",
    "endet_am" "date",
    "status" "text" DEFAULT 'ENTWURF'::"text" NOT NULL,
    "reihenfolge" integer DEFAULT 100 NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erstellt_von" "text",
    CONSTRAINT "spendenaufrufe_status_check" CHECK (("status" = ANY (ARRAY['ENTWURF'::"text", 'OEFFENTLICH'::"text", 'BEENDET'::"text"]))),
    CONSTRAINT "spendenaufrufe_waehrung_check" CHECK (("waehrung" = ANY (ARRAY['CHF'::"text", 'EUR'::"text"])))
);


ALTER TABLE "public"."spendenaufrufe" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sponsors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "packageKey" "text" DEFAULT 'BASIC'::"text" NOT NULL,
    "amount" numeric(10,2),
    "currency" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "company" "text" NOT NULL,
    "contactName" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text",
    "street" "text",
    "zip" "text",
    "city" "text",
    "country" "text",
    "website" "text",
    "logoUrl" "text",
    "message" "text",
    "status" "text" DEFAULT 'NEW'::"text" NOT NULL,
    "internalNote" "text",
    "createdAt" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updatedAt" timestamp with time zone,
    CONSTRAINT "sponsors_status_check" CHECK (("status" = ANY (ARRAY['NEW'::"text", 'IN_PROGRESS'::"text", 'CONFIRMED'::"text", 'DECLINED'::"text"])))
);


ALTER TABLE "public"."sponsors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."startseiten_vorlagen" (
    "schluessel" "text" NOT NULL,
    "name_de" "text" NOT NULL,
    "name_en" "text" NOT NULL,
    "name_sq" "text" NOT NULL,
    "beschreibung_de" "text" NOT NULL,
    "beschreibung_en" "text" NOT NULL,
    "beschreibung_sq" "text" NOT NULL,
    "ist_premium" boolean DEFAULT false NOT NULL,
    "modul" "text",
    "reihenfolge" integer DEFAULT 100 NOT NULL,
    "aktiv" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."startseiten_vorlagen" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'PENDING'::"text",
    "dueDate" "text",
    "assignedTo" "jsonb" DEFAULT '[]'::"jsonb",
    "createdBy" "text",
    "createdAt" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "tenantId" "text" NOT NULL,
    "priority" "text" DEFAULT 'MEDIUM'::"text",
    "assignedToName" "text",
    "sourceMeetingId" "text"
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenant_modules" (
    "tenantId" "text" NOT NULL,
    "modul" "text" NOT NULL,
    "zustand" "text" DEFAULT 'AUS'::"text" NOT NULL,
    "seit" timestamp with time zone DEFAULT "now"() NOT NULL,
    "testet_bis" "date",
    "geaendert_von" "text",
    CONSTRAINT "tenant_modules_zustand_gueltig" CHECK (("zustand" = ANY (ARRAY['AN'::"text", 'AUS'::"text", 'TESTPHASE'::"text", 'GESPERRT'::"text"])))
);


ALTER TABLE "public"."tenant_modules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."textbausteine" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "schluessel" "text" NOT NULL,
    "sprache" "text" NOT NULL,
    "betreff" "text",
    "text" "text" NOT NULL,
    "aktiv" boolean DEFAULT true NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text",
    "geprueft_am" timestamp with time zone,
    "geprueft_von" "text",
    "geprueft_text" "text",
    CONSTRAINT "textbausteine_sprache_check" CHECK (("sprache" = ANY (ARRAY['de'::"text", 'sq'::"text", 'en'::"text"])))
);


ALTER TABLE "public"."textbausteine" OWNER TO "postgres";


COMMENT ON COLUMN "public"."textbausteine"."geprueft_text" IS 'Der Wortlaut, der gegengelesen wurde. Weicht er vom heutigen ab, ist der Vermerk ueberholt -- geprueft wurde eine andere Fassung.';



CREATE TABLE IF NOT EXISTS "public"."treffen" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "titel" "text" NOT NULL,
    "beschreibung" "text",
    "datum" "date" NOT NULL,
    "beginn" time without time zone,
    "ende" "date",
    "ort" "text",
    "adresse" "text",
    "status" "text" DEFAULT 'ENTWURF'::"text" NOT NULL,
    "anmeldeschluss" "date",
    "preis_art" "text" DEFAULT 'KEINE'::"text" NOT NULL,
    "preis_betrag" numeric(10,2) DEFAULT 0 NOT NULL,
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erstellt_von" "text",
    "gastgeber" "text",
    CONSTRAINT "treffen_ende_nach_datum" CHECK ((("ende" IS NULL) OR ("ende" >= "datum"))),
    CONSTRAINT "treffen_preis_art_check" CHECK (("preis_art" = ANY (ARRAY['KEINE'::"text", 'PRO_VEREIN'::"text", 'PRO_KOPF'::"text"]))),
    CONSTRAINT "treffen_preis_betrag_check" CHECK (("preis_betrag" >= (0)::numeric)),
    CONSTRAINT "treffen_preis_stimmig" CHECK (((("preis_art" = 'KEINE'::"text") AND ("preis_betrag" = (0)::numeric)) OR (("preis_art" <> 'KEINE'::"text") AND ("preis_betrag" > (0)::numeric)))),
    CONSTRAINT "treffen_status_check" CHECK (("status" = ANY (ARRAY['ENTWURF'::"text", 'OEFFENTLICH'::"text", 'BEENDET'::"text"])))
);


ALTER TABLE "public"."treffen" OWNER TO "postgres";


COMMENT ON COLUMN "public"."treffen"."gastgeber" IS 'Der ausrichtende Verein. NULL = die Plattform richtet aus.';



CREATE TABLE IF NOT EXISTS "public"."treffen_ausflug_anmeldung" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "programm_id" "uuid" NOT NULL,
    "delegation_id" "uuid" NOT NULL,
    "angemeldet_am" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."treffen_ausflug_anmeldung" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."treffen_delegation" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "teilnehmer_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "rolle" "text" DEFAULT 'TEILNEHMER'::"text" NOT NULL,
    "bemerkung" "text",
    "erfasst_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text",
    "funktion" "text",
    "vorstellung" "text",
    "interessen" "text",
    "essen" "text" DEFAULT 'KEINE_ANGABE'::"text",
    "essen_hinweis" "text",
    "im_heft" boolean,
    "token_hash" "text",
    "gueltig_bis" "date",
    "vorgestellt_am" timestamp with time zone,
    CONSTRAINT "treffen_delegation_essen_check" CHECK (("essen" = ANY (ARRAY['KEINE_ANGABE'::"text", 'ALLES'::"text", 'VEGETARISCH'::"text", 'VEGAN'::"text", 'HALAL'::"text", 'GLUTENFREI'::"text", 'LAKTOSEFREI'::"text"]))),
    CONSTRAINT "treffen_delegation_rolle_check" CHECK (("rolle" = ANY (ARRAY['LEITUNG'::"text", 'TEILNEHMER'::"text"])))
);


ALTER TABLE "public"."treffen_delegation" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."treffen_programm" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "treffen_id" "uuid" NOT NULL,
    "tag" "date",
    "beginn" time without time zone NOT NULL,
    "dauer_min" integer,
    "titel" "text" NOT NULL,
    "ort" "text",
    "verantwortlich" "text",
    "spur" "text" DEFAULT 'Alle'::"text" NOT NULL,
    "fuer" "text" DEFAULT 'ALLE'::"text" NOT NULL,
    "freigegeben" boolean DEFAULT false NOT NULL,
    "reihenfolge" integer DEFAULT 0 NOT NULL,
    "art" "text" DEFAULT 'PUNKT'::"text" NOT NULL,
    "ziel" "text",
    "treffpunkt" "text",
    "anreise" "text",
    "rueckkehr" time without time zone,
    "plaetze" integer,
    "kosten" numeric(10,2) DEFAULT 0,
    CONSTRAINT "treffen_programm_art_check" CHECK (("art" = ANY (ARRAY['PUNKT'::"text", 'AUSFLUG'::"text"]))),
    CONSTRAINT "treffen_programm_ausflug_hat_ziel" CHECK ((("art" <> 'AUSFLUG'::"text") OR (COALESCE("btrim"("ziel"), ''::"text") <> ''::"text"))),
    CONSTRAINT "treffen_programm_dauer_min_check" CHECK ((("dauer_min" IS NULL) OR ("dauer_min" > 0))),
    CONSTRAINT "treffen_programm_fuer_check" CHECK (("fuer" = ANY (ARRAY['ALLE'::"text", 'VERTRETER'::"text"]))),
    CONSTRAINT "treffen_programm_kosten_check" CHECK (("kosten" >= (0)::numeric)),
    CONSTRAINT "treffen_programm_plaetze_check" CHECK ((("plaetze" IS NULL) OR ("plaetze" > 0)))
);


ALTER TABLE "public"."treffen_programm" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."treffen_teilnehmer" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "treffen_id" "uuid" NOT NULL,
    "art" "text" NOT NULL,
    "tenantId" "text",
    "name" "text",
    "kontakt_name" "text",
    "kontakt_email" "text",
    "token_hash" "text",
    "gueltig_bis" "date",
    "zugesagt" boolean,
    "personen" integer DEFAULT 0 NOT NULL,
    "bemerkung" "text",
    "eingeladen_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geantwortet_am" timestamp with time zone,
    CONSTRAINT "teilnehmer_verein_oder_name" CHECK (((("art" = 'VEREIN'::"text") AND ("tenantId" IS NOT NULL)) OR (("art" <> 'VEREIN'::"text") AND (COALESCE("btrim"("name"), ''::"text") <> ''::"text")))),
    CONSTRAINT "treffen_teilnehmer_art_check" CHECK (("art" = ANY (ARRAY['VEREIN'::"text", 'GASTVEREIN'::"text", 'GAST'::"text"]))),
    CONSTRAINT "treffen_teilnehmer_personen_check" CHECK (("personen" >= 0))
);


ALTER TABLE "public"."treffen_teilnehmer" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vereinsjahr" (
    "tenantId" "text" NOT NULL,
    "schluessel" "text" NOT NULL,
    "monat" integer NOT NULL,
    "tag" integer NOT NULL,
    "vorlauf_tage" integer DEFAULT 14 NOT NULL,
    "aktiv" boolean DEFAULT true NOT NULL,
    "reihenfolge" integer DEFAULT 0 NOT NULL,
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vereinsjahr_monat_check" CHECK ((("monat" >= 1) AND ("monat" <= 12))),
    CONSTRAINT "vereinsjahr_tag_check" CHECK ((("tag" >= 1) AND ("tag" <= 31)))
);


ALTER TABLE "public"."vereinsjahr" OWNER TO "postgres";


COMMENT ON COLUMN "public"."vereinsjahr"."vorlauf_tage" IS 'Tage VOR dem Termin, an denen erinnert wird. Negativ = danach: -7 heisst eine Woche nach dem Termin.';



CREATE TABLE IF NOT EXISTS "public"."versand_herkunft" (
    "ip" "text" NOT NULL,
    "art" "text" DEFAULT 'ipv4'::"text" NOT NULL,
    "zuerst" timestamp with time zone DEFAULT "now"() NOT NULL,
    "zuletzt" timestamp with time zone DEFAULT "now"() NOT NULL,
    "anzahl" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "public"."versand_herkunft" OWNER TO "postgres";


COMMENT ON TABLE "public"."versand_herkunft" IS 'Von aussen gesehene Absenderadressen der Edge Functions. Dient der Frage, ob eine IP-Freigabe beim Versanddienst tragen kann. Enthaelt keine Empfaengerdaten.';



CREATE TABLE IF NOT EXISTS "public"."videos" (
    "id" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "tenantId" "text" NOT NULL,
    "titel" "text" NOT NULL,
    "beschreibung" "text",
    "quelle" "text" NOT NULL,
    "vorschaubild" "text",
    "dauer_s" integer,
    "status" "text" DEFAULT 'ENTWURF'::"text" NOT NULL,
    "reihenfolge" integer DEFAULT 100 NOT NULL,
    "erstellt_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "erstellt_von" "text",
    CONSTRAINT "videos_status_check" CHECK (("status" = ANY (ARRAY['ENTWURF'::"text", 'OEFFENTLICH'::"text"])))
);


ALTER TABLE "public"."videos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."zaehler_salz" (
    "tag" "date" NOT NULL,
    "salz" "text" NOT NULL
);


ALTER TABLE "public"."zaehler_salz" OWNER TO "postgres";


COMMENT ON TABLE "public"."zaehler_salz" IS 'Taeglich wechselndes Salz fuer den Besucherwert. Nicht lesbar, auch nicht fuer die Administration -- sonst waere der Wert umkehrbar.';



CREATE TABLE IF NOT EXISTS "public"."zahlungseingaenge" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenantId" "text" NOT NULL,
    "paymentId" "text" NOT NULL,
    "betrag" numeric NOT NULL,
    "waehrung" "text" DEFAULT 'CHF'::"text" NOT NULL,
    "weg" "text",
    "eingang" "date" DEFAULT CURRENT_DATE NOT NULL,
    "erfasstVon" "text",
    "erfasstAm" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notiz" "text",
    "altbestand" boolean DEFAULT false NOT NULL,
    CONSTRAINT "zahlungseingaenge_betrag_check" CHECK (("betrag" <> (0)::numeric))
);


ALTER TABLE "public"."zahlungseingaenge" OWNER TO "postgres";


COMMENT ON TABLE "public"."zahlungseingaenge" IS 'Tatsaechliche Zahlungseingaenge je Rechnung. Eine Zeile je Eingang, damit Teilzahlungen und Korrekturen nachvollziehbar bleiben.';



CREATE TABLE IF NOT EXISTS "public"."zahlungsgeheimnisse" (
    "tenantId" "text" NOT NULL,
    "paypal_client_id" "text",
    "paypal_secret" "text",
    "geaendert_am" timestamp with time zone DEFAULT "now"() NOT NULL,
    "geaendert_von" "text"
);


ALTER TABLE "public"."zahlungsgeheimnisse" OWNER TO "postgres";


COMMENT ON TABLE "public"."zahlungsgeheimnisse" IS 'Zahlungszugangsdaten je Verein. Fuer kein angemeldetes Konto lesbar; nur die Serverrolle kommt heran. Gesetzt wird ueber zahlungsgeheimnis_setzen, der Stand ueber zahlungsgeheimnis_stand.';



ALTER TABLE ONLY "public"."accounting_accounts"
    ADD CONSTRAINT "accounting_accounts_pkey" PRIMARY KEY ("tenantId", "id");



ALTER TABLE ONLY "public"."accounting_journal_archiv"
    ADD CONSTRAINT "accounting_journal_archiv_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."accounting_journal"
    ADD CONSTRAINT "accounting_journal_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_emails"
    ADD CONSTRAINT "admin_emails_pkey" PRIMARY KEY ("email");



ALTER TABLE ONLY "public"."treffen_ausflug_anmeldung"
    ADD CONSTRAINT "ausflug_person_einmal" UNIQUE ("programm_id", "delegation_id");



ALTER TABLE ONLY "public"."board_meeting_versions"
    ADD CONSTRAINT "board_meeting_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."board_meetings"
    ADD CONSTRAINT "board_meetings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."board_members"
    ADD CONSTRAINT "board_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buchungsprotokoll"
    ADD CONSTRAINT "buchungsprotokoll_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."donations"
    ADD CONSTRAINT "donations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."families"
    ADD CONSTRAINT "families_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."family_links"
    ADD CONSTRAINT "family_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fiscal_budgets"
    ADD CONSTRAINT "fiscal_budgets_pkey" PRIMARY KEY ("tenantId", "id");



ALTER TABLE ONLY "public"."fiscal_years"
    ADD CONSTRAINT "fiscal_years_pkey" PRIMARY KEY ("tenantId", "id");



ALTER TABLE ONLY "public"."floky_einstellungen"
    ADD CONSTRAINT "floky_einstellungen_pkey" PRIMARY KEY ("tenantId");



ALTER TABLE ONLY "public"."floky_gespraeche"
    ADD CONSTRAINT "floky_gespraeche_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."floky_nachrichten"
    ADD CONSTRAINT "floky_nachrichten_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."floky_protokoll"
    ADD CONSTRAINT "floky_protokoll_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."floky_verbrauch"
    ADD CONSTRAINT "floky_verbrauch_pkey" PRIMARY KEY ("tenantId", "monat");



ALTER TABLE ONLY "public"."glossar"
    ADD CONSTRAINT "glossar_pkey" PRIMARY KEY ("tenantId", "begriff");



ALTER TABLE ONLY "public"."inquiries"
    ADD CONSTRAINT "inquiries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mail_domain_weg"
    ADD CONSTRAINT "mail_domain_weg_pkey" PRIMARY KEY ("domain");



ALTER TABLE ONLY "public"."mail_queue"
    ADD CONSTRAINT "mail_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mail_settings"
    ADD CONSTRAINT "mail_settings_pkey" PRIMARY KEY ("tenantId");



ALTER TABLE ONLY "public"."mitglied_meldungen"
    ADD CONSTRAINT "mitglied_meldungen_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "modules_pkey" PRIMARY KEY ("schluessel");



ALTER TABLE ONLY "public"."neighborhoods"
    ADD CONSTRAINT "neighborhoods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."news"
    ADD CONSTRAINT "news_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_reports"
    ADD CONSTRAINT "payment_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_admins"
    ADD CONSTRAINT "platform_admins_pkey" PRIMARY KEY ("email");



ALTER TABLE ONLY "public"."platform_invoices"
    ADD CONSTRAINT "platform_invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_leads"
    ADD CONSTRAINT "platform_leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_secrets"
    ADD CONSTRAINT "platform_secrets_pkey" PRIMARY KEY ("schluessel");



ALTER TABLE ONLY "public"."platform_support"
    ADD CONSTRAINT "platform_support_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."polls"
    ADD CONSTRAINT "polls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_ausgang"
    ADD CONSTRAINT "post_ausgang_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_kontingent"
    ADD CONSTRAINT "post_kontingent_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_preise"
    ADD CONSTRAINT "post_preise_pkey" PRIMARY KEY ("tenantId");



ALTER TABLE ONLY "public"."postausgang_zustand"
    ADD CONSTRAINT "postausgang_zustand_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pruefstand_referenzen"
    ADD CONSTRAINT "pruefstand_referenzen_pkey" PRIMARY KEY ("was");



ALTER TABLE ONLY "public"."revisionszugaenge"
    ADD CONSTRAINT "revisionszugaenge_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."revisionszugaenge"
    ADD CONSTRAINT "revisionszugaenge_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."security_logs"
    ADD CONSTRAINT "security_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."seiten"
    ADD CONSTRAINT "seiten_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."seiten"
    ADD CONSTRAINT "seiten_tenantId_pfad_key" UNIQUE ("tenantId", "pfad");



ALTER TABLE ONLY "public"."seitenaufrufe"
    ADD CONSTRAINT "seitenaufrufe_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings_archiv"
    ADD CONSTRAINT "settings_archiv_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY ("tenantId", "id");



ALTER TABLE ONLY "public"."social_connections"
    ADD CONSTRAINT "social_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."social_connections"
    ADD CONSTRAINT "social_connections_tenantId_plattform_key" UNIQUE ("tenantId", "plattform");



ALTER TABLE ONLY "public"."social_oauth_state"
    ADD CONSTRAINT "social_oauth_state_pkey" PRIMARY KEY ("nonce");



ALTER TABLE ONLY "public"."socialmediaposts"
    ADD CONSTRAINT "socialmediaposts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."spendenaufrufe"
    ADD CONSTRAINT "spendenaufrufe_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sponsors"
    ADD CONSTRAINT "sponsors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."startseiten_vorlagen"
    ADD CONSTRAINT "startseiten_vorlagen_pkey" PRIMARY KEY ("schluessel");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_teilnehmer"
    ADD CONSTRAINT "teilnehmer_verein_einmal" UNIQUE ("treffen_id", "tenantId");



ALTER TABLE ONLY "public"."tenant_domains"
    ADD CONSTRAINT "tenant_domains_pkey" PRIMARY KEY ("domain");



ALTER TABLE ONLY "public"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_pkey" PRIMARY KEY ("tenantId", "modul");



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."textbausteine"
    ADD CONSTRAINT "textbausteine_einmalig" UNIQUE ("tenantId", "schluessel", "sprache");



ALTER TABLE ONLY "public"."textbausteine"
    ADD CONSTRAINT "textbausteine_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_ausflug_anmeldung"
    ADD CONSTRAINT "treffen_ausflug_anmeldung_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_delegation"
    ADD CONSTRAINT "treffen_delegation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen"
    ADD CONSTRAINT "treffen_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_programm"
    ADD CONSTRAINT "treffen_programm_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_teilnehmer"
    ADD CONSTRAINT "treffen_teilnehmer_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."treffen_teilnehmer"
    ADD CONSTRAINT "treffen_teilnehmer_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vereinsjahr"
    ADD CONSTRAINT "vereinsjahr_pkey" PRIMARY KEY ("tenantId", "schluessel");



ALTER TABLE ONLY "public"."versand_herkunft"
    ADD CONSTRAINT "versand_herkunft_pkey" PRIMARY KEY ("ip");



ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."zaehler_salz"
    ADD CONSTRAINT "zaehler_salz_pkey" PRIMARY KEY ("tag");



ALTER TABLE ONLY "public"."zahlungseingaenge"
    ADD CONSTRAINT "zahlungseingaenge_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."zahlungsgeheimnisse"
    ADD CONSTRAINT "zahlungsgeheimnisse_pkey" PRIMARY KEY ("tenantId");



CREATE UNIQUE INDEX "accounting_accounts_code_je_verein" ON "public"."accounting_accounts" USING "btree" ("tenantId", "code");



CREATE INDEX "accounting_accounts_tenant_idx" ON "public"."accounting_accounts" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "accounting_journal_belegnr_je_jahr" ON "public"."accounting_journal" USING "btree" ("tenantId", "substr"("date", 1, 4), "belegnr");



CREATE INDEX "accounting_journal_date_idx" ON "public"."accounting_journal" USING "btree" ("date");



CREATE INDEX "accounting_journal_referenceid_idx" ON "public"."accounting_journal" USING "btree" ("referenceId");



CREATE INDEX "accounting_journal_tenant_idx" ON "public"."accounting_journal" USING "btree" ("tenantId");



CREATE INDEX "ausflug_anmeldung_programm" ON "public"."treffen_ausflug_anmeldung" USING "btree" ("programm_id");



CREATE UNIQUE INDEX "board_meeting_versions_eindeutig" ON "public"."board_meeting_versions" USING "btree" ("meetingId", "version");



CREATE INDEX "board_meeting_versions_nach_sitzung" ON "public"."board_meeting_versions" USING "btree" ("meetingId", "changedAt" DESC);



CREATE INDEX "board_meetings_tenant_idx" ON "public"."board_meetings" USING "btree" ("tenantId");



CREATE INDEX "board_meetings_veroeffentlicht" ON "public"."board_meetings" USING "btree" ("tenantId", "date" DESC) WHERE "publishedToMembers";



CREATE INDEX "board_members_tenant_idx" ON "public"."board_members" USING "btree" ("tenantId");



CREATE INDEX "board_members_userid_idx" ON "public"."board_members" USING "btree" ("userId");



CREATE INDEX "buchungsprotokoll_buchung" ON "public"."buchungsprotokoll" USING "btree" ("tenantId", "buchung_id");



CREATE INDEX "buchungsprotokoll_verein_zeit" ON "public"."buchungsprotokoll" USING "btree" ("tenantId", "wann" DESC);



CREATE INDEX "donations_aufruf_idx" ON "public"."donations" USING "btree" ("aufruf");



CREATE UNIQUE INDEX "donations_referenz_idx" ON "public"."donations" USING "btree" ("referenz") WHERE ("referenz" IS NOT NULL);



CREATE INDEX "donations_verein_idx" ON "public"."donations" USING "btree" ("tenantId", "status");



CREATE INDEX "event_registrations_eventid_idx" ON "public"."event_registrations" USING "btree" ("eventId");



CREATE INDEX "event_registrations_tenant_idx" ON "public"."event_registrations" USING "btree" ("tenantId");



CREATE INDEX "event_registrations_userid_idx" ON "public"."event_registrations" USING "btree" ("userId");



CREATE INDEX "events_date_idx" ON "public"."events" USING "btree" ("date");



CREATE INDEX "events_tenant_idx" ON "public"."events" USING "btree" ("tenantId");



CREATE INDEX "expenses_date_idx" ON "public"."expenses" USING "btree" ("date");



CREATE INDEX "expenses_tenant_idx" ON "public"."expenses" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "families_anker_einmalig" ON "public"."families" USING "btree" ("anker");



CREATE UNIQUE INDEX "family_links_einmalig" ON "public"."family_links" USING "btree" ("von", "nach", "art");



CREATE UNIQUE INDEX "family_links_geschwister_einmalig" ON "public"."family_links" USING "btree" (LEAST("von", "nach"), GREATEST("von", "nach")) WHERE ("art" = 'GESCHWISTER'::"text");



CREATE INDEX "family_links_nach_idx" ON "public"."family_links" USING "btree" ("nach");



CREATE UNIQUE INDEX "family_links_partner_einmalig" ON "public"."family_links" USING "btree" (LEAST("von", "nach"), GREATEST("von", "nach")) WHERE ("art" = 'PARTNER'::"text");



CREATE INDEX "family_links_von_idx" ON "public"."family_links" USING "btree" ("von");



CREATE INDEX "fiscal_budgets_tenant_idx" ON "public"."fiscal_budgets" USING "btree" ("tenantId");



CREATE INDEX "fiscal_years_tenant_idx" ON "public"."fiscal_years" USING "btree" ("tenantId");



CREATE INDEX "floky_gespraeche_meine" ON "public"."floky_gespraeche" USING "btree" ("userId", "archiviert", "geaendert_am" DESC);



CREATE INDEX "floky_nachrichten_folge" ON "public"."floky_nachrichten" USING "btree" ("gespraech_id", "erstellt_am");



CREATE INDEX "floky_protokoll_verein_zeit" ON "public"."floky_protokoll" USING "btree" ("tenantId", "erstellt_am" DESC);



CREATE INDEX "inquiries_tenant_idx" ON "public"."inquiries" USING "btree" ("tenantId");



CREATE INDEX "inquiries_userid_idx" ON "public"."inquiries" USING "btree" ("userId");



CREATE UNIQUE INDEX "mail_queue_once_per_year" ON "public"."mail_queue" USING "btree" ("kind", "memberId", "refYear") WHERE (("memberId" IS NOT NULL) AND ("refYear" IS NOT NULL));



CREATE INDEX "mail_queue_pending" ON "public"."mail_queue" USING "btree" ("scheduledFor") WHERE ("status" = 'PENDING'::"text");



CREATE INDEX "mitglied_meldungen_offen" ON "public"."mitglied_meldungen" USING "btree" ("tenantId", "status", "createdAt" DESC);



CREATE INDEX "neighborhoods_tenant_idx" ON "public"."neighborhoods" USING "btree" ("tenantId");



CREATE INDEX "news_publishat_idx" ON "public"."news" USING "btree" ("publishAt");



CREATE INDEX "news_tenant_idx" ON "public"."news" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "payment_reports_one_open" ON "public"."payment_reports" USING "btree" ("paymentId") WHERE ("status" = 'OPEN'::"text");



CREATE INDEX "payment_reports_tenant_status" ON "public"."payment_reports" USING "btree" ("tenantId", "status");



CREATE INDEX "payments_billingyear_idx" ON "public"."payments" USING "btree" ("billingYear");



CREATE INDEX "payments_status_idx" ON "public"."payments" USING "btree" ("status");



CREATE INDEX "payments_tenant_idx" ON "public"."payments" USING "btree" ("tenantId");



CREATE INDEX "payments_userid_idx" ON "public"."payments" USING "btree" ("userId");



CREATE INDEX "platform_invoices_status_idx" ON "public"."platform_invoices" USING "btree" ("status");



CREATE INDEX "platform_invoices_tenant_idx" ON "public"."platform_invoices" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "platform_invoices_treffen_je_verein" ON "public"."platform_invoices" USING "btree" ("treffen_id", "tenantId") WHERE ("treffen_id" IS NOT NULL);



CREATE INDEX "platform_leads_stage_idx" ON "public"."platform_leads" USING "btree" ("stage");



CREATE INDEX "platform_support_open_idx" ON "public"."platform_support" USING "btree" ("lower"("email")) WHERE ("endedAt" IS NULL);



CREATE INDEX "polls_tenant_idx" ON "public"."polls" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "post_ausgang_je_rechnung" ON "public"."post_ausgang" USING "btree" ("paymentId") WHERE (("paymentId" IS NOT NULL) AND ("zustand" <> 'ABGEBROCHEN'::"text"));



CREATE INDEX "post_ausgang_offen" ON "public"."post_ausgang" USING "btree" ("zustand", "naechster_versuch") WHERE ("zustand" = 'WARTEND'::"text");



CREATE INDEX "post_ausgang_pingen" ON "public"."post_ausgang" USING "btree" ("pingen_id") WHERE ("pingen_id" IS NOT NULL);



CREATE UNIQUE INDEX "post_kontingent_je_brief" ON "public"."post_kontingent" USING "btree" ("postId") WHERE ("postId" IS NOT NULL);



CREATE INDEX "post_kontingent_verein" ON "public"."post_kontingent" USING "btree" ("tenantId", "erstellt_am" DESC);



CREATE INDEX "revisionszugaenge_verein" ON "public"."revisionszugaenge" USING "btree" ("tenantId", "erstellt_am" DESC);



CREATE INDEX "security_logs_tenant_idx" ON "public"."security_logs" USING "btree" ("tenantId");



CREATE INDEX "seiten_menue" ON "public"."seiten" USING "btree" ("tenantId", "status", "im_menue", "reihenfolge");



CREATE INDEX "seitenaufrufe_besucher" ON "public"."seitenaufrufe" USING "btree" ("besucher", "gesehen_am" DESC);



CREATE INDEX "seitenaufrufe_pfad" ON "public"."seitenaufrufe" USING "btree" ("tenantId", "pfad", "gesehen_am" DESC);



CREATE INDEX "seitenaufrufe_zeit" ON "public"."seitenaufrufe" USING "btree" ("tenantId", "gesehen_am" DESC);



CREATE INDEX "settings_tenant_idx" ON "public"."settings" USING "btree" ("tenantId");



CREATE INDEX "socialmediaposts_tenant_idx" ON "public"."socialmediaposts" USING "btree" ("tenantId");



CREATE INDEX "sponsors_created_idx" ON "public"."sponsors" USING "btree" ("createdAt" DESC);



CREATE INDEX "sponsors_status_idx" ON "public"."sponsors" USING "btree" ("tenantId", "status");



CREATE INDEX "sponsors_tenant_idx" ON "public"."sponsors" USING "btree" ("tenantId");



CREATE INDEX "tasks_tenant_idx" ON "public"."tasks" USING "btree" ("tenantId");



CREATE INDEX "tenant_domains_tenant_idx" ON "public"."tenant_domains" USING "btree" ("tenantId");



CREATE INDEX "tenant_modules_verein_idx" ON "public"."tenant_modules" USING "btree" ("tenantId");



CREATE UNIQUE INDEX "tenants_slug_idx" ON "public"."tenants" USING "btree" ("slug");



CREATE INDEX "textbausteine_verein" ON "public"."textbausteine" USING "btree" ("tenantId", "schluessel");



CREATE INDEX "treffen_delegation_teilnehmer" ON "public"."treffen_delegation" USING "btree" ("teilnehmer_id");



CREATE UNIQUE INDEX "treffen_delegation_token" ON "public"."treffen_delegation" USING "btree" ("token_hash") WHERE ("token_hash" IS NOT NULL);



CREATE INDEX "treffen_gastgeber_idx" ON "public"."treffen" USING "btree" ("gastgeber");



CREATE INDEX "treffen_programm_zeit" ON "public"."treffen_programm" USING "btree" ("treffen_id", "tag", "beginn", "reihenfolge");



CREATE INDEX "treffen_teilnehmer_treffen" ON "public"."treffen_teilnehmer" USING "btree" ("treffen_id");



CREATE UNIQUE INDEX "users_email_je_verein" ON "public"."users" USING "btree" ("tenantId", "lower"("btrim"("email"))) WHERE (("email" IS NOT NULL) AND ("btrim"("email") <> ''::"text"));



CREATE UNIQUE INDEX "users_konto_je_verein" ON "public"."users" USING "btree" ("tenantId", "authUserId") WHERE ("authUserId" IS NOT NULL);



CREATE INDEX "users_membershipstatus_idx" ON "public"."users" USING "btree" ("membershipStatus");



CREATE INDEX "users_neighborhoodid_idx" ON "public"."users" USING "btree" ("neighborhoodId");



CREATE INDEX "users_tenant_idx" ON "public"."users" USING "btree" ("tenantId");



CREATE INDEX "zahlungseingaenge_verein" ON "public"."zahlungseingaenge" USING "btree" ("tenantId", "eingang" DESC);



CREATE INDEX "zahlungseingaenge_zahlung" ON "public"."zahlungseingaenge" USING "btree" ("paymentId");



CREATE OR REPLACE TRIGGER "accounting_accounts_set_tenant" BEFORE INSERT ON "public"."accounting_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "accounting_journal_jahressperre" BEFORE INSERT OR DELETE OR UPDATE ON "public"."accounting_journal" FOR EACH ROW EXECUTE FUNCTION "public"."geschlossenes_jahr_schuetzen"();



CREATE OR REPLACE TRIGGER "accounting_journal_protokoll" AFTER DELETE OR UPDATE ON "public"."accounting_journal" FOR EACH ROW EXECUTE FUNCTION "public"."buchung_protokollieren"();



CREATE OR REPLACE TRIGGER "accounting_journal_set_tenant" BEFORE INSERT ON "public"."accounting_journal" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "accounting_journal_zz_belegnr" BEFORE INSERT ON "public"."accounting_journal" FOR EACH ROW EXECUTE FUNCTION "public"."belegnummer_vergeben"();



CREATE OR REPLACE TRIGGER "board_meetings_freigabe" BEFORE UPDATE ON "public"."board_meetings" FOR EACH ROW EXECUTE FUNCTION "public"."board_meeting_freigabe"();



CREATE OR REPLACE TRIGGER "board_meetings_set_tenant" BEFORE INSERT ON "public"."board_meetings" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "board_meetings_versionieren" BEFORE UPDATE ON "public"."board_meetings" FOR EACH ROW EXECUTE FUNCTION "public"."board_meeting_versionieren"();



CREATE OR REPLACE TRIGGER "board_members_set_tenant" BEFORE INSERT ON "public"."board_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "event_registrations_capacity" BEFORE INSERT ON "public"."event_registrations" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_event_capacity"();



CREATE OR REPLACE TRIGGER "event_registrations_set_tenant" BEFORE INSERT ON "public"."event_registrations" FOR EACH ROW EXECUTE FUNCTION "public"."set_registration_tenant"();



CREATE OR REPLACE TRIGGER "events_set_tenant" BEFORE INSERT ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "expenses_set_tenant" BEFORE INSERT ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "families_verein_trg" BEFORE INSERT OR UPDATE ON "public"."families" FOR EACH ROW EXECUTE FUNCTION "public"."families_verein_setzen"();



CREATE OR REPLACE TRIGGER "family_links_verein_trg" BEFORE INSERT ON "public"."family_links" FOR EACH ROW EXECUTE FUNCTION "public"."family_links_verein_setzen"();



CREATE OR REPLACE TRIGGER "family_links_zz_pruefen_trg" BEFORE INSERT OR UPDATE ON "public"."family_links" FOR EACH ROW EXECUTE FUNCTION "public"."family_links_pruefen"();



CREATE OR REPLACE TRIGGER "fiscal_budgets_set_tenant" BEFORE INSERT ON "public"."fiscal_budgets" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "fiscal_years_set_tenant" BEFORE INSERT ON "public"."fiscal_years" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "inquiries_set_tenant" BEFORE INSERT ON "public"."inquiries" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "neighborhoods_set_tenant" BEFORE INSERT ON "public"."neighborhoods" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "news_set_tenant" BEFORE INSERT ON "public"."news" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "payments_book_entries" AFTER INSERT OR UPDATE OF "status", "amount" ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."book_payment_entries"();



CREATE OR REPLACE TRIGGER "payments_referenz_trg" BEFORE INSERT ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."rechnung_referenz_setzen"();



CREATE OR REPLACE TRIGGER "payments_set_tenant" BEFORE INSERT ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "polls_set_tenant" BEFORE INSERT ON "public"."polls" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "security_logs_set_tenant" BEFORE INSERT ON "public"."security_logs" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "settings_set_tenant" BEFORE INSERT ON "public"."settings" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "socialmediaposts_set_tenant" BEFORE INSERT ON "public"."socialmediaposts" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "spendenaufrufe_tenant" BEFORE INSERT ON "public"."spendenaufrufe" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "tasks_set_tenant" BEFORE INSERT ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "users_normalise_email" BEFORE INSERT OR UPDATE OF "email" ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."users_normalise_email"();



CREATE OR REPLACE TRIGGER "users_rollenwechsel" BEFORE UPDATE OF "role" ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."rollenwechsel_pruefen"();



CREATE OR REPLACE TRIGGER "users_set_tenant" BEFORE INSERT ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "users_vertreter_spalten" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."users_vertreter_spalten_pruefen"();



CREATE OR REPLACE TRIGGER "videos_tenant" BEFORE INSERT ON "public"."videos" FOR EACH ROW EXECUTE FUNCTION "public"."set_tenant_on_insert"();



CREATE OR REPLACE TRIGGER "zahlungseingaenge_buchen" AFTER INSERT ON "public"."zahlungseingaenge" FOR EACH ROW EXECUTE FUNCTION "public"."eingang_verbuchen"();



CREATE OR REPLACE TRIGGER "zahlungseingaenge_stand" AFTER INSERT OR DELETE OR UPDATE ON "public"."zahlungseingaenge" FOR EACH ROW EXECUTE FUNCTION "public"."zahlung_stand_pflegen"();



ALTER TABLE ONLY "public"."accounting_accounts"
    ADD CONSTRAINT "accounting_accounts_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."accounting_journal"
    ADD CONSTRAINT "accounting_journal_haben_fkey" FOREIGN KEY ("tenantId", "creditCode") REFERENCES "public"."accounting_accounts"("tenantId", "code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."accounting_journal"
    ADD CONSTRAINT "accounting_journal_soll_fkey" FOREIGN KEY ("tenantId", "debitCode") REFERENCES "public"."accounting_accounts"("tenantId", "code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."accounting_journal"
    ADD CONSTRAINT "accounting_journal_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."board_meetings"
    ADD CONSTRAINT "board_meetings_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."board_members"
    ADD CONSTRAINT "board_members_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."board_members"
    ADD CONSTRAINT "board_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."donations"
    ADD CONSTRAINT "donations_aufruf_fkey" FOREIGN KEY ("aufruf") REFERENCES "public"."spendenaufrufe"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."donations"
    ADD CONSTRAINT "donations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_aufwandkonto_fkey" FOREIGN KEY ("tenantId", "categoryAccountCode") REFERENCES "public"."accounting_accounts"("tenantId", "code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_zahlkonto_fkey" FOREIGN KEY ("tenantId", "paymentAccountCode") REFERENCES "public"."accounting_accounts"("tenantId", "code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."families"
    ADD CONSTRAINT "families_anker_fkey" FOREIGN KEY ("anker") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."family_links"
    ADD CONSTRAINT "family_links_nach_fkey" FOREIGN KEY ("nach") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."family_links"
    ADD CONSTRAINT "family_links_von_fkey" FOREIGN KEY ("von") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fiscal_budgets"
    ADD CONSTRAINT "fiscal_budgets_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."fiscal_years"
    ADD CONSTRAINT "fiscal_years_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."floky_einstellungen"
    ADD CONSTRAINT "floky_einstellungen_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."floky_gespraeche"
    ADD CONSTRAINT "floky_gespraeche_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."floky_nachrichten"
    ADD CONSTRAINT "floky_nachrichten_gespraech_id_fkey" FOREIGN KEY ("gespraech_id") REFERENCES "public"."floky_gespraeche"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."floky_protokoll"
    ADD CONSTRAINT "floky_protokoll_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."floky_verbrauch"
    ADD CONSTRAINT "floky_verbrauch_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."glossar"
    ADD CONSTRAINT "glossar_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inquiries"
    ADD CONSTRAINT "inquiries_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."inquiries"
    ADD CONSTRAINT "inquiries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."mitglied_meldungen"
    ADD CONSTRAINT "mitglied_meldungen_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."neighborhoods"
    ADD CONSTRAINT "neighborhoods_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."news"
    ADD CONSTRAINT "news_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."payment_reports"
    ADD CONSTRAINT "payment_reports_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "public"."payments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_neighborhoodId_fkey" FOREIGN KEY ("neighborhoodId") REFERENCES "public"."neighborhoods"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."platform_invoices"
    ADD CONSTRAINT "platform_invoices_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."platform_invoices"
    ADD CONSTRAINT "platform_invoices_treffen_id_fkey" FOREIGN KEY ("treffen_id") REFERENCES "public"."treffen"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."platform_leads"
    ADD CONSTRAINT "platform_leads_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."platform_support"
    ADD CONSTRAINT "platform_support_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."polls"
    ADD CONSTRAINT "polls_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."security_logs"
    ADD CONSTRAINT "security_logs_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."seiten"
    ADD CONSTRAINT "seiten_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."social_connections"
    ADD CONSTRAINT "social_connections_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."social_oauth_state"
    ADD CONSTRAINT "social_oauth_state_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."socialmediaposts"
    ADD CONSTRAINT "socialmediaposts_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."spendenaufrufe"
    ADD CONSTRAINT "spendenaufrufe_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sponsors"
    ADD CONSTRAINT "sponsors_tenant_fk" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."startseiten_vorlagen"
    ADD CONSTRAINT "startseiten_vorlagen_modul_fkey" FOREIGN KEY ("modul") REFERENCES "public"."modules"("schluessel");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_sourceMeetingId_fkey" FOREIGN KEY ("sourceMeetingId") REFERENCES "public"."board_meetings"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."tenant_domains"
    ADD CONSTRAINT "tenant_domains_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_modul_fkey" FOREIGN KEY ("modul") REFERENCES "public"."modules"("schluessel") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."textbausteine"
    ADD CONSTRAINT "textbausteine_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen_ausflug_anmeldung"
    ADD CONSTRAINT "treffen_ausflug_anmeldung_delegation_id_fkey" FOREIGN KEY ("delegation_id") REFERENCES "public"."treffen_delegation"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen_ausflug_anmeldung"
    ADD CONSTRAINT "treffen_ausflug_anmeldung_programm_id_fkey" FOREIGN KEY ("programm_id") REFERENCES "public"."treffen_programm"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen_delegation"
    ADD CONSTRAINT "treffen_delegation_teilnehmer_id_fkey" FOREIGN KEY ("teilnehmer_id") REFERENCES "public"."treffen_teilnehmer"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen"
    ADD CONSTRAINT "treffen_gastgeber_fkey" FOREIGN KEY ("gastgeber") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen_programm"
    ADD CONSTRAINT "treffen_programm_treffen_id_fkey" FOREIGN KEY ("treffen_id") REFERENCES "public"."treffen"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."treffen_teilnehmer"
    ADD CONSTRAINT "treffen_teilnehmer_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."treffen_teilnehmer"
    ADD CONSTRAINT "treffen_teilnehmer_treffen_id_fkey" FOREIGN KEY ("treffen_id") REFERENCES "public"."treffen"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_neighborhoodId_fkey" FOREIGN KEY ("neighborhoodId") REFERENCES "public"."neighborhoods"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."vereinsjahr"
    ADD CONSTRAINT "vereinsjahr_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."zahlungseingaenge"
    ADD CONSTRAINT "zahlungseingaenge_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "public"."payments"("id") ON DELETE CASCADE;



ALTER TABLE "public"."accounting_accounts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "accounting_accounts_staff" ON "public"."accounting_accounts" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text")));



ALTER TABLE "public"."accounting_journal" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."accounting_journal_archiv" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "accounting_journal_staff" ON "public"."accounting_journal" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text")));



ALTER TABLE "public"."admin_emails" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "aufrufe_public_read" ON "public"."spendenaufrufe" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'OEFFENTLICH'::"text") AND ("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())) AND "public"."modul_aktiv"('SPENDEN'::"text") AND (("beginnt_am" IS NULL) OR ("beginnt_am" <= CURRENT_DATE)) AND (("endet_am" IS NULL) OR ("endet_am" >= CURRENT_DATE))));



CREATE POLICY "aufrufe_staff_all" ON "public"."spendenaufrufe" TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('SPENDEN'::"text"))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('SPENDEN'::"text")));



CREATE POLICY "ausflug_eigene" ON "public"."treffen_ausflug_anmeldung" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."treffen_delegation" "d"
     JOIN "public"."treffen_teilnehmer" "te" ON (("te"."id" = "d"."teilnehmer_id")))
  WHERE (("d"."id" = "treffen_ausflug_anmeldung"."delegation_id") AND ("te"."art" = 'VEREIN'::"text") AND ("te"."tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()))));



CREATE POLICY "ausflug_fuehren" ON "public"."treffen_ausflug_anmeldung" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."treffen_programm" "p"
  WHERE (("p"."id" = "treffen_ausflug_anmeldung"."programm_id") AND "public"."treffen_gastgeber"("p"."treffen_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."treffen_programm" "p"
  WHERE (("p"."id" = "treffen_ausflug_anmeldung"."programm_id") AND "public"."treffen_gastgeber"("p"."treffen_id")))));



ALTER TABLE "public"."board_meeting_versions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "board_meeting_versions_read" ON "public"."board_meeting_versions" FOR SELECT TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."board_meetings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "board_meetings_published_read" ON "public"."board_meetings" FOR SELECT TO "authenticated" USING ((("publishedToMembers" IS TRUE) AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "board_meetings_staff" ON "public"."board_meetings" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."board_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "board_members_manage" ON "public"."board_members" TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "board_members_public_read" ON "public"."board_members" FOR SELECT TO "authenticated", "anon" USING (("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())));



ALTER TABLE "public"."buchungsprotokoll" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "buchungsprotokoll_lesen" ON "public"."buchungsprotokoll" FOR SELECT TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."donations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "donations_eigene" ON "public"."donations" FOR SELECT TO "authenticated" USING ((("userId" = "public"."current_user_row_id"()) AND "public"."modul_aktiv"('SPENDEN'::"text")));



CREATE POLICY "donations_verwaltung" ON "public"."donations" TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('SPENDEN'::"text"))) WITH CHECK ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('SPENDEN'::"text")));



CREATE POLICY "eingaenge_lesen" ON "public"."zahlungseingaenge" FOR SELECT TO "authenticated" USING (("public"."is_platform_admin"() OR (("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()) OR (EXISTS ( SELECT 1
   FROM "public"."payments" "p"
  WHERE (("p"."id" = "zahlungseingaenge"."paymentId") AND ("p"."userId" = "public"."current_user_row_id"()))))));



ALTER TABLE "public"."event_registrations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "event_registrations_guest_insert" ON "public"."event_registrations" FOR INSERT WITH CHECK ((("userId" IS NULL) AND "public"."modul_aktiv"('ANLAESSE'::"text") AND ("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())) AND (EXISTS ( SELECT 1
   FROM "public"."events" "e"
  WHERE (("e"."id" = "event_registrations"."eventId") AND ("e"."tenantId" = "e"."tenantId"))))));



CREATE POLICY "event_registrations_insert" ON "public"."event_registrations" FOR INSERT WITH CHECK (("public"."modul_aktiv"('ANLAESSE'::"text") AND (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("userId" = "public"."current_user_row_id"()))));



CREATE POLICY "event_registrations_manage" ON "public"."event_registrations" FOR UPDATE USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('ANLAESSE'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('ANLAESSE'::"text")));



CREATE POLICY "event_registrations_read" ON "public"."event_registrations" FOR SELECT USING (("public"."modul_aktiv"('ANLAESSE'::"text") AND (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("userId" = "public"."current_user_row_id"()))));



ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "events_manage" ON "public"."events" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('ANLAESSE'::"text"))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('ANLAESSE'::"text")));



CREATE POLICY "events_public_read" ON "public"."events" FOR SELECT USING ((("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())) AND "public"."modul_aktiv"('ANLAESSE'::"text")));



ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "expenses_staff" ON "public"."expenses" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text")));



ALTER TABLE "public"."families" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "families_lesen" ON "public"."families" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('STAMMBAUM'::"text") AND ("public"."is_member_manager"() OR ("public"."is_neighborhood_steward"() AND (EXISTS ( SELECT 1
   FROM "public"."users" "u"
  WHERE (("u"."id" = "families"."anker") AND ("u"."neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods")))))))));



CREATE POLICY "families_schreiben" ON "public"."families" TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('STAMMBAUM'::"text"))) WITH CHECK ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('STAMMBAUM'::"text")));



ALTER TABLE "public"."family_links" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "family_links_lesen" ON "public"."family_links" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('STAMMBAUM'::"text") AND ("public"."is_member_manager"() OR ("public"."is_neighborhood_steward"() AND (EXISTS ( SELECT 1
   FROM "public"."users" "u"
  WHERE (("u"."id" = ANY (ARRAY["family_links"."von", "family_links"."nach"])) AND ("u"."neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods")))))))));



CREATE POLICY "family_links_schreiben" ON "public"."family_links" TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('STAMMBAUM'::"text"))) WITH CHECK ((("tenantId" = "public"."current_tenant"()) AND "public"."is_member_manager"() AND "public"."modul_aktiv"('STAMMBAUM'::"text")));



ALTER TABLE "public"."fiscal_budgets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "fiscal_budgets_staff" ON "public"."fiscal_budgets" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text")));



ALTER TABLE "public"."fiscal_years" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "fiscal_years_staff_all" ON "public"."fiscal_years" USING ((("public"."app_role"() = ANY (ARRAY['SUPER_ADMIN'::"text", 'ADMIN'::"text", 'BOARD'::"text"])) AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text"))) WITH CHECK ((("public"."app_role"() = ANY (ARRAY['SUPER_ADMIN'::"text", 'ADMIN'::"text", 'BOARD'::"text"])) AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('BUCHHALTUNG'::"text")));



ALTER TABLE "public"."floky_einstellungen" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "floky_einstellungen_lesen" ON "public"."floky_einstellungen" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_staff"())));



ALTER TABLE "public"."floky_gespraeche" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "floky_gespraeche_meine" ON "public"."floky_gespraeche" FOR SELECT TO "authenticated" USING ((("userId" = "public"."current_user_row_id"()) AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."floky_nachrichten" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "floky_nachrichten_meine" ON "public"."floky_nachrichten" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."floky_gespraeche" "g"
  WHERE (("g"."id" = "floky_nachrichten"."gespraech_id") AND ("g"."userId" = "public"."current_user_row_id"()) AND ("g"."tenantId" = "public"."current_tenant"())))));



ALTER TABLE "public"."floky_protokoll" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "floky_protokoll_lesen" ON "public"."floky_protokoll" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_staff"())));



ALTER TABLE "public"."floky_verbrauch" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "floky_verbrauch_lesen" ON "public"."floky_verbrauch" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_staff"())));



ALTER TABLE "public"."glossar" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "glossar_lesen" ON "public"."glossar" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) OR "public"."is_platform_admin"()));



CREATE POLICY "glossar_pflegen" ON "public"."glossar" TO "authenticated" USING (("public"."is_platform_admin"() OR (("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()))) WITH CHECK (("public"."is_platform_admin"() OR (("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"())));



CREATE POLICY "herkunft_lesen" ON "public"."versand_herkunft" FOR SELECT TO "authenticated" USING ("public"."is_platform_admin"());



ALTER TABLE "public"."inquiries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inquiries_insert" ON "public"."inquiries" FOR INSERT TO "authenticated" WITH CHECK ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("userId" = "public"."current_user_row_id"())));



CREATE POLICY "inquiries_manage" ON "public"."inquiries" FOR UPDATE TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "inquiries_read" ON "public"."inquiries" FOR SELECT TO "authenticated" USING ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("userId" = "public"."current_user_row_id"())));



ALTER TABLE "public"."mail_domain_weg" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mail_domain_weg_lesen" ON "public"."mail_domain_weg" FOR SELECT TO "authenticated" USING (("public"."is_platform_admin"() OR "public"."is_member_manager"()));



ALTER TABLE "public"."mail_queue" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mail_queue_staff" ON "public"."mail_queue" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."mail_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mitglied_meldungen" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mitglied_meldungen_lesen" ON "public"."mitglied_meldungen" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_member_manager"() OR ("reportedBy" = "public"."current_user_row_id"()))));



ALTER TABLE "public"."modules" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "modules_lesen" ON "public"."modules" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."neighborhoods" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "neighborhoods_manage" ON "public"."neighborhoods" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "neighborhoods_public_read" ON "public"."neighborhoods" FOR SELECT TO "authenticated", "anon" USING (("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())));



ALTER TABLE "public"."news" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "news_manage" ON "public"."news" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('NEUIGKEITEN'::"text"))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('NEUIGKEITEN'::"text")));



CREATE POLICY "news_public_read" ON "public"."news" FOR SELECT USING ((("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())) AND "public"."modul_aktiv"('NEUIGKEITEN'::"text")));



ALTER TABLE "public"."payment_reports" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payment_reports_decide" ON "public"."payment_reports" FOR UPDATE TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "payment_reports_delete" ON "public"."payment_reports" FOR DELETE TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "payment_reports_insert" ON "public"."payment_reports" FOR INSERT TO "authenticated" WITH CHECK ((("tenantId" = "public"."current_tenant"()) AND ("reportedBy" = "public"."current_user_row_id"()) AND ("status" = 'OPEN'::"text") AND ("decidedBy" IS NULL) AND ("decidedAt" IS NULL) AND ("public"."is_member_manager"() OR ("public"."is_neighborhood_steward"() AND ("paymentId" IN ( SELECT "p"."id"
   FROM ("public"."payments" "p"
     JOIN "public"."users" "u" ON (("u"."id" = "p"."userId")))
  WHERE ("u"."neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods"))))))));



CREATE POLICY "payment_reports_read" ON "public"."payment_reports" FOR SELECT TO "authenticated" USING ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("reportedBy" = "public"."current_user_row_id"()) OR ("paymentId" IN ( SELECT "p"."id"
   FROM "public"."payments" "p"
  WHERE ("p"."userId" = "public"."current_user_row_id"())))));



ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payments_read" ON "public"."payments" FOR SELECT TO "authenticated" USING ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("userId" = "public"."current_user_row_id"()) OR ("public"."is_neighborhood_steward"() AND ("tenantId" = "public"."current_tenant"()) AND ("userId" IN ( SELECT "u"."id"
   FROM "public"."users" "u"
  WHERE ("u"."neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods")))))));



CREATE POLICY "payments_write" ON "public"."payments" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."platform_admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."platform_invoices" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "platform_invoices_owner" ON "public"."platform_invoices" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."platform_leads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "platform_leads_owner" ON "public"."platform_leads" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."platform_secrets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."platform_support" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "platform_support_read" ON "public"."platform_support" FOR SELECT TO "authenticated" USING (("public"."is_platform_admin"() OR ("tenantId" = ( SELECT "u"."tenantId"
   FROM "public"."users" "u"
  WHERE ("u"."id" = "public"."current_user_row_id"())))));



CREATE POLICY "platform_support_write" ON "public"."platform_support" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."polls" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "polls_manage" ON "public"."polls" TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "polls_public_read" ON "public"."polls" FOR SELECT TO "authenticated", "anon" USING (("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())));



ALTER TABLE "public"."post_ausgang" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_kontingent" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_preise" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."postausgang_zustand" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "postausgang_zustand_lesen" ON "public"."postausgang_zustand" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."pruefstand_referenzen" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."revisionszugaenge" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "revisionszugaenge_lesen" ON "public"."revisionszugaenge" FOR SELECT TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "schreibschranke_del" ON "public"."accounting_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."accounting_journal" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."board_meetings" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."board_members" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."donations" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."event_registrations" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."events" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."expenses" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."families" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."family_links" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."fiscal_budgets" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."glossar" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."inquiries" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."mail_queue" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."neighborhoods" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."news" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."payment_reports" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."payments" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."polls" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."security_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."settings" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."socialmediaposts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."spendenaufrufe" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."sponsors" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."tasks" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."textbausteine" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."treffen" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."treffen_delegation" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."treffen_teilnehmer" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."users" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_del" ON "public"."videos" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."accounting_accounts" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."accounting_journal" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."board_meetings" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."board_members" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."donations" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."event_registrations" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."events" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."expenses" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."families" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."family_links" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."fiscal_budgets" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."glossar" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."inquiries" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."mail_queue" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."neighborhoods" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."news" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."payment_reports" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."payments" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."polls" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."security_logs" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."settings" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."socialmediaposts" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."spendenaufrufe" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."sponsors" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."tasks" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."textbausteine" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."treffen" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."treffen_delegation" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."treffen_teilnehmer" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."users" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_ins" ON "public"."videos" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."accounting_accounts" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."accounting_journal" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."board_meetings" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."board_members" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."donations" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."event_registrations" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."events" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."expenses" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."families" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."family_links" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."fiscal_budgets" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."glossar" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."inquiries" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."mail_queue" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."neighborhoods" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."news" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."payment_reports" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."payments" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."polls" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."security_logs" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."settings" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."socialmediaposts" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."spendenaufrufe" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."sponsors" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."tasks" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."textbausteine" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."treffen" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."treffen_delegation" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."treffen_teilnehmer" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."users" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



CREATE POLICY "schreibschranke_upd" ON "public"."videos" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ("public"."darf_schreiben"()) WITH CHECK ("public"."darf_schreiben"());



ALTER TABLE "public"."security_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "security_logs_staff" ON "public"."security_logs" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."seiten" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "seiten_intern" ON "public"."seiten" FOR SELECT TO "authenticated" USING ((("status" = 'OEFFENTLICH'::"text") OR (("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_staff"()))));



CREATE POLICY "seiten_oeffentlich" ON "public"."seiten" FOR SELECT TO "anon" USING ((("status" = 'OEFFENTLICH'::"text") AND ("tenantId" = "public"."request_tenant"())));



ALTER TABLE "public"."seitenaufrufe" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."settings_archiv" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "settings_manage" ON "public"."settings" TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "settings_staff_read" ON "public"."settings" FOR SELECT TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."social_connections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."social_oauth_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."socialmediaposts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "socialmediaposts_staff" ON "public"."socialmediaposts" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('SOCIAL'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('SOCIAL'::"text")));



ALTER TABLE "public"."spendenaufrufe" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sponsors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sponsors_staff_delete" ON "public"."sponsors" FOR DELETE USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('TURNIER'::"text")));



CREATE POLICY "sponsors_staff_read" ON "public"."sponsors" FOR SELECT USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('TURNIER'::"text")));



CREATE POLICY "sponsors_staff_update" ON "public"."sponsors" FOR UPDATE USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('TURNIER'::"text"))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('TURNIER'::"text")));



ALTER TABLE "public"."startseiten_vorlagen" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tasks_staff" ON "public"."tasks" TO "authenticated" USING (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"()))) WITH CHECK (("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."tenant_domains" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenant_domains_platform" ON "public"."tenant_domains" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."tenant_modules" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenant_modules_lesen" ON "public"."tenant_modules" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) OR "public"."is_platform_admin"()));



CREATE POLICY "tenant_modules_schreiben" ON "public"."tenant_modules" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."tenants" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenants_own_read" ON "public"."tenants" FOR SELECT TO "authenticated" USING (("public"."is_platform_admin"() OR ("id" = "public"."current_tenant"())));



CREATE POLICY "tenants_platform_manage" ON "public"."tenants" TO "authenticated" USING ("public"."is_platform_admin"()) WITH CHECK ("public"."is_platform_admin"());



ALTER TABLE "public"."textbausteine" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "textbausteine_lesen" ON "public"."textbausteine" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) OR "public"."is_platform_admin"()));



CREATE POLICY "textbausteine_pflegen" ON "public"."textbausteine" TO "authenticated" USING (("public"."is_platform_admin"() OR (("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()))) WITH CHECK (("public"."is_platform_admin"() OR (("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"())));



ALTER TABLE "public"."treffen" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."treffen_ausflug_anmeldung" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."treffen_delegation" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "treffen_delegation_eigene" ON "public"."treffen_delegation" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."treffen_teilnehmer" "t"
  WHERE (("t"."id" = "treffen_delegation"."teilnehmer_id") AND ("t"."art" = 'VEREIN'::"text") AND ("t"."tenantId" = "public"."current_tenant"()) AND "public"."is_staff"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."treffen_teilnehmer" "t"
  WHERE (("t"."id" = "treffen_delegation"."teilnehmer_id") AND ("t"."art" = 'VEREIN'::"text") AND ("t"."tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()))));



CREATE POLICY "treffen_delegation_fuehren" ON "public"."treffen_delegation" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."treffen_teilnehmer" "te"
  WHERE (("te"."id" = "treffen_delegation"."teilnehmer_id") AND "public"."treffen_gastgeber"("te"."treffen_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."treffen_teilnehmer" "te"
  WHERE (("te"."id" = "treffen_delegation"."teilnehmer_id") AND "public"."treffen_gastgeber"("te"."treffen_id")))));



CREATE POLICY "treffen_fuehren" ON "public"."treffen" TO "authenticated" USING (("public"."is_platform_admin"() OR (("gastgeber" IS NOT NULL) AND ("gastgeber" = "public"."current_tenant"()) AND "public"."is_staff"() AND "public"."modul_aktiv"('TREFFEN'::"text")))) WITH CHECK ("public"."treffen_darf_anlegen"("gastgeber"));



CREATE POLICY "treffen_lesen" ON "public"."treffen" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'OEFFENTLICH'::"text") OR "public"."is_platform_admin"() OR (("gastgeber" IS NOT NULL) AND ("gastgeber" = "public"."current_tenant"()) AND "public"."is_staff"() AND "public"."modul_aktiv"('TREFFEN'::"text")) OR (EXISTS ( SELECT 1
   FROM "public"."treffen_teilnehmer" "te"
  WHERE (("te"."treffen_id" = "treffen"."id") AND ("te"."tenantId" = "public"."current_tenant"()))))));



ALTER TABLE "public"."treffen_programm" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "treffen_programm_fuehren" ON "public"."treffen_programm" TO "authenticated" USING ("public"."treffen_gastgeber"("treffen_id")) WITH CHECK ("public"."treffen_gastgeber"("treffen_id"));



CREATE POLICY "treffen_programm_lesen" ON "public"."treffen_programm" FOR SELECT TO "authenticated", "anon" USING (("public"."treffen_gastgeber"("treffen_id") OR ("freigegeben" AND (EXISTS ( SELECT 1
   FROM "public"."treffen" "t"
  WHERE (("t"."id" = "treffen_programm"."treffen_id") AND ("t"."status" = 'OEFFENTLICH'::"text")))))));



ALTER TABLE "public"."treffen_teilnehmer" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "treffen_teilnehmer_eigene_zusage" ON "public"."treffen_teilnehmer" FOR UPDATE TO "authenticated" USING ((("art" = 'VEREIN'::"text") AND ("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"())) WITH CHECK ((("art" = 'VEREIN'::"text") AND ("tenantId" = "public"."current_tenant"()) AND "public"."is_staff"()));



CREATE POLICY "treffen_teilnehmer_fuehren" ON "public"."treffen_teilnehmer" TO "authenticated" USING ("public"."treffen_gastgeber"("treffen_id")) WITH CHECK ("public"."treffen_gastgeber"("treffen_id"));



CREATE POLICY "treffen_teilnehmer_lesen" ON "public"."treffen_teilnehmer" FOR SELECT TO "authenticated" USING (("public"."is_platform_admin"() OR ("tenantId" = "public"."current_tenant"())));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_delete" ON "public"."users" FOR DELETE TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"())));



CREATE POLICY "users_insert" ON "public"."users" FOR INSERT TO "authenticated" WITH CHECK ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR (("id" = ("auth"."uid"())::"text") AND (COALESCE("role", 'MEMBER'::"text") = ANY (ARRAY["public"."claimable_role"(), 'MEMBER'::"text"])))));



CREATE POLICY "users_select" ON "public"."users" FOR SELECT TO "authenticated" USING ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("public"."is_neighborhood_steward"() AND ("tenantId" = "public"."current_tenant"()) AND ("neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods"))) OR ("id" = ("auth"."uid"())::"text") OR ("authUserId" = ("auth"."uid"())::"text") OR ((("auth"."jwt"() ->> 'email'::"text") IS NOT NULL) AND ("lower"("email") = "lower"(("auth"."jwt"() ->> 'email'::"text"))))));



CREATE POLICY "users_update" ON "public"."users" FOR UPDATE TO "authenticated" USING ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("public"."is_neighborhood_steward"() AND ("tenantId" = "public"."current_tenant"()) AND ("neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods")) AND (COALESCE("role", 'MEMBER'::"text") = 'MEMBER'::"text")) OR ("id" = ("auth"."uid"())::"text") OR ("authUserId" = ("auth"."uid"())::"text"))) WITH CHECK ((("public"."is_member_manager"() AND ("tenantId" = "public"."current_tenant"())) OR ("public"."is_neighborhood_steward"() AND ("tenantId" = "public"."current_tenant"()) AND ("neighborhoodId" IN ( SELECT "public"."my_neighborhoods"() AS "my_neighborhoods")) AND (COALESCE("role", 'MEMBER'::"text") = 'MEMBER'::"text")) OR ((("id" = ("auth"."uid"())::"text") OR ("authUserId" = ("auth"."uid"())::"text")) AND (COALESCE("role", 'MEMBER'::"text") = COALESCE("public"."app_role"(), 'MEMBER'::"text")))));



ALTER TABLE "public"."vereinsjahr" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vereinsjahr_aendern" ON "public"."vereinsjahr" FOR UPDATE TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR ("public"."app_role"() = ANY (ARRAY['SUPER_ADMIN'::"text", 'ADMIN'::"text"]))))) WITH CHECK (("tenantId" = "public"."current_tenant"()));



CREATE POLICY "vereinsjahr_lesen" ON "public"."vereinsjahr" FOR SELECT TO "authenticated" USING ((("tenantId" = "public"."current_tenant"()) AND ("public"."is_platform_admin"() OR "public"."is_staff"())));



ALTER TABLE "public"."versand_herkunft" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "videos_public_read" ON "public"."videos" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'OEFFENTLICH'::"text") AND ("tenantId" = COALESCE("public"."current_tenant"(), "public"."request_tenant"())) AND "public"."modul_aktiv"('VIDEOS'::"text")));



CREATE POLICY "videos_staff_all" ON "public"."videos" TO "authenticated" USING (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('VIDEOS'::"text"))) WITH CHECK (("public"."is_staff"() AND ("tenantId" = "public"."current_tenant"()) AND "public"."modul_aktiv"('VIDEOS'::"text")));



CREATE POLICY "vorlagen_lesen" ON "public"."startseiten_vorlagen" FOR SELECT TO "authenticated", "anon" USING ("aktiv");



ALTER TABLE "public"."zaehler_salz" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zahlungseingaenge" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zahlungsgeheimnisse" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."accounting_accounts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."accounting_journal";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."board_meetings";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."board_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."event_registrations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."events";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."expenses";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."inquiries";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."neighborhoods";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."news";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."payments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."polls";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."security_logs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."settings";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."socialmediaposts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."tasks";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."tenants";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users";









GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































REVOKE ALL ON FUNCTION "public"."app_neighborhood"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."app_neighborhood"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_neighborhood"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_neighborhood"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."app_role"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."app_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_role"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."ausfluege_fuer"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ausfluege_fuer"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ausfluege_fuer"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ausfluege_fuer"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ausflug_anmelden"("p_token" "text", "p_programm" "uuid", "p_dabei" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ausflug_plaetze_frei"("p_programm" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."baustein_gegengelesen"("p_id" "uuid", "p_an" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."baustein_gegengelesen"("p_id" "uuid", "p_an" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."baustein_gegengelesen"("p_id" "uuid", "p_an" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."beitragsjahre_oeffentlich"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."beitragsjahre_oeffentlich"() TO "anon";
GRANT ALL ON FUNCTION "public"."beitragsjahre_oeffentlich"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."beitragsjahre_oeffentlich"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."beitragsstand_oeffentlich"("p_jahr" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."belegnummer_vergeben"() TO "anon";
GRANT ALL ON FUNCTION "public"."belegnummer_vergeben"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."belegnummer_vergeben"() TO "service_role";



GRANT ALL ON FUNCTION "public"."board_meeting_freigabe"() TO "anon";
GRANT ALL ON FUNCTION "public"."board_meeting_freigabe"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."board_meeting_freigabe"() TO "service_role";



GRANT ALL ON FUNCTION "public"."board_meeting_versionieren"() TO "anon";
GRANT ALL ON FUNCTION "public"."board_meeting_versionieren"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."board_meeting_versionieren"() TO "service_role";



GRANT ALL ON FUNCTION "public"."book_payment_entries"() TO "anon";
GRANT ALL ON FUNCTION "public"."book_payment_entries"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."book_payment_entries"() TO "service_role";



GRANT ALL ON FUNCTION "public"."buchung_protokollieren"() TO "anon";
GRANT ALL ON FUNCTION "public"."buchung_protokollieren"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."buchung_protokollieren"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."claim_my_profile"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_my_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_my_profile"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."claimable_role"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claimable_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."claimable_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."claimable_role"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_tenant"("p_name" "text", "p_slug" "text", "p_domain" "text", "p_admin_email" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_tenant"("p_name" "text", "p_slug" "text", "p_domain" "text", "p_admin_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_tenant"("p_name" "text", "p_slug" "text", "p_domain" "text", "p_admin_email" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."current_tenant"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_tenant"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_tenant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_tenant"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."current_user_row_id"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_user_row_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_user_row_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_user_row_id"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."darf_schreiben"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."darf_schreiben"() TO "anon";
GRANT ALL ON FUNCTION "public"."darf_schreiben"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."darf_schreiben"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."decide_payment_report"("p_report" "uuid", "p_approve" boolean, "p_note" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."decide_payment_report"("p_report" "uuid", "p_approve" boolean, "p_note" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."decide_payment_report"("p_report" "uuid", "p_approve" boolean, "p_note" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."eingang_verbuchen"() TO "anon";
GRANT ALL ON FUNCTION "public"."eingang_verbuchen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."eingang_verbuchen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."end_tenant_support"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."end_tenant_support"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."end_tenant_support"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_event_capacity"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_event_capacity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_event_capacity"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."familien_uebersicht"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."familien_uebersicht"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."familien_uebersicht"() TO "service_role";



GRANT ALL ON FUNCTION "public"."families_verein_setzen"() TO "anon";
GRANT ALL ON FUNCTION "public"."families_verein_setzen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."families_verein_setzen"() TO "service_role";



GRANT ALL ON FUNCTION "public"."family_links_pruefen"() TO "anon";
GRANT ALL ON FUNCTION "public"."family_links_pruefen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."family_links_pruefen"() TO "service_role";



GRANT ALL ON FUNCTION "public"."family_links_verein_setzen"() TO "anon";
GRANT ALL ON FUNCTION "public"."family_links_verein_setzen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."family_links_verein_setzen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_anfrage_zaehlen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_anfrage_zaehlen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_anfrage_zaehlen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_darf"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_darf"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_darf"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_gespraech_ablegen"("p_id" "uuid", "p_archiv" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_gespraech_ablegen"("p_id" "uuid", "p_archiv" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_gespraech_ablegen"("p_id" "uuid", "p_archiv" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_gespraech_beginnen"("p_titel" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_gespraech_beginnen"("p_titel" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_gespraech_beginnen"("p_titel" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_gespraech_loeschen"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_gespraech_loeschen"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_gespraech_loeschen"("p_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_kontingent"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_kontingent"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_kontingent"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_kontingent_setzen"("p_verein" "text", "p_anfragen" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_kontingent_setzen"("p_verein" "text", "p_anfragen" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_kontingent_setzen"("p_verein" "text", "p_anfragen" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_nachricht_ablegen"("p_gespraech" "uuid", "p_rolle" "text", "p_text" "text", "p_werkzeuge" "text"[], "p_karten" "jsonb", "p_kuerzel" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_nachricht_ablegen"("p_gespraech" "uuid", "p_rolle" "text", "p_text" "text", "p_werkzeuge" "text"[], "p_karten" "jsonb", "p_kuerzel" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_nachricht_ablegen"("p_gespraech" "uuid", "p_rolle" "text", "p_text" "text", "p_werkzeuge" "text"[], "p_karten" "jsonb", "p_kuerzel" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_name_setzen"("p_name" "text", "p_du" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_name_setzen"("p_name" "text", "p_du" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_name_setzen"("p_name" "text", "p_du" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_protokollieren"("p_art" "text", "p_werkzeug" "text", "p_zusammenfassung" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_protokollieren"("p_art" "text", "p_werkzeug" "text", "p_zusammenfassung" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_protokollieren"("p_art" "text", "p_werkzeug" "text", "p_zusammenfassung" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_wochenstart_empfaenger"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_wochenstart_empfaenger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_wochenstart_empfaenger"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_wochenstart_setzen"("p_ids" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_wochenstart_setzen"("p_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_wochenstart_setzen"("p_ids" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."floky_wochenstart_waehlbar"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."floky_wochenstart_waehlbar"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."floky_wochenstart_waehlbar"() TO "service_role";



GRANT ALL ON FUNCTION "public"."geschlossenes_jahr_schuetzen"() TO "anon";
GRANT ALL ON FUNCTION "public"."geschlossenes_jahr_schuetzen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."geschlossenes_jahr_schuetzen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."haushalt_vorschlaege"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."haushalt_vorschlaege"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."haushalt_vorschlaege"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."heft_fuer_teilnehmer"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."herkunft_vermerken"("p_ip" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."herkunft_vermerken"("p_ip" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_member_manager"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_member_manager"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_member_manager"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_member_manager"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_neighborhood_steward"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_neighborhood_steward"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_neighborhood_steward"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_platform_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_platform_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_platform_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_platform_admin"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_staff"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_staff"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_staff"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_staff"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."jahresabschluss"("p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."jahresabschluss"("p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."jahresabschluss"("p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."jahresrechnung_betrag"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."jahresrechnung_betrag"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."jahresrechnung_betrag"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."konten_ohne_verbindung"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."konten_ohne_verbindung"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."konten_ohne_verbindung"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."kontenplan_anlegen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."kontenplan_anlegen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."kontenplan_anlegen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."konto_verbinden"("p_member" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."konto_verbinden"("p_member" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."konto_verbinden"("p_member" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mail_einstellungen_lesen"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mail_einstellungen_lesen"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mail_einstellungen_lesen"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mail_einstellungen_speichern"("p_host" "text", "p_port" integer, "p_benutzer" "text", "p_absender" "text", "p_absendername" "text", "p_tls" "text", "p_aktiv" boolean, "p_kennwort" "text", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mail_einstellungen_speichern"("p_host" "text", "p_port" integer, "p_benutzer" "text", "p_absender" "text", "p_absendername" "text", "p_tls" "text", "p_aktiv" boolean, "p_kennwort" "text", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mail_einstellungen_speichern"("p_host" "text", "p_port" integer, "p_benutzer" "text", "p_absender" "text", "p_absendername" "text", "p_tls" "text", "p_aktiv" boolean, "p_kennwort" "text", "p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mail_kennwort_loeschen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mail_kennwort_loeschen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mail_kennwort_loeschen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mark_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_betrag" numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mark_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_betrag" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_betrag" numeric) TO "service_role";



REVOKE ALL ON FUNCTION "public"."marktplatz_uebersicht"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."marktplatz_uebersicht"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."marktplatz_uebersicht"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mitglied_melden"("p_member" "text", "p_art" "text", "p_bemerkung" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mitglied_melden"("p_member" "text", "p_art" "text", "p_bemerkung" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mitglied_melden"("p_member" "text", "p_art" "text", "p_bemerkung" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mitglied_meldung_entscheiden"("p_id" "uuid", "p_uebernehmen" boolean, "p_notiz" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mitglied_meldung_entscheiden"("p_id" "uuid", "p_uebernehmen" boolean, "p_notiz" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mitglied_meldung_entscheiden"("p_id" "uuid", "p_uebernehmen" boolean, "p_notiz" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."mod10_pruefziffer"("p_ziffern" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."mod10_pruefziffer"("p_ziffern" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mod10_pruefziffer"("p_ziffern" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."mod97_pruefziffern"("p_ref" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."mod97_pruefziffern"("p_ref" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mod97_pruefziffern"("p_ref" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."modul_aktiv"("p_modul" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."modul_aktiv"("p_modul" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."modul_aktiv"("p_modul" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."modul_aktiv"("p_modul" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."modul_katalog_speichern"("p_schluessel" "text", "p_preis_monat" numeric, "p_preis_einmalig" numeric, "p_status" "text", "p_beschreibung_de" "text", "p_beschreibung_sq" "text", "p_beschreibung_en" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."modul_katalog_speichern"("p_schluessel" "text", "p_preis_monat" numeric, "p_preis_einmalig" numeric, "p_status" "text", "p_beschreibung_de" "text", "p_beschreibung_sq" "text", "p_beschreibung_en" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."modul_katalog_speichern"("p_schluessel" "text", "p_preis_monat" numeric, "p_preis_einmalig" numeric, "p_status" "text", "p_beschreibung_de" "text", "p_beschreibung_sq" "text", "p_beschreibung_en" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."modul_umschalten"("p_modul" "text", "p_zustand" "text", "p_verein" "text", "p_testet_bis" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."modul_umschalten"("p_modul" "text", "p_zustand" "text", "p_verein" "text", "p_testet_bis" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."modul_umschalten"("p_modul" "text", "p_zustand" "text", "p_verein" "text", "p_testet_bis" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."modul_verbreitung"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."modul_verbreitung"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."modul_verbreitung"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."module_oeffentlich"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."module_oeffentlich"() TO "anon";
GRANT ALL ON FUNCTION "public"."module_oeffentlich"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."module_oeffentlich"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."my_neighborhood_contacts"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."my_neighborhood_contacts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."my_neighborhood_contacts"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."my_neighborhoods"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."my_neighborhoods"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."my_neighborhoods"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."nachbarschaft_puls"("p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."nachbarschaft_puls"("p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."nachbarschaft_puls"("p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."nachbarschaften_ohne_verantwortlichen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."nachbarschaften_ohne_verantwortlichen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."nachbarschaften_ohne_verantwortlichen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."oeffentliche_module"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."oeffentliche_module"() TO "anon";
GRANT ALL ON FUNCTION "public"."oeffentliche_module"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."oeffentliche_module"() TO "service_role";



GRANT ALL ON FUNCTION "public"."payment_asset_code"("p_method" "text", "p_currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."payment_asset_code"("p_method" "text", "p_currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."payment_asset_code"("p_method" "text", "p_currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pfad_belegt"("p_pfad" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pfad_belegt"("p_pfad" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pfad_belegt"("p_pfad" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."plattform_geheimnis_setzen"("p_schluessel" "text", "p_wert" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."plattform_geheimnis_setzen"("p_schluessel" "text", "p_wert" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."plattform_geheimnis_setzen"("p_schluessel" "text", "p_wert" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."plattform_geheimnisse"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."plattform_geheimnisse"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."plattform_geheimnisse"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_abbrechen"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_abbrechen"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_abbrechen"("p_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_einkaufspreis_melden"("p_verein" "text", "p_preis" numeric, "p_waehrung" "text", "p_grundlage" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_einkaufspreis_melden"("p_verein" "text", "p_preis" numeric, "p_waehrung" "text", "p_grundlage" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_einreihen"("p_payment" "text", "p_dateiname" "text", "p_pdf" "text", "p_produkt" "text", "p_farbe" "text", "p_duplex" boolean, "p_adresslage" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_einreihen"("p_payment" "text", "p_dateiname" "text", "p_pdf" "text", "p_produkt" "text", "p_farbe" "text", "p_duplex" boolean, "p_adresslage" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_einreihen"("p_payment" "text", "p_dateiname" "text", "p_pdf" "text", "p_produkt" "text", "p_farbe" "text", "p_duplex" boolean, "p_adresslage" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_kontingent_buch"("p_grenze" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_kontingent_buch"("p_grenze" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_kontingent_buch"("p_grenze" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_kontingent_kaufen"("p_menge" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_kontingent_kaufen"("p_menge" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_kontingent_kaufen"("p_menge" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_kontingent_stand"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_kontingent_stand"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_kontingent_stand"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_kontingent_verbrauchen"("p_post" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_kontingent_verbrauchen"("p_post" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_marge"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_marge"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_marge"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_preis_setzen"("p_verein" "text", "p_aufpreis" numeric, "p_fest" numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_preis_setzen"("p_verein" "text", "p_aufpreis" numeric, "p_fest" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_preis_setzen"("p_verein" "text", "p_aufpreis" numeric, "p_fest" numeric) TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_tarife"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_tarife"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_tarife"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_uebersicht"("p_grenze" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_uebersicht"("p_grenze" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_uebersicht"("p_grenze" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."post_zustand_melden"("p_id" "uuid", "p_pingen_id" "text", "p_zustand" "text", "p_status" "text", "p_meldung" "text", "p_fehler" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."post_zustand_melden"("p_id" "uuid", "p_pingen_id" "text", "p_zustand" "text", "p_status" "text", "p_meldung" "text", "p_fehler" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."postausgang_bereit"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."postausgang_bereit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postausgang_bereit"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."postausgang_luecken"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."postausgang_luecken"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postausgang_luecken"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."postausgang_melden"("p_bereit" boolean, "p_quelle" "text", "p_fehler" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."postausgang_melden"("p_bereit" boolean, "p_quelle" "text", "p_fehler" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."postausgang_stau"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."postausgang_stau"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postausgang_stau"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."queue_birthday_greetings"("p_day" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."queue_birthday_greetings"("p_day" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."queue_birthday_greetings"("p_day" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."rechnung_referenz_setzen"() TO "anon";
GRANT ALL ON FUNCTION "public"."rechnung_referenz_setzen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rechnung_referenz_setzen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."referenz_fuer_rechnung"("p_rechnungsnummer" "text", "p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."referenzart"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."referenzart"("p_verein" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."referenzart"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."referenzart"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."report_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_note" "text", "p_betrag" numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."report_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_note" "text", "p_betrag" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."report_payment_paid"("p_payment" "text", "p_method" "text", "p_paid_on" "date", "p_note" "text", "p_betrag" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."request_tenant"() TO "anon";
GRANT ALL ON FUNCTION "public"."request_tenant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_tenant"() TO "service_role";



GRANT ALL ON FUNCTION "public"."request_tenant_probe"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_tenant_probe"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."reset_member_password"("p_member" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reset_member_password"("p_member" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reset_member_password"("p_member" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."revisionsbericht"("p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revisionsbericht"("p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."revisionsbericht"("p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."revisionsbericht_fuer"("p_verein" "text", "p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revisionsbericht_fuer"("p_verein" "text", "p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."revisionsdaten"("p_token" "text", "p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."revisionszugang_erstellen"("p_bezeichnung" "text", "p_gueltig_bis" "date", "p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revisionszugang_erstellen"("p_bezeichnung" "text", "p_gueltig_bis" "date", "p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."revisionszugang_erstellen"("p_bezeichnung" "text", "p_gueltig_bis" "date", "p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."revisionszugang_widerrufen"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revisionszugang_widerrufen"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."revisionszugang_widerrufen"("p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rolle_setzen"("p_user" "text", "p_rolle" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rolle_setzen"("p_user" "text", "p_rolle" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rolle_setzen"("p_user" "text", "p_rolle" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rollen_rang"("p_rolle" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rollen_rang"("p_rolle" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rollen_rang"("p_rolle" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rollenwechsel_pruefen"() TO "anon";
GRANT ALL ON FUNCTION "public"."rollenwechsel_pruefen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rollenwechsel_pruefen"() TO "service_role";



GRANT ALL ON FUNCTION "public"."scor_referenz"("p_kern" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."scor_referenz"("p_kern" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."scor_referenz"("p_kern" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seite_loeschen"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seite_loeschen"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seite_loeschen"("p_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seite_speichern"("p_id" "uuid", "p_pfad" "text", "p_titel" "jsonb", "p_bloecke" "jsonb", "p_status" "text", "p_im_menue" boolean, "p_reihenfolge" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seite_speichern"("p_id" "uuid", "p_pfad" "text", "p_titel" "jsonb", "p_bloecke" "jsonb", "p_status" "text", "p_im_menue" boolean, "p_reihenfolge" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."seite_speichern"("p_id" "uuid", "p_pfad" "text", "p_titel" "jsonb", "p_bloecke" "jsonb", "p_status" "text", "p_im_menue" boolean, "p_reihenfolge" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."seitenaufruf_dauer"("p_id" "uuid", "p_sekunden" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text", "p_verweis" "text", "p_ziel" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text", "p_verweis" "text", "p_ziel" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text", "p_verweis" "text", "p_ziel" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seitenaufruf_zaehlen"("p_pfad" "text", "p_titel" "text", "p_verweis" "text", "p_ziel" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_bereich"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_bereich"("p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_bereich"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_herkunft"("p_von" "date", "p_bis" "date", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_herkunft"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_herkunft"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_je_verein"("p_von" "date", "p_bis" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_je_verein"("p_von" "date", "p_bis" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_je_verein"("p_von" "date", "p_bis" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_kennzahlen"("p_von" "date", "p_bis" "date", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_kennzahlen"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_kennzahlen"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_verteilung"("p_von" "date", "p_bis" "date", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_verteilung"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_verteilung"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."seo_ziele"("p_von" "date", "p_bis" "date", "p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seo_ziele"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seo_ziele"("p_von" "date", "p_bis" "date", "p_verein" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_registration_tenant"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_registration_tenant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_registration_tenant"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_tenant_on_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_tenant_on_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_tenant_on_insert"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_einrichtung"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_einrichtung"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_einrichtung"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_jetzt_senden"("p_beitrag" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_jetzt_senden"("p_beitrag" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_jetzt_senden"("p_beitrag" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_seite_waehlen"("p_konto_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_seite_waehlen"("p_konto_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_seite_waehlen"("p_konto_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_trennen"("p_plattform" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_trennen"("p_plattform" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_trennen"("p_plattform" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_verbinden_starten"("p_zurueck" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_verbinden_starten"("p_zurueck" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_verbinden_starten"("p_zurueck" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."social_verbindungen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."social_verbindungen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."social_verbindungen"() TO "service_role";



GRANT ALL ON FUNCTION "public"."spende_anlegen"("p_betrag" numeric, "p_waehrung" "text", "p_name" "text", "p_email" "text", "p_strasse" "text", "p_plz" "text", "p_ort" "text", "p_land" "text", "p_nachricht" "text", "p_zweck" "text", "p_anonym" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."spende_anlegen"("p_betrag" numeric, "p_waehrung" "text", "p_name" "text", "p_email" "text", "p_strasse" "text", "p_plz" "text", "p_ort" "text", "p_land" "text", "p_nachricht" "text", "p_zweck" "text", "p_anonym" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."spende_anlegen"("p_betrag" numeric, "p_waehrung" "text", "p_name" "text", "p_email" "text", "p_strasse" "text", "p_plz" "text", "p_ort" "text", "p_land" "text", "p_nachricht" "text", "p_zweck" "text", "p_anonym" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."spende_aufruf_zuordnen"("p_spende" "uuid", "p_aufruf" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."spende_bescheinigt"("p_spende" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spende_bescheinigt"("p_spende" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."spende_bescheinigt"("p_spende" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."spende_bezahlt"("p_spende" "uuid", "p_weg" "text", "p_datum" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spende_bezahlt"("p_spende" "uuid", "p_weg" "text", "p_datum" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."spende_bezahlt"("p_spende" "uuid", "p_weg" "text", "p_datum" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."spendenaufrufe_oeffentlich"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spendenaufrufe_oeffentlich"() TO "anon";
GRANT ALL ON FUNCTION "public"."spendenaufrufe_oeffentlich"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."spendenaufrufe_oeffentlich"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."spendenaufrufe_stand"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spendenaufrufe_stand"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."spendenaufrufe_stand"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."spendenseite_sichtbar"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."spendenseite_sichtbar"() TO "anon";
GRANT ALL ON FUNCTION "public"."spendenseite_sichtbar"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."spendenseite_sichtbar"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."start_tenant_support"("p_tenant" "text", "p_reason" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."start_tenant_support"("p_tenant" "text", "p_reason" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_tenant_support"("p_tenant" "text", "p_reason" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."startseite_variante"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."startseite_variante"() TO "anon";
GRANT ALL ON FUNCTION "public"."startseite_variante"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."startseite_variante"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."startseiten_vorlage"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."startseiten_vorlage"() TO "anon";
GRANT ALL ON FUNCTION "public"."startseiten_vorlage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."startseiten_vorlage"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."startseiten_vorlagen_auswahl"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."startseiten_vorlagen_auswahl"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."startseiten_vorlagen_auswahl"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_city" "text", "p_members" integer, "p_note" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_city" "text", "p_members" integer, "p_note" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_city" "text", "p_members" integer, "p_note" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_platform_lead"("p_name" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_city" "text", "p_members" integer, "p_note" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."submit_sponsor"("p_package" "text", "p_amount" numeric, "p_company" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_street" "text", "p_zip" "text", "p_city" "text", "p_country" "text", "p_website" "text", "p_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."submit_sponsor"("p_package" "text", "p_amount" numeric, "p_company" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_street" "text", "p_zip" "text", "p_city" "text", "p_country" "text", "p_website" "text", "p_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_sponsor"("p_package" "text", "p_amount" numeric, "p_company" "text", "p_contact" "text", "p_email" "text", "p_phone" "text", "p_street" "text", "p_zip" "text", "p_city" "text", "p_country" "text", "p_website" "text", "p_message" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_antwort_speichern"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_antwort_speichern"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_ausflugslisten"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_ausflugslisten"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_ausflugslisten"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_darf_anlegen"("p_gastgeber" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_darf_anlegen"("p_gastgeber" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_darf_anlegen"("p_gastgeber" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_essenszahlen"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_essenszahlen"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_essenszahlen"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_gast_antworten"("p_token" "text", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_gast_lesen"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_gast_lesen"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_gast_lesen"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_gast_lesen"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_gastgeber"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_heft"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_heft"("p_treffen" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_heft"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_heft"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_heft_inhalt"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_heft_inhalt"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_kosten"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_kosten"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_kosten"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_mein_antworten"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_mein_antworten"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_mein_antworten"("p_teilnehmer" "uuid", "p_zugesagt" boolean, "p_bemerkung" "text", "p_delegation" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_meine"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_meine"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_meine"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_namensschilder"("p_treffen" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_namensschilder"("p_treffen" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_namensschilder"("p_treffen" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_oeffentlich"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_oeffentlich"() TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_oeffentlich"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_oeffentlich"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_programm_verschieben"("p_punkt" "uuid", "p_minuten" integer, "p_alle_spuren" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_programm_verschieben"("p_punkt" "uuid", "p_minuten" integer, "p_alle_spuren" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_programm_verschieben"("p_punkt" "uuid", "p_minuten" integer, "p_alle_spuren" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_sicht"("p_teilnehmer" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_sicht"("p_teilnehmer" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_token_pruefen"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_token_pruefen"("p_token" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."treffen_token_pruefen"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."treffen_token_pruefen"("p_token" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."treffen_verrechnen"("p_treffen" "uuid", "p_faellig_in_tagen" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_verrechnen"("p_treffen" "uuid", "p_faellig_in_tagen" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_verrechnen"("p_treffen" "uuid", "p_faellig_in_tagen" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_vorstellung_links"("p_teilnehmer" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_vorstellung_links"("p_teilnehmer" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_vorstellung_links"("p_teilnehmer" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_zugang_erstellen"("p_teilnehmer" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_zugang_erstellen"("p_teilnehmer" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_zugang_erstellen"("p_teilnehmer" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."treffen_zugang_widerrufen"("p_teilnehmer" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."treffen_zugang_widerrufen"("p_teilnehmer" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."treffen_zugang_widerrufen"("p_teilnehmer" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."users_normalise_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."users_normalise_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."users_normalise_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."users_vertreter_spalten_pruefen"() TO "anon";
GRANT ALL ON FUNCTION "public"."users_vertreter_spalten_pruefen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."users_vertreter_spalten_pruefen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."verantwortliche_stand"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verantwortliche_stand"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."verantwortliche_stand"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."verein_einrichten"("p_verein" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verein_einrichten"("p_verein" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."vereins_administrator_setzen"("p_verein" "text", "p_email" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vereins_administrator_setzen"("p_verein" "text", "p_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vereins_administrator_setzen"("p_verein" "text", "p_email" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."vereinsjahr_erinnern"("p_tag" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vereinsjahr_erinnern"("p_tag" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vereinsjahr_erinnern"("p_tag" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."vereinsjahr_text"("p_schluessel" "text", "p_sprache" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."vereinsjahr_text"("p_schluessel" "text", "p_sprache" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vereinsjahr_text"("p_schluessel" "text", "p_sprache" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."vertreter_felder_gesperrt"() TO "anon";
GRANT ALL ON FUNCTION "public"."vertreter_felder_gesperrt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."vertreter_felder_gesperrt"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."vertreter_felder_setzen"("p_felder" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vertreter_felder_setzen"("p_felder" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vertreter_felder_setzen"("p_felder" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vertreter_spalten_schuetzen"() TO "anon";
GRANT ALL ON FUNCTION "public"."vertreter_spalten_schuetzen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."vertreter_spalten_schuetzen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."vorstand_schreibrecht"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vorstand_schreibrecht"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."vorstand_schreibrecht"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."vorstand_schreibrecht_setzen"("p_an" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vorstand_schreibrecht_setzen"("p_an" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vorstand_schreibrecht_setzen"("p_an" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."vorstellung_lesen"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vorstellung_lesen"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."vorstellung_lesen"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vorstellung_lesen"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vorstellung_speichern"("p_token" "text", "p_name" "text", "p_funktion" "text", "p_vorstellung" "text", "p_interessen" "text", "p_essen" "text", "p_essen_hinweis" "text", "p_im_heft" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."wer_bin_ich"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."wer_bin_ich"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."wer_bin_ich"() TO "service_role";
GRANT ALL ON FUNCTION "public"."wer_bin_ich"() TO "anon";



REVOKE ALL ON FUNCTION "public"."widersprueche_zaehlen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."widersprueche_zaehlen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."widersprueche_zaehlen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."willkommen_einreihen"("p_member" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."willkommen_einreihen"("p_member" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."willkommen_einreihen"("p_member" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."wochenstart_einreihen"("p_tag" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."wochenstart_einreihen"("p_tag" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wochenstart_einreihen"("p_tag" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlung_differenz_setzen"("p_payment" "text", "p_art" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlung_differenz_setzen"("p_payment" "text", "p_art" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlung_differenz_setzen"("p_payment" "text", "p_art" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlung_eingang_entfernen"("p_eingang" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlung_eingang_entfernen"("p_eingang" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlung_eingang_entfernen"("p_eingang" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlung_eingang_erfassen"("p_payment" "text", "p_betrag" numeric, "p_weg" "text", "p_eingang" "date", "p_notiz" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlung_eingang_erfassen"("p_payment" "text", "p_betrag" numeric, "p_weg" "text", "p_eingang" "date", "p_notiz" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlung_eingang_erfassen"("p_payment" "text", "p_betrag" numeric, "p_weg" "text", "p_eingang" "date", "p_notiz" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."zahlung_stand_pflegen"() TO "anon";
GRANT ALL ON FUNCTION "public"."zahlung_stand_pflegen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlung_stand_pflegen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlungen_verbuchen"("p_jahr" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlungen_verbuchen"("p_jahr" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlungen_verbuchen"("p_jahr" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlungsgeheimnis_setzen"("p_client_id" "text", "p_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlungsgeheimnis_setzen"("p_client_id" "text", "p_secret" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlungsgeheimnis_setzen"("p_client_id" "text", "p_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zahlungsgeheimnis_stand"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zahlungsgeheimnis_stand"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zahlungsgeheimnis_stand"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zeitplan_token_gueltig"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zeitplan_token_gueltig"("p_token" "text") TO "service_role";
























GRANT ALL ON TABLE "public"."accounting_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."accounting_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."accounting_journal" TO "authenticated";
GRANT ALL ON TABLE "public"."accounting_journal" TO "service_role";



GRANT ALL ON TABLE "public"."accounting_journal_archiv" TO "service_role";



GRANT ALL ON TABLE "public"."admin_emails" TO "service_role";



GRANT ALL ON TABLE "public"."board_meeting_versions" TO "service_role";
GRANT SELECT ON TABLE "public"."board_meeting_versions" TO "authenticated";



GRANT ALL ON TABLE "public"."board_meetings" TO "authenticated";
GRANT ALL ON TABLE "public"."board_meetings" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."board_members" TO "anon";
GRANT ALL ON TABLE "public"."board_members" TO "authenticated";
GRANT ALL ON TABLE "public"."board_members" TO "service_role";



GRANT ALL ON TABLE "public"."buchungsprotokoll" TO "service_role";
GRANT SELECT ON TABLE "public"."buchungsprotokoll" TO "authenticated";



GRANT ALL ON TABLE "public"."donations" TO "authenticated";
GRANT ALL ON TABLE "public"."donations" TO "service_role";



GRANT ALL ON TABLE "public"."event_registrations" TO "authenticated";
GRANT ALL ON TABLE "public"."event_registrations" TO "service_role";
GRANT INSERT ON TABLE "public"."event_registrations" TO "anon";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses" TO "service_role";



GRANT ALL ON TABLE "public"."families" TO "authenticated";
GRANT ALL ON TABLE "public"."families" TO "service_role";



GRANT ALL ON TABLE "public"."family_links" TO "authenticated";
GRANT ALL ON TABLE "public"."family_links" TO "service_role";



GRANT ALL ON TABLE "public"."fiscal_budgets" TO "authenticated";
GRANT ALL ON TABLE "public"."fiscal_budgets" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."fiscal_years" TO "anon";
GRANT ALL ON TABLE "public"."fiscal_years" TO "authenticated";
GRANT ALL ON TABLE "public"."fiscal_years" TO "service_role";



GRANT ALL ON TABLE "public"."floky_einstellungen" TO "authenticated";
GRANT ALL ON TABLE "public"."floky_einstellungen" TO "service_role";



GRANT ALL ON TABLE "public"."floky_gespraeche" TO "authenticated";
GRANT ALL ON TABLE "public"."floky_gespraeche" TO "service_role";



GRANT ALL ON TABLE "public"."floky_nachrichten" TO "authenticated";
GRANT ALL ON TABLE "public"."floky_nachrichten" TO "service_role";



GRANT ALL ON TABLE "public"."floky_protokoll" TO "authenticated";
GRANT ALL ON TABLE "public"."floky_protokoll" TO "service_role";



GRANT ALL ON TABLE "public"."floky_verbrauch" TO "authenticated";
GRANT ALL ON TABLE "public"."floky_verbrauch" TO "service_role";



GRANT ALL ON TABLE "public"."glossar" TO "authenticated";
GRANT ALL ON TABLE "public"."glossar" TO "service_role";



GRANT ALL ON TABLE "public"."inquiries" TO "authenticated";
GRANT ALL ON TABLE "public"."inquiries" TO "service_role";



GRANT ALL ON TABLE "public"."mail_domain_weg" TO "authenticated";
GRANT ALL ON TABLE "public"."mail_domain_weg" TO "service_role";



GRANT ALL ON TABLE "public"."mail_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."mail_queue" TO "service_role";



GRANT ALL ON TABLE "public"."mail_settings" TO "service_role";



GRANT ALL ON TABLE "public"."mitglied_meldungen" TO "authenticated";
GRANT ALL ON TABLE "public"."mitglied_meldungen" TO "service_role";



GRANT ALL ON TABLE "public"."modules" TO "authenticated";
GRANT ALL ON TABLE "public"."modules" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."neighborhoods" TO "anon";
GRANT ALL ON TABLE "public"."neighborhoods" TO "authenticated";
GRANT ALL ON TABLE "public"."neighborhoods" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."news" TO "anon";
GRANT ALL ON TABLE "public"."news" TO "authenticated";
GRANT ALL ON TABLE "public"."news" TO "service_role";



GRANT ALL ON TABLE "public"."payment_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_reports" TO "service_role";



GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT ALL ON TABLE "public"."platform_admins" TO "service_role";



GRANT ALL ON TABLE "public"."platform_invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_invoices" TO "service_role";



GRANT ALL ON TABLE "public"."platform_leads" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_leads" TO "service_role";



GRANT ALL ON TABLE "public"."platform_secrets" TO "service_role";



GRANT ALL ON TABLE "public"."platform_support" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_support" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."polls" TO "anon";
GRANT ALL ON TABLE "public"."polls" TO "authenticated";
GRANT ALL ON TABLE "public"."polls" TO "service_role";



GRANT ALL ON TABLE "public"."post_ausgang" TO "service_role";



GRANT ALL ON TABLE "public"."post_kontingent" TO "service_role";



GRANT ALL ON TABLE "public"."post_preise" TO "service_role";



GRANT ALL ON TABLE "public"."postausgang_zustand" TO "authenticated";
GRANT ALL ON TABLE "public"."postausgang_zustand" TO "service_role";



GRANT ALL ON TABLE "public"."pruefstand_referenzen" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."public_members" TO "anon";
GRANT SELECT,MAINTAIN ON TABLE "public"."public_members" TO "authenticated";
GRANT ALL ON TABLE "public"."public_members" TO "service_role";



GRANT ALL ON TABLE "public"."settings" TO "authenticated";
GRANT ALL ON TABLE "public"."settings" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."public_settings" TO "anon";
GRANT SELECT,MAINTAIN ON TABLE "public"."public_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."public_settings" TO "service_role";



GRANT ALL ON TABLE "public"."tenant_domains" TO "service_role";



GRANT ALL ON TABLE "public"."tenants" TO "authenticated";
GRANT ALL ON TABLE "public"."tenants" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."public_tenant_domains" TO "anon";
GRANT SELECT,MAINTAIN ON TABLE "public"."public_tenant_domains" TO "authenticated";
GRANT ALL ON TABLE "public"."public_tenant_domains" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."public_tenants" TO "anon";
GRANT SELECT,MAINTAIN ON TABLE "public"."public_tenants" TO "authenticated";
GRANT ALL ON TABLE "public"."public_tenants" TO "service_role";



GRANT ALL ON TABLE "public"."revisionszugaenge" TO "service_role";
GRANT SELECT ON TABLE "public"."revisionszugaenge" TO "authenticated";



GRANT ALL ON TABLE "public"."security_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."security_logs" TO "service_role";



GRANT ALL ON TABLE "public"."seiten" TO "authenticated";
GRANT ALL ON TABLE "public"."seiten" TO "service_role";
GRANT SELECT ON TABLE "public"."seiten" TO "anon";



GRANT ALL ON TABLE "public"."seitenaufrufe" TO "service_role";



GRANT ALL ON TABLE "public"."settings_archiv" TO "service_role";



GRANT ALL ON TABLE "public"."social_connections" TO "service_role";



GRANT ALL ON TABLE "public"."social_oauth_state" TO "service_role";



GRANT ALL ON TABLE "public"."socialmediaposts" TO "authenticated";
GRANT ALL ON TABLE "public"."socialmediaposts" TO "service_role";



GRANT ALL ON SEQUENCE "public"."spenden_nummer" TO "anon";
GRANT ALL ON SEQUENCE "public"."spenden_nummer" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."spenden_nummer" TO "service_role";



GRANT ALL ON TABLE "public"."spendenaufrufe" TO "service_role";
GRANT SELECT ON TABLE "public"."spendenaufrufe" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."spendenaufrufe" TO "authenticated";



GRANT ALL ON TABLE "public"."sponsors" TO "authenticated";
GRANT ALL ON TABLE "public"."sponsors" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."startseiten_vorlagen" TO "anon";
GRANT ALL ON TABLE "public"."startseiten_vorlagen" TO "authenticated";
GRANT ALL ON TABLE "public"."startseiten_vorlagen" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."tenant_modules" TO "authenticated";
GRANT ALL ON TABLE "public"."tenant_modules" TO "service_role";



GRANT ALL ON TABLE "public"."textbausteine" TO "authenticated";
GRANT ALL ON TABLE "public"."textbausteine" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."treffen" TO "anon";
GRANT ALL ON TABLE "public"."treffen" TO "authenticated";
GRANT ALL ON TABLE "public"."treffen" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."treffen_ausflug_anmeldung" TO "anon";
GRANT ALL ON TABLE "public"."treffen_ausflug_anmeldung" TO "authenticated";
GRANT ALL ON TABLE "public"."treffen_ausflug_anmeldung" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."treffen_delegation" TO "anon";
GRANT ALL ON TABLE "public"."treffen_delegation" TO "authenticated";
GRANT ALL ON TABLE "public"."treffen_delegation" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."treffen_programm" TO "anon";
GRANT ALL ON TABLE "public"."treffen_programm" TO "authenticated";
GRANT ALL ON TABLE "public"."treffen_programm" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."treffen_teilnehmer" TO "anon";
GRANT ALL ON TABLE "public"."treffen_teilnehmer" TO "authenticated";
GRANT ALL ON TABLE "public"."treffen_teilnehmer" TO "service_role";



GRANT ALL ON TABLE "public"."vereinsjahr" TO "authenticated";
GRANT ALL ON TABLE "public"."vereinsjahr" TO "service_role";



GRANT ALL ON TABLE "public"."versand_herkunft" TO "service_role";
GRANT SELECT ON TABLE "public"."versand_herkunft" TO "authenticated";



GRANT ALL ON TABLE "public"."videos" TO "service_role";
GRANT SELECT ON TABLE "public"."videos" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."videos" TO "authenticated";



GRANT ALL ON TABLE "public"."zaehler_salz" TO "service_role";



GRANT ALL ON TABLE "public"."zahlungseingaenge" TO "service_role";
GRANT SELECT ON TABLE "public"."zahlungseingaenge" TO "authenticated";



GRANT ALL ON TABLE "public"."zahlungsgeheimnisse" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































