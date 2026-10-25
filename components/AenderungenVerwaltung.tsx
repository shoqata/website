import React, { useEffect, useState } from 'react';
import { Home, Users2, MessageSquare, Check, X, Loader2, Inbox } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Gemeldete Aenderungen der Mitglieder -- fuer Verwaltung und Vorstand.
// Adresse: Uebernehmen schreibt sie ins Mitglied. Familie: im Profil
// (Reiter Familie) eintragen, dann als erledigt markieren.

type Zeile = {
  id: string; mitglied: string; name: string; art: 'ADRESSE' | 'FAMILIE' | 'SONSTIGES';
  daten: any; status: string; erstellt_am: string; bisher: any;
};

const SYMBOL = { ADRESSE: <Home size={16} />, FAMILIE: <Users2 size={16} />, SONSTIGES: <MessageSquare size={16} /> };

export function useOffeneAenderungen() {
  const [zeilen, setZeilen] = useState<Zeile[] | null>(null);
  const laden = () => supabase.rpc('aenderungen_lesen', { p_alle: true }).then(({ data }) => setZeilen((data ?? []) as Zeile[]));
  useEffect(() => { laden(); }, []);
  return { zeilen, laden };
}

const adresse = (a: any) => a ? [a.street, [a.zip, a.city].filter(Boolean).join(' '), a.country].filter(Boolean).join(', ') : '';

const AenderungenVerwaltung: React.FC<{ onOeffnen?: (mitglied: string) => void; kompakt?: boolean }> = ({ onOeffnen, kompakt }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const { zeilen, laden } = useOffeneAenderungen();
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const offen = (zeilen ?? []).filter(z => z.status === 'OFFEN');
  if (zeilen === null || (kompakt && !offen.length)) return null;

  const entscheiden = async (z: Zeile, ja: boolean) => {
    setArbeitet(z.id);
    const { error } = await supabase.rpc('aenderung_entscheiden', { p_id: z.id, p_uebernehmen: ja, p_notiz: null });
    setArbeitet(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  return (
    <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-6">
      <div className="flex items-center gap-3 mb-4">
        <Inbox size={18} className="text-stone-400" />
        <h3 className="font-bold text-stone-900">{t('aend.verw_titel')} <span className="text-stone-400 font-normal">({offen.length})</span></h3>
      </div>
      {!offen.length ? <p className="text-xs text-stone-400">{t('aend.verw_leer')}</p> : (
        <div className="space-y-2">
          {offen.map(z => (
            <div key={z.id} className="flex flex-wrap items-start gap-3 p-4 bg-stone-50 rounded-2xl">
              <div className="w-9 h-9 rounded-xl bg-white text-stone-500 flex items-center justify-center shrink-0">{SYMBOL[z.art]}</div>
              <div className="flex-1 min-w-[200px]">
                <p className="text-sm font-bold text-stone-800">
                  {onOeffnen ? <button onClick={() => onOeffnen(z.mitglied)} className="hover:underline">{z.name}</button> : z.name}
                  <span className="text-stone-400 font-normal"> · {t(`aend.art.${z.art}`)} · {new Date(z.erstellt_am).toLocaleDateString('de-CH')}</span>
                </p>
                {z.art === 'ADRESSE' ? (
                  <div className="text-xs mt-1 space-y-0.5">
                    <p className="text-stone-400 line-through">{adresse(z.bisher) || '—'}</p>
                    <p className="text-stone-800 font-bold">{adresse(z.daten)}{z.daten.ab ? ` (${t('aend.ab')} ${z.daten.ab})` : ''}</p>
                  </div>
                ) : <p className="text-xs text-stone-600 mt-1 whitespace-pre-line">{z.daten.text}</p>}
              </div>
              <div className="flex items-center gap-2">
                {arbeitet === z.id ? <Loader2 size={16} className="animate-spin text-stone-300" /> : (
                  <>
                    <button onClick={() => entscheiden(z, true)}
                            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-emerald-600 text-white">
                      <Check size={13} /> {z.art === 'ADRESSE' ? t('aend.uebernehmen') : t('aend.erledigt')}
                    </button>
                    <button onClick={() => entscheiden(z, false)} title={t('aend.ablehnen')}
                            className="w-8 h-8 rounded-xl flex items-center justify-center text-stone-400 hover:text-rose-600 hover:bg-rose-50">
                      <X size={15} />
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AenderungenVerwaltung;
