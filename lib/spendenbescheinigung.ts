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

export async function spendenbescheinigungErzeugen(spende: Spende, verein: Verein) {
  // Beide Ausfuehrungen nehmen: im Browser liefert jspdf den Konstruktor
  // als Standard-Export, unter Node als benannten. Nur einen zu nehmen
  // heisst, sich auf eine Umgebung festzulegen -- und die Pruefung lief
  // prompt in "jsPDF is not a constructor".
  const modul: any = await import('jspdf');
  const jsPDF = modul.jsPDF ?? modul.default;
  const pdf = new jsPDF({ unit: 'mm', format: 'a4' });

  const links = 25;
  const breite = 210 - 2 * links;
  let y = 28;

  const zeile = (text: string, groesse = 10, fett = false, abstand = 6) => {
    pdf.setFont('helvetica', fett ? 'bold' : 'normal');
    pdf.setFontSize(groesse);
    pdf.text(text, links, y);
    y += abstand;
  };
  const absatz = (text: string, groesse = 10, abstand = 5.4) => {
    pdf.setFont('helvetica', 'normal');
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
  zeile(spende.name || '', 11, false, 5.2);
  [spende.strasse, [spende.plz, spende.ort].filter(Boolean).join(' '),
   spende.land && spende.land !== 'CH' ? spende.land : null]
    .filter(Boolean).forEach(t => zeile(String(t), 11, false, 5.2));
  y += 18;

  // --- Titel ------------------------------------------------------------
  zeile('Spendenbescheinigung', 17, true, 12);

  // --- Der Kern ---------------------------------------------------------
  absatz(`Wir bestätigen, von ${spende.name} die nachstehend aufgeführte Zuwendung `
       + `erhalten zu haben. Es wurde dafür keine Gegenleistung erbracht.`);
  y += 6;

  const feld = (bezeichnung: string, wert: string, fett = false) => {
    pdf.setFont('helvetica', 'normal'); pdf.setFontSize(9); pdf.setTextColor(110);
    pdf.text(bezeichnung, links, y);
    pdf.setFont('helvetica', fett ? 'bold' : 'normal');
    pdf.setFontSize(fett ? 13 : 10.5); pdf.setTextColor(20);
    pdf.text(wert, links + 48, y);
    pdf.setTextColor(20);
    y += fett ? 9 : 7;
  };

  feld('Betrag', `${Number(spende.betrag).toLocaleString('de-CH', { minimumFractionDigits: 2 })} ${spende.waehrung}`, true);
  feld('Eingegangen am', datum(spende.eingegangen_am));
  feld('Referenz', spende.referenz);
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
  pdf.text(verein.name || '', links, y);

  const sauber = (spende.name || 'Spender').replace(/[^A-Za-zÄÖÜäöü0-9]+/g, '_');
  pdf.save(`Spendenbescheinigung_${sauber}_${spende.referenz}.pdf`);
}
