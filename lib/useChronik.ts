import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Die Chronik des Vereins: Eintraege mit Jahr, wahlweise Monat und Tag.
// Gelesen wird ueber die Zeilenregel -- Besucher bekommen nur die
// veroeffentlichten des eigenen Vereins, die Verwaltung auch Entwuerfe.

export type Sprachfeld = { de?: string; sq?: string; en?: string };
export type ChronikEintrag = {
  id: string; jahr: number; monat: number | null; tag: number | null;
  titel: Sprachfeld; text: Sprachfeld; bild: string | null;
  bereich: 'VEREIN' | 'DORF'; meilenstein: boolean;
  status: 'ENTWURF' | 'OEFFENTLICH';
  geaendert_am?: string; geaendert_von?: string | null;
};

const SPALTEN = 'id,jahr,monat,tag,titel,text,bild,bereich,meilenstein,status,geaendert_am,geaendert_von';

// Aelteste zuerst; ohne Monat steht ein Eintrag am Anfang seines Jahres.
export const chronikOrdnung = (a: ChronikEintrag, b: ChronikEintrag) =>
  a.jahr - b.jahr || (a.monat ?? 0) - (b.monat ?? 0) || (a.tag ?? 0) - (b.tag ?? 0);

export async function chronikLaden(nurOeffentlich: boolean): Promise<ChronikEintrag[]> {
  let q = supabase.from('chronik').select(SPALTEN).order('jahr').order('monat', { nullsFirst: true }).limit(500);
  if (nurOeffentlich) q = q.eq('status', 'OEFFENTLICH');
  const { data, error } = await q;
  if (error) throw error;
  return ((data as ChronikEintrag[]) ?? []).sort(chronikOrdnung);
}

export function useChronik(): ChronikEintrag[] | null {
  const [eintraege, setEintraege] = useState<ChronikEintrag[] | null>(null);
  useEffect(() => {
    let lebt = true;
    chronikLaden(true).then(e => { if (lebt) setEintraege(e); }, () => { if (lebt) setEintraege([]); });
    return () => { lebt = false; };
  }, []);
  return eintraege;
}

// "18. Mai 2019", "Mai 2019" oder "2019" -- so genau, wie es bekannt ist.
export function chronikDatum(e: Pick<ChronikEintrag, 'jahr' | 'monat' | 'tag'>, sprache: string): string {
  const gebiet = sprache === 'de' ? 'de-CH' : sprache === 'sq' ? 'sq-AL' : 'en-GB';
  try {
    if (e.monat && e.tag) return new Date(e.jahr, e.monat - 1, e.tag)
      .toLocaleDateString(gebiet, { day: 'numeric', month: 'long', year: 'numeric' });
    if (e.monat) return new Date(e.jahr, e.monat - 1, 1)
      .toLocaleDateString(gebiet, { month: 'long', year: 'numeric' });
  } catch { /* unten */ }
  return String(e.jahr);
}
