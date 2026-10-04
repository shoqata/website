import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { useParams } from 'react-router-dom';
import { Loader2, AlertTriangle, Printer } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { supabase } from '@/services/supabase-bridge';

// Flyer und Poster zum Treffen.
//
// Eine Seite, die beides zeigt und beides druckt. Keine zweite Fassung
// fuer den Druck: was auf dem Schirm steht, kommt aus dem Drucker --
// sonst laeuft die eine der anderen davon, und das faellt erst auf,
// wenn zweihundert Blatt gedruckt sind.
//
// Gestaltung: Schweizer Grotesk, strenges Raster, eine Akzentfarbe.
// Das ist kein Geschmack, sondern Rechnung: diese Blaetter laufen durch
// gewoehnliche Bueradrucker in Vereinslokalen. Heller Grund und
// schwarze Schrift kosten wenig Toner und bleiben scharf; ein
// vollflaechig dunkles Poster kostet viel und wird streifig.
//
// Das Programm IST das Plakat. Zeiten links, Titel rechts -- wie eine
// Abfahrtstafel. Das traegt echte Auskunft, statt sie zu schmuecken.

const WOCHENTAG = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
const MONAT = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

const datumTeile = (s?: string | null) => {
  if (!s) return null;
  const d = new Date(s);
  if (isNaN(d.getTime())) return null;
  return { tag: d.getDate(), monat: MONAT[d.getMonth()], jahr: d.getFullYear(), wtag: WOCHENTAG[d.getDay()] };
};
const zeit = (s?: string | null) => (s ? String(s).slice(0, 5) : '');
const geld = (w: any) => Number(w || 0).toLocaleString('de-CH', { minimumFractionDigits: 2 });

const preisText = (t: any) => {
  if (!t || t.preis_art === 'KEINE') return 'Teilnahme kostenlos';
  const b = `${t.waehrung || 'CHF'} ${geld(t.preis_betrag)}`;
  return t.preis_art === 'PRO_KOPF' ? `${b} pro Person` : `${b} pro Verein`;
};

// Nur was freigegeben ist, kommt aufs Papier. Ein Zwischenstand, den
// jemand ausdruckt, ist nicht mehr einzufangen.
const nachTagen = (programm: any[]) => {
  const karte = new Map<string, any[]>();
  programm.filter(p => p.freigegeben).forEach(p => {
    const k = p.tag || '';
    if (!karte.has(k)) karte.set(k, []);
    karte.get(k)!.push(p);
  });
  return [...karte.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([tag, punkte]) => ({
      tag,
      punkte: punkte.sort((a, b) =>
        String(a.beginn).localeCompare(String(b.beginn)) || (a.reihenfolge - b.reihenfolge)),
    }));
};

const TreffenDrucksachen: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [treffen, setTreffen] = useState<any>(null);
  const [programm, setProgramm] = useState<any[]>([]);
  const [fehler, setFehler] = useState('');
  const [laedt, setLaedt] = useState(true);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const [{ data: t, error: e1 }, { data: p, error: e2 }] = await Promise.all([
        supabase.from('treffen').select('*').eq('id', id).maybeSingle(),
        supabase.from('treffen_programm').select('*').eq('treffen_id', id)
          .order('tag', { nullsFirst: true }).order('beginn'),
      ]);
      if (!lebt) return;
      if (e1 || e2) { setFehler(e1?.message || e2?.message || 'Nicht lesbar.'); setLaedt(false); return; }
      if (!t) { setFehler('Dieses Treffen gibt es nicht.'); setLaedt(false); return; }
      setTreffen(t); setProgramm((p as any[]) || []); setLaedt(false);
    })();
    return () => { lebt = false; };
  }, [id]);

  if (laedt) return (
    <div className="min-h-screen grid place-items-center bg-stone-100">
      <Loader2 className="w-6 h-6 animate-spin text-stone-400" />
    </div>
  );
  if (fehler || !treffen) return (
    <div className="min-h-screen grid place-items-center bg-stone-100 p-6">
      <div className="bg-white text-stone-900 rounded-2xl p-6 max-w-sm text-center">
        <AlertTriangle className="w-6 h-6 mx-auto mb-3 text-stone-400" />
        <p className="text-sm">{fehler}</p>
      </div>
    </div>
  );

  return <Drucksachen treffen={treffen} programm={programm} />;
};

export const Drucksachen: React.FC<{ treffen: any; programm: any[] }> = ({ treffen, programm }) => {
  const von = datumTeile(treffen.datum);
  const bis = treffen.ende && treffen.ende !== treffen.datum ? datumTeile(treffen.ende) : null;
  const tage = nachTagen(programm);
  const ziel = `https://unityhub.li/#/treffen`;

  const zahl = bis ? `${von?.tag}/${bis.tag}` : `${von?.tag}`;
  const monatZeile = bis && von && bis.monat !== von.monat
    ? `${von.monat} / ${bis.monat} ${bis.jahr}`
    : `${von?.monat} ${von?.jahr}`;

  const Tafel: React.FC<{ eng?: boolean }> = ({ eng }) => (
    <>
      {tage.map(({ tag, punkte }) => {
        const d = datumTeile(tag);
        return (
          <div key={tag || 'ohne'} className={eng ? 'tafel eng' : 'tafel'}>
            {d && (
              <div className="tafelkopf">
                {d.wtag}, {d.tag}. {d.monat}
              </div>
            )}
            <table>
              <tbody>
                {punkte.map(p => (
                  <tr key={p.id} className={p.art === 'AUSFLUG' ? 'ausflug' : undefined}>
                    <td className="zeit">{zeit(p.beginn)}</td>
                    <td className="was">
                      <span className="titel">{p.titel}</span>
                      {p.art === 'AUSFLUG' && <span className="chip">Ausflug</span>}
                      {p.fuer === 'VERTRETER' && <span className="chip stumm">nur Delegationsleitung</span>}
                      {(p.ort || p.ziel || p.spur !== 'Alle') && (
                        <span className={eng ? 'wo inline' : 'wo'}>
                          {[p.ziel, p.ort, p.spur !== 'Alle' ? p.spur : null]
                            .filter(Boolean).join(' \u00b7 ')}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );
      })}
    </>
  );

  const Fakten: React.FC<{ ohneOrt?: boolean }> = ({ ohneOrt }) => (
    <dl className="fakten">
      {!ohneOrt && (
        <div><dt>Wo</dt><dd>{treffen.ort}{treffen.adresse ? <><br />{treffen.adresse}</> : null}</dd></div>
      )}
      <div><dt>Kosten</dt><dd>{preisText(treffen)}</dd></div>
      {treffen.anmeldeschluss && (
        <div><dt>Anmeldung bis</dt><dd>{(() => {
          const d = datumTeile(treffen.anmeldeschluss);
          return d ? `${d.tag}. ${d.monat} ${d.jahr}` : treffen.anmeldeschluss;
        })()}</dd></div>
      )}
    </dl>
  );

  // Als direktes Kind von body: nur so kann die Druckregel unten
  // ALLES andere der App treffen -- Cookie-Hinweis, Kopfzeile, was
  // auch immer spaeter dazukommt -- ohne deren Aufbau zu kennen.
  return createPortal(
    <div className="druck" data-druck>
      <style>{CSS}</style>

      <div className="leiste">
        <span>Flyer A5 &amp; Poster A4 — im Druckdialog «Hintergrundgrafiken» aktivieren,
          für A3 auf 141 % vergrössern.</span>
        <button onClick={() => window.print()}>
          <Printer size={15} /> Drucken
        </button>
      </div>

      {/* ---------------------------------------------------- Poster A4 */}
      <section className="blatt a4">
        <header className="kopf">
          <p className="auge">Vereinstreffen</p>
          <p className="zahl">{zahl}</p>
          <p className="monat">{monatZeile}</p>
        </header>

        <h1>{treffen.titel}</h1>
        <div className="regel" />

        <div className="tafeln">
          <Tafel />
        </div>

        <footer className="fuss">
          <div className="fussText">
            <Fakten />
            <p className="url">unityhub.li</p>
          </div>
          <div className="qr">
            <QRCodeSVG value={ziel} size={96} level="M" bgColor="#ffffff" fgColor="#111111" />
            <span>Programm &amp; Anmeldung</span>
          </div>
        </footer>
      </section>

      {/* -------------------------------------------- Flyer A5, Vorderseite */}
      <section className="blatt a5 vorne">
        <header className="kopf">
          <p className="auge">Vereinstreffen</p>
          <p className="zahl">{zahl}</p>
          <p className="monat">{monatZeile}</p>
        </header>

        <h1>{treffen.titel}</h1>

        {treffen.beschreibung && (
          <p className="anriss">{String(treffen.beschreibung).split(/\n+/)[0]}</p>
        )}

        <div className="untenRaum" />

        <div className="faktenband vorne">
          <Fakten ohneOrt />
        </div>

        <footer className="fuss">
          <div className="fussText">
            <p className="ortGross">{treffen.ort}</p>
            {treffen.adresse && <p className="adresse">{treffen.adresse}</p>}
            <p className="url">unityhub.li</p>
          </div>
          <div className="qr">
            <QRCodeSVG value={ziel} size={78} level="M" bgColor="#ffffff" fgColor="#111111" />
          </div>
        </footer>
      </section>

      {/* -------------------------------------------- Flyer A5, Rueckseite */}
      <section className="blatt a5 hinten">
        <p className="auge">Das Programm</p>
        <div className="tafeln">
          <Tafel eng />
        </div>
        <div className="faktenband">
          <Fakten />
        </div>
      </section>
    </div>,
    document.body);
};

// Das Druck-CSS steht hier und nicht in einer Klassendatei: diese Seite
// ist das einzige, was es betrifft, und @page gehoert zum Blatt.
const CSS = `
.druck {
  /* Das Blatt haengt per Portal an body, also HINTER #root. Ohne
     feste Lage saesse es unterhalb der App -- die Seite sah leer aus,
     und man haette erst daran vorbeiscrollen muessen. Im Druck
     wieder normal, sonst ergaebe fixed genau eine Seite. */
  position:fixed; inset:0; overflow:auto; z-index:9000;
  --papier:#ffffff; --tinte:#111111; --weich:#6f6b66;
  --linie:#ddd8d1; --akzent:#0428cb; --warm:#f7f5f1;
  --grotesk:'Helvetica Neue', Helvetica, Arial, 'Liberation Sans', sans-serif;
  background:#e7e5e4; min-height:100vh; padding:0 0 3rem;
  font-family:var(--grotesk); color:var(--tinte);
  -webkit-print-color-adjust:exact; print-color-adjust:exact;
}
.druck * { box-sizing:border-box }

.leiste {
  position:sticky; top:0; z-index:5; display:flex; gap:1rem;
  align-items:center; justify-content:space-between; flex-wrap:wrap;
  background:#1c1917; color:#fff; padding:.7rem 1.1rem; font-size:12.5px;
}
.leiste button {
  display:inline-flex; align-items:center; gap:.45rem; border:0; cursor:pointer;
  background:#fff; color:#1c1917; font:inherit; font-weight:600;
  padding:.45rem .9rem; border-radius:999px;
}

/* Ein Blatt ist ein Blatt: feste Masse, damit die Vorschau nicht
   schmeichelt, was der Drucker dann anders sieht. */
.blatt {
  background:var(--papier); color:var(--tinte);
  margin:2rem auto; box-shadow:0 10px 30px rgba(0,0,0,.14);
  display:flex; flex-direction:column; overflow:hidden;
}
.a4 { width:210mm; height:297mm; padding:17mm 16mm 14mm }
.a5 { width:148mm; height:210mm; padding:13mm 12mm 11mm }

.kopf { display:flex; align-items:baseline; gap:.6rem; flex-wrap:wrap }
.auge {
  margin:0; font-size:10px; letter-spacing:.18em; text-transform:uppercase;
  color:var(--akzent); font-weight:700;
}
.kopf { display:block }
.a4 .zahl { font-size:76pt }
.a5 .zahl { font-size:54pt }
.zahl {
  margin:.1rem 0 0; font-weight:700; letter-spacing:-.045em; line-height:.9;
  font-variant-numeric:tabular-nums;
}
.monat { margin:.15rem 0 0; font-size:11.5pt; color:var(--weich); font-weight:500 }

.a4 h1 { font-size:27pt; margin:7mm 0 0 }
.a5 h1 { font-size:19pt; margin:6mm 0 0 }
h1 {
  font-weight:700; letter-spacing:-.025em; line-height:1.08;
  text-wrap:balance; max-width:22ch;
}

.regel { height:3px; background:var(--akzent); margin:6mm 0 5mm; width:100% }

.anriss {
  font-size:10.5pt; line-height:1.5; color:#36322e; margin:4mm 0 0;
  max-width:36ch;
}
.untenRaum { flex:1 }

/* ---------- Die Tafel: Zeiten links, Sache rechts ---------- */
.tafeln { flex:1; min-height:0 }
.a4 .tafeln { column-count:2; column-gap:9mm; column-fill:auto }
.a4 .tafel { break-inside:avoid; -webkit-column-break-inside:avoid }
.a4 .tafel + .tafel { margin-top:0 }
.tafel + .tafel { margin-top:5mm }
.tafelkopf {
  font-size:9pt; font-weight:700; letter-spacing:.06em; text-transform:uppercase;
  padding-bottom:1.5mm; border-bottom:1px solid var(--tinte); margin-bottom:2mm;
}
.tafel table { width:100%; border-collapse:collapse }
.tafel td { vertical-align:baseline; padding:1.4mm 0; border-bottom:1px solid var(--linie) }
.tafel tr:last-child td { border-bottom:0 }
.zeit {
  width:15mm; font-variant-numeric:tabular-nums; font-weight:700;
  font-size:10pt; letter-spacing:-.01em; white-space:nowrap;
}
.a5 .zeit { width:13mm; font-size:8.5pt }
.was { font-size:10pt; line-height:1.3 }
.a5 .was { font-size:8.5pt }
.titel { font-weight:500 }
.wo { display:block; color:var(--weich); font-size:8.5pt; margin-top:.4mm }
.wo.inline { display:inline; margin:0 0 0 1.5mm }
.a5 .wo { font-size:7pt }

.chip {
  display:inline-block; margin-left:1.6mm; padding:.2mm 1.6mm;
  background:var(--akzent); color:#fff; font-size:7pt; font-weight:700;
  letter-spacing:.06em; text-transform:uppercase; vertical-align:.4mm;
  border-radius:1mm;
}
.chip.stumm { background:transparent; color:var(--weich); border:1px solid var(--linie) }
.ausflug .titel { font-weight:700 }

/* ---------- Fuss ---------- */
.fuss {
  display:flex; align-items:flex-end; justify-content:space-between; gap:6mm;
  border-top:3px solid var(--tinte); padding-top:4mm; margin-top:6mm;
}
.a5.vorne .fuss { border-top-color:var(--akzent) }
.fakten { margin:0; display:flex; flex-wrap:wrap; gap:4mm 9mm }
.fakten div { margin:0 }
.fakten dt {
  font-size:7.5pt; letter-spacing:.14em; text-transform:uppercase;
  color:var(--weich); font-weight:700; margin-bottom:.8mm;
}
.fakten dd { margin:0; font-size:9.5pt; line-height:1.35; font-weight:500 }
.url { margin:3mm 0 0; font-size:12pt; font-weight:700; letter-spacing:-.02em; color:var(--akzent) }
.ortGross { margin:0; font-size:13pt; font-weight:700; letter-spacing:-.02em }
.adresse { margin:.8mm 0 0; font-size:9pt; color:var(--weich) }

.qr { text-align:center; flex:none }
.qr span {
  display:block; margin-top:1.4mm; font-size:7pt; color:var(--weich);
  letter-spacing:.04em; max-width:28mm; line-height:1.25;
}

.a5.hinten { background:var(--warm) }
.a5.hinten .auge { margin-bottom:3mm }
.faktenband {
  border-top:3px solid var(--tinte); padding-top:3.5mm; margin-top:6mm;
}
.faktenband.vorne { border-top-width:1px; border-top-color:var(--linie); margin-top:0 }

/* ---------- Druck ---------- */
@media print {
  /* Das Blatt haengt als direktes Kind an body. Alles andere der App --
     Cookie-Hinweis, Kopfzeile, was spaeter dazukommt -- gehoert nicht
     aufs Papier, und so muss ich dessen Aufbau nicht kennen. */
  body > *:not([data-druck]) { display:none !important }
  html, body { background:#fff !important; margin:0 !important }
  .druck { position:static; overflow:visible; z-index:auto }
  .leiste { display:none }
  .druck { background:#fff; padding:0 }
  .blatt { margin:0; box-shadow:none; break-after:page; page-break-after:always }
  .blatt:last-child { break-after:auto; page-break-after:auto }
  /* Gemischte Formate in einem Auftrag: A4 als Rahmen, das A5-Blatt
     sitzt dann oben links auf dem A4-Bogen und wird geschnitten. Das
     ist ehrlicher als ein @page-Wechsel, den kaum ein Browser kann. */
  @page { size:A4 portrait; margin:0 }
}
`;

export default TreffenDrucksachen;
