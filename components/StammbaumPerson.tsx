import React, { useState } from 'react';
import { Search, UserMinus, Plus, X, Loader2 } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { verwandteVon } from '../lib/verwandtschaft';
import { direkteBeziehungen, weiblich, type Rolle, type useStammbaum } from '../lib/stammbaum';

// Die Verwandtschaft einer Person: was erfasst ist (einzeln loesbar), was
// sich daraus ergibt, und Verwandte hinzufuegen per Klick -- ohne Ziehen,
// damit es auch auf dem Telefon und im Mitgliedsprofil geht.
//
// Gebraucht auf der Stammbaum-Seite und im Reiter "Familie" beim Mitglied.

type Sb = ReturnType<typeof useStammbaum>;

const ROLLEN: Rolle[] = ['ELTERNTEIL', 'PARTNER', 'GESCHWISTER', 'KIND'];

const StammbaumPerson: React.FC<{
  sb: Sb;
  person: string;
  onOeffnen?: (id: string) => void;        // Name anklicken: zu dieser Person
  onHinzugefuegt?: (id: string) => void;   // neue Person ist jetzt verbunden
  onHerausgenommen?: () => void;
  nurLesen?: boolean;                      // Vertreter: sehen, nicht aendern
}> = ({ sb, person, onOeffnen, onHinzugefuegt, onHerausgenommen, nurLesen }) => {
  const { t } = useTranslation();
  const { showConfirm } = useFeedback();
  const [rolle, setRolle] = useState<Rolle | null>(null);
  const [suche, setSuche] = useState('');

  const p = sb.nachId.get(person);
  if (!p) return null;

  const direkt = direkteBeziehungen(p);
  const schonDa = new Set([person, ...direkt.map(d => d.id)]);
  const rollenwort = (r: Rolle) => t(`stamm.rolle_${r.toLowerCase()}`);

  const treffer = suche.trim().length < 2 ? [] : sb.leute
    .filter(l => !schonDa.has(l.person) && l.name?.toLowerCase().includes(suche.trim().toLowerCase()))
    .slice(0, 8);

  const verwandte = verwandteVon(sb.netz, person, sb.leute.map(l => l.person), sb.namen,
    (id) => weiblich(sb.anreden.get(id)))
    .filter(v => !schonDa.has(v.id));

  const hinzufuegen = async (wer: string) => {
    if (!rolle) return;
    const ok = await sb.verbinden(person, rolle, wer);
    if (ok) { setSuche(''); setRolle(null); onHinzugefuegt?.(wer); }
  };

  const allesLoesen = async () => {
    const ja = await showConfirm({
      title: t('stamm.herausnehmen'),
      message: t('stamm.herausnehmen_frage').replace('{name}', p.name).replace('{n}', String(direkt.length)),
      confirmText: t('stamm.herausnehmen'), type: 'danger',
    });
    if (ja && await sb.herausnehmen(person)) onHerausgenommen?.();
  };

  const name = (id: string, text: string) => onOeffnen
    ? <button onClick={() => onOeffnen(id)} className="font-bold text-stone-800 hover:underline">{text}</button>
    : <span className="font-bold text-stone-800">{text}</span>;

  return (
    <div className="space-y-5">
      {/* Erfasst */}
      <div>
        <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('stamm.erfasst')}</p>
        {direkt.length ? (
          <div className="flex flex-wrap gap-2">
            {direkt.map(x => (
              <span key={`${x.rolle}${x.id}`}
                    className="inline-flex items-center gap-2 pl-3 pr-1.5 py-1.5 bg-white border border-stone-200 rounded-xl text-xs">
                <span className="text-stone-400">{rollenwort(x.rolle)}</span>
                {name(x.id, x.name)}
                {!nurLesen && <button onClick={() => sb.loesen(x.a, x.b, x.art)} disabled={sb.arbeitet}
                        className="w-6 h-6 rounded-lg flex items-center justify-center text-stone-300 hover:text-rose-600 hover:bg-rose-50"
                        title={t('stamm.loesen')}>
                  <X size={13} />
                </button>}
              </span>
            ))}
          </div>
        ) : <p className="text-xs text-stone-400">{t('stamm.noch_nichts')}</p>}
      </div>

      {/* Hinzufuegen */}
      {!nurLesen && <div>
        <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('stamm.hinzufuegen')}</p>
        <div className="flex flex-wrap gap-2">
          {ROLLEN.map(r => (
            <button key={r} onClick={() => { setRolle(rolle === r ? null : r); setSuche(''); }}
                    className={`inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold border transition-colors ${
                      rolle === r ? 'knopf-primaer text-white border-transparent' : 'bg-white text-stone-600 border-stone-200 hover:border-stone-400'}`}>
              <Plus size={12} /> {rollenwort(r)}
            </button>
          ))}
        </div>
        {rolle && (
          <div className="mt-3 p-3 bg-stone-50 rounded-2xl border border-stone-200">
            <p className="text-[11px] text-stone-500 mb-2">
              {t('stamm.wer_ist').replace('{rolle}', rollenwort(rolle)).replace('{name}', p.name)}
            </p>
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
              <input autoFocus value={suche} onChange={e => setSuche(e.target.value)}
                     placeholder={t('stamm.mitglied_suchen')}
                     className="w-full pl-9 pr-3 py-2.5 bg-white border border-stone-200 rounded-xl text-sm outline-none" />
            </div>
            <div className="mt-2 space-y-1">
              {treffer.map(l => (
                <button key={l.person} onClick={() => hinzufuegen(l.person)} disabled={sb.arbeitet}
                        className="w-full text-left px-3 py-2 bg-white hover:bg-stone-100 rounded-lg flex items-center justify-between gap-3">
                  <span className="min-w-0">
                    <span className="block text-sm font-bold text-stone-700 truncate">{l.name}</span>
                    <span className="block text-[10px] text-stone-400 truncate">
                      {l.nachbarschaft || '—'}{l.geburtsdatum ? ` · ${l.geburtsdatum}` : ''}
                      {l.familienname ? ` · ${t('stamm.familie')} ${l.familienname}` : ''}
                    </span>
                  </span>
                  {sb.arbeitet ? <Loader2 size={14} className="animate-spin text-stone-300" /> : <Plus size={14} className="text-stone-400 shrink-0" />}
                </button>
              ))}
              {suche.trim().length >= 2 && !treffer.length && (
                <p className="text-[11px] text-stone-400 px-1 py-2">{t('stamm.nichts_gefunden')}</p>
              )}
            </div>
          </div>
        )}
      </div>}

      {sb.fehler && <p className="text-xs text-rose-600">{sb.fehler}</p>}

      {/* Abgeleitet */}
      <div>
        <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('stamm.abgeleitet')}</p>
        {verwandte.length ? (
          <div className="flex flex-wrap gap-2">
            {verwandte.map(v => (
              <span key={v.id + v.bezeichnung}
                    className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs ${
                      v.gruppe === 'angeheiratet' ? 'bg-stone-50 text-stone-400' : 'bg-stone-100 text-stone-600'}`}>
                {name(v.id, sb.namen.get(v.id) ?? '…')}
                <span className="opacity-70">{v.bezeichnung}</span>
              </span>
            ))}
          </div>
        ) : <p className="text-xs text-stone-400">{t('stamm.keine_abgeleiteten')}</p>}
      </div>

      {!nurLesen && direkt.length > 0 && (
        <button onClick={allesLoesen} disabled={sb.arbeitet}
                className="inline-flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-bold text-rose-600 bg-rose-50 hover:bg-rose-100">
          <UserMinus size={14} /> {t('stamm.herausnehmen')}
        </button>
      )}
    </div>
  );
};

export default StammbaumPerson;
