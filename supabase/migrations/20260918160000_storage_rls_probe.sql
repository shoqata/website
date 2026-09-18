-- Ist der Zugriffsschutz auf storage.objects aktiv?
--
-- Aktiv ohne eine einzige Regel bedeutet: alles verboten. Dann scheitert jeder
-- Bilderupload -- und in AdminBoard wird der Fehler verschluckt, sodass der
-- Knopf wirkungslos bleibt, ohne dass jemand erfaehrt warum. Dass im Bucket
-- null Dateien liegen, passt zu dieser Vermutung.
DO $$
DECLARE v_rls boolean; v_n int; r record;
BEGIN
  SELECT c.relrowsecurity INTO v_rls
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'storage' AND c.relname = 'objects';
  RAISE NOTICE 'storage.objects: Zugriffsschutz aktiv = %', v_rls;

  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname = 'storage' AND tablename = 'objects';
  RAISE NOTICE 'Regeln darauf: %', v_n;

  IF v_rls AND v_n = 0 THEN
    RAISE NOTICE 'FOLGE: jeder Upload und jeder Zugriff ueber die Anwendung wird abgewiesen.';
  END IF;

  RAISE NOTICE '=== Rechte auf storage.objects ===';
  FOR r IN SELECT grantee, string_agg(privilege_type, ',' ORDER BY privilege_type) AS rechte
             FROM information_schema.role_table_grants
            WHERE table_schema='storage' AND table_name='objects'
              AND grantee IN ('anon','authenticated')
            GROUP BY grantee LOOP
    RAISE NOTICE '  %: %', r.grantee, r.rechte;
  END LOOP;
END $$;
