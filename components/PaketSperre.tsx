import React from 'react';
import { Lock, Sparkles } from 'lucide-react';
import { useModule } from '../lib/useModule';

// Was ein Verein nicht gebucht hat, steht in der Verwaltung ausgegraut da
// statt zu fehlen: so sieht man im Paket Light, was Voll dazu bringt.
//
// Das ist nur Anzeige. Die Daten eines nicht gebuchten Moduls gibt die
// Datenbank ohnehin nicht heraus (modul_aktiv in den Zeilenregeln) --
// diese Seite zeigt darum auch keine, sondern nur, was das Modul kann.

export const VollMarke: React.FC<{ klein?: boolean }> = ({ klein }) => (
  <span className={`inline-flex items-center gap-1 rounded-full bg-amber-100 text-amber-800 font-bold uppercase tracking-wide ${klein ? 'text-[8px] px-1.5 py-0.5' : 'text-[9px] px-2 py-0.5'}`}>
    <Lock size={klein ? 8 : 9} /> Voll
  </span>
);

const PaketSperre: React.FC<{ modul: string; titel?: string }> = ({ modul, titel }) => {
  const { modul: info } = useModule();
  const m = info(modul);
  return (
    <div className="max-w-2xl mx-auto mt-10 bg-white border border-stone-100 rounded-[2.5rem] p-10 text-center shadow-sm">
      <div className="w-14 h-14 mx-auto rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center mb-5"><Lock size={24} /></div>
      <p className="text-[10px] font-bold uppercase tracking-widest text-amber-700 mb-2">Im Paket Voll enthalten</p>
      <h3 className="text-2xl font-display font-bold italic text-stone-900">{m?.name || titel || modul}</h3>
      {m?.beschreibung && <p className="text-sm text-stone-500 mt-3 leading-relaxed">{m.beschreibung}</p>}
      <p className="text-xs text-stone-400 mt-6 flex items-center justify-center gap-1.5">
        <Sparkles size={13} /> Ihr Verein nutzt das Paket Light. Mit Voll ist diese Funktion sofort verfügbar.
      </p>
    </div>
  );
};

export default PaketSperre;
