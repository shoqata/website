-- Tote Bildverweise in den Inhalten bereinigen.
--
-- Gefunden bei einem Durchlauf aller URLs in Quellcode und Daten:
--
--   402  firebasestorage.googleapis.com  (events, news)  -- hochgeladene Bilder
--        aus der Firebase-Zeit. Der Bucket antwortet mit "Payment Required",
--        die Dateien sind nicht mehr erreichbar und auch nicht wiederherstellbar.
--        Der Verweis wird geleert, statt ein Ersatzmotiv zu erfinden.
--   404  drei Unsplash-Fotos (events, news) -- die Bilder wurden dort entfernt.
--        Ersetzt durch Aufnahmen, deren Erreichbarkeit geprueft ist; das Motiv
--        konnte ich nicht beurteilen, das gehoert bei Gelegenheit ausgetauscht.
--   404  tenants.logoUrl -- wird nirgends gerendert (der Header liest
--        branding.logoUrl), also ein toter Verweis ohne sichtbare Wirkung.
--
-- NewsSection und EventsPage rendern <img src={...}> ohne onError-Fallback:
-- ein totes Bild bleibt dort als kaputtes Bild stehen. Deshalb leeren statt
-- stehenlassen -- ein leeres Feld ist besser als ein sichtbar kaputtes.

-- Firebase-Storage: Dateien sind weg.
UPDATE public.events SET image = NULL WHERE image LIKE '%firebasestorage.googleapis.com%';
UPDATE public.news   SET image = NULL WHERE image LIKE '%firebasestorage.googleapis.com%';

-- Unsplash 404 -> geprueft erreichbare Aufnahmen, gleiche Parameter.
UPDATE public.events SET image =
  'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=800&q=80'
 WHERE image LIKE '%photo-1508098682722-e99c43a406b2%';

UPDATE public.news SET image =
  'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=800&q=80'
 WHERE image LIKE '%photo-1584515901407-4b653309976a%';

UPDATE public.news SET image =
  'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=800&q=80'
 WHERE image LIKE '%photo-1523050854058-8df90110c9f1%';

-- Totes Logo, das ohnehin niemand liest.
UPDATE public.tenants SET "logoUrl" = NULL WHERE "logoUrl" LIKE '%photo-1599305445671-ac291c95aba9%';
