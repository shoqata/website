import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Welches Paket hat der Verein dieser Adresse? Heute nur beim Demoverein
// verschieden (paket_oeffentlich); jeder andere Verein ist VOLL. Solange
// die Antwort aussteht oder die Abfrage scheitert: VOLL -- dann bleibt
// alles, wie es war.
export function usePaket(): 'LIGHT' | 'VOLL' {
  const [paket, setPaket] = useState<'LIGHT' | 'VOLL'>('VOLL');
  useEffect(() => {
    let lebt = true;
    supabase.rpc('paket_oeffentlich').then(({ data, error }) => {
      if (lebt && !error && data === 'LIGHT') setPaket('LIGHT');
    });
    return () => { lebt = false; };
  }, []);
  return paket;
}
