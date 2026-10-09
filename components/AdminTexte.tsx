import React, { useEffect, useState } from 'react';
import { Loader2, Save, Check, AlertTriangle, Languages, BookMarked, Eye } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Textbausteine und Glossar.
//
// Zwei Dinge, die zusammengehoeren: der Baustein sagt, WAS geschrieben
// wird, das Glossar sagt, WIE die Vereinsbegriffe darin heissen. Wer
// "Lagje" einmal mit Nachbarschaft und einmal mit Quartier uebersetzt,
// schreibt in jedem Brief etwas anderes -- und genau das faellt
// Mitgliedern auf.
//
// Gespeichert wird direkt auf die Tabellen; die Zeilenregeln lassen das
// nur fuer den eigenen Verein und nur der Verwaltung zu. Die Maske
// verlaesst sich darauf und prueft nicht noch einmal selbst -- zwei
// Pruefungen laufen frueher oder spaeter auseinander.

type Baustein = {
  id: string; schluessel: string; sprache: string;
  betreff: string | null; text: string; aktiv: boolean;
  // Wer hat diesen Wortlaut gegengelesen? geprueft_text haelt fest, WELCHE
  // Fassung -- weicht sie vom heutigen Text ab, ist der Vermerk ueberholt.
  geprueft_am: string | null; geprueft_von: string | null; geprueft_text: string | null;
};
type Begriff = { begriff: string; de: string | null; sq: string | null; en: string | null; hinweis: string | null };

const SPRACHEN = [
  { wert: 'de', name: 'Deutsch' },
  { wert: 'sq', name: 'Shqip' },
  { wert: 'en', name: 'English' },
] as const;

// Die Schluessel heissen in der Datenbank nach ihrem Zweck. Hier stehen
// die Namen, die ein Vorstand erwartet.
const NAMEN: Record<string, string> = {
  MAHNUNG_1: 'Erste Mahnung',
  MAHNUNG_2: 'Zweite Mahnung',
  DANK_SPENDE: 'Dank für eine Spende',
  EINLADUNG_GV: 'Einladung zur Generalversammlung',
};

const PLATZHALTER = ['{{anrede}}', '{{verein}}', '{{jahr}}', '{{betrag}}',
                     '{{frist}}', '{{datum}}', '{{ort}}', '{{zweck}}', '{{traktanden}}'];

const AdminTexte: React.FC = () => {
  const [bausteine, setBausteine] = useState<Baustein[] | null>(null);
  const [begriffe, setBegriffe] = useState<Begriff[] | null>(null);
  const [sprache, setSprache] = useState<string>('de');
  const [offen, setOffen] = useState<string | null>(null);
  const [speichert, setSpeichert] = useState<string | null>(null);
  const [gespeichert, setGespeichert] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  const laden = async () => {
    const [{ data: b, error: e1 }, { data: g, error: e2 }] = await Promise.all([
      supabase.from('textbausteine').select('*').order('schluessel'),
      supabase.from('glossar').select('*').order('begriff'),
    ]);
    if (e1 || e2) { setFehler(e1?.message || e2?.message || 'Nicht lesbar.'); }
    setBausteine((b as Baustein[]) || []);
    setBegriffe((g as Begriff[]) || []);
  };
  useEffect(() => { laden(); }, []);

  // Ein Vermerk gilt nur fuer den Wortlaut, der gegengelesen wurde.
  const istGeprueft = (b: Baustein) =>
    !!b.geprueft_am && b.geprueft_text === b.text;
  const istUeberholt = (b: Baustein) =>
    !!b.geprueft_am && b.geprueft_text !== b.text;

  const gegenlesen = async (b: Baustein, an: boolean) => {
    setSpeichert(b.id); setFehler(null);
    const { error } = await supabase.rpc('baustein_gegengelesen', { p_id: b.id, p_an: an });
    setSpeichert(null);
    if (error) { setFehler(error.message); return; }
    await laden();
  };

  const bausteinSichern = async (b: Baustein) => {
    setSpeichert(b.id); setFehler(null);
    // .select() zurueckfordern: ein UPDATE ohne Treffer wirft keinen
    // Fehler, und "gespeichert" zu melden, waehrend nichts geschrieben
    // wurde, ist schlimmer als eine Fehlermeldung.
    const { data, error } = await supabase.from('textbausteine')
      .update({ betreff: b.betreff, text: b.text, geaendert_am: new Date().toISOString() })
      .eq('id', b.id).select('id');
    setSpeichert(null);
    if (error) { setFehler(error.message); return; }
    if (!data || data.length === 0) { setFehler('Nicht gespeichert — fehlende Berechtigung?'); return; }
    setGespeichert(b.id); setTimeout(() => setGespeichert(null), 2000);
  };

  const begriffSichern = async (g: Begriff) => {
    setSpeichert(g.begriff); setFehler(null);
    const { data, error } = await supabase.from('glossar')
      .update({ de: g.de, sq: g.sq, en: g.en, geaendert_am: new Date().toISOString() })
      .eq('begriff', g.begriff).select('begriff');
    setSpeichert(null);
    if (error) { setFehler(error.message); return; }
    if (!data || data.length === 0) { setFehler('Nicht gespeichert — fehlende Berechtigung?'); return; }
    setGespeichert(g.begriff); setTimeout(() => setGespeichert(null), 2000);
  };

  if (bausteine === null || begriffe === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm text-stone-700 outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)]';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';
  const schluesselListe = [...new Set(bausteine.map(b => b.schluessel))];

  return (
    <div className="space-y-6">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {/* ------------------------------------------------ Textbausteine */}
      <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <p className={marke}>Textbausteine</p>
          <div className="flex gap-1 bg-white p-1 rounded-xl border border-stone-200">
            {SPRACHEN.map(s => (
              <button key={s.wert} onClick={() => setSprache(s.wert)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  sprache === s.wert ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                {s.name}
              </button>
            ))}
          </div>
        </div>
        {sprache === 'sq' && bausteine.some(b => b.sprache === 'sq' && !b.geprueft_am) && (
          <p className="text-[11px] text-amber-700 bg-amber-50 border border-amber-100 rounded-xl p-3
                        leading-relaxed">
            Die albanischen Vorlagen sind ein erster Entwurf und noch von niemandem
            gegengelesen. Sie gehen an Mitglieder hinaus — bitte lassen Sie sie von
            jemandem durchsehen, der die Sprache spricht, und vermerken Sie es hier.
          </p>
        )}
        <p className="text-[11px] text-stone-500 leading-relaxed">
          Diese Texte gehen an Mitglieder. Platzhalter werden beim Versand ersetzt:{' '}
          {PLATZHALTER.map(p => (
            <code key={p} className="font-mono text-[10px] bg-white border border-stone-200 rounded px-1 mr-1">{p}</code>
          ))}
        </p>

        <div className="space-y-2">
          {schluesselListe.map(k => {
            const b = bausteine.find(x => x.schluessel === k && x.sprache === sprache);
            const istOffen = offen === `${k}-${sprache}`;
            return (
              <div key={k} className="bg-white rounded-2xl border border-stone-100 overflow-hidden">
                <button onClick={() => setOffen(istOffen ? null : `${k}-${sprache}`)}
                  className="w-full flex items-center justify-between gap-3 p-4 text-left hover:bg-stone-50">
                  <span className="text-sm font-bold text-stone-800 flex items-center gap-2">
                    {NAMEN[k] || k}
                    {b && istGeprueft(b) && (
                      <span className="text-[9px] font-bold uppercase tracking-widest
                                       text-emerald-700 bg-emerald-50 border border-emerald-100
                                       rounded px-1.5 py-0.5">gegengelesen</span>
                    )}
                    {b && istUeberholt(b) && (
                      <span className="text-[9px] font-bold uppercase tracking-widest
                                       text-amber-700 bg-amber-50 border border-amber-100
                                       rounded px-1.5 py-0.5">seither geändert</span>
                    )}
                    {b && !b.geprueft_am && (
                      <span className="text-[9px] font-bold uppercase tracking-widest
                                       text-stone-400 bg-stone-50 border border-stone-200
                                       rounded px-1.5 py-0.5">ungeprüft</span>
                    )}
                  </span>
                  <span className="text-[10px] text-stone-400 uppercase tracking-widest">
                    {b ? (istOffen ? 'schliessen' : 'bearbeiten')
                       : <span className="text-amber-600">in dieser Sprache nicht hinterlegt</span>}
                  </span>
                </button>

                {istOffen && b && (
                  <div className="px-4 pb-4 space-y-3 border-t border-stone-100 pt-4">
                    <div>
                      <label className={`${marke} block mb-2`}>Betreff</label>
                      <input className={feld} value={b.betreff ?? ''}
                        onChange={e => setBausteine(bausteine.map(x =>
                          x.id === b.id ? { ...x, betreff: e.target.value } : x))} />
                    </div>
                    <div>
                      <label className={`${marke} block mb-2`}>Text</label>
                      <textarea className={`${feld} font-mono text-xs leading-relaxed`} rows={12}
                        value={b.text}
                        onChange={e => setBausteine(bausteine.map(x =>
                          x.id === b.id ? { ...x, text: e.target.value } : x))} />
                    </div>
                    <div className="flex items-center gap-3 flex-wrap">
                      <button onClick={() => bausteinSichern(b)} disabled={speichert === b.id}
                        className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2 rounded-xl
                                   text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
                        {speichert === b.id ? <Loader2 size={12} className="animate-spin" />
                          : gespeichert === b.id ? <Check size={12} /> : <Save size={12} />}
                        {gespeichert === b.id ? 'Gespeichert' : 'Speichern'}
                      </button>

                      <button onClick={() => gegenlesen(b, !istGeprueft(b))} disabled={speichert === b.id}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-[10px]
                                    font-bold uppercase tracking-widest border disabled:opacity-40 ${
                          istGeprueft(b) ? 'border-emerald-200 text-emerald-700 bg-emerald-50'
                                         : 'border-stone-200 text-stone-500 hover:text-stone-900'}`}>
                        <Eye size={12} />
                        {istGeprueft(b) ? 'Gegengelesen — zurücknehmen' : 'Als gegengelesen vermerken'}
                      </button>

                      {b.geprueft_am && (
                        <span className={`text-[10px] ${istUeberholt(b) ? 'text-amber-600' : 'text-stone-400'}`}>
                          {istUeberholt(b)
                            ? `${b.geprueft_von} hat eine frühere Fassung gelesen — bitte erneut prüfen`
                            : `${b.geprueft_von}, ${new Date(b.geprueft_am).toLocaleDateString('de-CH')}`}
                        </span>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* ------------------------------------------------------ Glossar */}
      <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
        <p className={`${marke} flex items-center gap-2`}><BookMarked size={13} /> Vereinsglossar</p>
        <p className="text-[11px] text-stone-500 leading-relaxed max-w-2xl">
          Wie Ihr Verein seine Begriffe nennt. Was hier steht, wird in Texten
          einheitlich verwendet — statt dass dieselbe Sache einmal „Nachbarschaft"
          und einmal „Quartier" heisst.
        </p>

        <div className="bg-white rounded-2xl border border-stone-100 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-stone-50 text-stone-400 font-bold uppercase text-[10px] tracking-widest border-b border-stone-100">
              <tr>
                <th className="px-4 py-3">Begriff</th>
                <th className="px-4 py-3">Deutsch</th>
                <th className="px-4 py-3">Shqip</th>
                <th className="px-4 py-3">English</th>
                <th className="px-4 py-3 w-28"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-50">
              {begriffe.map(g => (
                <tr key={g.begriff} className="hover:bg-stone-50/60">
                  <td className="px-4 py-2">
                    <span className="font-mono text-[11px] text-stone-500">{g.begriff}</span>
                    {g.hinweis && <p className="text-[10px] text-stone-400 mt-0.5">{g.hinweis}</p>}
                  </td>
                  {(['de', 'sq', 'en'] as const).map(sp => (
                    <td key={sp} className="px-4 py-2">
                      <input
                        className="w-full p-2 bg-transparent border border-transparent rounded-lg text-sm
                                   hover:border-stone-200 focus:border-stone-300 focus:bg-white outline-none"
                        value={g[sp] ?? ''}
                        onChange={e => setBegriffe(begriffe.map(x =>
                          x.begriff === g.begriff ? { ...x, [sp]: e.target.value } : x))} />
                    </td>
                  ))}
                  <td className="px-4 py-2 text-right">
                    <button onClick={() => begriffSichern(g)} disabled={speichert === g.begriff}
                      className="text-[10px] font-bold uppercase tracking-widest text-stone-400
                                 hover:text-stone-900 disabled:opacity-40 flex items-center gap-1.5 ml-auto">
                      {speichert === g.begriff ? <Loader2 size={11} className="animate-spin" />
                        : gespeichert === g.begriff ? <Check size={11} className="text-emerald-600" /> : <Save size={11} />}
                      {gespeichert === g.begriff ? 'ok' : 'Sichern'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminTexte;
