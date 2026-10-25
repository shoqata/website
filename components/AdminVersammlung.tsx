import React, { useEffect, useMemo, useState } from 'react';
import { Plus, Trash2, Send, Save, Loader2, ArrowLeft, Users, CheckCircle2, AlertTriangle, FileText, Printer, ArrowUp, ArrowDown, Search, Gavel } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { useTenant } from '../context/TenantContext';
import Jahresbericht from './Jahresbericht';

// Generalversammlung von A bis Z: vorbereiten (Traktanden), einladen (an
// alle mit E-Mail), am Abend Praesenz und Ergebnisse festhalten, Protokoll
// erstellen und versenden. Abgestimmt wird im Saal; hier stehen die Zahlen.

type Traktandum = { titel: string; abstimmung: boolean; ja?: number | null; nein?: number | null; enthaltung?: number | null; beschluss?: string };
type Versammlung = {
  id: string; titel: string; datum: string; zeit: string | null; ort: string | null;
  traktanden: Traktandum[]; quorum_prozent: number; status: string; protokoll: string | null;
  eingeladen_am: string | null; protokoll_versandt_am: string | null;
};

const VORLAGE: Traktandum[] = [
  { titel: 'Begrüssung und Feststellung der Beschlussfähigkeit', abstimmung: false },
  { titel: 'Wahl der Stimmenzähler', abstimmung: true },
  { titel: 'Protokoll der letzten Generalversammlung', abstimmung: true },
  { titel: 'Jahresbericht des Vorstands', abstimmung: true },
  { titel: 'Jahresrechnung und Bericht der Revision', abstimmung: true },
  { titel: 'Entlastung des Vorstands', abstimmung: true },
  { titel: 'Wahlen', abstimmung: true },
  { titel: 'Budget und Mitgliederbeitrag', abstimmung: true },
  { titel: 'Anträge', abstimmung: true },
  { titel: 'Varia', abstimmung: false },
];

const esc = (s: string) => s.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]!));
const datumText = (d: string) => new Date(d + 'T12:00:00').toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
const angenommen = (t: Traktandum) => (t.ja ?? 0) > (t.nein ?? 0);

const AdminVersammlung: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const { tenant } = useTenant() as any;
  const [liste, setListe] = useState<Versammlung[] | null>(null);
  const [v, setV] = useState<Versammlung | null>(null);
  const [geaendert, setGeaendert] = useState(false);
  const [arbeitet, setArbeitet] = useState(false);
  const [reiter, setReiter] = useState<'VORBEREITEN' | 'ABEND' | 'PROTOKOLL'>('VORBEREITEN');
  const [mitglieder, setMitglieder] = useState<{ id: string; displayName: string; email: string | null }[]>([]);
  const [praesenz, setPraesenz] = useState<Set<string>>(new Set());
  const [stimmberechtigt, setStimmberechtigt] = useState(0);
  const [suche, setSuche] = useState('');
  const verein = tenant?.name || 'Verein';

  const laden = async () => {
    const { data } = await supabase.from('versammlungen').select('*').order('datum', { ascending: false });
    setListe((data ?? []) as Versammlung[]);
  };
  useEffect(() => { laden(); }, []);

  const oeffnen = async (x: Versammlung) => {
    setV(x); setGeaendert(false); setReiter(x.status === 'ENTWURF' ? 'VORBEREITEN' : x.status === 'EINGELADEN' ? 'ABEND' : 'PROTOKOLL');
    const [p, m, s] = await Promise.all([
      supabase.from('versammlung_praesenz').select('mitglied').eq('versammlung', x.id).eq('anwesend', true),
      (tenant?.id ? supabase.from('users').select('id, displayName, email, membershipStatus').eq('tenantId', tenant.id) : supabase.from('users').select('id, displayName, email, membershipStatus')).or('membershipStatus.is.null,membershipStatus.neq.INACTIVE').order('displayName'),
      supabase.rpc('versammlung_stimmberechtigt'),
    ]);
    setPraesenz(new Set((p.data ?? []).map((r: any) => r.mitglied)));
    setMitglieder((m.data ?? []) as any);
    setStimmberechtigt(Number(s.data ?? 0));
  };

  const neu = async () => {
    const jahr = new Date().getFullYear();
    const { data, error } = await supabase.from('versammlungen').insert({
      titel: `Generalversammlung ${jahr}`, datum: new Date(Date.now() + 30 * 864e5).toISOString().slice(0, 10),
      zeit: '19:00', ort: '', traktanden: VORLAGE, quorum_prozent: 0,
    }).select().single();
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    await laden(); oeffnen(data as Versammlung);
  };

  const aendern = (p: Partial<Versammlung>) => { setV(x => x ? { ...x, ...p } : x); setGeaendert(true); };
  const traktandum = (i: number, p: Partial<Traktandum>) => v && aendern({ traktanden: v.traktanden.map((x, j) => j === i ? { ...x, ...p } : x) });

  const speichern = async () => {
    if (!v) return true;
    setArbeitet(true);
    const { error } = await supabase.from('versammlungen').update({
      titel: v.titel, datum: v.datum, zeit: v.zeit, ort: v.ort, traktanden: v.traktanden,
      quorum_prozent: v.quorum_prozent, protokoll: v.protokoll,
    }).eq('id', v.id);
    setArbeitet(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return false; }
    setGeaendert(false); laden(); return true;
  };

  const anwesendSetzen = async (id: string, ja: boolean) => {
    if (!v) return;
    const neuP = new Set(praesenz); ja ? neuP.add(id) : neuP.delete(id); setPraesenz(neuP);
    const { error } = ja
      ? await supabase.from('versammlung_praesenz').upsert({ versammlung: v.id, mitglied: id, anwesend: true })
      : await supabase.from('versammlung_praesenz').delete().eq('versammlung', v.id).eq('mitglied', id);
    if (error) showAlert({ type: 'error', message: error.message });
  };

  const einladungHtml = (x: Versammlung) => `
    <p>Liebe Mitglieder</p>
    <p>Wir laden Sie herzlich zur <b>${esc(x.titel)}</b> ein.</p>
    <p><b>${esc(datumText(x.datum))}${x.zeit ? `, ${esc(x.zeit)} Uhr` : ''}</b>${x.ort ? `<br>${esc(x.ort)}` : ''}</p>
    <p><b>Traktanden</b></p>
    <ol>${x.traktanden.map(tr => `<li>${esc(tr.titel)}</li>`).join('')}</ol>
    <p>Anträge zuhanden der Versammlung richten Sie bitte schriftlich an den Vorstand.</p>
    <p>Wir freuen uns auf Ihre Teilnahme.<br>Der Vorstand von ${esc(verein)}</p>`;

  const protokollErstellen = (x: Versammlung) => {
    const quote = stimmberechtigt ? Math.round(praesenz.size / stimmberechtigt * 100) : 0;
    const zeilen = [
      `Protokoll – ${x.titel}`,
      `${datumText(x.datum)}${x.zeit ? `, ${x.zeit} Uhr` : ''}${x.ort ? `, ${x.ort}` : ''}`,
      '',
      `Anwesend: ${praesenz.size} von ${stimmberechtigt} Mitgliedern (${quote} %).` +
        (x.quorum_prozent ? (quote >= x.quorum_prozent ? ' Die Versammlung ist beschlussfähig.' : ` Das Quorum von ${x.quorum_prozent} % ist nicht erreicht.`) : ''),
      '',
      ...x.traktanden.flatMap((tr, i) => [
        `${i + 1}. ${tr.titel}`,
        ...(tr.abstimmung && (tr.ja != null || tr.nein != null)
          ? [`   Abstimmung: ${tr.ja ?? 0} Ja, ${tr.nein ?? 0} Nein, ${tr.enthaltung ?? 0} Enthaltungen – ${angenommen(tr) ? 'angenommen' : 'abgelehnt'}.`]
          : []),
        ...(tr.beschluss ? [`   ${tr.beschluss}`] : []),
        '',
      ]),
      `Für das Protokoll: ____________________`,
    ];
    aendern({ protokoll: zeilen.join('\n') });
  };

  const versenden = async (art: 'EINLADUNG' | 'PROTOKOLL') => {
    if (!v) return;
    if (geaendert && !(await speichern())) return;
    const mitMail = mitglieder.filter(m => m.email && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(m.email) && !m.email.endsWith('.legacy')).length;
    const ok = await showConfirm({
      title: art === 'EINLADUNG' ? t('gv.einladen') : t('gv.protokoll_senden'),
      message: t('gv.versand_frage', { count: mitMail, ohne: mitglieder.length - mitMail }),
      confirmText: t('gv.senden'), type: 'primary',
    });
    if (!ok) return;
    const html = art === 'EINLADUNG' ? einladungHtml(v)
      : `<p>Liebe Mitglieder</p><p>Nachstehend finden Sie das Protokoll der ${esc(v.titel)}.</p><pre style="font-family:inherit;white-space:pre-wrap">${esc(v.protokoll || '')}</pre><p>Der Vorstand von ${esc(verein)}</p>`;
    const text = html.replace(/<li>/g, '- ').replace(/<br>/g, '\n').replace(/<\/p>|<\/li>/g, '\n').replace(/<[^>]+>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
    setArbeitet(true);
    const { data, error } = await supabase.rpc('versammlung_versenden', {
      p_id: v.id, p_art: art,
      p_betreff: art === 'EINLADUNG' ? `Einladung: ${v.titel}` : `Protokoll: ${v.titel}`,
      p_html: html, p_text: text,
    });
    setArbeitet(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    showAlert({ type: 'success', message: t('gv.versandt', { count: Number(data) }) });
    const { data: frisch } = await supabase.from('versammlungen').select('*').eq('id', v.id).single();
    if (frisch) setV(frisch as Versammlung);
    laden();
  };

  const drucken = (text: string, titel: string) => {
    const w = window.open('', '_blank');
    if (!w) return;
    w.document.write(`<!doctype html><html><head><meta charset="utf-8"><title>${esc(titel)}</title><style>body{font:14px/1.6 system-ui,sans-serif;max-width:720px;margin:40px auto;padding:0 20px;white-space:pre-wrap}</style></head><body>${esc(text)}</body></html>`);
    w.document.close(); w.focus(); w.print();
  };

  const praesenzliste = () => v && drucken(
    `Präsenzliste – ${v.titel}\n${datumText(v.datum)}\n\n` + mitglieder.map(m => `[  ]  ${m.displayName}`).join('\n'), 'Präsenzliste');

  const quote = stimmberechtigt ? Math.round(praesenz.size / stimmberechtigt * 100) : 0;
  const treffer = useMemo(() => {
    const s = suche.trim().toLowerCase();
    return (s ? mitglieder.filter(m => m.displayName?.toLowerCase().includes(s)) : mitglieder).slice(0, 60);
  }, [mitglieder, suche]);

  if (liste === null) return <div className="p-8 text-stone-400"><Loader2 className="animate-spin" size={18} /></div>;

  // ----------------------------------------------------------- Liste
  if (!v) return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div>
          <h3 className="text-xl font-bold text-stone-900 flex items-center gap-2"><Gavel size={20} /> {t('gv.titel')}</h3>
          <p className="text-sm text-stone-500">{t('gv.untertitel')}</p>
        </div>
        <button onClick={neu} className="knopf-primaer px-5 py-2.5 text-white rounded-xl text-xs font-bold flex items-center gap-2"><Plus size={14} /> {t('gv.neu')}</button>
      </div>
      <Jahresbericht />
      {!liste.length ? (
        <div className="p-10 bg-stone-50 rounded-3xl border border-stone-100 text-center text-sm text-stone-500">{t('gv.leer')}</div>
      ) : (
        <div className="grid gap-3">
          {liste.map(x => (
            <button key={x.id} onClick={() => oeffnen(x)} className="text-left bg-white border border-stone-200 hover:border-stone-400 rounded-2xl p-5 flex items-center justify-between gap-4">
              <div>
                <p className="font-bold text-stone-900">{x.titel}</p>
                <p className="text-xs text-stone-500">{datumText(x.datum)}{x.ort ? ` · ${x.ort}` : ''}</p>
              </div>
              <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-widest bg-stone-100 text-stone-600">{t(`gv.status.${x.status}`)}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );

  // ----------------------------------------------------------- Eine Versammlung
  const schritte = [
    { k: 'VORBEREITEN' as const, n: 1, text: t('gv.schritt1'), fertig: !!v.eingeladen_am },
    { k: 'ABEND' as const, n: 2, text: t('gv.schritt2'), fertig: praesenz.size > 0 },
    { k: 'PROTOKOLL' as const, n: 3, text: t('gv.schritt3'), fertig: !!v.protokoll_versandt_am },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <button onClick={async () => { if (geaendert && !(await showConfirm({ title: t('gv.ungespeichert'), message: t('gv.ungespeichert_frage'), type: 'danger' }))) return; setV(null); }}
                className="flex items-center gap-2 text-xs font-bold text-stone-500 hover:text-stone-900"><ArrowLeft size={14} /> {t('gv.alle')}</button>
        <button onClick={speichern} disabled={!geaendert || arbeitet}
                className="knopf-primaer px-5 py-2.5 text-white rounded-xl text-xs font-bold flex items-center gap-2 disabled:opacity-40">
          {arbeitet ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />} {t('common.save')}
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2">
        {schritte.map(s => (
          <button key={s.k} onClick={() => setReiter(s.k)}
                  className={`flex items-center gap-3 p-4 rounded-2xl border text-left ${reiter === s.k ? 'bg-stone-900 text-white border-stone-900' : 'bg-white border-stone-200 text-stone-700'}`}>
            <span className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0 ${s.fertig ? 'bg-emerald-500 text-white' : reiter === s.k ? 'bg-white/15' : 'bg-stone-100'}`}>
              {s.fertig ? <CheckCircle2 size={16} /> : s.n}
            </span>
            <span className="text-xs font-bold">{s.text}</span>
          </button>
        ))}
      </div>

      {reiter === 'VORBEREITEN' && (
        <div className="bg-white rounded-3xl border border-stone-100 p-6 space-y-5">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <label className="md:col-span-2 text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('gv.feld_titel')}
              <input value={v.titel} onChange={e => aendern({ titel: e.target.value })} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-bold text-stone-800 normal-case tracking-normal" /></label>
            <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('gv.feld_datum')}
              <input type="date" value={v.datum} onChange={e => aendern({ datum: e.target.value })} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800" /></label>
            <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('gv.feld_zeit')}
              <input value={v.zeit || ''} onChange={e => aendern({ zeit: e.target.value })} placeholder="19:00" className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800" /></label>
            <label className="md:col-span-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('gv.feld_ort')}
              <input value={v.ort || ''} onChange={e => aendern({ ort: e.target.value })} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800 normal-case tracking-normal" /></label>
            <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('gv.feld_quorum')}
              <input type="number" min={0} max={100} value={v.quorum_prozent} onChange={e => aendern({ quorum_prozent: Math.max(0, Math.min(100, Number(e.target.value) || 0)) })} className="mt-1 w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm text-stone-800" /></label>
          </div>

          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('gv.traktanden')}</p>
            <div className="space-y-2">
              {v.traktanden.map((tr, i) => (
                <div key={i} className="flex items-center gap-2 p-2 bg-stone-50 rounded-xl">
                  <span className="w-7 text-center text-xs font-bold text-stone-400">{i + 1}.</span>
                  <input value={tr.titel} onChange={e => traktandum(i, { titel: e.target.value })} className="flex-1 p-2 bg-white border border-stone-200 rounded-lg text-sm" />
                  <label className="flex items-center gap-1.5 text-[11px] text-stone-500 whitespace-nowrap">
                    <input type="checkbox" checked={tr.abstimmung} onChange={e => traktandum(i, { abstimmung: e.target.checked })} /> {t('gv.abstimmung')}
                  </label>
                  <button disabled={i === 0} onClick={() => { const a = [...v.traktanden]; [a[i - 1], a[i]] = [a[i], a[i - 1]]; aendern({ traktanden: a }); }} className="p-1.5 text-stone-400 disabled:opacity-20"><ArrowUp size={14} /></button>
                  <button disabled={i === v.traktanden.length - 1} onClick={() => { const a = [...v.traktanden]; [a[i + 1], a[i]] = [a[i], a[i + 1]]; aendern({ traktanden: a }); }} className="p-1.5 text-stone-400 disabled:opacity-20"><ArrowDown size={14} /></button>
                  <button onClick={() => aendern({ traktanden: v.traktanden.filter((_, j) => j !== i) })} className="p-1.5 text-stone-300 hover:text-rose-600"><Trash2 size={14} /></button>
                </div>
              ))}
            </div>
            <button onClick={() => aendern({ traktanden: [...v.traktanden, { titel: '', abstimmung: false }] })}
                    className="mt-2 inline-flex items-center gap-1.5 text-xs font-bold text-stone-600"><Plus size={13} /> {t('gv.traktandum_neu')}</button>
          </div>

          <div className="flex flex-wrap items-center gap-3 pt-4 border-t border-stone-100">
            <button onClick={() => versenden('EINLADUNG')} disabled={arbeitet}
                    className="knopf-primaer px-5 py-3 text-white rounded-xl text-sm font-bold flex items-center gap-2"><Send size={15} /> {v.eingeladen_am ? t('gv.nochmals_einladen') : t('gv.einladen')}</button>
            <button onClick={() => drucken(einladungHtml(v).replace(/<li>/g, '\n- ').replace(/<br>/g, '\n').replace(/<\/p>/g, '\n').replace(/<[^>]+>/g, '').replace(/&amp;/g, '&'), v.titel)}
                    className="px-5 py-3 bg-white border border-stone-200 rounded-xl text-sm font-bold flex items-center gap-2"><Printer size={15} /> {t('gv.einladung_drucken')}</button>
            {v.eingeladen_am && <span className="text-xs text-emerald-700 flex items-center gap-1.5"><CheckCircle2 size={13} /> {t('gv.eingeladen_am', { datum: new Date(v.eingeladen_am).toLocaleDateString('de-CH') })}</span>}
          </div>
        </div>
      )}

      {reiter === 'ABEND' && (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          <div className="bg-white rounded-3xl border border-stone-100 p-6">
            <div className="flex items-center justify-between gap-3 mb-4 flex-wrap">
              <h4 className="font-bold text-stone-900 flex items-center gap-2"><Users size={18} /> {t('gv.praesenz')}</h4>
              <button onClick={praesenzliste} className="text-[10px] font-bold uppercase tracking-widest flex items-center gap-1" style={{ color: 'var(--primary)' }}><Printer size={12} /> {t('gv.praesenzliste')}</button>
            </div>
            <div className={`p-4 rounded-2xl mb-4 ${v.quorum_prozent && quote < v.quorum_prozent ? 'bg-amber-50 text-amber-800' : 'bg-emerald-50 text-emerald-800'}`}>
              <p className="text-2xl font-bold">{praesenz.size} <span className="text-sm font-normal">/ {stimmberechtigt} · {quote} %</span></p>
              <p className="text-xs flex items-center gap-1.5 mt-1">
                {v.quorum_prozent ? (quote >= v.quorum_prozent
                  ? <><CheckCircle2 size={12} /> {t('gv.beschlussfaehig')}</>
                  : <><AlertTriangle size={12} /> {t('gv.quorum_fehlt', { quorum: v.quorum_prozent })}</>) : t('gv.kein_quorum')}
              </p>
            </div>
            <div className="relative mb-3">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
              <input value={suche} onChange={e => setSuche(e.target.value)} placeholder={t('stamm.mitglied_suchen')} className="w-full pl-9 pr-3 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none" />
            </div>
            <div className="max-h-[420px] overflow-y-auto space-y-1">
              {treffer.map(m => (
                <label key={m.id} className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-stone-50 cursor-pointer">
                  <input type="checkbox" checked={praesenz.has(m.id)} onChange={e => anwesendSetzen(m.id, e.target.checked)} className="w-4 h-4" />
                  <span className={`text-sm ${praesenz.has(m.id) ? 'font-bold text-stone-900' : 'text-stone-600'}`}>{m.displayName}</span>
                </label>
              ))}
            </div>
          </div>
          <div className="bg-white rounded-3xl border border-stone-100 p-6">
            <h4 className="font-bold text-stone-900 mb-4">{t('gv.ergebnisse')}</h4>
            <div className="space-y-3">
              {v.traktanden.map((tr, i) => (
                <div key={i} className="p-3 bg-stone-50 rounded-xl">
                  <p className="text-sm font-bold text-stone-800">{i + 1}. {tr.titel}</p>
                  {tr.abstimmung && (
                    <div className="flex flex-wrap items-center gap-2 mt-2">
                      {(['ja', 'nein', 'enthaltung'] as const).map(f => (
                        <label key={f} className="text-[11px] text-stone-500 flex items-center gap-1">{t(`gv.${f}`)}
                          <input type="number" min={0} value={tr[f] ?? ''} onChange={e => traktandum(i, { [f]: e.target.value === '' ? null : Math.max(0, Number(e.target.value)) } as any)}
                                 className="w-16 p-1.5 bg-white border border-stone-200 rounded-lg text-sm" />
                        </label>
                      ))}
                      {(tr.ja != null || tr.nein != null) && (
                        <span className={`text-[10px] font-bold uppercase px-2 py-1 rounded ${angenommen(tr) ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'}`}>
                          {angenommen(tr) ? t('gv.angenommen') : t('gv.abgelehnt')}
                        </span>
                      )}
                    </div>
                  )}
                  <input value={tr.beschluss || ''} onChange={e => traktandum(i, { beschluss: e.target.value })} placeholder={t('gv.notiz')}
                         className="mt-2 w-full p-2 bg-white border border-stone-200 rounded-lg text-xs" />
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {reiter === 'PROTOKOLL' && (
        <div className="bg-white rounded-3xl border border-stone-100 p-6 space-y-4">
          <div className="flex flex-wrap items-center gap-3">
            <button onClick={() => protokollErstellen(v)} className="px-4 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center gap-2"><FileText size={14} /> {v.protokoll ? t('gv.protokoll_neu') : t('gv.protokoll_erstellen')}</button>
            {v.protokoll && <button onClick={() => drucken(v.protokoll!, `Protokoll ${v.titel}`)} className="px-4 py-2.5 bg-white border border-stone-200 rounded-xl text-xs font-bold flex items-center gap-2"><Printer size={14} /> {t('gv.drucken')}</button>}
          </div>
          <textarea value={v.protokoll || ''} onChange={e => aendern({ protokoll: e.target.value })} rows={20}
                    placeholder={t('gv.protokoll_ph')} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-2xl text-sm font-mono leading-relaxed outline-none" />
          <div className="flex flex-wrap items-center gap-3">
            <button onClick={() => versenden('PROTOKOLL')} disabled={!v.protokoll || arbeitet}
                    className="knopf-primaer px-5 py-3 text-white rounded-xl text-sm font-bold flex items-center gap-2 disabled:opacity-40"><Send size={15} /> {t('gv.protokoll_senden')}</button>
            {v.protokoll_versandt_am && <span className="text-xs text-emerald-700 flex items-center gap-1.5"><CheckCircle2 size={13} /> {t('gv.versandt_am', { datum: new Date(v.protokoll_versandt_am).toLocaleDateString('de-CH') })}</span>}
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminVersammlung;
