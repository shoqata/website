// Wo auf der Rechnung was steht.
//
// Zwei Zonen, und der Unterschied ist der Kern dieses Moduls:
//
// 1. Die unteren 105 mm gehoeren dem Zahlteil. Dessen Masse sind in den
//    Swiss-QR-Bill-Richtlinien auf den Millimeter vorgeschrieben --
//    Empfangsschein 62 mm, Zahlteil 148 mm, Hoehe 105 mm, der Code 46 mm
//    mit 7 mm Schweizerkreuz. Daran darf nichts verstellt werden: eine
//    verschobene Angabe macht den Beleg ungueltig, und das faellt nicht
//    hier auf, sondern wenn ein Mitglied an der Kasse steht. Der Designer
//    zeigt diese Masse, damit man sie pruefen kann, und laesst sie fest.
//
// 2. Alles darueber gehoert dem Verein. Logo, Absender, Empfaenger, Titel,
//    Tabelle, Schlusswort -- Lage und Groesse frei.
//
// Gespeichert werden Millimeter, nicht Pixel oder Prozent: ein Blatt A4 ist
// 210 x 297 mm, und eine Rechnung wird gedruckt. Prozente waeren beim
// Umrechnen ungenau, Pixel bei anderer Aufloesung falsch.

export const BLATT = { breite: 210, hoehe: 297 } as const;

// Die Zone, die dem Zahlteil gehoert. Nichts Eigenes darf hier hinein.
export const ZAHLTEIL = {
  oben: BLATT.hoehe - 105,   // 192 mm
  hoehe: 105,
  empfangsschein: 62,
  zahlteil: 148,
  qrSeite: 46,               // Kantenlaenge des Codes
  kreuz: 7,                  // Schweizerkreuz in der Mitte
} as const;

export type Feld = {
  schluessel: string;
  x: number; y: number;        // obere linke Ecke in mm
  breite?: number;             // mm; fehlt = inhaltsabhaengig
  groesse: number;             // Schriftgrad in pt
  ausrichtung?: 'links' | 'rechts';
  sichtbar: boolean;
};

export type Rechnungslayout = {
  version: 1;
  felder: Record<string, Feld>;
};

// Die Vorgabe bildet die heutige Rechnung nach, damit das Umstellen nichts
// veraendert, solange niemand etwas verschiebt.
export const VORGABE: Rechnungslayout = {
  version: 1,
  felder: {
    logo:       { schluessel: 'logo',       x: 20,  y: 20,  groesse: 12, breite: 60, sichtbar: true },
    absender:   { schluessel: 'absender',   x: 120, y: 20,  breite: 70, groesse: 9,  ausrichtung: 'rechts', sichtbar: true },
    titel:      { schluessel: 'titel',      x: 20,  y: 42,  groesse: 24, sichtbar: true },
    nummer:     { schluessel: 'nummer',     x: 20,  y: 56,  breite: 60, groesse: 9,  sichtbar: true },
    datum:      { schluessel: 'datum',      x: 20,  y: 63,  breite: 60, groesse: 9,  sichtbar: true },
    empfaenger: { schluessel: 'empfaenger', x: 20,  y: 78,  breite: 85, groesse: 11, sichtbar: true },
    tabelle:    { schluessel: 'tabelle',    x: 20,  y: 110, breite: 170, groesse: 10, sichtbar: true },
    hinweis:    { schluessel: 'hinweis',    x: 20,  y: 170, breite: 170, groesse: 9,  sichtbar: true },
  },
};

// Was ein Feld im Designer heisst und wofuer es da ist.
export const FELDNAMEN: Record<string, { de: string; en: string; sq: string }> = {
  logo:       { de: 'Logo und Vereinsname', en: 'Logo and association name', sq: 'Logoja dhe emri i shoqatës' },
  absender:   { de: 'Absender',             en: 'Sender',                    sq: 'Dërguesi' },
  titel:      { de: 'Überschrift',          en: 'Heading',                   sq: 'Titulli' },
  nummer:     { de: 'Rechnungsnummer',      en: 'Invoice number',            sq: 'Numri i faturës' },
  datum:      { de: 'Datum',                en: 'Date',                      sq: 'Data' },
  empfaenger: { de: 'Empfänger',            en: 'Recipient',                 sq: 'Marrësi' },
  tabelle:    { de: 'Positionen',           en: 'Line items',                sq: 'Pozicionet' },
  hinweis:    { de: 'Schlusswort',          en: 'Closing note',              sq: 'Fjala e fundit' },
};

// Ein Feld darf nicht in den Zahlteil rutschen und nicht ueber den Rand.
//
// Das wird hier geprueft und nicht erst beim Drucken: wer ein Feld in den
// Zahlteil zieht, bekaeme sonst eine Rechnung, die im Browser gut aussieht
// und an der Kasse zurueckgewiesen wird.
export function begrenzen(f: Feld): Feld {
  const breite = f.breite ?? 40;
  // Grobe Hoehe aus dem Schriftgrad; genauer geht erst beim Zeichnen, und
  // fuer die Grenze genuegt es, das Feld nicht anstossen zu lassen.
  const hoehe = Math.max(6, (f.groesse / 72) * 25.4 * 1.4);
  return {
    ...f,
    x: Math.min(Math.max(0, f.x), BLATT.breite - breite),
    y: Math.min(Math.max(0, f.y), ZAHLTEIL.oben - hoehe),
  };
}

export function layoutLesen(roh: any): Rechnungslayout {
  if (!roh || roh.version !== 1 || typeof roh.felder !== 'object') return VORGABE;
  // Fehlende Felder aus der Vorgabe ergaenzen: ein Layout, das vor einem
  // neuen Feld gespeichert wurde, darf dieses nicht verschlucken.
  const felder: Record<string, Feld> = { ...VORGABE.felder };
  for (const [k, v] of Object.entries(roh.felder as Record<string, any>)) {
    if (!felder[k]) continue;         // unbekanntes Feld: ignorieren
    felder[k] = begrenzen({ ...felder[k], ...v, schluessel: k });
  }
  return { version: 1, felder };
}
