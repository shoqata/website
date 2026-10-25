// Die Spendenbescheinigung als PDF.
//
// Bis zum 29.09.2026 setzte der Knopf "bescheinigen" nur ein Datum in der
// Datenbank. Der Verein hatte damit festgehalten, dass er bescheinigt hat --
// und nichts in der Hand, was er dem Spender geben konnte.
//
// Geschrieben wird echter Text, nicht ein Bild der Seite wie bei den
// Rechnungen. Eine Bescheinigung wird abgelegt, durchsucht und manchmal
// weitergereicht; ein Bild davon waere unnoetig schwer und nicht lesbar fuer
// eine Maschine.

type Spende = {
  name: string | null; strasse: string | null; plz: string | null;
  ort: string | null; land: string | null;
  betrag: number; waehrung: string;
  referenz: string; eingegangen_am: string | null; zweck: string | null;
};

type Verein = {
  name?: string; strasse?: string; plz?: string; ort?: string;
  email?: string; land?: string;
};

const datum = (s?: string | null) =>
  s ? new Date(s).toLocaleDateString('de-CH', { day: '2-digit', month: 'long', year: 'numeric' }) : '';

// Laendercodes ausschreiben. Ein Spender in Pristina bekommt sonst "XK"
// unter seine Adresse -- die Post versteht das, eine Steuerbehoerde nicht
// unbedingt.
const landName = (code?: string | null) => {
  if (!code) return null;
  if (code.length !== 2) return code;
  try { return new Intl.DisplayNames(['de-CH'], { type: 'region' }).of(code.toUpperCase()) || code; }
  catch { return code; }
};

// Helvetica, die in jsPDF eingebaute Schrift, kennt nur Latin-1: ë und ç
// gehen, aber aus "Wiśniewska" wird "Wi[niewska" und aus "Đorđević"
// Zeichensalat. Auf einem Beleg mit dem Namen des Spenders ist das kein
// Schoenheitsfehler. Noto Sans deckt Latein, Kyrillisch und Griechisch ab
// und wird erst geladen, wenn tatsaechlich eine Bescheinigung entsteht.
async function schriftEinbetten(pdf: any) {
  const base64 = async (url: string) => {
    const r = await fetch(url);
    if (!r.ok) throw new Error(`Schrift ${url} nicht geladen (${r.status})`);
    const bytes = new Uint8Array(await r.arrayBuffer());
    let bin = '';
    for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    return btoa(bin);
  };
  const [normal, fett] = await Promise.all([
    base64('/fonts/NotoSans-Regular.ttf'), base64('/fonts/NotoSans-Bold.ttf'),
  ]);
  pdf.addFileToVFS('NotoSans-Regular.ttf', normal);
  pdf.addFont('NotoSans-Regular.ttf', 'Noto', 'normal');
  pdf.addFileToVFS('NotoSans-Bold.ttf', fett);
  pdf.addFont('NotoSans-Bold.ttf', 'Noto', 'bold');
}

export async function spendenbescheinigungErzeugen(spende: Spende, verein: Verein) {
  // Beide Ausfuehrungen nehmen: im Browser liefert jspdf den Konstruktor
  // als Standard-Export, unter Node als benannten.
  const modul: any = await import('jspdf');
  const jsPDF = modul.jsPDF ?? modul.default;
  const pdf = new jsPDF({ unit: 'mm', format: 'a4' });
  await schriftEinbetten(pdf);
  const SCHRIFT = 'Noto';

  const links = 25;
  const breite = 210 - 2 * links;
  let y = 28;

  // Jede Zeile bricht um. Name, Strasse und Zweck kommen aus einem
  // oeffentlichen Formular ohne Laengengrenze -- ungebrochen liefen sie
  // ueber den Papierrand.
  const zeile = (text: string, groesse = 10, fett = false, abstand = 6, b = breite, x = links) => {
    pdf.setFont(SCHRIFT, fett ? 'bold' : 'normal');
    pdf.setFontSize(groesse);
    const zeilen: string[] = pdf.splitTextToSize(text, b);
    zeilen.forEach((z, i) => { pdf.text(z, x, y); y += i < zeilen.length - 1 ? groesse * 0.45 : abstand; });
  };
  const absatz = (text: string, groesse = 10, abstand = 5.4) => {
    pdf.setFont(SCHRIFT, 'normal');
    pdf.setFontSize(groesse);
    pdf.splitTextToSize(text, breite).forEach((z: string) => { pdf.text(z, links, y); y += abstand; });
  };

  // --- Absender ---------------------------------------------------------
  pdf.setTextColor(90);
  zeile(verein.name || '', 9, true, 4.4);
  [verein.strasse, [verein.plz, verein.ort].filter(Boolean).join(' '), verein.email]
    .filter(Boolean).forEach(t => zeile(String(t), 9, false, 4.2));
  pdf.setTextColor(20);
  y += 14;

  // --- Empfaenger -------------------------------------------------------
  const land = spende.land && spende.land !== 'CH' && spende.land.toLowerCase() !== 'schweiz'
    ? landName(spende.land) : null;
  [spende.name, spende.strasse, [spende.plz, spende.ort].filter(Boolean).join(' '), land]
    .filter(Boolean).forEach(t => zeile(String(t), 11, false, 5.2));
  y += 18;

  // --- Titel ------------------------------------------------------------
  zeile('Spendenbescheinigung', 17, true, 12);

  // --- Der Kern ---------------------------------------------------------
  absatz(`Wir bestätigen, von ${spende.name || 'der zuwendenden Person'} die nachstehend `
       + `aufgeführte Zuwendung erhalten zu haben. Es wurde dafür keine Gegenleistung erbracht.`);
  y += 6;

  const feld = (bezeichnung: string, wert: string, fett = false) => {
    pdf.setFont(SCHRIFT, 'normal'); pdf.setFontSize(9); pdf.setTextColor(110);
    pdf.text(bezeichnung, links, y);
    pdf.setTextColor(20);
    zeile(wert, fett ? 13 : 10.5, fett, fett ? 9 : 7, breite - 48, links + 48);
  };

  feld('Betrag', `${Number(spende.betrag).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${spende.waehrung}`, true);
  // Leere Zeilen weglassen statt ein Etikett ohne Wert zu drucken.
  if (spende.eingegangen_am) feld('Eingegangen am', datum(spende.eingegangen_am));
  if (spende.referenz) feld('Referenz', spende.referenz);
  if (spende.zweck) feld('Zweck', spende.zweck);

  y += 10;
  pdf.setDrawColor(210);
  pdf.line(links, y, links + breite, y);
  y += 12;

  absatz('Diese Bescheinigung dient dem Nachweis der Zuwendung gegenüber der '
       + 'Steuerbehörde. Ob und in welchem Umfang die Zuwendung abzugsfähig ist, '
       // Kein Bindestrich-Wort wie "Wohnsitzkantons bzw. -landes": der
       // Umbruch trennt dort und schiebt "-landes" allein in die Zeile.
       + 'richtet sich nach dem Recht des Wohnsitzkantons oder Wohnsitzlandes '
       + 'des Zuwendenden.', 9);
  y += 14;

  const ort = verein.ort || '';
  zeile(`${ort}${ort ? ', ' : ''}${datum(new Date().toISOString())}`, 10, false, 22);

  pdf.setDrawColor(150);
  pdf.line(links, y, links + 70, y);
  y += 5;
  pdf.setFontSize(8.5); pdf.setTextColor(110);
  zeile(verein.name || '', 8.5, false, 4, 70);

  // Akzente abstreifen statt Buchstaben zu verlieren: aus "Žaklina" wurde
  // sonst "_aklina".
  // Đ, ł, ß zerfallen nicht in Buchstabe + Akzent und brauchen eine Zuordnung.
  const sauber = (spende.name || 'Spender')
    .replace(/[Đđ]/g, m => m === 'Đ' ? 'Dj' : 'dj').replace(/[Łł]/g, m => m === 'Ł' ? 'L' : 'l').replace(/ß/g, 'ss')
    .normalize('NFKD').replace(/\p{M}/gu, '')
    .replace(/[^A-Za-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'Spender';
  pdf.save(`Spendenbescheinigung_${sauber}_${spende.referenz || 'ohne_Referenz'}.pdf`);
}
