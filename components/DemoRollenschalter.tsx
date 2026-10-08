import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Eye, X, ChevronUp } from 'lucide-react';
import { DEMO_ROLLEN, type DemoRolle } from '../lib/useDemoRolle';

// Die Leiste, mit der sich in der Vorfuehrung die Rolle wechseln laesst.
//
// Sie sitzt unten und bleibt stehen -- wer vorfuehrt, hat eine Hand am
// Beamer und soll nicht erst ein Menue suchen. Sie nennt bei jeder Rolle
// in einem Satz, was diese Person sieht: das ist die Aussage, nicht der
// Rollenname.
//
// Und sie sagt offen, dass sie eine Ansicht umschaltet und keine Rechte.
// Eine Vorfuehrung, die so tut, als beweise sie die Zugriffskontrolle,
// waere unehrlich gegenueber dem Verein, der zusieht.

const DemoRollenschalter: React.FC<{
  rolle: DemoRolle | null;
  setRolle: (r: DemoRolle | null) => void;
}> = ({ rolle, setRolle }) => {
  const [offen, setOffen] = useState(true);
  const navigate = useNavigate();

  // Umschalten heisst auch hingehen: ohne den Sprung bliebe man auf der
  // Seite der vorigen Rolle und saehe eine leere Maske -- in einer
  // Vorfuehrung der denkbar schlechteste Moment dafuer.
  const waehle = (wert: DemoRolle, ziel: string) => { setRolle(wert); navigate(ziel); };

  if (!offen) return (
    <button
      onClick={() => setOffen(true)}
      className="fixed bottom-4 left-4 z-[9998] flex items-center gap-2 bg-stone-900 text-white
                 px-3 py-2 rounded-xl shadow-lg text-[10px] font-bold uppercase tracking-widest">
      <Eye size={13} /> Demo
    </button>
  );

  return (
    <div className="fixed bottom-4 left-4 right-4 z-[9998] flex justify-center pointer-events-none">
      <div className="pointer-events-auto bg-stone-900 text-white rounded-2xl shadow-2xl
                      px-4 py-3 max-w-3xl w-full">
        <div className="flex items-center justify-between gap-3 mb-2.5">
          <span className="flex items-center gap-2 text-[10px] font-bold uppercase tracking-widest text-stone-400">
            <Eye size={13} /> Ansicht als
          </span>
          <button onClick={() => setOffen(false)}
            className="text-stone-500 hover:text-white" aria-label="Leiste einklappen">
            <X size={15} />
          </button>
        </div>

        <div className="flex gap-1.5 flex-wrap">
          {DEMO_ROLLEN.map(r => (
            <button key={r.wert} onClick={() => waehle(r.wert, r.ziel)}
              title={r.was}
              className={`px-3 py-2 rounded-xl text-xs font-bold transition-colors ${
                rolle === r.wert
                  ? 'bg-white text-stone-900'
                  : 'bg-white/5 text-stone-300 hover:bg-white/10 hover:text-white'}`}>
              {r.name}
            </button>
          ))}
          {rolle && (
            <button onClick={() => { setRolle(null); navigate('/admin'); }}
              className="px-3 py-2 rounded-xl text-xs font-bold text-stone-400
                         hover:text-white flex items-center gap-1.5">
              <ChevronUp size={13} /> Zurück zum Betreiber
            </button>
          )}
        </div>

        <p className="text-[11px] text-stone-400 leading-relaxed mt-2.5">
          {rolle
            ? DEMO_ROLLEN.find(r => r.wert === rolle)?.was
            : 'Wähle eine Rolle, um zu zeigen, was diese Person in der Vereinsverwaltung sieht.'}
          {' '}
          <span className="text-stone-500">
            Schaltet die Ansicht um, nicht die Rechte — und nur im Demo-Verein.
          </span>
        </p>
      </div>
    </div>
  );
};

export default DemoRollenschalter;
