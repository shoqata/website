import React, { useEffect, useRef, useState } from 'react';
import { Sparkles, Send, Loader2, X, AlertTriangle, MessageSquare, Check } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { karteAusfuehren, type Karte } from '../lib/flokykarte';
import { useTranslation } from '../context/LanguageContext';

// Floky -- das Gespraechsfenster.
//
// Die Maske stellt keine eigenen Fragen an die Datenbank und prueft keine
// Rechte: beides macht die Funktion auf dem Server, und zwar mit dem Konto
// des Fragenden. Zwei Pruefungen laufen frueher oder spaeter auseinander --
// dann zeigte die Oberflaeche etwas an, das der Server nicht hergibt, oder
// umgekehrt.
//
// Sie zeigt nur, was ohnehin wahr ist: ist das Modul nicht gebucht,
// erscheint der Knopf gar nicht.

type Kuerzel = { kuerzel: string; wurde: string; offen: boolean };
type Zeile = { rolle: 'mensch' | 'floky'; text: string; werkzeuge?: string[]; karten?: Karte[]; kuerzel?: Kuerzel[] };

// **fett** darstellen, sonst nichts. Der Wochenstart gliedert damit seine
// Abschnitte, und roh gesetzte Sternchen sahen aus wie ein Fehler.
//
// Bewusst kein Markdown-Werkzeug und kein dangerouslySetInnerHTML: der Text
// kommt von einem Sprachmodell. Ihm HTML zu erlauben, hiesse ihm das
// Fenster zu oeffnen.
// Die Kuerzel im eigenen Text hervorheben. Ohne das tippt jemand
// "@Arben" und sieht nicht, ob es als Verweis gelesen wurde oder nur als
// Zeichen.
const MARKEN = /(^|\s)(\/\/|@|#|!|>)(?=[^\s@#!>])/g;
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

const mitFett = (text: string) =>
  text.split(/(\*\*[^*]+\*\*)/g).map((teil, i) =>
    teil.startsWith('**') && teil.endsWith('**') && teil.length > 4
      ? <strong key={i} className="font-bold text-stone-900">{teil.slice(2, -2)}</strong>
      : <React.Fragment key={i}>{teil}</React.Fragment>);

// Zustand je Karte: offen, laeuft, erledigt (mit Satz) oder gescheitert.
type Kartenstand = { lauf?: boolean; fertig?: string; fehler?: string };

const Floky: React.FC = () => {
  // Die eingestellte Sprache geht mit. Floky hat sie bisher aus der
  // Nachricht geraten -- und lag falsch: wer deutsch schrieb, bekam
  // albanisch zurueck. Was die Oberflaeche weiss, muss sie sagen.
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
  // Die Befehlsliste kommt vom Server: dort steht, welche Rolle welche
  // bekommt. Eine zweite Liste im Browser liefe auseinander.
  const [befehle, setBefehle] = useState<{ name: string; zweck: string }[]>([]);
  const [zeigeBefehle, setZeigeBefehle] = useState(false);
  const ende = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const { data, error } = await supabase.rpc('floky_darf');
      if (!lebt) return;
      // Ein Fehler heisst hier: nicht angemeldet oder keine Berechtigung.
      // In beiden Faellen gibt es nichts anzuzeigen.
      setDarf(!error && !!data);
      if (!error && data) {
        const { data: k } = await supabase.rpc('floky_kontingent');
        const kk = Array.isArray(k) ? k[0] : k;
        if (kk && lebt) { setName(kk.assistent_name || 'Floky'); setUebrig(kk.uebrig); }
        const { data: b } = await supabase.functions.invoke('floky', { body: { befehle: true } });
        if (lebt && Array.isArray(b?.befehle)) setBefehle(b.befehle);
      }
    })();
    return () => { lebt = false; };
  }, []);

  useEffect(() => { ende.current?.scrollIntoView({ behavior: 'smooth' }); }, [verlauf, laeuft]);

  const fragen = async () => {
    const text = eingabe.trim();
    if (!text || laeuft) return;
    const neu: Zeile[] = [...verlauf, { rolle: 'mensch', text }];
    setVerlauf(neu); setEingabe(''); setLaeuft(true); setFehler(null);
    try {
      const { data, error } = await supabase.functions.invoke('floky', {
        body: { sprache: language, verlauf: neu.map(z => ({ rolle: z.rolle, text: z.text })) },
      });
      if (error) {
        // invoke() liefert bei 4xx/5xx den Leib im Fehler mit; ohne das
        // stuende hier "non-2xx status code" statt des eigentlichen Grundes.
        let grund = error.message;
        try { const j = await (error as any).context?.json?.(); if (j?.fehler) grund = j.fehler; } catch { /* dann eben die Kurzform */ }
        throw new Error(grund);
      }
      if (data?.fehler) throw new Error(data.fehler);
      setVerlauf([...neu, { rolle: 'floky', text: data?.text || '(keine Antwort)',
                            werkzeuge: data?.werkzeuge, karten: data?.karten ?? [],
                            kuerzel: data?.kuerzel ?? [] }]);
      if (typeof data?.uebrig === 'number') setUebrig(data.uebrig);
      if (data?.name) setName(data.name);
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

  return (
    <div className="fixed bottom-6 right-6 z-40 w-[min(26rem,calc(100vw-3rem))]
                    h-[min(34rem,calc(100vh-6rem))] bg-white rounded-3xl shadow-2xl
                    border border-stone-200 flex flex-col overflow-hidden">
      <div className="flex items-center justify-between gap-3 px-5 py-4 bg-stone-900 text-white shrink-0">
        <div className="flex items-center gap-2 min-w-0">
          <Sparkles size={15} className="text-[color:var(--primary)] shrink-0" />
          <span className="text-xs font-bold uppercase tracking-widest truncate">{name}</span>
          {uebrig !== null && (
            <span className="text-[10px] text-white/40 tabular-nums shrink-0">
              {uebrig} übrig
            </span>
          )}
        </div>
        <button onClick={() => setOffen(false)} className="p-1 text-white/50 hover:text-white">
          <X size={16} />
        </button>
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
                  <code className="font-mono font-bold text-stone-500 w-6 shrink-0">{z}</code>
                  {w}
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
                  heissen -- er sieht nur eine Rueckfrage ohne Grund. */}
              {z.kuerzel?.length ? (
                <div className="mt-2 pt-2 border-t border-stone-100 space-y-1">
                  {z.kuerzel.map((k, n) => (
                    <p key={n} className={`text-[10px] leading-snug ${k.offen ? 'text-amber-600' : 'text-stone-400'}`}>
                      <code className="font-mono font-bold">{k.kuerzel}</code>
                      {' → '}{k.wurde}
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
            {/* Karten. Sie stehen ausserhalb der Sprechblase, weil sie
                keine Aussage sind, sondern etwas zu Entscheidendes. */}
            {z.karten?.map((k, j) => {
              const sl = `${i}-${j}`;
              const st = kartenstand[sl] ?? {};
              return (
                <div key={sl} className="mt-2 bg-white border border-stone-200 rounded-2xl p-4 shadow-sm">
                  <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-3">
                    {k.titel}
                  </p>
                  <div className="space-y-1.5 mb-3">
                    {k.felder.map(([bez, wert]) => {
                      // Ein Absatz gehoert nicht in eine rechtsbuendige
                      // Wertspalte: fett und rechts ausgerichtet liest ihn
                      // niemand. Lange Werte stehen deshalb unter ihrer
                      // Beschriftung und in normaler Schrift.
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
        {zeigeBefehle && befehle.length > 0 && (
          <div className="absolute bottom-full left-3 right-3 mb-2 bg-white border border-stone-200
                          rounded-2xl shadow-xl overflow-hidden max-h-64 overflow-y-auto">
            {befehle
              .filter(b => b.name.startsWith(eingabe.trim().toLowerCase()))
              .map(b => (
              <button key={b.name}
                onClick={() => { setEingabe(b.name + ' '); setZeigeBefehle(false); }}
                className="w-full text-left px-4 py-2.5 hover:bg-stone-50 border-b border-stone-50 last:border-0">
                <span className="font-mono text-xs font-bold text-stone-800">{b.name}</span>
                <span className="block text-[11px] text-stone-400 mt-0.5">{b.zweck}</span>
              </button>
            ))}
          </div>
        )}
        <div className="flex items-end gap-2">
          <textarea value={eingabe}
            onChange={e => {
              setEingabe(e.target.value);
              // Nur am Zeilenanfang und solange noch kein Leerzeichen
              // getippt ist -- sonst springt die Liste mitten im Satz auf.
              setZeigeBefehle(/^\/[a-zäöü]*$/i.test(e.target.value));
            }}
            onKeyDown={e => {
              if (e.key === 'Escape') { setZeigeBefehle(false); return; }
              if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); setZeigeBefehle(false); fragen(); }
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
  );
};

export default Floky;
