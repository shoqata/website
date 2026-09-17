import React, { useState, useEffect } from 'react';
import { Mail, Send, Loader2, CheckCircle2, Clock, AlertTriangle, Cake, RefreshCw } from 'lucide-react';
import { db } from '../services/firebase';
import { collection, getDocs, query } from '@/services/supabase-bridge';
import { flushMailQueue } from '../services/mailService';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Was hinaus soll, und was schon draussen ist.
//
// Ohne diese Ansicht bliebe der Versand unsichtbar -- genau der Zustand, der
// dazu gefuehrt hat, dass ueber Monate keine einzige Nachricht hinausging und
// es niemandem auffiel.
const AdminMailQueue: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [zeilen, setZeilen] = useState<any[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [sendet, setSendet] = useState(false);

  const laden = async () => {
    setLaedt(true);
    try {
      const snap = await getDocs(query(collection(db, 'mail_queue')));
      const alle = snap.docs.map(d => ({ id: d.id, ...d.data() } as any));
      alle.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
      setZeilen(alle);
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { laden(); }, []);

  const jetztSenden = async () => {
    setSendet(true);
    try {
      const r = await flushMailQueue();
      if (!r.configured) {
        // Kein Fehler, sondern eine offene Voraussetzung -- entsprechend
        // gekennzeichnet, damit niemand nach einer Stoerung sucht.
        showAlert({ type: 'info', message: r.hinweis || t('mail.not_configured') });
      } else {
        showAlert({ type: 'success', message: t('mail.sent_result', { sent: r.sent ?? 0, failed: r.failed ?? 0 }) });
      }
      await laden();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setSendet(false);
    }
  };

  const offen = zeilen.filter(z => z.status === 'PENDING');
  const gesendet = zeilen.filter(z => z.status === 'SENT');
  const gescheitert = zeilen.filter(z => z.status === 'FAILED');

  if (laedt) return <div className="p-10 flex justify-center"><Loader2 className="animate-spin text-primary" size={24} /></div>;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <Mail size={18} className="text-primary" />
          <h4 className="font-bold text-lg text-stone-900">{t('mail.title')}</h4>
        </div>
        <div className="flex gap-2">
          <button onClick={laden} className="px-4 py-2.5 bg-stone-100 text-stone-600 rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-stone-200 transition-colors">
            <RefreshCw size={13} /> {t('common.refresh')}
          </button>
          <button onClick={jetztSenden} disabled={sendet || offen.length === 0}
            className="px-4 py-2.5 bg-primary text-white rounded-xl font-bold text-xs flex items-center gap-1.5 disabled:opacity-40 transition-colors">
            {sendet ? <Loader2 size={13} className="animate-spin" /> : <Send size={13} />} {t('mail.send_now')}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
          <p className="text-2xl font-bold text-amber-700">{offen.length}</p>
          <p className="text-[10px] font-bold uppercase tracking-widest text-amber-600 mt-1">{t('mail.pending')}</p>
        </div>
        <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4">
          <p className="text-2xl font-bold text-emerald-700">{gesendet.length}</p>
          <p className="text-[10px] font-bold uppercase tracking-widest text-emerald-600 mt-1">{t('mail.sent')}</p>
        </div>
        <div className="bg-stone-50 border border-stone-200 rounded-2xl p-4">
          <p className="text-2xl font-bold text-stone-600">{gescheitert.length}</p>
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mt-1">{t('mail.failed')}</p>
        </div>
      </div>

      <p className="text-xs text-stone-500 leading-relaxed p-4 bg-stone-50 border border-stone-200 rounded-2xl">
        {t('mail.explain')}
      </p>

      {zeilen.length === 0 && <p className="text-sm text-stone-400 italic p-6 text-center">{t('mail.empty')}</p>}

      <div className="space-y-2">
        {zeilen.slice(0, 40).map(z => (
          <div key={z.id} className="bg-white border border-stone-100 rounded-2xl p-4 flex flex-wrap items-center justify-between gap-3">
            <div className="min-w-0">
              <p className="font-bold text-sm text-stone-900 truncate flex items-center gap-2">
                {z.kind === 'BIRTHDAY' && <Cake size={13} className="text-primary shrink-0" />}
                {z.subject}
              </p>
              <p className="text-xs text-stone-500 truncate">{z.recipient}</p>
              {z.lastError && <p className="text-[11px] text-red-600 mt-1 truncate">{z.lastError}</p>}
            </div>
            <span className={`px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase flex items-center gap-1.5 shrink-0 ${
              z.status === 'SENT' ? 'bg-emerald-50 text-emerald-700'
              : z.status === 'FAILED' ? 'bg-red-50 text-red-700'
              : 'bg-amber-50 text-amber-700'}`}>
              {z.status === 'SENT' ? <CheckCircle2 size={12} /> : z.status === 'FAILED' ? <AlertTriangle size={12} /> : <Clock size={12} />}
              {z.status === 'SENT' ? t('mail.sent') : z.status === 'FAILED' ? t('mail.failed') : t('mail.pending')}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AdminMailQueue;
