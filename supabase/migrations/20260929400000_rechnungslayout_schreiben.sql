-- Darf der Vorstand das Rechnungslayout speichern?
--
-- Der neue Rechnungsdesigner legt settings/rechnungslayout an. In den
-- Migrationen steht fuer public.settings nur eine LESE-Regel; eine
-- Schreibregel muss es live geben, sonst koennte heute niemand das Branding
-- aendern -- in welcher Form, ist aus den Dateien nicht ersichtlich.
--
-- Deshalb wird hier zuerst GEMESSEN und erst danach etwas geaendert. Eine
-- Regel blind anzulegen hiesse, den Zugriff vielleicht auszuweiten, ohne es
-- zu merken.
--
-- Die Messung benutzt GET DIAGNOSTICS. Ein UPDATE, das null Zeilen trifft,
-- wirft keinen Fehler -- "hat funktioniert" und "hat nichts getan" sehen
-- sonst gleich aus. Dieselbe Falle hat in diesem Projekt schon einmal eine
-- falsche Entwarnung gegeben.

DO $$
DECLARE
  r RECORD;
  v_regeln int := 0;
  v_schreibregeln int := 0;
BEGIN
  RAISE NOTICE '--- Regeln auf public.settings ---';
  FOR r IN
    SELECT polname, polcmd,
           pg_get_expr(polqual, polrelid)      AS lesen,
           pg_get_expr(polwithcheck, polrelid) AS schreiben
      FROM pg_policy WHERE polrelid = 'public.settings'::regclass
     ORDER BY polname
  LOOP
    v_regeln := v_regeln + 1;
    IF r.polcmd IN ('a','w','*') THEN v_schreibregeln := v_schreibregeln + 1; END IF;
    RAISE NOTICE '  % [%]  USING=%  WITH CHECK=%',
      r.polname,
      CASE r.polcmd WHEN 'r' THEN 'SELECT' WHEN 'a' THEN 'INSERT'
                    WHEN 'w' THEN 'UPDATE' WHEN 'd' THEN 'DELETE' ELSE 'ALL' END,
      coalesce(r.lesen,'-'), coalesce(r.schreiben,'-');
  END LOOP;
  RAISE NOTICE '  Summe: % Regeln, davon % schreibend', v_regeln, v_schreibregeln;

  IF v_schreibregeln = 0 THEN
    RAISE WARNING 'Keine Schreibregel auf settings gefunden. Der Rechnungsdesigner koennte nicht speichern -- unten wird eine angelegt.';
  END IF;
END $$;


-- Eine Schreibregel anlegen, aber nur wenn keine da ist.
--
-- Sie spiegelt die Leseregel: derselbe Personenkreis (Vorstand und
-- Vorsitz -- is_staff), derselbe Verein. Keine Ausweitung.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy
                  WHERE polrelid = 'public.settings'::regclass
                    AND polcmd IN ('a','w','*')) THEN
    EXECUTE $r$
      CREATE POLICY settings_staff_schreiben ON public.settings
        FOR ALL TO authenticated
        USING      (public.is_staff() AND "tenantId" = public.current_tenant())
        WITH CHECK (public.is_staff() AND "tenantId" = public.current_tenant())
    $r$;
    RAISE NOTICE 'Schreibregel settings_staff_schreiben angelegt.';
  ELSE
    RAISE NOTICE 'Schreibregel vorhanden -- nichts geaendert.';
  END IF;
END $$;


-- Nachweis: schreibt ein Vorstandsmitglied das Layout wirklich, und bleibt
-- es dabei in seinem Verein?
--
-- Geschrieben wird auf eine Wegwerf-Kennung, NICHT auf rechnungslayout
-- selbst. Der erste Entwurf schrieb dorthin und loeschte die Zeile danach
-- wieder -- haette ein Verein sein Layout schon gespeichert, haette die
-- Pruefung es zerstoert. Eine Pruefung, die Daten vernichtet, ist keine.
DO $$
DECLARE
  v_zurueck text := current_user;
  v_verein  text;
  -- text, nicht uuid: public.users.id ist in dieser Datenbank Text (331 von
  -- 340 Zeilen tragen alte Textkennungen wie 'admin-user-id').
  v_person  text;
  v_auth    text;
  v_zeilen  int;
  v_fremd   int;
BEGIN
  -- Entscheidend: "sub" im Token ist die AUTH-Kennung, nicht die
  -- Zeilenkennung. current_user_row_id() sucht ueber auth.uid(), und
  -- auth.uid() wandelt sub in uuid um -- mit einer Textkennung als sub
  -- bricht schon das ab, bevor irgendeine Regel geprueft wird. Ein erster
  -- Versuch setzte users.id ein und scheiterte genau daran.
  SELECT u."tenantId", u.id, u."authUserId" INTO v_verein, v_person, v_auth
    FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN','BOARD')
     AND u."authUserId" ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   ORDER BY u."tenantId" LIMIT 1;

  IF v_auth IS NULL THEN
    RAISE WARNING 'PRUEFUNG UEBERSPRUNGEN: kein Vorstandsmitglied mit gueltiger Auth-Kennung.';
    RETURN;
  END IF;

  PERFORM set_config('request.jwt.claims', json_build_object(
    'sub', v_auth,
    'role', 'authenticated',
    'app_metadata', json_build_object('tenant', v_verein))::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  INSERT INTO public.settings ("tenantId", id, data)
  VALUES (v_verein, '__probe_schreibrecht', '{"probe":true}'::jsonb)
  ON CONFLICT ("tenantId", id) DO UPDATE SET data = EXCLUDED.data;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;

  -- Und die Gegenprobe: ein fremder Verein darf NICHT beschrieben werden.
  BEGIN
    UPDATE public.settings SET data = '{"fremd":true}'::jsonb
     WHERE "tenantId" <> v_verein AND id = '__probe_schreibrecht';
    GET DIAGNOSTICS v_fremd = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_fremd := 0;
  END;

  EXECUTE format('SET LOCAL ROLE %I', v_zurueck);

  RAISE NOTICE '--- Nachweis ---';
  RAISE NOTICE '  Vorstand von % schreibt Einstellungen: % Zeile(n)', v_verein, v_zeilen;
  RAISE NOTICE '  Fremder Verein beschrieben: % Zeile(n) (0 ist richtig)', v_fremd;

  IF v_zeilen <> 1 THEN
    RAISE EXCEPTION 'Der Designer koennte nicht speichern: % Zeilen statt 1.', v_zeilen;
  END IF;
  IF v_fremd <> 0 THEN
    RAISE EXCEPTION 'MANDANTENTRENNUNG VERLETZT: % fremde Zeilen beschrieben.', v_fremd;
  END IF;

  -- Der Test darf nichts hinterlassen.
  DELETE FROM public.settings WHERE "tenantId" = v_verein AND id = '__probe_schreibrecht';
  PERFORM set_config('request.jwt.claims', NULL, true);
  RAISE NOTICE '  Nachweis erbracht, Probezeile entfernt.';
END $$;
