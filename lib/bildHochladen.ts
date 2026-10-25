import { vereinsbildHochladen, type BildZweck } from './bildPruefen';

// Website-Bild hochladen: laeuft ueber die Pruefung (bild-pruefen), die das
// Bild aus seinen Pixeln neu erzeugt -- Skripte, Metadaten und angehaengte
// Daten bleiben dabei zurueck. Der Ordnername von frueher ist der Zweck.
export async function bildHochladen(datei: File, ordner: BildZweck): Promise<string> {
  return vereinsbildHochladen(datei, ordner);
}
