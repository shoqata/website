import React, { useRef, useState } from 'react';
import {
  ArrowUp, ArrowDown, Eye, EyeOff, Plus, Trash2, ChevronDown, ChevronUp, Upload, Loader2, X, LayoutList,
} from 'lucide-react';
import BausteinEditor from './BausteinEditor';
import { abschnitte, FESTE, WERT_SYMBOLE, WERT_NAMEN, wertSymbol, type Abschnitt } from '../lib/ueberUns';
import { bildHochladen } from '../lib/bildHochladen';
import { useTranslation } from '../context/LanguageContext';

// "Ueber uns" bearbeiten: Aufbau (Reihenfolge, An/Aus, eigene Abschnitte)
// und die Inhalte der festen Abschnitte.
//
// Alles hier lebt im Branding und wird mit dem Knopf "Veroeffentlichen"
// unten gespeichert -- wie die uebrigen Texte der Website. Der Vorstand
// steht weiter darueber (eigene Tabelle, sofort gespeichert), die Chronik
// im eigenen Reiter.
//
// Die Teile sind eigene Komponenten auf Modulebene. Innerhalb einer
// anderen Komponente definiert, waeren sie bei jedem Tastendruck neu
// entstanden -- das Feld haette nach jedem Buchstaben den Fokus verloren.

type Sprache = 'de' | 'sq' | 'en';
type Props = { branding: any; setBranding: (f: (b: any) => any) => void; sprache: Sprache };

const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-300';
const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

// Ein mehrsprachiges Feld lesen und setzen. Alte Eintraege sind einfache
// Zeichenketten: sie gelten als Deutsch und bleiben beim Setzen erhalten.
const lies = (v: any, s: Sprache): string =>
  !v ? '' : typeof v === 'string' ? (s === 'de' ? v : '') : (v[s] ?? '');
const setze = (v: any, s: Sprache, wert: string) =>
  ({ ...(typeof v === 'object' && v ? v : { de: typeof v === 'string' ? v : '' }), [s]: wert });

const Karte: React.FC<{ titel: string; hinweis?: string; offen: boolean; umschalten: () => void; children: React.ReactNode }> =
  ({ titel, hinweis, offen, umschalten, children }) => (
  <div className={`rounded-3xl border transition-colors ${offen ? 'bg-white border-stone-300 shadow-sm' : 'bg-stone-50 border-stone-200'}`}>
    <button type="button" onClick={umschalten} className="w-full flex items-center justify-between gap-3 p-5 text-left">
      <div>
        <p className="font-bold text-sm text-stone-900">{titel}</p>
        {hinweis && <p className="text-[11px] text-stone-400 mt-0.5">{hinweis}</p>}
      </div>
      {offen ? <ChevronUp size={18} className="text-stone-400" /> : <ChevronDown size={18} className="text-stone-300" />}
    </button>
    {offen && <div className="px-5 pb-5 space-y-4 border-t border-stone-100 pt-4">{children}</div>}
  </div>
);

// ------------------------------------------------------------ Aufbau
const Aufbau: React.FC<Props> = ({ branding, setBranding, sprache }) => {
  const { t } = useTranslation();
  const liste = abschnitte(branding.ueberUns);
  const [offen, setOffen] = useState<string | null>(null);
  const schreiben = (neu: Abschnitt[]) =>
    setBranding(b => ({ ...b, ueberUns: { ...(b.ueberUns || {}), abschnitte: neu } }));
  const aendern = (id: string, teil: Partial<Abschnitt>) =>
    schreiben(liste.map(a => a.id === id ? { ...a, ...teil } : a));
  const schieben = (i: number, um: number) => {
    const z = i + um; if (z < 0 || z >= liste.length) return;
    const n = [...liste]; [n[i], n[z]] = [n[z], n[i]]; schreiben(n);
  };
  const name = (a: Abschnitt) => a.art === 'eigen'
    ? (lies(a.titel, sprache) || lies(a.titel, 'de') || 'Eigener Abschnitt')
    : FESTE.find(f => f.art === a.art)?.name ?? a.art;

  return (
    <div className="space-y-2">
      {liste.map((a, i) => {
        const fest = FESTE.find(f => f.art === a.art);
        const istOffen = offen === a.id;
        return (
          <div key={a.id} className={`rounded-2xl border ${a.an ? 'bg-white border-stone-200' : 'bg-stone-50 border-stone-100'}`}>
            <div className="flex items-center gap-2 p-3">
              <div className="flex flex-col">
                <button type="button" onClick={() => schieben(i, -1)} disabled={i === 0}
                  className="p-0.5 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowUp size={13} /></button>
                <button type="button" onClick={() => schieben(i, 1)} disabled={i === liste.length - 1}
                  className="p-0.5 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowDown size={13} /></button>
              </div>
              <button type="button" onClick={() => setOffen(istOffen ? null : a.id)} className="flex-1 min-w-0 text-left">
                <p className={`text-sm font-bold truncate ${a.an ? 'text-stone-900' : 'text-stone-400'}`}>
                  {name(a)}
                  {a.art === 'eigen' && <span className="ml-2 text-[9px] uppercase tracking-widest text-primary">eigen</span>}
                </p>
                <p className="text-[11px] text-stone-400 truncate">{fest?.hinweis ?? `${a.bloecke?.length ?? 0} Bausteine`}</p>
              </button>
              <button type="button" onClick={() => aendern(a.id, { an: !a.an })}
                title={a.an ? 'Ausblenden' : 'Einblenden'}
                className={`p-2 rounded-lg ${a.an ? 'text-stone-600 hover:bg-stone-100' : 'text-stone-300 hover:bg-stone-100'}`}>
                {a.an ? <Eye size={15} /> : <EyeOff size={15} />}
              </button>
              {a.art === 'eigen' && (
                <button type="button" onClick={() => schreiben(liste.filter(x => x.id !== a.id))}
                  className="p-2 rounded-lg text-stone-300 hover:text-red-600 hover:bg-red-50"><Trash2 size={15} /></button>
              )}
            </div>
            {istOffen && (
              <div className="px-4 pb-4 pt-1 space-y-3 border-t border-stone-100">
                <div>
                  <label className={`${marke} block mb-1.5 mt-3`}>Überschrift ({sprache})</label>
                  <input className={feld} value={lies(a.titel, sprache)}
                    onChange={e => aendern(a.id, { titel: setze(a.titel, sprache, e.target.value) })}
                    placeholder={fest ? t(fest.titel) : 'Unser Dorf'} />
                  {fest && <p className="text-[10px] text-stone-400 mt-1">Leer lassen für die vorgegebene Überschrift.</p>}
                </div>
                {a.art === 'eigen' && (
                  <BausteinEditor sprache={sprache} bloecke={(a.bloecke ?? []) as any}
                    onChange={bloecke => aendern(a.id, { bloecke })} />
                )}
              </div>
            )}
          </div>
        );
      })}
      <button type="button"
        onClick={() => {
          const id = `eigen-${Date.now().toString(36)}`;
          schreiben([...liste, { id, art: 'eigen', an: true, titel: {}, bloecke: [{ art: 'text', text: {} }] }]);
          setOffen(id);
        }}
        className="w-full py-3 border-2 border-dashed border-stone-200 rounded-2xl text-stone-500 text-xs font-bold hover:text-stone-900 hover:border-stone-300 flex items-center justify-center gap-2">
        <Plus size={14} /> Eigenen Abschnitt hinzufügen
      </button>
      <p className="text-[10px] text-stone-400 leading-relaxed">
        Abschnitte ohne Inhalt erscheinen nicht, auch wenn sie eingeblendet sind — etwa „Geschichte“,
        solange die Chronik leer ist, oder „Vorstand“ ohne eingetragene Personen.
      </p>
    </div>
  );
};

// --------------------------------------------------------- Einleitung
const Einleitung: React.FC<Props> = ({ branding, setBranding, sprache }) => {
  const { t } = useTranslation();
  const eingabe = useRef<HTMLInputElement>(null);
  const [laedt, setLaedt] = useState(false);
  const [fehler, setFehler] = useState('');
  const f = (k: string, wert: string) => setBranding(b => ({ ...b, [k]: setze(b[k], sprache, wert) }));
  return (
    <>
      <div>
        <label className={`${marke} block mb-1.5`}>Kennzeichen ({sprache})</label>
        <input className={feld} value={lies(branding.aboutBadge, sprache)} onChange={e => f('aboutBadge', e.target.value)}
          placeholder={t('about.badge')} />
      </div>
      <div>
        <label className={`${marke} block mb-1.5`}>Titel ({sprache})</label>
        <input className={`${feld} font-bold`} value={lies(branding.aboutTitle, sprache)} onChange={e => f('aboutTitle', e.target.value)}
          placeholder={t('about.title')} />
      </div>
      <div>
        <label className={`${marke} block mb-1.5`}>Text ({sprache})</label>
        <textarea className={`${feld} leading-relaxed`} rows={6} value={lies(branding.aboutIntro, sprache)}
          onChange={e => f('aboutIntro', e.target.value)} placeholder={t('about.intro')} />
        <p className="text-[10px] text-stone-400 mt-1">Eine Leerzeile beginnt einen neuen Absatz.</p>
      </div>
      <div>
        <label className={`${marke} block mb-1.5`}>Gründungsjahr</label>
        <input type="number" className={feld} value={branding.gruendungsjahr ?? ''} placeholder="1994"
          onChange={e => setBranding(b => ({ ...b, gruendungsjahr: e.target.value ? Number(e.target.value) : null }))} />
        <p className="text-[10px] text-stone-400 mt-1">Ergibt „seit …“ und die Zahl der Jahre. Leer: das erste Jahr der Chronik.</p>
      </div>
      <div>
        <label className={`${marke} block mb-1.5`}>Bild statt Globus</label>
        {branding.aboutBild ? (
          <div className="relative">
            <img src={branding.aboutBild} alt="" className="w-full aspect-[4/3] object-cover rounded-2xl border border-stone-100" />
            <button type="button" onClick={() => setBranding(b => ({ ...b, aboutBild: '' }))}
              className="absolute top-2 right-2 w-8 h-8 bg-white/90 rounded-full flex items-center justify-center text-stone-600 hover:text-red-600"><X size={15} /></button>
          </div>
        ) : (
          <button type="button" onClick={() => eingabe.current?.click()} disabled={laedt}
            className="w-full py-6 border-2 border-dashed border-stone-200 rounded-2xl text-stone-500 text-xs font-bold flex items-center justify-center gap-2 hover:border-stone-300">
            {laedt ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />} Bild hochladen (sonst Globus mit den Mitgliedern)
          </button>
        )}
        <input ref={eingabe} type="file" accept="image/*" hidden onChange={async e => {
          const d = e.target.files?.[0]; e.target.value = '';
          if (!d) return;
          setLaedt(true); setFehler('');
          try { const url = await bildHochladen(d, 'branding'); setBranding(b => ({ ...b, aboutBild: url })); }
          catch (err: any) { setFehler(err?.message || 'Hochladen fehlgeschlagen.'); }
          finally { setLaedt(false); }
        }} />
        {fehler && <p className="text-[11px] text-red-600 mt-1">{fehler}</p>}
      </div>
    </>
  );
};

// ------------------------------------------------------- Listen-Editor
// Werte, Kennzahlen und Ziele sind dieselbe Form: eine Liste von Karten
// mit Titel und Text, verschiebbar, loeschbar.
const Liste: React.FC<Props & {
  schluessel: 'missions' | 'roadmap' | 'ueberUnsZahlen';
  felder: { k: string; name: string; mehrsprachig: boolean; lang?: boolean; platzhalter: string }[];
  neu: any; knopf: string; symbol?: boolean;
}> = ({ branding, setBranding, sprache, schluessel, felder, neu, knopf, symbol }) => {
  const eintraege: any[] = branding[schluessel] || [];
  const schreiben = (n: any[]) => setBranding(b => ({ ...b, [schluessel]: n }));
  const aendern = (i: number, k: string, wert: any) =>
    schreiben(eintraege.map((e, n) => n === i ? { ...e, [k]: wert } : e));
  const schieben = (i: number, um: number) => {
    const z = i + um; if (z < 0 || z >= eintraege.length) return;
    const n = [...eintraege]; [n[i], n[z]] = [n[z], n[i]]; schreiben(n);
  };
  return (
    <div className="space-y-3">
      {eintraege.map((e, i) => (
        <div key={i} className="bg-stone-50 rounded-2xl border border-stone-200 p-3 space-y-2">
          <div className="flex items-center gap-2">
            {symbol && (
              <select className="p-2 bg-white border border-stone-200 rounded-lg text-xs font-bold"
                value={wertSymbol(e.type)} onChange={ev => aendern(i, 'type', ev.target.value)}>
                {WERT_SYMBOLE.map(s => <option key={s} value={s}>{WERT_NAMEN[s]}</option>)}
              </select>
            )}
            <div className="flex-1" />
            <button type="button" onClick={() => schieben(i, -1)} disabled={i === 0}
              className="p-1 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowUp size={13} /></button>
            <button type="button" onClick={() => schieben(i, 1)} disabled={i === eintraege.length - 1}
              className="p-1 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowDown size={13} /></button>
            <button type="button" onClick={() => schreiben(eintraege.filter((_, n) => n !== i))}
              className="p-1 text-stone-300 hover:text-red-600"><Trash2 size={13} /></button>
          </div>
          {felder.map(f => {
            const wert = f.mehrsprachig ? lies(e[f.k], sprache) : (e[f.k] ?? '');
            const setzen = (v: string) => aendern(i, f.k, f.mehrsprachig ? setze(e[f.k], sprache, v) : v);
            return f.lang
              ? <textarea key={f.k} className={`${feld} leading-relaxed`} rows={3} value={wert}
                  onChange={ev => setzen(ev.target.value)} placeholder={`${f.platzhalter}${f.mehrsprachig ? ` (${sprache})` : ''}`} />
              : <input key={f.k} className={`${feld} ${f.k === 'title' ? 'font-bold' : ''}`} value={wert}
                  onChange={ev => setzen(ev.target.value)} placeholder={`${f.platzhalter}${f.mehrsprachig ? ` (${sprache})` : ''}`} />;
          })}
        </div>
      ))}
      <button type="button" onClick={() => schreiben([...eintraege, neu])}
        className="w-full py-2.5 border-2 border-dashed border-stone-200 rounded-xl text-stone-500 text-xs font-bold hover:text-stone-900 hover:border-stone-300 flex items-center justify-center gap-1.5">
        <Plus size={13} /> {knopf}
      </button>
    </div>
  );
};

const Mitmachen: React.FC<Props> = ({ branding, setBranding, sprache }) => {
  const { t } = useTranslation();
  const f = (k: string, wert: string) => setBranding(b => ({ ...b, [k]: setze(b[k], sprache, wert) }));
  return (
    <>
      <input className={`${feld} font-bold`} value={lies(branding.mitmachenTitel, sprache)}
        onChange={e => f('mitmachenTitel', e.target.value)} placeholder={t('about.mitmachen.titel')} />
      <textarea className={`${feld} leading-relaxed`} rows={3} value={lies(branding.mitmachenText, sprache)}
        onChange={e => f('mitmachenText', e.target.value)} placeholder={t('about.mitmachen.text')} />
      <p className="text-[10px] text-stone-400">
        Darunter stehen „Mitglied werden“ und die Kontaktadresse aus Allgemein → Fusszeile.
      </p>
    </>
  );
};

// --------------------------------------------------------------- Ganzes
const AdminUeberUns: React.FC<Props> = (p) => {
  const [offen, setOffen] = useState<string | null>('aufbau');
  const k = (id: string) => ({ offen: offen === id, umschalten: () => setOffen(offen === id ? null : id) });
  return (
    <div className="space-y-3">
      <Karte titel="Aufbau der Seite" hinweis="Reihenfolge, ein- und ausblenden, eigene Abschnitte" {...k('aufbau')}>
        <div className="flex items-center gap-2 text-[11px] text-stone-500 -mt-1">
          <LayoutList size={13} /> Mit den Pfeilen verschieben, mit dem Auge ein- und ausblenden.
        </div>
        <Aufbau {...p} />
      </Karte>
      <Karte titel="Einleitung" hinweis="Titel, Text, Gründungsjahr, Bild" {...k('einleitung')}>
        <Einleitung {...p} />
      </Karte>
      <Karte titel="Werte" hinweis={`${(p.branding.missions || []).length} Karten`} {...k('werte')}>
        <Liste {...p} schluessel="missions" symbol knopf="Karte hinzufügen" neu={{ type: 'HERZ', title: {}, description: {} }}
          felder={[{ k: 'title', name: 'Titel', mehrsprachig: true, platzhalter: 'Zusammenhalt' },
                   { k: 'description', name: 'Text', mehrsprachig: true, lang: true, platzhalter: 'Wofür steht das?' }]} />
      </Karte>
      <Karte titel="Eigene Kennzahlen" hinweis="Zusätzlich zu Mitgliedern, Nachbarschaften, Ländern und Jahren" {...k('zahlen')}>
        <Liste {...p} schluessel="ueberUnsZahlen" knopf="Kennzahl hinzufügen" neu={{ wert: '', text: {} }}
          felder={[{ k: 'wert', name: 'Wert', mehrsprachig: false, platzhalter: 'CHF 120 000' },
                   { k: 'text', name: 'Beschriftung', mehrsprachig: true, platzhalter: 'für Projekte im Dorf' }]} />
      </Karte>
      <Karte titel="Ziele" hinweis={`${(p.branding.roadmap || []).length} Ziele`} {...k('ziele')}>
        <Liste {...p} schluessel="roadmap" knopf="Ziel hinzufügen" neu={{ title: {}, description: {} }}
          felder={[{ k: 'title', name: 'Titel', mehrsprachig: true, platzhalter: 'Neues Vereinslokal' },
                   { k: 'description', name: 'Text', mehrsprachig: true, lang: true, platzhalter: 'Was, bis wann, wozu?' }]} />
      </Karte>
      <Karte titel="Mitmachen" hinweis="Der Aufruf am Ende der Seite" {...k('mitmachen')}>
        <Mitmachen {...p} />
      </Karte>
    </div>
  );
};

export default AdminUeberUns;
