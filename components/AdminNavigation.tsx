import React, { useEffect, useState } from 'react';
import { ArrowUp, ArrowDown, Eye, EyeOff, Loader2, Save, Check, AlertCircle } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, onSnapshot, setDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { useKopfzeile, NavEintrag } from './kopfzeile';

// Die Kopfzeile der Website verwalten: welche Eintraege, in welcher
// Reihenfolge.
//
// Ein Eintrag, dessen Modul nicht gebucht ist (oder dessen Seite
// ausgeschaltet ist), laesst sich trotzdem einordnen -- er erscheint, sobald
// das Modul da ist. Die Maske sagt dazu, warum er gerade fehlt, statt ihn zu
// verstecken: sonst sucht der Verein einen Eintrag, den es nicht gibt.
//
// Eigene Seiten (Website → Eigene Seiten) koennen hier in die Kopfzeile.
// "Im Menü" bei der Seite selbst steuert weiterhin die Fusszeile.

const AdminNavigation: React.FC = () => {
  const { t, loc } = useTranslation();
  const { showAlert } = useFeedback();
  const [system, setSystem] = useState<any>(undefined);
  const [liste, setListe] = useState<NavEintrag[] | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [geaendert, setGeaendert] = useState(false);

  useEffect(() => onSnapshot(doc(db, 'settings', 'system'), (snap: any) => {
    setSystem(snap.exists() ? snap.data() : {});
  }), []);

  const alle = useKopfzeile({
    einstellung: system?.navigation, zahlerliste: system?.zahlerliste,
    angemeldet: true, alle: true, loc,
  });
  // Einmal uebernehmen, danach gehoert die Liste der Maske -- sonst
  // ueberschriebe jede Antwort der Datenbank die laufende Bearbeitung.
  useEffect(() => { if (alle && system !== undefined && !geaendert) setListe(alle); }, [alle, system]);

  const schieben = (i: number, um: number) => {
    if (!liste) return;
    const j = i + um;
    if (j < 0 || j >= liste.length) return;
    const neu = [...liste];
    [neu[i], neu[j]] = [neu[j], neu[i]];
    setListe(neu); setGeaendert(true); setGespeichert(false);
  };
  const schalten = (i: number) => {
    if (!liste) return;
    setListe(liste.map((e, k) => k === i ? { ...e, an: !e.an } : e));
    setGeaendert(true); setGespeichert(false);
  };

  const speichern = async () => {
    if (!liste) return;
    setSpeichert(true);
    try {
      await setDoc(doc(db, 'settings', 'system'),
        { navigation: liste.map(e => ({ schluessel: e.schluessel, an: e.an })) }, { merge: true });
      setGeaendert(false); setGespeichert(true);
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || t('set.save_failed') });
    } finally {
      setSpeichert(false);
    }
  };

  if (!liste) return <div className="p-8 flex justify-center"><Loader2 className="animate-spin text-primary" /></div>;

  const sichtbar = liste.filter(e => e.an && e.moeglich);

  return (
    <div className="space-y-5">
      <div>
        <h3 className="font-bold text-stone-900">{t('navv.titel')}</h3>
        <p className="text-xs text-stone-500 leading-relaxed mt-1 max-w-2xl">{t('navv.hinweis')}</p>
      </div>

      {/* Vorschau: so sieht die Leiste aus. */}
      <div className="bg-stone-50 border border-stone-100 rounded-2xl p-3 flex flex-wrap gap-1.5">
        {sichtbar.length === 0 && <span className="text-xs text-stone-400 italic p-2">{t('navv.leer')}</span>}
        {sichtbar.map(e => (
          <span key={e.schluessel} className="flex items-center gap-2 px-3 py-2 rounded-xl bg-white shadow-sm text-sm font-bold">
            {e.icon}{e.uebersetzen ? t(e.label) : e.label}
          </span>
        ))}
      </div>

      <div className="border border-stone-100 rounded-2xl divide-y divide-stone-100 bg-white">
        {liste.map((e, i) => (
          <div key={e.schluessel} className={`p-3 flex items-center gap-3 ${!e.an ? 'opacity-60' : ''}`}>
            <div className="flex flex-col">
              <button onClick={() => schieben(i, -1)} disabled={i === 0} className="p-1 text-stone-400 hover:text-stone-900 disabled:opacity-20" aria-label={t('navv.hoch')}><ArrowUp size={14} /></button>
              <button onClick={() => schieben(i, 1)} disabled={i === liste.length - 1} className="p-1 text-stone-400 hover:text-stone-900 disabled:opacity-20" aria-label={t('navv.runter')}><ArrowDown size={14} /></button>
            </div>
            <span className="shrink-0">{e.icon}</span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-stone-900 truncate">{e.uebersetzen ? t(e.label) : e.label}</p>
              <p className="text-[11px] text-stone-400 truncate">
                {e.pfad}{e.eigeneSeite ? ` · ${t('navv.eigene_seite')}` : ''}
              </p>
              {!e.moeglich && e.grund && (
                <p className="text-[11px] text-amber-700 flex items-center gap-1 mt-0.5"><AlertCircle size={11} /> {e.grund}</p>
              )}
            </div>
            <button onClick={() => schalten(i)}
              className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 shrink-0 ${
                e.an ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-500'}`}>
              {e.an ? <Eye size={13} /> : <EyeOff size={13} />} {e.an ? t('navv.an') : t('navv.aus')}
            </button>
          </div>
        ))}
      </div>

      <button onClick={speichern} disabled={speichert || !geaendert}
        className={`w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-3 transition-all disabled:opacity-60 ${
          gespeichert ? 'bg-green-500 text-white' : 'bg-primary text-white'}`}>
        {speichert ? <Loader2 className="animate-spin" size={18} /> : gespeichert ? <Check size={18} /> : <Save size={18} />}
        {gespeichert ? t('navv.gespeichert') : t('navv.speichern')}
      </button>
    </div>
  );
};

export default AdminNavigation;
