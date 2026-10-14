-- Jede Selbstzuordnung war blockiert -- von meinem eigenen Ausloeser.
--
-- Gemeldet: wer sich neu anmeldet oder das Passwort aendert, kommt nicht
-- herein. Gemessen, in seinem Namen:
--
--   claim_my_profile()
--   -> FEHLER: Als Verantwortlicher einer Nachbarschaft koennen Sie
--      diese Felder nicht aendern: authUserId
--
-- Die Kette:
--
--   claim_my_profile setzt users.authUserId -- das ist ihre ganze
--   Aufgabe: ein Anmeldekonto mit der vorhandenen Mitgliedszeile
--   verbinden.
--
--   Der Ausloeser users_vertreter_spalten (aus
--   20261014000000_vertreterrechte_einstellbar) laesst einem
--   Nachbarschaftsverantwortlichen nur die freigegebenen Felder durch.
--   authUserId steht in vertreter_felder_gesperrt(), und das ist
--   richtig: wer fremde Konten umhaengen kann, uebernimmt Identitaeten.
--
--   Der Ausloeser hat eine Ausnahme fuer die eigene Zeile:
--     IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW
--   Sie greift hier aber NICHT, weil v_ich aus current_user_row_id()
--   kommt -- und das findet nichts, solange die Verbindung fehlt. Genau
--   die soll ja erst entstehen.
--
-- Also: jede Selbstzuordnung scheitert, seit dem 14.10. Betroffen ist
-- jeder, der sich erstmals anmeldet. Gemessen sind es drei echte
-- Personen; eine davon (Rolle MEMBER) haette sich verbinden koennen und
-- konnte es nicht.
--
-- Der Ausloeser bleibt. Dazu kommt eine zweite Ausnahme, und zwar eine
-- enge: das Anziehen des EIGENEN Kontos an eine Zeile, die noch keines
-- hat. Beides muss stimmen --
--
--   OLD."authUserId" IS NULL      die Zeile ist noch unverbunden
--   NEW."authUserId" = auth.uid() es ist MEIN Konto, kein fremdes
--
-- Damit kann niemand ein fremdes Konto anhaengen und niemand eine
-- bestehende Verbindung umbiegen. Und es bleibt bei genau diesem Feld:
-- aendert derselbe Vorgang noch etwas anderes Gesperrtes, greift die
-- Pruefung weiter.

CREATE OR REPLACE FUNCTION public.users_vertreter_spalten_pruefen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
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

-- Den Ausloeser auf die neue Fassung zeigen lassen. Der Name der
-- Funktion kann vom Namen des Ausloesers abweichen -- darum beides
-- ausdruecklich.
DO $$
DECLARE v_fn text;
BEGIN
  SELECT p.proname INTO v_fn
    FROM pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid
   WHERE t.tgrelid = 'public.users'::regclass AND t.tgname = 'users_vertreter_spalten';
  IF v_fn IS NULL THEN
    RAISE EXCEPTION 'Der Ausloeser users_vertreter_spalten fehlt.';
  END IF;
  IF v_fn <> 'users_vertreter_spalten_pruefen' THEN
    -- Die alte Funktion hiess anders; den Ausloeser neu haengen.
    EXECUTE 'DROP TRIGGER users_vertreter_spalten ON public.users';
    EXECUTE 'CREATE TRIGGER users_vertreter_spalten BEFORE UPDATE ON public.users '
         || 'FOR EACH ROW EXECUTE FUNCTION public.users_vertreter_spalten_pruefen()';
    RAISE NOTICE 'Ausloeser von % auf users_vertreter_spalten_pruefen umgehaengt', v_fn;
  END IF;
END $$;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_verein text; v_konto text := gen_random_uuid()::text;
  v_zeile text := 'selbsttest-zuordnung';
  v_fremd text := 'selbsttest-fremd';
  v_vorher int; v_nachher int; v_id text; v_zeilen int;
BEGIN
  SELECT id INTO v_verein FROM public.tenants ORDER BY id LIMIT 1;
  SELECT count(*) INTO v_vorher FROM public.users;

  -- Eine unverbundene Zeile mit einer Adresse, und eine fremde.
  INSERT INTO public.users (id,"tenantId","displayName",role,email)
  VALUES (v_zeile, v_verein, 'Selbsttest Zuordnung', 'MEMBER', 'zuordnung@example.invalid');
  INSERT INTO public.users (id,"tenantId","displayName",role,email,"authUserId")
  VALUES (v_fremd, v_verein, 'Selbsttest Fremd', 'MEMBER', 'fremd@example.invalid',
          gen_random_uuid()::text);

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_konto, 'email','zuordnung@example.invalid',
                      'role','authenticated')::text, true);
  PERFORM set_config('role','authenticated', true);

  -- 1. Die eigene Zuordnung muss gehen. Das ist der behobene Fall.
  v_id := public.claim_my_profile();
  IF v_id IS DISTINCT FROM v_zeile THEN
    RAISE EXCEPTION 'Die Selbstzuordnung scheitert weiterhin (Ergebnis %).', v_id;
  END IF;

  -- 2. Ein zweiter Versuch darf keine zweite Zeile anziehen.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid()::text, 'email','zuordnung@example.invalid',
                      'role','authenticated')::text, true);
  v_id := public.claim_my_profile();
  IF v_id IS NOT NULL THEN
    RAISE EXCEPTION 'Eine bereits verbundene Zeile liess sich erneut beanspruchen (%).', v_id;
  END IF;

  -- 3. Eine FREMDE Verbindung darf sich nicht umbiegen lassen.
  --
  -- Geprueft wird AUSDRUECKLICH die Wirkung und nicht nur das Fehlen
  -- einer Ausnahme. Mein erster Versuch sah nur nach, ob es wirft -- und
  -- meldete ein Loch, das keines war: die Zeilenregel weist den fremden
  -- Satz still ab, mit null Zeilen und ohne Fehler. Ein Test, der ein
  -- stilles Nichts fuer Erfolg nimmt, laeuft in beide Richtungen falsch.
  BEGIN
    UPDATE public.users SET "authUserId" = auth.uid()::text WHERE id = v_fremd;
    GET DIAGNOSTICS v_zeilen = ROW_COUNT;
    IF v_zeilen > 0 THEN
      RAISE EXCEPTION 'Eine fremde Kontoverbindung liess sich umbiegen (% Zeile) -- '
                      'die Ausnahme ist zu weit.', v_zeilen;
    END IF;
  EXCEPTION WHEN insufficient_privilege THEN NULL;
       WHEN unique_violation THEN NULL;
  END;

  -- 4. Und bei der Gelegenheit die Rolle zu heben, bleibt verboten.
  BEGIN
    UPDATE public.users SET "authUserId" = auth.uid()::text, role = 'ADMIN'
     WHERE id = v_fremd;
    GET DIAGNOSTICS v_zeilen = ROW_COUNT;
    IF v_zeilen > 0 THEN
      RAISE EXCEPTION 'Rolle und Konto liessen sich zusammen aendern (% Zeile).', v_zeilen;
    END IF;
  EXCEPTION WHEN insufficient_privilege THEN NULL;
       WHEN unique_violation THEN NULL;
  END;

  -- 5. Die Gegenprobe zur Gegenprobe: dass der fremde Satz UNVERAENDERT
  --    dasteht. Ohne diesen Schritt koennte Schritt 3 auch dann
  --    schweigen, wenn die Zeile gar nicht existiert.
  --
  -- Und zwar MIT den Rechten der Tabelle, nicht mit denen des
  -- Testkontos. Mein erster Versuch las als authenticated -- und die
  -- Zeilenregel zeigt dem Testkonto den fremden Satz gar nicht. Die
  -- Pruefung meldete darum eine Aenderung, wo nur Unsichtbarkeit war.
  -- Zweimal hintereinander derselbe Fehler in derselben Pruefung: ein
  -- Blick durch die Zeilenregel beantwortet keine Frage ueber die
  -- Tabelle.
  PERFORM set_config('role','postgres', true);
  IF NOT EXISTS (SELECT 1 FROM public.users
                  WHERE id = v_fremd AND "authUserId" IS NOT NULL
                    AND "authUserId" <> v_konto) THEN
    RAISE EXCEPTION 'Der fremde Satz steht nicht mehr unveraendert da.';
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, true);
  DELETE FROM public.users WHERE id IN (v_zeile, v_fremd);
  SELECT count(*) INTO v_nachher FROM public.users;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Zeile(n) hinterlassen.', v_nachher - v_vorher;
  END IF;

  RAISE NOTICE 'Selbstzuordnung geht wieder; fremde Konten und die Rolle bleiben gesperrt.';
END $$;
