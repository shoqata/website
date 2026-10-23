import React, { useEffect, useMemo, useState } from 'react';
import {
  MessageSquare, X, Loader2, CheckCircle2, XCircle, Hourglass, Hand, RotateCcw, Flag,
  Plus, Trash2, Square, CheckSquare, User, CalendarClock, History, Send, StickyNote, Mail, ChevronRight,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

// Anfragen & Feedback -- bearbeitet vom Vorstand: annehmen, warten,
// genehmigen, ablehnen, erledigen; dazu naechste Schritte und Verlauf.
//
// Jede Aktion geht ueber anfrage_aktion() in der Datenbank. Die prueft das
// Recht, verlangt bei einer Ablehnung die Begruendung und schreibt den
// Verlauf -- die Maske zeigt nur an und fragt nach.
//
// Was das Mitglied sieht: Status, Antwort, Entscheid und worauf gewartet
// wird. Schritte, Notizen und Verlauf bleiben im Vorstand.

type Status = 'OPEN' | 'IN_PROGRESS' | 'WAITING' | 'APPROVED' | 'REJECTED' | 'DONE';
type Anfrage = {
  id: string; userId?: string; userName?: string; email?: string; type: string;
  subject: string; message: string; status: Status; adminNote?: string | null;
  zustaendig?: string | null; wartenAuf?: string | null; wartenBis?: string | null;
  entscheid?: string | null; entscheidVon?: string | null; entscheidAm?: string | null;
  createdAt: string; updatedAt?: string | null;
};
type Schritt = { id: string; anfrage: string; text: string; zustaendig: string | null; faellig: string | null; erledigt_am: string | null };
type Eintrag = { id: string; art: string; status: string | null; text: string | null; von_name: string | null; am: string };
type Aktion = 'ANNEHMEN' | 'WARTEN' | 'GENEHMIGEN' | 'ABLEHNEN' | 'ERLEDIGT' | 'WIEDER_OEFFNEN';

export const STATUS_FARBE: Record<string, string> = {
  OPEN: 'bg-rose-100 text-rose-700',
  IN_PROGRESS: 'bg-blue-100 text-blue-700',
  WAITING: 'bg-amber-100 text-amber-800',
  APPROVED: 'bg-emerald-100 text-emerald-700',
  REJECTED: 'bg-stone-200 text-stone-700',
  DONE: 'bg-stone-100 text-stone-500',
};

const FILTER: { k: string; s: Status[] }[] = [
  { k: 'anf.f_todo', s: ['OPEN', 'IN_PROGRESS', 'WAITING'] },
  { k: 'anf.f_new', s: ['OPEN'] },
  { k: 'anf.f_waiting', s: ['WAITING'] },
  { k: 'anf.f_decided', s: ['APPROVED', 'REJECTED', 'DONE'] },
  { k: 'anf.f_all', s: ['OPEN', 'IN_PROGRESS', 'WAITING', 'APPROVED', 'REJECTED', 'DONE'] },
];

// Was in welchem Status als Naechstes moeglich ist.
const MOEGLICH: Record<Status, Aktion[]> = {
  OPEN: ['ANNEHMEN', 'WARTEN', 'GENEHMIGEN', 'ABLEHNEN'],
  IN_PROGRESS: ['GENEHMIGEN', 'ABLEHNEN', 'WARTEN', 'ERLEDIGT'],
  WAITING: ['ANNEHMEN', 'GENEHMIGEN', 'ABLEHNEN'],
  APPROVED: ['ERLEDIGT', 'WIEDER_OEFFNEN'],
  REJECTED: ['WIEDER_OEFFNEN'],
  DONE: ['WIEDER_OEFFNEN'],
};
const AKTION: Record<Aktion, { I: any; stil: string }> = {
  ANNEHMEN: { I: Hand, stil: 'bg-blue-600 text-white hover:bg-blue-700' },
  WARTEN: { I: Hourglass, stil: 'bg-amber-100 text-amber-900 hover:bg-amber-200' },
  GENEHMIGEN: { I: CheckCircle2, stil: 'bg-emerald-600 text-white hover:bg-emerald-700' },
  ABLEHNEN: { I: XCircle, stil: 'bg-white border border-rose-200 text-rose-700 hover:bg-rose-50' },
  ERLEDIGT: { I: Flag, stil: 'bg-stone-900 text-white hover:bg-stone-700' },
  WIEDER_OEFFNEN: { I: RotateCcw, stil: 'bg-stone-100 text-stone-700 hover:bg-stone-200' },
};
// Diese Aktionen fragen erst nach einem Text.
const MIT_TEXT: Aktion[] = ['WARTEN', 'GENEHMIGEN', 'ABLEHNEN'];

const datum = (v?: string | null) => v ? new Date(v).toLocaleDateString('de-CH') : '';
const zeit = (v?: string | null) => v ? new Date(v).toLocaleString('de-CH', { dateStyle: 'short', timeStyle: 'short' }) : '';
const heute = () => new Date().toISOString().slice(0, 10);

// breit: ueber die ganze Seite, Liste zweispaltig, Hoehe nach Inhalt (bis
// zu einer Grenze) -- so steht sie oben im Vorstandsbereich, ohne bei
// "nichts zu tun" eine leere Flaeche zu hinterlassen.
const AnfragenBearbeiten: React.FC<{ breit?: boolean }> = ({ breit }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [anfragen, setAnfragen] = useState<Anfrage[] | null>(null);
  const [schritte, setSchritte] = useState<Schritt[]>([]);
  const [vorstand, setVorstand] = useState<{ id: string; name: string }[]>([]);
  const [filter, setFilter] = useState(0);
  const [offenId, setOffenId] = useState<string | null>(null);

  const laden = async () => {
    const [a, s] = await Promise.all([
      supabase.from('inquiries').select('*').order('createdAt', { ascending: false }),
      supabase.from('anfrage_schritte').select('*').order('erstellt_am'),
    ]);
    setAnfragen(((a.data as any[]) || []) as Anfrage[]);
    setSchritte(((s.data as any[]) || []) as Schritt[]);
  };
  useEffect(() => {
    laden();
    supabase.from('users').select('id,displayName,firstName,lastName,role').in('role', ['SUPER_ADMIN', 'ADMIN', 'BOARD'])
      .then(({ data }) => setVorstand(((data as any[]) || []).map(u => ({
        id: u.id, name: u.displayName || `${u.firstName || ''} ${u.lastName || ''}`.trim() || u.id,
      })).sort((x, y) => x.name.localeCompare(y.name))));
  }, []);

  const name = (id?: string | null) => (id && vorstand.find(v => v.id === id)?.name) || '';
  const zahl = (s: Status[]) => (anfragen || []).filter(a => s.includes(a.status)).length;
  const sichtbar = useMemo(() => (anfragen || []).filter(a => FILTER[filter].s.includes(a.status)), [anfragen, filter]);
  const offen = (anfragen || []).find(a => a.id === offenId) || null;

  return (
    <div className={`bg-white p-6 md:p-8 rounded-[2.5rem] border border-stone-100 shadow-sm ${breit ? 'max-h-[640px]' : 'h-[600px]'} flex flex-col`}>
      <div className="flex items-center justify-between gap-3 mb-4">
        <h3 className="text-xl font-bold flex items-center gap-2"><MessageSquare size={20} className="text-blue-500" /> {t('board.inquiries')}</h3>
        {zahl(['OPEN']) > 0 && (
          <span className="text-[11px] font-bold bg-rose-100 text-rose-700 px-2.5 py-1 rounded-full">{t('anf.new_count', { count: zahl(['OPEN']) })}</span>
        )}
      </div>

      <div className="flex gap-1.5 overflow-x-auto pb-3 -mx-1 px-1">
        {FILTER.map((f, i) => (
          <button key={f.k} onClick={() => setFilter(i)}
            className={`shrink-0 px-3 py-1.5 rounded-xl text-xs font-bold transition-colors ${filter === i ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-500 hover:bg-stone-200'}`}>
            {t(f.k)} <span className="opacity-60 ml-0.5">{zahl(f.s)}</span>
          </button>
        ))}
      </div>

      <div className={`overflow-y-auto custom-scrollbar flex-1 min-h-0 pr-1 ${breit ? 'grid lg:grid-cols-2 gap-2.5 content-start' : 'space-y-2.5'}`}>
        {anfragen === null && <div className="flex justify-center py-10 lg:col-span-2"><Loader2 className="animate-spin text-stone-300" /></div>}
        {anfragen !== null && sichtbar.length === 0 && (
          <p className="text-stone-400 italic text-center py-10 text-sm lg:col-span-2">{filter === 0 ? t('anf.nothing_todo') : t('board.no_inquiries')}</p>
        )}
        {sichtbar.map(a => {
          const offeneSchritte = schritte.filter(s => s.anfrage === a.id && !s.erledigt_am);
          const ueberfaellig = a.status === 'WAITING' && a.wartenBis && a.wartenBis < heute();
          return (
            <button key={a.id} onClick={() => setOffenId(a.id)}
              className="w-full text-left p-4 rounded-2xl bg-stone-50 border border-stone-100 hover:bg-white hover:shadow-md hover:border-stone-200 transition-all group">
              <div className="flex items-center gap-2 mb-1.5 flex-wrap">
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${STATUS_FARBE[a.status] || 'bg-stone-100'}`}>{t(`req.status.${a.status}`)}</span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-white border border-stone-200 text-stone-500 uppercase">{t(`req.type.${a.type}`)}</span>
                <span className="text-[11px] text-stone-400 ml-auto">{datum(a.createdAt)}</span>
              </div>
              <div className="flex items-start gap-2">
                <div className="min-w-0 flex-1">
                  <h5 className="font-bold text-sm text-stone-900 truncate">{a.subject}</h5>
                  <p className="text-xs text-stone-500 truncate">{a.userName}{a.zustaendig ? ` · ${t('anf.assigned_short')}: ${name(a.zustaendig)}` : ''}</p>
                  {a.status === 'WAITING' && a.wartenAuf && (
                    <p className={`text-[11px] mt-1 flex items-center gap-1 ${ueberfaellig ? 'text-rose-600 font-bold' : 'text-amber-700'}`}>
                      <Hourglass size={11} /> {a.wartenAuf}{a.wartenBis ? ` · ${t('anf.until')} ${datum(a.wartenBis)}` : ''}
                    </p>
                  )}
                  {offeneSchritte.length > 0 && (
                    <p className="text-[11px] mt-1 text-stone-500 flex items-center gap-1"><Square size={11} /> {t('anf.open_steps', { count: offeneSchritte.length })}</p>
                  )}
                </div>
                <ChevronRight size={16} className="text-stone-300 group-hover:text-stone-500 shrink-0 mt-1" />
              </div>
            </button>
          );
        })}
      </div>

      <AnimatePresence>
        {offen && (
          <Detail anfrage={offen} schritte={schritte.filter(s => s.anfrage === offen.id)} vorstand={vorstand} name={name}
            onClose={() => setOffenId(null)} neuLaden={laden} fehler={(m) => showAlert({ type: 'error', message: m })} />
        )}
      </AnimatePresence>
    </div>
  );
};

const Detail: React.FC<{
  anfrage: Anfrage; schritte: Schritt[]; vorstand: { id: string; name: string }[];
  name: (id?: string | null) => string; onClose: () => void; neuLaden: () => Promise<void>; fehler: (m: string) => void;
}> = ({ anfrage: a, schritte, vorstand, name, onClose, neuLaden, fehler }) => {
  const { t } = useTranslation();
  const [verlauf, setVerlauf] = useState<Eintrag[] | null>(null);
  const [laeuft, setLaeuft] = useState(false);
  const [frage, setFrage] = useState<Aktion | null>(null);
  const [text, setText] = useState('');
  const [bis, setBis] = useState('');
  const [antwort, setAntwort] = useState(a.adminNote || '');
  const [notiz, setNotiz] = useState('');
  const [schritt, setSchritt] = useState({ text: '', zustaendig: '', faellig: '' });

  const verlaufLaden = () => supabase.from('anfrage_verlauf').select('*').eq('anfrage', a.id).order('am', { ascending: false })
    .then(({ data }) => setVerlauf(((data as any[]) || []) as Eintrag[]));
  useEffect(() => { verlaufLaden(); }, [a.id]);
  useEffect(() => { setAntwort(a.adminNote || ''); }, [a.adminNote]);

  const rufen = async (fn: string, args: any) => {
    setLaeuft(true);
    const { error } = await supabase.rpc(fn, args);
    setLaeuft(false);
    if (error) { fehler(error.message); return false; }
    await Promise.all([neuLaden(), verlaufLaden()]);
    return true;
  };
  const aktion = async (ak: Aktion | 'ANTWORT' | 'NOTIZ' | 'ZUSTAENDIG', txt?: string, datum?: string) =>
    rufen('anfrage_aktion', { p_id: a.id, p_aktion: ak, p_text: txt ?? null, p_bis: datum || null });

  const starten = (ak: Aktion) => {
    if (MIT_TEXT.includes(ak)) {
      setFrage(ak); setText(ak === 'WARTEN' ? (a.wartenAuf || '') : ''); setBis(ak === 'WARTEN' ? (a.wartenBis || '') : '');
    } else aktion(ak);
  };
  const bestaetigen = async () => {
    if (!frage) return;
    if ((frage === 'ABLEHNEN' || frage === 'WARTEN') && !text.trim()) return;
    if (await aktion(frage, text, frage === 'WARTEN' ? bis : undefined)) { setFrage(null); setText(''); setBis(''); }
  };

  const offeneSchritte = schritte.filter(s => !s.erledigt_am);
  const erledigteSchritte = schritte.filter(s => s.erledigt_am);

  return (
    <div className="fixed inset-0 z-[200] flex items-end md:items-center justify-center md:p-6 bg-stone-900/60 backdrop-blur-sm" onClick={onClose}>
      <motion.div initial={{ y: 30, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 30, opacity: 0 }}
        onClick={e => e.stopPropagation()}
        className="bg-white w-full max-w-3xl max-h-[92vh] overflow-y-auto rounded-t-[2rem] md:rounded-[2.5rem] shadow-2xl">

        {/* Kopf */}
        <div className="sticky top-0 bg-white/95 backdrop-blur z-10 px-6 md:px-8 pt-6 pb-4 border-b border-stone-100">
          <div className="flex items-start gap-3">
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2 mb-2 flex-wrap">
                <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${STATUS_FARBE[a.status]}`}>{t(`req.status.${a.status}`)}</span>
                <span className="text-[10px] font-bold px-2 py-1 rounded bg-stone-100 text-stone-500 uppercase">{t(`req.type.${a.type}`)}</span>
              </div>
              <h3 className="text-xl md:text-2xl font-bold text-stone-900">{a.subject}</h3>
              <p className="text-xs text-stone-500 mt-1 flex items-center gap-3 flex-wrap">
                <span className="flex items-center gap-1"><User size={12} /> {a.userName}</span>
                {a.email && <a href={`mailto:${a.email}`} className="flex items-center gap-1 hover:text-primary"><Mail size={12} /> {a.email}</a>}
                <span>{zeit(a.createdAt)}</span>
              </p>
            </div>
            <button onClick={onClose} className="p-2 bg-stone-50 rounded-full hover:bg-stone-100 text-stone-500 shrink-0"><X size={20} /></button>
          </div>

          {/* Aktionen */}
          <div className="flex flex-wrap gap-2 mt-4">
            {MOEGLICH[a.status]?.map(ak => {
              const { I, stil } = AKTION[ak];
              return (
                <button key={ak} disabled={laeuft} onClick={() => starten(ak)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-colors disabled:opacity-50 ${stil} ${frage === ak ? 'ring-2 ring-offset-1 ring-stone-900' : ''}`}>
                  <I size={14} /> {t(`anf.act.${ak}`)}
                </button>
              );
            })}
            {laeuft && <Loader2 size={16} className="animate-spin text-stone-400 self-center" />}
          </div>

          {frage && (
            <div className="mt-3 p-4 rounded-2xl bg-stone-50 border border-stone-200 space-y-3">
              <label className="block text-xs font-bold text-stone-700">{t(`anf.ask.${frage}`)}</label>
              <textarea value={text} onChange={e => setText(e.target.value)} rows={3} autoFocus
                className="w-full p-3 rounded-xl border border-stone-200 text-sm outline-none focus:border-stone-400 bg-white" />
              {frage === 'WARTEN' && (
                <label className="flex items-center gap-2 text-xs text-stone-600">
                  <CalendarClock size={14} /> {t('anf.until')}
                  <input type="date" value={bis} onChange={e => setBis(e.target.value)} className="p-2 rounded-lg border border-stone-200 text-sm bg-white" />
                </label>
              )}
              <p className="text-[11px] text-stone-400">{t('anf.member_sees')}</p>
              <div className="flex gap-2 justify-end">
                <button onClick={() => setFrage(null)} className="px-4 py-2 rounded-xl text-xs font-bold text-stone-500 hover:bg-stone-100">{t('common.cancel')}</button>
                <button onClick={bestaetigen} disabled={laeuft || ((frage === 'ABLEHNEN' || frage === 'WARTEN') && !text.trim())}
                  className={`px-4 py-2 rounded-xl text-xs font-bold disabled:opacity-40 ${AKTION[frage].stil}`}>{t(`anf.act.${frage}`)}</button>
              </div>
            </div>
          )}
        </div>

        <div className="px-6 md:px-8 py-6 grid md:grid-cols-5 gap-6">
          {/* Links: Anliegen, Entscheid, Antwort */}
          <div className="md:col-span-3 space-y-5">
            <div className="bg-stone-50 p-4 rounded-2xl text-sm text-stone-700 leading-relaxed whitespace-pre-wrap">{a.message}</div>

            {(a.status === 'APPROVED' || a.status === 'REJECTED' || a.entscheid) && a.entscheidAm && (
              <div className={`p-4 rounded-2xl border ${a.status === 'REJECTED' ? 'bg-rose-50/50 border-rose-100' : 'bg-emerald-50/50 border-emerald-100'}`}>
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mb-1">{t('anf.decision')}</p>
                <p className="text-sm text-stone-800 whitespace-pre-wrap">{a.entscheid || t(`req.status.${a.status}`)}</p>
                <p className="text-[11px] text-stone-400 mt-2">{name(a.entscheidVon)} · {zeit(a.entscheidAm)}</p>
              </div>
            )}

            {a.status === 'WAITING' && a.wartenAuf && (
              <div className="p-4 rounded-2xl bg-amber-50 border border-amber-100">
                <p className="text-[10px] font-bold uppercase tracking-widest text-amber-700 mb-1">{t('anf.waiting_for')}</p>
                <p className="text-sm text-stone-800">{a.wartenAuf}</p>
                {a.wartenBis && <p className={`text-[11px] mt-1 ${a.wartenBis < heute() ? 'text-rose-600 font-bold' : 'text-amber-700'}`}>{t('anf.until')} {datum(a.wartenBis)}</p>}
              </div>
            )}

            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mb-2 flex items-center gap-1.5"><Send size={12} /> {t('anf.reply')}</p>
              <textarea value={antwort} onChange={e => setAntwort(e.target.value)} rows={3} placeholder={t('anf.reply_ph')}
                className="w-full p-3 rounded-xl border border-stone-200 text-sm outline-none focus:border-stone-400" />
              <div className="flex items-center justify-between mt-1.5">
                <p className="text-[11px] text-stone-400">{t('anf.reply_hint')}</p>
                <button disabled={laeuft || antwort === (a.adminNote || '')} onClick={() => aktion('ANTWORT', antwort)}
                  className="px-3 py-1.5 rounded-lg bg-stone-900 text-white text-[11px] font-bold disabled:opacity-30">{t('common.save')}</button>
              </div>
            </div>
          </div>

          {/* Rechts: Zustaendig, Schritte */}
          <div className="md:col-span-2 space-y-5">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mb-2">{t('anf.assigned')}</p>
              <select value={a.zustaendig || ''} disabled={laeuft}
                onChange={e => aktion('ZUSTAENDIG', e.target.value)}
                className="w-full p-2.5 rounded-xl border border-stone-200 text-sm bg-white">
                <option value="">{t('anf.nobody')}</option>
                {vorstand.map(v => <option key={v.id} value={v.id}>{v.name}</option>)}
              </select>
            </div>

            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mb-2">{t('anf.next_steps')}</p>
              <div className="space-y-1.5">
                {offeneSchritte.length === 0 && erledigteSchritte.length === 0 && (
                  <p className="text-xs text-stone-400 italic">{t('anf.no_steps')}</p>
                )}
                {[...offeneSchritte, ...erledigteSchritte].map(s => {
                  const faellig = !s.erledigt_am && s.faellig && s.faellig < heute();
                  return (
                    <div key={s.id} className="flex items-start gap-2 p-2 rounded-xl hover:bg-stone-50 group">
                      <button disabled={laeuft} onClick={() => rufen('anfrage_schritt_setzen', { p_schritt: s.id, p_aktion: s.erledigt_am ? 'OFFEN' : 'ERLEDIGT' })}
                        className="mt-0.5 text-stone-400 hover:text-emerald-600 shrink-0">
                        {s.erledigt_am ? <CheckSquare size={16} className="text-emerald-600" /> : <Square size={16} />}
                      </button>
                      <div className="min-w-0 flex-1">
                        <p className={`text-sm ${s.erledigt_am ? 'line-through text-stone-400' : 'text-stone-800'}`}>{s.text}</p>
                        {(s.zustaendig || s.faellig) && (
                          <p className={`text-[11px] ${faellig ? 'text-rose-600 font-bold' : 'text-stone-400'}`}>
                            {name(s.zustaendig)}{s.zustaendig && s.faellig ? ' · ' : ''}{s.faellig ? datum(s.faellig) : ''}
                          </p>
                        )}
                      </div>
                      <button disabled={laeuft} onClick={() => rufen('anfrage_schritt_setzen', { p_schritt: s.id, p_aktion: 'LOESCHEN' })}
                        className="p-1 text-stone-300 hover:text-rose-600 opacity-0 group-hover:opacity-100 shrink-0" aria-label={t('common.delete')}><Trash2 size={13} /></button>
                    </div>
                  );
                })}
              </div>
              <div className="mt-2 p-3 rounded-2xl border border-dashed border-stone-200 space-y-2">
                <input value={schritt.text} onChange={e => setSchritt({ ...schritt, text: e.target.value })} placeholder={t('anf.step_ph')}
                  onKeyDown={e => { if (e.key === 'Enter' && schritt.text.trim()) (document.getElementById('anf-schritt-add') as HTMLButtonElement)?.click(); }}
                  className="w-full p-2 rounded-lg border border-stone-200 text-sm outline-none focus:border-stone-400" />
                <div className="flex gap-2">
                  <select value={schritt.zustaendig} onChange={e => setSchritt({ ...schritt, zustaendig: e.target.value })}
                    className="flex-1 min-w-0 p-2 rounded-lg border border-stone-200 text-xs bg-white">
                    <option value="">{t('anf.who')}</option>
                    {vorstand.map(v => <option key={v.id} value={v.id}>{v.name}</option>)}
                  </select>
                  <input type="date" value={schritt.faellig} onChange={e => setSchritt({ ...schritt, faellig: e.target.value })}
                    className="p-2 rounded-lg border border-stone-200 text-xs bg-white" />
                  <button id="anf-schritt-add" disabled={laeuft || !schritt.text.trim()}
                    onClick={async () => {
                      if (await rufen('anfrage_schritt', { p_anfrage: a.id, p_text: schritt.text, p_zustaendig: schritt.zustaendig || null, p_faellig: schritt.faellig || null }))
                        setSchritt({ text: '', zustaendig: '', faellig: '' });
                    }}
                    className="px-3 rounded-lg bg-stone-900 text-white disabled:opacity-30 shrink-0" aria-label={t('anf.add_step')}><Plus size={15} /></button>
                </div>
              </div>
            </div>
          </div>

          {/* Verlauf, ueber die ganze Breite */}
          <div className="md:col-span-5 border-t border-stone-100 pt-5">
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500 mb-3 flex items-center gap-1.5"><History size={12} /> {t('anf.history')}</p>
            <div className="flex gap-2 mb-4">
              <input value={notiz} onChange={e => setNotiz(e.target.value)} placeholder={t('anf.note_ph')}
                className="flex-1 min-w-0 p-2.5 rounded-xl border border-stone-200 text-sm outline-none focus:border-stone-400" />
              <button disabled={laeuft || !notiz.trim()} onClick={async () => { if (await aktion('NOTIZ', notiz)) setNotiz(''); }}
                className="px-3 rounded-xl bg-stone-100 text-stone-700 text-xs font-bold flex items-center gap-1.5 disabled:opacity-40 shrink-0"><StickyNote size={14} /> {t('anf.add_note')}</button>
            </div>
            {verlauf === null ? <Loader2 size={16} className="animate-spin text-stone-300" /> : verlauf.length === 0 ? (
              <p className="text-xs text-stone-400 italic">{t('anf.no_history')}</p>
            ) : (
              <ol className="relative border-l-2 border-stone-100 ml-1.5 space-y-3">
                {verlauf.map(e => (
                  <li key={e.id} className="pl-4 relative">
                    <span className={`absolute -left-[7px] top-1 w-3 h-3 rounded-full border-2 border-white ${e.art === 'NOTIZ' ? 'bg-stone-300' : (STATUS_FARBE[e.status || ''] || 'bg-stone-300').split(' ')[0]}`} />
                    <p className="text-xs text-stone-700">
                      <span className="font-bold">{t(`anf.log.${e.art}`)}</span>
                      {e.text ? <span className="text-stone-600">: {e.text}</span> : null}
                    </p>
                    <p className="text-[11px] text-stone-400">{e.von_name} · {zeit(e.am)}</p>
                  </li>
                ))}
              </ol>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default AnfragenBearbeiten;
