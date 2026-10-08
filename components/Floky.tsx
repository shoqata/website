import React, { useEffect, useRef, useState } from 'react';
import { Sparkles, Send, Loader2, X, AlertTriangle, MessageSquare } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

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

type Zeile = { rolle: 'mensch' | 'floky'; text: string; werkzeuge?: string[] };

const Floky: React.FC = () => {
  const [offen, setOffen] = useState(false);
  const [darf, setDarf] = useState<boolean | null>(null);
  const [name, setName] = useState('Floky');
  const [uebrig, setUebrig] = useState<number | null>(null);
  const [verlauf, setVerlauf] = useState<Zeile[]>([]);
  const [eingabe, setEingabe] = useState('');
  const [laeuft, setLaeuft] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);
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
        body: { verlauf: neu.map(z => ({ rolle: z.rolle, text: z.text })) },
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
                            werkzeuge: data?.werkzeuge }]);
      if (typeof data?.uebrig === 'number') setUebrig(data.uebrig);
      if (data?.name) setName(data.name);
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
      setVerlauf(neu);
    } finally { setLaeuft(false); }
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
            </p>
          </div>
        )}
        {verlauf.map((z, i) => (
          <div key={i} className={z.rolle === 'mensch' ? 'flex justify-end' : ''}>
            <div className={`max-w-[85%] px-4 py-3 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap ${
              z.rolle === 'mensch' ? 'bg-stone-900 text-white' : 'bg-white border border-stone-100 text-stone-700'}`}>
              {z.text}
              {z.werkzeuge?.length ? (
                <p className="mt-2 pt-2 border-t border-stone-100 text-[10px] text-stone-400 uppercase tracking-widest">
                  gelesen: {z.werkzeuge.join(', ')}
                </p>
              ) : null}
            </div>
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

      <div className="p-3 border-t border-stone-100 shrink-0">
        <div className="flex items-end gap-2">
          <textarea value={eingabe} onChange={e => setEingabe(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); fragen(); } }}
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
