import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

const SPEICHER = 'startseite-variante';

// Welche Startseite bekommt dieser Besucher?
//
// Entschieden wird das in der Datenbank, nicht hier: startseite_variante()
// verlangt, dass BEIDES stimmt -- das Modul "Startseite Premium" ist fuer
// diesen Verein aktiv, und der Verein hat umgeschaltet. Eine Pruefung im
// Browser koennte ein Verein durch einen Eintrag in settings umgehen und
// die kostenpflichtige Seite ohne Buchung bekommen.
//
// Der zuletzt bekannte Wert liegt im Speicher, damit beim naechsten Besuch
// nicht erst die Standardseite erscheint und dann wegspringt. Beim allerersten
// Besuch ist die Antwort null -- Aufrufer duerfen sich dann auf keine der
// beiden festlegen, sonst blitzt die falsche Seite auf. Dieselbe Lehre wie
// bei useIstPlattformDomain.
export function useStartseiteVariante(): 'STANDARD' | 'PREMIUM' | null {
  const [variante, setVariante] = useState<'STANDARD' | 'PREMIUM' | null>(() => {
    try {
      const w = localStorage.getItem(SPEICHER);
      return w === 'PREMIUM' || w === 'STANDARD' ? w : null;
    } catch { return null; }
  });

  useEffect(() => {
    let lebt = true;
    (async () => {
      try {
        const { data, error } = await supabase.rpc('startseite_variante');
        if (!lebt || error) return;
        const w = data === 'PREMIUM' ? 'PREMIUM' : 'STANDARD';
        setVariante(w);
        try { localStorage.setItem(SPEICHER, w); } catch { /* egal */ }
      } catch {
        // Keine Antwort heisst Standard. Die erzaehlende Seite ist die
        // Zugabe; im Zweifel bekommt der Besucher die Seite, die es
        // ueberall gibt.
        if (lebt) setVariante('STANDARD');
      }
    })();
    return () => { lebt = false; };
  }, []);

  return variante;
}
