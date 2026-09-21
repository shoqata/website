-- "Dorf-Livestream" hiess eine Seite, die gar keinen Stream zeigt: sie
-- listet Vorhaben im Dorf nach Bereichen (Gesundheit, Wasser, Energie,
-- Bildung) und liest dafuer die events-Tabelle. Kein Video, keine Kamera,
-- kein iframe im ganzen Code -- der Name fuehrte in die Irre. Sie heisst
-- im Katalog deshalb DORFLEBEN.
--
-- Der echte Kamera-Stream wird ein eigenes Modul. Es steht auf
-- EINGESTELLT, weil es noch nicht gebaut ist -- ein Katalogeintrag fuer
-- etwas, das es nicht gibt, waere genau die Sorte Versprechen, die das
-- Social-Modul schon einmal gemacht hat.
INSERT INTO public.modules
  (schluessel, name_de, name_sq, name_en, beschreibung_de, beschreibung_sq, beschreibung_en,
   ist_kern, status, braucht_einrichtung, reihenfolge)
VALUES
  ('LIVESTREAM','Dorf-Livestream','Transmetim i drejtpërdrejtë','Village livestream',
   'Kameras im Dorf als Livestream auf der Vereinsseite.',
   'Kamerat në fshat si transmetim i drejtpërdrejtë në faqen e shoqatës.',
   'Cameras in the village as a livestream on the association page.',
   false,'EINGESTELLT',true,120)
ON CONFLICT (schluessel) DO UPDATE SET
  name_de = excluded.name_de, name_sq = excluded.name_sq, name_en = excluded.name_en,
  beschreibung_de = excluded.beschreibung_de, beschreibung_sq = excluded.beschreibung_sq,
  beschreibung_en = excluded.beschreibung_en, status = excluded.status,
  braucht_einrichtung = excluded.braucht_einrichtung, reihenfolge = excluded.reihenfolge;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schluessel, name_de, status, ist_kern FROM public.modules
            WHERE status = 'EINGESTELLT' OR schluessel IN ('DORFLEBEN','LIVESTREAM')
            ORDER BY reihenfolge LOOP
    RAISE NOTICE '  % | % | %', rpad(r.schluessel,12), rpad(r.name_de,26), r.status;
  END LOOP;
END $$;
