-- Kommt jemand an den Postausgang heran, der nicht soll?
-- Geprueft in den Rollen, in denen die Anwendung wirklich arbeitet.
DO $$
DECLARE v_n int; v_back text := current_user; v_txt text;
BEGIN
  -- Ein Probeeintrag mit erkennbarem Kennwort.
  INSERT INTO public.mail_settings ("tenantId", host, benutzer, kennwort, absender)
  VALUES ('koretini', 'mail.beispiel.ch', 'probe', 'GEHEIM-PROBE-12345', 'info@koretini.me')
  ON CONFLICT ("tenantId") DO UPDATE SET kennwort = 'GEHEIM-PROBE-12345';

  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.mail_settings;
    RAISE NOTICE 'anon liest die Tabelle: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'anon Tabelle: kein Zugriff (richtig)';
  END;
  BEGIN
    PERFORM public.mail_einstellungen_lesen();
    RAISE NOTICE 'anon ruft mail_einstellungen_lesen -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon Funktion: abgewiesen (richtig)';
  END;

  -- Gewoehnliches Mitglied: angemeldet, aber ohne Verwaltungsrolle.
  SET LOCAL ROLE authenticated;
  BEGIN
    SELECT count(*) INTO v_n FROM public.mail_settings;
    RAISE NOTICE 'Mitglied liest die Tabelle: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'Mitglied Tabelle: kein Zugriff (richtig)';
  END;
  BEGIN
    PERFORM public.mail_einstellungen_lesen();
    RAISE NOTICE 'Mitglied ruft mail_einstellungen_lesen -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Mitglied Funktion: abgewiesen (richtig)';
  END;

  EXECUTE format('SET ROLE %I', v_back);

  -- Gibt die Lesefunktion das Kennwort heraus? Die Spaltenliste zeigt es.
  SELECT string_agg(a.attname, ', ' ORDER BY a.attnum) INTO v_txt
    FROM pg_proc p
    JOIN pg_type t ON t.oid = p.prorettype
    JOIN pg_class c ON c.reltype = t.oid
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0
   WHERE p.proname = 'mail_einstellungen_lesen';
  RAISE NOTICE 'Rueckgabe der Lesefunktion: %', coalesce(v_txt, '(zusammengesetzt)');

  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema='public' AND table_name='public_settings' AND column_name='kennwort';
  RAISE NOTICE 'Kennwort in public_settings: % (soll 0 sein)', v_n;

  DELETE FROM public.mail_settings WHERE "tenantId" = 'koretini';
  RAISE NOTICE 'Probeeintrag entfernt.';
END $$;
