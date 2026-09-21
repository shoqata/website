import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Welche Module hat dieser Verein?
//
// Die Zeilenregeln sperren die Daten bereits -- ein abgeschaltetes Modul
// liefert 0 Zeilen. Das genuegt fuer die Sicherheit, nicht aber fuer die
// Bedienung: ein Reiter, der eine leere Liste zeigt, sieht nach Fehler aus
// statt nach "nicht gebucht".
//
// Gefragt wird dieselbe Stelle, die auch die Zeilenregeln benutzen
// (marktplatz_uebersicht rechnet mit derselben Regel wie modul_aktiv). Die
// Oberflaeche bekommt so keine eigene Vorstellung davon, was laeuft.
export function useModule() {
  const [aktive, setAktive] = useState<Set<string> | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      try {
        const { data, error } = await supabase.rpc('marktplatz_uebersicht');
        if (!lebt) return;
        if (error) throw error;
        setAktive(new Set((data ?? []).filter((z: any) => z.aktiv).map((z: any) => z.schluessel)));
      } catch {
        // Wer den Marktplatz nicht abfragen darf -- etwa ein gewoehnliches
        // Mitglied -- bekommt hier nichts. Dann wird nichts ausgeblendet:
        // die Zeilenregeln entscheiden ohnehin, und ein leeres Menue waere
        // schlimmer als ein vollstaendiges.
        if (lebt) setAktive(null);
      }
    })();
    return () => { lebt = false; };
  }, []);

  return {
    // Solange nichts bekannt ist, gilt alles als vorhanden -- sonst
    // flackerten beim Laden die halben Menuepunkte weg.
    aktiv: (schluessel: string) => aktive === null || aktive.has(schluessel),
    geladen: aktive !== null,
  };
}
