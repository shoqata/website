-- Eine eigene Ablage fuer Videos.
--
-- Die bestehende Ablage "uploads" nimmt nur Bilder und PDF an und begrenzt
-- auf 5 MB. Das ist fuer Mitgliederfotos richtig und fuer Filme unbrauchbar:
-- schon der 15-Sekunden-Test wiegt 2,7 MB, ein Rueckblick ueber eine
-- Veranstaltung ein Vielfaches davon. Beides in einen Topf zu werfen hiesse,
-- entweder die Grenze fuer Fotos aufzuweichen oder Videos auszusperren.
--
-- Hochladen darf nur, wer ohnehin am Verein arbeitet. Lesen darf jeder --
-- ein Video, das auf der oeffentlichen Seite steht, ist oeffentlich.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('videos', 'videos', true, 314572800,
        ARRAY['video/mp4','video/webm','video/quicktime','image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE
  SET public = true,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS videos_read ON storage.objects;
CREATE POLICY videos_read ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'videos');

DROP POLICY IF EXISTS videos_insert ON storage.objects;
CREATE POLICY videos_insert ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'videos' AND public.is_staff());

DROP POLICY IF EXISTS videos_update ON storage.objects;
CREATE POLICY videos_update ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'videos' AND (owner = auth.uid() OR public.is_staff()));

DROP POLICY IF EXISTS videos_delete ON storage.objects;
CREATE POLICY videos_delete ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'videos' AND (owner = auth.uid() OR public.is_staff()));

DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT id, public, file_size_limit/1024/1024 AS mb,
                  array_to_string(allowed_mime_types, ', ') AS typen
             FROM storage.buckets ORDER BY id LOOP
    RAISE NOTICE '  % | oeffentlich=% | % MB | %', rpad(r.id,10), r.public, r.mb, r.typen;
  END LOOP;
END $$;
