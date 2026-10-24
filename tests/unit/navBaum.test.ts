import { describe, it, expect } from 'vitest';
import { navBaum, navLayout } from '../../components/kopfzeile';
import { absaetze } from '../../lib/news';

const e = (schluessel: string, gruppe?: string) => ({ schluessel, gruppe, pfad: `/${schluessel}` } as any);

describe('navBaum', () => {
  it('bleibt ohne Gruppen flach', () => {
    const b = navBaum([e('a'), e('b')], []);
    expect(b.map(k => k.art)).toEqual(['eintrag', 'eintrag']);
  });
  it('fasst Eintraege einer Gruppe dort zusammen, wo der erste steht', () => {
    const b = navBaum([e('a'), e('b', 'g'), e('c'), e('d', 'g')], [{ id: 'g', label: 'G' }]);
    expect(b.length).toBe(3);
    expect(b[1].art).toBe('gruppe');
    expect((b[1] as any).eintraege.map((x: any) => x.schluessel)).toEqual(['b', 'd']);
  });
  it('laesst Eintraege mit unbekannter Gruppe einzeln stehen', () => {
    expect(navBaum([e('a', 'weg')], []).map(k => k.art)).toEqual(['eintrag']);
  });
  it('kennt das Megamenue', () => {
    expect(navLayout({ computer: 'MEGAMENU' }).computer).toBe('MEGAMENU');
    expect(navLayout({ computer: 'quatsch' }).computer).toBe('KOPFZEILE');
  });
});

describe('absaetze', () => {
  it('teilt Text an Leerzeilen', () => expect(absaetze('Eins\n\nZwei')).toEqual(['Eins', 'Zwei']));
  it('nimmt Listen und als Text gespeicherte Listen', () => {
    expect(absaetze(['A', 'B'])).toEqual(['A', 'B']);
    expect(absaetze('["A","B"]')).toEqual(['A', 'B']);
  });
  it('liefert bei nichts eine leere Liste', () => expect(absaetze(null)).toEqual([]));
});
