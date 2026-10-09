import React, { useEffect, useState } from 'react';
import { Loader2, CalendarClock, Save, Check, AlertTriangle } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Das Vereinsjahr.
//
// Die Vorgaben stammen aus dem Konzept und passen zu einem Verein mit
// Generalversammlung im Fruehjahr. Ein Verein mit GV im Herbst stellt sie
// hier um -- deshalb steht der Monat als Feld und nicht im Quelltext.
//
// Der Vorlauf steht als Tage und darf negativ sein: -7 heisst "eine Woche
// danach". Das klingt zunaechst eigen, erspart aber eine zweite Angabe
// "davor oder danach", die mit der ersten auseinanderlaufen koennte.

type Posten = {
  schluessel: string; monat: number; tag: number;
  vorlauf_tage: number; aktiv: boolean; reihenfolge: number;
};

// Die Namen stehen hier, nicht in der Datenbank: sie gehoeren zur
// Software. Was der Verein aendern will, sind die Monate.
const NAMEN: Record<string, { titel: string; was: string }> = {
  BEITRAGSLAUF:         { titel: 'Beitragslauf', was: 'Die Rechnungen des Jahres vorbereiten' },
  MAHNSTUFE_1:          { titel: 'Erste Mahnstufe', was: 'Wenn die Zahlungsfrist abläuft' },
  JAHRESABSCHLUSS:      { titel: 'Jahresabschluss und Revision', was: 'Abschluss und Zugang für die Revision' },
  GV_EINLADUNG:         { titel: 'Einladung zur GV', was: 'Einladung, Traktanden, Jahresbericht' },
  GV_NACHARBEIT:        { titel: 'Nach der GV', was: 'Protokoll und Jahressperre des Vorjahres' },
  SOMMERTREFFEN:        { titel: 'Treffen in der Heimat', was: 'Anmeldestand und Meldungen der Vertreter' },
  SPENDENBESCHEINIGUNG: { titel: 'Spendenbescheinigungen', was: 'Für alle Spender des Jahres' },
};

const MONATE = ['Januar','Februar','März','April','Mai','Juni',
                'Juli','August','September','Oktober','November','Dezember'];

const AdminVereinsjahr: React.FC = () => {
  const [posten, setPosten] = useState<Posten[] | null>(null);
  const [speichert, setSpeichert] = useState<string | null>(null);
  const [gespeichert, setGespeichert] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const { data, error } = await supabase.from('vereinsjahr')
        .select('schluessel,monat,tag,vorlauf_tage,aktiv,reihenfolge').order('reihenfolge');
      if (!lebt) return;
      if (error) { setFehler(error.message); setPosten([]); return; }
      setPosten((data as Posten[]) ?? []);
    })();
    return () => { lebt = false; };
  }, []);

  const sichern = async (p: Posten) => {
    setSpeichert(p.schluessel); setFehler(null);
    // .select() zurueckfordern: ein UPDATE ohne Treffer wirft keinen
    // Fehler, und "gespeichert" zu melden, waehrend nichts geschrieben
    // wurde, waere schlimmer als eine Fehlermeldung.
    const { data, error } = await supabase.from('vereinsjahr')
      .update({ monat: p.monat, tag: p.tag, vorlauf_tage: p.vorlauf_tage,
                aktiv: p.aktiv, geaendert_am: new Date().toISOString() })
      .eq('schluessel', p.schluessel).select('schluessel');
    setSpeichert(null);
    if (error) { setFehler(error.message); return; }
    if (!data?.length) { setFehler('Nicht gespeichert — fehlende Berechtigung?'); return; }
    setGespeichert(p.schluessel); setTimeout(() => setGespeichert(null), 2000);
  };

  // Wann die Erinnerung tatsaechlich kommt. Sie hier auszurechnen und
  // anzuzeigen ist der Punkt der Maske: "28 Tage vorher" sagt niemandem
  // etwas, "17. April" schon.
  const wann = (p: Posten) => {
    const jahr = new Date().getFullYear();
    const letzter = new Date(jahr, p.monat, 0).getDate();
    const termin = new Date(jahr, p.monat - 1, Math.min(p.tag, letzter));
    const d = new Date(termin); d.setDate(d.getDate() - p.vorlauf_tage);
    return d.toLocaleDateString('de-CH', { day: 'numeric', month: 'long' });
  };

  if (posten === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';
  const feld = 'p-2 bg-white border border-stone-200 rounded-lg text-sm outline-none focus:border-stone-300';

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div>
        <p className={`${marke} flex items-center gap-2`}><CalendarClock size={13} /> Das Vereinsjahr</p>
        <p className="text-[11px] text-stone-500 leading-relaxed mt-2 max-w-2xl">
          Woran erinnert werden soll und wann. Die Erinnerung geht an dieselben
          Personen wie der Wochenstart — ist dort niemand gewählt, wird nichts
          verschickt. Ein Minus beim Vorlauf heisst „danach": −7 erinnert eine
          Woche <em>nach</em> dem Termin.
        </p>
      </div>

      {posten.length === 0 ? (
        <p className="text-xs text-stone-400">Noch nichts eingerichtet.</p>
      ) : (
        <div className="bg-white rounded-2xl border border-stone-100 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-stone-50 text-stone-400 font-bold uppercase text-[10px] tracking-widest border-b border-stone-100">
              <tr>
                <th className="px-4 py-3">Anlass</th>
                <th className="px-4 py-3 w-36">Monat</th>
                <th className="px-4 py-3 w-20">Tag</th>
                <th className="px-4 py-3 w-28">Vorlauf</th>
                <th className="px-4 py-3 w-36">Erinnerung am</th>
                <th className="px-4 py-3 w-24"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-50">
              {posten.map(p => {
                const n = NAMEN[p.schluessel] ?? { titel: p.schluessel, was: '' };
                const setze = (teil: Partial<Posten>) =>
                  setPosten(posten.map(x => x.schluessel === p.schluessel ? { ...x, ...teil } : x));
                return (
                  <tr key={p.schluessel} className={p.aktiv ? '' : 'opacity-40'}>
                    <td className="px-4 py-2">
                      <label className="flex items-start gap-2.5 cursor-pointer">
                        <input type="checkbox" checked={p.aktiv}
                          onChange={e => setze({ aktiv: e.target.checked })}
                          className="w-4 h-4 accent-stone-900 mt-0.5 shrink-0" />
                        <span>
                          <span className="font-bold text-stone-800">{n.titel}</span>
                          <span className="block text-[10px] text-stone-400">{n.was}</span>
                        </span>
                      </label>
                    </td>
                    <td className="px-4 py-2">
                      <select value={p.monat} onChange={e => setze({ monat: Number(e.target.value) })}
                        className={`${feld} w-full`}>
                        {MONATE.map((m, i) => <option key={m} value={i + 1}>{m}</option>)}
                      </select>
                    </td>
                    <td className="px-4 py-2">
                      <input type="number" min={1} max={31} value={p.tag}
                        onChange={e => setze({ tag: Math.min(31, Math.max(1, Number(e.target.value) || 1)) })}
                        className={`${feld} w-full tabular-nums`} />
                    </td>
                    <td className="px-4 py-2">
                      <input type="number" value={p.vorlauf_tage}
                        onChange={e => setze({ vorlauf_tage: Number(e.target.value) || 0 })}
                        className={`${feld} w-full tabular-nums`} />
                    </td>
                    <td className="px-4 py-2 text-sm text-stone-500 tabular-nums">{wann(p)}</td>
                    <td className="px-4 py-2 text-right">
                      <button onClick={() => sichern(p)} disabled={speichert === p.schluessel}
                        className="text-[10px] font-bold uppercase tracking-widest text-stone-400
                                   hover:text-stone-900 disabled:opacity-40 flex items-center gap-1.5 ml-auto">
                        {speichert === p.schluessel ? <Loader2 size={11} className="animate-spin" />
                          : gespeichert === p.schluessel ? <Check size={11} className="text-emerald-600" />
                          : <Save size={11} />}
                        {gespeichert === p.schluessel ? 'ok' : 'Sichern'}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default AdminVereinsjahr;
