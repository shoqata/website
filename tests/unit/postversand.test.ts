import { describe, it, expect } from 'vitest';
import {
  zahlungsteilEntscheiden, zahlungsangabenPruefen, einreihAntwortLesen,
  PINGEN_ZAHLUNGSTEIL_FERTIG,
} from '../../lib/postversand';

describe('Zahlungsteil: wer zeichnet den QR', () => {
  it('zeichnet ihn ohne Angabe selbst', () => {
    const e = zahlungsteilEntscheiden();
    expect(e.weg).toBe('SELBST');
    expect(e.ohneZahlungsteil).toBe(false);
  });

  it('lehnt PINGEN ab, solange die Uebergabe nicht gebaut ist', () => {
    // Der wichtigste Test der Datei. Wuerde PINGEN stillschweigend zu
    // SELBST, waere das harmlos. Wuerde es stillschweigend durchgehen,
    // ginge eine Rechnung OHNE jeden Zahlungsteil per Post hinaus --
    // Papier, Porto und eine Forderung, die niemand bezahlen kann.
    expect(PINGEN_ZAHLUNGSTEIL_FERTIG).toBe(false);
    expect(() => zahlungsteilEntscheiden('PINGEN')).toThrow(/nicht dokumentiert/);
  });

  it('nennt den Grund so, dass man weiss, was fehlt', () => {
    expect(() => zahlungsteilEntscheiden('PINGEN')).toThrow(/Briefschnittstelle/);
  });

  it('laesst SELBST ausdruecklich zu', () => {
    expect(zahlungsteilEntscheiden('SELBST').ohneZahlungsteil).toBe(false);
  });
});

describe('Zahlungsangaben: kann man die Rechnung bezahlen?', () => {
  const V = { name: 'Shoqata Humanitare Koretini' };

  it('nimmt eine QR-IBAN mit Kontoinhaber', () => {
    expect(zahlungsangabenPruefen({ ...V, qrIban: 'CH44 3199 9123 0008 8901 2' }).ok).toBe(true);
  });

  it('nimmt eine gewoehnliche IBAN mit Kontoinhaber', () => {
    expect(zahlungsangabenPruefen({ ...V, iban: 'CH13 0630 0508 6189 1750 0' }).ok).toBe(true);
  });

  it('lehnt eine IBAN ohne Kontoinhaber ab', () => {
    // Nach der Swiss-QR-Spezifikation gehoert der Kontoinhaber dazu.
    // Ohne ihn weist die Bank den Beleg zurueck -- und das faellt erst
    // beim Empfaenger auf, nach Druck und Porto.
    const z = zahlungsangabenPruefen({ name: '', iban: 'CH13 0630 0508 6189 1750 0' });
    expect(z.ok).toBe(false);
    expect(z.grund).toMatch(/Kontoinhaber/);
  });

  it('nimmt PayPal allein -- fuer Mitglieder ausserhalb der Schweiz', () => {
    expect(zahlungsangabenPruefen({ name: '', paypal: 'kasse@verein.ch' }).ok).toBe(true);
  });

  it('nimmt TWINT allein', () => {
    expect(zahlungsangabenPruefen({ name: '', twint: '079 000 00 00' }).ok).toBe(true);
  });

  it('lehnt eine Bankadresse ohne IBAN ab', () => {
    // Eine Bank und eine BIC sind keine Zahlungsverbindung: ueberweisen
    // kann damit niemand.
    expect(zahlungsangabenPruefen({ ...V, bank: 'PostFinance', bic: 'POFICHBEXXX' }).ok).toBe(false);
  });

  it('lehnt einen Verein ohne jede Angabe ab', () => {
    const z = zahlungsangabenPruefen(V);
    expect(z.ok).toBe(false);
    expect(z.grund).toMatch(/Finanzen/);
  });

  it('zaehlt Leerzeichen nicht als Angabe', () => {
    expect(zahlungsangabenPruefen({ ...V, iban: '   ' }).ok).toBe(false);
  });

  it('lehnt auch null und undefined ab', () => {
    expect(zahlungsangabenPruefen(null).ok).toBe(false);
    expect(zahlungsangabenPruefen(undefined).ok).toBe(false);
  });
});

describe('Antwort auf das Einreihen', () => {
  it('nimmt eine eingereihte Briefnummer an', () => {
    expect(einreihAntwortLesen({ eingereiht: true, id: 'abc', empfaenger: 'X' }).id).toBe('abc');
  });

  it('macht aus einem schon erfassten Brief KEINEN Erfolg', () => {
    // post_einreihen wirft hier nicht, es antwortet. Wer nur auf error
    // prueft, meldet "eingereiht" fuer einen Brief, der schon unterwegs
    // ist -- und jemand reiht ihn dann noch einmal ein.
    expect(() => einreihAntwortLesen({
      eingereiht: false, zustand: 'UEBERGEBEN',
      grund: 'Für diese Rechnung ist schon ein Brief erfasst (UEBERGEBEN).',
    })).toThrow(/schon ein Brief erfasst/);
  });

  it('lehnt eine Antwort ohne Briefnummer ab', () => {
    expect(() => einreihAntwortLesen({ eingereiht: true })).toThrow(/Briefnummer/);
  });

  it('lehnt eine leere Antwort ab', () => {
    expect(() => einreihAntwortLesen(null)).toThrow(/nicht geantwortet/);
  });
});
