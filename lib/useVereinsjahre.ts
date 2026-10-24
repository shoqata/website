import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Das Arbeitsjahr des Vereins und die waehlbaren Jahre (vereinsjahre()).
//
// Arbeitsjahr ist das Kalenderjahr -- oder ein spaeteres, sobald es
// eroeffnet ist (mit dem Jahresabschluss oder im Jahreswechsel). Vorher
// rechnete jede Ansicht mit new Date().getFullYear(): ein im Dezember
// eroeffnetes 2027 war nirgends waehlbar, bis der Kalender umsprang.
//
// Bis die Antwort da ist, gilt das Kalenderjahr; neuLaden() nach einem
// Abschluss oder einer Eroeffnung.
export type Vereinsjahre = { aktuell: number; jahre: number[]; geschlossen: number[]; offen: number[] };

const kalender = () => new Date().getFullYear();
const grund = (): Vereinsjahre => ({
  aktuell: kalender(), jahre: Array.from({ length: 5 }, (_, i) => kalender() - i), geschlossen: [], offen: [],
});

const hoerer = new Set<(v: Vereinsjahre) => void>();
let letzter: Vereinsjahre | null = null;

export async function vereinsjahreNeuLaden(): Promise<Vereinsjahre> {
  try {
    const { data, error } = await supabase.rpc('vereinsjahre');
    if (!error && data && typeof (data as any).aktuell === 'number') {
      const d: any = data;
      letzter = { aktuell: d.aktuell, jahre: d.jahre ?? grund().jahre,
                  geschlossen: d.geschlossen ?? [], offen: d.offen ?? [] };
      hoerer.forEach(h => h(letzter!));
    }
  } catch { /* dann bleibt es beim Kalenderjahr */ }
  return letzter ?? grund();
}

export function useVereinsjahre(): Vereinsjahre & { geladen: boolean } {
  const [v, setV] = useState<Vereinsjahre | null>(letzter);
  useEffect(() => {
    hoerer.add(setV);
    if (!letzter) vereinsjahreNeuLaden();
    return () => { hoerer.delete(setV); };
  }, []);
  return { ...(v ?? grund()), geladen: !!v };
}

// Fuer eine Jahresauswahl: das Arbeitsjahr vorwaehlen, sobald bekannt --
// aber nur, solange niemand selbst gewaehlt hat.
export function useJahresauswahl(): [number, (j: number) => void, Vereinsjahre & { geladen: boolean }] {
  const vj = useVereinsjahre();
  const [jahr, setJahr] = useState<number>(vj.aktuell);
  const [selbst, setSelbst] = useState(false);
  useEffect(() => { if (!selbst) setJahr(vj.aktuell); }, [vj.aktuell, selbst]);
  return [jahr, (j: number) => { setSelbst(true); setJahr(j); }, vj];
}
