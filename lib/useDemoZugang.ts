import { useEffect, useState } from 'react';
import { supabase } from '../services/supabase-bridge';
import { DEMO_VEREIN } from './useDemoRolle';

// Der eigene Testzugang, wenn man als Interessent im Demoverein angemeldet
// ist -- sonst null. Die Datenbank gibt nur die eigene Zeile heraus
// (mein_demozugang); fuer alle anderen Konten ist die Antwort leer.
export type DemoZugang = { bis: Date; tage: number; flokyUebrig: number };

export function useDemoZugang(angemeldet: boolean, verein: string | null): DemoZugang | null {
  const [zugang, setZugang] = useState<DemoZugang | null>(null);

  useEffect(() => {
    if (!angemeldet || verein !== DEMO_VEREIN || !supabase) { setZugang(null); return; }
    let aktiv = true;
    supabase.rpc('mein_demozugang').then(({ data, error }) => {
      if (!aktiv) return;
      const z = !error && Array.isArray(data) ? data[0] : null;
      if (!z) { setZugang(null); return; }
      const bis = new Date(z.gueltig_bis);
      // Aufgerundet: wer heute Abend ablaeuft, hat noch "1 Tag", nicht 0.
      const tage = Math.max(0, Math.ceil((bis.getTime() - Date.now()) / 86_400_000));
      setZugang({ bis, tage, flokyUebrig: z.floky_uebrig });
    });
    return () => { aktiv = false; };
  }, [angemeldet, verein]);

  return zugang;
}

export const restzeit = (z: DemoZugang) =>
  z.tage <= 0 ? 'Testzugang läuft heute ab'
    : z.tage === 1 ? 'Testzugang: noch 1 Tag'
    : `Testzugang: noch ${z.tage} Tage`;
