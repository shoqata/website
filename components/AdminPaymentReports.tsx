import React, { useState, useEffect } from 'react';
import { BellRing, Check, X, Loader2, User, Calendar, Banknote } from 'lucide-react';
import { db } from '../services/firebase';
import { collection, getDocs, query, decidePaymentReport } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Offene Zahlungsmeldungen aus den Nachbarschaften.
//
// Eine verantwortliche Person meldet, dass jemand bezahlt hat; gebucht wird
// erst hier. Das Bestaetigen setzt die Rechnung auf bezahlt -- in einer
// einzigen serverseitigen Funktion, damit Meldung und Rechnung nicht
// auseinanderlaufen koennen.
const AdminPaymentReports: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [meldungen, setMeldungen] = useState<any[]>([]);
  const [namen, setNamen] = useState<Record<string, string>>({});
  const [laedt, setLaedt] = useState(true);
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const laden = async () => {
    setLaedt(true);
    try {
      const [rep, usr] = await Promise.all([
        getDocs(query(collection(db, 'payment_reports'))),
        getDocs(query(collection(db, 'users'))),
      ]);
      const karte: Record<string, string> = {};
      usr.docs.forEach(d => { karte[d.id] = (d.data() as any).displayName || d.id; });
      setNamen(karte);
      setMeldungen(rep.docs.map(d => ({ id: d.id, ...d.data() })).filter((r: any) => r.status === 'OPEN'));
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { laden(); }, []);

  const entscheiden = async (id: string, zustimmen: boolean) => {
    setArbeitet(id);
    try {
      await decidePaymentReport(id, zustimmen);
      showAlert({ type: 'success', message: zustimmen ? t('reports.confirmed') : t('reports.rejected') });
      setMeldungen(l => l.filter(m => m.id !== id));
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setArbeitet(null);
    }
  };

  if (laedt) {
    return <div className="p-10 flex justify-center"><Loader2 className="animate-spin text-primary" size={24} /></div>;
  }

  if (!meldungen.length) {
    return (
      <div className="bg-white p-8 rounded-[2rem] border border-stone-100 text-center">
        <BellRing className="mx-auto text-stone-300 mb-3" size={28} />
        <p className="text-sm text-stone-400">{t('reports.none')}</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2 mb-2">
        <BellRing size={18} className="text-primary" />
        <h4 className="font-bold text-lg text-stone-900">{t('reports.title')}</h4>
        <span className="text-xs font-bold bg-amber-100 text-amber-700 px-2.5 py-1 rounded-lg">{meldungen.length}</span>
      </div>
      <p className="text-xs text-stone-500 leading-relaxed mb-4">{t('reports.explain')}</p>

      {meldungen.map(m => (
        <div key={m.id} className="bg-white border border-stone-100 rounded-2xl p-5 flex flex-wrap items-center justify-between gap-4">
          <div className="min-w-0 space-y-1">
            <p className="font-bold text-stone-900 flex items-center gap-2">
              <Banknote size={14} className="text-primary" /> {m.amount} · {m.method || '-'}
            </p>
            <p className="text-xs text-stone-500 flex flex-wrap items-center gap-3">
              <span className="flex items-center gap-1"><User size={11} /> {t('reports.by')} {namen[m.reportedBy] || m.reportedBy}</span>
              <span className="flex items-center gap-1"><Calendar size={11} /> {m.paidOn || '-'}</span>
            </p>
            {m.note && <p className="text-xs text-stone-400 italic">{m.note}</p>}
          </div>
          <div className="flex gap-2">
            <button onClick={() => entscheiden(m.id, false)} disabled={arbeitet === m.id}
              className="px-4 py-2.5 bg-stone-100 text-stone-600 rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-stone-200 transition-colors disabled:opacity-50">
              <X size={13} /> {t('reports.reject')}
            </button>
            <button onClick={() => entscheiden(m.id, true)} disabled={arbeitet === m.id}
              className="px-4 py-2.5 bg-emerald-600 text-white rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-emerald-700 transition-colors disabled:opacity-50">
              {arbeitet === m.id ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} />} {t('reports.confirm')}
            </button>
          </div>
        </div>
      ))}
    </div>
  );
};

export default AdminPaymentReports;
