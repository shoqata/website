-- Die Regel polls_vote entfernen.
--
-- Sie lautet USING (true) WITH CHECK (true) fuer jeden Angemeldeten. Das ist
-- kein Stimmrecht, sondern das Recht, jede Umfrage jedes Vereins vollstaendig
-- zu ueberschreiben -- Frage, Antworten, Stimmen, sogar die Vereinszuordnung.
-- Eine Vereinsgrenze kommt darin nicht vor.
--
-- Nachgesehen, bevor sie faellt: im gesamten Code wird nirgends abgestimmt.
-- Umfragen werden nur im Adminbereich angelegt und geloescht, und dafuer gibt
-- es polls_manage. Die Regel deckte also eine Funktion ab, die es nicht gibt.
--
-- Wird das Abstimmen spaeter gebaut, gehoert es in eine Funktion mit erhoehten
-- Rechten, die genau eine Stimme hochzaehlt -- nicht in ein offenes
-- Schreibrecht auf die ganze Zeile.

DROP POLICY IF EXISTS polls_vote ON public.polls;

DO $$
DECLARE v_back text := current_user; v_err text; r record; v_n int;
BEGIN
  RAISE NOTICE '=== Regeln auf polls jetzt ===';
  FOR r IN SELECT policyname, cmd, coalesce(qual,'-') AS q FROM pg_policies
            WHERE schemaname='public' AND tablename='polls' ORDER BY cmd LOOP
    RAISE NOTICE '  % [%] USING %', r.policyname, r.cmd, r.q;
  END LOOP;

  -- Gegenprobe mit einem gewoehnlichen Mitglied: es darf keine Umfrage mehr
  -- veraendern, aber weiterhin lesen.
  SELECT u."authUserId", u.email INTO r FROM public.users u
   WHERE u."authUserId" IS NOT NULL AND coalesce(u.role,'MEMBER') NOT IN ('ADMIN','SUPER_ADMIN','BOARD')
   LIMIT 1;

  IF r IS NULL THEN
    RAISE NOTICE 'Gegenprobe nicht moeglich: kein angemeldetes Mitglied ohne Leitungsrolle.';
    RETURN;
  END IF;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', r."authUserId", 'role','authenticated','email', r.email)::text, false);
  EXECUTE 'SET ROLE authenticated';

  BEGIN
    UPDATE public.polls SET question = question;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN
      RAISE NOTICE 'Mitglied aendert Umfragen: % Zeilen -- SCHWERER FEHLER', v_n;
    ELSE
      RAISE NOTICE 'Mitglied aendert Umfragen: 0 Zeilen -- richtig';
    END IF;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Mitglied aendert Umfragen: abgewiesen -- richtig';
  END;

  SELECT count(*) INTO v_n FROM public.polls;
  RAISE NOTICE 'Mitglied liest Umfragen: % -- muss weiterhin gehen', v_n;

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
