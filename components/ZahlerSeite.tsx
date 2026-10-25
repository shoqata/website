import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { BadgeCheck, Lock, Loader2, Users } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Wer hat den Mitgliederbeitrag bezahlt -- als Zahl, je Nachbarschaft und,
// wenn der Verein es so eingestellt hat, mit Namen.
//
// Was hier steht, entscheidet zahlerliste() in der Datenbank: ob die Seite
// oeffentlich ist oder nur fuer Mitglieder, ob Namen erscheinen, und dass
// ein Mitglied mit Widerspruch nicht namentlich genannt wird. Diese Seite
// zeigt nur an, was sie bekommt.

type Nb = { name: string; gesamt: number; bezahlt: number; namen: string[] | null };
type Liste = {
  sichtbar: 'AUS' | 'MITGLIEDER' | 'OEFFENTLICH'; gesperrt?: boolean; jahr?: number;
  gesamt?: number; bezahlt?: number; namen?: string[] | null; namen_an?: boolean;
  nachbarschaften?: Nb[] | null; nachbarschaften_an?: boolean;
};

const Balken: React.FC<{ bezahlt: number; gesamt: number }> = ({ bezahlt, gesamt }) => {
  const anteil = gesamt > 0 ? Math.floor((bezahlt / gesamt) * 100) : 0;
  return (
    <div className="h-2.5 bg-stone-100 rounded-full overflow-hidden">
      <div className="h-full bg-emerald-500 rounded-full transition-[width] duration-300 ease-out-strong" style={{ width: `${anteil}%` }} />
    </div>
  );
};

const ZahlerSeite: React.FC = () => {
  const { t } = useTranslation();
  const jetzt = new Date().getFullYear();
  const [jahr, setJahr] = useState(jetzt);
  const [liste, setListe] = useState<Liste | null>(null);

  useEffect(() => {
    setListe(null);
    supabase.rpc('zahlerliste', { p_jahr: jahr }).then(({ data, error }) => {
      setListe(error ? { sichtbar: 'AUS' } : (data as Liste));
    });
  }, [jahr]);

  if (!liste) return <div className="min-h-[60dvh] flex items-center justify-center"><Loader2 className="animate-spin text-primary" size={32} /></div>;

  if (liste.sichtbar === 'AUS') {
    return (
      <div className="min-h-[60dvh] flex items-center justify-center p-6 pt-32">
        <p className="text-stone-500 text-sm">{t('zl.aus')}</p>
      </div>
    );
  }
  if (liste.gesperrt) {
    return (
      <div className="min-h-[60dvh] flex items-center justify-center p-6 pt-32">
        <div className="max-w-md text-center space-y-4">
          <Lock className="mx-auto text-stone-300" size={40} />
          <p className="text-stone-600 text-sm leading-relaxed">{t('zl.nur_mitglieder')}</p>
          <Link to="/login" className="inline-block bg-primary text-white px-6 py-3 rounded-xl font-bold text-sm">{t('nav.login')}</Link>
        </div>
      </div>
    );
  }

  const gesamt = liste.gesamt || 0, bezahlt = liste.bezahlt || 0;
  const anteil = gesamt > 0 ? Math.floor((bezahlt / gesamt) * 100) : 0;

  return (
    <div className="max-w-5xl mx-auto px-6 pt-32 pb-20 space-y-10">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-stone-400 mb-2">{t('zl.kicker')}</p>
          <h1 className="text-4xl md:text-5xl font-display font-bold italic text-stone-900">{t('zl.titel', { year: liste.jahr || jahr })}</h1>
        </div>
        <div className="flex gap-1 bg-stone-100 p-1 rounded-xl">
          {[jetzt - 1, jetzt].map(j => (
            <button key={j} onClick={() => setJahr(j)}
              className={`px-4 py-2 rounded-lg text-sm font-bold ${jahr === j ? 'bg-white shadow-sm text-stone-900' : 'text-stone-500'}`}>{j}</button>
          ))}
        </div>
      </div>

      <div className="bg-stone-900 text-white rounded-[2.5rem] p-8 md:p-10">
        <div className="flex flex-wrap items-end gap-x-6 gap-y-2 mb-5">
          <p className="text-6xl font-bold">{bezahlt}</p>
          <p className="text-stone-400 pb-2">{t('zl.von', { total: gesamt })} · {anteil}%</p>
        </div>
        <div className="h-3 bg-white/10 rounded-full overflow-hidden">
          <div className="h-full bg-emerald-400 rounded-full" style={{ width: `${anteil}%` }} />
        </div>
      </div>

      {liste.nachbarschaften_an && (liste.nachbarschaften || []).length > 0 && (
        <div className="space-y-4">
          <h2 className="text-xl font-bold text-stone-900 flex items-center gap-2"><Users size={20} /> {t('zl.je_nachbarschaft')}</h2>
          <div className="grid gap-4 md:grid-cols-2">
            {(liste.nachbarschaften || []).map(n => (
              <div key={n.name} className="bg-white border border-stone-100 rounded-[2rem] p-6 space-y-3">
                <div className="flex items-baseline justify-between gap-3">
                  <p className="font-bold text-stone-900">{n.name}</p>
                  <p className="text-sm text-stone-500 shrink-0">
                    <span className="font-bold text-emerald-700">{n.bezahlt}</span> / {n.gesamt}
                    <span className="ml-2 text-stone-400">{n.gesamt ? Math.floor((n.bezahlt / n.gesamt) * 100) : 0}%</span>
                  </p>
                </div>
                <Balken bezahlt={n.bezahlt} gesamt={n.gesamt} />
                {liste.namen_an && (n.namen || []).length > 0 && (
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {(n.namen || []).map((x, i) => (
                      <span key={`${x}-${i}`} className="px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-800 text-xs font-bold flex items-center gap-1 min-w-0 [overflow-wrap:anywhere]">
                        <BadgeCheck size={12} /> {x}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {liste.namen_an && !liste.nachbarschaften_an && (liste.namen || []).length > 0 && (
        <div className="flex flex-wrap gap-2">
          {(liste.namen || []).map((x, i) => (
            <span key={`${x}-${i}`} className="px-3 py-1.5 rounded-xl bg-emerald-50 text-emerald-800 text-sm font-bold flex items-center gap-1.5 min-w-0 [overflow-wrap:anywhere]">
              <BadgeCheck size={14} /> {x}
            </span>
          ))}
        </div>
      )}

      {liste.namen_an && (
        <p className="text-xs text-stone-400 leading-relaxed max-w-2xl">{t('zl.widerspruch_hinweis')}</p>
      )}
    </div>
  );
};

export default ZahlerSeite;
