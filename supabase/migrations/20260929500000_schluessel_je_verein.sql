-- Drei Tabellen, in denen es jeden Datensatz nur EINMAL auf der ganzen
-- Plattform geben konnte.
--
-- settings wurde dafuer schon einmal umgestellt -- damals fiel auf, dass es
-- settings/payment nur ein einziges Mal geben konnte. Dieselbe Falle steht
-- noch in der Buchhaltung:
--
--   accounting_accounts   Primaerschluessel id, und der Code schreibt den
--                         Kontocode hinein ('3000'). Der zweite Verein
--                         koennte also kein Konto 3000 anlegen.
--   fiscal_years          id = Jahreszahl. Das Jahr 2026 gaebe es einmal.
--   fiscal_budgets        id = Jahreszahl. Dasselbe fuer das Budget.
--
-- Heute faellt das niemandem auf, weil es genau einen Verein gibt. Der
-- zweite haette es sofort gemerkt: sein Kontenplan liesse sich nicht
-- anlegen, sein Budget nicht speichern.
--
-- Die Fremdschluessel aus accounting_journal und expenses zeigen auf
-- (tenantId, code) und nicht auf den Primaerschluessel -- sie bleiben
-- unberuehrt. Der eindeutige Index accounting_accounts_code_je_verein
-- traegt sie weiter.

DO $$
DECLARE
  t text;
  v_ohne int;
  v_dubletten int;
BEGIN
  FOREACH t IN ARRAY ARRAY['accounting_accounts','fiscal_years','fiscal_budgets']
  LOOP
    -- Erst messen, dann aendern. Ein zusammengesetzter Schluessel verlangt,
    -- dass tenantId gefuellt ist; und wenn es dieselbe Kennung schon zweimal
    -- je Verein gaebe, liesse er sich gar nicht anlegen.
    EXECUTE format('SELECT count(*) FROM public.%I WHERE "tenantId" IS NULL', t) INTO v_ohne;
    EXECUTE format('SELECT count(*) FROM (SELECT id, "tenantId" FROM public.%I
                      GROUP BY 1,2 HAVING count(*) > 1) x', t) INTO v_dubletten;

    IF v_ohne > 0 THEN
      RAISE EXCEPTION '%: % Zeilen ohne Verein. Nichts geaendert.', t, v_ohne;
    END IF;
    IF v_dubletten > 0 THEN
      RAISE EXCEPTION '%: % doppelte (Verein, id). Nichts geaendert.', t, v_dubletten;
    END IF;

    EXECUTE format('ALTER TABLE public.%I ALTER COLUMN "tenantId" SET NOT NULL', t);

    -- Den alten Schluessel loesen und den zusammengesetzten setzen. Der Name
    -- bleibt derselbe, damit spaetere Migrationen ihn wiederfinden.
    EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I', t, t || '_pkey');
    EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I PRIMARY KEY ("tenantId", id)', t, t || '_pkey');

    RAISE NOTICE '%: Primaerschluessel ist jetzt (tenantId, id)', t;
  END LOOP;
END $$;


-- Nachweis: zwei Vereine duerfen dieselbe Kennung tragen.
--
-- Gemessen wird mit einem erfundenen zweiten Verein, der danach wieder
-- verschwindet. Ohne das waere der Nachweis leer -- es gibt bis heute nur
-- einen Verein, und eine Kollision kann man mit einem Verein nicht
-- herbeifuehren.
DO $$
DECLARE
  v_erster text;
  v_zweiter text := '__probe_zweiter_verein';
  v_konto text;
BEGIN
  SELECT "tenantId" INTO v_erster FROM public.accounting_accounts LIMIT 1;
  SELECT id INTO v_konto FROM public.accounting_accounts WHERE "tenantId" = v_erster LIMIT 1;
  IF v_konto IS NULL THEN
    RAISE WARNING 'PRUEFUNG UEBERSPRUNGEN: kein Konto vorhanden.';
    RETURN;
  END IF;

  -- name ist pflichtig. Ein erster Versuch schrieb nur die id, und die
  -- Migration brach ab -- richtig so: nichts wurde geaendert. Mein Geruest
  -- hatte eine schlankere tenants-Tabelle als die echte Datenbank.
  INSERT INTO public.tenants (id, name) VALUES (v_zweiter, 'Probeverein (wird entfernt)')
  ON CONFLICT DO NOTHING;

  -- Dieselbe Kennung, anderer Verein. Vorher scheiterte genau das.
  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category)
  VALUES (v_konto, v_zweiter, v_konto, 'Probe', 'REVENUE', 'Probe');
  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  VALUES ('2026', v_zweiter, 2026, 'OPEN');
  INSERT INTO public.fiscal_budgets (id, "tenantId", year, entries)
  VALUES ('2026', v_zweiter, 2026, '{}'::jsonb);

  RAISE NOTICE 'Zweiter Verein konnte Konto %, Jahr 2026 und Budget 2026 anlegen.', v_konto;

  DELETE FROM public.fiscal_budgets WHERE "tenantId" = v_zweiter;
  DELETE FROM public.fiscal_years   WHERE "tenantId" = v_zweiter;
  DELETE FROM public.accounting_accounts WHERE "tenantId" = v_zweiter;
  DELETE FROM public.tenants WHERE id = v_zweiter;
  RAISE NOTICE 'Probeverein wieder entfernt.';
END $$;
