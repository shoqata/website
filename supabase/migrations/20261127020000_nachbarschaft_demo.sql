-- Beispiel-Vorstellungen fuer den Demo-Verein (und dieselben in der
-- Vorlage des Zuruecksetzens). Gebiete um ein Dorf in Kosovo herum,
-- frei erfunden wie alle Demo-Daten.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.neighborhoods WHERE id = 'demo-lagje-1' AND "tenantId" = 'demo') THEN RETURN; END IF;
  INSERT INTO public.nachbarschaft_profil (nachbarschaft, "tenantId", sichtbar, text, gebiet, ort, geaendert_von) VALUES
  ('demo-lagje-2', 'demo', true,
   '{"de":"Die Lagjja e Epërme liegt am Hang über dem Dorf, rund um den alten Brunnen. Hier stehen die ältesten Häuser, und von hier stammen viele der Familien, die heute in der Schweiz leben.\n\nIm Sommer treffen sich die Nachbarn am Brunnen; die neue Wasserleitung von 2001 wurde von hier aus geplant.","sq":"Lagjja e Epërme shtrihet në shpatin mbi fshat, rreth kroit të vjetër. Këtu janë shtëpitë më të vjetra dhe prej këtu vijnë shumë nga familjet që sot jetojnë në Zvicër.","en":"The upper neighbourhood lies on the slope above the village, around the old well. The oldest houses stand here."}',
   '[[42.5452,21.5752],[42.5466,21.5801],[42.5449,21.5843],[42.5428,21.5812],[42.5431,21.5764]]', 'Oberdorf, beim alten Brunnen', 'Demo'),
  ('demo-lagje-1', 'demo', true,
   '{"de":"Die Lagjja e Poshtme zieht sich entlang der Hauptstrasse bis zur Schule. Hier sind Laden, Moschee und Sportplatz — das Herz des Dorfalltags.\n\nDie renovierte Schule und die Strassenbeleuchtung sind hier zu sehen.","sq":"Lagjja e Poshtme shtrihet përgjatë rrugës kryesore deri te shkolla. Këtu janë dyqani, xhamia dhe fusha sportive.","en":"The lower neighbourhood runs along the main road to the school — the heart of everyday village life."}',
   '[[42.5428,21.5812],[42.5449,21.5843],[42.5422,21.5889],[42.5398,21.5861],[42.5404,21.5819]]', 'Entlang der Hauptstrasse', 'Demo'),
  ('demo-lagje-3', 'demo', true,
   '{"de":"Die Lagjja e Re ist in den letzten zwanzig Jahren entstanden, als Familien aus der Diaspora am Dorfrand neue Häuser bauten. Junge Familien, viele Kinder und der neue Spielplatz.","sq":"Lagjja e Re u krijua në njëzet vitet e fundit, kur familjet e diasporës ndërtuan shtëpi të reja në skaj të fshatit.","en":"The new neighbourhood grew over the last twenty years as diaspora families built new houses at the edge of the village."}',
   '[[42.5431,21.5764],[42.5428,21.5812],[42.5404,21.5819],[42.5396,21.5772],[42.5412,21.5748]]', 'Westlicher Dorfrand', 'Demo')
  ON CONFLICT (nachbarschaft) DO NOTHING;

  IF EXISTS (SELECT 1 FROM public.demo_vorlage) THEN
    DELETE FROM public.demo_vorlage WHERE tabelle = 'nachbarschaft_profil';
    INSERT INTO public.demo_vorlage (tabelle, zeile)
    SELECT 'nachbarschaft_profil', to_jsonb(p) FROM public.nachbarschaft_profil p WHERE p."tenantId" = 'demo';
  END IF;
END $$;
