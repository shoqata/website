import React, { useEffect, useState } from 'react';
import { X, Loader2, Save, Upload, Trash2, ArrowLeft, ArrowRight, Eye, EyeOff, ExternalLink, MapPin } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';
import { bildHochladen } from '../lib/bildHochladen';
import { GebietZeichnen, type Flaeche } from './NachbarschaftKarte';
import type { NbBild, Punkt } from '../lib/nachbarschaften';

// Die Vorstellung einer Nachbarschaft bearbeiten: Text, Bilder, Gebiet.
// Fuer Verwaltung und Vorstand (alle Nachbarschaften) und fuer Vertreter
// (die eigene). Wer was darf, prueft nachbarschaft_profil_speichern().

type Sprache = 'de' | 'sq' | 'en';
const SPRACHEN: [Sprache, string][] = [['de', 'Deutsch'], ['sq', 'Shqip'], ['en', 'English']];

const NachbarschaftProfilEditor: React.FC<{ nb: { id: string; name: string }; onClose: () => void; onGespeichert?: () => void }> =
  ({ nb, onClose, onGespeichert }) => {
  const { showAlert } = useFeedback();
  const [geladen, setGeladen] = useState(false);
  const [sichtbar, setSichtbar] = useState(false);
  const [text, setText] = useState<Record<string, string>>({});
  const [bilder, setBilder] = useState<NbBild[]>([]);
  const [gebiet, setGebiet] = useState<Punkt[]>([]);
  const [ort, setOrt] = useState('');
  const [andere, setAndere] = useState<Flaeche[]>([]);
  const [sprache, setSprache] = useState<Sprache>('de');
  const [laedt, setLaedt] = useState(false);
  const [speichert, setSpeichert] = useState(false);

  useEffect(() => {
    (async () => {
      const { data } = await supabase.from('nachbarschaft_profil')
        .select('sichtbar,text,bilder,gebiet,ort').eq('nachbarschaft', nb.id).maybeSingle();
      if (data) {
        setSichtbar(!!data.sichtbar); setText(data.text || {}); setBilder(data.bilder || []);
        setGebiet(data.gebiet || []); setOrt(data.ort || '');
      }
      // Die Gebiete der anderen Nachbarschaften als Hilfe beim Zeichnen.
      const { data: alle } = await supabase.from('nachbarschaft_profil').select('nachbarschaft,gebiet').neq('nachbarschaft', nb.id);
      const { data: namen } = await supabase.from('neighborhoods').select('id,name');
      const n = new Map(((namen as any[]) ?? []).map(x => [x.id, x.name]));
      setAndere(((alle as any[]) ?? []).map(a => ({ id: a.nachbarschaft, name: n.get(a.nachbarschaft) || '', gebiet: a.gebiet || [] })));
      setGeladen(true);
    })();
  }, [nb.id]);

  const sichern = async () => {
    setSpeichert(true);
    const { error } = await supabase.rpc('nachbarschaft_profil_speichern', {
      p_nachbarschaft: nb.id, p_text: text, p_bilder: bilder, p_gebiet: gebiet, p_ort: ort, p_sichtbar: sichtbar,
    });
    setSpeichert(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    showAlert({ type: 'success', message: sichtbar ? 'Gespeichert — die Nachbarschaft ist auf der Website zu sehen.' : 'Gespeichert. Noch nicht auf der Website (ausgeblendet).' });
    onGespeichert?.();
  };

  const schieben = (i: number, um: number) => {
    const z = i + um; if (z < 0 || z >= bilder.length) return;
    const n = [...bilder]; [n[i], n[z]] = [n[z], n[i]]; setBilder(n);
  };
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2';

  return (
    <div className="fixed inset-0 z-[300] flex items-center justify-center p-3 md:p-6 bg-stone-900/60 backdrop-blur-sm">
      <div className="bg-white w-full max-w-3xl rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[94vh]">
        <div className="p-5 border-b border-stone-100 flex justify-between items-center bg-stone-50 gap-3">
          <div>
            <h3 className="font-bold text-lg text-stone-900">{nb.name}</h3>
            <p className="text-[11px] text-stone-500">Vorstellung auf der Website (Seite „Dorf“ und eigene Seite)</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={20} /></button>
        </div>

        {!geladen ? (
          <div className="p-16 flex justify-center"><Loader2 className="animate-spin text-stone-300" /></div>
        ) : (
          <div className="p-5 md:p-7 space-y-6 overflow-y-auto">
            <button type="button" onClick={() => setSichtbar(!sichtbar)}
              className={`w-full flex items-center justify-between gap-3 p-4 rounded-2xl border text-left ${sichtbar ? 'bg-emerald-50 border-emerald-200' : 'bg-stone-50 border-stone-200'}`}>
              <span>
                <span className="block font-bold text-sm text-stone-900">{sichtbar ? 'Auf der Website gezeigt' : 'Ausgeblendet'}</span>
                <span className="block text-[11px] text-stone-500 mt-0.5">
                  {sichtbar ? 'Erscheint auf der Seite „Dorf“ und hat eine eigene Seite.' : 'Erst einschalten, wenn Text und Bilder stimmen.'}
                </span>
              </span>
              {sichtbar ? <Eye size={20} className="text-emerald-600" /> : <EyeOff size={20} className="text-stone-400" />}
            </button>

            <div>
              <div className="flex items-center justify-between mb-2">
                <label className={marke + ' mb-0'}>Vorstellung</label>
                <div className="flex gap-1 bg-stone-100 p-1 rounded-lg">
                  {SPRACHEN.map(([w, n]) => (
                    <button key={w} onClick={() => setSprache(w)}
                      className={`px-2.5 py-1 rounded-md text-[11px] font-bold ${sprache === w ? 'bg-white text-stone-900' : 'text-stone-400'}`}>{n}</button>
                  ))}
                </div>
              </div>
              <textarea rows={7} value={text[sprache] || ''} onChange={e => setText({ ...text, [sprache]: e.target.value })}
                placeholder="Wer wohnt hier, was macht die Nachbarschaft aus, was ist hier entstanden?"
                className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm leading-relaxed outline-none" />
              <p className="text-[10px] text-stone-400 mt-1">Eine Leerzeile beginnt einen neuen Absatz. Fehlt eine Sprache, erscheint die vorhandene.</p>
            </div>

            <div>
              <label className={marke}>Lage</label>
              <div className="flex items-center gap-2">
                <MapPin size={15} className="text-stone-400" />
                <input value={ort} onChange={e => setOrt(e.target.value)} placeholder="z. B. Oberdorf, beim Brunnen"
                  className="flex-1 p-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none" />
              </div>
            </div>

            <div>
              <label className={marke}>Bilder ({bilder.length}/24)</label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {bilder.map((b, i) => (
                  <div key={b.url + i} className="relative group rounded-xl overflow-hidden border border-stone-200 bg-stone-50">
                    <img src={b.url} alt="" className="w-full aspect-[4/3] object-cover" />
                    {i === 0 && <span className="absolute top-2 left-2 text-[9px] font-bold uppercase tracking-widest bg-white/90 px-1.5 py-0.5 rounded">Titelbild</span>}
                    <div className="absolute top-2 right-2 flex gap-1">
                      <button onClick={() => schieben(i, -1)} disabled={i === 0} className="w-7 h-7 bg-white/90 rounded-lg flex items-center justify-center disabled:opacity-30"><ArrowLeft size={13} /></button>
                      <button onClick={() => schieben(i, 1)} disabled={i === bilder.length - 1} className="w-7 h-7 bg-white/90 rounded-lg flex items-center justify-center disabled:opacity-30"><ArrowRight size={13} /></button>
                      <button onClick={() => setBilder(bilder.filter((_, n) => n !== i))} className="w-7 h-7 bg-white/90 rounded-lg flex items-center justify-center text-red-600"><Trash2 size={13} /></button>
                    </div>
                    <input value={b.text?.[sprache] || ''} placeholder={`Bildtext (${sprache})`}
                      onChange={e => setBilder(bilder.map((x, n) => n === i ? { ...x, text: { ...x.text, [sprache]: e.target.value } } : x))}
                      className="w-full p-2 text-[11px] bg-white border-t border-stone-200 outline-none" />
                  </div>
                ))}
                {bilder.length < 24 && (
                  <label className={`aspect-[4/3] border-2 border-dashed border-stone-200 rounded-xl flex flex-col items-center justify-center gap-1 text-stone-400 text-xs font-bold cursor-pointer hover:border-stone-300 ${laedt ? 'opacity-50 pointer-events-none' : ''}`}>
                    {laedt ? <Loader2 size={18} className="animate-spin" /> : <Upload size={18} />} Bilder hochladen
                    <input type="file" accept="image/*" multiple hidden onChange={async e => {
                      const dateien = [...(e.target.files || [])].slice(0, 24 - bilder.length); e.target.value = '';
                      if (!dateien.length) return;
                      setLaedt(true);
                      try {
                        const neu: NbBild[] = [];
                        for (const d of dateien) neu.push({ url: await bildHochladen(d, `nachbarschaften/${nb.id}`) });
                        setBilder(b => [...b, ...neu]);
                      } catch (err: any) { showAlert({ type: 'error', message: err?.message || 'Hochladen fehlgeschlagen.' }); }
                      finally { setLaedt(false); }
                    }} />
                  </label>
                )}
              </div>
            </div>

            <div>
              <label className={marke}>Gebiet auf der Karte</label>
              <GebietZeichnen gebiet={gebiet} onChange={setGebiet} andere={andere} />
            </div>
          </div>
        )}

        <div className="p-5 border-t border-stone-100 bg-stone-50 flex gap-3 items-center">
          {sichtbar && (
            <a href={`/#/nachbarschaften/${encodeURIComponent(nb.id)}`} target="_blank" rel="noopener noreferrer"
               className="text-xs font-bold text-stone-500 hover:text-stone-900 flex items-center gap-1.5 mr-auto">
              <ExternalLink size={13} /> Ansehen
            </a>
          )}
          <button onClick={onClose} className="px-5 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold text-sm ml-auto">Schliessen</button>
          <button onClick={sichern} disabled={speichert || laedt || !geladen}
            className="px-6 py-3 bg-stone-900 text-white rounded-xl font-bold text-sm flex items-center gap-2 disabled:opacity-50">
            {speichert ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />} Speichern
          </button>
        </div>
      </div>
    </div>
  );
};

export default NachbarschaftProfilEditor;
