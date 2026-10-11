import React, { useState, useEffect } from 'react';
import { BellRing, Check, X, Loader2, User, Calendar, Banknote } from 'lucide-react';
import { db } from '../services/datenzugriff';
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
  const [rechnungen, setRechnungen] = useState<Record<string, any>>({});
  const [laedt, setLaedt] = useState(true);
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const laden = async () => {
    setLaedt(true);
    try {
      const [rep, usr, zhl] = await Promise.all([
        getDocs(query(collection(db, 'payment_reports'))),
        getDocs(query(collection(db, 'users'))),
        getDocs(query(collection(db, 'payments'))),
      ]);
      // Was verrechnet wurde und was schon eingegangen ist. Der gemeldete
      // Betrag allein sagt nichts -- erst daneben wird sichtbar, dass
      // jemand zu wenig oder zu viel gegeben hat.
      const rech: Record<string, any> = {};
      zhl.docs.forEach(d => { rech[d.id] = d.data(); });
      setRechnungen(rech);
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
              <Banknote size={14} className="text-primary" />
              {(() => {
                const r = rechnungen[m.paymentId] || {};
                const soll = Number(r.amount ?? NaN);
                const ist = Number(m.amount ?? NaN);
                const waehrung = r.currency || 'CHF';
                if (!Number.isFinite(soll) || !Number.isFinite(ist) || soll === ist) {
                  return <span>{waehrung} {Number.isFinite(ist) ? ist.toFixed(2) : '?'} · {m.method || '-'}</span>;
                }
                const d = ist - soll;
                return (
                  <span className="flex flex-wrap items-center gap-x-2 gap-y-1">
                    <span className="font-mono font-bold">{waehrung} {ist.toFixed(2)}</span>
                    <span className="text-stone-400 line-through font-mono">{soll.toFixed(2)}</span>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      d > 0 ? 'bg-sky-100 text-sky-800' : 'bg-amber-100 text-amber-800'}`}>
                      {d > 0 ? `+${d.toFixed(2)} zu viel` : `${d.toFixed(2)} offen`}
                    </span>
                    <span className="text-stone-400">· {m.method || '-'}</span>
                  </span>
                );
              })()}
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
