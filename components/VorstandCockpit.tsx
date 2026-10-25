import React, { useEffect, useState } from 'react';
import { Inbox, Gavel, CalendarDays, Newspaper, AlertTriangle, CheckCircle2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { isOverdue } from '../lib/memberQuality';

// Cockpit fuer den Vorstand: was heute Aufmerksamkeit braucht, auf einen
// Blick. Jede Kachel zaehlt nur; gearbeitet wird in den Bereichen darunter.

type Kachel = { k: string; icon: React.ReactNode; zahl: number | string; text: string; dringend?: boolean; unter?: string };

const VorstandCockpit: React.FC = () => {
  const { t } = useTranslation();
  const [kacheln, setKacheln] = useState<Kachel[] | null>(null);

  useEffect(() => {
    (async () => {
      const heute = new Date().toISOString().slice(0, 10);
      const in30 = new Date(Date.now() + 30 * 864e5).toISOString().slice(0, 10);
      const [aend, gv, ev, news, pay] = await Promise.all([
        supabase.rpc('aenderungen_lesen', { p_alle: true }),
        supabase.from('versammlungen').select('titel, datum, status').gte('datum', heute).order('datum').limit(1),
        supabase.from('events').select('id, title, date, status').gte('date', heute).lte('date', in30),
        supabase.from('news').select('id, status'),
        supabase.from('payments').select('status, dueDate'),
      ]);
      const offen = (aend.data ?? []).filter((z: any) => z.status === 'OFFEN').length;
      const naechste = (gv.data ?? [])[0] as any;
      const anlaesse = (ev.data ?? []).filter((e: any) => e.status === 'PUBLISHED');
      const entwuerfe = (news.data ?? []).filter((n: any) => n.status === 'DRAFT').length;
      const ueberfaellig = (pay.data ?? []).filter((p: any) => isOverdue(p)).length;
      setKacheln([
        { k: 'aend', icon: <Inbox size={18} />, zahl: offen, text: t('cockpit.aenderungen'), dringend: offen > 0 },
        { k: 'ueber', icon: <AlertTriangle size={18} />, zahl: ueberfaellig, text: t('cockpit.ueberfaellig'), dringend: ueberfaellig > 0 },
        { k: 'gv', icon: <Gavel size={18} />, zahl: naechste ? new Date(naechste.datum + 'T12:00:00').toLocaleDateString('de-CH', { day: 'numeric', month: 'short' }) : '—',
          text: t('cockpit.gv'), unter: naechste ? `${naechste.titel} · ${t(`gv.status.${naechste.status}`)}` : t('cockpit.gv_keine') },
        { k: 'ev', icon: <CalendarDays size={18} />, zahl: anlaesse.length, text: t('cockpit.anlaesse'), unter: anlaesse[0]?.title },
        { k: 'news', icon: <Newspaper size={18} />, zahl: entwuerfe, text: t('cockpit.entwuerfe') },
      ]);
    })().catch(() => setKacheln([]));
  }, []);

  if (!kacheln || !kacheln.length) return null;
  const allesGut = kacheln.every(k => !k.dringend);

  return (
    <div className="mb-10">
      <div className="flex items-center gap-2 mb-3">
        <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('cockpit.titel')}</p>
        {allesGut && <span className="text-[10px] font-bold text-emerald-600 flex items-center gap-1"><CheckCircle2 size={12} /> {t('cockpit.alles_gut')}</span>}
      </div>
      <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-5 gap-3">
        {kacheln.map(k => (
          <div key={k.k} className={`p-5 rounded-2xl border ${k.dringend ? 'bg-amber-50 border-amber-200' : 'bg-white border-stone-100'}`}>
            <div className={`mb-3 ${k.dringend ? 'text-amber-600' : 'text-stone-400'}`}>{k.icon}</div>
            <p className="text-2xl font-bold text-stone-900">{k.zahl}</p>
            <p className="text-xs font-bold text-stone-600">{k.text}</p>
            {k.unter && <p className="text-[11px] text-stone-400 truncate mt-1">{k.unter}</p>}
          </div>
        ))}
      </div>
    </div>
  );
};

export default VorstandCockpit;
