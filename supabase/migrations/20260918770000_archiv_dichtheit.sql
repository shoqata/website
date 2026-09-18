-- Kommt jemand an das Archiv heran, der nicht soll?
-- Geprueft wird in der Rolle, in der die Anwendung wirklich arbeitet.
DO $$
DECLARE v_n int; v_back text := current_user;
BEGIN
  SELECT count(*) INTO v_n FROM public.accounting_journal_archiv;
  RAISE NOTICE 'Archiv enthaelt % Buchungen ueber % CHF', v_n,
    (SELECT coalesce(sum((zeile->>'amount')::numeric),0) FROM public.accounting_journal_archiv);

  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.accounting_journal_archiv;
    RAISE NOTICE 'anon liest das Archiv: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'anon: kein Zugriff (richtig)';
  END;

  SET LOCAL ROLE authenticated;
  BEGIN
    SELECT count(*) INTO v_n FROM public.accounting_journal_archiv;
    RAISE NOTICE 'authenticated liest das Archiv: % Zeilen -- LOCH', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'authenticated: kein Zugriff (richtig)';
  END;
  BEGIN
    INSERT INTO public.accounting_journal_archiv (id, zeile, grund)
      VALUES ('probe', '{}'::jsonb, 'Probe');
    RAISE NOTICE 'authenticated schreibt ins Archiv -- LOCH';
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'authenticated: kein Schreiben (richtig)';
  END;

  -- Zurueck in die urspruengliche Rolle. Weder RESET ROLE noch
  -- SET LOCAL ROLE NONE wirken hier zuverlaessig; ohne diese Zeile bleibt
  -- die Sitzung auf authenticated und die Migrationsverwaltung kann ihren
  -- eigenen Eintrag nicht mehr schreiben.
  EXECUTE format('SET ROLE %I', v_back);
END $$;
