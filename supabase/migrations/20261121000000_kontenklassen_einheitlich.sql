-- Kontenklassen: nur noch ASSET, LIABILITY, REVENUE, EXPENSE.
--
-- verein_einrichten() legte den Kontenplan mit AKTIVEN, PASSIVEN, ERTRAG,
-- AUFWAND an; Bilanz, Erfolgsrechnung und jahresabschluss() kennen nur die
-- englischen Namen. Die Konten fehlten darum in beiden Berichten, und mit
-- ihnen die Buchungen darauf -- im Demoverein ausgerechnet Bank,
-- Forderungen, Mitgliederbeitraege und Kasse EUR. Koretini (Kontenplan aus
-- kontenplan_anlegen) war nicht betroffen.
--
-- 1. Bestand umschreiben. 2. verein_einrichten() korrigieren. 3. Eine
-- Pruefung, damit kein dritter Name mehr hineinkommt.

UPDATE public.accounting_accounts SET class = CASE upper(class)
    WHEN 'AKTIVEN' THEN 'ASSET' WHEN 'PASSIVEN' THEN 'LIABILITY'
    WHEN 'ERTRAG' THEN 'REVENUE' WHEN 'AUFWAND' THEN 'EXPENSE' ELSE upper(class) END
 WHERE class IS DISTINCT FROM CASE upper(class)
    WHEN 'AKTIVEN' THEN 'ASSET' WHEN 'PASSIVEN' THEN 'LIABILITY'
    WHEN 'ERTRAG' THEN 'REVENUE' WHEN 'AUFWAND' THEN 'EXPENSE' ELSE upper(class) END;

DO $$
DECLARE v_def text; v_neu text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'verein_einrichten';
  IF v_def IS NULL THEN RETURN; END IF;
  v_neu := replace(replace(replace(replace(v_def,
             '''AKTIVEN''', '''ASSET'''), '''PASSIVEN''', '''LIABILITY'''),
             '''ERTRAG''', '''REVENUE'''), '''AUFWAND''', '''EXPENSE''');
  IF v_neu <> v_def THEN EXECUTE v_neu; END IF;
END $$;

ALTER TABLE public.accounting_accounts DROP CONSTRAINT IF EXISTS accounting_accounts_class_check;
ALTER TABLE public.accounting_accounts ADD CONSTRAINT accounting_accounts_class_check
  CHECK (class IN ('ASSET', 'LIABILITY', 'REVENUE', 'EXPENSE'));

-- Die Demo-Vorlage traegt den alten Stand; neu speichern, sonst kaemen die
-- deutschen Namen mit dem naechsten Zuruecksetzen zurueck (und scheiterten
-- jetzt an der Pruefung).
DO $$
DECLARE v_betreiber text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;
  SELECT email INTO v_betreiber FROM public.platform_admins LIMIT 1;
  PERFORM set_config('request.jwt.claims', json_build_object('email', v_betreiber, 'role', 'authenticated')::text, true);
  PERFORM public.demo_vorlage_speichern();
  PERFORM set_config('request.jwt.claims', '', true);
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'verein_einrichten' AND prosrc ~ '''(AKTIVEN|PASSIVEN|ERTRAG|AUFWAND)''') THEN
    RAISE EXCEPTION 'verein_einrichten schreibt noch deutsche Klassen';
  END IF;
END $$;
