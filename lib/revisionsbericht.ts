// Der Revisionsbericht als eigenstaendiges Dokument.
//
// Eine Revisionsstelle arbeitet mit Unterlagen, nicht mit Zugaengen. Sie
// bekommt eine Datei, oeffnet sie in irgendeinem Browser, druckt sie bei
// Bedarf -- ohne Konto, ohne Internet, ohne diese Anwendung.
//
// Deshalb eine einzelne HTML-Datei ohne jede externe Abhaengigkeit: kein
// Skript, keine Schriftart von aussen, kein Bild. Was drin steht, bleibt
// lesbar, auch wenn es diese Plattform in zehn Jahren nicht mehr gibt --
// und das ist bei Buchhaltungsunterlagen keine Nebensaechlichkeit.
//
// Gerechnet wird nichts hier. Die Zahlen kommen aus revisionsbericht() in
// der Datenbank; dieses Modul setzt sie nur. Rechnete der Browser mit,
// zeigte der Bericht am Ende das, was die Oberflaeche ohnehin zeigt -- und
// genau das will eine Revision nicht.

const schuetzen = (s: any): string =>
  String(s ?? '').replace(/[&<>"']/g, z =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[z] as string));

const zahl = (w: any) =>
  Number(w ?? 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const zeitpunkt = (s: any) => {
  if (!s) return '';
  try { return new Date(s).toLocaleString('de-CH'); } catch { return String(s); }
};

export function revisionsberichtHtml(b: any): string {
  const konten = (b.saldenliste || []) as any[];
  const journal = (b.journal || []) as any[];
  const aenderungen = (b.aenderungen || []) as any[];
  const entfernt = (b.frueher_entfernt || []) as any[];
  const er = b.erfolgsrechnung || {};
  const bil = b.bilanz || {};

  const gruppe = (klasse: string) => konten.filter(k => k.klasse === klasse && Number(k.saldo) !== 0);

  const kontenTabelle = (klasse: string, titel: string) => {
    const zeilen = gruppe(klasse);
    if (!zeilen.length) return '';
    const summe = zeilen.reduce((s, k) => s + Number(k.saldo), 0);
    return `<h3>${schuetzen(titel)}</h3><table class="z">
      <thead><tr><th>Konto</th><th>Bezeichnung</th><th class="r">Soll</th><th class="r">Haben</th><th class="r">Saldo</th></tr></thead>
      <tbody>${zeilen.map(k => `<tr>
        <td class="m">${schuetzen(k.konto)}</td><td>${schuetzen(k.name)}</td>
        <td class="r m">${zahl(k.soll)}</td><td class="r m">${zahl(k.haben)}</td>
        <td class="r m b">${zahl(k.saldo)}</td></tr>`).join('')}
      <tr class="summe"><td></td><td>Total ${schuetzen(titel)}</td><td></td><td></td>
        <td class="r m b">${zahl(summe)}</td></tr></tbody></table>`;
  };

  const abschluss = b.abschluss
    ? `${schuetzen(b.abschluss.status)}${b.abschluss.geschlossen_am ? ', abgeschlossen am ' + zeitpunkt(b.abschluss.geschlossen_am) : ''}`
    : 'offen — das Geschäftsjahr wurde nicht abgeschlossen';

  return `<!doctype html>
<html lang="de"><head><meta charset="utf-8">
<title>Revisionsbericht ${schuetzen(b.jahr)} — ${schuetzen(b.verein?.name)}</title>
<style>
  :root { --tinte:#1a1a1a; --weich:#666; --linie:#d8d8d8; --papier:#fff; }
  * { box-sizing:border-box }
  body { font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;
         color:var(--tinte); background:var(--papier); margin:0; padding:2.5rem 1.5rem 5rem;
         font-size:14px; line-height:1.55 }
  .bahn { max-width:60rem; margin:0 auto }
  h1 { font-size:1.9rem; margin:0 0 .3rem; letter-spacing:-.02em }
  h2 { font-size:1.15rem; margin:2.8rem 0 .8rem; padding-bottom:.35rem;
       border-bottom:2px solid var(--tinte) }
  h3 { font-size:.95rem; margin:1.6rem 0 .5rem; color:var(--weich);
       text-transform:uppercase; letter-spacing:.09em }
  .kopf { border-bottom:3px solid var(--tinte); padding-bottom:1.2rem; margin-bottom:.5rem }
  .kopf p { margin:.15rem 0; color:var(--weich) }
  table { width:100%; border-collapse:collapse; margin-bottom:.6rem }
  th { text-align:left; font-size:.68rem; text-transform:uppercase; letter-spacing:.09em;
       color:var(--weich); border-bottom:1px solid var(--tinte); padding:.3rem .5rem .3rem 0 }
  td { padding:.3rem .5rem .3rem 0; border-bottom:1px solid var(--linie); vertical-align:top }
  .r { text-align:right } .b { font-weight:700 }
  .m { font-variant-numeric:tabular-nums; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
       font-size:.86em }
  tr.summe td { border-top:2px solid var(--tinte); border-bottom:none; padding-top:.5rem }
  .ergebnis { display:flex; gap:2.5rem; flex-wrap:wrap; margin:1.2rem 0; padding:1.1rem 1.3rem;
              border:2px solid var(--tinte) }
  .ergebnis div p:first-child { font-size:.68rem; text-transform:uppercase; letter-spacing:.09em;
              color:var(--weich); margin:0 0 .2rem }
  .ergebnis div p:last-child { font-size:1.35rem; font-weight:700; margin:0;
              font-variant-numeric:tabular-nums }
  .hinweis { border-left:3px solid var(--tinte); padding:.7rem 1rem; margin:1rem 0;
             background:#f6f6f6; font-size:.88rem }
  .leer { color:var(--weich); font-style:italic; padding:.6rem 0 }
  .vorher { color:#a33 } .nachher { color:#2a6 }
  @media print { body { padding:0; font-size:11px } h2 { page-break-after:avoid }
                 table { page-break-inside:auto } tr { page-break-inside:avoid } }
</style></head><body><div class="bahn">

<div class="kopf">
  <h1>Revisionsbericht ${schuetzen(b.jahr)}</h1>
  <p><strong>${schuetzen(b.verein?.name || b.verein?.id)}</strong></p>
  <p>Geschäftsjahr: ${abschluss}</p>
  <p>Erstellt am ${zeitpunkt(b.erstellt)}</p>
</div>

<div class="hinweis">
  Dieser Bericht enthält die vollständige Buchführung des Geschäftsjahres: Saldenliste,
  Bilanz, Erfolgsrechnung, das Journal mit fortlaufenden Belegnummern sowie jede
  nachträgliche Änderung und Löschung mit Urheber und Zeitpunkt.
  Die Zahlen stammen unmittelbar aus der Datenbank.
</div>

<h2>Erfolgsrechnung</h2>
${kontenTabelle('REVENUE', 'Ertrag')}
${kontenTabelle('EXPENSE', 'Aufwand')}
<div class="ergebnis">
  <div><p>Ertrag</p><p>${zahl(er.ertrag)}</p></div>
  <div><p>Aufwand</p><p>${zahl(er.aufwand)}</p></div>
  <div><p>${Number(er.ergebnis) >= 0 ? 'Gewinn' : 'Verlust'}</p><p>${zahl(Math.abs(Number(er.ergebnis || 0)))}</p></div>
</div>

<h2>Bilanz</h2>
${kontenTabelle('ASSET', 'Aktiven')}
${kontenTabelle('LIABILITY', 'Passiven')}
<div class="ergebnis">
  <div><p>Aktiven</p><p>${zahl(bil.aktiven)}</p></div>
  <div><p>Passiven</p><p>${zahl(bil.passiven)}</p></div>
  <div><p>Ergebnis</p><p>${zahl(er.ergebnis)}</p></div>
  <div><p>Differenz</p><p>${zahl(Number(bil.aktiven || 0) - (Number(bil.passiven || 0) + Number(er.ergebnis || 0)))}</p></div>
</div>

<h2>Journal</h2>
<table class="z">
  <thead><tr><th>Beleg</th><th>Datum</th><th>Text</th><th>Soll</th><th>Haben</th><th class="r">Betrag</th></tr></thead>
  <tbody>${journal.length ? journal.map(j => `<tr>
    <td class="m">${schuetzen(j.beleg)}</td><td class="m">${schuetzen(j.datum)}</td>
    <td>${schuetzen(j.text)}${j.systembuchung ? ' <em>(System)</em>' : ''}</td>
    <td class="m">${schuetzen(j.soll || '')}</td><td class="m">${schuetzen(j.haben || '')}</td>
    <td class="r m">${zahl(j.betrag)}</td></tr>`).join('')
    : '<tr><td colspan="6" class="leer">Keine Buchungen in diesem Geschäftsjahr.</td></tr>'}
  </tbody></table>

<h2>Nachträgliche Änderungen</h2>
${aenderungen.length ? `<table class="z">
  <thead><tr><th>Zeitpunkt</th><th>Vorgang</th><th>Beleg</th><th>Wer</th><th>Was</th></tr></thead>
  <tbody>${aenderungen.map(a => `<tr>
    <td class="m">${zeitpunkt(a.wann)}</td>
    <td>${a.vorgang === 'LOESCHUNG' ? 'Löschung' : 'Änderung'}</td>
    <td class="m">${schuetzen(a.vorher?.belegnr ?? '')}</td>
    <td>${schuetzen(a.wer)}</td>
    <td><span class="vorher">${schuetzen(a.vorher?.date)} · ${schuetzen(a.vorher?.description)} · ${zahl(a.vorher?.amount)}</span>${
      a.nachher ? `<br><span class="nachher">${schuetzen(a.nachher?.date)} · ${schuetzen(a.nachher?.description)} · ${zahl(a.nachher?.amount)}</span>` : ''
    }</td></tr>`).join('')}
  </tbody></table>`
 : `<p class="leer">Keine. Keine Buchung dieses Geschäftsjahres wurde nachträglich geändert oder gelöscht.</p>`}

${entfernt.length ? `<h2>Früher entfernte Buchungen</h2>
<table class="z"><thead><tr><th>Entfernt am</th><th>Grund</th><th>Buchung</th></tr></thead>
<tbody>${entfernt.map(e => `<tr><td class="m">${zeitpunkt(e.entfernt_am)}</td>
  <td>${schuetzen(e.grund)}</td>
  <td class="m">${schuetzen(e.zeile?.date)} · ${schuetzen(e.zeile?.description)} · ${zahl(e.zeile?.amount)}</td>
</tr>`).join('')}</tbody></table>
<p class="leer">Diese Buchungen wurden vor Einführung des Änderungsprotokolls entfernt. Sie sind hier aufgeführt, damit die Unterlagen vollständig sind.</p>` : ''}

</div></body></html>`;
}
