-- Die fuenf Vereinsadressen des Vorstands von Koretini.
--
-- Geliefert wurde eine Liste "Vereinsadresse -> privat". Beim Nachsehen
-- zeigte sich: die Ziele sind GENAU die Adressen, die in users schon
-- stehen --
--
--   Valton Rexha      valton.rexha@gmail.com
--   Sokol Axhija      axhija.sokol@gmail.com
--   Gazmend Mehmeti   gazmend.mehmeti@multinetcom.ch
--   Ismet Klaiqi      Ismetklaiqi6@gmail.com
--   Bajram Shillova   shillovabajram@gmail.com
--
-- Darum werden die Eintraege hier angelegt und nicht von Hand eingefuegt.
-- Die Zuordnung geschieht ueber die ID, nicht ueber den Namen: ein Name
-- laesst sich aendern, und eine Absenderidentitaet, die danach auf eine
-- andere Person zeigt, waere der schlimmste Fall.
--
-- WAS DAMIT NOCH NICHT GESCHIEHT: die Weiterleitung. Die richtet der
-- Mailhost der Domain ein. Hier stehen nur die Adressen -- sie wirken
-- sofort als ANTWORTADRESSE in Vorstandsnachrichten, aber eingehende
-- Post an valton.rexha@koretini.me kommt erst an, wenn sie beim Host
-- eingetragen ist. Die Maske Vereinsadressen zeigt die Paare dafuer.

DO $$
DECLARE
  r record;
  v_domains text[];
  v_n int := 0;
BEGIN
  -- Dieselbe Regel wie in vorstand_adresse_setzen: die Domain muss dem
  -- Verein gehoeren. Hier wird sie nicht umgangen, sondern wiederholt.
  SELECT array_agg(DISTINCT regexp_replace(lower(d.domain), '^www\.', ''))
    INTO v_domains
    FROM public.tenant_domains d WHERE d."tenantId" = 'koretini';
  IF v_domains IS NULL OR NOT ('koretini.me' = ANY (v_domains)) THEN
    RAISE EXCEPTION 'koretini.me gehoert nicht zu den Domains von koretini: %',
      coalesce(array_to_string(v_domains, ', '), '(keine)');
  END IF;

  FOR r IN
    SELECT * FROM (VALUES
      ('valton.rexha@koretini.me',    'valton',  'rexha'),
      ('sokol.axhija@koretini.me',    'sokol',   'axhija'),
      ('gazmend.mehmeti@koretini.me', 'gazmend', 'mehmeti'),
      ('ismet.klaiqi@koretini.me',    'ismet',   'klaiqi'),
      ('bajram.shillova@koretini.me', 'bajram',  'shillova')
    ) AS t(adresse, vorname, nachname)
  LOOP
    DECLARE
      v_user text; v_name text; v_privat text; v_treffer int;
    BEGIN
      SELECT count(*) INTO v_treffer
        FROM public.users u
       WHERE u."tenantId" = 'koretini'
         AND lower(coalesce(u."displayName",'')) LIKE '%' || r.vorname || '%'
         AND lower(coalesce(u."displayName",'')) LIKE '%' || r.nachname || '%';
      -- Nicht eindeutig heisst: nicht raten. Eine Adresse bei der
      -- falschen Person ist kein kleiner Fehler.
      IF v_treffer <> 1 THEN
        RAISE EXCEPTION '% passt auf % Mitglieder, nicht auf eines.', r.adresse, v_treffer;
      END IF;

      SELECT u.id, u."displayName", u.email INTO v_user, v_name, v_privat
        FROM public.users u
       WHERE u."tenantId" = 'koretini'
         AND lower(coalesce(u."displayName",'')) LIKE '%' || r.vorname || '%'
         AND lower(coalesce(u."displayName",'')) LIKE '%' || r.nachname || '%';

      -- Das Weiterleitungsziel ist die gespeicherte private Adresse.
      -- Fehlt sie, wird nichts erfunden: dann steht die Adresse ohne
      -- Ziel da, und die Maske zeigt "Ziel fehlt".
      IF coalesce(btrim(coalesce(v_privat,'')),'') = '' THEN
        RAISE NOTICE '% hat keine private Adresse -- Eintrag ohne Ziel.', v_name;
      END IF;

      INSERT INTO public.vorstand_adressen
        ("tenantId", "userId", adresse, weiterleitung, aktiv, geaendert_am, geaendert_von)
      VALUES ('koretini', v_user, r.adresse, nullif(btrim(coalesce(v_privat,'')),''),
              true, now(), 'migration 20261103000000')
      ON CONFLICT (lower(adresse)) DO UPDATE
        SET "userId" = EXCLUDED."userId",
            weiterleitung = coalesce(EXCLUDED.weiterleitung, public.vorstand_adressen.weiterleitung),
            aktiv = true, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;
      v_n := v_n + 1;
    END;
  END LOOP;

  -- ------------------------------------------------- Nachweis
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'Erwartet waren 5 Adressen, angelegt wurden %.', v_n;
  END IF;

  -- a) Jede Adresse gehoert genau einer Person, und das Ziel ist deren
  --    gespeicherte Adresse. Weicht es ab, ist die Zuordnung falsch --
  --    und dann ginge die Post eines anderen woanders hin.
  SELECT count(*) INTO v_n
    FROM public.vorstand_adressen a
    JOIN public.users u ON u.id = a."userId"
   WHERE a."tenantId" = 'koretini' AND a.aktiv
     AND a.weiterleitung IS NOT NULL
     AND a.weiterleitung IS DISTINCT FROM u.email;
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Eintrag/Eintraege zeigen auf eine andere Adresse als die des Mitglieds.', v_n;
  END IF;

  -- b) Alle fuenf sind wirklich im Vorstand. Eine Absenderidentitaet
  --    fuer ein gewoehnliches Mitglied waere ein Fehler.
  SELECT count(*) INTO v_n
    FROM public.vorstand_adressen a
    JOIN public.users u ON u.id = a."userId"
   WHERE a."tenantId" = 'koretini' AND a.aktiv
     AND coalesce(u.role,'') NOT IN ('BOARD','ADMIN','SUPER_ADMIN')
     AND NOT EXISTS (SELECT 1 FROM public.board_members b
                      WHERE b."userId" = u.id AND b."tenantId" = 'koretini');
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Adresse(n) gehoeren Personen ohne Vorstandsfunktion.', v_n;
  END IF;

  -- c) Keine Adresse doppelt, keine Person zweimal.
  IF (SELECT count(*) FROM public.vorstand_adressen WHERE "tenantId"='koretini' AND aktiv) <> 5 THEN
    RAISE EXCEPTION 'Es stehen nicht genau 5 aktive Adressen da.';
  END IF;

  RAISE NOTICE 'Koretini: 5 Vereinsadressen gesetzt, Ziele stimmen mit den gespeicherten Adressen ueberein.';
END $$;
