import React, { useEffect, useMemo, useState } from 'react';
import { Users2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useModule } from '../lib/useModule';
import Familienbaum, { type Knoten } from './Familienbaum';
import { netzAus, verwandteVon, type Kante } from '../lib/verwandtschaft';
import { weiblich, familienTitel } from '../lib/stammbaum';

// "Meine Familie" im Mitgliederbereich: nur lesen, nur die eigene Familie,
// nur Name und Geburtsjahr (meine_familie()). Aenderungen meldet das
// Mitglied ueber "Änderung melden"; eintragen tut der Vorstand.

type Zeile = {
  person: string; name: string; nachname: string | null; geburtsjahr: string | null; anrede: string | null;
  familienname: string | null; ich: boolean;
  eltern: { id: string; name: string }[]; partner: { id: string; name: string }[];
  kinder: { id: string; name: string }[]; geschwister: { id: string; name: string }[];
};

const MeineFamilie: React.FC<{ onMelden?: () => void }> = ({ onMelden }) => {
  const { t } = useTranslation();
  const { aktiv } = useModule();
  const [zeilen, setZeilen] = useState<Zeile[] | null>(null);

  useEffect(() => {
    if (!aktiv('STAMMBAUM')) return;
    supabase.rpc('meine_familie').then(({ data }) => setZeilen((data ?? []) as Zeile[]));
  }, [aktiv('STAMMBAUM')]);

  const ich = zeilen?.find(z => z.ich);
  const knoten: Knoten[] = useMemo(() => (zeilen ?? []).map(z => ({
    person: z.person, name: z.name, geburtsdatum: z.geburtsjahr, anrede: z.anrede,
    eltern: z.eltern, partner: z.partner, kinder: z.kinder, geschwister: z.geschwister,
  })), [zeilen]);
  const verwandte = useMemo(() => {
    if (!zeilen || !ich) return [];
    const kanten: Kante[] = [];
    const gesehen = new Set<string>();
    for (const z of zeilen) {
      for (const e of z.eltern) kanten.push({ von: e.id, nach: z.person, art: 'ELTERNTEIL' });
      for (const [art, l] of [['PARTNER', z.partner], ['GESCHWISTER', z.geschwister]] as const)
        for (const q of l) {
          const k = art + [z.person, q.id].sort().join('|');
          if (!gesehen.has(k)) { gesehen.add(k); kanten.push({ von: z.person, nach: q.id, art }); }
        }
    }
    const namen = new Map(zeilen.map(z => [z.person, z.name]));
    const anr = new Map(zeilen.map(z => [z.person, z.anrede]));
    return verwandteVon(netzAus(kanten), ich.person, zeilen.map(z => z.person), namen, id => weiblich(anr.get(id)));
  }, [zeilen, ich]);

  if (!aktiv('STAMMBAUM') || zeilen === null) return null;

  return (
    <div className="bg-white rounded-3xl border border-stone-100 shadow-sm p-6 md:p-8">
      <div className="flex items-start justify-between gap-4 mb-5 flex-wrap">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-stone-100 text-stone-500 flex items-center justify-center"><Users2 size={18} /></div>
          <div>
            <h3 className="font-bold text-stone-900">
              {ich?.familienname ? familienTitel(ich.familienname, t('stamm.familie')) : t('meinefam.titel')}
            </h3>
            <p className="text-xs text-stone-400">
              {zeilen.length > 1 ? `${zeilen.length} ${t('stamm.personen')}` : t('meinefam.leer')}
            </p>
          </div>
        </div>
        {onMelden && (
          <button onClick={onMelden} className="text-[10px] font-bold uppercase tracking-widest" style={{ color: 'var(--primary)' }}>
            {t('meinefam.melden')}
          </button>
        )}
      </div>
      {zeilen.length > 1 && (
        <>
          <div className="bg-stone-50 rounded-2xl p-3">
            <Familienbaum leute={knoten} fokusId={ich?.person} einpassen />
          </div>
          {verwandte.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4">
              {verwandte.map(v => (
                <span key={v.id + v.bezeichnung} className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs bg-stone-100 text-stone-600">
                  <span className="font-bold">{zeilen.find(z => z.person === v.id)?.name}</span>
                  <span className="opacity-70">{v.bezeichnung}</span>
                </span>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default MeineFamilie;
