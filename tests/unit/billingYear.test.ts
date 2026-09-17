import { describe, it, expect } from 'vitest';
import { billingYearOf, feeStateFor } from '../../lib/memberQuality';

// Die Bruecke wandelt ISO-Zeichenketten in Objekte mit toDate(); in Tests wird
// dasselbe nachgebildet, damit beide Wege geprueft sind.
const alsTimestamp = (iso: string) => ({ toDate: () => new Date(iso) });

describe('billingYearOf', () => {
  it('nimmt billingYear, auch wenn der Zeitstempel in einem anderen Jahr liegt', () => {
    // Genau der Fall, der die Vorstandszahlen verfaelschte: im Januar 2026
    // gestellte Rechnung fuer das Beitragsjahr 2025.
    expect(billingYearOf({ billingYear: 2025, timestamp: alsTimestamp('2026-01-15T10:00:00Z') })).toBe(2025);
  });

  it('nimmt billingYear auch als Zeichenkette', () => {
    expect(billingYearOf({ billingYear: '2026' })).toBe(2026);
  });

  it('faellt ohne billingYear auf den Zeitstempel zurueck', () => {
    expect(billingYearOf({ timestamp: alsTimestamp('2026-07-01T00:00:00Z') })).toBe(2026);
    expect(billingYearOf({ timestamp: '2026-07-01T00:00:00Z' })).toBe(2026);
  });

  it('meldet NaN, wenn beides fehlt -- statt still ein falsches Jahr zu behaupten', () => {
    expect(Number.isNaN(billingYearOf({}))).toBe(true);
    expect(Number.isNaN(billingYearOf(null))).toBe(true);
  });
});

describe('feeStateFor nutzt dieselbe Regel', () => {
  const zahlungen = [
    { userId: 'a', billingYear: 2026, status: 'PAID' },
    { userId: 'b', billingYear: 2026, status: 'PENDING' },
    { userId: 'c', billingYear: 2025, status: 'PAID', timestamp: alsTimestamp('2026-01-15T10:00:00Z') },
  ];

  it('zaehlt eine 2025er Rechnung nicht zu 2026, auch wenn sie 2026 entstand', () => {
    expect(feeStateFor('c', zahlungen, 2026)).toBe('NONE');
    expect(feeStateFor('c', zahlungen, 2025)).toBe('PAID');
  });

  it('unterscheidet bezahlt, offen und nicht verrechnet', () => {
    expect(feeStateFor('a', zahlungen, 2026)).toBe('PAID');
    expect(feeStateFor('b', zahlungen, 2026)).toBe('OPEN');
    expect(feeStateFor('unbekannt', zahlungen, 2026)).toBe('NONE');
  });
});
