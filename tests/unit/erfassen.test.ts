import { describe, it, expect } from 'vitest';
import {
  zustellweg, zahlungsart, rechnungsnummer, mitgliedPruefen, rechnungPruefen,
} from '../../lib/erfassen';

// Geprueft werden die Entscheidungen, nicht das Schreiben. Genau dort
// lagen die Fehler der drei bisherigen Erfassungswege: der Zustellweg
// stand fest auf EMAIL, das Beitragsjahr fehlte, und die
// Rechnungsnummer bestand aus fuenf Stellen des Zeitstempels.

describe('Zustellweg', () => {
  it('ohne brauchbare Adresse immer Post', () => {
    // Der haeufigste Fall im Verein: 241 von 348 Rechnungen gehen per
    // Post, meist weil keine Mailadresse vorliegt. Eine Rechnung mit
    // EMAIL an jemanden ohne Adresse geht nirgendwohin -- und niemand
    // merkt es, weil der Versand keinen Fehler meldet.
    expect(zustellweg({ email: '' })).toBe('POST');
    expect(zustellweg({})).toBe('POST');
  });

  it('Platzhalteradressen zaehlen nicht als Adresse', () => {
    // Beim Datenimport entstanden Adressen wie
    // vorname.nachname.no-email-123@koretini.legacy. Sie sehen aus wie
    // eine Adresse und sind keine.
    expect(zustellweg({ email: 'a.b.no-email-17@koretini.legacy' })).toBe('POST');
  });

  it('der Wunsch des Mitglieds hat Vorrang', () => {
    expect(zustellweg({ email: 'a@b.ch', invoiceDeliveryMethod: 'POST' } as any)).toBe('POST');
    expect(zustellweg({ email: 'a@b.ch', invoiceDeliveryMethod: 'BOTH' } as any)).toBe('BOTH');
    expect(zustellweg({ email: 'a@b.ch' })).toBe('EMAIL');
  });
});

describe('Zahlungsart', () => {
  it('Schweiz bekommt die QR-Rechnung', () => {
    expect(zahlungsart({ country: 'Switzerland' })).toBe('QR_BILL');
  });
  it('alles andere eine Ueberweisung', () => {
    expect(zahlungsart({ country: 'Kosovo' })).toBe('BANK_TRANSFER');
    expect(zahlungsart({})).toBe('BANK_TRANSFER');
  });
});

describe('Rechnungsnummer', () => {
  it('traegt das Jahr und ist lesbar', () => {
    expect(rechnungsnummer(2026, () => 'abcdef1234')).toBe('INV-2026-ABCDEF');
  });

  it('zwei gleichzeitige Erfassungen kollidieren nicht', () => {
    // Das alte Schema war INV-<letzte 5 Stellen von Date.now()>. Es
    // wiederholt sich alle hundert Sekunden -- hier nachgestellt: bei
    // gleichem Zeitpunkt dieselbe Nummer, waehrend das neue Schema vom
    // Zufall abhaengt und nicht von der Uhr.
    const alt = (t: number) => `INV-${String(t).slice(-5)}`;
    expect(alt(1760000012345)).toBe(alt(1760000012345));

    const gesehen = new Set<string>();
    for (let i = 0; i < 2000; i++) {
      gesehen.add(rechnungsnummer(2026, () =>
        crypto.randomUUID().replace(/-/g, '')));
    }
    // Sechs Stellen aus 16 Zeichen: 16^6 = 16.7 Mio. Bei 2000 Nummern
    // ist eine Kollision moeglich, aber selten. Der Test prueft darum
    // eine Schranke, nicht Vollstaendigkeit -- alles andere waere ein
    // Test, der gelegentlich grundlos fehlschlaegt.
    expect(gesehen.size).toBeGreaterThan(1995);
  });
});

describe('Pruefung beim Mitglied', () => {
  const gut = { firstName: 'Ana', lastName: 'Berisha', neighborhoodId: 'nb1' };

  it('nimmt einen vollstaendigen Satz an', () => {
    expect(mitgliedPruefen(gut)).toBeNull();
  });

  it('verlangt beide Namensteile', () => {
    expect(mitgliedPruefen({ ...gut, firstName: ' ' })).toBe('name');
    expect(mitgliedPruefen({ ...gut, lastName: '' })).toBe('name');
  });

  it('verlangt eine Nachbarschaft', () => {
    // Ohne sie gehoert das Mitglied niemandem: es erscheint in keiner
    // Betreuungsliste. Acht der 333 Mitglieder haben keine, und das
    // sind genau die, die immer wieder auffallen.
    expect(mitgliedPruefen({ ...gut, neighborhoodId: '' })).toBe('neighborhood');
  });

  it('weist eine unbrauchbare Adresse zurueck, laesst keine zu', () => {
    expect(mitgliedPruefen({ ...gut, email: 'kein-at-zeichen' })).toBe('email');
    expect(mitgliedPruefen({ ...gut, email: '' })).toBeNull();
    expect(mitgliedPruefen({ ...gut, email: 'a@b.ch' })).toBeNull();
  });
});

describe('Pruefung bei der Rechnung', () => {
  const gut = {
    mitglied: { id: 'u1' }, amount: 40, description: 'Mitgliederbeitrag 2026',
    dueDate: '2026-11-30', billingYear: 2026,
  };

  it('nimmt einen vollstaendigen Satz an', () => {
    expect(rechnungPruefen(gut)).toBeNull();
  });

  it('kein Betrag von null oder darunter', () => {
    expect(rechnungPruefen({ ...gut, amount: 0 })).toBe('amount');
    expect(rechnungPruefen({ ...gut, amount: -5 })).toBe('amount');
    expect(rechnungPruefen({ ...gut, amount: NaN })).toBe('amount');
  });

  it('verlangt ein Beitragsjahr', () => {
    // Drei bestehende Rechnungen haben keines -- sie fallen aus jeder
    // Jahresauswertung heraus. Der alte Adminweg setzte es nicht.
    expect(rechnungPruefen({ ...gut, billingYear: undefined as any })).toBe('year');
  });

  it('verlangt ein Faelligkeitsdatum in fester Form', () => {
    expect(rechnungPruefen({ ...gut, dueDate: '30.11.2026' })).toBe('due');
    expect(rechnungPruefen({ ...gut, dueDate: '' })).toBe('due');
  });

  it('verlangt eine Bezeichnung', () => {
    // Sie steht auf der QR-Rechnung und im Journal. Ohne sie steht dort
    // nur die Rechnungsnummer, und niemand weiss, wofuer gezahlt wurde.
    expect(rechnungPruefen({ ...gut, description: '  ' })).toBe('description');
  });
});
