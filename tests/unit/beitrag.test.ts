import { describe, it, expect } from 'vitest';
import { beitragFuer, gruppensatz } from '../../lib/beitrag';

// Die Saetze von Koretini, gemessen:
//   annualFeeAmount 120
//   STANDARD 120 CHF · KOSOVO 12 EUR · REDUCED 100 EUR
const saetze = {
  annualFeeAmount: 120,
  fees: {
    STANDARD: { amount: 120, currency: 'CHF', label: 'Standard' },
    KOSOVO: { amount: 12, currency: 'EUR', label: 'Resident' },
    REDUCED: { amount: 100, currency: 'EUR', label: 'Reduced' },
  },
};

describe('Beitrag je Mitglied', () => {
  it('ohne alles den Standardsatz', () => {
    const b = beitragFuer({}, saetze);
    expect(b.betrag).toBe(120);
    expect(b.quelle).toBe('STANDARD');
  });

  it('mit Gruppe den Gruppensatz', () => {
    const b = beitragFuer({ billingGroup: 'KOSOVO' } as any, saetze);
    expect(b.betrag).toBe(12);
    expect(b.waehrung).toBe('EUR');
    expect(b.quelle).toBe('GRUPPE');
  });

  it('ein eigener Beitrag gewinnt', () => {
    const b = beitragFuer({ billingGroup: 'KOSOVO', customAnnualFee: 50 } as any, saetze);
    expect(b.betrag).toBe(50);
    expect(b.quelle).toBe('EIGEN');
    // Und die Maske muss sagen koennen, wovon abgewichen wird.
    expect(b.ohne_eigenen).toBe(12);
  });

  it('ein eigener Beitrag von NULL bleibt null', () => {
    // Der wichtigste Fall. Eine Beitragsbefreiung ist ein eigener
    // Beitrag von 0. Mit || statt ?? geprueft wuerde sie still
    // ueberschrieben, und das Mitglied bekaeme eine Rechnung, von der
    // es nichts weiss.
    const b = beitragFuer({ customAnnualFee: 0 } as any, saetze);
    expect(b.betrag).toBe(0);
    expect(b.quelle).toBe('EIGEN');
  });

  it('eine unbekannte Gruppe faellt auf den Standard zurück, nicht auf 0', () => {
    const b = beitragFuer({ billingGroup: 'GIBTSNICHT' } as any, saetze);
    expect(b.betrag).toBe(120);
    expect(b.quelle).toBe('STANDARD');
  });

  it('ohne Sätze ein erkennbarer Rückfall', () => {
    // 120 ist eine Annahme, und sie soll als solche erkennbar sein --
    // sonst haelt die Maske sie fuer einen gepflegten Satz.
    const b = beitragFuer({}, null);
    expect(b.betrag).toBe(120);
    expect(b.quelle).toBe('RUECKFALL');
  });

  it('Gross- und Kleinschreibung der Gruppe zählt nicht', () => {
    expect(beitragFuer({ billingGroup: 'kosovo' } as any, saetze).betrag).toBe(12);
    expect(beitragFuer({ billingGroup: ' Kosovo ' } as any, saetze).betrag).toBe(12);
  });

  it('gruppensatz allein ist brauchbar', () => {
    expect(gruppensatz('REDUCED', saetze).betrag).toBe(100);
    expect(gruppensatz(null, saetze).betrag).toBe(120);
  });

  it('eine leere Zeichenkette ist kein eigener Beitrag', () => {
    // Ein geleertes Eingabefeld schickt ''. Das darf nicht als 0
    // gelesen werden -- sonst macht Leeren aus einem Beitrag eine
    // Befreiung.
    const b = beitragFuer({ customAnnualFee: '' } as any, saetze);
    expect(b.betrag).toBe(120);
    expect(b.quelle).toBe('STANDARD');
  });
});
