import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { X, Loader2, Printer, ShoppingCart, AlertTriangle, CheckCircle2 } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Vor dem Aufgeben: reicht das Briefguthaben?
//
// Bisher erfuhr man es erst hinterher -- der Brief blieb mit "Kontingent
// aufgebraucht" liegen, und gekauft wurde in einem anderen Reiter. Hier
// steht vor dem Klick: wie viele Briefe es werden, was frei ist (Guthaben
// minus was schon wartet), was danach bleibt -- und wenn es nicht reicht,
// der Kauf gleich daneben.
//
// Gerechnet und gebucht wird in der Datenbank (post_guthaben_vor_versand,
// post_kontingent_kaufen). Kaufen darf nur die Administration; dem
// Vorstand sagt die Maske, wen er fragen muss.

type Guthaben = {
  stand: number; wartet: number; frei: number; modul_aktiv: boolean;
  preis_je_brief: number | null; waehrung: string; kaufbar: boolean; darf_kaufen: boolean;
};

const geld = (n: number, w: string) =>
  `${w} ${Number(n || 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const PostGuthabenDialog: React.FC<{
  anzahl: number; onAbbrechen: () => void; onAufgeben: () => void;
}> = ({ anzahl, onAbbrechen, onAufgeben }) => {
  const [g, setG] = useState<Guthaben | null>(null);
  const [fehler, setFehler] = useState('');
  const [menge, setMenge] = useState(0);
  const [kauft, setKauft] = useState(false);
  const [gekauft, setGekauft] = useState<string>('');

  const laden = async () => {
    const { data, error } = await supabase.rpc('post_guthaben_vor_versand');
    if (error) { setFehler(error.message); return; }
    const d = data as Guthaben;
    setG(d);
    // Vorschlag: was fehlt, auf zehn aufgerundet.
    const fehlt = Math.max(anzahl - d.frei, 0);
    setMenge(fehlt > 0 ? Math.ceil(fehlt / 10) * 10 : 0);
  };
  useEffect(() => { laden(); }, []);

  const kaufen = async () => {
    if (!menge) return;
    setKauft(true); setFehler('');
    const { data, error } = await supabase.rpc('post_kontingent_kaufen', { p_menge: menge });
    setKauft(false);
    if (error) { setFehler(error.message); return; }
    const d = data as any;
    setGekauft(`${d.gekauft} Briefe gekauft (${geld(d.betrag, d.waehrung)}, Rechnung ${d.rechnungsnummer}).`);
    laden();
  };

  const reicht = !!g && g.frei >= anzahl;
  const fehlt = g ? Math.max(anzahl - g.frei, 0) : 0;

  return (
    <div className="fixed inset-0 z-[200] flex items-end sm:items-center justify-center sm:p-6 bg-stone-900/60 backdrop-blur-sm" onClick={onAbbrechen}>
      <motion.div initial={{ y: 24, opacity: 0 }} animate={{ y: 0, opacity: 1 }} onClick={e => e.stopPropagation()}
        className="bg-white w-full sm:max-w-lg rounded-t-[2rem] sm:rounded-[2rem] shadow-2xl p-6 md:p-8 space-y-5">
        <div className="flex items-start justify-between gap-3">
          <h3 className="text-xl font-bold text-stone-900 flex items-center gap-2"><Printer size={20} className="text-amber-600" /> {anzahl === 1 ? 'Brief aufgeben' : `${anzahl} Briefe aufgeben`}</h3>
          <button onClick={onAbbrechen} className="p-2 rounded-full bg-stone-50 hover:bg-stone-100 text-stone-500"><X size={18} /></button>
        </div>

        {!g && !fehler && <div className="flex justify-center py-6"><Loader2 className="animate-spin text-stone-300" /></div>}

        {g && (
          <>
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="bg-stone-50 rounded-2xl p-3">
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">Guthaben</p>
                <p className="text-2xl font-bold text-stone-900">{g.frei}</p>
                {g.wartet > 0 && <p className="text-[10px] text-stone-400">{g.stand} − {g.wartet} wartend</p>}
              </div>
              <div className="bg-stone-50 rounded-2xl p-3">
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">Jetzt</p>
                <p className="text-2xl font-bold text-stone-900">−{anzahl}</p>
              </div>
              <div className={`rounded-2xl p-3 ${reicht ? 'bg-emerald-50' : 'bg-rose-50'}`}>
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">Danach</p>
                <p className={`text-2xl font-bold ${reicht ? 'text-emerald-700' : 'text-rose-700'}`}>{g.frei - anzahl}</p>
              </div>
            </div>
            {g.preis_je_brief != null && (
              <p className="text-xs text-stone-500 text-center">Preis je Brief: {geld(g.preis_je_brief, g.waehrung)}</p>
            )}

            {!reicht && (
              <div className="p-4 rounded-2xl bg-amber-50 border border-amber-100 space-y-3">
                <p className="text-sm text-amber-900 flex items-start gap-2">
                  <AlertTriangle size={16} className="shrink-0 mt-0.5" />
                  Es fehlen {fehlt} Briefe. Ohne Guthaben bleiben sie liegen und gehen erst nach einem Kauf hinaus.
                </p>
                {g.darf_kaufen && g.kaufbar ? (
                  <div className="flex items-center gap-2">
                    <input type="number" min={1} max={10000} value={menge || ''} onChange={e => setMenge(Math.max(0, parseInt(e.target.value) || 0))}
                      className="w-24 p-2.5 rounded-xl border border-amber-200 text-sm bg-white" />
                    <span className="text-xs text-stone-600 flex-1">Briefe = {geld((g.preis_je_brief || 0) * menge, g.waehrung)}</span>
                    <button onClick={kaufen} disabled={kauft || menge < 1}
                      className="px-4 py-2.5 rounded-xl bg-stone-900 text-white text-xs font-bold flex items-center gap-1.5 disabled:opacity-40">
                      {kauft ? <Loader2 size={14} className="animate-spin" /> : <ShoppingCart size={14} />} Kaufen
                    </button>
                  </div>
                ) : (
                  <p className="text-xs text-amber-800">
                    {!g.kaufbar ? 'Für diesen Verein ist noch kein Briefpreis festgelegt — das macht der Plattformbetreiber.'
                      : 'Guthaben kauft die Vereinsadministration.'}
                  </p>
                )}
              </div>
            )}
          </>
        )}

        {gekauft && <p className="text-sm text-emerald-800 flex items-center gap-2"><CheckCircle2 size={16} /> {gekauft}</p>}
        {fehler && <p className="text-sm text-rose-700">{fehler}</p>}

        <div className="flex gap-2 justify-end pt-1">
          <button onClick={onAbbrechen} className="px-5 py-3 rounded-xl text-sm font-bold text-stone-500 hover:bg-stone-100">Abbrechen</button>
          <button onClick={onAufgeben} disabled={!g}
            className={`px-6 py-3 rounded-xl text-sm font-bold flex items-center gap-2 disabled:opacity-40 ${reicht ? 'bg-primary text-white' : 'bg-stone-200 text-stone-700'}`}>
            <Printer size={16} /> {reicht ? 'Jetzt aufgeben' : 'Trotzdem einreihen'}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

export default PostGuthabenDialog;
