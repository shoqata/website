import React from 'react';
import { Plus, Trash2, UserPlus } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import type { Gast } from '../lib/protokollGaeste';

// Eingabe der Gaeste: Vorname, Name, E-Mail.
const ProtokollGaeste: React.FC<{ value: Gast[]; onChange: (g: Gast[]) => void; feld?: string }> = ({ value, onChange, feld }) => {
  const { t } = useTranslation();
  const f = feld || 'w-full p-2.5 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-stone-400';
  const setze = (i: number, k: keyof Gast, v: string) => onChange(value.map((x, j) => j === i ? { ...x, [k]: v } : x));
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-1"><UserPlus size={11} /> {t('minutes.guests')}</span>
        <button type="button" onClick={() => onChange([...value, { vorname: '', nachname: '', email: '' }])}
          className="text-xs font-bold text-primary flex items-center gap-1 hover:opacity-70"><Plus size={13} /> {t('minutes.add_guest')}</button>
      </div>
      {value.length === 0 && <p className="text-xs text-stone-400 italic">{t('minutes.no_guests')}</p>}
      {value.map((g, i) => (
        <div key={i} className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_1.4fr_auto] gap-2">
          <input value={g.vorname} placeholder={t('field.firstName')} className={f} onChange={e => setze(i, 'vorname', e.target.value)} />
          <input value={g.nachname} placeholder={t('field.lastName')} className={f} onChange={e => setze(i, 'nachname', e.target.value)} />
          <input value={g.email} type="email" placeholder={t('field.email')} className={f} onChange={e => setze(i, 'email', e.target.value)} />
          <button type="button" onClick={() => onChange(value.filter((_, j) => j !== i))}
            className="p-2 text-stone-400 hover:text-red-600 justify-self-end"><Trash2 size={15} /></button>
        </div>
      ))}
      {value.length > 0 && <p className="text-[11px] text-stone-400">{t('minutes.guest_hint')}</p>}
    </div>
  );
};

export default ProtokollGaeste;
