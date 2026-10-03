-- Die Gast-Anmeldung zu einem Anlass war der einzige Weg, vereinsfremd zu
-- schreiben.
--
-- Die Regel lautete:
--
--   CHECK ("userId" IS NULL AND modul_aktiv('ANLAESSE'))
--
-- Kein Wort ueber den Verein. Und set_tenant_on_insert fuellt nur einen
-- LEEREN tenantId -- einen mitgelieferten laesst es stehen. Ein nicht
-- angemeldeter Aufrufer konnte damit eine Anmeldung in die Anlassliste
-- eines FREMDEN Vereins schreiben. Lesen konnte er sie nicht, aber
-- hineinschreiben schon: fremde Namen in fremden Teilnehmerlisten.
--
-- Gefunden beim systematischen Durchgehen aller INSERT-Regeln; es war die
-- einzige ohne Verein-Pruefung.
--
-- Jetzt zwei Bedingungen statt keiner:
--   - die Zeile gehoert dem Verein, von dessen Adresse die Anfrage kommt
--   - und der Anlass gehoert demselben Verein
--
-- Das zweite schliesst auch die Anmeldung zu einem Anlass aus, den es
-- beim eigenen Verein gar nicht gibt.

DROP POLICY IF EXISTS event_registrations_guest_insert ON public.event_registrations;
CREATE POLICY event_registrations_guest_insert ON public.event_registrations
  FOR INSERT
  WITH CHECK (
    "userId" IS NULL
    AND public.modul_aktiv('ANLAESSE')
    AND "tenantId" = coalesce(public.current_tenant(), public.request_tenant())
    AND EXISTS (SELECT 1 FROM public.events e
                 WHERE e.id = "eventId"
                   AND e."tenantId" = "tenantId")
  );


-- Nachweis mit einem erfundenen zweiten Verein, der danach wieder
-- verschwindet. Mit einem Verein laesst sich eine Kollision nicht
-- herbeifuehren -- und ein Nachweis, der nichts pruefen kann, ist keiner.
DO $$
DECLARE
  v_zurueck text := current_user;
  v_erster  text;
  v_zweiter text := '__probe_fremdverein';
  v_anlass  text;
  v_fremd_anlass text := '__probe_anlass';
  v_zeilen int;
BEGIN
  SELECT t.id INTO v_erster FROM public.tenants t
   WHERE EXISTS (SELECT 1 FROM public.events e WHERE e."tenantId" = t.id) LIMIT 1;
  IF v_erster IS NULL THEN
    RAISE WARNING 'PRUEFUNG UEBERSPRUNGEN: kein Verein mit Anlaessen.';
    RETURN;
  END IF;
  SELECT e.id INTO v_anlass FROM public.events e WHERE e."tenantId" = v_erster LIMIT 1;

  INSERT INTO public.tenants (id, name, alle_module_frei)
  VALUES (v_zweiter, 'Probeverein (wird entfernt)', true) ON CONFLICT DO NOTHING;
  INSERT INTO public.events (id, "tenantId", title, description, date, location, image,
                             category, status, "isFeatured", "isRegistrable")
  VALUES (v_fremd_anlass, v_zweiter, 'Probe', 'Probe', '2026-12-01', 'Probe', '',
          'SOCIAL', 'UPCOMING', false, true)
  ON CONFLICT DO NOTHING;

  -- Als nicht angemeldeter Gast, dessen Adresse zum ZWEITEN Verein gehoert.
  PERFORM set_config('request.jwt.claims', '{}', true);
  PERFORM set_config('request.headers',
    json_build_object('origin', 'https://' || v_zweiter || '.example')::text, true);
  EXECUTE 'SET LOCAL ROLE anon';

  BEGIN
    INSERT INTO public.event_registrations (id, "eventId", "tenantId", name, email, type, status)
    VALUES ('__probe_anmeldung', v_anlass, v_erster, 'Eindringling', 'x@y.z', 'GUEST', 'PENDING');
    GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege OR check_violation THEN
    v_zeilen := 0;
  END;

  EXECUTE format('SET LOCAL ROLE %I', v_zurueck);
  PERFORM set_config('request.headers', '{}', true);

  RAISE NOTICE 'Gast des Vereins % schreibt in die Anlassliste von %: % Zeile(n) (0 ist richtig)',
    v_zweiter, v_erster, coalesce(v_zeilen, 0);

  DELETE FROM public.event_registrations WHERE id = '__probe_anmeldung';
  DELETE FROM public.events WHERE id = v_fremd_anlass;
  DELETE FROM public.tenants WHERE id = v_zweiter;

  IF coalesce(v_zeilen, 0) <> 0 THEN
    RAISE EXCEPTION 'TRENNUNG VERLETZT: fremde Anmeldung ging durch.';
  END IF;
  RAISE NOTICE 'Trennung nachgewiesen, Probedaten entfernt.';
END $$;
