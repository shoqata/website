-- Postausgang des Vorstands: auch an Externe, mit Kopie (CC).
--
-- Bisher gingen Briefe nur an Mitglieder des Vereins. Der Vorstand schreibt
-- aber auch an Gemeinde, Vermieter, Sponsoren -- bisher aus dem privaten
-- Postfach, mit der privaten Adresse als Absender. Jetzt:
--
--   p_extern  bis zu 10 Adressen ausserhalb des Vereins
--   p_cc      bis zu 5 Adressen in Kopie
--   p_kopie   die eigene Antwortadresse in Kopie -- bei einer bestaetigten
--             Vorstandsadresse landet die Kopie ueber deren Weiterleitung
--             im eigenen Postfach
--
-- CC nur bei hoechstens 10 Empfaengern: jeder Brief geht einzeln hinaus,
-- und eine Kopie an jedem Brief eines Rundschreibens an 300 Mitglieder
-- waeren 300 Kopien.
--
-- Die Grenzen sind keine Kosmetik. Externe Empfaenger machen den
-- Postausgang zu einem Weg, unter dem Namen des Vereins an beliebige
-- Adressen zu schreiben; darum wenige auf einmal, und alles zaehlt auf die
-- Tagesgrenze.

ALTER TABLE public.mail_queue ADD COLUMN IF NOT EXISTS cc text[];

DROP FUNCTION IF EXISTS public.vorstand_mail_einreihen(text[], text, text, text);

CREATE OR REPLACE FUNCTION public.vorstand_mail_einreihen(
  p_mitglieder text[], p_betreff text, p_html text, p_text text DEFAULT NULL,
  p_extern text[] DEFAULT NULL, p_cc text[] DEFAULT NULL, p_kopie boolean DEFAULT false)
RETURNS jsonb
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
  v_muster constant text := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
  v_extern text[];
  v_cc text[];
  v_anzahl int;
  v_falsch text;
  r record;
BEGIN
  -- Schreibentzug des Vorstands. SECURITY DEFINER umgeht die
  -- Zeilenregeln, deshalb steht die Pruefung hier und nicht nur dort.
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

  -- Externe und Kopien: gesaeubert, ohne Doppel, nur echte Adressen.
  SELECT array_agg(DISTINCT lower(btrim(a))) INTO v_extern
    FROM unnest(coalesce(p_extern, '{}')) a WHERE btrim(a) <> '';
  SELECT array_agg(DISTINCT lower(btrim(a))) INTO v_cc
    FROM unnest(coalesce(p_cc, '{}')) a WHERE btrim(a) <> '';
  SELECT string_agg(a, ', ') INTO v_falsch
    FROM unnest(coalesce(v_extern, '{}') || coalesce(v_cc, '{}')) a WHERE a !~ v_muster;
  IF v_falsch IS NOT NULL THEN
    RAISE EXCEPTION 'Keine gültige Adresse: %', v_falsch USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(array_length(v_extern, 1), 0) > 10 THEN
    RAISE EXCEPTION 'An höchstens 10 externe Adressen auf einmal.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(array_length(v_cc, 1), 0) > 5 THEN
    RAISE EXCEPTION 'Höchstens 5 Adressen in Kopie.' USING ERRCODE = 'check_violation';
  END IF;

  v_anzahl := coalesce(array_length(p_mitglieder, 1), 0) + coalesce(array_length(v_extern, 1), 0);
  IF v_anzahl = 0 THEN
    RAISE EXCEPTION 'Es ist niemand ausgewaehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_anzahl > 2000 THEN
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

  IF p_kopie AND coalesce(btrim(v_antwort), '') <> '' THEN
    v_cc := array(SELECT DISTINCT x FROM unnest(coalesce(v_cc, '{}') || lower(btrim(v_antwort))) x);
  END IF;
  IF coalesce(array_length(v_cc, 1), 0) > 0 AND v_anzahl > 10 THEN
    RAISE EXCEPTION 'Kopie (CC) geht nur bei höchstens 10 Empfängern. Jeder Brief geht einzeln hinaus — bei % Empfängern wären es % Kopien.',
      v_anzahl, v_anzahl USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(array_length(v_cc, 1), 0) = 0 THEN v_cc := NULL; END IF;

  SELECT t.name INTO v_vereinsname FROM public.tenants t WHERE t.id = v_verein;

  -- Die Tagesgrenze. Was heute nicht mehr hineingeht, wird auf die
  -- Folgetage verteilt und NICHT verworfen.
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
    SELECT * FROM (
      SELECT 0 AS sorte, u.id, u.email
        FROM public.users u
       WHERE u.id = ANY (coalesce(p_mitglieder, '{}'))
         -- Nur eigene Mitglieder. Eine fremde Id trifft hier auf keine Zeile.
         AND u."tenantId" = v_verein
         AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
      UNION ALL
      SELECT 1, NULL::text, e FROM unnest(coalesce(v_extern, '{}')) e
    ) x ORDER BY sorte, id NULLS LAST, email
  LOOP
    IF coalesce(btrim(r.email),'') = '' OR position('@' in r.email) = 0 THEN
      v_ohne := v_ohne + 1;
      CONTINUE;
    END IF;
    IF EXISTS (SELECT 1 FROM public.mail_queue q
                WHERE q."tenantId" = v_verein AND q.status = 'PENDING'
                  AND q.kind = 'VORSTAND' AND lower(q.recipient) = lower(r.email)
                  AND q.subject = p_betreff) THEN
      v_doppelt := v_doppelt + 1;
      CONTINUE;
    END IF;

    WHILE v_frei <= 0 LOOP
      v_tag := v_tag + 1;
      v_frei := v_pro_tag;
    END LOOP;

    INSERT INTO public.mail_queue
      ("tenantId", recipient, subject, html, text, kind, "memberId",
       antwort_an, absender_name, absender_id, status, "scheduledFor", cc)
    VALUES (v_verein, r.email, p_betreff, p_html,
            coalesce(p_text, regexp_replace(p_html, '<[^>]*>', '', 'g')),
            'VORSTAND', r.id,
            v_antwort,
            case when coalesce(v_vereinsname,'') = '' then v_name
                 else v_name || ' · ' || v_vereinsname end,
            v_ich, 'PENDING',
            case when v_tag = current_date then now()
                 else v_tag::timestamptz + interval '8 hours' end,
            -- Die Kopie nie an den Empfaenger selbst.
            nullif(array(SELECT c FROM unnest(coalesce(v_cc, '{}')) c WHERE c <> lower(r.email)), '{}'));
    v_frei := v_frei - 1;
    IF v_tag = current_date THEN v_heute := v_heute + 1;
                            ELSE v_spaeter := v_spaeter + 1; END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'eingereiht', v_heute + v_spaeter,
    'heute', v_heute,
    'spaeter', v_spaeter,
    'fertig_am', v_tag,
    'ohne_adresse', v_ohne,
    'schon_offen', v_doppelt,
    'grenze_verein', v_grenze ->> 'grenze_verein',
    'grenze_person', v_grenze ->> 'grenze_person',
    'antwort_an', v_antwort,
    'cc', to_jsonb(v_cc),
    'absender', v_name);
END $$;
REVOKE ALL ON FUNCTION public.vorstand_mail_einreihen(text[], text, text, text, text[], text[], boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.vorstand_mail_einreihen(text[], text, text, text, text[], text[], boolean) TO authenticated;

-- Selbsttest als Vorstand im Demoverein, zurueckgerollt.
DO $$
DECLARE v_eigen text := current_user; v_auth text; r jsonb; v_cc text[]; v_mem text; v_ok boolean;
BEGIN
  SELECT "authUserId" INTO v_auth FROM public.users WHERE id = 'demo-u02';
  IF v_auth IS NULL THEN RAISE NOTICE 'Selbsttest uebersprungen.'; RETURN; END IF;
  BEGIN
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_auth, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    r := public.vorstand_mail_einreihen(NULL, 'Selbsttest extern', '<p>x</p>', NULL,
           ARRAY['Gemeinde@Example.org'], ARRAY['kopie@example.org'], true);
    v_ok := false;
    BEGIN PERFORM public.vorstand_mail_einreihen(NULL, 'Selbsttest', '<p>x</p>', NULL, ARRAY['kein-at']);
    EXCEPTION WHEN check_violation THEN v_ok := true; END;
    EXECUTE format('SET LOCAL ROLE %I', v_eigen);
    SELECT cc, "memberId" INTO v_cc, v_mem FROM public.mail_queue
     WHERE subject = 'Selbsttest extern' AND recipient = 'gemeinde@example.org';
    IF (r ->> 'eingereiht')::int <> 1 OR v_cc IS NULL OR NOT ('kopie@example.org' = ANY (v_cc))
       OR array_length(v_cc, 1) <> 2 OR v_mem IS NOT NULL OR NOT v_ok THEN
      RAISE EXCEPTION 'Selbsttest: % / cc % / Mitglied % / Pruefung %', r, v_cc, v_mem, v_ok;
    END IF;
    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
END $$;
