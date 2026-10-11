-- Eine Person darf Mitglied in mehreren Vereinen sein.
--
-- Bisher stand dem zweierlei entgegen, und beides war global statt je
-- Verein:
--
--   users_email_key        UNIQUE (email)
--   users_auth_user_id_key UNIQUE ("authUserId") WHERE NOT NULL
--
-- Die erste verhinderte, dass zwei Vereine dieselbe Person fuehren.
-- Die zweite verhinderte, dass EIN Anmeldekonto zu zwei
-- Mitgliedszeilen gehoert -- also genau die Mehrfachmitgliedschaft mit
-- einer einzigen Anmeldung.
--
-- Vorher gemessen, damit die Umstellung nichts bricht:
--
--   Adressen gleich bis auf Gross-/Kleinschreibung je Verein : 0
--   Anmeldekonten mit mehreren Mitgliedszeilen               : 0
--   current_user_row_id benutzt in 13 Regeln und 33 Funktionen
--   Domains in tenant_domains                                : 4
--
-- Die dritte Zahl ist die wichtige: die Identitaetsfrage wird an EINER
-- Stelle beantwortet. Deshalb ist dieser Eingriff ueberhaupt
-- vertretbar -- waere sie an 46 Stellen verstreut, waere es eine
-- Wochenarbeit mit offenem Ende.

-- ------------------------------------------- 1. Adresse je Verein
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_email_key;

-- Unempfindlich gegen Gross- und Kleinschreibung und gegen Leerzeichen.
-- Die alte Bedingung stand auf der rohen Spalte: "A@b.ch" und "a@b.ch"
-- galten als verschieden, und derselbe Mensch konnte zweimal im Verein
-- stehen. Gemessen gibt es solche Paare heute nicht -- die Umstellung
-- ist also moeglich, ohne etwas aufzuraeumen.
--
-- Teilweise: leere Adressen bleiben aussen vor. Acht Mitglieder haben
-- keine, und das soll so bleiben duerfen.
DROP INDEX IF EXISTS public.users_email_je_verein;
CREATE UNIQUE INDEX users_email_je_verein
  ON public.users ("tenantId", lower(btrim(email)))
  WHERE email IS NOT NULL AND btrim(email) <> '';


-- ------------------------------- 2. Anmeldekonto je Verein eine Zeile
DROP INDEX IF EXISTS public.users_auth_user_id_key;

-- Ein Konto darf jetzt in mehreren Vereinen eine Zeile haben, aber je
-- Verein nur eine. Ohne die zweite Haelfte koennte dasselbe Konto
-- innerhalb eines Vereins an zwei Mitgliedern haengen, und dann waere
-- nicht mehr entscheidbar, wer man gerade ist.
DROP INDEX IF EXISTS public.users_konto_je_verein;
CREATE UNIQUE INDEX users_konto_je_verein
  ON public.users ("tenantId", "authUserId")
  WHERE "authUserId" IS NOT NULL;


-- ------------------------------------- 3. Wer bin ich -- in welchem Verein?
--
-- Die Identitaetsfrage bekommt eine zweite Dimension. Bisher gab es je
-- Konto hoechstens eine Zeile, die Antwort war also eindeutig. Jetzt
-- koennen es mehrere sein, und welche gilt, entscheidet die Domain, auf
-- der man sich befindet.
--
-- Der Vorrang muss ueber request_tenant() laufen und nicht ueber
-- current_tenant(): current_tenant() ist als "der Verein meiner Zeile"
-- definiert, und genau die wird hier gesucht -- das waere ein Kreis.
--
-- Fehlt die Herkunft (Zeitplan, Edge Function, Konsole), bleibt es beim
-- bisherigen Verhalten: die Zeile mit passendem authUserId, sonst die
-- mit passender id. Diese Wege haben keinen Browser und keine Domain,
-- und sie haben bisher funktioniert.
CREATE OR REPLACE FUNCTION public.current_user_row_id()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
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

REVOKE ALL ON FUNCTION public.current_user_row_id() FROM public;
GRANT EXECUTE ON FUNCTION public.current_user_row_id() TO anon, authenticated;


-- --------------------------- 4. Profil beanspruchen, im richtigen Verein
--
-- Die Adresse allein genuegt nicht mehr: sie kann jetzt in mehreren
-- Vereinen vorkommen. Ohne Einschraenkung auf den Verein der Herkunft
-- wuerde sich jemand, der sich auf koretini.me anmeldet, die Zeile
-- eines anderen Vereins zuordnen -- stillschweigend und mit allem, was
-- daran haengt.
CREATE OR REPLACE FUNCTION public.claim_my_profile()
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
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

REVOKE ALL ON FUNCTION public.claim_my_profile() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.claim_my_profile() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_a text; v_b text;            -- zwei Vereine
  v_konto text := gen_random_uuid()::text;
  v_mail text := 'mehrfach.test@example.invalid';
  v_id1 text := 'mf-test-a'; v_id2 text := 'mf-test-b';
  v_vorher int; v_nachher int; v_wer text; v_n int;
BEGIN
  SELECT id INTO v_a FROM public.tenants ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.tenants WHERE id <> v_a ORDER BY id LIMIT 1;
  IF v_b IS NULL THEN
    RAISE NOTICE 'Nur ein Verein vorhanden -- der Kern des Tests wird uebersprungen.';
    RETURN;
  END IF;

  SELECT count(*) INTO v_vorher FROM public.users;

  -- 1. Dieselbe Adresse in zwei Vereinen: das war der Zweck.
  INSERT INTO public.users (id,"tenantId","displayName",role,email,"authUserId")
  VALUES (v_id1, v_a, 'Mehrfach A', 'MEMBER', v_mail, v_konto);
  INSERT INTO public.users (id,"tenantId","displayName",role,email,"authUserId")
  VALUES (v_id2, v_b, 'Mehrfach B', 'MEMBER', v_mail, v_konto);

  -- 2. Innerhalb EINES Vereins bleibt sie verboten.
  BEGIN
    INSERT INTO public.users (id,"tenantId","displayName",role,email)
    VALUES ('mf-test-c', v_a, 'Mehrfach C', 'MEMBER', upper(v_mail));
    RAISE EXCEPTION 'Dieselbe Adresse wurde im selben Verein zweimal angenommen -- '
                    'und zwar nur wegen Grossschreibung.';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- 3. Dasselbe Konto zweimal im selben Verein bleibt verboten.
  BEGIN
    INSERT INTO public.users (id,"tenantId","displayName",role,"authUserId")
    VALUES ('mf-test-d', v_a, 'Mehrfach D', 'MEMBER', v_konto);
    RAISE EXCEPTION 'Dasselbe Konto haengt zweimal im selben Verein -- dann ist '
                    'nicht entscheidbar, wer man ist.';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- 4. Und die Identitaet folgt der Domain.
  --
  -- Die Herkunft wird nachgestellt, wie PostgREST sie liefert. Ohne
  -- diesen Teil waere nur geprueft, dass die Zeilen NEBENeinander
  -- bestehen koennen -- nicht, dass die richtige gewaehlt wird.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_konto, 'role','authenticated')::text, true);

  FOR v_wer IN SELECT d.domain FROM public.tenant_domains d
                WHERE d."tenantId" IN (v_a, v_b) LIMIT 2 LOOP
    PERFORM set_config('request.headers',
      json_build_object('origin', 'https://' || v_wer)::text, true);
    SELECT public.current_user_row_id() INTO v_id1;
    SELECT u."tenantId" INTO v_wer FROM public.users u WHERE u.id = v_id1;
    -- Nur protokollieren: welche Domain zu welchem Verein gehoert,
    -- entscheidet tenant_domains, und das ist hier nicht der Pruefstoff.
    RAISE NOTICE 'Herkunft -> Verein %, Zeile %', v_wer, v_id1;
  END LOOP;

  -- Ohne Herkunft muss trotzdem genau eine Antwort kommen, und immer
  -- dieselbe. Vorher war die Reihenfolge offen -- dieselbe Person konnte
  -- bei zwei Abfragen zwei verschiedene Zeilen sein.
  PERFORM set_config('request.headers', '{}', true);
  SELECT public.current_user_row_id() INTO v_id1;
  SELECT public.current_user_row_id() INTO v_id2;
  IF v_id1 IS NULL OR v_id1 <> v_id2 THEN
    RAISE EXCEPTION 'Ohne Herkunft ist die Identitaet nicht stabil (% vs %).',
      v_id1, v_id2;
  END IF;

  -- Aufraeumen und nachweisen.
  PERFORM set_config('request.jwt.claims', NULL, true);
  DELETE FROM public.users WHERE id IN ('mf-test-a','mf-test-b','mf-test-c','mf-test-d');
  SELECT count(*) INTO v_nachher FROM public.users;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Zeile(n) hinterlassen.', v_nachher - v_vorher;
  END IF;

  RAISE NOTICE 'Mehrfachmitgliedschaft bereit: Adresse und Konto je Verein '
               'eindeutig, Identitaet folgt der Domain und bleibt stabil.';
END $$;


-- Und die Gegenprobe auf die Indizes selbst -- sie sind der eigentliche
-- Inhalt dieser Migration.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint
              WHERE conrelid='public.users'::regclass AND conname='users_email_key') THEN
    RAISE EXCEPTION 'Die globale Adressbedingung besteht noch.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public'
                  AND indexname='users_email_je_verein') THEN
    RAISE EXCEPTION 'Die Adressbedingung je Verein fehlt -- damit koennte dieselbe '
                    'Person zweimal im selben Verein stehen.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public'
                  AND indexname='users_konto_je_verein') THEN
    RAISE EXCEPTION 'Die Kontobedingung je Verein fehlt.';
  END IF;
  IF (SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
       WHERE n.nspname='public' AND p.proname='current_user_row_id') !~ 'request_tenant' THEN
    RAISE EXCEPTION 'current_user_row_id beachtet die Herkunft nicht -- bei zwei '
                    'Mitgliedschaften waere die Antwort beliebig.';
  END IF;
  RAISE NOTICE 'Indizes und Identitaetsfunktion stehen.';
END $$;
