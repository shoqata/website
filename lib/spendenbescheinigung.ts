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

export type Spende = {
  name: string | null; strasse: string | null; plz: string | null;
  ort: string | null; land: string | null;
  betrag: number; waehrung: string;
  referenz: string; eingegangen_am: string | null; zweck: string | null;
};

export type Verein = {
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

// --- Gemeinsame Bausteine -----------------------------------------------

async function neuesPdf() {
  // Beide Ausfuehrungen nehmen: im Browser liefert jspdf den Konstruktor
  // als Standard-Export, unter Node als benannten.
  const modul: any = await import('jspdf');
  const jsPDF = modul.jsPDF ?? modul.default;
  const pdf = new jsPDF({ unit: 'mm', format: 'a4' });
  await schriftEinbetten(pdf);
  return pdf;
}

const SCHRIFT = 'Noto';
const LINKS = 25;
const BREITE = 210 - 2 * LINKS;

// Eine Seite mit eigenem Schreibstand. Jede Zeile bricht um: Name, Strasse
// und Zweck kommen aus einem oeffentlichen Formular ohne Laengengrenze.
function blatt(pdf: any) {
  const b = {
    y: 28,
    zeile(text: string, groesse = 10, fett = false, abstand = 6, breite = BREITE, x = LINKS) {
      pdf.setFont(SCHRIFT, fett ? 'bold' : 'normal');
      pdf.setFontSize(groesse);
      const zeilen: string[] = pdf.splitTextToSize(text, breite);
      zeilen.forEach((z, i) => { pdf.text(z, x, b.y); b.y += i < zeilen.length - 1 ? groesse * 0.45 : abstand; });
    },
    absatz(text: string, groesse = 10, abstand = 5.4) {
      pdf.setFont(SCHRIFT, 'normal');
      pdf.setFontSize(groesse);
      pdf.splitTextToSize(text, BREITE).forEach((z: string) => { pdf.text(z, LINKS, b.y); b.y += abstand; });
    },
    feld(bezeichnung: string, wert: string, fett = false) {
      pdf.setFont(SCHRIFT, 'normal'); pdf.setFontSize(9); pdf.setTextColor(110);
      pdf.text(bezeichnung, LINKS, b.y);
      pdf.setTextColor(20);
      b.zeile(wert, fett ? 13 : 10.5, fett, fett ? 9 : 7, BREITE - 48, LINKS + 48);
    },
    linie(abstandVor = 10, abstandNach = 12) {
      b.y += abstandVor;
      pdf.setDrawColor(210);
      pdf.line(LINKS, b.y, LINKS + BREITE, b.y);
      b.y += abstandNach;
    },
  };
  return b;
}

type Empfaenger = { name: string | null; strasse: string | null; plz: string | null; ort: string | null; land: string | null };

function kopfzeilen(pdf: any, b: ReturnType<typeof blatt>, verein: Verein, an: Empfaenger, titel: string) {
  // Absender
  pdf.setTextColor(90);
  b.zeile(verein.name || '', 9, true, 4.4);
  [verein.strasse, [verein.plz, verein.ort].filter(Boolean).join(' '), verein.email]
    .filter(Boolean).forEach(t => b.zeile(String(t), 9, false, 4.2));
  pdf.setTextColor(20);
  b.y += 14;
  // Empfaenger
  const land = an.land && an.land !== 'CH' && an.land.toLowerCase() !== 'schweiz' ? landName(an.land) : null;
  [an.name, an.strasse, [an.plz, an.ort].filter(Boolean).join(' '), land]
    .filter(Boolean).forEach(t => b.zeile(String(t), 11, false, 5.2));
  b.y += 18;
  b.zeile(titel, 17, true, 12);
}

function schluss(pdf: any, b: ReturnType<typeof blatt>, verein: Verein) {
  b.absatz('Diese Bescheinigung dient dem Nachweis der Zuwendung gegenüber der '
       + 'Steuerbehörde. Ob und in welchem Umfang die Zuwendung abzugsfähig ist, '
       // Kein Bindestrich-Wort wie "Wohnsitzkantons bzw. -landes": der
       // Umbruch trennt dort und schiebt "-landes" allein in die Zeile.
       + 'richtet sich nach dem Recht des Wohnsitzkantons oder Wohnsitzlandes '
       + 'des Zuwendenden.', 9);
  b.y += 14;
  const ort = verein.ort || '';
  b.zeile(`${ort}${ort ? ', ' : ''}${datum(new Date().toISOString())}`, 10, false, 22);
  pdf.setDrawColor(150);
  pdf.line(LINKS, b.y, LINKS + 70, b.y);
  b.y += 5;
  pdf.setTextColor(110);
  b.zeile(verein.name || '', 8.5, false, 4, 70);
  pdf.setTextColor(20);
}

const geld = (n: number, w: string) =>
  `${Number(n).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${w}`;

// Akzente abstreifen statt Buchstaben zu verlieren: aus "Žaklina" wurde
// sonst "_aklina". Đ, ł, ß zerfallen nicht und brauchen eine Zuordnung.
const dateiname = (t: string | null) => (t || 'Spender')
  .replace(/[Đđ]/g, m => m === 'Đ' ? 'Dj' : 'dj').replace(/[Łł]/g, m => m === 'Ł' ? 'L' : 'l').replace(/ß/g, 'ss')
  .normalize('NFKD').replace(/\p{M}/gu, '')
  .replace(/[^A-Za-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'Spender';


// --- Einzelne Spende ----------------------------------------------------

export async function spendenbescheinigungErzeugen(spende: Spende, verein: Verein) {
  const pdf = await neuesPdf();
  const b = blatt(pdf);
  kopfzeilen(pdf, b, verein, spende, 'Spendenbescheinigung');

  b.absatz(`Wir bestätigen, von ${spende.name || 'der zuwendenden Person'} die nachstehend `
       + `aufgeführte Zuwendung erhalten zu haben. Es wurde dafür keine Gegenleistung erbracht.`);
  b.y += 6;
  b.feld('Betrag', geld(spende.betrag, spende.waehrung), true);
  // Leere Zeilen weglassen statt ein Etikett ohne Wert zu drucken.
  if (spende.eingegangen_am) b.feld('Eingegangen am', datum(spende.eingegangen_am));
  if (spende.referenz) b.feld('Referenz', spende.referenz);
  if (spende.zweck) b.feld('Zweck', spende.zweck);
  b.linie();
  schluss(pdf, b, verein);

  pdf.save(`Spendenbescheinigung_${dateiname(spende.name)}_${spende.referenz || 'ohne_Referenz'}.pdf`);
}


// --- Jahresbescheinigung ------------------------------------------------

// Alle Spenden eines Jahres auf einem Blatt -- so, wie die Steuererklaerung
// sie verlangt. Bisher gab es nur eine Bescheinigung je einzelne Spende;
// wer viermal im Jahr gab, bekam vier Blaetter und musste selbst addieren.
//
// Mehrere Spender ergeben ein PDF mit einer Seite (oder mehr) je Spender,
// zum Drucken in einem Zug.
export type Jahresspender = Empfaenger & {
  spenden: { betrag: number; waehrung: string; eingegangen_am: string | null; referenz: string | null; zweck: string | null }[];
};

export async function jahresbescheinigungenErzeugen(spender: Jahresspender[], verein: Verein, jahr: number) {
  if (!spender.length) return;
  const pdf = await neuesPdf();

  spender.forEach((s, nr) => {
    if (nr > 0) pdf.addPage();
    const b = blatt(pdf);
    kopfzeilen(pdf, b, verein, s, `Spendenbescheinigung ${jahr}`);

    const sortiert = [...s.spenden].sort((a, z) => String(a.eingegangen_am).localeCompare(String(z.eingegangen_am)));
    const summen = new Map<string, number>();
    sortiert.forEach(x => summen.set(x.waehrung, (summen.get(x.waehrung) || 0) + Number(x.betrag)));
    const gesamt = [...summen.entries()].map(([w, n]) => geld(n, w)).join(' und ');

    b.absatz(`Wir bestätigen, von ${s.name || 'der zuwendenden Person'} im Jahr ${jahr} `
      + (sortiert.length === 1
          ? 'die nachstehend aufgeführte Zuwendung erhalten zu haben.'
          : `Zuwendungen von insgesamt ${gesamt} erhalten zu haben, aufgeführt in der folgenden Aufstellung (${sortiert.length} Zahlungen).`)
      + ' Es wurde dafür keine Gegenleistung erbracht.');
    b.y += 6;

    // Tabelle: Datum | Zweck | Betrag. Rechts buendig, damit die Betraege
    // untereinander stehen.
    const xBetrag = LINKS + BREITE;
    const kopf = () => {
      pdf.setFont(SCHRIFT, 'normal'); pdf.setFontSize(8.5); pdf.setTextColor(110);
      pdf.text('Eingegangen', LINKS, b.y); pdf.text('Zweck / Referenz', LINKS + 32, b.y);
      pdf.text('Betrag', xBetrag, b.y, { align: 'right' });
      pdf.setTextColor(20); b.y += 2;
      pdf.setDrawColor(210); pdf.line(LINKS, b.y, xBetrag, b.y); b.y += 5;
    };
    kopf();
    sortiert.forEach(x => {
      // Neue Seite, bevor Zeile und Schluss nicht mehr passen.
      if (b.y > 250) {
        pdf.addPage(); b.y = 28;
        // Wem gehoert dieses Blatt? Bei "alle als ein PDF" sonst nicht zu erkennen.
        pdf.setFont(SCHRIFT, 'bold'); pdf.setFontSize(10);
        pdf.text(`${s.name || ''} · Spendenbescheinigung ${jahr} (Fortsetzung)`, LINKS, b.y); b.y += 9;
        kopf();
      }
      pdf.setFont(SCHRIFT, 'normal'); pdf.setFontSize(9.5);
      pdf.text(x.eingegangen_am ? new Date(x.eingegangen_am).toLocaleDateString('de-CH') : '–', LINKS, b.y);
      pdf.text(geld(x.betrag, x.waehrung), xBetrag, b.y, { align: 'right' });
      const text = [x.zweck, x.referenz].filter(Boolean).join(' · ') || '–';
      const zeilen: string[] = pdf.splitTextToSize(text, BREITE - 32 - 34);
      zeilen.forEach((z, i) => { pdf.text(z, LINKS + 32, b.y); if (i < zeilen.length - 1) b.y += 4.3; });
      b.y += 6;
    });
    pdf.setDrawColor(150); pdf.line(LINKS, b.y - 3, xBetrag, b.y - 3); b.y += 2;
    pdf.setFont(SCHRIFT, 'bold'); pdf.setFontSize(11);
    pdf.text('Total', LINKS, b.y);
    pdf.text(gesamt, xBetrag, b.y, { align: 'right' });
    b.y += 4;

    if (b.y > 215) { pdf.addPage(); b.y = 28; }
    b.linie(10, 12);
    schluss(pdf, b, verein);
  });

  pdf.save(spender.length === 1
    ? `Spendenbescheinigung_${jahr}_${dateiname(spender[0].name)}.pdf`
    : `Spendenbescheinigungen_${jahr}_alle_${spender.length}.pdf`);
}
