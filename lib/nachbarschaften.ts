import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Die Vorstellungen der Nachbarschaften (nachbarschaft_profil). Nach aussen
// gehen nur die eingeschalteten, ohne Namen von Mitgliedern oder
// Kontaktangaben -- nachbarschaften_oeffentlich() gibt nichts anderes her.

export type Punkt = [number, number];
export type NbBild = { url: string; text?: { de?: string; sq?: string; en?: string } };
export type NbOeffentlich = {
  id: string; name: string; city: string | null; text: any; bilder: NbBild[];
  gebiet: Punkt[]; ort: string | null; mitglieder: number;
};

export function useNachbarschaftenOeffentlich(): NbOeffentlich[] | null {
  const [liste, setListe] = useState<NbOeffentlich[] | null>(null);
  useEffect(() => {
    let lebt = true;
    supabase.rpc('nachbarschaften_oeffentlich').then(({ data, error }) => {
      if (lebt) setListe(error ? [] : ((data as NbOeffentlich[]) ?? []));
    }, () => { if (lebt) setListe([]); });
    return () => { lebt = false; };
  }, []);
  return liste;
}

export const hatFlaeche = (g: Punkt[] | null | undefined) => Array.isArray(g) && g.length >= 3;
