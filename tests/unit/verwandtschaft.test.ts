import { describe, it, expect } from 'vitest';
import { netzAus, gradZwischen, verwandteVon, type Kante } from '../../lib/verwandtschaft';

// Oma -> Mama -> Kind; Mama hat einen Bruder (Onkel) mit Tochter (Cousine).
const kanten: Kante[] = [
  { von: 'oma', nach: 'mama', art: 'ELTERNTEIL' },
  { von: 'oma', nach: 'onkel', art: 'ELTERNTEIL' },
  { von: 'mama', nach: 'kind', art: 'ELTERNTEIL' },
  { von: 'onkel', nach: 'cousine', art: 'ELTERNTEIL' },
  { von: 'mama', nach: 'papa', art: 'PARTNER' },
];
const netz = netzAus(kanten);

describe('Verwandtschaft mit Anrede', () => {
  it('ohne Anrede bleibt es neutral', () => {
    expect(gradZwischen(netz, 'kind', 'mama')?.bezeichnung).toBe('Elternteil');
    expect(gradZwischen(netz, 'kind', 'oma')?.bezeichnung).toBe('Grosselternteil');
    expect(gradZwischen(netz, 'kind', 'onkel')?.bezeichnung).toBe('Onkel/Tante');
    expect(gradZwischen(netz, 'mama', 'onkel')?.bezeichnung).toBe('Geschwister');
  });
  it('mit Anrede passend benannt', () => {
    expect(gradZwischen(netz, 'kind', 'mama', true)?.bezeichnung).toBe('Mutter');
    expect(gradZwischen(netz, 'kind', 'oma', true)?.bezeichnung).toBe('Grossmutter');
    expect(gradZwischen(netz, 'kind', 'onkel', false)?.bezeichnung).toBe('Onkel');
    expect(gradZwischen(netz, 'mama', 'onkel', false)?.bezeichnung).toBe('Bruder');
    expect(gradZwischen(netz, 'kind', 'cousine', true)?.bezeichnung).toBe('Cousine ersten Grades');
    expect(gradZwischen(netz, 'oma', 'kind', false)?.bezeichnung).toBe('Enkel');
    expect(gradZwischen(netz, 'mama', 'kind', true)?.bezeichnung).toBe('Tochter');
  });
  it('Partner und Angeheiratete', () => {
    const w = (id: string) => (id === 'papa' ? false : null);
    const v = verwandteVon(netz, 'mama', ['oma', 'mama', 'onkel', 'kind', 'cousine', 'papa'], new Map([['papa', 'Papa']]), w);
    expect(v.find(x => x.id === 'papa')?.bezeichnung).toBe('Partner');
    const o = verwandteVon(netz, 'onkel', ['oma', 'mama', 'onkel', 'kind', 'cousine', 'papa'], new Map([['mama', 'Mama']]));
    expect(o.find(x => x.id === 'papa')?.gruppe).toBe('angeheiratet');
  });
});
