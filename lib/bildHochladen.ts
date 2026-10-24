import { storage } from '../services/datenzugriff';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';

// Ein Bild in den Speicher laden und seine oeffentliche Adresse holen --
// dieselben drei Schritte wie im Website-Editor, an einer Stelle.
// Leerzeichen und Umlaute im Dateinamen ergaeben Adressen, die je nach
// Browser anders kodiert werden; darum wird der Name vereinfacht.
export async function bildHochladen(datei: File, ordner: string): Promise<string> {
  const name = datei.name.toLowerCase().replace(/[^a-z0-9.]+/g, '-').replace(/^-+|-+$/g, '') || 'bild';
  const ziel = ref(storage, `${ordner}/${Date.now()}_${name}`);
  const stand = await uploadBytes(ziel, datei);
  return getDownloadURL(stand.ref);
}
