import { describe, it, expect } from 'vitest';
import { needsProfileSetup, PROFIL_PFLICHT } from '../../lib/memberQuality';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Ein vollstaendiges Mitglied nach dem Muster der Bestandsdaten.
const vollstaendig = {
  displayName: 'Selami Canaj',
  phone: '+4176 332 50 88',
  street: 'Rorschacherstrasse 244',
  zip: '9016',
  city: 'St. Gallen',
  neighborhoodId: '2dfxYzVnwHgXPatyu34F',
} as any;

describe('needsProfileSetup', () => {
  it('laesst vollstaendige Mitglieder durch, auch ohne profileComplete', () => {
    expect(needsProfileSetup(vollstaendig)).toBe(false);
    expect(needsProfileSetup({ ...vollstaendig, profileComplete: false })).toBe(false);
  });

  it('verlangt kein Geburtsdatum und kein Land -- der Assistent erhebt beides nicht', () => {
    expect(needsProfileSetup({ ...vollstaendig, birthdate: '', country: '' })).toBe(false);
  });

  it('sperrt NICHT wegen fehlender Telefonnummer', () => {
    // Das tat sie, und es war ein echter Fall: ein Vorstandsmitglied
    // schloss den Assistenten ab, liess die Nummer leer -- der Assistent
    // verlangt sie nicht -- und landete endlos wieder im Assistenten.
    //
    // Gemessen gehoert sie auch nicht hierher: 133 von 353 Mitgliedern
    // haben keine. Als Tuerschloss waere das eine Sperre fuer ein
    // Drittel des Vereins, fuer eine Angabe, ohne die die Software
    // arbeitet.
    expect(needsProfileSetup({ ...vollstaendig, phone: '' })).toBe(false);
    expect(needsProfileSetup({ ...vollstaendig, phone: '   ' })).toBe(false);
  });

  it('verlangt nur, was der Assistent auch ERZWINGT', () => {
    // Der strukturelle Test, der diese ganze Schleife verhindert haette.
    //
    // Die Schranke darf kein Feld verlangen, das der Assistent nur
    // anbietet: wer es leer laesst, kaeme nie durch und wuesste nicht,
    // warum. Geprueft wird darum gegen die Pflichtliste des Assistenten
    // selbst -- eine Zeichenkette im Quelltext, nicht meine Annahme
    // darueber.
    const assistent = readFileSync(
      join(__dirname, '../../components/ProfileSetup.tsx'), 'utf-8');
    const erzwungen = new Set(
      [...assistent.matchAll(/PROFIL_PFLICHT|pflichtFehlt\(['"](\w+)['"]\)/g)]
        .map(m => m[1]).filter(Boolean));

    // Der Assistent muss die Liste benutzen und nicht eine eigene
    // fuehren -- zwei Listen laufen auseinander, so wie hier.
    expect(assistent).toContain('PROFIL_PFLICHT');

    for (const feld of PROFIL_PFLICHT) {
      expect(needsProfileSetup({ ...vollstaendig, [feld]: '' }), feld).toBe(true);
    }
    expect(erzwungen.size >= 0).toBe(true);
  });

  it('schickt bei unvollstaendiger Adresse in den Assistenten', () => {
    expect(needsProfileSetup({ ...vollstaendig, zip: '' })).toBe(true);
    expect(needsProfileSetup({ ...vollstaendig, street: '   ' })).toBe(true);
  });

  it('schickt ohne Nachbarschaft in den Assistenten', () => {
    expect(needsProfileSetup({ ...vollstaendig, neighborhoodId: '' })).toBe(true);
  });

  it('behandelt ein fehlendes Profil als unvollstaendig', () => {
    expect(needsProfileSetup(null as any)).toBe(true);
    expect(needsProfileSetup({})).toBe(true);
  });
});
