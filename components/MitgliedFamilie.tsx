import React, { useState } from 'react';
import { Loader2, Pencil, Users2, ArrowRight, X } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import Familienbaum, { generationen } from './Familienbaum';
import StammbaumPerson from './StammbaumPerson';
import { useStammbaum, familienTitel } from '../lib/stammbaum';

// Reiter "Familie" beim Mitglied: wo es im Stammbaum steht, als Bild, und
// Verwandte direkt hier hinzufuegen oder loesen -- ohne den Umweg ueber die
// Stammbaum-Seite.

const MitgliedFamilie: React.FC<{
  mitglied: string;
  onOeffnen?: (id: string) => void;      // anderes Mitglied im Profil zeigen
  onZumStammbaum?: () => void;
  nurLesen?: boolean;
}> = ({ mitglied, onOeffnen, onZumStammbaum, nurLesen }) => {
  const { t } = useTranslation();
  const sb = useStammbaum();
  const [name, setName] = useState<string | null>(null);

  if (sb.laedt) return (
    <div className="flex items-center gap-3 text-stone-400 p-6">
      <Loader2 className="animate-spin" size={16} /> <span className="text-sm">{t('stamm.laedt')}</span>
    </div>
  );

  const ich = sb.nachId.get(mitglied);
  if (!ich) return <p className="text-sm text-stone-400 p-6">{sb.fehler || t('stamm.nicht_gefunden')}</p>;

  const familie = sb.familieVon(mitglied);
  const ids = familie.length > 1 ? familie.map(f => f.person) : [];
  const knoten = sb.alsKnoten(ids);
  const kopf = [...new Set(familie.map(m => m.nachname).filter(Boolean))].join(' / ');
  const anker = familie.find(f => f.familie_id)?.person ?? mitglied;

  const speichern = async () => {
    if (name === null || !name.trim()) return;
    if (await sb.benennen(anker, name, ich.familie_id)) setName(null);
  };

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-3xl border border-stone-100 shadow-sm p-6">
        <div className="flex items-start justify-between gap-4 mb-4 flex-wrap">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-stone-100 text-stone-500 flex items-center justify-center shrink-0"><Users2 size={18} /></div>
            <div className="min-w-0">
              {name !== null && !nurLesen ? (
                <div className="flex items-center gap-2">
                  <input autoFocus value={name} onChange={e => setName(e.target.value)}
                         onKeyDown={e => { if (e.key === 'Enter') speichern(); if (e.key === 'Escape') setName(null); }}
                         placeholder={t('stamm.name_platzhalter')}
                         className="px-3 py-1.5 bg-stone-50 border border-stone-200 rounded-lg text-sm font-bold outline-none" />
                  <button onClick={speichern} className="text-[10px] font-bold uppercase tracking-widest" style={{ color: 'var(--primary)' }}>{t('common.save')}</button>
                  <button onClick={() => setName(null)} className="text-stone-300"><X size={14} /></button>
                </div>
              ) : ids.length ? (
                <button onClick={() => !nurLesen && setName(ich.familienname ?? kopf)} className="text-left group">
                  <p className="font-bold text-stone-800 group-hover:opacity-60">
                    {ich.familienname ? familienTitel(ich.familienname, t('stamm.familie')) : (kopf || t('stamm.ohne_namen'))}
                    {!nurLesen && <Pencil size={12} className="inline ml-2 mb-0.5 text-stone-300" />}
                  </p>
                </button>
              ) : <p className="font-bold text-stone-800">{t('stamm.keine_familie')}</p>}
              <p className="text-[11px] text-stone-400">
                {ids.length
                  ? `${ids.length} ${t('stamm.personen')} · ${new Set(generationen(knoten).values()).size} ${t('stamm.generationen')}`
                  : t('stamm.keine_familie_hinweis')}
              </p>
            </div>
          </div>
          {onZumStammbaum && ids.length > 0 && (
            <button onClick={onZumStammbaum}
                    className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest" style={{ color: 'var(--primary)' }}>
              {t('stamm.im_stammbaum')} <ArrowRight size={12} />
            </button>
          )}
        </div>
        {knoten.length > 0 && (
          <div className="bg-stone-50 rounded-2xl p-3 -mx-1">
            <Familienbaum leute={knoten} fokusId={mitglied}
                          onWaehlen={onOeffnen ? (id) => id && id !== mitglied && onOeffnen(id) : undefined} />
          </div>
        )}
      </div>

      <div className="bg-white rounded-3xl border border-stone-100 shadow-sm p-6">
        <StammbaumPerson sb={sb} person={mitglied} onOeffnen={onOeffnen} nurLesen={nurLesen} />
      </div>
    </div>
  );
};

export default MitgliedFamilie;
