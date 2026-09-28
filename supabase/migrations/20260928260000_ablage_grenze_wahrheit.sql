-- Die Grenze an der Ablage auf das stellen, was wirklich gilt.
--
-- Gemessen am 28.09.2026 mit echten Dateien: 44 MB gehen durch, 57 MB
-- werden mit 413 EntityTooLarge abgewiesen. Die 300 MB, die ich beim
-- Anlegen eingetragen hatte, sind wirkungslos -- das Projekt begrenzt
-- Uploads global auf 50 MB, und eine Ablage kann darueber nicht hinaus.
--
-- Eine Zahl in der Tabelle, die der Server nicht einhaelt, ist schlimmer
-- als eine kleine Zahl: der naechste liest 300 MB, verspricht sie in der
-- Oberflaeche, und ein Verein merkt es erst, wenn ein langer Upload
-- abbricht. Die Grenze laesst sich in den Projekteinstellungen von
-- Supabase anheben; das kann nur der Inhaber.
UPDATE storage.buckets SET file_size_limit = 52428800 WHERE id = 'videos';

DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT id, file_size_limit/1024/1024 AS mb FROM storage.buckets ORDER BY id LOOP
    RAISE NOTICE '  % -> % MB', rpad(r.id,10), r.mb;
  END LOOP;
END $$;
