import React, { useEffect, useState } from 'react';
import { ArrowUp, ArrowDown, Eye, EyeOff, Loader2, Save, Check, AlertCircle, Monitor, Smartphone, Plus, Trash2, FolderTree, Wand2, ChevronDown } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, onSnapshot, setDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { useKopfzeile, NavEintrag, NavOrt, NavLayout, NavGruppe, navLayout, navGruppen, navBaum, GRUPPEN_VORSCHLAG, zeigtOben, zeigtFuss } from './kopfzeile';

// Die Kopfzeile der Website verwalten: welche Eintraege, in welcher
// Reihenfolge.
//
// Ein Eintrag, dessen Modul nicht gebucht ist (oder dessen Seite
// ausgeschaltet ist), laesst sich trotzdem einordnen -- er erscheint, sobald
// das Modul da ist. Die Maske sagt dazu, warum er gerade fehlt, statt ihn zu
// verstecken: sonst sucht der Verein einen Eintrag, den es nicht gibt.
//
// Eigene Seiten (Website → Eigene Seiten) koennen hier in die Kopfzeile.
// "Im Menü" bei der Seite selbst steuert weiterhin die Fusszeile.

const AdminNavigation: React.FC = () => {
  const { t, loc } = useTranslation();
  const { showAlert } = useFeedback();
  const [system, setSystem] = useState<any>(undefined);
  const [liste, setListe] = useState<NavEintrag[] | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [geaendert, setGeaendert] = useState(false);
  const [layout, setLayout] = useState<NavLayout | null>(null);
  const [gruppen, setGruppen] = useState<NavGruppe[] | null>(null);
  const [sprache, setSprache] = useState<'de' | 'sq' | 'en'>('de');

  useEffect(() => onSnapshot(doc(db, 'settings', 'system'), (snap: any) => {
    setSystem(snap.exists() ? snap.data() : {});
  }), []);

  const alle = useKopfzeile({
    einstellung: system?.navigation, zahlerliste: system?.zahlerliste,
    angemeldet: true, alle: true, loc,
  });
  // Einmal uebernehmen, danach gehoert die Liste der Maske -- sonst
  // ueberschriebe jede Antwort der Datenbank die laufende Bearbeitung.
  useEffect(() => { if (alle && system !== undefined && !geaendert) setListe(alle); }, [alle, system]);
  useEffect(() => { if (system !== undefined && !geaendert) setLayout(navLayout(system?.navigationLayout)); }, [system]);
  useEffect(() => { if (system !== undefined && !geaendert) setGruppen(navGruppen(system?.navigationGruppen)); }, [system]);

  const geaendertMarken = () => { setGeaendert(true); setGespeichert(false); };
  const gruppeSetzen = (i: number, gruppe: string) => {
    if (!liste) return;
    setListe(liste.map((e, k) => k === i ? { ...e, gruppe: gruppe || null } : e));
    geaendertMarken();
  };
  const gruppeAendern = (id: string, wert: string) => {
    setGruppen(g => (g || []).map(x => x.id === id
      ? { ...x, label: { ...(typeof x.label === 'object' && x.label ? x.label : { de: x.label || '' }), [sprache]: wert } } : x));
    geaendertMarken();
  };
  const gruppeNeu = () => {
    setGruppen(g => [...(g || []), { id: `g${Date.now().toString(36)}`, label: { [sprache]: '' } }]);
    geaendertMarken();
  };
  const gruppeWeg = (id: string) => {
    setGruppen(g => (g || []).filter(x => x.id !== id));
    setListe(l => l ? l.map(e => e.gruppe === id ? { ...e, gruppe: null } : e) : l);
    geaendertMarken();
  };
  // Vorschlag: Verein / Aktuell / Mitmachen. Eintraege in der Liste
  // werden so umsortiert, dass jede Gruppe beisammen steht.
  const vorschlag = () => {
    if (!liste) return;
    const zuordnung = new Map<string, string>();
    GRUPPEN_VORSCHLAG.forEach(v => v.eintraege.forEach(k => zuordnung.set(k, v.gruppe.id)));
    const mit = liste.map(e => ({ ...e, gruppe: zuordnung.get(e.schluessel) ?? e.gruppe ?? null }));
    const reihe = [...GRUPPEN_VORSCHLAG.map(v => v.gruppe.id)];
    mit.sort((a, b) => {
      const ia = a.gruppe ? reihe.indexOf(a.gruppe) : 99, ib = b.gruppe ? reihe.indexOf(b.gruppe) : 99;
      return ia - ib;
    });
    setListe(mit);
    setGruppen(GRUPPEN_VORSCHLAG.map(v => v.gruppe));
    if ((layout?.computer || 'KOPFZEILE') === 'KOPFZEILE') setLayout(l => ({ ...(l || navLayout(null)), computer: 'MEGAMENU' }));
    geaendertMarken();
  };

  const ortSetzen = (i: number, ort: NavOrt) => {
    if (!liste) return;
    setListe(liste.map((e, k) => k === i ? { ...e, ort } : e));
    setGeaendert(true); setGespeichert(false);
  };
  const layoutSetzen = (neu: Partial<NavLayout>) => {
    setLayout(l => ({ ...(l || navLayout(null)), ...neu }));
    setGeaendert(true); setGespeichert(false);
  };

  const schieben = (i: number, um: number) => {
    if (!liste) return;
    const j = i + um;
    if (j < 0 || j >= liste.length) return;
    const neu = [...liste];
    [neu[i], neu[j]] = [neu[j], neu[i]];
    setListe(neu); setGeaendert(true); setGespeichert(false);
  };
  const schalten = (i: number) => {
    if (!liste) return;
    setListe(liste.map((e, k) => k === i ? { ...e, an: !e.an } : e));
    setGeaendert(true); setGespeichert(false);
  };

  const speichern = async () => {
    if (!liste) return;
    setSpeichert(true);
    try {
      await setDoc(doc(db, 'settings', 'system'),
        { navigation: liste.map(e => ({ schluessel: e.schluessel, an: e.an, ort: e.ort, gruppe: e.gruppe ?? null })),
          navigationLayout: layout || navLayout(null),
          navigationGruppen: (gruppen || []).filter(g => Object.values(g.label || {}).some((v: any) => String(v || '').trim())) },
        { merge: true });
      setGeaendert(false); setGespeichert(true);
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || t('set.save_failed') });
    } finally {
      setSpeichert(false);
    }
  };

  if (!liste) return <div className="p-8 flex justify-center"><Loader2 className="animate-spin text-primary" /></div>;

  const sichtbar = liste.filter(e => e.an && e.moeglich && zeigtOben(e));
  const imFuss = liste.filter(e => e.an && e.moeglich && zeigtFuss(e));
  const lay = layout || navLayout(null);

  const Wahl = <W extends string>({ wert, optionen, setzen }:
    { wert: W; optionen: [W, string][]; setzen: (w: W) => void }) => (
    <div className="flex bg-stone-100 p-1 rounded-xl gap-1">
      {optionen.map(([w, label]) => (
        <button key={w} onClick={() => setzen(w)}
          className={`flex-1 px-3 py-2 rounded-lg text-xs font-bold transition-colors ${
            wert === w ? 'bg-white shadow-sm text-stone-900' : 'text-stone-500 hover:text-stone-800'}`}>
          {label}
        </button>
      ))}
    </div>
  );

  return (
    <div className="space-y-5">
      <div>
        <h3 className="font-bold text-stone-900">{t('navv.titel')}</h3>
        <p className="text-xs text-stone-500 leading-relaxed mt-1 max-w-2xl">{t('navv.hinweis')}</p>
      </div>

      {/* Wo die Navigation steht -- am Computer und auf dem Handy getrennt. */}
      <div className="bg-white border border-stone-100 rounded-2xl p-4 space-y-3">
        <p className="text-xs font-bold text-stone-500 uppercase tracking-wider">{t('navv.layout')}</p>
        <div className="grid md:grid-cols-2 gap-3">
          <div className="space-y-1.5">
            <p className="text-xs font-bold text-stone-700 flex items-center gap-1.5"><Monitor size={13} /> {t('navv.computer')}</p>
            <Wahl wert={lay.computer} setzen={(w) => { layoutSetzen({ computer: w }); if (w === 'MEGAMENU' && (gruppen || []).length === 0) vorschlag(); }}
              optionen={[['KOPFZEILE', t('navv.kopfzeile')], ['MEGAMENU', t('navv.megamenu')], ['SEITENLEISTE', t('navv.seitenleiste')]]} />
          </div>
          <div className="space-y-1.5">
            <p className="text-xs font-bold text-stone-700 flex items-center gap-1.5"><Smartphone size={13} /> {t('navv.handy')}</p>
            <Wahl wert={lay.handy} setzen={(w) => layoutSetzen({ handy: w })}
              optionen={[['MENUE', t('navv.menue')], ['LEISTE', t('navv.leiste_unten')]]} />
          </div>
        </div>
        {lay.handy === 'LEISTE' && <p className="text-[11px] text-stone-500">{t('navv.leiste_hinweis')}</p>}
        {lay.computer === 'MEGAMENU' && <p className="text-[11px] text-stone-500">{t('navv.mega_hinweis')}</p>}
      </div>

      {/* Untermenues. */}
      <div className="bg-white border border-stone-100 rounded-2xl p-4 space-y-3">
        <div className="flex items-start justify-between gap-3 flex-wrap">
          <div>
            <p className="text-xs font-bold text-stone-500 uppercase tracking-wider flex items-center gap-1.5"><FolderTree size={13} /> {t('navv.gruppen')}</p>
            <p className="text-[11px] text-stone-500 mt-1 max-w-xl leading-relaxed">{t('navv.gruppen_hinweis')}</p>
          </div>
          <div className="flex gap-1 bg-stone-100 p-1 rounded-lg">
            {(['de', 'sq', 'en'] as const).map(l => (
              <button key={l} onClick={() => setSprache(l)}
                className={`px-2 py-1 rounded-md text-[10px] font-bold uppercase ${sprache === l ? 'bg-white text-stone-900' : 'text-stone-400'}`}>{l}</button>
            ))}
          </div>
        </div>
        {(gruppen || []).map(g => (
          <div key={g.id} className="flex items-center gap-2">
            <input value={(typeof g.label === 'object' ? g.label?.[sprache] : (sprache === 'de' ? g.label : '')) || ''}
              onChange={e => gruppeAendern(g.id, e.target.value)}
              placeholder={`${t('navv.gruppe_name')} (${sprache})`}
              className="flex-1 p-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm font-bold outline-none" />
            <span className="text-[11px] text-stone-400 w-16 text-right shrink-0">
              {(liste || []).filter(e => e.gruppe === g.id).length} {t('navv.eintraege')}
            </span>
            <button onClick={() => gruppeWeg(g.id)} className="p-2 text-stone-300 hover:text-red-600"><Trash2 size={14} /></button>
          </div>
        ))}
        <div className="flex gap-2 flex-wrap">
          <button onClick={gruppeNeu}
            className="px-3 py-2 border-2 border-dashed border-stone-200 rounded-xl text-xs font-bold text-stone-500 hover:text-stone-900 flex items-center gap-1.5">
            <Plus size={13} /> {t('navv.gruppe_neu')}
          </button>
          {(gruppen || []).length === 0 && (
            <button onClick={vorschlag}
              className="px-3 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center gap-1.5">
              <Wand2 size={13} /> {t('navv.vorschlag')}
            </button>
          )}
        </div>
      </div>

      {/* Vorschau: was in der Navigation steht, was in der Fusszeile. */}
      <div className="space-y-2">
        <p className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">{t('navv.vorschau_oben')}</p>
        <div className={`bg-stone-50 border border-stone-100 rounded-2xl p-3 flex gap-1.5 ${
          lay.computer === 'SEITENLEISTE' ? 'flex-col items-start max-w-xs' : 'flex-wrap'}`}>
          {sichtbar.length === 0 && <span className="text-xs text-stone-400 italic p-2">{t('navv.leer')}</span>}
          {navBaum(sichtbar, gruppen || []).map(k => k.art === 'eintrag' ? (
            <span key={k.eintrag.schluessel} className="flex items-center gap-2 px-3 py-2 rounded-xl bg-white shadow-sm text-sm font-bold">
              {k.eintrag.icon}{k.eintrag.uebersetzen ? t(k.eintrag.label) : k.eintrag.label}
            </span>
          ) : (
            <span key={k.gruppe.id} title={k.eintraege.map(e => e.uebersetzen ? t(e.label) : e.label).join(', ')}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-white shadow-sm text-sm font-bold">
              {loc(k.gruppe.label) || '…'} <ChevronDown size={13} className="text-stone-400" />
              <span className="text-[10px] text-stone-400 font-normal">({k.eintraege.length})</span>
            </span>
          ))}
        </div>
        <p className="text-[10px] font-bold text-stone-400 uppercase tracking-wider pt-1">{t('navv.vorschau_fuss')}</p>
        <div className="bg-stone-800 rounded-2xl p-3 flex flex-wrap gap-x-4 gap-y-1.5">
          {imFuss.length === 0 && <span className="text-xs text-white/40 italic p-1">{t('navv.leer')}</span>}
          {imFuss.map(e => (
            <span key={e.schluessel} className="text-sm text-white/70">{e.uebersetzen ? t(e.label) : e.label}</span>
          ))}
        </div>
      </div>

      <div className="border border-stone-100 rounded-2xl divide-y divide-stone-100 bg-white">
        {liste.map((e, i) => (
          <div key={e.schluessel} className={`p-3 flex items-center gap-3 ${!e.an ? 'opacity-60' : ''}`}>
            <div className="flex flex-col">
              <button onClick={() => schieben(i, -1)} disabled={i === 0} className="p-1 text-stone-400 hover:text-stone-900 disabled:opacity-20" aria-label={t('navv.hoch')}><ArrowUp size={14} /></button>
              <button onClick={() => schieben(i, 1)} disabled={i === liste.length - 1} className="p-1 text-stone-400 hover:text-stone-900 disabled:opacity-20" aria-label={t('navv.runter')}><ArrowDown size={14} /></button>
            </div>
            <span className="shrink-0">{e.icon}</span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-stone-900 truncate">{e.uebersetzen ? t(e.label) : e.label}</p>
              <p className="text-[11px] text-stone-400 truncate">
                {e.pfad}{e.eigeneSeite ? ` · ${t('navv.eigene_seite')}` : ''}
              </p>
              {!e.moeglich && e.grund && (
                <p className="text-[11px] text-amber-700 flex items-center gap-1 mt-0.5"><AlertCircle size={11} /> {e.grund}</p>
              )}
            </div>
            {e.an && (gruppen || []).length > 0 && e.ort !== 'FUSS' && (
              <select value={e.gruppe || ''} onChange={ev => gruppeSetzen(i, ev.target.value)}
                aria-label={t('navv.gruppe')}
                className="px-2 py-2 bg-white border border-stone-200 rounded-xl text-xs font-bold shrink-0 max-w-[9rem]">
                <option value="">{t('navv.ohne_gruppe')}</option>
                {(gruppen || []).map(g => <option key={g.id} value={g.id}>{loc(g.label) || '…'}</option>)}
              </select>
            )}
            {e.an && (
              <select value={e.ort} onChange={ev => ortSetzen(i, ev.target.value as NavOrt)}
                aria-label={t('navv.ort')}
                className="px-2 py-2 bg-white border border-stone-200 rounded-xl text-xs font-bold shrink-0">
                <option value="OBEN">{t('navv.ort_oben')}</option>
                <option value="FUSS">{t('navv.ort_fuss')}</option>
                <option value="BEIDES">{t('navv.ort_beides')}</option>
              </select>
            )}
            <button onClick={() => schalten(i)}
              className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 shrink-0 ${
                e.an ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-500'}`}>
              {e.an ? <Eye size={13} /> : <EyeOff size={13} />} {e.an ? t('navv.an') : t('navv.aus')}
            </button>
          </div>
        ))}
      </div>

      <button onClick={speichern} disabled={speichert || !geaendert}
        className={`w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-3 transition-all disabled:opacity-60 ${
          gespeichert ? 'bg-green-500 text-white' : 'bg-primary text-white'}`}>
        {speichert ? <Loader2 className="animate-spin" size={18} /> : gespeichert ? <Check size={18} /> : <Save size={18} />}
        {gespeichert ? t('navv.gespeichert') : t('navv.speichern')}
      </button>
    </div>
  );
};

export default AdminNavigation;
