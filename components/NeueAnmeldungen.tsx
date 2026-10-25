import React, { useState } from 'react';
import { UserPlus, Check, X, Loader2 } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, updateDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import type { UserProfile } from '../types';

// Wer sich ueber "Mitglied werden" angemeldet hat, steht auf PENDING, bis
// der Vorstand aufnimmt. Bisher gab es dafuer keine Stelle -- sie standen
// nur irgendwo in der Mitgliederliste.

const NeueAnmeldungen: React.FC<{ users: UserProfile[]; onOeffnen?: (u: UserProfile) => void }> = ({ users, onOeffnen }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [erledigt, setErledigt] = useState<Set<string>>(new Set());
  const offen = users.filter(u => u.membershipStatus === 'PENDING' && !erledigt.has(u.id));
  if (!offen.length) return null;

  const setzen = async (u: UserProfile, status: 'ACTIVE' | 'INACTIVE') => {
    if (status === 'INACTIVE' && !(await showConfirm({ title: t('aend.ablehnen'), message: t('neu.ablehnen_frage', { name: u.displayName || '' }), type: 'danger' }))) return;
    setArbeitet(u.id);
    try {
      await updateDoc(doc(db, 'users', u.id), status === 'ACTIVE'
        ? { membershipStatus: 'ACTIVE', joinedAt: (u as any).joinedAt || new Date().toISOString() }
        : { membershipStatus: 'INACTIVE' });
      setErledigt(e => new Set(e).add(u.id));
    } catch (e: any) { showAlert({ type: 'error', message: e?.message || '?' }); }
    finally { setArbeitet(null); }
  };

  return (
    <div className="bg-white rounded-3xl border border-emerald-200 shadow-sm p-6">
      <div className="flex items-center gap-3 mb-1">
        <UserPlus size={18} className="text-emerald-600" />
        <h3 className="font-bold text-stone-900">{t('neu.titel')} <span className="text-stone-400 font-normal">({offen.length})</span></h3>
      </div>
      <p className="text-xs text-stone-500 mb-4">{t('neu.text')}</p>
      <div className="space-y-2">
        {offen.map(u => (
          <div key={u.id} className="flex flex-wrap items-center gap-3 p-3 bg-stone-50 rounded-xl">
            <button onClick={() => onOeffnen?.(u)} className="flex-1 min-w-[180px] text-left">
              <p className="text-sm font-bold text-stone-800 hover:underline">{u.displayName}</p>
              <p className="text-xs text-stone-500">{[u.email, [u.zip, u.city].filter(Boolean).join(' ')].filter(Boolean).join(' · ')}</p>
            </button>
            {arbeitet === u.id ? <Loader2 size={16} className="animate-spin text-stone-300" /> : (
              <>
                <button onClick={() => setzen(u, 'ACTIVE')} className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-emerald-600 text-white"><Check size={13} /> {t('neu.aufnehmen')}</button>
                <button onClick={() => setzen(u, 'INACTIVE')} title={t('aend.ablehnen')} className="w-8 h-8 rounded-xl flex items-center justify-center text-stone-400 hover:text-rose-600 hover:bg-rose-50"><X size={15} /></button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default NeueAnmeldungen;
