
/**
 * Swiss QR Bill Service
 * Strictly adheres to SIX Implementation Guidelines v2.3
 */

export interface QrBillData {
  amount: number;
  currency: 'CHF' | 'EUR';
  iban: string; // QR-IBAN or Standard IBAN
  creditor: {
    name: string;
    address: string; // Street + Nr
    zip: string;
    city: string;
    country: string;
  };
  debtor: {
    name: string;
    address: string;
    zip: string;
    city: string;
    country: string;
  };
  reference: string; 
  referenceType?: 'QRR' | 'SCOR' | 'NON'; 
  additionalInfo?: string; 
}

// Der nach SIX zugelassene Zeichenvorrat (IG v2.3, Anhang "Zeichensatz").
// Alles ausserhalb davon muss ersetzt werden -- nicht durchgereicht: ein
// kyrillischer oder emojihaltiger Name ging bisher ungeprueft in den Code,
// und ein Beleg, den die Bank zurueckweist, faellt erst beim Zahlen auf.
// Die Richtlinie sieht den Punkt als Ersatzzeichen vor.
const ZUGELASSEN =
  /[A-Za-z0-9.,;:'+\-\/()?*\[\]{}\\`´~ !"#%&<>÷=@_$£àáâäçèéêëìíîïñòóôöùúûüýßÀÁÂÄÇÈÉÊËÌÍÎÏÑÒÓÔÖÙÚÛÜÝ]/;

// Was mit einem nicht zugelassenen Zeichen geschieht.
//
// Erst versuchen, es zu zerlegen: Unicode trennt "Ż" in "Z" + Haken, "ğ" in
// "g" + Bogen. Bleibt danach ein zugelassenes Zeichen uebrig, wird es
// genommen. Das erledigt saemtliche lateinischen Zeichen samt
// Grossbuchstaben von selbst -- eine Liste von Hand kannte vorher "ż",
// aber nicht "Ż", und machte daraus einen Punkt.
//
// Was sich so nicht retten laesst (kyrillisch, Emoji), wird zum Punkt; so
// sieht es die Richtlinie vor.
//
// Wichtig: ë, ç, ä, ö, ü und ß sind ZUGELASSEN und werden nicht angetastet.
// Ein frueher Versuch ersetzte sie trotzdem -- und machte aus "Shpëtim
// Kërçeli" ein "Shpetim Kerceli", ausgerechnet bei den albanischen Namen,
// fuer die diese Plattform gebaut ist.
const SONDERFAELLE: Record<string, string> = {
  'ł':'l','Ł':'L','đ':'d','Đ':'D','ı':'i','İ':'I','ø':'o','Ø':'O','æ':'ae','Æ':'AE',
  'œ':'oe','Œ':'OE','þ':'th','Þ':'TH','ð':'d','Ð':'D',
  '„':'"','“':'"','”':'"','‚':"'",'‘':"'",'’':"'",
  '–':'-','—':'-','‐':'-','…':'...','\u00a0':' ','\u202f':' ','\u2009':' ',
};

const einZeichen = (z: string): string => {
  if (ZUGELASSEN.test(z)) return z;
  const bekannt = SONDERFAELLE[z];
  if (bekannt !== undefined) return bekannt;
  // Zerlegen und die Akzente wegnehmen.
  const roh = z.normalize('NFD').replace(/\p{M}+/gu, '');
  if (roh && Array.from(roh).every(x => ZUGELASSEN.test(x))) return roh;
  return '.';
};

const sanitize = (str: string | undefined, laenge = 70): string => {
  if (!str) return '';
  const t = Array.from(str.replace(/[\r\n]+/g, ' ')).map(einZeichen).join('');
  return t.trim().substring(0, laenge);
};

const normalizeCountry = (input: string | undefined): string => {
    if (!input) return 'CH';
    const c = input.toLowerCase().trim();
    if (c === 'schweiz' || c === 'switzerland' || c === 'suisse' || c === 'svizzera' || c === 'zvicer' || c === 'zvicër') return 'CH';
    if (c === 'deutschland' || c === 'germany' || c === 'gjermania' || c === 'gjermani') return 'DE';
    if (c === 'austria' || c === 'österreich' || c === 'austri') return 'AT';
    if (c === 'kosovo' || c === 'kosova' || c === 'xk') return 'XK'; 
    if (c === 'liechtenstein') return 'LI';
    if (input.length === 2) return input.toUpperCase(); 
    return 'CH'; 
};

export const calculateMod10 = (input: string): string => {
  const table = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5];
  let carry = 0;
  for (let i = 0; i < input.length; i++) {
    carry = table[(carry + parseInt(input.charAt(i), 10)) % 10];
  }
  return ((10 - carry) % 10).toString();
};

export const generateQrReference = (customerId: string): string => {
  let cleanId = customerId.replace(/\D/g, '');
  if(!cleanId) cleanId = '0';
  const prefix = new Date().getFullYear().toString(); 
  const payload = prefix + cleanId.padStart(22, '0'); 
  const checkDigit = calculateMod10(payload);
  return payload + checkDigit;
};

export const formatIban = (iban: string) => {
  if (!iban) return '';
  return iban.replace(/\s/g, '').replace(/(.{4})/g, '$1 ').trim();
};

export const formatReference = (ref: string, type: 'QRR' | 'SCOR' | 'NON') => {
  if (!ref) return '';
  const clean = ref.replace(/\s/g, '');
  if (type === 'QRR') {
    return clean.replace(/(.{2})(.{5})(.{5})(.{5})(.{5})(.{5})/, '$1 $2 $3 $4 $5 $6').trim(); 
  }
  if (type === 'SCOR') {
    return clean.replace(/(.{4})/g, '$1 ').trim();
  }
  return clean;
};

// Welche Referenz traegt dieser Beleg -- und welcher Art?
//
// Das stand bisher an ZWEI Stellen: hier im Dienst fuer den QR-Inhalt und
// noch einmal in SwissQRBill.tsx fuer den Aufdruck. Sie kamen bei einer
// QR-IBAN zu verschiedenen Ergebnissen: auf dem Papier stand RF18MB...,
// im Code eine erfundene Nummer. Der Mensch las die eine Referenz, die
// Bank die andere.
//
// Jetzt entscheidet das eine Funktion, und beide fragen sie.
export const referenzBestimmen = (
  iban: string, reference: string | undefined,
): { typ: 'QRR' | 'SCOR' | 'NON'; wert: string; abgeleitet: boolean } => {
  const sauber = (iban || '').replace(/\s/g, '');
  const iid = parseInt(sauber.substring(4, 9), 10);
  const istQrIban = iid >= 30000 && iid <= 31999;
  const ref = (reference || '').replace(/\s/g, '').toUpperCase();

  if (istQrIban) {
    // Eine QR-IBAN verlangt zwingend eine QR-Referenz: 27 Stellen, nur
    // Ziffern, letzte ist die Pruefziffer nach Modulo 10 rekursiv.
    if (/^\d{27}$/.test(ref) && calculateMod10(ref.slice(0, 26)) === ref[26]) {
      return { typ: 'QRR', wert: ref, abgeleitet: false };
    }
    // Keine brauchbare QRR vorhanden. Frueher kam hier fuer JEDE Rechnung
    // dieselbe Platzhalternummer heraus -- damit liess sich keine Zahlung
    // mehr einem Mitglied zuordnen. Stattdessen wird eine aus der
    // vorhandenen Referenz abgeleitet: gleiche Rechnung, gleiche Nummer;
    // verschiedene Rechnungen, verschiedene Nummern.
    const ziffern = ref.replace(/\D/g, '');
    return { typ: 'QRR', wert: generateQrReference(ziffern || '0'), abgeleitet: true };
  }

  // Normale IBAN: entweder eine Creditor Reference nach ISO 11649 oder gar
  // keine. Eine QRR waere hier unzulaessig.
  if (/^RF\d{2}[A-Z0-9]{1,21}$/.test(ref)) return { typ: 'SCOR', wert: ref, abgeleitet: false };
  return { typ: 'NON', wert: '', abgeleitet: false };
};

/**
 * Generates the raw QR content string.
 * Logic based on IG v2.3 Chapter 4.
 */
export const generateQrCodeContent = (data: QrBillData): string => {
  const br = '\r\n'; 

  const cleanIban = data.iban.replace(/\s/g, '');
  // Eine Stelle entscheidet, hier wie im Aufdruck -- siehe referenzBestimmen.
  const { typ: refType, wert: reference } = referenzBestimmen(cleanIban, data.reference);

  // 3. Build SIX-compliant String
  let content = 'SPC' + br; // Header
  content += '0200' + br;     // Version
  content += '1' + br;        // Coding
  content += cleanIban + br;  // Account

  // Creditor (Address Type K - Combined)
  // Ein Adressblock hat nach der Spezifikation immer sieben Felder, auch bei
  // Typ K: AdrTp, Name, AdrLine1, AdrLine2, PstCd, TwnNm, Ctry. Bei K bleiben
  // PstCd und TwnNm leer, weil Postleitzahl und Ort in AdrLine2 stehen -- aber
  // sie muessen als leere Felder dastehen. Ohne sie verschiebt sich alles
  // Nachfolgende und der Beleg ist nicht einlesbar.
  content += 'K' + br;
  content += sanitize(data.creditor.name, 70) + br;
  content += (sanitize(data.creditor.address) || 'Street 1') + br;
  content += (sanitize(data.creditor.zip) + ' ' + sanitize(data.creditor.city)).trim() + br;
  content += '' + br; // PstCd - bei Typ K leer
  content += '' + br; // TwnNm - bei Typ K leer
  content += normalizeCountry(data.creditor.country) + br; 

  // Ultimate Creditor (Empty)
  content += '' + br + '' + br + '' + br + '' + br + '' + br + '' + br + '' + br;

  // Amount
  content += (data.amount ? data.amount.toFixed(2) : '') + br;
  content += data.currency + br;

  // Debtor (Address Type K) -- ebenfalls sieben Felder.
  content += 'K' + br;
  content += sanitize(data.debtor.name, 70) + br;
  content += (sanitize(data.debtor.address) || 'Unknown St.') + br;
  content += (sanitize(data.debtor.zip) + ' ' + sanitize(data.debtor.city)).trim() + br;
  content += '' + br; // PstCd - bei Typ K leer
  content += '' + br; // TwnNm - bei Typ K leer
  content += normalizeCountry(data.debtor.country) + br;

  // Reference
  content += refType + br;
  content += reference + br;

  // Unstructured Message
  content += sanitize(data.additionalInfo, 140) + br;  // Ustrd darf 140, nicht 70

  // Trailer. Die optionalen Felder danach (Rechnungsinformationen, alternative
  // Verfahren) entfallen, damit der Beleg mit genau den 31 Pflichtfeldern endet.
  content += 'EPD';

  return content;
};
