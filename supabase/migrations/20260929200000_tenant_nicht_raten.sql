-- Der Ausloeser darf den Verein nicht raten.
--
-- Bisher: COALESCE(current_tenant(), 'koretini'). Solange es einen Verein
-- gab, fiel das nicht auf. Gemessen am 29.09.2026 mit einem zweiten Verein:
-- eine oeffentliche Anlassanmeldung auf dessen Domain bekam "koretini"
-- gestempelt und wurde daraufhin von der Zeilenregel abgewiesen. Kein Leck
-- also -- aber eine Anmeldung, die bei jedem Verein ausser Koretini
-- unmoeglich ist.
--
-- Richtig ist derselbe Weg, den die ganze Anwendung sonst geht: angemeldet
-- der eigene Verein, sonst der Verein der aufrufenden Adresse. Ist beides
-- unbekannt, bleibt die Spalte leer -- und die NOT-NULL-Bedingung sagt
-- deutlich, was fehlt. Das ist besser als ein stiller falscher Verein.
CREATE OR REPLACE FUNCTION public.set_tenant_on_insert()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."tenantId" IS NULL THEN
    NEW."tenantId" := COALESCE(public.current_tenant(), public.request_tenant());
  END IF;
  RETURN NEW;
END $$;

DO $$
DECLARE v_back text := current_user; v_wo text; v_n int;
BEGIN
  INSERT INTO public.events (id, "tenantId", title, date, status)
  VALUES ('probe-fremd-anlass','probe-fremdverein','Probeanlass', (current_date+10)::text, 'PUBLISHED')
  ON CONFLICT (id) DO NOTHING;

  PERFORM set_config('request.headers',
    json_build_object('origin','https://probe-fremd.example.org')::text, false);
  EXECUTE 'SET ROLE anon';
  BEGIN
    INSERT INTO public.event_registrations (id, "eventId", name, email)
    VALUES ('probe-anmeldung','probe-fremd-anlass','Probe Gast','gast@example.org');
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  abgewiesen: %', left(SQLERRM,70);
  END;
  EXECUTE format('SET ROLE %I', v_back);

  SELECT "tenantId" INTO v_wo FROM public.event_registrations WHERE id='probe-anmeldung';
  RAISE NOTICE 'Anmeldung landet jetzt bei: % (erwartet probe-fremdverein)', coalesce(v_wo,'(keine Zeile)');

  -- Und die gewohnte Seite arbeitet unveraendert?
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.public_members;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Koretini unveraendert: % Mitglieder sichtbar', v_n;

  -- Aufraeumen: Probeanmeldung, Anlass und der Probeverein
  DELETE FROM public.event_registrations WHERE id='probe-anmeldung';
  DELETE FROM public.events WHERE id='probe-fremd-anlass';
  DELETE FROM public.tenant_modules WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.accounting_accounts WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.fiscal_years WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.settings WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.users WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.tenant_domains WHERE "tenantId"='probe-fremdverein';
  DELETE FROM public.tenants WHERE id='probe-fremdverein';
  PERFORM set_config('request.headers', NULL, false);
  SELECT count(*) INTO v_n FROM public.tenants;
  RAISE NOTICE 'Vereine danach: % (erwartet 1)', v_n;
END $$;
