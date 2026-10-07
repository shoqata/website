// Die Rechnung als Anhang.
//
// Bis hierher ging eine Rechnung nur als HTML im Mailtext hinaus: keine
// Datei, nichts zum Ablegen, nichts zum Weitergeben an den Treuhaender.
// Und die Zahlungsangaben standen als blosser Text da -- der Swiss QR
// wurde zwar in der Oberflaeche gezeichnet, kam aber nie in die Mail.
//
// Gebaut wie die Spendenbescheinigung: jsPDF, dynamisch geladen, und
// Text als Vektor statt als Bild. Eine Seite wiegt so wenige Kilobyte.
// html2canvas waere einfacher gewesen und haette ein halbes Megabyte
// Pixelbrei je Rechnung erzeugt -- bei dreihundert Mitgliedern ist das
// der Unterschied zwischen einem Versand und einem verstopften Postfach.
//
// Welche Zahlungsangaben draufstehen, entscheidet der Wohnsitz:
// Schweiz heisst Swiss QR, alles andere heisst Bankverbindung und
// PayPal. Eine QR-Rechnung nuetzt einer deutschen Bank nichts.

import { generateQrCodeContent, referenzBestimmen, formatIban, formatReference, istSchweiz }
  from '../services/qrBillService';

export type RechnungDaten = {
  nummer: string;
  datum: string;              // ISO
  faellig?: string | null;    // ISO
  betrag: number;
  waehrung: 'CHF' | 'EUR';
  zweck: string;              // wofuer, eine Zeile
  verein: {
    name: string; adresse?: string; plz?: string; ort?: string; land?: string;
    iban?: string; qrIban?: string; bic?: string; bank?: string;
    paypal?: string; twint?: string;
  };
  empfaenger: {
    name: string; adresse?: string; plz?: string; ort?: string; land?: string;
  };
  referenz?: string;
};

const geld = (n: number) =>
  Number(n || 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const tag = (iso?: string | null) => {
  if (!iso) return '';
  const d = new Date(iso);
  return isNaN(d.getTime()) ? '' : d.toLocaleDateString('de-CH');
};

// Der QR als Bild. qrcode.react ist eine React-Komponente und kennt
// keinen Weg, eine Matrix herauszugeben -- also wird sie kurz in einen
// losgeloesten Knoten gezeichnet und die Leinwand ausgelesen. Das nutzt
// React und qrcode.react, die beide ohnehin geladen sind; der Umweg
// ueber react-dom/server haette 268 KB gekostet, nur um einen String
// zu erzeugen.
async function qrAlsBild(inhalt: string, px = 480): Promise<string | null> {
  if (typeof document === 'undefined') return null;
  try {
    const [{ createRoot }, { flushSync }, { QRCodeCanvas }, React] = await Promise.all([
      import('react-dom/client'), import('react-dom'), import('qrcode.react'), import('react'),
    ]);
    const halter = document.createElement('div');
    halter.style.cssText = 'position:fixed;left:-10000px;top:0;width:0;height:0;overflow:hidden';
    document.body.appendChild(halter);
    const wurzel = createRoot(halter);
    try {
      flushSync(() => {
        wurzel.render(React.createElement(QRCodeCanvas as any, {
          value: inhalt, size: px, level: 'M', bgColor: '#ffffff', fgColor: '#000000',
          includeMargin: false,
        }));
      });
      const leinwand = halter.querySelector('canvas');
      return leinwand ? (leinwand as HTMLCanvasElement).toDataURL('image/png') : null;
    } finally {
      wurzel.unmount();
      halter.remove();
    }
  } catch {
    // Kein QR ist besser als eine halbe Rechnung: der Aufrufer faellt
    // dann auf die Bankangaben zurueck.
    return null;
  }
}

export async function erzeugeRechnungPdf(
  d: RechnungDaten,
): Promise<{ base64: string; dateiname: string; bytes: number; mitQr: boolean }> {
  const modul: any = await import('jspdf');
  const jsPDF = modul.jsPDF || modul.default?.jsPDF || modul.default;
  const pdf = new jsPDF({ unit: 'mm', format: 'a4', compress: true });

  const L = 20;                 // linker Rand
  const R = 190;                // rechter Satzspiegel
  let y = 22;

  const schrift = (groesse: number, fett = false, grau = false) => {
    pdf.setFont('helvetica', fett ? 'bold' : 'normal');
    pdf.setFontSize(groesse);
    pdf.setTextColor(grau ? 110 : 20);
  };
  const zeile = (text: string, x = L, groesse = 10, fett = false, grau = false) => {
    schrift(groesse, fett, grau);
    pdf.text(text, x, y);
    y += groesse * 0.52;
  };

  // ---------------------------------------------------------- Absender
  zeile(d.verein.name, L, 13, true);
  schrift(8.5, false, true);
  const absender = [d.verein.adresse, [d.verein.plz, d.verein.ort].filter(Boolean).join(' ')]
    .filter(Boolean);
  absender.forEach(t => { pdf.text(String(t), L, y); y += 4; });

  // --------------------------------------------------------- Empfaenger
  y = 52;
  schrift(10.5, false);
  pdf.text(d.empfaenger.name, L, y); y += 5;
  schrift(10, false);
  [d.empfaenger.adresse, [d.empfaenger.plz, d.empfaenger.ort].filter(Boolean).join(' ')]
    .filter(Boolean)
    .forEach(t => { pdf.text(String(t), L, y); y += 5; });

  // ------------------------------------------------------------ Kopf
  y = 86;
  zeile(`Rechnung ${d.nummer}`, L, 16, true);
  y += 2;
  schrift(9.5, false, true);
  const kopf = [`Datum: ${tag(d.datum)}`];
  if (d.faellig) kopf.push(`Zahlbar bis: ${tag(d.faellig)}`);
  pdf.text(kopf.join('     '), L, y); y += 9;

  // --------------------------------------------------------- Position
  pdf.setDrawColor(210); pdf.setLineWidth(0.3);
  pdf.line(L, y, R, y); y += 6;
  schrift(10, true);
  pdf.text('Position', L, y);
  pdf.text('Betrag', R, y, { align: 'right' });
  y += 2.5;
  pdf.line(L, y, R, y); y += 7;

  schrift(10.5, false);
  // Lange Zwecke umbrechen statt ueber den Rand schieben.
  const zeilen: string[] = pdf.splitTextToSize(d.zweck, 120);
  zeilen.forEach((t: string, i: number) => {
    pdf.text(t, L, y + i * 5);
  });
  pdf.text(`${d.waehrung} ${geld(d.betrag)}`, R, y, { align: 'right' });
  y += Math.max(zeilen.length * 5, 5) + 3;

  pdf.line(L, y, R, y); y += 7;
  schrift(12, true);
  pdf.text('Total', L, y);
  pdf.text(`${d.waehrung} ${geld(d.betrag)}`, R, y, { align: 'right' });
  y += 12;

  // ----------------------------------------------------- Zahlungsteil
  const schweiz = istSchweiz(d.empfaenger.land);
  const iban = (schweiz ? (d.verein.qrIban || d.verein.iban) : d.verein.iban) || '';
  let mitQr = false;

  if (schweiz && iban) {
    const ref = referenzBestimmen(iban, d.referenz);
    const inhalt = generateQrCodeContent({
      amount: d.betrag,
      currency: d.waehrung,
      iban,
      creditor: {
        name: d.verein.name, address: d.verein.adresse || '',
        zip: d.verein.plz || '', city: d.verein.ort || '', country: d.verein.land || 'CH',
      },
      debtor: {
        name: d.empfaenger.name, address: d.empfaenger.adresse || '',
        zip: d.empfaenger.plz || '', city: d.empfaenger.ort || '', country: d.empfaenger.land || 'CH',
      },
      reference: ref.wert,
      referenceType: ref.typ,
      additionalInfo: d.zweck,
    });
    const bild = await qrAlsBild(inhalt);

    schrift(11, true);
    pdf.text('Zahlbar mit Swiss QR', L, y); y += 6;

    if (bild) {
      pdf.addImage(bild, 'PNG', L, y, 42, 42);
      mitQr = true;
      const tx = L + 48;
      let ty = y + 5;
      schrift(8, false, true); pdf.text('Konto', tx, ty); ty += 4;
      schrift(9.5, false);     pdf.text(formatIban(iban), tx, ty); ty += 6;
      schrift(8, false, true); pdf.text('Zugunsten', tx, ty); ty += 4;
      schrift(9.5, false);     pdf.text(d.verein.name, tx, ty); ty += 6;
      if (ref.typ !== 'NON') {
        schrift(8, false, true); pdf.text('Referenz', tx, ty); ty += 4;
        schrift(9.5, false);     pdf.text(formatReference(ref.wert, ref.typ), tx, ty); ty += 6;
      }
      schrift(8, false, true); pdf.text('Betrag', tx, ty); ty += 4;
      schrift(10.5, true);     pdf.text(`${d.waehrung} ${geld(d.betrag)}`, tx, ty);
      y += 48;
    } else {
      // Der QR liess sich nicht zeichnen. Dann die Angaben im Klartext,
      // statt eine Rechnung ohne Zahlungsweg zu verschicken.
      schrift(9.5, false);
      pdf.text(`Konto: ${formatIban(iban)}`, L, y); y += 5;
      pdf.text(`Zugunsten: ${d.verein.name}`, L, y); y += 5;
      if (ref.typ !== 'NON') {
        pdf.text(`Referenz: ${formatReference(ref.wert, ref.typ)}`, L, y); y += 5;
      }
    }
    if (d.verein.twint) {
      schrift(9, false, true);
      pdf.text(`TWINT: ${d.verein.twint}`, L, y); y += 5;
    }
  } else {
    // Ausserhalb der Schweiz: eine QR-Rechnung kann die Bank dort nicht
    // lesen. Also Bankverbindung und PayPal.
    schrift(11, true);
    pdf.text('Zahlungsangaben', L, y); y += 6;
    schrift(9.5, false);
    const angaben: string[] = [];
    if (d.verein.bank) angaben.push(`Bank: ${d.verein.bank}`);
    angaben.push(`Kontoinhaber: ${d.verein.name}`);
    if (iban) angaben.push(`IBAN: ${formatIban(iban)}`);
    if (d.verein.bic) angaben.push(`BIC/SWIFT: ${d.verein.bic}`);
    angaben.push(`Verwendungszweck: ${d.nummer}`);
    angaben.forEach(t => { pdf.text(t, L, y); y += 5; });

    if (d.verein.paypal) {
      y += 3;
      schrift(10, true); pdf.text('PayPal', L, y); y += 5;
      schrift(9.5, false); pdf.text(d.verein.paypal, L, y); y += 5;
    }
  }

  // ------------------------------------------------------------ Fuss
  schrift(8, false, true);
  pdf.text(`${d.verein.name} · ${[d.verein.plz, d.verein.ort].filter(Boolean).join(' ')}`,
           L, 285);

  const roh: string = pdf.output('datauristring');
  const base64 = roh.substring(roh.indexOf(',') + 1);
  const dateiname = `Rechnung_${String(d.nummer).replace(/[^A-Za-z0-9._-]+/g, '_')}.pdf`;
  // Groesse der Datei, nicht der base64-Zeichenkette: base64 traegt ein
  // Drittel Luft, und wer die Zahl meldet, soll die echte melden.
  const bytes = Math.round((base64.length * 3) / 4);
  return { base64, dateiname, bytes, mitQr };
}
