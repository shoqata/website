import { describe, it, expect } from 'vitest';
import { oeffentlich } from '../../lib/zaehler';

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
