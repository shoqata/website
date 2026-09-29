import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Soll die Spendenseite erscheinen?
//
// Entschieden wird das in der Datenbank (spendenseite_sichtbar): Modul
// gebucht, Stellung des Vereins, und bei "nur bei laufendem Aufruf" auch,
// ob gerade einer laeuft. Hier nur abholen -- eine zweite Rechnung im
// Browser liefe frueher oder spaeter auseinander.
//
// null heisst: noch nicht bekannt. Aufrufer zeigen dann weder Verweis noch
// Seite, warten aber auch nicht mit dem Rest der Anwendung darauf.
export function useSpendenseiteSichtbar(): boolean | null {
  const [sichtbar, setSichtbar] = useState<boolean | null>(null);

  useEffect(() => {
    let lebt = true;
    supabase.rpc('spendenseite_sichtbar').then(({ data, error }) => {
      if (!lebt) return;
      setSichtbar(error ? false : data === true);
    });
    return () => { lebt = false; };
  }, []);

  return sichtbar;
}
