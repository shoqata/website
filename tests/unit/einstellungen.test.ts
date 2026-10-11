import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { alsText } from '../../lib/einstellungen';

// Dieser Test haette mich davor bewahrt, dem Verein mehrfach zu sagen,
// er muesse eine IBAN eintragen, die er laengst eingetragen hatte.
//
// Die Tabelle settings hat je Bereich eine eigene Spalte -- payment,
// branding, company, system -- und zusaetzlich eine Spalte "data", die
// bei allen Zeilen {} ist. Zwei Stellen lasen "data":
//
//   mahnung.ts     -> QR-Rechnung ohne IBAN -> PDF scheiterte ->
//                     Mahnung abgelehnt mit "Die Rechnung liess sich
//                     nicht erzeugen"
//   flokykarte.ts  -> Vereinsname leer -> Mahnung ohne Absendernamen
//
// Beides ohne jeden Fehler: PostgREST liefert die Zeile mit null, der
// Aufrufer macht daraus {} und arbeitet weiter. Genau diese Art
// Fehlgriff findet man nicht im Betrieb, sondern nur, indem man die
// Spaltennamen nachsieht -- oder mit einem Test wie diesem.

const dateien = (ordner: string): string[] => {
  const basis = join(__dirname, '../..', ordner);
  return readdirSync(basis, { withFileTypes: true })
    .filter(e => e.isFile() && /\.tsx?$/.test(e.name))
    .map(e => join(basis, e.name));
};

describe('Einstellungen aus der richtigen Spalte', () => {
  it('niemand liest die Spalte data der Tabelle settings', () => {
    const treffer: string[] = [];
    for (const ordner of ['lib', 'components', 'services']) {
      for (const pfad of dateien(ordner)) {
        const inhalt = readFileSync(pfad, 'utf-8');
        // Eine Abfrage auf settings, die 'data' auswaehlt. Die Spalte
        // existiert und ist leer -- der Zugriff scheitert also nicht,
        // er liefert nur nichts.
        if (/from\(\s*['"]settings['"]\s*\)[\s\S]{0,120}?select\(\s*['"]data['"]/.test(inhalt)) {
          treffer.push(pfad.split('/').slice(-2).join('/'));
        }
      }
    }
    expect(treffer).toEqual([]);
  });

  it('mahnung.ts und flokykarte.ts gehen über einstellungLaden', () => {
    for (const d of ['lib/mahnung.ts', 'lib/flokykarte.ts']) {
      const inhalt = readFileSync(join(__dirname, '../..', d), 'utf-8');
      expect(inhalt, d).toContain('einstellungLaden');
    }
  });
});

describe('alsText', () => {
  it('nimmt eine Zeichenkette', () => {
    expect(alsText('  Koretini ')).toBe('Koretini');
  });

  it('nimmt ein mehrsprachiges Objekt', () => {
    expect(alsText({ de: 'Verein', sq: 'Shoqata' })).toBe('Verein');
    expect(alsText({ de: 'Verein', sq: 'Shoqata' }, 'sq')).toBe('Shoqata');
  });

  it('fällt auf eine vorhandene Sprache zurück', () => {
    // Fehlt die gewuenschte Sprache, ist eine andere besser als leer --
    // ein Brief ohne Absendernamen ist schlechter als einer mit dem
    // albanischen.
    expect(alsText({ sq: 'Shoqata' }, 'de')).toBe('Shoqata');
    expect(alsText({ en: 'Association' }, 'de')).toBe('Association');
  });

  it('leer bleibt leer, ohne zu werfen', () => {
    expect(alsText(null)).toBe('');
    expect(alsText(undefined)).toBe('');
    expect(alsText({})).toBe('');
  });
});
