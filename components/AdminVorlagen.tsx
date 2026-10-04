import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Check, Lock, Loader2, Sparkles, LayoutTemplate, ExternalLink, Eye } from 'lucide-react';
import { doc, setDoc, supabase } from '@/services/supabase-bridge';
import { db } from '../services/datenzugriff';
import { useTranslation } from '../context/LanguageContext';

// Die Auswahl der Startseiten-Vorlage.
//
// Sie steht hier unter Website und nicht mehr in den Einstellungen: ein
// Verein, der sein Aussehen aendern will, sucht es dort, wo er seine
// Website macht. In den Einstellungen stand es, weil es damals eine
// Umschaltung war und keine Auswahl.
//
// Was zur Wahl steht und was gesperrt ist, rechnet die Datenbank aus
// (startseiten_vorlagen_auswahl). Das Frontend muesste sonst die
// Modulbuchung kennen -- und zwei Stellen, die dasselbe ausrechnen, laufen
// auseinander. Dass die Sperre auch wirklich sperrt, entscheidet ohnehin
// eine dritte Stelle: startseiten_vorlage() beim Besucher.

type Vorlage = {
  schluessel: string;
  name_de: string; name_en: string; name_sq: string;
  beschreibung_de: string; beschreibung_en: string; beschreibung_sq: string;
  ist_premium: boolean; modul: string | null; preis_monat: number | null;
  gesperrt: boolean; gewaehlt: boolean;
};

// onGewaehlt: der Aufrufer zeigt daneben die echte Seite in einem Rahmen.
// Nach einem Wechsel muss der neu laden, sonst steht dort weiter die alte
// Vorlage und es sieht aus, als habe die Wahl nicht gewirkt.
const AdminVorlagen: React.FC<{ onGewaehlt?: () => void }> = ({ onGewaehlt }) => {
  const { t, language } = useTranslation();
  const [vorlagen, setVorlagen] = useState<Vorlage[] | null>(null);
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [fehler, setFehler] = useState('');

  const laden = async () => {
    const { data, error } = await supabase.rpc('startseiten_vorlagen_auswahl');
    if (error) { setFehler(error.message); setVorlagen([]); return; }
    setVorlagen((data as Vorlage[]) || []);
  };
  useEffect(() => { laden(); }, []);

  const name = (v: Vorlage) =>
    language === 'sq' ? v.name_sq : language === 'en' ? v.name_en : v.name_de;
  const beschreibung = (v: Vorlage) =>
    language === 'sq' ? v.beschreibung_sq : language === 'en' ? v.beschreibung_en : v.beschreibung_de;

  const waehlen = async (v: Vorlage) => {
    if (v.gesperrt || v.gewaehlt) return;
    setArbeitet(v.schluessel); setFehler('');
    try {
      await setDoc(doc(db, 'settings', 'system'),
                   { startseitenVorlage: v.schluessel }, { merge: true });
      // Der Browser merkt sich die zuletzt gesehene Vorlage, damit die Seite
      // beim naechsten Besuch nicht erst falsch erscheint. Nach einer
      // Aenderung ist dieser Merkzettel veraltet.
      try { localStorage.removeItem('startseiten-vorlage'); } catch { /* egal */ }
      await laden();
      onGewaehlt?.();
    } catch (e: any) {
      setFehler(e?.message || 'Konnte nicht gespeichert werden.');
    } finally { setArbeitet(null); }
  };

  if (vorlagen === null) {
    return <div className="flex items-center gap-2 text-stone-400 text-sm p-8">
      <Loader2 className="animate-spin" size={16} /> …
    </div>;
  }

  const gruppe = (premium: boolean) => vorlagen.filter(v => v.ist_premium === premium);

  const Karte: React.FC<{ v: Vorlage }> = ({ v }) => (
    <button type="button" onClick={() => waehlen(v)} disabled={v.gesperrt || !!arbeitet}
      className={`text-left p-5 rounded-2xl border transition-all relative ${
        v.gesperrt ? 'bg-stone-50 border-stone-200 cursor-not-allowed'
        : v.gewaehlt ? 'bg-white border-primary shadow-sm ring-1 ring-primary/20'
        : 'bg-white/70 border-stone-200 hover:border-stone-300 hover:shadow-sm'}`}>

      <div className="flex items-start justify-between gap-3 mb-2">
        <p className={`font-bold text-sm ${v.gewaehlt && !v.gesperrt ? 'text-primary' : 'text-stone-900'}`}>
          {name(v)}
        </p>
        {arbeitet === v.schluessel ? <Loader2 size={15} className="animate-spin text-stone-400 shrink-0" />
          : v.gewaehlt ? <Check size={15} className="text-primary shrink-0" />
          : v.gesperrt ? <Lock size={13} className="text-stone-400 shrink-0" /> : null}
      </div>

      <p className={`text-[11px] leading-relaxed ${v.gesperrt ? 'text-stone-400' : 'text-stone-500'}`}>
        {beschreibung(v)}
      </p>

      {v.gesperrt && v.preis_monat != null && (
        <p className="text-[10px] font-bold text-amber-600 mt-3 tabular-nums">
          {t('vorl.ab')} CHF {Number(v.preis_monat).toFixed(2)}/{t('vorl.monat')}
        </p>
      )}
    </button>
  );

  const gesperrte = vorlagen.filter(v => v.gesperrt).length;

  return (
    <div className="space-y-8">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">{fehler}</p>
      )}

      <section>
        <div className="flex items-center gap-2 mb-1">
          <LayoutTemplate size={16} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('vorl.standard')}</h3>
        </div>
        <p className="text-[11px] text-stone-400 mb-4">{t('vorl.standard_text')}</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {gruppe(false).map(v => <Karte key={v.schluessel} v={v} />)}
        </div>
      </section>

      <section>
        <div className="flex items-center gap-2 mb-1">
          <Sparkles size={16} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('vorl.premium')}</h3>
        </div>
        <p className="text-[11px] text-stone-400 mb-4">{t('vorl.premium_text')}</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {gruppe(true).map(v => <Karte key={v.schluessel} v={v} />)}
        </div>

        {gesperrte > 0 && (
          <div className="mt-4 flex items-center justify-between gap-4 flex-wrap
                          bg-amber-50/60 border border-amber-100 rounded-2xl px-5 py-4">
            <p className="text-[11px] text-amber-700 leading-relaxed max-w-md">{t('vorl.nicht_gebucht')}</p>
            <Link to="/admin?tab=MARKTPLATZ"
              className="text-[10px] font-bold uppercase tracking-widest text-amber-800
                         hover:text-amber-900 inline-flex items-center gap-1.5 shrink-0">
              {t('vorl.zum_marktplatz')} <ExternalLink size={11} />
            </Link>
          </div>
        )}
      </section>

      {/* Ansehen statt vorstellen. Die eigene Startseite in einem neuen
          Reiter -- mit dem Inhalt des Vereins, nicht mit erfundenem. */}
      <a href="/" target="_blank" rel="noopener noreferrer"
         className="inline-flex items-center gap-2 text-[11px] font-bold text-stone-400
                    hover:text-stone-700 transition-colors">
        <Eye size={13} /> {t('vorl.ansehen')}
      </a>

      <p className="text-[11px] text-stone-400 leading-relaxed max-w-2xl">{t('vorl.hinweis')}</p>
    </div>
  );
};

export default AdminVorlagen;
