import React, { useEffect, useState } from 'react';
import { BellRing, Loader2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Erinnerungen per E-Mail einschalten -- ab Werk aus (erinnerungen_einreihen).
type E = { faelligkeit: boolean; tage_vorher: number; vorstand: boolean; vertreter: boolean };

const ErinnerungEinstellung: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [e, setE] = useState<E | null>(null);
  const [speichert, setSpeichert] = useState(false);
  useEffect(() => { supabase.rpc('erinnerung_einstellung_lesen').then(({ data }) => setE(data as E)); }, []);
  if (!e) return null;

  const setzen = async (neu: E) => {
    setE(neu); setSpeichert(true);
    const { error } = await supabase.rpc('erinnerung_einstellung_setzen', {
      p_faelligkeit: neu.faelligkeit, p_tage: neu.tage_vorher, p_vorstand: neu.vorstand, p_vertreter: neu.vertreter });
    setSpeichert(false);
    if (error) showAlert({ type: 'error', message: error.message });
  };
  const Schalter = ({ k, titel, text }: { k: 'faelligkeit' | 'vorstand' | 'vertreter'; titel: string; text: React.ReactNode }) => (
    <label className="flex items-start gap-4 p-4 bg-stone-50 rounded-2xl cursor-pointer">
      <input type="checkbox" checked={e[k]} onChange={x => setzen({ ...e, [k]: x.target.checked })} className="mt-1 w-4 h-4" />
      <span><span className="block text-sm font-bold text-stone-800">{titel}</span><span className="block text-xs text-stone-500">{text}</span></span>
    </label>
  );

  return (
    <div className="bg-white rounded-3xl border border-stone-100 p-6 space-y-3">
      <h4 className="font-bold text-stone-900 flex items-center gap-2"><BellRing size={18} /> {t('erin.titel')} {speichert && <Loader2 size={14} className="animate-spin text-stone-300" />}</h4>
      <p className="text-xs text-stone-500">{t('erin.text')}</p>
      <Schalter k="faelligkeit" titel={t('erin.faellig')} text={<>{t('erin.faellig_text')}{' '}
        <input type="number" min={1} max={60} value={e.tage_vorher} onClick={x => x.preventDefault()}
               onChange={x => setE({ ...e, tage_vorher: Number(x.target.value) || 7 })} onBlur={() => setzen(e)}
               className="w-14 px-2 py-0.5 border border-stone-200 rounded" /> {t('erin.tage')}</>} />
      <Schalter k="vorstand" titel={t('erin.vorstand')} text={t('erin.vorstand_text')} />
      <Schalter k="vertreter" titel={t('erin.vertreter')} text={t('erin.vertreter_text')} />
    </div>
  );
};

export default ErinnerungEinstellung;
