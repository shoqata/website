-- Zwei Luecken meiner ersten Suche.
--
-- Erstens hatte ich nur collection(db,'X') ausgewertet und damit alle
-- Tabellen uebersehen, die nur ueber doc(db,'X',id) angesprochen werden.
-- Zweitens laedt der Adminbereich Bilder in einen Speicher-Bucket 'uploads' --
-- gibt es den nicht, scheitert jeder Upload, und in AdminBoard wird der
-- Fehler verschluckt. Das ist dasselbe Muster wie bei der Tabelle 'mail'.
DO $$
DECLARE
  nur_doc text[] := ARRAY['fiscal_years','fiscal_budgets','settings','public_settings','board_members'];
  t text; v_da boolean; v_fehlen int := 0; r record; v_n int;
BEGIN
  RAISE NOTICE '=== Nur ueber doc() angesprochen ===';
  FOREACH t IN ARRAY nur_doc LOOP
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=t
      UNION ALL
      SELECT 1 FROM information_schema.views  WHERE table_schema='public' AND table_name=t
    ) INTO v_da;
    IF v_da THEN
      RAISE NOTICE '  % vorhanden', t;
    ELSE
      RAISE NOTICE '  FEHLT: %', t;
      v_fehlen := v_fehlen + 1;
    END IF;
  END LOOP;

  RAISE NOTICE '=== Speicher-Buckets ===';
  v_n := 0;
  FOR r IN SELECT id, name, public FROM storage.buckets ORDER BY name LOOP
    RAISE NOTICE '  % (oeffentlich %)', r.name, r.public;
    v_n := v_n + 1;
  END LOOP;
  IF v_n = 0 THEN
    RAISE NOTICE '  KEINE -- jeder Bilderupload scheitert';
  END IF;

  SELECT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'uploads') INTO v_da;
  RAISE NOTICE 'Bucket "uploads", den der Code verwendet: %',
    CASE WHEN v_da THEN 'vorhanden' ELSE 'FEHLT -- Uploads scheitern' END;

  IF v_da THEN
    SELECT count(*) INTO v_n FROM storage.objects WHERE bucket_id = 'uploads';
    RAISE NOTICE '  darin % Dateien', v_n;
    RAISE NOTICE '=== Regeln auf storage.objects ===';
    FOR r IN SELECT policyname, cmd FROM pg_policies
              WHERE schemaname='storage' AND tablename='objects' ORDER BY cmd LOOP
      RAISE NOTICE '  % [%]', r.policyname, r.cmd;
    END LOOP;
  END IF;
END $$;
