import React, { useEffect, useRef, useState } from 'react';
import {
  Sparkles, Send, Loader2, X, AlertTriangle, MessageSquare, Check,
  Plus, Archive, Trash2, PanelLeft, Maximize2, Minimize2,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { karteAusfuehren, type Karte } from '../lib/flokykarte';
import { useTranslation } from '../context/LanguageContext';

// Floky -- das Gespraechsfenster.
//
// Die Maske stellt keine eigenen Fragen an die Datenbank und prueft keine
// Rechte: beides macht die Funktion auf dem Server, und zwar mit dem Konto
// des Fragenden. Zwei Pruefungen laufen frueher oder spaeter auseinander.
//
// Drei Dinge, die hier bewusst so sind:
//
//   GESPRAECHE liegen in der Datenbank, nicht im Browser. Wer eine Karte
//   nicht sofort bestaetigt, soll sie morgen noch finden -- mit dem
//   Zusammenhang, in dem sie entstand.
//
//   DIE GROESSE merkt sich der Browser. Ein Fenster, das bei jedem Besuch
//   wieder klein ist, wird bei jedem Besuch wieder vergroessert.
//
//   DIE TASTATUR fuehrt durch die Befehlsliste. Vorher sendete Enter bei
//   offenem Menue die halb getippte Zeile ("/wo") -- und Floky verstand
//   sie nicht.

type Kuerzel = { kuerzel: string; wurde: string; offen: boolean };
type Zeile = {
  rolle: 'mensch' | 'floky'; text: string;
  werkzeuge?: string[]; karten?: Karte[]; kuerzel?: Kuerzel[];
};
type Kartenstand = { lauf?: boolean; fertig?: string; fehler?: string };
type Gespraech = { id: string; titel: string | null; archiviert: boolean; geaendert_am: string };

// Drei Groessen. Der Browser merkt sie sich -- ein Fenster, das bei jedem
// Besuch wieder klein ist, wird bei jedem Besuch wieder vergroessert.
const GROESSEN = {
  klein: 'w-[min(26rem,calc(100vw-3rem))] h-[min(34rem,calc(100vh-6rem))]',
  gross: 'w-[min(42rem,calc(100vw-3rem))] h-[min(48rem,calc(100vh-6rem))]',
  voll:  'w-[calc(100vw-3rem)] h-[calc(100vh-4rem)]',
} as const;
type Groesse = keyof typeof GROESSEN;

const MARKEN = /(^|\s)(\/\/|@|#|!|>)(?=[^\s@#!>])/g;

// Nur das Zeichen hervorheben. Wo ein Verweis endet, weiss der Browser
// nicht -- das entscheidet die Datenbank.
const mitMarken = (text: string) => {
  const teile: React.ReactNode[] = [];
  let pos = 0;
  for (const m of text.matchAll(MARKEN)) {
    const start = m.index! + m[1].length;
    if (start > pos) teile.push(<React.Fragment key={`v${start}`}>{text.slice(pos, start)}</React.Fragment>);
    teile.push(<span key={`m${start}`} className="text-white/50 font-bold">{m[2]}</span>);
    pos = start + m[2].length;
  }
  if (!teile.length) return text;
  if (pos < text.length) teile.push(<React.Fragment key="rest">{text.slice(pos)}</React.Fragment>);
  return teile;
};

// **fett** darstellen, sonst nichts. Bewusst kein Markdown-Werkzeug und
// kein dangerouslySetInnerHTML: der Text kommt von einem Sprachmodell.
const mitFett = (text: string) =>
  text.split(/(\*\*[^*]+\*\*)/g).map((teil, i) =>
    teil.startsWith('**') && teil.endsWith('**') && teil.length > 4
      ? <strong key={i} className="font-bold text-stone-900">{teil.slice(2, -2)}</strong>
      : <React.Fragment key={i}>{teil}</React.Fragment>);

const Floky: React.FC = () => {
  const { language } = useTranslation();
  const [offen, setOffen] = useState(false);
  const [darf, setDarf] = useState<boolean | null>(null);
  const [name, setName] = useState('Floky');
  const [uebrig, setUebrig] = useState<number | null>(null);
  const [verlauf, setVerlauf] = useState<Zeile[]>([]);
  const [eingabe, setEingabe] = useState('');
  const [laeuft, setLaeuft] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);
  const [kartenstand, setKartenstand] = useState<Record<string, Kartenstand>>({});
  const [befehle, setBefehle] = useState<{ name: string; zweck: string }[]>([]);
  const [zeigeBefehle, setZeigeBefehle] = useState(false);
  const [markiert, setMarkiert] = useState(0);

  const [groesse, setGroesse] = useState<Groesse>(() => {
    const g = localStorage.getItem('floky-groesse');
    return (g === 'klein' || g === 'gross' || g === 'voll') ? g : 'klein';
  });
  const [gespraeche, setGespraeche] = useState<Gespraech[]>([]);
  const [aktuell, setAktuell] = useState<string | null>(null);
  const [zeigeListe, setZeigeListe] = useState(false);
  const [zeigeArchiv, setZeigeArchiv] = useState(false);

  const ende = useRef<HTMLDivElement>(null);
  const feld = useRef<HTMLTextAreaElement>(null);

  useEffect(() => { localStorage.setItem('floky-groesse', groesse); }, [groesse]);

  const gespraecheLaden = async () => {
    const { data } = await supabase.from('floky_gespraeche')
      .select('id,titel,archiviert,geaendert_am').order('geaendert_am', { ascending: false }).limit(60);
    setGespraeche((data as Gespraech[]) ?? []);
  };

  useEffect(() => {
    let lebt = true;
    (async () => {
      const { data, error } = await supabase.rpc('floky_darf');
      if (!lebt) return;
      setDarf(!error && !!data);
      if (error || !data) return;
      const { data: k } = await supabase.rpc('floky_kontingent');
      const kk = Array.isArray(k) ? k[0] : k;
      if (kk && lebt) { setName(kk.assistent_name || 'Floky'); setUebrig(kk.uebrig); }
      const { data: b } = await supabase.functions.invoke('floky', { body: { befehle: true } });
      if (lebt && Array.isArray(b?.befehle)) setBefehle(b.befehle);
      if (lebt) await gespraecheLaden();
    })();
    return () => { lebt = false; };
  }, []);

  useEffect(() => { ende.current?.scrollIntoView({ behavior: 'smooth' }); }, [verlauf, laeuft]);

  const gefiltert = befehle.filter(b => b.name.startsWith(eingabe.trim().toLowerCase()));
  useEffect(() => { setMarkiert(0); }, [eingabe]);

  const gespraechOeffnen = async (id: string) => {
    setZeigeListe(false); setFehler(null); setKartenstand({});
    const { data } = await supabase.from('floky_nachrichten')
      .select('rolle,text,werkzeuge,karten,kuerzel').eq('gespraech_id', id).order('erstellt_am');
    setAktuell(id);
    setVerlauf((data ?? []).map((n: any) => ({
      rolle: n.rolle, text: n.text, werkzeuge: n.werkzeuge ?? undefined,
      karten: n.karten ?? undefined, kuerzel: n.kuerzel ?? undefined,
    })));
  };

  const neuesGespraech = () => {
    // Die Zeile in der Datenbank entsteht erst mit der ersten Nachricht --
    // sonst sammelten sich leere Gespraeche von jedem Klick.
    setAktuell(null); setVerlauf([]); setKartenstand({});
    setFehler(null); setZeigeListe(false);
    setTimeout(() => feld.current?.focus(), 50);
  };

  const archivieren = async (id: string, an: boolean) => {
    const { error } = await supabase.rpc('floky_gespraech_ablegen', { p_id: id, p_archiv: an });
    if (error) { setFehler(error.message); return; }
    if (an && id === aktuell) neuesGespraech();
    await gespraecheLaden();
  };

  const loeschen = async (id: string) => {
    const { error } = await supabase.rpc('floky_gespraech_loeschen', { p_id: id });
    if (error) { setFehler(error.message); return; }
    if (id === aktuell) neuesGespraech();
    await gespraecheLaden();
  };

  const fragen = async () => {
    const text = eingabe.trim();
    if (!text || laeuft) return;
    const neu: Zeile[] = [...verlauf, { rolle: 'mensch', text }];
    setVerlauf(neu); setEingabe(''); setLaeuft(true); setFehler(null);

    let id = aktuell;
    try {
      if (!id) {
        const { data, error } = await supabase.rpc('floky_gespraech_beginnen');
        if (error) throw new Error(error.message);
        id = data as string; setAktuell(id);
      }
      await supabase.rpc('floky_nachricht_ablegen',
        { p_gespraech: id, p_rolle: 'mensch', p_text: text });

      const { data, error } = await supabase.functions.invoke('floky', {
        body: { sprache: language, verlauf: neu.map(z => ({ rolle: z.rolle, text: z.text })) },
      });
      if (error) {
        // invoke() liefert bei 4xx/5xx den Leib im Fehler mit; ohne das
        // stuende hier "non-2xx status code" statt des eigentlichen Grundes.
        let grund = error.message;
        try { const j = await (error as any).context?.json?.(); if (j?.fehler) grund = j.fehler; } catch { /* dann die Kurzform */ }
        throw new Error(grund);
      }
      if (data?.fehler) throw new Error(data.fehler);

      const antwort: Zeile = {
        rolle: 'floky', text: data?.text || '(keine Antwort)',
        werkzeuge: data?.werkzeuge, karten: data?.karten ?? [], kuerzel: data?.kuerzel ?? [],
      };
      setVerlauf([...neu, antwort]);
      await supabase.rpc('floky_nachricht_ablegen', {
        p_gespraech: id, p_rolle: 'floky', p_text: antwort.text,
        p_werkzeuge: antwort.werkzeuge ?? null,
        p_karten: antwort.karten?.length ? antwort.karten : null,
        p_kuerzel: antwort.kuerzel?.length ? antwort.kuerzel : null,
      });
      if (typeof data?.uebrig === 'number') setUebrig(data.uebrig);
      if (data?.name) setName(data.name);
      await gespraecheLaden();
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
      setVerlauf(neu);
    } finally { setLaeuft(false); }
  };

  const ausfuehren = async (schluessel: string, k: Karte) => {
    setKartenstand(z => ({ ...z, [schluessel]: { lauf: true } }));
    try {
      const satz = await karteAusfuehren(k);
      setKartenstand(z => ({ ...z, [schluessel]: { fertig: satz } }));
      await supabase.rpc('floky_protokollieren', {
        p_art: 'BESTAETIGT', p_werkzeug: k.art,
        p_zusammenfassung: k.felder.map(([a, b]) => `${a}: ${b}`).join(', '),
      });
    } catch (e: any) {
      setKartenstand(z => ({ ...z, [schluessel]: { fehler: e?.message ?? String(e) } }));
    }
  };

  const verwerfen = async (schluessel: string, k: Karte) => {
    setKartenstand(z => ({ ...z, [schluessel]: { fehler: 'Verworfen.' } }));
    await supabase.rpc('floky_protokollieren', {
      p_art: 'ABGELEHNT', p_werkzeug: k.art,
      p_zusammenfassung: k.felder.map(([a, b]) => `${a}: ${b}`).join(', '),
    });
  };

  if (darf !== true) return null;

  if (!offen) return (
    <button onClick={() => setOffen(true)}
      className="fixed bottom-6 right-6 z-40 flex items-center gap-2 bg-stone-900 text-white
                 pl-4 pr-5 py-3 rounded-2xl shadow-2xl hover:bg-stone-800 transition-colors">
      <Sparkles size={16} className="text-[color:var(--primary)]" />
      <span className="text-xs font-bold uppercase tracking-widest">{name}</span>
    </button>
  );

  const sichtbar = gespraeche.filter(g => g.archiviert === zeigeArchiv);

  return (
    <div className={`fixed bottom-6 right-6 z-40 bg-white rounded-3xl shadow-2xl
                     border border-stone-200 flex overflow-hidden transition-all
                     ${GROESSEN[groesse]}`}>

      {/* --------------------------------------------- Gesprächsliste */}
      {zeigeListe && (
        <div className="w-60 shrink-0 border-r border-stone-100 bg-[#faf9f6] flex flex-col">
          <div className="p-3 shrink-0">
            <button onClick={neuesGespraech}
              className="w-full flex items-center justify-center gap-2 bg-stone-900 text-white
                         py-2.5 rounded-xl text-[10px] font-bold uppercase tracking-widest">
              <Plus size={13} /> Neues Gespräch
            </button>
            <div className="flex gap-1 mt-3 bg-white p-1 rounded-lg border border-stone-200">
              {([[false, 'Laufend'], [true, 'Abgelegt']] as const).map(([w, n]) => (
                <button key={String(w)} onClick={() => setZeigeArchiv(w)}
                  className={`flex-1 py-1.5 rounded text-[10px] font-bold transition-all ${
                    zeigeArchiv === w ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                  {n}
                </button>
              ))}
            </div>
          </div>
          <div className="flex-1 overflow-y-auto px-2 pb-2 space-y-0.5 custom-scrollbar">
            {sichtbar.length === 0 && (
              <p className="text-[11px] text-stone-400 text-center py-6 px-2 leading-relaxed">
                {zeigeArchiv ? 'Nichts abgelegt.' : 'Noch kein Gespräch.'}
              </p>
            )}
            {sichtbar.map(g => (
              <div key={g.id}
                className={`group rounded-xl px-3 py-2 cursor-pointer ${
                  g.id === aktuell ? 'bg-white border border-stone-200' : 'hover:bg-white/70'}`}
                onClick={() => gespraechOeffnen(g.id)}>
                <p className="text-xs text-stone-700 leading-snug line-clamp-2">
                  {g.titel || 'Ohne Titel'}
                </p>
                <div className="flex items-center justify-between gap-2 mt-1">
                  <span className="text-[10px] text-stone-400 tabular-nums">
                    {new Date(g.geaendert_am).toLocaleDateString('de-CH')}
                  </span>
                  <span className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button title={zeigeArchiv ? 'Zurückholen' : 'Ablegen'}
                      onClick={e => { e.stopPropagation(); archivieren(g.id, !zeigeArchiv); }}
                      className="p-1 text-stone-400 hover:text-stone-900"><Archive size={12} /></button>
                    <button title="Löschen"
                      onClick={e => { e.stopPropagation(); loeschen(g.id); }}
                      className="p-1 text-stone-400 hover:text-red-600"><Trash2 size={12} /></button>
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ------------------------------------------------- Das Gespräch */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center justify-between gap-2 px-4 py-3 bg-stone-900 text-white shrink-0">
          <div className="flex items-center gap-2 min-w-0">
            <button onClick={() => setZeigeListe(!zeigeListe)} title="Gespräche"
              className={`p-1.5 rounded-lg transition-colors ${
                zeigeListe ? 'bg-white/15 text-white' : 'text-white/50 hover:text-white'}`}>
              <PanelLeft size={15} />
            </button>
            <Sparkles size={15} className="text-[color:var(--primary)] shrink-0" />
            <span className="text-xs font-bold uppercase tracking-widest truncate">{name}</span>
            {uebrig !== null && (
              <span className="text-[10px] text-white/40 tabular-nums shrink-0">{uebrig} übrig</span>
            )}
          </div>
          <div className="flex items-center gap-0.5 shrink-0">
            <button onClick={neuesGespraech} title="Neues Gespräch"
              className="p-1.5 text-white/50 hover:text-white rounded-lg"><Plus size={15} /></button>
            {aktuell && (
              <button onClick={() => archivieren(aktuell, true)} title="Dieses Gespräch ablegen"
                className="p-1.5 text-white/50 hover:text-white rounded-lg"><Archive size={14} /></button>
            )}
            <button
              onClick={() => setGroesse(groesse === 'klein' ? 'gross' : groesse === 'gross' ? 'voll' : 'klein')}
              title={groesse === 'voll' ? 'Verkleinern' : 'Vergrössern'}
              className="p-1.5 text-white/50 hover:text-white rounded-lg">
              {groesse === 'voll' ? <Minimize2 size={14} /> : <Maximize2 size={14} />}
            </button>
            <button onClick={() => setOffen(false)} title="Schliessen"
              className="p-1.5 text-white/50 hover:text-white rounded-lg"><X size={15} /></button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4 bg-[#faf9f6] custom-scrollbar">
          {verlauf.length === 0 && (
            <div className="text-center py-10">
              <MessageSquare size={32} className="mx-auto text-stone-200 mb-3" />
              <p className="text-xs text-stone-400 leading-relaxed max-w-xs mx-auto">
                Fragen Sie in Ihrer Sprache — deutsch, shqip oder englisch.
                <br /><br />
                <span className="text-stone-300">„Wer hat den Beitrag 2026 noch nicht bezahlt?"</span>
                <br /><br />
                <span className="text-stone-400">
                  <code className="font-mono bg-stone-100 rounded px-1">/</code> zeigt die Kurzbefehle
                </span>
              </p>
              <div className="mt-5 pt-4 border-t border-stone-100 text-left max-w-xs mx-auto space-y-1">
                {[['@', 'Mitglied, Familie, Anlass, Rechnung'],
                  ['//', 'Datum oder Frist'],
                  ['#', 'Nachbarschaft, Kategorie, Konto'],
                  ['!', 'Priorität'],
                  ['>', 'Textbaustein des Vereins']].map(([z, w]) => (
                  <p key={z} className="text-[11px] text-stone-400 flex gap-2">
                    <code className="font-mono font-bold text-stone-500 w-6 shrink-0">{z}</code>{w}
                  </p>
                ))}
              </div>
            </div>
          )}

          {verlauf.map((z, i) => (
            <div key={i} className={z.rolle === 'mensch' ? 'flex justify-end' : ''}>
              <div className={`max-w-[85%] px-4 py-3 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap ${
                z.rolle === 'mensch' ? 'bg-stone-900 text-white' : 'bg-white border border-stone-100 text-stone-700'}`}>
                {z.rolle === 'floky' ? mitFett(z.text) : mitMarken(z.text)}
                {/* Was aus den Kuerzeln wurde. Ohne das tippt jemand
                    "@Gashi" und erfaehrt nie, dass zwei Personen so
                    heissen -- er saehe nur eine Rueckfrage ohne Grund. */}
                {z.kuerzel?.length ? (
                  <div className="mt-2 pt-2 border-t border-stone-100 space-y-1">
                    {z.kuerzel.map((k, n) => (
                      <p key={n} className={`text-[10px] leading-snug ${k.offen ? 'text-amber-600' : 'text-stone-400'}`}>
                        <code className="font-mono font-bold">{k.kuerzel}</code>{' → '}{k.wurde}
                      </p>
                    ))}
                  </div>
                ) : null}
                {z.werkzeuge?.length ? (
                  <p className="mt-2 pt-2 border-t border-stone-100 text-[10px] text-stone-400 uppercase tracking-widest">
                    gelesen: {z.werkzeuge.join(', ')}
                  </p>
                ) : null}
              </div>

              {/* Karten stehen ausserhalb der Sprechblase: sie sind keine
                  Aussage, sondern etwas zu Entscheidendes. */}
              {z.karten?.map((k, j) => {
                const sl = `${i}-${j}`;
                const st = kartenstand[sl] ?? {};
                return (
                  <div key={sl} className="mt-2 bg-white border border-stone-200 rounded-2xl p-4 shadow-sm">
                    <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-3">{k.titel}</p>
                    <div className="space-y-1.5 mb-3">
                      {k.felder.map(([bez, wert]) => {
                        const lang = String(wert).length > 60;
                        return lang ? (
                          <div key={bez}>
                            <p className="text-[10px] text-stone-400 uppercase tracking-widest mb-1">{bez}</p>
                            <p className="text-xs text-stone-700 leading-relaxed whitespace-pre-wrap">{wert}</p>
                          </div>
                        ) : (
                          <div key={bez} className="flex justify-between gap-4 text-xs">
                            <span className="text-stone-400">{bez}</span>
                            <span className="font-bold text-stone-800 tabular-nums text-right">{wert}</span>
                          </div>
                        );
                      })}
                    </div>
                    {st.fertig ? (
                      <p className="text-xs font-bold text-emerald-600 flex items-center gap-1.5">
                        <Check size={13} /> {st.fertig}
                      </p>
                    ) : st.fehler ? (
                      <p className="text-xs text-red-600 flex items-start gap-1.5">
                        <AlertTriangle size={13} className="shrink-0 mt-0.5" /> {st.fehler}
                      </p>
                    ) : (
                      <div className="flex gap-2">
                        <button onClick={() => ausfuehren(sl, k)} disabled={st.lauf}
                          className="flex-1 bg-stone-900 text-white py-2 rounded-xl text-[10px]
                                     font-bold uppercase tracking-widest disabled:opacity-40
                                     flex items-center justify-center gap-1.5">
                          {st.lauf ? <Loader2 size={12} className="animate-spin" /> : <Check size={12} />}
                          Ausführen
                        </button>
                        <button onClick={() => verwerfen(sl, k)} disabled={st.lauf}
                          className="px-3 py-2 rounded-xl text-[10px] font-bold uppercase
                                     tracking-widest text-stone-400 hover:text-stone-700">
                          Verwerfen
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          ))}

          {laeuft && (
            <div className="flex items-center gap-2 text-stone-400 text-xs">
              <Loader2 size={13} className="animate-spin" /> denkt nach …
            </div>
          )}
          {fehler && (
            <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
              <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
            </p>
          )}
          <div ref={ende} />
        </div>

        <div className="p-3 border-t border-stone-100 shrink-0 relative">
          {zeigeBefehle && gefiltert.length > 0 && (
            <div className="absolute bottom-full left-3 right-3 mb-2 bg-white border border-stone-200
                            rounded-2xl shadow-xl overflow-hidden max-h-64 overflow-y-auto">
              {gefiltert.map((b, i) => (
                <button key={b.name}
                  onMouseEnter={() => setMarkiert(i)}
                  onClick={() => { setEingabe(b.name + ' '); setZeigeBefehle(false); feld.current?.focus(); }}
                  className={`w-full text-left px-4 py-2.5 border-b border-stone-50 last:border-0 ${
                    i === markiert ? 'bg-stone-100' : 'hover:bg-stone-50'}`}>
                  <span className="font-mono text-xs font-bold text-stone-800">{b.name}</span>
                  <span className="block text-[11px] text-stone-400 mt-0.5">{b.zweck}</span>
                </button>
              ))}
              <p className="px-4 py-2 text-[10px] text-stone-400 bg-stone-50 border-t border-stone-100">
                ↑ ↓ wählen · ⏎ oder ⇥ übernehmen · esc schliessen
              </p>
            </div>
          )}

          <div className="flex items-end gap-2">
            <textarea ref={feld} value={eingabe}
              onChange={e => {
                setEingabe(e.target.value);
                // Nur am Zeilenanfang und solange kein Leerzeichen getippt
                // ist -- sonst springt die Liste mitten im Satz auf.
                setZeigeBefehle(/^\/[a-zäöü]*$/i.test(e.target.value));
              }}
              onKeyDown={e => {
                // Die Tastatur fuehrt durch die Liste. Vorher sendete Enter
                // bei offenem Menue die halb getippte Zeile ("/wo"), und
                // Floky verstand sie nicht.
                if (zeigeBefehle && gefiltert.length) {
                  if (e.key === 'ArrowDown') {
                    e.preventDefault(); setMarkiert(m => (m + 1) % gefiltert.length); return;
                  }
                  if (e.key === 'ArrowUp') {
                    e.preventDefault();
                    setMarkiert(m => (m - 1 + gefiltert.length) % gefiltert.length); return;
                  }
                  if (e.key === 'Enter' || e.key === 'Tab') {
                    e.preventDefault();
                    setEingabe(gefiltert[Math.min(markiert, gefiltert.length - 1)].name + ' ');
                    setZeigeBefehle(false); return;
                  }
                }
                if (e.key === 'Escape') { setZeigeBefehle(false); return; }
                if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); fragen(); }
              }}
              rows={1} placeholder="Frage oder Auftrag …"
              className="flex-1 resize-none p-3 bg-stone-50 border border-stone-200 rounded-xl
                         text-sm outline-none focus:border-stone-300 max-h-32" />
            <button onClick={fragen} disabled={laeuft || !eingabe.trim()}
              className="p-3 bg-stone-900 text-white rounded-xl disabled:opacity-30 shrink-0">
              {laeuft ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
            </button>
          </div>
          <p className="text-[10px] text-stone-400 mt-2 px-1 leading-relaxed">
            {name} schlägt vor — gebucht, verschickt oder veröffentlicht wird nichts ohne Ihre Bestätigung.
          </p>
        </div>
      </div>
    </div>
  );
};

export default Floky;
