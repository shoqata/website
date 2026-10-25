import React, { useEffect, useState } from 'react';
import {
  Loader2, Plus, Save, Check, AlertTriangle, Eye, EyeOff, FileText,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import BausteinEditor, { type Baustein } from './BausteinEditor';
import { SeitenInhalt } from './EigeneSeite';

// Eigene Seiten bauen.
//
// Der Inhalt besteht aus Bausteinen, nicht aus HTML. Ein Textfeld, in das
// jemand HTML schreibt, waere schneller gebaut -- und was dort steht,
// liefe im Browser jedes Besuchers. Bausteine haben feste Arten, und wie
// sie aussehen, entscheidet die Anwendung.
//
// Dreisprachig von Anfang an: jeder Text ist {de, sq, en}. Ein Verein,
// der auf Deutsch anfaengt und spaeter Albanisch nachzieht, soll das
// koennen, ohne dass etwas umgebaut wird. Leere Sprachen fallen bei der
// Anzeige auf die gefuellte zurueck -- loc() macht das.

type Sprachfeld = { de?: string; sq?: string; en?: string };
type Seite = {
  id: string | null; pfad: string; titel: Sprachfeld; bloecke: Baustein[];
  status: 'ENTWURF' | 'OEFFENTLICH'; im_menue: boolean; reihenfolge: number;
  geaendert_am?: string; geaendert_von?: string;
};

const LEER: Seite = {
  id: null, pfad: '', titel: {}, bloecke: [],
  status: 'ENTWURF', im_menue: false, reihenfolge: 100,
};

const SPRACHEN = [['de', 'Deutsch'], ['sq', 'Shqip'], ['en', 'English']] as const;

const AdminSeiten: React.FC = () => {
  const { language } = useTranslation();
  const [seiten, setSeiten] = useState<Seite[] | null>(null);
  const [offen, setOffen] = useState<Seite | null>(null);
  const [sprache, setSprache] = useState<'de' | 'sq' | 'en'>(
    (['de', 'sq', 'en'].includes(language) ? language : 'de') as any);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);

  const laden = async () => {
    const { data, error } = await supabase.from('seiten')
      .select('id,pfad,titel,bloecke,status,im_menue,reihenfolge,geaendert_am,geaendert_von')
      .order('reihenfolge');
    if (error) { setFehler(error.message); setSeiten([]); return; }
    setSeiten((data as Seite[]) ?? []);
  };
  useEffect(() => { laden(); }, []);

  const sichern = async () => {
    if (!offen) return;
    setSpeichert(true); setFehler(null);
    const { data, error } = await supabase.rpc('seite_speichern', {
      p_id: offen.id, p_pfad: offen.pfad || offen.titel[sprache] || offen.titel.de || '',
      p_titel: offen.titel, p_bloecke: offen.bloecke,
      p_status: offen.status, p_im_menue: offen.im_menue, p_reihenfolge: offen.reihenfolge,
    });
    setSpeichert(false);
    if (error) { setFehler(error.message); return; }
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
    await laden();
    setOffen(o => (o ? { ...o, id: (data as string) ?? o.id } : o));
  };

  const loeschen = async (s: Seite) => {
    if (!s.id) { setOffen(null); return; }
    const { error } = await supabase.rpc('seite_loeschen', { p_id: s.id });
    if (error) { setFehler(error.message); return; }
    setOffen(null); await laden();
  };

  if (seiten === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-300';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  // ------------------------------------------------------------ Liste
  if (!offen) return (
    <div className="space-y-5">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div className="max-w-xl">
          <p className={marke}>Eigene Seiten</p>
          <p className="text-[11px] text-stone-500 leading-relaxed mt-2">
            Seiten, die es nur bei Ihnen gibt — „Unsere Geschichte", „Statuten",
            „Anfahrt". Sie erscheinen unter Ihrer Adresse und, wenn Sie wollen,
            im Menü. Ein Entwurf ist für Besucher unsichtbar.
          </p>
        </div>
        <button onClick={() => setOffen({ ...LEER })}
          className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2.5 rounded-xl
                     text-[10px] font-bold uppercase tracking-widest shrink-0">
          <Plus size={13} /> Neue Seite
        </button>
      </div>

      {seiten.length === 0 ? (
        <div className="bg-stone-50 rounded-3xl border border-dashed border-stone-200 p-12 text-center">
          <FileText size={34} className="mx-auto text-stone-200 mb-4" />
          <p className="text-sm text-stone-400">Noch keine eigene Seite.</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-stone-100 divide-y divide-stone-50">
          {seiten.map(s => (
            <button key={s.id} onClick={() => setOffen({ ...s, bloecke: s.bloecke ?? [] })}
              className="w-full text-left px-5 py-4 hover:bg-stone-50 flex items-center gap-4">
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-stone-800 truncate">
                  {s.titel?.[sprache] || s.titel?.de || s.titel?.sq || s.pfad}
                </p>
                <p className="text-[11px] text-stone-400 font-mono mt-0.5">/{s.pfad}</p>
              </div>
              {s.im_menue && (
                <span className="text-[9px] font-bold uppercase tracking-widest text-stone-400
                                 bg-stone-50 border border-stone-200 rounded px-1.5 py-0.5 shrink-0">
                  im Menü
                </span>
              )}
              <span className={`text-[9px] font-bold uppercase tracking-widest rounded px-1.5 py-0.5 shrink-0 ${
                s.status === 'OEFFENTLICH'
                  ? 'text-emerald-700 bg-emerald-50 border border-emerald-100'
                  : 'text-stone-400 bg-stone-50 border border-stone-200'}`}>
                {s.status === 'OEFFENTLICH' ? 'öffentlich' : 'Entwurf'}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  );

  // ----------------------------------------------------------- Editor
  return (
    <div className="space-y-5">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div className="flex items-center justify-between gap-3 flex-wrap">
        <button onClick={() => { setOffen(null); setFehler(null); }}
          className="text-[10px] font-bold uppercase tracking-widest text-stone-400 hover:text-stone-900">
          ← Alle Seiten
        </button>
        <div className="flex gap-1 bg-white p-1 rounded-xl border border-stone-200">
          {SPRACHEN.map(([w, n]) => (
            <button key={w} onClick={() => setSprache(w as any)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                sprache === w ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
              {n}
            </button>
          ))}
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* ------------------------------------------------ Bearbeiten */}
        <div className="space-y-5">
          <div className="bg-stone-50 rounded-3xl border border-stone-100 p-6 space-y-4">
            <div>
              <label className={`${marke} block mb-2`}>Titel ({sprache})</label>
              <input className={feld} value={offen.titel[sprache] ?? ''}
                onChange={e => setOffen({ ...offen, titel: { ...offen.titel, [sprache]: e.target.value } })}
                placeholder="Unsere Geschichte" />
            </div>
            <div>
              <label className={`${marke} block mb-2`}>Adresse</label>
              <div className="flex items-center gap-2">
                <span className="text-sm text-stone-400 font-mono">/</span>
                <input className={feld} value={offen.pfad}
                  onChange={e => setOffen({ ...offen, pfad: e.target.value })}
                  placeholder="unsere-geschichte" />
              </div>
              <p className="text-[10px] text-stone-400 mt-2">
                Leer gelassen wird sie aus dem Titel gebildet. Umlaute und Leerzeichen
                werden ersetzt.
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" checked={offen.im_menue}
                  onChange={e => setOffen({ ...offen, im_menue: e.target.checked })}
                  className="w-4 h-4 accent-stone-900" />
                <span className="text-xs text-stone-700">Im Menü zeigen</span>
              </label>
              <div className="flex gap-1 bg-white p-1 rounded-xl border border-stone-200">
                {([['ENTWURF', 'Entwurf'], ['OEFFENTLICH', 'Öffentlich']] as const).map(([w, n]) => (
                  <button key={w} onClick={() => setOffen({ ...offen, status: w })}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 ${
                      offen.status === w ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                    {w === 'ENTWURF' ? <EyeOff size={12} /> : <Eye size={12} />} {n}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <BausteinEditor bloecke={offen.bloecke} sprache={sprache}
            onChange={bloecke => setOffen({ ...offen, bloecke })} />

          <div className="flex items-center gap-3 flex-wrap">
            <button onClick={sichern} disabled={speichert}
              className="flex items-center gap-2 bg-stone-900 text-white px-5 py-2.5 rounded-xl
                         text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
              {speichert ? <Loader2 size={12} className="animate-spin" />
                : gespeichert ? <Check size={12} /> : <Save size={12} />}
              {gespeichert ? 'Gespeichert' : 'Speichern'}
            </button>
            {offen.id && (
              <button onClick={() => loeschen(offen)}
                className="text-[10px] font-bold uppercase tracking-widest text-stone-400 hover:text-red-600">
                Seite löschen
              </button>
            )}
            {offen.geaendert_von && (
              <span className="text-[10px] text-stone-400">
                zuletzt {offen.geaendert_von}
                {offen.geaendert_am && `, ${new Date(offen.geaendert_am).toLocaleDateString('de-CH')}`}
              </span>
            )}
          </div>
        </div>

        {/* -------------------------------------------------- Vorschau */}
        <div className="lg:sticky lg:top-6 self-start">
          <p className={`${marke} mb-3`}>So sieht es aus</p>
          <div className="bg-white rounded-3xl border border-stone-200 p-8 max-h-[70dvh] overflow-y-auto">
            <h1 className="text-3xl font-display font-bold italic text-stone-900 mb-8">
              {offen.titel[sprache] || offen.titel.de || 'Ohne Titel'}
            </h1>
            {offen.bloecke.length === 0 ? (
              <p className="text-sm text-stone-300 italic">Noch kein Inhalt.</p>
            ) : (
              <SeitenInhalt bloecke={offen.bloecke as any} />
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminSeiten;
