import React, { useEffect, useMemo, useState } from 'react';
import { ArrowRight, CheckCircle2, Circle, Loader2, Printer, Repeat, Search, AlertTriangle } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { neighborhoodsLedBy } from '../lib/stewardship';

// Uebergabe beim Vorstandswechsel, Schritt fuer Schritt:
//  1. Nachfolger bekommt die Rolle            (rolle_setzen)
//  2. Nachbarschafts-Verantwortung uebertragen (neighborhoods)
//  3. Bisherige Person zuruecksetzen           (rolle_setzen -- nicht bei sich selbst)
//  4. Festhalten und Uebergabeprotokoll drucken (uebergabe_festhalten)
// Jeder Schritt einzeln, damit ein Fehler nicht alles mitreisst.

type P = { id: string; displayName: string; role: string; email?: string | null };
type Schritt = 'ROLLE' | 'NACHBARSCHAFTEN' | 'ZURUECK' | 'FESTHALTEN';

const AdminUebergabe: React.FC<{ meineId?: string | null }> = ({ meineId }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [leute, setLeute] = useState<P[]>([]);
  const [nbs, setNbs] = useState<any[]>([]);
  const [von, setVon] = useState<string>('');
  const [an, setAn] = useState<string>('');
  const [suche, setSuche] = useState('');
  const [rolle, setRolle] = useState<'BOARD' | 'ADMIN'>('BOARD');
  const [amt, setAmt] = useState('');
  const [notiz, setNotiz] = useState('');
  const [erledigt, setErledigt] = useState<Record<Schritt, boolean>>({ ROLLE: false, NACHBARSCHAFTEN: false, ZURUECK: false, FESTHALTEN: false });
  const [arbeitet, setArbeitet] = useState<Schritt | null>(null);
  const [verlauf, setVerlauf] = useState<any[]>([]);

  const laden = async () => {
    const [u, n, h] = await Promise.all([
      supabase.from('users').select('id, displayName, role, email').or('membershipStatus.is.null,membershipStatus.neq.INACTIVE').order('displayName'),
      supabase.from('neighborhoods').select('*'),
      supabase.from('uebergaben').select('*').order('erfasst_am', { ascending: false }).limit(10),
    ]);
    setLeute((u.data ?? []) as P[]); setNbs(n.data ?? []); setVerlauf(h.data ?? []);
  };
  useEffect(() => { laden(); }, []);

  const fuehrung = leute.filter(p => ['BOARD', 'ADMIN', 'SUPER_ADMIN'].includes(p.role));
  const vonP = leute.find(p => p.id === von), anP = leute.find(p => p.id === an);
  const vonNbs = useMemo(() => neighborhoodsLedBy(von, nbs), [von, nbs]);
  const treffer = suche.trim().length < 2 ? [] : leute.filter(p => p.id !== von && p.displayName?.toLowerCase().includes(suche.trim().toLowerCase())).slice(0, 8);

  const schritt = async (s: Schritt, f: () => Promise<void>) => {
    setArbeitet(s);
    try { await f(); setErledigt(e => ({ ...e, [s]: true })); }
    catch (e: any) { showAlert({ type: 'error', message: e?.message || String(e) }); }
    finally { setArbeitet(null); }
  };

  const rolleGeben = () => schritt('ROLLE', async () => {
    const { error } = await supabase.rpc('rolle_setzen', { p_user: an, p_rolle: rolle });
    if (error) throw error;
  });

  const nbUebertragen = () => schritt('NACHBARSCHAFTEN', async () => {
    for (const n of vonNbs as any[]) {
      const liste: string[] = Array.isArray(n.contactPersonIds) ? n.contactPersonIds : [];
      const neu = [...new Set(liste.map((x: string) => x === von ? an : x))];
      const patch: any = { contactPersonIds: neu };
      if (n.managerId === von) patch.managerId = an;
      if (n.representativeId === von) patch.representativeId = an;
      const { error } = await supabase.from('neighborhoods').update(patch).eq('id', n.id);
      if (error) throw error;
    }
  });

  const zuruecksetzen = () => schritt('ZURUECK', async () => {
    const ok = await showConfirm({ title: t('ueb.zurueck_titel'), message: t('ueb.zurueck_frage', { name: vonP?.displayName || '' }), type: 'danger', confirmText: t('ueb.zurueck_knopf') });
    if (!ok) throw new Error(t('ueb.abgebrochen'));
    const { error } = await supabase.rpc('rolle_setzen', { p_user: von, p_rolle: 'MEMBER' });
    if (error) throw error;
  });

  const festhalten = () => schritt('FESTHALTEN', async () => {
    const { error } = await supabase.rpc('uebergabe_festhalten', { p_von: von || null, p_an: an, p_rolle: rolle, p_amt: amt, p_notiz: notiz, p_schritte: erledigt });
    if (error) throw error;
    laden();
  });

  const drucken = () => {
    const zeilen = [
      `Übergabeprotokoll${amt ? ` – ${amt}` : ''}`, new Date().toLocaleDateString('de-CH'), '',
      `Bisher: ${vonP?.displayName || '—'}`, `Neu: ${anP?.displayName || '—'} (Rolle ${rolle})`, '',
      `[${erledigt.ROLLE ? 'x' : ' '}] Rolle an Nachfolger vergeben`,
      `[${erledigt.NACHBARSCHAFTEN || !vonNbs.length ? 'x' : ' '}] Nachbarschafts-Verantwortung übertragen${vonNbs.length ? ` (${vonNbs.map((n: any) => n.name).join(', ')})` : ' (keine)'}`,
      `[${erledigt.ZURUECK ? 'x' : ' '}] Bisherige Person auf Mitglied zurückgesetzt`,
      `[ ] Bankvollmachten / E-Banking übertragen`,
      `[ ] Schlüssel, Unterlagen und Passwörter übergeben`,
      `[ ] Handelsregister / Vereinsregister angepasst (falls nötig)`,
      '', notiz ? `Notiz:\n${notiz}` : '', '', 'Unterschrift bisher: ____________________', '', 'Unterschrift neu: ____________________',
    ];
    const w = window.open('', '_blank'); if (!w) return;
    w.document.write(`<!doctype html><meta charset="utf-8"><title>Übergabe</title><body style="font:14px/1.7 system-ui,sans-serif;max-width:720px;margin:40px auto;padding:0 20px;white-space:pre-wrap">${zeilen.join('\n').replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]!))}</body>`);
    w.document.close(); w.focus(); w.print();
  };

  const Punkt: React.FC<{ s: Schritt; titel: string; text: string; knopf: string; onClick: () => void; aus?: boolean; hinweis?: string }> = ({ s, titel, text, knopf, onClick, aus, hinweis }) => (
    <div className="flex items-start gap-4 p-4 bg-stone-50 rounded-2xl">
      {erledigt[s] ? <CheckCircle2 size={20} className="text-emerald-600 shrink-0 mt-0.5" /> : <Circle size={20} className="text-stone-300 shrink-0 mt-0.5" />}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-bold text-stone-800">{titel}</p>
        <p className="text-xs text-stone-500">{text}</p>
        {hinweis && <p className="text-xs text-amber-700 mt-1 flex items-center gap-1.5"><AlertTriangle size={12} /> {hinweis}</p>}
      </div>
      <button onClick={onClick} disabled={aus || erledigt[s] || arbeitet !== null}
              className="px-4 py-2 rounded-xl text-xs font-bold bg-stone-900 text-white disabled:opacity-30 shrink-0 flex items-center gap-1.5">
        {arbeitet === s && <Loader2 size={12} className="animate-spin" />} {knopf}
      </button>
    </div>
  );

  return (
    <div className="bg-white rounded-3xl border border-stone-100 p-6 space-y-5">
      <div>
        <h4 className="font-bold text-stone-900 flex items-center gap-2"><Repeat size={18} /> {t('ueb.titel')}</h4>
        <p className="text-xs text-stone-500">{t('ueb.text')}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-[1fr_auto_1fr] gap-4 items-start">
        <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('ueb.bisher')}
          <select value={von} onChange={e => { setVon(e.target.value); setErledigt({ ROLLE: false, NACHBARSCHAFTEN: false, ZURUECK: false, FESTHALTEN: false }); }}
                  className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800 normal-case tracking-normal">
            <option value="">{t('ueb.niemand')}</option>
            {fuehrung.map(p => <option key={p.id} value={p.id}>{p.displayName} · {p.role}</option>)}
          </select>
        </label>
        <ArrowRight className="hidden md:block text-stone-300 mt-8" />
        <div className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('ueb.neu')}
          {anP ? (
            <div className="mt-1 flex items-center justify-between gap-2 p-3 bg-emerald-50 border border-emerald-200 rounded-xl">
              <span className="text-sm font-bold text-stone-800 normal-case tracking-normal">{anP.displayName} <span className="text-stone-400 font-normal">· {anP.role}</span></span>
              <button onClick={() => { setAn(''); setErledigt(e => ({ ...e, ROLLE: false })); }} className="text-[10px] text-stone-500 underline normal-case tracking-normal">{t('ueb.aendern')}</button>
            </div>
          ) : (
            <div className="mt-1 relative">
              <Search size={14} className="absolute left-3 top-3.5 text-stone-300" />
              <input value={suche} onChange={e => setSuche(e.target.value)} placeholder={t('stamm.mitglied_suchen')}
                     className="w-full pl-9 pr-3 py-3 bg-stone-50 border border-stone-200 rounded-xl text-sm normal-case tracking-normal font-normal" />
              {treffer.length > 0 && (
                <div className="absolute z-10 left-0 right-0 mt-1 bg-white border border-stone-200 rounded-xl shadow-lg overflow-hidden normal-case tracking-normal">
                  {treffer.map(p => <button key={p.id} onClick={() => { setAn(p.id); setSuche(''); }} className="block w-full text-left px-3 py-2 text-sm hover:bg-stone-50 font-normal text-stone-700">{p.displayName} <span className="text-stone-400">· {p.role}</span></button>)}
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('ueb.rolle')}
          <select value={rolle} onChange={e => setRolle(e.target.value as any)} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800">
            <option value="BOARD">{t('role.board')}</option><option value="ADMIN">{t('role.admin')}</option>
          </select></label>
        <label className="md:col-span-2 text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('ueb.amt')}
          <input value={amt} onChange={e => setAmt(e.target.value)} placeholder={t('ueb.amt_ph')} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800 normal-case tracking-normal" /></label>
      </div>

      {an && (
        <div className="space-y-2">
          <Punkt s="ROLLE" titel={t('ueb.s1')} text={t('ueb.s1_text', { name: anP?.displayName || '', rolle })} knopf={t('ueb.ausfuehren')} onClick={rolleGeben} />
          {von && <Punkt s="NACHBARSCHAFTEN" titel={t('ueb.s2')}
                         text={vonNbs.length ? vonNbs.map((n: any) => n.name).join(', ') : t('ueb.s2_keine')}
                         knopf={t('ueb.uebertragen')} onClick={nbUebertragen} aus={!vonNbs.length} />}
          {von && <Punkt s="ZURUECK" titel={t('ueb.s3')} text={t('ueb.s3_text', { name: vonP?.displayName || '' })} knopf={t('ueb.ausfuehren')}
                         onClick={zuruecksetzen} aus={!erledigt.ROLLE || von === meineId}
                         hinweis={von === meineId ? t('ueb.s3_selbst') : !erledigt.ROLLE ? t('ueb.s3_erst') : undefined} />}
          <textarea value={notiz} onChange={e => setNotiz(e.target.value)} rows={3} placeholder={t('ueb.notiz_ph')}
                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none" />
          <div className="flex flex-wrap gap-3">
            <button onClick={festhalten} disabled={erledigt.FESTHALTEN || arbeitet !== null}
                    className="knopf-primaer px-5 py-3 text-white rounded-xl text-sm font-bold disabled:opacity-40 flex items-center gap-2">
              {erledigt.FESTHALTEN ? <CheckCircle2 size={15} /> : null} {t('ueb.festhalten')}
            </button>
            <button onClick={drucken} className="px-5 py-3 bg-white border border-stone-200 rounded-xl text-sm font-bold flex items-center gap-2"><Printer size={15} /> {t('ueb.drucken')}</button>
          </div>
        </div>
      )}

      {verlauf.length > 0 && (
        <div className="pt-4 border-t border-stone-100">
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('ueb.verlauf')}</p>
          <div className="space-y-1">
            {verlauf.map(h => (
              <p key={h.id} className="text-xs text-stone-600">
                {new Date(h.erfasst_am).toLocaleDateString('de-CH')} · {h.von_name || '—'} → <b>{h.an_name}</b> ({h.amt || h.rolle})
              </p>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminUebergabe;
