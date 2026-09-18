-- Schreibt die Anwendung noch irgendwo in Tabellen, die es nicht gibt?
--
-- Genau daran scheiterte der E-Mail-Versand monatelang unbemerkt: der Code
-- sprach eine Tabelle 'mail' an, die es nach der Umstellung nicht mehr gab,
-- und der Fehler wurde verschluckt. Dieselbe Pruefung fuer alle 24 Sammlungen,
-- die im Code vorkommen.
DO $$
DECLARE
  benutzt text[] := ARRAY[
    'accounting_accounts','accounting_journal','board_meetings','board_members',
    'event_registrations','events','expenses','inquiries','mail_queue',
    'neighborhoods','news','payment_reports','payments','platform_invoices',
    'platform_leads','platform_support','polls','public_members',
    'security_logs','sponsors','tasks','tenant_domains','tenants','users'
  ];
  t text; v_da boolean; v_fehlen int := 0; v_n int; r record;
BEGIN
  RAISE NOTICE '=== Vom Code angesprochen, aber nicht vorhanden ===';
  FOREACH t IN ARRAY benutzt LOOP
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
       WHERE table_schema='public' AND table_name=t
      UNION ALL
      SELECT 1 FROM information_schema.views
       WHERE table_schema='public' AND table_name=t
    ) INTO v_da;
    IF NOT v_da THEN
      RAISE NOTICE '  FEHLT: %', t;
      v_fehlen := v_fehlen + 1;
    END IF;
  END LOOP;
  IF v_fehlen = 0 THEN RAISE NOTICE '  keine -- alle 24 vorhanden'; END IF;

  -- Tabellen ohne Zugriffsschutz waeren die andere Richtung desselben Problems.
  RAISE NOTICE '=== Tabellen ohne aktivierte Zugriffsregeln ===';
  v_n := 0;
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='r' AND NOT c.relrowsecurity
            ORDER BY c.relname LOOP
    RAISE NOTICE '  %', r.relname;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; END IF;

  -- Und Tabellen mit aktiviertem Schutz, aber ohne eine einzige Regel: dort
  -- kommt niemand mehr heran, was sich als leere Ansicht zeigt.
  RAISE NOTICE '=== Zugriffsregeln aktiv, aber keine Regel definiert ===';
  v_n := 0;
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='public' AND c.relkind='r' AND c.relrowsecurity
              AND NOT EXISTS (SELECT 1 FROM pg_policies p
                               WHERE p.schemaname='public' AND p.tablename=c.relname)
            ORDER BY c.relname LOOP
    RAISE NOTICE '  % -- unerreichbar', r.relname;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN RAISE NOTICE '  keine'; END IF;
END $$;
