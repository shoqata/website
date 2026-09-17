import { describe, it, expect } from 'vitest';
import { needsProfileSetup } from '../../lib/memberQuality';

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

  it('schickt bei fehlendem Telefon in den Assistenten', () => {
    expect(needsProfileSetup({ ...vollstaendig, phone: '' })).toBe(true);
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
