import React, { useMemo, useState } from 'react';
import { Loader2, X } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import Familienbaum from './Familienbaum';
import StammbaumPerson from './StammbaumPerson';
import { useStammbaum, type Person } from '../lib/stammbaum';

// Stammbaum fuer Vertreter: nur lesen. Die Datenbank liefert ihnen ohnehin
// nur die Mitglieder, fuer die sie zustaendig sind, und deren Beziehungen
// (familien_uebersicht laeuft mit den Rechten des Aufrufers).

const VertreterFamilien: React.FC = () => {
  const { t } = useTranslation();
  const sb = useStammbaum();
  const [gewaehlt, setGewaehlt] = useState<string | null>(null);

  const familien = useMemo(() => {
    const m = new Map<string, Person[]>();
    for (const p of sb.leute) { if (!m.has(p.familie)) m.set(p.familie, []); m.get(p.familie)!.push(p); }
    return [...m.values()].filter(g => g.length > 1).sort((a, b) => b.length - a.length);
  }, [sb.leute]);

  if (sb.laedt) return <div className="p-6 text-stone-400"><Loader2 className="animate-spin" size={18} /></div>;
  if (!familien.length) return <p className="text-sm text-stone-400 italic p-6 text-center">{t('vfam.leer')}</p>;

  const person = gewaehlt ? sb.nachId.get(gewaehlt) : null;

  return (
    <div className="space-y-4">
      <p className="text-xs text-stone-500">{t('vfam.hinweis')}</p>
      {familien.map(g => {
        const ids = g.map(p => p.person);
        const name = g[0].familienname || [...new Set(g.map(p => p.nachname).filter(Boolean))].join(' / ') || t('stamm.ohne_namen');
        return (
          <div key={g[0].familie} className="bg-white border border-stone-200 rounded-2xl p-5">
            <p className="font-bold text-stone-800 mb-3">{name} <span className="text-stone-400 font-normal text-xs">· {g.length} {t('stamm.personen')}</span></p>
            <Familienbaum leute={sb.alsKnoten(ids)} onWaehlen={setGewaehlt} gewaehltId={gewaehlt} />
            {person && ids.includes(person.person) && (
              <div className="mt-4 p-4 bg-stone-50 rounded-2xl">
                <div className="flex items-center justify-between mb-3">
                  <p className="font-bold text-stone-800">{person.name}</p>
                  <button onClick={() => setGewaehlt(null)} className="text-stone-400"><X size={16} /></button>
                </div>
                <StammbaumPerson sb={sb} person={person.person} nurLesen onOeffnen={setGewaehlt} />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default VertreterFamilien;
