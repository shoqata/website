-- Zugriffsregeln fuer den Dateispeicher.
--
-- Der Bucket 'uploads' existiert, auf storage.objects ist der Zugriffsschutz
-- aktiv -- und es gibt keine einzige Regel. Das bedeutet: alles verboten.
-- Jeder Bilderupload der Anwendung scheiterte, an zehn Stellen quer durch den
-- Adminbereich: Belege zu Ausgaben, Fotos des Vorstands, Bilder der Website,
-- Mitgliederfotos, Belege der Vertreter. Dass im Bucket null Dateien liegen,
-- bestaetigt, dass nie einer durchkam.
--
-- Derselbe Fehlertyp wie bei der Tabelle 'mail': etwas aus der Zeit vor der
-- Umstellung fehlt, der Fehler wird verschluckt, und der Knopf bleibt
-- wirkungslos, ohne dass jemand erfaehrt warum.

-- Lesen: der Bucket ist oeffentlich, die Bilder stehen ohnehin unter einer
-- offenen Adresse in der Website. Eine Leseregel hier macht nichts zugaenglich,
-- was es nicht schon waere, sorgt aber dafuer, dass die Anwendung Dateien auch
-- auflisten kann.
DROP POLICY IF EXISTS uploads_read ON storage.objects;
CREATE POLICY uploads_read ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'uploads');

-- Hochladen: nur angemeldet. Ein nicht angemeldeter Besucher hat in diesem
-- Speicher nichts abzulegen.
DROP POLICY IF EXISTS uploads_insert ON storage.objects;
CREATE POLICY uploads_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'uploads');

-- Ersetzen und Loeschen: die eigene Datei, oder die Geschaeftsfuehrung.
-- uploadBytes schreibt mit upsert, deshalb braucht es auch UPDATE -- sonst
-- scheitert jedes erneute Hochladen unter demselben Namen.
DROP POLICY IF EXISTS uploads_update ON storage.objects;
CREATE POLICY uploads_update ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'uploads' AND (owner = auth.uid() OR public.is_member_manager()))
  WITH CHECK (bucket_id = 'uploads');

DROP POLICY IF EXISTS uploads_delete ON storage.objects;
CREATE POLICY uploads_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'uploads' AND (owner = auth.uid() OR public.is_member_manager()));

-- Grenzen am Bucket statt in der Anwendung: was hier nicht hineinpasst, kommt
-- gar nicht erst an. Ein veraenderter Client hilft nicht daran vorbei.
UPDATE storage.buckets
   SET file_size_limit = 5242880,  -- 5 MB
       allowed_mime_types = ARRAY[
         'image/jpeg','image/png','image/webp','image/gif','image/heic','application/pdf'
       ]
 WHERE name = 'uploads';

DO $$
DECLARE r record; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM pg_policies WHERE schemaname='storage' AND tablename='objects';
  RAISE NOTICE 'Regeln auf storage.objects jetzt: %', v_n;
  FOR r IN SELECT policyname, cmd FROM pg_policies
            WHERE schemaname='storage' AND tablename='objects' ORDER BY cmd, policyname LOOP
    RAISE NOTICE '  % [%]', r.policyname, r.cmd;
  END LOOP;

  FOR r IN SELECT name, public, file_size_limit, allowed_mime_types FROM storage.buckets LOOP
    RAISE NOTICE 'Bucket %: oeffentlich %, Hoechstgroesse % Byte, erlaubte Typen %',
      r.name, r.public, r.file_size_limit, r.allowed_mime_types;
  END LOOP;
END $$;
