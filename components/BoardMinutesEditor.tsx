import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  FileText, X, Save, Loader2, Plus, Trash2, History, ChevronDown, ChevronRight, Users,
  Eye, EyeOff, Download, PenLine,
} from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, updateDoc, setDoc, collection, getDocs, query } from '@/services/supabase-bridge';
import { protokollPdf } from '../lib/protokollPdf';
import { gaesteLaden, gaesteSpeichern, mitGaesten, gueltigeGaeste, gastMailFalsch, gastName, type Gast } from '../lib/protokollGaeste';
import ProtokollGaeste from './ProtokollGaeste';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { BoardMeeting, UserProfile } from '../types';

interface Props {
  meeting: BoardMeeting | null;   // null = neues Protokoll
  open: boolean;
  boardUsers: UserProfile[];
  onClose: (geaendert: boolean) => void;
}

const leeresProtokoll = (): any => ({
  id: '',
  publishedToMembers: false,
  title: '',
  date: new Date().toISOString().slice(0, 10),
  location: '',
  status: 'PLANNED',
  attendees: [],
  protokollfuehrer: null,
  agendaItems: [],
  decisions: [],
  documents: [],
});

// Protokoll einer Vorstandssitzung schreiben und ueberarbeiten.
//
// Jede inhaltliche Aenderung erzeugt eine neue Fassung. Das geschieht in einem
// Ausloeser in der Datenbank, nicht hier -- so entsteht die Fassung auch dann,
// wenn jemand an dieser Maske vorbei schreibt. Der Verlauf ist nur lesbar; eine
// Fassung, die sich nachtraeglich anpassen laesst, belegt nichts.
const BoardMinutesEditor: React.FC<Props> = ({ meeting, open, boardUsers, onClose }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();

  const [form, setForm] = useState<any>(leeresProtokoll());
  const [speichert, setSpeichert] = useState(false);
  const [verlauf, setVerlauf] = useState<any[]>([]);
  const [zeigeVerlauf, setZeigeVerlauf] = useState(false);
  const [offeneFassung, setOffeneFassung] = useState<string | null>(null);
  const [pdfLaeuft, setPdfLaeuft] = useState(false);
  // Gaeste: Name im Protokoll, E-Mail nur in board_meeting_guests (die Tabelle
  // liest nur der Vorstand -- ein freigegebenes Protokoll lesen alle Mitglieder).
  const [gaeste, setGaeste] = useState<Gast[]>([]);

  const istNeu = !meeting?.id;

  useEffect(() => {
    if (!open) return;
    setForm(meeting?.id ? { ...leeresProtokoll(), ...meeting } : leeresProtokoll());
    setZeigeVerlauf(false);
    setOffeneFassung(null);
    setVerlauf([]);
    setGaeste([]);
    if (meeting?.id) {
      gaesteLaden(meeting.id).then(setGaeste);
      (async () => {
        try {
          const snap = await getDocs(query(collection(db, 'board_meeting_versions')));
          const eigene = snap.docs
            .map(d => ({ id: d.id, ...d.data() } as any))
            .filter(v => v.meetingId === meeting.id)
            .sort((a, b) => (b.version || 0) - (a.version || 0));
          setVerlauf(eigene);
        } catch { /* der Verlauf ist eine Zugabe, kein Grund zu scheitern */ }
      })();
    }
  }, [meeting, open]);

  if (!open) return null;

  const setzen = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));

  const listeAendern = (feld: 'agendaItems' | 'decisions', i: number, k: string, v: any) =>
    setForm((f: any) => {
      const liste = [...(f[feld] || [])];
      liste[i] = { ...liste[i], [k]: v };
      return { ...f, [feld]: liste };
    });

  const listeErgaenzen = (feld: 'agendaItems' | 'decisions') =>
    setForm((f: any) => ({
      ...f,
      [feld]: [...(f[feld] || []), {
        id: Math.random().toString(36).slice(2, 11),
        title: '', content: '', responsible: '', dueDate: '',
      }],
    }));

  const listeEntfernen = (feld: 'agendaItems' | 'decisions', i: number) =>
    setForm((f: any) => ({ ...f, [feld]: (f[feld] || []).filter((_: any, j: number) => j !== i) }));

  const anwesenheitUmschalten = (userId: string, name: string, rolle: string) =>
    setForm((f: any) => {
      const liste = [...(f.attendees || [])];
      const i = liste.findIndex((a: any) => a.userId === userId);
      if (i >= 0) liste[i] = { ...liste[i], present: !liste[i].present };
      else liste.push({ userId, name, role: rolle, present: true });
      return { ...f, attendees: liste };
    });

  const istAnwesend = (userId: string) =>
    !!(form.attendees || []).find((a: any) => a.userId === userId)?.present;

  const speichern = async () => {
    if (!form.title?.trim()) { showAlert({ type: 'error', message: t('minutes.title_required') }); return; }
    if (!form.date) { showAlert({ type: 'error', message: t('minutes.date_required') }); return; }

    const gaesteGueltig = gueltigeGaeste(gaeste);
    const falsch = gaesteGueltig.find(gastMailFalsch);
    if (falsch) { showAlert({ type: 'error', message: t('minutes.guest_bad_mail', { name: gastName(falsch) }) }); return; }

    setSpeichert(true);
    try {
      const rumpf = {
        title: form.title.trim(),
        date: form.date,
        location: form.location?.trim() || null,
        status: form.status || 'PLANNED',
        // Gaeste stehen mit Namen unter den Anwesenden (lib/protokollGaeste).
        attendees: mitGaesten(form.attendees, gaesteGueltig),
        protokollfuehrer: form.protokollfuehrer || null,
        agendaItems: form.agendaItems || [],
        decisions: form.decisions || [],
        documents: form.documents || [],
        publishedToMembers: !!form.publishedToMembers,
      };

      if (istNeu) {
        // Die Kennung wird hier vergeben, damit sie im Protokoll steht und
        // sich spaeter darauf verweisen laesst.
        const id = `mtg-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
        await setDoc(doc(db, 'board_meetings', id), { ...rumpf, createdAt: new Date().toISOString() } as any);
        await gaesteSpeichern(id, gaesteGueltig);
        showAlert({ type: 'success', message: t('minutes.created') });
      } else {
        await updateDoc(doc(db, 'board_meetings', meeting!.id), rumpf as any);
        await gaesteSpeichern(meeting!.id, gaesteGueltig);
        showAlert({ type: 'success', message: t('minutes.saved_new_version') });
      }
      onClose(true);
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSpeichert(false);
    }
  };

  // Das Protokoll als PDF.
  //
  // Gesetzt wird echter Text, nicht ein Abbild des Bildschirms. Ein
  // abfotografiertes Fenster laesst sich weder durchsuchen noch kopieren, wird
  // unnoetig gross und bricht an jeder Bildschirmbreite anders um.
  const alsPdf = async () => {
    setPdfLaeuft(true);
    try {
      const p = await protokollPdf({ ...form, version: (meeting as any)?.version ?? 1 }, t);
      const url = URL.createObjectURL(p.blob);
      const el = document.createElement('a');
      el.href = url; el.download = p.dateiname; document.body.appendChild(el); el.click(); el.remove();
      setTimeout(() => URL.revokeObjectURL(url), 5000);
    } catch (e: any) {
      showAlert({ type: 'error', message: t('minutes.pdf_failed', { reason: e?.message || '?' }) });
    } finally {
      setPdfLaeuft(false);
    }
  };

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)] transition-colors';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  const abschnitt = (feldName: 'agendaItems' | 'decisions', titel: string) => (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <label className={marke + ' mb-0'}>{titel}</label>
        <button type="button" onClick={() => listeErgaenzen(feldName)}
          className="text-xs font-bold text-primary flex items-center gap-1 hover:opacity-70">
          <Plus size={13} /> {t('common.add')}
        </button>
      </div>
      {(form[feldName] || []).length === 0 && (
        <p className="text-xs text-stone-400 italic">{t('minutes.none_yet')}</p>
      )}
      {(form[feldName] || []).map((eintrag: any, i: number) => (
        <div key={eintrag.id || i} className="p-4 bg-stone-50 border border-stone-200 rounded-2xl space-y-2.5">
          <div className="flex gap-2">
            <span className="text-xs font-bold text-stone-400 pt-3 w-5 shrink-0">{i + 1}.</span>
            <input value={eintrag.title || ''} onChange={e => listeAendern(feldName, i, 'title', e.target.value)}
              placeholder={t('minutes.item_title')} className={feld} />
            <button type="button" onClick={() => listeEntfernen(feldName, i)}
              className="p-2 text-stone-400 hover:text-red-600 shrink-0"><Trash2 size={15} /></button>
          </div>
          <textarea value={eintrag.content || ''} onChange={e => listeAendern(feldName, i, 'content', e.target.value)}
            rows={2} placeholder={t('minutes.item_content')} className={feld + ' resize-none ml-7 w-[calc(100%-1.75rem)]'} />
          {feldName === 'decisions' && (
            <div className="grid grid-cols-2 gap-2 ml-7">
              <input value={eintrag.responsible || ''} onChange={e => listeAendern(feldName, i, 'responsible', e.target.value)}
                placeholder={t('minutes.responsible')} className={feld} />
              <input type="date" value={eintrag.dueDate || ''} onChange={e => listeAendern(feldName, i, 'dueDate', e.target.value)}
                className={feld} />
            </div>
          )}
        </div>
      ))}
    </div>
  );

  return (
    <div className="fixed inset-0 z-[400] flex items-center justify-center p-4 md:p-6 bg-stone-900/70 backdrop-blur-sm">
      <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-3xl rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[92dvh]">

        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
          <div>
            <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2">
              <FileText size={18} className="text-primary" />
              {istNeu ? t('minutes.new') : t('minutes.edit')}
            </h3>
            {!istNeu && (
              <p className="text-[11px] text-stone-500 mt-0.5">
                {t('minutes.version', { n: (meeting as any)?.version ?? 1 })}
                {(meeting as any)?.updatedAt &&
                  ` · ${t('minutes.last_change')} ${new Date((meeting as any).updatedAt).toLocaleString()}`}
              </p>
            )}
          </div>
          <button onClick={() => onClose(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={20} /></button>
        </div>

        <div className="p-6 md:p-8 space-y-6 overflow-y-auto custom-scrollbar">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="md:col-span-2">
              <label className={marke}>{t('minutes.title_label')} *</label>
              <input value={form.title || ''} onChange={e => setzen('title', e.target.value)} className={feld} />
            </div>
            <div>
              <label className={marke}>{t('minutes.date_label')} *</label>
              <input type="date" value={form.date || ''} onChange={e => setzen('date', e.target.value)} className={feld} />
            </div>
            <div className="md:col-span-2">
              <label className={marke}>{t('minutes.location')}</label>
              <input value={form.location || ''} onChange={e => setzen('location', e.target.value)} className={feld} />
            </div>
            <div>
              <label className={marke}>{t('minutes.status')}</label>
              <select value={form.status || 'PLANNED'} onChange={e => setzen('status', e.target.value)} className={feld}>
                <option value="PLANNED">{t('minutes.status_planned')}</option>
                <option value="HELD">{t('minutes.status_held')}</option>
                <option value="APPROVED">{t('minutes.status_approved')}</option>
              </select>
            </div>
          </div>

          <div>
            <label className={marke}><Users size={11} className="inline mr-1" /> {t('minutes.attendance')}</label>
            <div className="flex flex-wrap gap-2">
              {boardUsers.map(u => (
                <button key={u.id} type="button"
                  onClick={() => anwesenheitUmschalten(u.id!, u.displayName || '', (u as any).boardRole || u.role || '')}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold border transition-colors ${
                    istAnwesend(u.id!) ? 'bg-emerald-600 text-white border-emerald-600'
                                       : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                  {u.displayName}
                </button>
              ))}
              {boardUsers.length === 0 && <p className="text-xs text-stone-400 italic">{t('minutes.no_board')}</p>}
            </div>
          </div>

          <div>
            <label className={marke}><PenLine size={11} className="inline mr-1" /> {t('minutes.minute_taker')}</label>
            <select value={form.protokollfuehrer?.userId || ''}
              onChange={e => {
                const u = boardUsers.find(x => x.id === e.target.value);
                setzen('protokollfuehrer', u ? { userId: u.id, name: u.displayName || '' } : null);
              }} className={feld}>
              <option value="">{t('minutes.minute_taker_none')}</option>
              {boardUsers.map(u => <option key={u.id} value={u.id}>{u.displayName}</option>)}
            </select>
          </div>

          <ProtokollGaeste value={gaeste} onChange={setGaeste} feld={feld} />

          {abschnitt('agendaItems', t('minutes.agenda'))}
          {abschnitt('decisions', t('minutes.decisions'))}

          {/* Freigabe ist eine Entscheidung, keine Einstellung -- deshalb steht
              daneben, was sie bewirkt, und der Zeitpunkt wird festgehalten.
              Wirksam wird sie ueber die Zugriffsregel: ein Mitglied bekommt ein
              nicht freigegebenes Protokoll gar nicht erst geliefert. */}
          <div className="border-t border-stone-100 pt-5">
            <button type="button" onClick={() => setzen('publishedToMembers', !form.publishedToMembers)}
              className={`w-full p-4 rounded-2xl border-2 text-left transition-colors flex items-start gap-3 ${
                form.publishedToMembers ? 'bg-emerald-50 border-emerald-300' : 'bg-stone-50 border-stone-200 hover:border-stone-300'}`}>
              {form.publishedToMembers
                ? <Eye size={18} className="text-emerald-600 mt-0.5 shrink-0" />
                : <EyeOff size={18} className="text-stone-400 mt-0.5 shrink-0" />}
              <div className="flex-1">
                <p className={`text-sm font-bold ${form.publishedToMembers ? 'text-emerald-800' : 'text-stone-700'}`}>
                  {form.publishedToMembers ? t('minutes.published') : t('minutes.not_published')}
                </p>
                <p className="text-xs text-stone-500 leading-relaxed mt-0.5">
                  {form.publishedToMembers ? t('minutes.published_hint') : t('minutes.not_published_hint')}
                </p>
                {form.publishedToMembers && (form as any).publishedAt && (
                  <p className="text-[10px] text-emerald-700 mt-1.5">
                    {t('minutes.published_since')} {new Date((form as any).publishedAt).toLocaleString()}
                  </p>
                )}
              </div>
            </button>
          </div>

          {!istNeu && verlauf.length > 0 && (
            <div className="border-t border-stone-100 pt-5">
              <button type="button" onClick={() => setZeigeVerlauf(v => !v)}
                className="flex items-center gap-2 text-xs font-bold text-stone-500 hover:text-stone-900">
                {zeigeVerlauf ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                <History size={14} /> {t('minutes.history', { n: verlauf.length })}
              </button>
              {zeigeVerlauf && (
                <div className="mt-3 space-y-2">
                  <p className="text-[11px] text-stone-400 leading-relaxed">{t('minutes.history_hint')}</p>
                  {verlauf.map(v => (
                    <div key={v.id} className="border border-stone-200 rounded-xl overflow-hidden">
                      <button type="button"
                        onClick={() => setOffeneFassung(offeneFassung === v.id ? null : v.id)}
                        className="w-full text-left p-3 bg-stone-50 hover:bg-stone-100 flex justify-between items-center">
                        <span className="text-xs font-bold text-stone-700">
                          {t('minutes.version', { n: v.version })} · {v.snapshot?.title || '-'}
                        </span>
                        <span className="text-[10px] text-stone-400">
                          {v.changedAt ? new Date(v.changedAt).toLocaleString() : ''}
                        </span>
                      </button>
                      {offeneFassung === v.id && (
                        <div className="p-4 text-xs text-stone-600 space-y-2 bg-white">
                          <p><b>{t('minutes.date_label')}:</b> {v.snapshot?.date || '-'}</p>
                          <p><b>{t('minutes.location')}:</b> {v.snapshot?.location || '-'}</p>
                          <div>
                            <b>{t('minutes.agenda')}:</b>
                            <ol className="list-decimal ml-5 mt-1 space-y-0.5">
                              {(v.snapshot?.agendaItems || []).map((a: any, i: number) => (
                                <li key={i}>{a.title}{a.content ? ` — ${a.content}` : ''}</li>
                              ))}
                            </ol>
                            {(v.snapshot?.agendaItems || []).length === 0 && <span className="italic"> —</span>}
                          </div>
                          <div>
                            <b>{t('minutes.decisions')}:</b>
                            <ol className="list-decimal ml-5 mt-1 space-y-0.5">
                              {(v.snapshot?.decisions || []).map((d: any, i: number) => (
                                <li key={i}>{d.title}{d.content ? ` — ${d.content}` : ''}</li>
                              ))}
                            </ol>
                            {(v.snapshot?.decisions || []).length === 0 && <span className="italic"> —</span>}
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="p-6 border-t border-stone-100 bg-stone-50 flex flex-wrap gap-3">
          <button onClick={() => onClose(false)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">
            {t('common.cancel')}
          </button>
          {!istNeu && (
            <button onClick={alsPdf} disabled={pdfLaeuft}
              className="px-5 py-3 bg-white border border-stone-300 text-stone-700 rounded-xl font-bold flex items-center justify-center gap-2 disabled:opacity-60">
              {pdfLaeuft ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />} PDF
            </button>
          )}
          <button onClick={speichern} disabled={speichert}
            className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
            {speichert ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
            {istNeu ? t('minutes.create') : t('minutes.save_version')}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

export default BoardMinutesEditor;
