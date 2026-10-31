import { describe, it, expect } from 'vitest';
import { oeffentlich, pfadKuerzen } from '../../lib/zaehler';

// Welche Seiten gezaehlt werden, ist keine Nebensache: bei sechs
// angemeldeten Konten und wenigen Besuchern kippen die eigenen Klicks
// des Vorstands die Zahlen. "Wie laeuft die Website" soll nicht die
// Arbeit im Adminbereich messen.

describe('Welche Pfade gezählt werden', () => {
  it('öffentliche Seiten ja', () => {
    for (const p of ['/', '/spenden', '/anlaesse', '/ueber-uns', '/dorfleben',
                     '/eigene-seite', '/kontakt']) {
      expect(oeffentlich(p), p).toBe(true);
    }
  });

  it('interne Bereiche nein', () => {
    for (const p of ['/admin', '/super-admin', '/dashboard', '/nachbarschaft',
                     '/login', '/register', '/setup-profile']) {
      expect(oeffentlich(p), p).toBe(false);
    }
  });

  it('auch Unterseiten interner Bereiche nein', () => {
    expect(oeffentlich('/admin/mitglieder')).toBe(false);
    expect(oeffentlich('/vorstellen/abc123')).toBe(false);
    expect(oeffentlich('/revision/token')).toBe(false);
  });

  it('ein Pfad, der nur so anfängt, bleibt öffentlich', () => {
    // "/adminstrasse" ist kein Adminbereich. Ein blosses startsWith ohne
    // Trennzeichen haette diese Seite stumm aus der Zaehlung genommen.
    expect(oeffentlich('/adminstrasse')).toBe(true);
    expect(oeffentlich('/logins-info')).toBe(true);
    expect(oeffentlich('/registerkarte')).toBe(true);
  });
});

describe('Zugänge werden gekürzt', () => {
  it('Token und Kennungen verschwinden aus dem Pfad', () => {
    expect(pfadKuerzen('/treffen/abc123')).toBe('/treffen/*');
    expect(pfadKuerzen('/heft/xyz')).toBe('/heft/*');
    expect(pfadKuerzen('/ausweis/0b6f-uuid')).toBe('/ausweis/*');
    expect(pfadKuerzen('/drucksachen/42')).toBe('/drucksachen/*');
  });

  it('andere Pfade bleiben, nur Abfrage und Anker fallen weg', () => {
    expect(pfadKuerzen('/news/7')).toBe('/news/7');
    expect(pfadKuerzen('/treffen')).toBe('/treffen');
    expect(pfadKuerzen('/spenden?betrag=50')).toBe('/spenden');
    expect(pfadKuerzen('/heftig')).toBe('/heftig');
  });
});
