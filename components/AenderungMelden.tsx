import React, { useEffect, useState } from 'react';
import { X, Home, Users2, MessageSquare, Loader2, CheckCircle2, Clock, XCircle } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Mitglied meldet eine Aenderung: neue Adresse, Familie (Geburt, Heirat,
// Verwandte), Sonstiges. Der Vorstand uebernimmt sie mit einem Klick
// (AenderungenVerwaltung).

type Art = 'ADRESSE' | 'FAMILIE' | 'SONSTIGES';
type Meldung = { id: string; art: Art; daten: any; status: string; erstellt_am: string; notiz: string | null };

const ARTEN: { art: Art; icon: React.ReactNode }[] = [
  { art: 'ADRESSE', icon: <Home size={16} /> },
  { art: 'FAMILIE', icon: <Users2 size={16} /> },
  { art: 'SONSTIGES', icon: <MessageSquare size={16} /> },
];

const AenderungMelden: React.FC<{ onClose: () => void; startArt?: Art }> = ({ onClose, startArt = 'FAMILIE' }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [art, setArt] = useState<Art>(startArt);
  const [d, setD] = useState<Record<string, string>>({});
  const [sendet, setSendet] = useState(false);
  const [meine, setMeine] = useState<Meldung[]>([]);

  const laden = () => supabase.rpc('aenderungen_lesen', { p_alle: false }).then(({ data }) => setMeine((data ?? []) as Meldung[]));
  useEffect(() => { laden(); }, []);

  const senden = async () => {
    setSendet(true);
    const { error } = await supabase.rpc('aenderung_melden', { p_art: art, p_daten: d });
    setSendet(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setD({});
    showAlert({ type: 'success', message: t('aend.gesendet') });
    laden();
  };

  const feld = (k: string, ph: string, cls = '') => (
    <input value={d[k] || ''} onChange={e => setD({ ...d, [k]: e.target.value })} placeholder={ph}
           className={`w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none ${cls}`} />
  );

  return (
    <div className="fixed inset-0 z-[400] flex items-center justify-center p-4 bg-stone-900/70 backdrop-blur-sm" onClick={onClose}>
      <div onClick={e => e.stopPropagation()} className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <div className="p-6 border-b border-stone-100 flex items-start justify-between gap-4">
          <div>
            <h3 className="font-bold text-lg text-stone-900">{t('aend.titel')}</h3>
            <p className="text-xs text-stone-500">{t('aend.hinweis')}</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-stone-100 rounded-full text-stone-500"><X size={18} /></button>
        </div>
        <div className="p-6 space-y-4 overflow-y-auto">
          <div className="grid grid-cols-3 gap-2">
            {ARTEN.map(a => (
              <button key={a.art} onClick={() => { setArt(a.art); setD({}); }}
                      className={`flex flex-col items-center gap-1.5 py-3 rounded-xl text-xs font-bold border ${
                        art === a.art ? 'knopf-primaer text-white border-transparent' : 'bg-white text-stone-600 border-stone-200'}`}>
                {a.icon} {t(`aend.art.${a.art}`)}
              </button>
            ))}
          </div>

          {art === 'ADRESSE' ? (
            <div className="space-y-3">
              {feld('street', t('admin.members.street_no'))}
              <div className="grid grid-cols-3 gap-3">
                {feld('zip', t('field.zip'))}
                <div className="col-span-2">{feld('city', t('field.city'))}</div>
              </div>
              {feld('country', t('field.country'))}
              {feld('ab', t('aend.ab'))}
            </div>
          ) : (
            <textarea value={d.text || ''} onChange={e => setD({ ...d, text: e.target.value })} rows={5}
                      placeholder={t(art === 'FAMILIE' ? 'aend.familie_ph' : 'aend.sonst_ph')}
                      className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none" />
          )}

          <button onClick={senden} disabled={sendet}
                  className="w-full knopf-primaer py-3 text-white rounded-xl text-sm font-bold flex items-center justify-center gap-2 disabled:opacity-60">
            {sendet && <Loader2 size={14} className="animate-spin" />} {t('aend.senden')}
          </button>

          {meine.length > 0 && (
            <div className="pt-4 border-t border-stone-100 space-y-2">
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('aend.meine')}</p>
              {meine.map(m => (
                <div key={m.id} className="flex items-start gap-3 p-3 bg-stone-50 rounded-xl text-xs">
                  {m.status === 'OFFEN' ? <Clock size={14} className="text-amber-500 mt-0.5" />
                    : m.status === 'UEBERNOMMEN' ? <CheckCircle2 size={14} className="text-emerald-600 mt-0.5" />
                    : <XCircle size={14} className="text-stone-400 mt-0.5" />}
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-stone-700">{t(`aend.art.${m.art}`)} · {t(`aend.status.${m.status}`)}</p>
                    <p className="text-stone-500 truncate">
                      {m.art === 'ADRESSE' ? [m.daten.street, [m.daten.zip, m.daten.city].filter(Boolean).join(' ')].filter(Boolean).join(', ') : m.daten.text}
                    </p>
                    {m.notiz && <p className="text-stone-400 italic mt-1">{m.notiz}</p>}
                  </div>
                  <span className="text-stone-400 shrink-0">{new Date(m.erstellt_am).toLocaleDateString('de-CH')}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AenderungMelden;
