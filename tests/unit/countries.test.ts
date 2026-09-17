import { describe, it, expect } from 'vitest';
import { matchCountry, COUNTRY_OPTIONS } from '../../lib/countries';

describe('Land aus dem Altbestand einordnen', () => {
  it('erkennt die Kuerzel, die tatsaechlich im Bestand stehen', () => {
    // Gemessen in der Datenbank: DE (4x), Holland (1x), FR (1x), Schweiz (1x)
    expect(matchCountry('DE')).toBe('Deutschland');
    expect(matchCountry('FR')).toBe('Frankreich');
    expect(matchCountry('Holland')).toBe('Niederlande');
    expect(matchCountry('Schweiz')).toBe('Schweiz');
  });

  it('erkennt albanische Schreibweisen', () => {
    expect(matchCountry('Zvicër')).toBe('Schweiz');
    expect(matchCountry('Kosova')).toBe('Kosovo');
  });

  it('ist unabhaengig von Gross- und Kleinschreibung und Leerzeichen', () => {
    expect(matchCountry('  schweiz ')).toBe('Schweiz');
    expect(matchCountry('KOSOVO')).toBe('Kosovo');
  });

  it('gibt bei Leerwerten nichts zurueck', () => {
    expect(matchCountry('')).toBeNull();
    expect(matchCountry(undefined)).toBeNull();
    expect(matchCountry('   ')).toBeNull();
  });

  it('meldet Unbekanntes als Sonderfall, statt es still zu verwerfen', () => {
    // Faellt auf "Anderes" mit Freitext -- der Wert darf nicht verschwinden.
    expect(matchCountry('Neuseeland')).toBeNull();
  });

  it('fuehrt jede Listenoption auf sich selbst zurueck', () => {
    COUNTRY_OPTIONS.forEach((c) => expect(matchCountry(c)).toBe(c));
  });
});
