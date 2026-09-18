-- Nachweis, bevor etwas geaendert wird.
--
-- Die Sichten laufen mit den Rechten ihres Eigentuemers und umgehen damit die
-- Zugriffsregeln der Tabellen darunter. Zugleich haben anon und authenticated
-- darauf INSERT, UPDATE, DELETE und TRUNCATE. Eine einfache Sicht auf genau
-- eine Tabelle ist in PostgreSQL automatisch beschreibbar -- public_members
-- liegt auf users, socialMediaPosts auf socialmediaposts.
--
-- Geprueft wird ohne Datenverlust: geloescht wird nach einer Bedingung, die
-- auf keine Zeile passt. Kommt kein Rechtefehler, besteht das Recht.
DO $$
DECLARE
  v_back text := current_user;
  v_n int; v_err text;
BEGIN
  EXECUTE 'SET ROLE anon';

  BEGIN
    SELECT count(*) INTO v_n FROM public."socialMediaPosts";
    RAISE NOTICE '1 anon liest socialMediaPosts: % Zeilen -- sollte 0 sein', v_n;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '1 anon liest socialMediaPosts: abgewiesen -- %', v_err;
  END;

  BEGIN
    SELECT count(*) INTO v_n FROM public.socialmediaposts;
    RAISE NOTICE '2 anon liest die Tabelle darunter: % Zeilen -- erwartet 0', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '2 anon liest die Tabelle darunter: abgewiesen -- richtig';
  END;

  BEGIN
    DELETE FROM public."socialMediaPosts" WHERE id = '__nichts__';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '3 anon darf in socialMediaPosts loeschen: JA (% Zeilen getroffen)', v_n;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '3 anon darf in socialMediaPosts loeschen: nein -- richtig';
  WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '3 anon loescht in socialMediaPosts: anderer Fehler -- %', v_err;
  END;

  BEGIN
    DELETE FROM public.public_members WHERE id = '__nichts__';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '4 anon darf ueber public_members Mitglieder loeschen: JA (% getroffen)', v_n;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '4 anon darf ueber public_members loeschen: nein -- richtig';
  WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '4 anon loescht ueber public_members: anderer Fehler -- %', v_err;
  END;

  BEGIN
    DELETE FROM public.public_tenants WHERE id = '__nichts__';
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE '5 anon darf ueber public_tenants Vereine loeschen: JA (% getroffen)', v_n;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '5 anon darf ueber public_tenants loeschen: nein -- richtig';
  WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '5 anon loescht ueber public_tenants: anderer Fehler -- %', v_err;
  END;

  BEGIN
    SELECT count(*) INTO v_n FROM public.public_settings;
    RAISE NOTICE '6 anon liest public_settings: % Zeilen', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '6 anon liest public_settings: abgewiesen';
  END;

  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Rolle zurueckgesetzt. Es wurde nichts geloescht -- die Bedingung passt auf keine Zeile.';
END $$;
