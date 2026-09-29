import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Welche Module hat der Verein dieser Adresse -- aus der Sicht eines
// Besuchers?
//
// useModule() fragt marktplatz_uebersicht(), und das darf nur der Vorstand
// lesen. Fuer die Navigation genuegt das nicht: ein Verweis auf die
// Spendenseite gehoert in die Leiste, wenn der Verein das Modul hat, und
// sonst nicht -- unabhaengig davon, wer gerade schaut.
//
// Solange die Antwort aussteht, ist sie null. Aufrufer zeigen dann keinen
// Verweis: ein Menuepunkt, der erscheint und wieder verschwindet, ist
// schlimmer als einer, der eine Sekunde spaeter kommt.
export function useOeffentlicheModule(): Set<string> | null {
  const [module, setModule] = useState<Set<string> | null>(null);

  useEffect(() => {
    let lebt = true;
    supabase.rpc('module_oeffentlich').then(({ data, error }) => {
      if (!lebt) return;
      if (error) { setModule(new Set()); return; }
      setModule(new Set(((data as any[]) || []).map(z => z.schluessel)));
    });
    return () => { lebt = false; };
  }, []);

  return module;
}
