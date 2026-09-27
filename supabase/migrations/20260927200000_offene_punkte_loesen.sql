-- Drei offene Punkte, die ohne fremde Zugangsdaten zu loesen sind.

-- --- 1. Der Postausgang stand wieder auf Port 25 -------------------------
-- Port 25 ist der Weg zwischen Mailservern, nicht der zum Einliefern. Viele
-- Anbieter und fast alle Heim- und Firmennetze sperren ihn ausgehend; die
-- Einlieferung gehoert auf 587 mit STARTTLS. Das Kennwort wird dabei nicht
-- angefasst -- es steht hier ohnehin nicht zur Debatte.
UPDATE public.mail_settings
   SET port = 587, tls = 'starttls',
       geaendert_am = now(),
       geaendert_von = coalesce(geaendert_von, 'system')
 WHERE port = 25;

-- --- 2. Das doppelte Spendenkonto ----------------------------------------
-- 3200 "Ertrag Spenden" und 3400 "Spenden" sind dasselbe. Gebucht wird auf
-- 3200 (so macht es spende_bezahlt und so legt es verein_einrichten an);
-- 3400 traegt 0 Buchungen. Geloescht wird trotzdem nur nach Pruefung: auf
-- accounting_accounts.code zeigen vier Fremdschluessel.
DO $$
DECLARE r record; v_n int; v_gesamt int := 0;
BEGIN
  FOR r IN SELECT c.conname, t.relname AS tab,
                  (SELECT a.attname FROM unnest(c.conkey) k
                     JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k LIMIT 1) AS spalte
             FROM pg_constraint c
             JOIN pg_class t ON t.oid=c.conrelid
            WHERE c.contype='f' AND c.confrelid='public.accounting_accounts'::regclass
  LOOP
    EXECUTE format('SELECT count(*) FROM public.%I WHERE %I = %L', r.tab, r.spalte, '3400')
      INTO v_n;
    RAISE NOTICE '  %.% verweist auf 3400: % Zeilen', r.tab, r.spalte, v_n;
    v_gesamt := v_gesamt + v_n;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.accounting_journal
   WHERE "tenantId"='koretini' AND ('3400' IN ("debitCode", "creditCode"));
  RAISE NOTICE '  Buchungen auf 3400: %', v_n;
  v_gesamt := v_gesamt + v_n;

  IF v_gesamt = 0 THEN
    DELETE FROM public.accounting_accounts WHERE "tenantId"='koretini' AND code='3400';
    RAISE NOTICE '  -> 3400 entfernt.';
  ELSE
    RAISE NOTICE '  -> 3400 bleibt stehen: % Verweise. Ein Konto mit Verweisen', v_gesamt;
    RAISE NOTICE '     zu loeschen hiesse, die Buchhaltung zu zerreissen.';
  END IF;
END $$;

-- --- 3. Schreibrechte, die nichts zu suchen haben ------------------------
-- anon hat auf fiscal_years INSERT/UPDATE/DELETE/TRUNCATE. Die Zeilenregel
-- haelt das ab (fiscal_years_staff_all), das Recht selbst ist trotzdem
-- falsch: faellt die Regel je weg oder kommt eine zweite mit anderer
-- Bedingung dazu, steht die Tuer offen. Rechte und Regeln sollen dasselbe
-- sagen.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.fiscal_years FROM anon;

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Nachher ===';
  FOR r IN SELECT to_jsonb(m) - 'kennwort' - 'zeitplan_token' AS j FROM public.mail_settings m LOOP
    RAISE NOTICE '  Postausgang: %', r.j;
  END LOOP;
  FOR r IN SELECT code, name FROM public.accounting_accounts
            WHERE "tenantId"='koretini' AND code LIKE '3%' ORDER BY code LOOP
    RAISE NOTICE '  Ertragskonto % %', r.code, r.name;
  END LOOP;
  FOR r IN SELECT table_name, string_agg(privilege_type,',' ORDER BY privilege_type) AS p
             FROM information_schema.role_table_grants
            WHERE grantee='anon' AND table_schema='public'
              AND privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE')
            GROUP BY 1 LOOP
    RAISE NOTICE '  anon schreibt noch auf %: %', r.table_name, r.p;
  END LOOP;
END $$;
