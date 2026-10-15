import React, { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  X, Mail, Send, Loader2, AlertTriangle, Search, Users, CheckCircle2,
  Clock, Gauge, UserX,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { empfaengerAufbereiten } from '../lib/vorstandsmail';
import { alsHtml } from '../lib/textbaustein';
import type { UserProfile, Neighborhood } from '../types';

// Der Postausgang des Vorstands.
//
// Drei Dinge muessen VOR dem Senden dastehen, nicht danach:
//
//   an wie viele es geht, und wer keine Adresse hat
//   woran der Empfaenger erkennt, wer schreibt, und wohin er antwortet
//   wie viel heute noch hinausgehen darf
//
// Das letzte ist keine Gaengelung. Alle Vereine gehen ueber denselben
// Postausgang; ein unbedachter Lauf verschlechtert die Zustellung fuer
// alle, und zwar ueber Wochen. Was heute nicht mehr hineingeht, wird auf
// die Folgetage verteilt und nicht verworfen -- und das steht hier,
// bevor jemand auf Senden drueckt.

type Props = {
  mitglieder: UserProfile[];
  nachbarschaften?: Neighborhood[];
  onClose: () => void;
};

type Absender = {
  darf: boolean; name?: string; verein?: string;
  adresse?: string | null; antwort_an?: string | null;
  eigene_adresse?: boolean; darf_schreiben?: boolean;
};

type Grenze = {
  darf: boolean; decke?: number;
  grenze_verein?: number; verbraucht_verein?: number; rest_verein?: number;
  grenze_person?: number; verbraucht_person?: number; rest_person?: number;
  rest?: number;
};

const VorstandPostausgang: React.FC<Props> = ({ mitglieder, nachbarschaften, onClose }) => {
  const { t } = useTranslation();
  const [absender, setAbsender] = useState<Absender | null>(null);
  const [grenze, setGrenze] = useState<Grenze | null>(null);
  const [alle, setAlle] = useState(false);
  const [gewaehlt, setGewaehlt] = useState<Set<string>>(new Set());
  const [suche, setSuche] = useState('');
  const [nbFilter, setNbFilter] = useState('');
  const [betreff, setBetreff] = useState('');
  const [text, setText] = useState('');
  const [sendet, setSendet] = useState(false);
  const [fehler, setFehler] = useState('');
  const [ergebnis, setErgebnis] = useState<any>(null);

  useEffect(() => {
    Promise.all([
      supabase.rpc('vorstand_absender'),
      supabase.rpc('mail_grenze_heute'),
    ]).then(([a, g]) => {
      setAbsender((a.data as Absender) ?? null);
      setGrenze((g.data as Grenze) ?? null);
    }).catch(() => { /* die Maske sagt es unten */ });
  }, []);

  // Wer steht zur Auswahl? Die Liste folgt Suche und Nachbarschaft; die
  // AUSWAHL selbst bleibt davon unberuehrt -- wer gewaehlt ist und durch
  // eine Suche aus der Liste faellt, bleibt gewaehlt. Anders waere es
  // eine Falle: man tippt, und die Haelfte der Empfaenger ist fort.
  const sichtbar = useMemo(() => {
    const s = suche.trim().toLowerCase();
    return (mitglieder ?? []).filter(m => {
      if (String((m as any)?.membershipStatus ?? '') === 'INACTIVE') return false;
      if (nbFilter && (m as any)?.neighborhoodId !== nbFilter) return false;
      if (!s) return true;
      return [(m as any)?.displayName, (m as any)?.email, (m as any)?.city]
        .some(v => String(v ?? '').toLowerCase().includes(s));
    });
  }, [mitglieder, suche, nbFilter]);

  const aufbereitet = useMemo(
    () => empfaengerAufbereiten(mitglieder, alle ? null : gewaehlt),
    [mitglieder, alle, gewaehlt]);

  const anzahl = aufbereitet.erreichbar.length;
  const rest = grenze?.rest ?? 0;
  const proTag = Math.min(grenze?.grenze_verein ?? 0, grenze?.grenze_person ?? 0);
  const heute = Math.min(anzahl, rest);
  const spaeter = Math.max(anzahl - rest, 0);
  const tage = spaeter > 0 && proTag > 0 ? Math.ceil(spaeter / proTag) : 0;

  const umschalten = (id: string) => {
    const n = new Set(gewaehlt);
    n.has(id) ? n.delete(id) : n.add(id);
    setGewaehlt(n);
    setAlle(false);
  };

  const senden = async () => {
    setFehler(''); setErgebnis(null);
    if (!betreff.trim() || !text.trim()) { setFehler(t('vpost.fehlt_text')); return; }
    if (anzahl === 0) { setFehler(t('vpost.fehlt_empfaenger')); return; }
    setSendet(true);
    const { data, error } = await supabase.rpc('vorstand_mail_einreihen', {
      p_mitglieder: aufbereitet.erreichbar.map(e => e.id),
      p_betreff: betreff.trim(),
      p_html: alsHtml(text),
    });
    setSendet(false);
    if (error) { setFehler(error.message); return; }
    setErgebnis(data);
    supabase.rpc('mail_grenze_heute').then(({ data: g }) => setGrenze(g as Grenze));
  };

  return (
    <div className="fixed inset-0 z-[70] bg-stone-900/50 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-6">
      <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }}
        className="bg-white w-full sm:max-w-4xl max-h-[92vh] rounded-t-[2rem] sm:rounded-[2rem] shadow-2xl flex flex-col overflow-hidden">

        <div className="p-6 border-b border-stone-100 flex items-start justify-between gap-4">
          <div>
            <h2 className="font-display text-2xl font-bold text-stone-900 flex items-center gap-2">
              <Mail size={20} className="text-primary" /> {t('vpost.titel')}
            </h2>
            {absender && (
              <p className="text-xs text-stone-500 mt-1">
                {absender.eigene_adresse
                  ? t('vpost.absender_mit', { name: absender.name, adresse: absender.antwort_an })
                  : t('vpost.absender_ohne', { name: absender.name, adresse: absender.antwort_an })}
              </p>
            )}
          </div>
          <button onClick={onClose} className="p-2 rounded-xl hover:bg-stone-100 text-stone-400">
            <X size={20} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-5">
          {absender && absender.darf_schreiben === false && (
            <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl text-sm text-amber-900">
              {t('vpost.kein_schreibrecht')}
            </div>
          )}

          {/* Die Tagesgrenze. Steht oben, weil sie entscheidet, was
              ueberhaupt passiert. */}
          {grenze?.darf && (
            <div className="p-4 bg-stone-900 rounded-2xl text-stone-300 flex items-start gap-3">
              <Gauge size={18} className="shrink-0 mt-0.5 text-stone-500" />
              <div className="text-xs leading-relaxed">
                <p className="text-white font-bold">
                  {t('vpost.grenze_titel', { rest, grenze: proTag })}
                </p>
                <p className="mt-1">
                  {t('vpost.grenze_text', {
                    verein: grenze.grenze_verein, person: grenze.grenze_person })}
                </p>
              </div>
            </div>
          )}

          {/* Empfaenger */}
          <div>
            <div className="flex items-center justify-between gap-3 flex-wrap mb-3">
              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                {t('vpost.empfaenger')}
              </label>
              <div className="flex gap-2">
                <button onClick={() => { setAlle(true); setGewaehlt(new Set()); }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold ${alle ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-600 hover:bg-stone-200'}`}>
                  <Users size={12} className="inline mr-1" />{t('vpost.alle')}
                </button>
                <button onClick={() => setAlle(false)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold ${!alle ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-600 hover:bg-stone-200'}`}>
                  {t('vpost.auswahl', { anzahl: gewaehlt.size })}
                </button>
              </div>
            </div>

            {!alle && (
              <>
                <div className="flex gap-2 mb-2 flex-wrap">
                  <div className="relative flex-1 min-w-[12rem]">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={14} />
                    <input value={suche} onChange={e => setSuche(e.target.value)}
                      placeholder={t('common.search')}
                      className="w-full pl-9 pr-3 py-2 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-400" />
                  </div>
                  {(nachbarschaften?.length ?? 0) > 0 && (
                    <select value={nbFilter} onChange={e => setNbFilter(e.target.value)}
                      className="px-3 py-2 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none">
                      <option value="">{t('vpost.alle_nachbarschaften')}</option>
                      {(nachbarschaften ?? []).map(n => (
                        <option key={(n as any).id} value={(n as any).id}>{(n as any).name}</option>
                      ))}
                    </select>
                  )}
                </div>
                <div className="max-h-56 overflow-y-auto border border-stone-200 rounded-xl divide-y divide-stone-50">
                  {sichtbar.length === 0 && (
                    <p className="p-4 text-xs text-stone-400 text-center">{t('vpost.niemand_gefunden')}</p>
                  )}
                  {sichtbar.map(m => {
                    const id = String((m as any).id);
                    const mail = String((m as any).email ?? '').trim();
                    return (
                      <label key={id} className="flex items-center gap-3 px-4 py-2 hover:bg-stone-50 cursor-pointer">
                        <input type="checkbox" checked={gewaehlt.has(id)} onChange={() => umschalten(id)} />
                        <span className="text-sm text-stone-800 flex-1 truncate">{(m as any).displayName}</span>
                        <span className={`text-xs truncate max-w-[12rem] ${mail ? 'text-stone-400' : 'text-amber-600 font-bold'}`}>
                          {mail || t('vpost.ohne_adresse_kurz')}
                        </span>
                      </label>
                    );
                  })}
                </div>
              </>
            )}

            {/* Was jetzt wirklich passiert. Diese Zeile ist der Grund,
                dass es die Maske gibt: "verschickt" nach einem Lauf, der
                56 Mitglieder uebersprungen hat, ist eine Falschmeldung. */}
            <div className="mt-3 text-xs space-y-1">
              <p className="text-stone-700 font-bold">
                {t('vpost.geht_an', { anzahl })}
                {spaeter > 0 && ' — ' + t('vpost.verteilt', { heute, spaeter, tage })}
              </p>
              {aufbereitet.ohne_adresse.length > 0 && (
                <details className="text-amber-700">
                  <summary className="cursor-pointer font-bold flex items-center gap-1">
                    <UserX size={12} />
                    {t('vpost.ohne_adresse', { anzahl: aufbereitet.ohne_adresse.length })}
                  </summary>
                  <p className="mt-1 text-amber-700/80 leading-relaxed">
                    {aufbereitet.ohne_adresse.map(o => o.name).join(', ')}
                  </p>
                </details>
              )}
            </div>
          </div>

          {/* Der Brief */}
          <div className="space-y-3">
            <div>
              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">
                {t('vpost.betreff')}
              </label>
              <input value={betreff} onChange={e => setBetreff(e.target.value)}
                className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-400 font-bold" />
            </div>
            <div>
              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">
                {t('vpost.text')}
              </label>
              <textarea rows={8} value={text} onChange={e => setText(e.target.value)}
                placeholder={t('vpost.text_ph')}
                className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-400 leading-relaxed" />
              <p className="text-[11px] text-stone-400 mt-1">{t('vpost.text_hinweis')}</p>
            </div>
          </div>

          {fehler && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-sm text-red-800 flex gap-3">
              <AlertTriangle size={18} className="shrink-0 mt-0.5" /><span>{fehler}</span>
            </div>
          )}

          {ergebnis && (
            <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-sm text-emerald-900 space-y-1">
              <p className="flex items-center gap-2 font-bold">
                <CheckCircle2 size={16} />
                {t('vpost.fertig', { anzahl: ergebnis.eingereiht })}
              </p>
              {Number(ergebnis.spaeter) > 0 && (
                <p className="flex items-center gap-2 text-xs">
                  <Clock size={13} />
                  {t('vpost.fertig_verteilt', {
                    heute: ergebnis.heute, spaeter: ergebnis.spaeter,
                    datum: new Date(ergebnis.fertig_am).toLocaleDateString('de-CH') })}
                </p>
              )}
              {Number(ergebnis.ohne_adresse) > 0 && (
                <p className="text-xs">{t('vpost.fertig_ohne', { anzahl: ergebnis.ohne_adresse })}</p>
              )}
              {Number(ergebnis.schon_offen) > 0 && (
                <p className="text-xs">{t('vpost.fertig_doppelt', { anzahl: ergebnis.schon_offen })}</p>
              )}
              <p className="text-xs text-emerald-800/70">
                {t('vpost.fertig_antwort', { adresse: ergebnis.antwort_an })}
              </p>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-stone-100 bg-stone-50 flex justify-between items-center gap-3 flex-wrap">
          <p className="text-[11px] text-stone-400 max-w-sm leading-relaxed">
            {t('vpost.fuss')}
          </p>
          <div className="flex gap-3">
            <button onClick={onClose}
              className="px-6 py-3 rounded-xl font-bold text-stone-500 hover:bg-stone-200 text-sm">
              {t('common.cancel')}
            </button>
            <button onClick={senden}
              disabled={sendet || anzahl === 0 || !betreff.trim() || !text.trim()
                        || absender?.darf_schreiben === false}
              className="px-8 py-3 bg-primary text-white rounded-xl font-bold shadow-lg hover:scale-105 transition-all text-sm flex items-center gap-2 disabled:opacity-40 disabled:hover:scale-100">
              {sendet ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
              {t('vpost.senden', { anzahl })}
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default VorstandPostausgang;
