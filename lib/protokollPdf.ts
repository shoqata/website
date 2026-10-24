// Das Vorstandsprotokoll als PDF -- fuer den Editor, die Ansicht, das
// Teilen per WhatsApp und den Versand per E-Mail. Eine Stelle, damit alle
// Wege dasselbe Blatt erzeugen.
//
// Gesetzt wird echter Text, nicht ein Abbild des Bildschirms. Ein
// abfotografiertes Fenster laesst sich weder durchsuchen noch kopieren, wird
// unnoetig gross und bricht an jeder Bildschirmbreite anders um.

type T = (k: string, p?: Record<string, string | number>) => string;

export type ProtokollPdf = { blob: Blob; base64: string; dateiname: string };

export function protokollDateiname(m: any): string {
  return `${(m?.title || 'Protokoll').replace(/[^\p{L}\p{N}]+/gu, '-')}-${m?.date || ''}.pdf`;
}

export async function protokollPdf(m: any, t: T): Promise<ProtokollPdf> {
  const { default: jsPDF } = await import('jspdf');
  const pdf = new jsPDF({ unit: 'mm', format: 'a4' });
  const rand = 18;
  const breite = 210 - rand * 2;
  let y = rand;

  const umbruch = (text: string, groesse: number, fett = false, einzug = 0) => {
    pdf.setFontSize(groesse);
    pdf.setFont('helvetica', fett ? 'bold' : 'normal');
    const zeilen = pdf.splitTextToSize(text, breite - einzug);
    zeilen.forEach((z: string) => {
      // Neue Seite, bevor der Text unten herauslaeuft.
      if (y > 275) { pdf.addPage(); y = rand; }
      pdf.text(z, rand + einzug, y);
      y += groesse * 0.45 + 1.4;
    });
  };
  const grau = (text: string, groesse = 10, einzug = 0) => { pdf.setTextColor(120); umbruch(text, groesse, false, einzug); pdf.setTextColor(0); };

  umbruch(m.title || t('minutes.heading'), 18, true);
  y += 1;
  grau([
    m.date ? new Date(m.date).toLocaleDateString('de-CH') : null,
    m.location || null,
    t('minutes.version', { n: m.version ?? 1 }),
  ].filter(Boolean).join('  ·  '));
  if (m.protokollfuehrer?.name) grau(`${t('minutes.minute_taker')}: ${m.protokollfuehrer.name}`);
  y += 3;

  const alle = (m.attendees || []) as any[];
  const anwesend = alle.filter(a => a.present && !a.guest).map(a => a.name);
  const gaeste = alle.filter(a => a.guest).map(a => a.name);
  umbruch(t('minutes.attendance'), 12, true);
  umbruch(anwesend.length ? anwesend.join(', ') : '—', 10, false, 2);
  if (gaeste.length) {
    y += 1;
    umbruch(t('minutes.guests'), 11, true);
    umbruch(gaeste.join(', '), 10, false, 2);
  }
  y += 3;

  const teil = (titel: string, liste: any[]) => {
    umbruch(titel, 12, true);
    if (!liste?.length) { umbruch('—', 10, false, 2); y += 2; return; }
    liste.forEach((e: any, i: number) => {
      umbruch(`${i + 1}. ${e.title || ''}`, 11, true, 2);
      if (e.content) umbruch(String(e.content).replace(/<[^>]*>/g, ''), 10, false, 6);
      if (e.responsible || e.dueDate) {
        grau([e.responsible && `${t('minutes.responsible')}: ${e.responsible}`,
              e.dueDate && new Date(e.dueDate).toLocaleDateString('de-CH')].filter(Boolean).join('  ·  '), 9, 6);
      }
      y += 1.5;
    });
    y += 2;
  };
  teil(t('minutes.agenda'), m.agendaItems || []);
  teil(t('minutes.decisions'), m.decisions || []);

  // Unterschrift des Protokollfuehrers -- ein Protokoll ohne Urheber belegt wenig.
  if (m.protokollfuehrer?.name) {
    if (y > 255) { pdf.addPage(); y = rand; }
    y += 8;
    pdf.setDrawColor(180); pdf.line(rand, y, rand + 70, y); y += 5;
    grau(`${t('minutes.minute_taker')}: ${m.protokollfuehrer.name}`, 9);
  }

  // Fusszeile auf jeder Seite: ohne sie ist ein ausgedrucktes Blatt nicht
  // zuzuordnen.
  const seiten = pdf.getNumberOfPages();
  for (let i = 1; i <= seiten; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.setTextColor(150);
    pdf.text(`${m.title || ''} · ${m.date ? new Date(m.date).toLocaleDateString('de-CH') : ''}`, rand, 289);
    pdf.text(`${i} / ${seiten}`, 210 - rand, 289, { align: 'right' });
  }

  const blob = pdf.output('blob') as Blob;
  const base64 = (pdf.output('datauristring') as string).split(',')[1] || '';
  return { blob, base64, dateiname: protokollDateiname(m) };
}

// Kurzfassung als Text -- fuer WhatsApp, wenn das Geraet keine Datei teilen kann.
export function protokollKurztext(m: any, t: T): string {
  const z: string[] = [`*${m.title || t('minutes.heading')}*`,
    [m.date ? new Date(m.date).toLocaleDateString('de-CH') : '', m.location].filter(Boolean).join(' · ')];
  if ((m.decisions || []).length) {
    z.push('', `${t('minutes.decisions')}:`);
    (m.decisions || []).forEach((d: any, i: number) => z.push(`${i + 1}. ${d.title || ''}${d.responsible ? ` (${d.responsible})` : ''}`));
  }
  if (m.protokollfuehrer?.name) z.push('', `${t('minutes.minute_taker')}: ${m.protokollfuehrer.name}`);
  return z.join('\n');
}
