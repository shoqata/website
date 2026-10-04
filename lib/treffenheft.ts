// Das Heft: wer alles dabei war.
//
// Ein Dokument, zwei Verwendungen -- am Bildschirm zu lesen und auf
// Papier zu drucken. Eine zweite Fassung fuer den Druck liefe der ersten
// frueher oder spaeter davon.
//
// Selbsttragend: keine Schrift von aussen, kein Skript, kein Bild. Ein
// Andenken, das nach zwei Jahren nur noch halb laedt, ist keines. Dafuer
// Georgia und die Systemschriften -- sie sind ueberall da und altern
// nicht.
//
// Drin steht NUR, wer zugestimmt hat. Die Stillen werden gezaehlt, nicht
// verschwiegen: "und 14 weitere" ist ehrlicher als eine Liste, die so
// tut, als waeren es alle.

const schuetzen = (s: any): string =>
  String(s ?? '').replace(/[&<>"']/g, z =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[z] as string));

const absatz = (s: any): string =>
  schuetzen(s).split(/\n+/).filter(Boolean).map(z => `<p>${z}</p>`).join('');

const tag = (s?: string | null) => {
  if (!s) return '';
  try {
    return new Date(s).toLocaleDateString('de-CH', { day: 'numeric', month: 'long', year: 'numeric' });
  } catch { return String(s); }
};
const zeit = (s?: string | null) => (s ? String(s).slice(0, 5) : '');

export function treffenheftHtml(b: any): string {
  const t = b.treffen || {};
  const vereine = (b.vereine || []) as any[];
  const programm = (b.programm || []) as any[];
  const mitStimme = vereine.filter(v => (v.leute || []).length > 0);
  const stilleGesamt = vereine.reduce((s, v) => s + (v.stille || 0), 0);

  const zeitraum = t.ende && t.ende !== t.datum
    ? `${tag(t.datum)} – ${tag(t.ende)}` : tag(t.datum);

  return `<!doctype html>
<html lang="de"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${schuetzen(t.titel)} — wer dabei war</title>
<style>
  :root {
    --papier:#faf8f5; --tinte:#1c1917; --weich:#78716c; --linie:#e2ddd6;
    --akzent:#0428cb;
    --serif: Georgia, 'Iowan Old Style', 'Palatino Linotype', serif;
    --sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
    --mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  }
  * { box-sizing:border-box }
  body { margin:0; background:var(--papier); color:var(--tinte);
         font-family:var(--sans); font-size:15px; line-height:1.65;
         -webkit-font-smoothing:antialiased }
  .blatt { max-width:42rem; margin:0 auto; padding:0 1.6rem }

  /* ---------- Titel ---------- */
  /* gedeckelt: auf sehr hohen Bildschirmen wuchs der Titel ins Leere */
  .titel { min-height:min(72vh,34rem); display:flex; flex-direction:column; justify-content:center;
           padding:4rem 0 3rem; border-bottom:1px solid var(--linie) }
  .marke { font-family:var(--mono); font-size:10px; letter-spacing:.22em;
           text-transform:uppercase; color:var(--akzent); margin:0 0 1.4rem }
  h1 { font-family:var(--serif); font-weight:400; font-size:clamp(2.2rem,7vw,3.6rem);
       line-height:1.08; letter-spacing:-.015em; margin:0 0 1.4rem; text-wrap:balance }
  .wann { font-size:1rem; color:var(--weich); margin:0 0 .3rem }
  .einleitung { font-family:var(--serif); font-size:1.12rem; line-height:1.7;
                color:var(--weich); margin:2.2rem 0 0; max-width:30rem }
  .zahlen { display:flex; gap:2.6rem; flex-wrap:wrap; margin-top:2.6rem }
  .zahlen div p:first-child { font-family:var(--serif); font-size:2rem; line-height:1;
                              margin:0 0 .25rem }
  .zahlen div p:last-child { font-family:var(--mono); font-size:10px; letter-spacing:.14em;
                             text-transform:uppercase; color:var(--weich); margin:0 }

  /* ---------- Abschnitte ---------- */
  section { padding:3.4rem 0; border-bottom:1px solid var(--linie) }
  section:last-of-type { border-bottom:none }
  h2 { font-family:var(--mono); font-size:10px; letter-spacing:.22em; text-transform:uppercase;
       color:var(--weich); margin:0 0 1.8rem; font-weight:700 }

  /* ---------- Programm ---------- */
  .programm { width:100%; border-collapse:collapse }
  .programm td { padding:.55rem 1rem .55rem 0; border-bottom:1px solid var(--linie);
                 vertical-align:top }
  .programm tr:last-child td { border-bottom:none }
  .programm .t { font-family:var(--mono); font-size:.8rem; white-space:nowrap }
  .programm .s { font-family:var(--mono); font-size:.62rem; letter-spacing:.1em;
                 text-transform:uppercase; color:var(--weich); white-space:nowrap }
  .programm .o { color:var(--weich); font-size:.86rem; white-space:nowrap }

  /* ---------- Vereine und Menschen ---------- */
  .verein { margin-bottom:3rem }
  .verein:last-child { margin-bottom:0 }
  .vname { font-family:var(--serif); font-size:1.5rem; margin:0 0 .3rem; line-height:1.25 }
  .vrand { font-family:var(--mono); font-size:10px; letter-spacing:.14em; text-transform:uppercase;
           color:var(--weich); margin:0 0 1.6rem }
  .person { padding:1.3rem 0; border-top:1px solid var(--linie) }
  .pname { font-weight:600; font-size:1.02rem; margin:0 }
  .pfunktion { font-family:var(--mono); font-size:10px; letter-spacing:.12em;
               text-transform:uppercase; color:var(--akzent); margin:.15rem 0 .7rem }
  .person p { margin:0 0 .5rem; font-family:var(--serif); font-size:.98rem; line-height:1.7 }
  .interessen { font-family:var(--sans) !important; font-size:.84rem !important;
                color:var(--weich); margin-top:.6rem !important }
  .interessen span { font-family:var(--mono); font-size:9px; letter-spacing:.14em;
                     text-transform:uppercase; margin-right:.5rem }
  .still { font-size:.84rem; color:var(--weich); font-style:italic;
           border-top:1px solid var(--linie); padding-top:1rem; margin-top:1.3rem }

  .schluss { font-family:var(--serif); font-size:1rem; color:var(--weich); line-height:1.75;
             padding:3rem 0 4rem }

  /* ---------- Druck ---------- */
  @media print {
    body { background:#fff; font-size:10.5pt }
    .blatt { max-width:none; padding:0 }
    @page { size:A5; margin:16mm 14mm }
    .titel { min-height:auto; padding:0 0 2rem; page-break-after:always }
    section { page-break-inside:auto; padding:1.6rem 0 }
    h2 { page-break-after:avoid }
    .verein { page-break-inside:avoid }
    .person { page-break-inside:avoid }
  }
</style></head><body><div class="blatt">

<header class="titel">
  <p class="marke">Vereinstreffen</p>
  <h1>${schuetzen(t.titel)}</h1>
  <p class="wann">${schuetzen(zeitraum)}${t.ort ? ' · ' + schuetzen(t.ort) : ''}</p>
  ${t.beschreibung ? `<div class="einleitung">${absatz(t.beschreibung)}</div>` : ''}
  <div class="zahlen">
    <div><p>${vereine.length}</p><p>Vereine</p></div>
    <div><p>${b.gesamt ?? 0}</p><p>Menschen</p></div>
    <div><p>${b.stimmen ?? 0}</p><p>stellen sich vor</p></div>
  </div>
</header>

${programm.length ? `<section>
  <h2>Der Tag</h2>
  <table class="programm"><tbody>
    ${programm.map(p => `<tr>
      <td class="t">${schuetzen(zeit(p.beginn))}</td>
      <td class="s">${schuetzen(p.spur || '')}</td>
      <td>${schuetzen(p.titel)}</td>
      <td class="o">${schuetzen(p.ort || '')}</td>
    </tr>`).join('')}
  </tbody></table>
</section>` : ''}

<section>
  <h2>Wer dabei war</h2>
  ${mitStimme.length === 0 ? `<p style="color:var(--weich)">
      Niemand hat einer Aufnahme ins Heft zugestimmt. ${b.gesamt ?? 0} Menschen waren da.
    </p>` : mitStimme.map(v => `
    <div class="verein">
      <p class="vname">${schuetzen(v.name)}</p>
      <p class="vrand">${v.art === 'GASTVEREIN' ? 'zu Gast' : 'Verein'} · ${(v.leute || []).length + (v.stille || 0)} ${(v.leute || []).length + (v.stille || 0) === 1 ? 'Person' : 'Personen'}</p>
      ${(v.leute || []).map((p: any) => `
        <div class="person">
          <p class="pname">${schuetzen(p.name)}</p>
          ${p.funktion ? `<p class="pfunktion">${schuetzen(p.funktion)}${p.rolle === 'LEITUNG' ? ' · Delegationsleitung' : ''}</p>`
            : p.rolle === 'LEITUNG' ? `<p class="pfunktion">Delegationsleitung</p>` : ''}
          ${p.vorstellung ? absatz(p.vorstellung) : ''}
          ${p.interessen ? `<p class="interessen"><span>Interessiert an</span>${schuetzen(p.interessen)}</p>` : ''}
        </div>`).join('')}
      ${v.stille ? `<p class="still">
        Dazu ${v.stille} ${v.stille === 1 ? 'weitere Person, die' : 'weitere Personen, die'}
        dabei ${v.stille === 1 ? 'war' : 'waren'}, aber nicht im Heft erscheinen ${v.stille === 1 ? 'wollte' : 'wollten'}.
      </p>` : ''}
    </div>`).join('')}
</section>

<p class="schluss">
  ${stilleGesamt > 0
    ? `Dieses Heft zeigt ${b.stimmen ?? 0} von ${b.gesamt ?? 0} Menschen. Die übrigen waren ebenso dabei — sie wollten nur nicht darin stehen, und das ist ihr gutes Recht.`
    : `Dieses Heft zeigt alle ${b.gesamt ?? 0} Menschen, die dabei waren.`}
</p>

</div></body></html>`;
}
