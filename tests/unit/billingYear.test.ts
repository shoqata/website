import { describe, it, expect } from 'vitest';
import { billingYearOf, feeStateFor, paidDateOf, isOverdue } from '../../lib/memberQuality';

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

describe('paidDateOf', () => {
  const alsTimestamp = (iso: string) => ({ toDate: () => new Date(iso) });

  it('nimmt das Zahlungsdatum, nicht den Zeitstempel des Datensatzes', () => {
    // Genau der Fall, der die Umsatzentwicklung leer liess: alle
    // uebernommenen Rechnungen entstanden im Juni, bezahlt wurde im Juli.
    const d = paidDateOf({ paidAt: '2026-07-05T07:27:18.165Z', timestamp: alsTimestamp('2026-06-01T00:00:00Z') });
    expect(d?.getMonth()).toBe(6);   // Juli
  });

  it('faellt ohne Zahlungsdatum auf den Zeitstempel zurueck', () => {
    const d = paidDateOf({ timestamp: alsTimestamp('2026-06-01T00:00:00Z') });
    expect(d?.getMonth()).toBe(5);   // Juni
  });

  it('kommt mit einem Datum ohne Uhrzeit zurecht', () => {
    expect(paidDateOf({ paidAt: '2026-09-18' })?.getFullYear()).toBe(2026);
  });

  it('gibt null zurueck, wenn nichts Brauchbares dasteht', () => {
    expect(paidDateOf({})).toBeNull();
    expect(paidDateOf(null)).toBeNull();
    expect(paidDateOf({ paidAt: '', timestamp: null })).toBeNull();
  });

  it('haelt einen unbrauchbaren Wert aus, statt ein falsches Datum zu behaupten', () => {
    expect(paidDateOf({ paidAt: 'kein Datum' })).toBeNull();
  });
});

describe('isOverdue', () => {
  const gestern = '2026-09-01';
  const morgen  = '2027-01-01';
  const heute   = new Date('2026-09-18');

  it('erkennt eine offene Rechnung mit ueberschrittener Faelligkeit', () => {
    // Der Fall, der im Armaturenbrett fehlte: 242 Rechnungen sind offen und
    // faellig, aber keine einzige traegt den Status OVERDUE.
    expect(isOverdue({ status: 'PENDING', dueDate: gestern }, heute)).toBe(true);
  });

  it('achtet weiterhin auf den Status, falls der Mahnlauf ihn gesetzt hat', () => {
    expect(isOverdue({ status: 'OVERDUE' }, heute)).toBe(true);
  });

  it('haelt eine noch nicht faellige Rechnung nicht fuer ueberfaellig', () => {
    expect(isOverdue({ status: 'PENDING', dueDate: morgen }, heute)).toBe(false);
  });

  it('eine bezahlte Rechnung ist nie ueberfaellig, auch nicht verspaetet bezahlt', () => {
    expect(isOverdue({ status: 'PAID', dueDate: gestern }, heute)).toBe(false);
  });

  it('ohne Faelligkeitsdatum bleibt es offen, nicht ueberfaellig', () => {
    expect(isOverdue({ status: 'PENDING' }, heute)).toBe(false);
  });

  it('haelt einen unbrauchbaren Wert aus', () => {
    expect(isOverdue({ status: 'PENDING', dueDate: 'kein Datum' }, heute)).toBe(false);
    expect(isOverdue(null, heute)).toBe(false);
  });
});
