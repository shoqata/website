import { describe, it, expect } from 'vitest';
import { generateQrCodeContent } from '../../services/qrBillService';

// Der Zahlteil wurde lange mit 29 statt 31 Feldern erzeugt, weil die beiden
// leeren Felder fuer Postleitzahl und Ort bei Adresstyp K fehlten. Dadurch
// verschob sich alles nach dem Glaeubigerblock und kein Beleg war einlesbar.
// Diese Tests halten die Struktur fest.

const base = (over: Partial<any> = {}) => ({
  amount: 120,
  currency: 'CHF',
  iban: 'CH13 0630 0508 6189 1750 0',
  creditor: { name: 'Shoqata Humanitare Koretini', address: 'Weidgartenstrasse 8', zip: '8909', city: 'Zwillikon', country: 'CH' },
  debtor: { name: 'Max Muster', address: 'Musterweg 1', zip: '8000', city: 'Zürich', country: 'CH' },
  reference: '',
  additionalInfo: 'Mitgliederbeitrag 2026',
  ...over,
});

const fields = (d: any) => generateQrCodeContent(d as any).split('\r\n');

// Mod-10 rekursiv, wie der ESR-Standard ihn vorschreibt
const mod10 = (digits: string) => {
  const table = [
    [0, 9, 4, 6, 8, 2, 7, 1, 3, 5], [9, 4, 6, 8, 2, 7, 1, 3, 5, 0],
    [4, 6, 8, 2, 7, 1, 3, 5, 0, 9], [6, 8, 2, 7, 1, 3, 5, 0, 9, 4],
    [8, 2, 7, 1, 3, 5, 0, 9, 4, 6], [2, 7, 1, 3, 5, 0, 9, 4, 6, 8],
    [7, 1, 3, 5, 0, 9, 4, 6, 8, 2], [1, 3, 5, 0, 9, 4, 6, 8, 2, 7],
    [3, 5, 0, 9, 4, 6, 8, 2, 7, 1], [5, 0, 9, 4, 6, 8, 2, 7, 1, 3],
  ];
  let carry = 0;
  for (const ch of digits) carry = table[carry][Number(ch)];
  return (10 - carry) % 10;
};

describe('generateQrCodeContent', () => {
  it('erzeugt genau die 31 Pflichtfelder und schliesst mit EPD ab', () => {
    const f = fields(base());
    expect(f).toHaveLength(31);
    expect(f[30]).toBe('EPD');
  });

  it('haelt Kopf und Konto an ihrer Position', () => {
    const f = fields(base());
    expect(f[0]).toBe('SPC');
    expect(f[1]).toBe('0200');
    expect(f[2]).toBe('1');
    expect(f[3]).toBe('CH1306300508618917500');
  });

  it('gibt jedem Adressblock sieben Felder, mit leerer PLZ und leerem Ort bei Typ K', () => {
    const f = fields(base());
    // Glaeubiger: Felder 5..11 (Index 4..10)
    expect(f[4]).toBe('K');
    expect(f[7]).toBe('8909 Zwillikon'); // PLZ und Ort stehen in Adresszeile 2
    expect(f[8]).toBe('');               // PstCd bleibt leer
    expect(f[9]).toBe('');               // TwnNm bleibt leer
    expect(f[10]).toBe('CH');
    // Schuldner: Felder 21..27 (Index 20..26)
    expect(f[20]).toBe('K');
    expect(f[23]).toBe('8000 Zürich');
    expect(f[24]).toBe('');
    expect(f[25]).toBe('');
    expect(f[26]).toBe('CH');
  });

  it('setzt Betrag und Waehrung auf Feld 19 und 20', () => {
    const f = fields(base());
    expect(f[18]).toBe('120.00');
    expect(f[19]).toBe('CHF');
  });

  it('nutzt bei normaler IBAN ohne Referenz den Typ NON', () => {
    const f = fields(base());
    expect(f[27]).toBe('NON');
    expect(f[28]).toBe('');
  });

  it('erzwingt bei einer QR-IBAN eine QRR-Referenz mit gueltiger Pruefziffer', () => {
    const f = fields(base({ iban: 'CH44 3199 9123 0008 8901 2' }));
    expect(f[27]).toBe('QRR');
    const ref = f[28];
    expect(ref).toHaveLength(27);
    expect(ref).toMatch(/^\d{27}$/);
    expect(String(mod10(ref.slice(0, 26)))).toBe(ref.slice(-1));
  });

  it('kommt ohne Referenz aus, statt zu werfen', () => {
    expect(() => fields(base({ reference: undefined }))).not.toThrow();
    expect(fields(base({ reference: undefined }))).toHaveLength(31);
  });
});
