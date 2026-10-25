import React, { useEffect, useState } from 'react';
import { CalendarDays, CalendarPlus, CheckCircle2, Clock, MapPin, Loader2 } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { collection, query, where, getDocs, addDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { useModule } from '../lib/useModule';
import { icsHerunterladen } from '../lib/kalender';
import type { SolidarityEvent, UserProfile } from '../types';

// Naechste Anlaesse im Mitgliederbereich: mit einem Klick anmelden, sehen,
// wofuer man angemeldet ist, und den Termin in den eigenen Kalender holen.

const MeineAnlaesse: React.FC<{ user: UserProfile }> = ({ user }) => {
  const { t, loc } = useTranslation();
  const { showAlert } = useFeedback();
  const { aktiv } = useModule();
  const [anlaesse, setAnlaesse] = useState<SolidarityEvent[] | null>(null);
  const [angemeldet, setAngemeldet] = useState<Record<string, string>>({});
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const laden = async () => {
    const heute = new Date().toISOString().slice(0, 10);
    const [ev, reg] = await Promise.all([
      getDocs(query(collection(db, 'events'), where('tenantId', '==', user.tenantId))),
      getDocs(query(collection(db, 'event_registrations'), where('userId', '==', user.id))),
    ]);
    setAnlaesse(ev.docs.map((d: any) => ({ id: d.id, ...d.data() }) as SolidarityEvent)
      .filter(e => e.status === 'PUBLISHED' && (e.date || '') >= heute)
      .sort((a, b) => a.date.localeCompare(b.date)).slice(0, 4));
    const m: Record<string, string> = {};
    reg.docs.forEach((d: any) => { const r = d.data(); if (r.status !== 'REJECTED') m[r.eventId] = r.status || 'PENDING'; });
    setAngemeldet(m);
  };
  useEffect(() => { if (aktiv('ANLAESSE')) laden().catch(() => setAnlaesse([])); }, [user.id, aktiv('ANLAESSE')]);

  if (!aktiv('ANLAESSE') || !anlaesse || !anlaesse.length) return null;

  const anmelden = async (e: SolidarityEvent) => {
    setArbeitet(e.id);
    try {
      await addDoc(collection(db, 'event_registrations'), {
        eventId: e.id, eventTitle: e.title, registeredAt: new Date().toISOString(), type: 'MEMBER',
        name: user.displayName || 'Member', email: user.email, phone: user.phone || '', userId: user.id, status: 'PENDING',
      });
      setAngemeldet(a => ({ ...a, [e.id]: 'PENDING' }));
      showAlert({ type: 'success', message: t('anl.angemeldet_meldung') });
    } catch (err: any) {
      showAlert({ type: 'error', message: err?.message || t('common.error') });
    } finally { setArbeitet(null); }
  };

  return (
    <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
      <h4 className="font-bold text-xl text-stone-900 flex items-center gap-2 mb-6"><CalendarDays className="text-primary" /> {t('anl.titel')}</h4>
      <div className="space-y-3">
        {anlaesse.map(e => {
          const status = angemeldet[e.id];
          const d = new Date(e.date);
          return (
            <div key={e.id} className="flex flex-wrap items-center gap-4 p-4 bg-stone-50 rounded-2xl">
              <div className="w-14 text-center shrink-0">
                <p className="text-2xl font-bold text-stone-900 leading-none">{d.getDate()}</p>
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{d.toLocaleDateString('de-CH', { month: 'short' })}</p>
              </div>
              <div className="flex-1 min-w-[180px]">
                <p className="font-bold text-stone-800">{e.title}</p>
                <p className="text-xs text-stone-500 flex flex-wrap gap-3">
                  {e.time && <span className="inline-flex items-center gap-1"><Clock size={11} /> {e.time}</span>}
                  {e.location && <span className="inline-flex items-center gap-1"><MapPin size={11} /> {e.location}</span>}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <button onClick={() => icsHerunterladen({ id: e.id, title: e.title, date: e.date, time: e.time, location: e.location, description: e.description }, `${window.location.origin}/events`)}
                        title={t('anl.kalender')} className="w-9 h-9 rounded-xl bg-white border border-stone-200 text-stone-500 hover:text-stone-900 flex items-center justify-center">
                  <CalendarPlus size={15} />
                </button>
                {status ? (
                  <span className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                    <CheckCircle2 size={13} /> {status === 'APPROVED' ? t('anl.bestaetigt') : t('anl.angemeldet')}
                  </span>
                ) : e.isRegistrable ? (
                  <button onClick={() => anmelden(e)} disabled={arbeitet === e.id}
                          className="knopf-primaer px-4 py-2 text-white rounded-xl text-xs font-bold flex items-center gap-1.5">
                    {arbeitet === e.id && <Loader2 size={12} className="animate-spin" />} {t('anl.anmelden')}
                  </button>
                ) : null}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default MeineAnlaesse;
