import React, { useRef, useState } from 'react';
import {
  Trash2, Type, AlignLeft, Image as BildIcon, Link2, Minus, Quote, ArrowUp, ArrowDown, Upload, Loader2,
} from 'lucide-react';
import { bildHochladen } from '../lib/bildHochladen';

// Bausteine bearbeiten -- fuer eigene Seiten und fuer die eigenen
// Abschnitte auf "Ueber uns". Vorher stand der Editor nur in
// AdminSeiten; ein zweiter Ort haette eine zweite Abschrift bedeutet, und
// Abschriften laufen auseinander.
//
// Die Arten sind fest (siehe EigeneSeite.tsx): kein freies HTML.

type Sprachfeld = { de?: string; sq?: string; en?: string };
export type Baustein =
  | { art: 'ueberschrift'; text: Sprachfeld }
  | { art: 'text'; text: Sprachfeld }
  | { art: 'zitat'; text: Sprachfeld; wer?: Sprachfeld }
  | { art: 'bild'; url: string; alt?: Sprachfeld }
  | { art: 'knopf'; text: Sprachfeld; ziel: string }
  | { art: 'trenner' };

export const ARTEN: { art: Baustein['art']; name: string; icon: React.ReactNode }[] = [
  { art: 'ueberschrift', name: 'Überschrift', icon: <Type size={13} /> },
  { art: 'text',         name: 'Text',        icon: <AlignLeft size={13} /> },
  { art: 'bild',         name: 'Bild',        icon: <BildIcon size={13} /> },
  { art: 'knopf',        name: 'Knopf',       icon: <Link2 size={13} /> },
  { art: 'zitat',        name: 'Zitat',       icon: <Quote size={13} /> },
  { art: 'trenner',      name: 'Trennlinie',  icon: <Minus size={13} /> },
];

const neu = (art: Baustein['art']): Baustein =>
  art === 'trenner' ? { art: 'trenner' }
  : art === 'bild' ? { art: 'bild', url: '', alt: {} }
  : art === 'knopf' ? { art: 'knopf', text: {}, ziel: '' }
  : { art, text: {} } as Baustein;

const BildFeld: React.FC<{ url: string; onUrl: (u: string) => void; feld: string }> = ({ url, onUrl, feld }) => {
  const eingabe = useRef<HTMLInputElement>(null);
  const [laedt, setLaedt] = useState(false);
  const [fehler, setFehler] = useState('');
  return (
    <div className="space-y-2">
      <div className="flex gap-2">
        <input className={feld} value={url} onChange={e => onUrl(e.target.value)}
          placeholder="https://… oder hochladen" />
        <button type="button" onClick={() => eingabe.current?.click()} disabled={laedt}
          className="shrink-0 px-3 bg-stone-100 hover:bg-stone-200 rounded-xl text-stone-600 flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest">
          {laedt ? <Loader2 size={13} className="animate-spin" /> : <Upload size={13} />} Hochladen
        </button>
        <input ref={eingabe} type="file" accept="image/*" hidden onChange={async e => {
          const d = e.target.files?.[0]; e.target.value = '';
          if (!d) return;
          setLaedt(true); setFehler('');
          try { onUrl(await bildHochladen(d, 'seiten')); }
          catch (err: any) { setFehler(err?.message || 'Hochladen fehlgeschlagen.'); }
          finally { setLaedt(false); }
        }} />
      </div>
      {url && <img src={url} alt="" className="h-20 rounded-lg border border-stone-100 object-cover" />}
      {fehler && <p className="text-[11px] text-red-600">{fehler}</p>}
    </div>
  );
};

const BausteinEditor: React.FC<{
  bloecke: Baustein[];
  onChange: (b: Baustein[]) => void;
  sprache: 'de' | 'sq' | 'en';
  /** Welche Arten angeboten werden; ohne Angabe alle. */
  arten?: Baustein['art'][];
}> = ({ bloecke, onChange, sprache, arten }) => {
  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-300';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';
  const sf = (b: any, k: string) => (b[k] ?? {})[sprache] ?? '';
  const setze = (i: number, teil: any) =>
    onChange(bloecke.map((b, n) => n === i ? ({ ...b, ...teil } as Baustein) : b));
  const schieben = (i: number, um: number) => {
    const z = i + um;
    if (z < 0 || z >= bloecke.length) return;
    const n = [...bloecke]; [n[i], n[z]] = [n[z], n[i]];
    onChange(n);
  };

  return (
    <div className="space-y-3">
      {bloecke.map((b, i) => (
        <div key={i} className="bg-white rounded-2xl border border-stone-100 p-4">
          <div className="flex items-center justify-between gap-2 mb-3">
            <span className={marke}>{ARTEN.find(a => a.art === b.art)?.name ?? b.art}</span>
            <div className="flex gap-1">
              <button type="button" onClick={() => schieben(i, -1)} disabled={i === 0}
                className="p-1 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowUp size={13} /></button>
              <button type="button" onClick={() => schieben(i, 1)} disabled={i === bloecke.length - 1}
                className="p-1 text-stone-300 hover:text-stone-700 disabled:opacity-30"><ArrowDown size={13} /></button>
              <button type="button" onClick={() => onChange(bloecke.filter((_, n) => n !== i))}
                className="p-1 text-stone-300 hover:text-red-600"><Trash2 size={13} /></button>
            </div>
          </div>

          {b.art === 'trenner' ? (
            <hr className="border-stone-200" />
          ) : b.art === 'bild' ? (
            <div className="space-y-2">
              <BildFeld url={b.url ?? ''} onUrl={u => setze(i, { url: u })} feld={feld} />
              <input className={feld} value={sf(b, 'alt')}
                onChange={e => setze(i, { alt: { ...b.alt, [sprache]: e.target.value } })}
                placeholder="Bildbeschreibung (für Blinde und Suchmaschinen)" />
            </div>
          ) : b.art === 'knopf' ? (
            <div className="space-y-2">
              <input className={feld} value={sf(b, 'text')}
                onChange={e => setze(i, { text: { ...b.text, [sprache]: e.target.value } })}
                placeholder="Jetzt anmelden" />
              <input className={feld} value={b.ziel ?? ''}
                onChange={e => setze(i, { ziel: e.target.value })}
                placeholder="/events oder https://…" />
            </div>
          ) : (
            <div className="space-y-2">
              <textarea className={`${feld} leading-relaxed`}
                rows={b.art === 'text' ? 6 : 2} value={sf(b, 'text')}
                onChange={e => setze(i, { text: { ...(b as any).text, [sprache]: e.target.value } })}
                placeholder={b.art === 'ueberschrift' ? 'Seit 1998' : 'Schreiben Sie hier …'} />
              {b.art === 'zitat' && (
                <input className={feld} value={sf(b, 'wer')}
                  onChange={e => setze(i, { wer: { ...b.wer, [sprache]: e.target.value } })}
                  placeholder="Wer hat das gesagt?" />
              )}
            </div>
          )}
        </div>
      ))}

      <div className="flex flex-wrap gap-2">
        {ARTEN.filter(a => !arten || arten.includes(a.art)).map(a => (
          <button key={a.art} type="button" onClick={() => onChange([...bloecke, neu(a.art)])}
            className="flex items-center gap-1.5 bg-white border border-stone-200 px-3 py-2
                       rounded-xl text-[10px] font-bold uppercase tracking-widest
                       text-stone-500 hover:text-stone-900 hover:border-stone-300">
            {a.icon} {a.name}
          </button>
        ))}
      </div>
    </div>
  );
};

export default BausteinEditor;
