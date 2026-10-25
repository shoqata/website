import React, { useMemo, useState } from 'react';
import { UserCheck, Globe, Copy, Loader2 } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, updateDoc, writeBatch } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import type { UserProfile } from '../types';

// Schnellkorrektur in der Datenqualitaet: was sich in Sekunden beheben
// laesst, statt jedes Mitglied einzeln zu oeffnen.
//
//  - Anrede: fehlt bei fast allen. Sie entscheidet, ob im Stammbaum
//    "Mutter" oder "Elternteil" steht und wie Briefe beginnen. Geraten wird
//    nicht -- zwei Knoepfe je Zeile.
//  - Land: vierstellige Postleitzahl ohne Land ist eine Schweizer Adresse
//    (dieselbe Regel wie im Einrichtungsassistenten).
//  - Dubletten: gleicher Name und gleiches Geburtsdatum, oder dieselbe
//    E-Mail. Nur angezeigt; zusammengefuehrt wird bewusst von Hand.

const norm = (s?: string | null) => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/\s+/g, ' ').trim();

const DatenSchnellkorrektur: React.FC<{ users: UserProfile[]; onEditUser: (u: UserProfile) => void }> = ({ users, onEditUser }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [gesetzt, setGesetzt] = useState<Record<string, string>>({});
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [mehr, setMehr] = useState(false);

  const ohneAnrede = useMemo(() => users.filter(u => !u.salutation && !gesetzt[u.id])
    .sort((a, b) => (a.displayName || '').localeCompare(b.displayName || '')), [users, gesetzt]);
  const ohneLand = useMemo(() => users.filter(u => !u.country && /^\d{4}$/.test((u.zip || '').trim())), [users]);
  const dubletten = useMemo(() => {
    const gruppen = new Map<string, UserProfile[]>();
    for (const u of users) {
      const schluessel = [
        norm(u.displayName) && u.birthdate ? `n:${norm(u.displayName)}|${u.birthdate}` : null,
        u.email && !u.email.endsWith('.legacy') ? `e:${norm(u.email)}` : null,
      ].filter(Boolean) as string[];
      for (const k of schluessel) { if (!gruppen.has(k)) gruppen.set(k, []); gruppen.get(k)!.push(u); }
    }
    const gesehen = new Set<string>();
    return [...gruppen.values()].filter(g => g.length > 1).filter(g => {
      const id = g.map(u => u.id).sort().join('|');
      if (gesehen.has(id)) return false;
      gesehen.add(id); return true;
    });
  }, [users]);

  const anredeSetzen = async (u: UserProfile, anrede: 'Z.' | 'Znj.') => {
    setArbeitet(u.id);
    try {
      await updateDoc(doc(db, 'users', u.id), { salutation: anrede });
      setGesetzt(g => ({ ...g, [u.id]: anrede }));
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setArbeitet(null); }
  };

  const landSetzen = async () => {
    const ok = await showConfirm({
      title: t('dq2.land_titel'), message: t('dq2.land_frage', { count: ohneLand.length }),
      confirmText: t('dq2.land_knopf', { count: ohneLand.length }), type: 'primary',
    });
    if (!ok) return;
    setArbeitet('land');
    try {
      const batch = writeBatch(db);
      ohneLand.forEach(u => batch.set(doc(db, 'users', u.id), { country: 'Schweiz' }, { merge: true }));
      await batch.commit();
      showAlert({ type: 'success', message: t('dq2.land_fertig', { count: ohneLand.length }) });
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setArbeitet(null); }
  };

  if (!ohneAnrede.length && !ohneLand.length && !dubletten.length) return null;
  const liste = mehr ? ohneAnrede.slice(0, 120) : ohneAnrede.slice(0, 12);

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
      {ohneAnrede.length > 0 && (
        <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-6 xl:col-span-2">
          <div className="flex items-center gap-3 mb-1">
            <UserCheck size={18} className="text-stone-400" />
            <h3 className="font-bold text-stone-900">{t('dq2.anrede_titel')} <span className="text-stone-400 font-normal">({ohneAnrede.length})</span></h3>
          </div>
          <p className="text-xs text-stone-500 mb-4">{t('dq2.anrede_text')}</p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
            {liste.map(u => (
              <div key={u.id} className="flex items-center gap-2 px-3 py-2 bg-stone-50 rounded-xl">
                <button onClick={() => onEditUser(u)} className="flex-1 min-w-0 text-left text-sm font-bold text-stone-700 truncate hover:underline">{u.displayName}</button>
                {arbeitet === u.id ? <Loader2 size={14} className="animate-spin text-stone-300" /> : (
                  <>
                    <button onClick={() => anredeSetzen(u, 'Z.')} className="px-2.5 py-1 rounded-lg text-xs font-bold bg-white border border-stone-200 text-sky-700 hover:border-sky-300">{t('salutation.mr')}</button>
                    <button onClick={() => anredeSetzen(u, 'Znj.')} className="px-2.5 py-1 rounded-lg text-xs font-bold bg-white border border-stone-200 text-pink-700 hover:border-pink-300">{t('salutation.ms')}</button>
                  </>
                )}
              </div>
            ))}
          </div>
          {ohneAnrede.length > liste.length && (
            <button onClick={() => setMehr(true)} className="mt-3 text-[10px] font-bold uppercase tracking-widest" style={{ color: 'var(--primary)' }}>
              {t('dq2.mehr', { count: Math.min(120, ohneAnrede.length) })}
            </button>
          )}
        </div>
      )}

      <div className="space-y-6">
        {ohneLand.length > 0 && (
          <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-6">
            <div className="flex items-center gap-3 mb-1">
              <Globe size={18} className="text-stone-400" />
              <h3 className="font-bold text-stone-900">{t('dq2.land_titel')} <span className="text-stone-400 font-normal">({ohneLand.length})</span></h3>
            </div>
            <p className="text-xs text-stone-500 mb-4">{t('dq2.land_text')}</p>
            <button onClick={landSetzen} disabled={arbeitet === 'land'}
                    className="knopf-primaer px-4 py-2.5 text-white rounded-xl text-xs font-bold disabled:opacity-60">
              {t('dq2.land_knopf', { count: ohneLand.length })}
            </button>
          </div>
        )}
        {dubletten.length > 0 && (
          <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-6">
            <div className="flex items-center gap-3 mb-1">
              <Copy size={18} className="text-stone-400" />
              <h3 className="font-bold text-stone-900">{t('dq2.dubletten_titel')} <span className="text-stone-400 font-normal">({dubletten.length})</span></h3>
            </div>
            <p className="text-xs text-stone-500 mb-4">{t('dq2.dubletten_text')}</p>
            <div className="space-y-2 max-h-72 overflow-y-auto">
              {dubletten.map(g => (
                <div key={g.map(u => u.id).join()} className="p-3 bg-stone-50 rounded-xl space-y-1">
                  {g.map(u => (
                    <button key={u.id} onClick={() => onEditUser(u)} className="block w-full text-left text-xs hover:underline">
                      <span className="font-bold text-stone-700">{u.displayName}</span>
                      <span className="text-stone-400"> · {u.birthdate || '—'} · {u.email || '—'}{u.membershipStatus === 'INACTIVE' ? ` · ${t('dq2.inaktiv')}` : ''}</span>
                    </button>
                  ))}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DatenSchnellkorrektur;
