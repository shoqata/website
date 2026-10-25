import { useCallback, useEffect, useMemo, useState } from 'react';
import { supabase } from '../services/supabase-bridge';
import { netzAus, type Kante } from './verwandtschaft';
import type { Knoten } from '../components/Familienbaum';

// Gemeinsamer Zugang zum Stammbaum -- fuer die Stammbaum-Seite und den
// Reiter "Familie" beim Mitglied. Beide lesen dieselbe Uebersicht und legen
// Beziehungen auf demselben Weg an, damit sich nirgends eine zweite Regel
// einschleicht, wer Elternteil von wem ist.

export type Bezug = { id: string; name: string };
export type Person = {
  familie: string; familienname: string | null; familie_id: string | null;
  person: string; name: string; nachname: string | null;
  nachbarschaft: string | null; geburtsdatum: string | null;
  eltern: Bezug[]; partner: Bezug[]; kinder: Bezug[]; geschwister: Bezug[];
  anrede?: string | null;
};
export type Art = 'ELTERNTEIL' | 'PARTNER' | 'GESCHWISTER';
// Aus Sicht der Person, bei der man steht: "füge ihr einen Elternteil hinzu".
export type Rolle = 'ELTERNTEIL' | 'PARTNER' | 'KIND' | 'GESCHWISTER';

// Anrede 'Znj.' (Frau) / 'Z.' (Herr). Unbekannt bleibt unbekannt.
export const weiblich = (anrede?: string | null): boolean | null =>
  anrede === 'Znj.' ? true : anrede === 'Z.' ? false : null;

export function useStammbaum() {
  const [leute, setLeute] = useState<Person[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [arbeitet, setArbeitet] = useState(false);

  const laden = useCallback(async () => {
    try {
      const { data, error } = await supabase.rpc('familien_uebersicht');
      if (error) throw error;
      setLeute(data ?? []);
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setLaedt(false);
    }
  }, []);
  useEffect(() => { laden(); }, [laden]);

  const nachId = useMemo(() => new Map(leute.map(l => [l.person, l])), [leute]);
  const namen = useMemo(() => new Map(leute.map(l => [l.person, l.name])), [leute]);
  const anreden = useMemo(() => new Map(leute.map(l => [l.person, l.anrede ?? null])), [leute]);

  // Die Kanten aus der Uebersicht zurueckgewinnen -- die Verwandtschafts-
  // rechnung arbeitet auf Kanten, die Anzeige auf zusammengefassten Listen.
  const kanten: Kante[] = useMemo(() => {
    const raus: Kante[] = [];
    const gesehen = new Set<string>();
    for (const p of leute) {
      for (const e of p.eltern) raus.push({ von: e.id, nach: p.person, art: 'ELTERNTEIL' });
      for (const [art, liste] of [['PARTNER', p.partner], ['GESCHWISTER', p.geschwister ?? []]] as const) {
        for (const q of liste) {
          const k = art + [p.person, q.id].sort().join('|');
          if (gesehen.has(k)) continue;
          gesehen.add(k);
          raus.push({ von: p.person, nach: q.id, art });
        }
      }
    }
    return raus;
  }, [leute]);
  const netz = useMemo(() => netzAus(kanten), [kanten]);

  const familieVon = (id: string) => {
    const f = nachId.get(id)?.familie;
    return f ? leute.filter(l => l.familie === f) : [];
  };

  const alsKnoten = (ids: string[]): Knoten[] => {
    const drin = new Set(ids);
    return ids.map(id => nachId.get(id)).filter((p): p is Person => !!p).map(p => ({
      person: p.person, name: p.name, geburtsdatum: p.geburtsdatum, anrede: p.anrede ?? null,
      eltern: p.eltern.filter(e => drin.has(e.id)),
      partner: p.partner.filter(q => drin.has(q.id)),
      kinder: p.kinder.filter(k => drin.has(k.id)),
      geschwister: (p.geschwister ?? []).filter(g => drin.has(g.id)),
    }));
  };

  const ausfuehren = async (schritt: () => PromiseLike<{ error: any }>) => {
    setArbeitet(true); setFehler(null);
    try {
      const { error } = await schritt();
      if (error) throw error;
      await laden();
      return true;
    } catch (e: any) {
      setFehler(lesbar(e?.message ?? String(e)));
      return false;
    } finally {
      setArbeitet(false);
    }
  };

  // bei: die Person, bei der man steht; wer: die hinzukommende.
  const verbinden = (bei: string, rolle: Rolle, wer: string) => {
    const zeile =
      rolle === 'ELTERNTEIL' ? { von: wer, nach: bei, art: 'ELTERNTEIL' } :
      rolle === 'KIND'       ? { von: bei, nach: wer, art: 'ELTERNTEIL' } :
                               { von: bei, nach: wer, art: rolle };
    return ausfuehren(() => supabase.from('family_links').insert(zeile));
  };

  const loesen = (a: string, b: string, art: Art) => ausfuehren(() => {
    const q = supabase.from('family_links').delete().eq('art', art);
    // Partner und Geschwister sind ungerichtet -- gespeichert ist nur eine
    // der beiden Richtungen, geloest werden muss deshalb beides.
    return art === 'ELTERNTEIL'
      ? q.eq('von', a).eq('nach', b)
      : q.or(`and(von.eq.${a},nach.eq.${b}),and(von.eq.${b},nach.eq.${a})`);
  });

  // Alle Beziehungen einer Person auf einmal; der Familienname wandert mit.
  const herausnehmen = (id: string) =>
    ausfuehren(() => supabase.rpc('stammbaum_person_loesen', { p_person: id }));

  const benennen = (anker: string, name: string, id: string | null) => ausfuehren(() => id
    ? supabase.from('families').update({ name: name.trim() }).eq('id', id)
    : supabase.from('families').insert({ anker, name: name.trim() }));

  return {
    leute, laedt, fehler, setFehler, arbeitet, laden,
    nachId, namen, anreden, kanten, netz, familieVon, alsKnoten,
    verbinden, loesen, herausnehmen, benennen,
  };
}

// Die Meldungen der Datenbank sind fuer Entwickler geschrieben.
function lesbar(m: string): string {
  if (/family_links_einmalig|partner_einmalig|geschwister_einmalig|duplicate key/i.test(m))
    return 'Diese Beziehung ist schon erfasst.';
  if (/Kreis/i.test(m)) return 'Das geht nicht: die Person wäre dann ihr eigener Vorfahre.';
  if (/nicht_selbst/i.test(m)) return 'Eine Person kann nicht mit sich selbst verwandt sein.';
  return m;
}

// Die Beziehungen einer Person, wie sie gespeichert sind -- jede einzeln
// loesbar. a/b sind die Argumente fuer loesen().
export function direkteBeziehungen(p: Person) {
  return [
    ...p.eltern.map(e => ({ ...e, rolle: 'ELTERNTEIL' as Rolle, art: 'ELTERNTEIL' as Art, a: e.id, b: p.person })),
    ...p.partner.map(q => ({ ...q, rolle: 'PARTNER' as Rolle, art: 'PARTNER' as Art, a: p.person, b: q.id })),
    ...(p.geschwister ?? []).map(g => ({ ...g, rolle: 'GESCHWISTER' as Rolle, art: 'GESCHWISTER' as Art, a: p.person, b: g.id })),
    ...p.kinder.map(k => ({ ...k, rolle: 'KIND' as Rolle, art: 'ELTERNTEIL' as Art, a: p.person, b: k.id })),
  ];
}
