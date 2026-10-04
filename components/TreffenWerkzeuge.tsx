import React, { useEffect, useState } from 'react';
import {
  Loader2, Utensils, IdCard, Clock, Receipt, Link2, Copy, Check, Download, AlertTriangle, Bus, Printer,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Was der Gastgeber am Tag und danach braucht.
//
// Vier Dinge an einem Ort, weil sie alle dieselbe Frage beantworten: was
// mache ich jetzt mit dem, was die Leute eingetragen haben.
//
// Gerechnet wird nichts hier -- jede Zahl kommt aus der Datenbank. Eine
// zweite Rechnung im Browser liefe der ersten davon, und dann steht auf
// der Küchenliste etwas anderes als auf der Rechnung.

const ESSEN_NAME: Record<string, string> = {
  ALLES: 'Isst alles', VEGETARISCH: 'Vegetarisch', VEGAN: 'Vegan',
  HALAL: 'Halal', GLUTENFREI: 'Glutenfrei', LAKTOSEFREI: 'Laktosefrei',
  KEINE_ANGABE: 'Keine Angabe',
};

const geld = (w: any) => Number(w || 0).toLocaleString('de-CH', { minimumFractionDigits: 2 });

const TreffenWerkzeuge: React.FC<{ treffenId: string; teilnehmer: any[]; neuLaden: () => void }> =
  ({ treffenId, teilnehmer, neuLaden }) => {
  const [essen, setEssen] = useState<any>(null);
  const [schilder, setSchilder] = useState<any[] | null>(null);
  const [programm, setProgramm] = useState<any[]>([]);
  const [arbeitet, setArbeitet] = useState('');
  const [fehler, setFehler] = useState('');
  const [meldung, setMeldung] = useState('');
  const [links, setLinks] = useState<any[] | null>(null);
  const [ausfluege, setAusfluege] = useState<any[]>([]);
  const [kopiert, setKopiert] = useState('');

  const laden = async () => {
    const [{ data: e }, { data: s }, { data: p }, { data: a }] = await Promise.all([
      supabase.rpc('treffen_essenszahlen', { p_treffen: treffenId }),
      supabase.rpc('treffen_namensschilder', { p_treffen: treffenId }),
      supabase.from('treffen_programm').select('*').eq('treffen_id', treffenId)
        .order('tag', { nullsFirst: true }).order('beginn'),
      supabase.rpc('treffen_ausflugslisten', { p_treffen: treffenId }),
    ]);
    setEssen(e); setSchilder((s as any[]) || []); setProgramm((p as any[]) || []);
    setAusfluege((a as any[]) || []);
  };
  useEffect(() => { laden(); /* eslint-disable-next-line */ }, [treffenId]);

  const mitFehler = async (was: string, f: () => Promise<any>) => {
    setArbeitet(was); setFehler(''); setMeldung('');
    try { return await f(); }
    catch (e: any) { setFehler(e?.message || 'Fehlgeschlagen.'); }
    finally { setArbeitet(''); }
  };

  const verschieben = (punkt: any, minuten: number, alle: boolean) =>
    mitFehler('verschieben', async () => {
      const { data, error } = await supabase.rpc('treffen_programm_verschieben', {
        p_punkt: punkt.id, p_minuten: minuten, p_alle_spuren: alle });
      if (error) throw error;
      const d: any = data;
      setMeldung(`${d.verschoben} Punkte um ${minuten > 0 ? '+' : ''}${minuten} Minuten verschoben (${d.spur}).`);
      await laden();
    });

  const verrechnen = () => mitFehler('verrechnen', async () => {
    const { data, error } = await supabase.rpc('treffen_verrechnen', { p_treffen: treffenId });
    if (error) throw error;
    const d: any = data;
    const aus = (d.ausserhalb || []).map((g: any) => `${g.wer} ${geld(g.betrag)}`).join(', ');
    setMeldung(`${d.gestellt} Rechnung(en) als Entwurf angelegt.`
      + (aus ? ` Ausserhalb zu stellen: ${aus}.` : ''));
  });

  const linksHolen = (te: any) => mitFehler('links', async () => {
    const { data, error } = await supabase.rpc('treffen_vorstellung_links', { p_teilnehmer: te.id });
    if (error) throw error;
    const d: any = data;
    setLinks((d.neue || []).map((p: any) => ({
      ...p, url: `${window.location.origin}/#/vorstellen/${p.token}`, verein: te.name || te.tenantId })));
    if ((d.neue || []).length === 0) setMeldung('Alle dieser Delegation haben bereits einen Link.');
    await neuLaden();
  });

  const schilderDrucken = () => {
    if (!schilder?.length) return;
    const html = `<!doctype html><html lang="de"><head><meta charset="utf-8">
<title>Namensschilder</title><style>
  @page { size:A4; margin:10mm }
  body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,sans-serif;
       display:grid;grid-template-columns:1fr 1fr;gap:4mm}
  .s{border:1px solid #ddd;border-radius:3mm;padding:7mm 6mm;height:52mm;
     display:flex;flex-direction:column;justify-content:center;page-break-inside:avoid}
  .n{font-size:17pt;font-weight:700;line-height:1.15;margin:0 0 2mm}
  .f{font-size:8pt;letter-spacing:.12em;text-transform:uppercase;color:#0428cb;margin:0 0 4mm}
  .v{font-size:10pt;color:#666;margin:0}
</style></head><body>
${schilder.map(p => `<div class="s">
  <p class="n">${String(p.name || '').replace(/[&<>]/g, '')}</p>
  ${p.funktion ? `<p class="f">${String(p.funktion).replace(/[&<>]/g, '')}</p>` : ''}
  <p class="v">${String(p.verein || '').replace(/[&<>]/g, '')}</p>
</div>`).join('')}
</body></html>`;
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = 'Namensschilder.html'; a.click();
    URL.revokeObjectURL(url);
  };

  const kasten = 'bg-white/5 border border-white/10 rounded-2xl p-5';
  const titel = 'text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-3 flex items-center gap-2';

  return (
    <div className="space-y-4">
      {fehler && (
        <p className="text-xs text-red-400 bg-red-500/10 border border-red-500/20 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}
      {meldung && <p className="text-xs text-emerald-400 bg-emerald-500/10 rounded-xl p-3">{meldung}</p>}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* ---------------------------------------------------- Essen */}
        <div className={kasten}>
          <p className={titel}><Utensils size={13} /> Essenszahlen</p>
          {!essen ? <Loader2 size={14} className="animate-spin text-stone-500" /> : (
            <>
              <div className="space-y-1.5 mb-3">
                {Object.entries(essen.nach_art || {}).sort().map(([k, n]) => (
                  <div key={k} className="flex justify-between text-sm">
                    <span className="text-stone-300">{ESSEN_NAME[k] || k}</span>
                    <span className="text-white font-bold tabular-nums">{String(n)}</span>
                  </div>
                ))}
              </div>
              <div className="flex justify-between text-sm border-t border-white/10 pt-2">
                <span className="text-stone-400">Gesamt</span>
                <span className="text-white font-bold tabular-nums">{essen.gesamt}</span>
              </div>
              {(essen.hinweise || []).length > 0 && (
                <div className="mt-4 pt-3 border-t border-white/10 space-y-1">
                  <p className="text-[10px] uppercase tracking-widest text-amber-400 mb-1.5">
                    Zu lesen, nicht zu zählen
                  </p>
                  {essen.hinweise.map((h: any, i: number) => (
                    <p key={i} className="text-[11px] text-stone-300">
                      <span className="text-stone-500">{h.name}:</span> {h.hinweis}
                    </p>
                  ))}
                </div>
              )}
              {essen.ohne_angabe > 0 && (
                <p className="text-[11px] text-stone-500 mt-3">
                  {essen.ohne_angabe} ohne Angabe — diese haben sich noch nicht vorgestellt.
                </p>
              )}
            </>
          )}
        </div>

        {/* ----------------------------------------------- Namensschilder */}
        <div className={kasten}>
          <p className={titel}><IdCard size={13} /> Namensschilder</p>
          <p className="text-sm text-stone-300 mb-1">{schilder?.length ?? 0} Stück</p>
          <p className="text-[11px] text-stone-500 leading-relaxed mb-4">
            Alle, die kommen — unabhängig davon, ob sie ins Heft wollen. Ein Namensschild
            ist keine Veröffentlichung.
          </p>
          <button onClick={schilderDrucken} disabled={!schilder?.length}
            className="flex items-center gap-2 text-[10px] font-bold uppercase tracking-widest
                       text-stone-300 hover:text-white disabled:opacity-40">
            <Download size={12} /> Zum Drucken herunterladen
          </button>
        </div>

        {/* ------------------------------------------- Flyer und Poster */}
        <div className={kasten}>
          <p className={titel}><Printer size={13} /> Flyer und Poster</p>
          <p className="text-sm text-stone-300 mb-1">
            {programm.filter(p => p.freigegeben).length} freigegebene Programmpunkte
          </p>
          <p className="text-[11px] text-stone-500 leading-relaxed mb-4">
            Aus dem Treffen gesetzt, nicht abgetippt: Flyer A5 (Vorder- und Rückseite)
            und Poster A4. Was nicht freigegeben ist, kommt nicht aufs Papier.
          </p>
          <button
            onClick={() => window.open(`${window.location.origin}/#/drucksachen/${treffenId}`, '_blank')}
            disabled={!programm.some(p => p.freigegeben)}
            className="flex items-center gap-2 text-[10px] font-bold uppercase tracking-widest
                       text-stone-300 hover:text-white disabled:opacity-40">
            <Printer size={12} /> Öffnen und drucken
          </button>
        </div>
      </div>

      {/* ------------------------------------------------ Ausfluege */}
      {ausfluege.length > 0 && (
        <div className={kasten}>
          <p className={titel}><Bus size={13} /> Ausflüge — wer fährt mit</p>
          <div className="space-y-4">
            {ausfluege.map((a: any) => (
              <div key={a.id}>
                <div className="flex items-baseline justify-between gap-3 flex-wrap mb-1.5">
                  <p className="text-sm text-white">
                    {a.titel}
                    <span className="text-stone-500"> nach {a.ziel}</span>
                  </p>
                  <p className="text-[11px] text-stone-400 tabular-nums shrink-0">
                    {a.angemeldet}{a.plaetze ? ` / ${a.plaetze}` : ''} angemeldet
                    {a.plaetze != null && (a.frei === 0
                      ? <span className="text-amber-400"> · ausgebucht</span>
                      : <span> · {a.frei} frei</span>)}
                  </p>
                </div>
                <p className="text-[11px] text-stone-500 mb-2">
                  {String(a.beginn).slice(0,5)}{a.rueckkehr ? `–${String(a.rueckkehr).slice(0,5)}` : ''}
                  {a.treffpunkt ? ` · ab ${a.treffpunkt}` : ''}
                  {a.anreise ? ` · ${a.anreise}` : ''}
                  {Number(a.kosten) > 0 ? ` · ${geld(a.kosten)} CHF` : ''}
                </p>
                {(a.leute || []).length === 0 ? (
                  <p className="text-[11px] text-stone-600">Noch niemand angemeldet.</p>
                ) : (
                  <div className="text-[11px] text-stone-300 space-y-0.5">
                    {a.leute.map((p: any, i: number) => (
                      <p key={i}>{p.name} <span className="text-stone-500">· {p.verein}</span></p>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ------------------------------------------------ Programm */}
      <div className={kasten}>
        <p className={titel}><Clock size={13} /> Programm am Tag verschieben</p>
        {programm.length === 0 ? (
          <p className="text-[11px] text-stone-500">Kein Programmpunkt erfasst.</p>
        ) : (
          <>
            <p className="text-[11px] text-stone-500 leading-relaxed mb-3">
              Verschiebt diesen Punkt und alles Spätere <strong className="text-stone-300">in
              derselben Spur</strong>. Die anderen Spuren bleiben — das Essen wartet nicht,
              weil das Halbfinale länger dauert.
            </p>
            <div className="space-y-1">
              {programm.map(p => (
                <div key={p.id} className="flex items-center justify-between gap-3 py-1.5
                                           border-b border-white/5 last:border-0 flex-wrap">
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="font-mono text-xs text-white tabular-nums">
                      {String(p.beginn).slice(0, 5)}
                    </span>
                    <span className="text-[10px] uppercase tracking-wider text-stone-500 px-1.5 py-0.5
                                     border border-white/10 rounded">{p.spur}</span>
                    <span className="text-sm text-stone-300 truncate">{p.titel}</span>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    {[-15, -5, 5, 15].map(m => (
                      <button key={m} onClick={() => verschieben(p, m, false)} disabled={!!arbeitet}
                        className="px-2 py-1 rounded-lg text-[10px] font-bold font-mono
                                   text-stone-400 hover:text-white hover:bg-white/10 disabled:opacity-40">
                        {m > 0 ? `+${m}` : m}
                      </button>
                    ))}
                    <button onClick={() => verschieben(p, 15, true)} disabled={!!arbeitet}
                      title="Alle Spuren um 15 Minuten"
                      className="px-2 py-1 rounded-lg text-[10px] font-bold text-stone-500
                                 hover:text-amber-300 disabled:opacity-40">
                      alle +15
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* ------------------------------------------------ Vorstellungs-Links */}
      <div className={kasten}>
        <p className={titel}><Link2 size={13} /> Links zur Selbstvorstellung</p>
        <p className="text-[11px] text-stone-500 leading-relaxed mb-3">
          Jede Person bekommt ihren eigenen Link — die Vorstellung ist persönlich, und
          der Delegationsleiter soll sie nicht für andere ausfüllen.
        </p>
        <div className="space-y-1.5">
          {teilnehmer.filter(te => te.art !== 'GAST').map(te => (
            <div key={te.id} className="flex items-center justify-between gap-3 py-1.5
                                        border-b border-white/5 last:border-0">
              <span className="text-sm text-stone-300 truncate">{te.name || te.tenantId}</span>
              <button onClick={() => linksHolen(te)} disabled={!!arbeitet}
                className="text-[10px] font-bold uppercase tracking-widest text-stone-400
                           hover:text-white disabled:opacity-40 shrink-0">
                Links ausstellen
              </button>
            </div>
          ))}
        </div>

        {links && links.length > 0 && (
          <div className="mt-4 bg-black/40 rounded-xl p-4 space-y-3">
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
              Diese Links werden nur jetzt angezeigt
            </p>
            {links.map(l => (
              <div key={l.id} className="space-y-1">
                <p className="text-[11px] text-stone-400">
                  {l.name}{l.email ? ` · ${l.email}` : ''}
                </p>
                <div className="flex items-center gap-2">
                  <p className="font-mono text-[10px] text-stone-200 break-all flex-1">{l.url}</p>
                  <button onClick={() => {
                      navigator.clipboard?.writeText(l.url);
                      setKopiert(l.id); setTimeout(() => setKopiert(''), 2000);
                    }}
                    className="shrink-0 text-stone-400 hover:text-white">
                    {kopiert === l.id ? <Check size={13} /> : <Copy size={13} />}
                  </button>
                </div>
              </div>
            ))}
            <p className="text-[10px] text-stone-500 leading-relaxed">
              In der Datenbank liegt nur eine Prüfsumme. Wer jetzt nicht kopiert, stellt neu aus.
            </p>
          </div>
        )}
      </div>

      {/* ------------------------------------------------ Abrechnen */}
      <div className={kasten}>
        <p className={titel}><Receipt size={13} /> Teilnahmebeiträge</p>
        <p className="text-[11px] text-stone-500 leading-relaxed mb-4">
          Legt je teilnehmendem Verein eine Rechnung als Entwurf an. Gastvereine haben keine
          Vereinszeile auf der Plattform — ihre Beiträge werden ausgewiesen und müssen
          ausserhalb gestellt werden.
        </p>
        <button onClick={verrechnen} disabled={!!arbeitet}
          className="flex items-center gap-2 bg-white text-stone-900 px-4 py-2 rounded-xl
                     text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
          {arbeitet === 'verrechnen' ? <Loader2 size={12} className="animate-spin" /> : <Receipt size={12} />}
          Beiträge verrechnen
        </button>
      </div>
    </div>
  );
};

export default TreffenWerkzeuge;
