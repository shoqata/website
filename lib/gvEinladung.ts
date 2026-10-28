// Die Einladung zur Generalversammlung -- als E-Mail und als Brief.
//
// Bis zum 28.10.2026 bestand die E-Mail aus nackten Absaetzen und einer
// Aufzaehlung, und "drucken" zerlegte dieses HTML zu reinem Text in
// Systemschrift. Eine Einladung ist aber das Schreiben, mit dem der Verein
// einmal im Jahr alle Mitglieder anspricht; sie soll nach dem Verein
// aussehen, nicht nach einem Formular.
//
// Die E-Mail ist mit Tabellen und Inline-Stilen gebaut: viele Mailprogramme
// ignorieren <style>, Flexbox und Webschriften. Der Brief darf beides.

export type Traktandum = { titel: string; abstimmung: boolean };
export type Einladung = {
  titel: string; datum: string; zeit: string | null; ort: string | null;
  traktanden: Traktandum[];
};
export type Absender = {
  verein: string; logo?: string | null; farbe?: string | null;
  strasse?: string | null; plz?: string | null; ort?: string | null; email?: string | null;
};

const esc = (s: string) => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]!));
const datumLang = (d: string) => new Date(d + 'T12:00:00').toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

// Nur was sicher in ein style-Attribut darf. Die Farbe kommt aus den
// Einstellungen des Vereins, nicht aus festem Code.
const farbeVon = (f?: string | null) =>
  f && /^(#[0-9a-f]{3,8}|rgb\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\))$/i.test(f.trim()) ? f.trim() : '#9f1239';
const logoVon = (l?: string | null) => (l && /^https:\/\//i.test(l) ? l : null);
const karteVon = (ort: string) => `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(ort)}`;
const adresse = (a: Absender) => [a.strasse, [a.plz, a.ort].filter(Boolean).join(' ')].filter(Boolean).join(' · ');

// ------------------------------------------------------------------ E-Mail
export function einladungMail(x: Einladung, a: Absender): string {
  const farbe = farbeVon(a.farbe);
  const logo = logoVon(a.logo);
  const schrift = "font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif";
  const kachel = (label: string, wert: string, zusatz = '') => `
    <td valign="top" style="padding:16px 18px;background:#f7f5f2;border-radius:10px">
      <div style="${schrift};font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:#8a8580">${label}</div>
      <div style="${schrift};font-size:16px;font-weight:600;color:#1c1917;margin-top:4px;line-height:1.35">${wert}</div>${zusatz}
    </td>`;
  const zeilen = x.traktanden.filter(t => t.titel.trim()).map((t, i) => `
    <tr>
      <td valign="top" width="34" style="padding:12px 0;border-top:1px solid #eeebe7;${schrift};font-size:14px;font-weight:700;color:${farbe}">${i + 1}.</td>
      <td valign="top" style="padding:12px 0;border-top:1px solid #eeebe7;${schrift};font-size:15px;color:#292524;line-height:1.45">${esc(t.titel)}</td>
      <td valign="top" align="right" style="padding:12px 0 12px 10px;border-top:1px solid #eeebe7;white-space:nowrap">${t.abstimmung
        ? `<span style="${schrift};font-size:10px;letter-spacing:.06em;text-transform:uppercase;color:${farbe};border:1px solid ${farbe};border-radius:20px;padding:3px 8px">Abstimmung</span>` : ''}</td>
    </tr>`).join('');

  return `<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;padding:0;background:#efece8">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#efece8"><tr><td align="center" style="padding:28px 12px">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:100%;max-width:600px;background:#ffffff;border-radius:14px;overflow:hidden">
  <tr><td style="background:${farbe};padding:22px 32px">
    <table role="presentation" cellpadding="0" cellspacing="0"><tr>
      ${logo ? `<td style="padding-right:14px"><img src="${esc(logo)}" alt="" width="44" height="44" style="display:block;width:44px;height:44px;object-fit:contain;background:#ffffff;border-radius:8px;padding:4px"></td>` : ''}
      <td style="${schrift};font-size:17px;font-weight:600;color:#ffffff">${esc(a.verein)}</td>
    </tr></table>
  </td></tr>
  <tr><td style="padding:36px 32px 8px">
    <div style="${schrift};font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:${farbe};font-weight:700">Einladung</div>
    <h1 style="${schrift};font-size:28px;line-height:1.2;color:#1c1917;margin:8px 0 18px;font-weight:700">${esc(x.titel)}</h1>
    <p style="${schrift};font-size:15px;line-height:1.6;color:#44403c;margin:0">Liebe Mitglieder<br><br>Wir laden Sie herzlich zur <b>${esc(x.titel)}</b> ein und freuen uns, Sie dabei zu haben.</p>
  </td></tr>
  <tr><td style="padding:22px 32px 6px">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
      ${kachel('Datum', esc(datumLang(x.datum)))}
      <td width="10"></td>
      ${kachel('Zeit', x.zeit ? `${esc(x.zeit)} Uhr` : '—')}
    </tr>${x.ort ? `<tr><td colspan="3" height="10"></td></tr><tr>
      ${kachel('Ort', esc(x.ort), `<div style="margin-top:8px"><a href="${karteVon(x.ort)}" style="${schrift};font-size:13px;color:${farbe};font-weight:600;text-decoration:none">Auf der Karte ansehen →</a></div>`).replace('<td valign="top"', '<td colspan="3" valign="top"')}
    </tr>` : ''}</table>
  </td></tr>
  <tr><td style="padding:28px 32px 4px">
    <div style="${schrift};font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#8a8580;font-weight:700;margin-bottom:6px">Traktanden</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">${zeilen}</table>
  </td></tr>
  <tr><td style="padding:22px 32px 34px">
    <p style="${schrift};font-size:14px;line-height:1.6;color:#57534e;margin:0 0 18px;padding:14px 16px;border-left:3px solid ${farbe};background:#faf8f6">Anträge zuhanden der Versammlung richten Sie bitte schriftlich an den Vorstand.</p>
    <p style="${schrift};font-size:15px;line-height:1.6;color:#44403c;margin:0">Wir freuen uns auf Ihre Teilnahme.<br><b>Der Vorstand von ${esc(a.verein)}</b></p>
  </td></tr>
  ${adresse(a) || a.email ? `<tr><td style="padding:16px 32px;border-top:1px solid #eeebe7;${schrift};font-size:12px;color:#a8a29e">${esc([a.verein, adresse(a), a.email].filter(Boolean).join(' · '))}</td></tr>` : ''}
</table>
</td></tr></table>
</body></html>`;
}

// ------------------------------------------------------------------ Klartext
// Fuer Mailprogramme ohne HTML. Frueher aus dem HTML zurechtgeschnitten;
// aus den Daten gebaut ist er verlaesslicher.
export function einladungText(x: Einladung, a: Absender): string {
  return [
    `EINLADUNG – ${x.titel}`, '',
    'Liebe Mitglieder', '',
    `Wir laden Sie herzlich zur ${x.titel} ein.`, '',
    `Datum: ${datumLang(x.datum)}`,
    ...(x.zeit ? [`Zeit:  ${x.zeit} Uhr`] : []),
    ...(x.ort ? [`Ort:   ${x.ort}`] : []), '',
    'TRAKTANDEN',
    ...x.traktanden.filter(t => t.titel.trim()).map((t, i) => `${i + 1}. ${t.titel}${t.abstimmung ? ' (Abstimmung)' : ''}`), '',
    'Anträge zuhanden der Versammlung richten Sie bitte schriftlich an den Vorstand.', '',
    'Wir freuen uns auf Ihre Teilnahme.',
    `Der Vorstand von ${a.verein}`,
  ].join('\n');
}

// ------------------------------------------------------------------ Brief
export function einladungBrief(x: Einladung, a: Absender): string {
  const farbe = farbeVon(a.farbe);
  const logo = logoVon(a.logo);
  const heute = new Date().toLocaleDateString('de-CH', { day: 'numeric', month: 'long', year: 'numeric' });
  const punkte = x.traktanden.filter(t => t.titel.trim()).map((t, i) => `
    <li><span class="nr">${i + 1}</span><span class="tt">${esc(t.titel)}</span>${t.abstimmung ? '<span class="ab">Abstimmung</span>' : ''}</li>`).join('');
  return `<!doctype html><html lang="de"><head><meta charset="utf-8"><title>${esc(x.titel)}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600&family=Inter:wght@400;500;600&display=swap">
<style>
@page{size:A4;margin:0}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Inter,system-ui,sans-serif;color:#292524;-webkit-print-color-adjust:exact;print-color-adjust:exact;background:#fff}
/* min-height, nicht height: mit mehr Traktanden laeuft der Brief auf eine
   zweite Seite weiter, statt unten abgeschnitten zu werden. */
.blatt{width:210mm;min-height:297mm;padding:14mm 20mm 9mm;position:relative;display:flex;flex-direction:column}
.band{position:absolute;left:0;top:0;bottom:0;width:6mm;background:${farbe}}
.kopf{display:flex;justify-content:space-between;align-items:flex-start;gap:10mm}
.marke{display:flex;align-items:center;gap:4mm}
.marke img{width:16mm;height:16mm;object-fit:contain}
.marke b{font-size:13pt;font-weight:600}
.abs{text-align:right;font-size:8.5pt;line-height:1.5;color:#78716c}
.auge{margin-top:13mm;font-size:9pt;letter-spacing:.16em;text-transform:uppercase;font-weight:600;color:${farbe}}
h1{font-family:Fraunces,Georgia,serif;font-weight:600;font-size:30pt;line-height:1.08;letter-spacing:-.01em;margin-top:3mm;color:#1c1917}
.anrede{margin-top:6mm;font-size:11pt;line-height:1.6;max-width:150mm}
.eckdaten{margin-top:7mm;display:grid;grid-template-columns:1.4fr .7fr 1.6fr;border-top:1.5px solid #1c1917;border-bottom:1px solid #e7e5e4}
.eckdaten div{padding:4mm 4mm 4mm 0}
.eckdaten div+div{padding-left:5mm;border-left:1px solid #e7e5e4}
.eckdaten span{display:block;font-size:7.5pt;letter-spacing:.14em;text-transform:uppercase;color:#a8a29e;font-weight:600}
.eckdaten b{display:block;margin-top:1.5mm;font-size:11pt;font-weight:600;line-height:1.35}
h2{margin-top:8mm;font-size:8.5pt;letter-spacing:.16em;text-transform:uppercase;color:#78716c;font-weight:600}
ol{list-style:none;margin-top:3mm}
li{break-inside:avoid;display:flex;align-items:baseline;gap:4mm;padding:1.6mm 0;border-bottom:1px solid #f0eeec;font-size:11pt;line-height:1.4}
.nr{flex:none;width:7mm;height:7mm;border-radius:50%;background:${farbe};color:#fff;font-size:8.5pt;font-weight:600;display:inline-flex;align-items:center;justify-content:center;transform:translateY(1.2mm)}
.tt{flex:1}
.ab{flex:none;font-size:7pt;letter-spacing:.1em;text-transform:uppercase;color:${farbe};border:1px solid ${farbe};border-radius:10mm;padding:.8mm 2.4mm}
.hinweis{margin-top:6mm;padding:4mm 5mm;border-left:1mm solid ${farbe};background:#faf8f6;font-size:10pt;line-height:1.5;color:#57534e}
.gruss{margin-top:auto;padding-top:7mm;font-size:11pt;line-height:1.6}
.gruss b{font-weight:600}
.fuss{margin-top:8mm;padding-top:3mm;border-top:1px solid #e7e5e4;font-size:8pt;color:#a8a29e;display:flex;justify-content:space-between}
</style></head><body><main class="blatt"><div class="band"></div>
<header class="kopf">
  <div class="marke">${logo ? `<img src="${esc(logo)}" alt="">` : ''}<b>${esc(a.verein)}</b></div>
  <div class="abs">${[a.strasse, [a.plz, a.ort].filter(Boolean).join(' '), a.email].filter(Boolean).map(z => esc(String(z))).join('<br>')}</div>
</header>
<p class="auge">Einladung</p>
<h1>${esc(x.titel)}</h1>
<p class="anrede">Liebe Mitglieder<br>Wir laden Sie herzlich zur ${esc(x.titel)} ein und freuen uns, Sie dabei zu haben.</p>
<section class="eckdaten">
  <div><span>Datum</span><b>${esc(datumLang(x.datum))}</b></div>
  <div><span>Zeit</span><b>${x.zeit ? `${esc(x.zeit)} Uhr` : '—'}</b></div>
  <div><span>Ort</span><b>${x.ort ? esc(x.ort) : '—'}</b></div>
</section>
<h2>Traktanden</h2>
<ol>${punkte}</ol>
<p class="hinweis">Anträge zuhanden der Versammlung richten Sie bitte schriftlich an den Vorstand.</p>
<div class="gruss">Wir freuen uns auf Ihre Teilnahme.<br><b>Der Vorstand von ${esc(a.verein)}</b></div>
<footer class="fuss"><span>${esc(a.verein)}</span><span>${esc(heute)}</span></footer>
</main></body></html>`;
}
