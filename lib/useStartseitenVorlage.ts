import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

const SPEICHER = 'startseiten-vorlage';

// Die sechs Vorlagen. Die Liste steht auch in der Datenbank
// (startseiten_vorlagen) -- dort entscheidet sie ueber Preis und Sperre,
// hier darueber, was gezeichnet wird. Kennt der Browser einen Schluessel
// nicht, faellt er auf KLASSISCH zurueck statt nichts zu zeigen.
export const VORLAGEN = ['KLASSISCH','MAGAZIN','KOMPAKT',
                         'ERZAEHLUNG','BUEHNE','JOURNAL'] as const;
export type Vorlage = typeof VORLAGEN[number];

const gueltig = (w: any): w is Vorlage => VORLAGEN.includes(w);

// Welche Vorlage bekommt dieser Besucher?
//
// Entschieden wird das in der Datenbank: startseiten_vorlage() verlangt,
// dass der Verein die Vorlage gewaehlt hat UND -- bei den bezahlten -- das
// Modul fuer ihn aktiv ist. Eine Pruefung im Browser koennte ein Verein
// durch einen Eintrag in settings umgehen.
//
// Der zuletzt bekannte Wert liegt im Speicher, damit beim naechsten Besuch
// nicht erst die falsche Vorlage erscheint und dann wegspringt. Beim
// allerersten Besuch ist die Antwort null -- Aufrufer duerfen sich dann auf
// keine festlegen.
export function useStartseitenVorlage(): Vorlage | null {
  const [vorlage, setVorlage] = useState<Vorlage | null>(() => {
    try {
      const w = localStorage.getItem(SPEICHER);
      return gueltig(w) ? w : null;
    } catch { return null; }
  });

  useEffect(() => {
    let lebt = true;
    (async () => {
      try {
        const { data, error } = await supabase.rpc('startseiten_vorlage');
        if (!lebt) return;
        // Bei einem Fehler NICHT einfach zurueckkehren: die Vorlage bliebe
        // dann null, und null heisst beim Aufrufer "noch nicht bekannt" --
        // also Ladekreis, dauerhaft. Genau das passiert, solange die
        // Funktion in der Datenbank fehlt, etwa zwischen dem Ausliefern des
        // Frontends und dem der Migration. Ein Verein ohne Startseite ist
        // schlimmer als einer mit der schlichten.
        const w: Vorlage = !error && gueltig(data) ? data : 'KLASSISCH';
        setVorlage(w);
        // Gemerkt wird nur eine echte Antwort. Sonst machte eine kurze
        // Stoerung aus der bezahlten Vorlage eines Vereins dauerhaft die
        // schlichte -- auch nachdem die Stoerung vorbei ist, denn beim
        // naechsten Besuch zeigte der Merkzettel zuerst wieder KLASSISCH.
        if (!error) { try { localStorage.setItem(SPEICHER, w); } catch { /* egal */ } }
      } catch {
        // Keine Antwort heisst Klassisch. Die erzaehlenden Seiten sind die
        // Zugabe; im Zweifel bekommt der Besucher die, die es ueberall gibt.
        if (lebt) setVorlage('KLASSISCH');
      }
    })();
    return () => { lebt = false; };
  }, []);

  return vorlage;
}
