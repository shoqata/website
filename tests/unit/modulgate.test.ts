import { describe, it, expect } from 'vitest';
import { seitenZustand } from '../../lib/modulgate';

describe('Modulgate einer Seite', () => {
  it('zeigt die Seite bei gebuchtem Modul', () => {
    expect(seitenZustand(new Set(['TURNIER']), 'TURNIER', false)).toBe('ZEIGEN');
  });

  it('leitet um, wenn das Modul fehlt', () => {
    expect(seitenZustand(new Set(['TURNIER']), 'DORFLEBEN', false)).toBe('UMLEITEN');
  });

  it('laedt, solange die Module unbekannt sind', () => {
    // Der wichtigste Fall. Wer hier umleitet, wirft einen Besucher
    // hinaus, dessen Verein das Modul hat -- und merkt es nie, weil der
    // zweite Aufruf klappt.
    expect(seitenZustand(null, 'TURNIER', false)).toBe('LAEDT');
    expect(seitenZustand(undefined, 'TURNIER', false)).toBe('LAEDT');
  });

  it('zeigt nicht vorab: ein unbekannter Zustand ist kein ZEIGEN', () => {
    // Die Gegenrichtung: waehrend des Ladens anzuzeigen liesse eine
    // Seite aufblitzen, die dem Verein nicht gehoert.
    expect(seitenZustand(null, 'TURNIER', false)).not.toBe('ZEIGEN');
  });

  it('leitet auf der Betreiberseite immer um', () => {
    expect(seitenZustand(new Set(['TURNIER']), 'TURNIER', true)).toBe('UMLEITEN');
  });

  it('behandelt eine unbekannte Betreiberfrage als Vereinsseite', () => {
    // istPlattformDomain ist anfangs null. Vorher galt null als
    // "kein Betreiber"; das bleibt so, sonst wuerde jede Vereinsseite
    // beim ersten Bild umgeleitet.
    expect(seitenZustand(new Set(['TURNIER']), 'TURNIER', null)).toBe('ZEIGEN');
  });

  it('leitet bei leerer Modulmenge um, statt zu laden', () => {
    // Eine leere Menge ist eine ANTWORT: der Verein hat keine Module.
    // Sie mit "unbekannt" zu verwechseln hiesse, ewig zu laden.
    expect(seitenZustand(new Set(), 'TURNIER', false)).toBe('UMLEITEN');
  });
});
