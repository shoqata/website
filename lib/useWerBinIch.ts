import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

export type WerBinIch = {
  ist_betreiber: boolean;
  verein: string | null;
  vereinsname: string | null;
  vereinsdomain: string | null;
  rolle: string;
};

// Wer ist angemeldet, und wohin gehoert er?
//
// Massgeblich ist die Datenbank, nicht eine Liste im Quelltext. Vorher
// entschied App.tsx anhand fest eingetragener E-Mail-Adressen und
// behandelte zusaetzlich jede Vereinsrolle SUPER_ADMIN als
// Plattformbetreiber -- damit landete ein Vereinsadministrator, der sich
// auf unityhub.li anmeldet, im Betreiberbereich.
//
// Solange die Antwort aussteht, ist sie null. Aufrufer duerfen dann keine
// der beiden Welten behaupten: lieber kurz warten als die falsche zeigen.
export function useWerBinIch(angemeldet: boolean): WerBinIch | null {
  const [wer, setWer] = useState<WerBinIch | null>(null);

  useEffect(() => {
    if (!angemeldet) { setWer(null); return; }
    let lebt = true;
    (async () => {
      try {
        const { data, error } = await supabase.rpc('wer_bin_ich');
        if (!lebt) return;
        if (error) throw error;
        const z = Array.isArray(data) ? data[0] : data;
        if (z) setWer(z);
      } catch {
        // Bei einem Fehler bleibt es bei "unbekannt". Der Betreiberbereich
        // wird dann nicht geoeffnet -- die Datenbank haelt ihn ohnehin ab,
        // aber die Maske soll ihn erst gar nicht anbieten.
        if (lebt) setWer(null);
      }
    })();
    return () => { lebt = false; };
  }, [angemeldet]);

  return wer;
}
