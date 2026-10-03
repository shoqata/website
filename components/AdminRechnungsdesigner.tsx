import React, { useEffect, useRef, useState, useCallback } from 'react';
import { Loader2, RotateCcw, Save, Check, Lock, Eye, EyeOff, Move } from 'lucide-react';
import { doc, onSnapshot, setDoc } from '@/services/supabase-bridge';
import { db } from '../services/firebase';
import { useTranslation } from '../context/LanguageContext';
import {
  BLATT, ZAHLTEIL, VORGABE, FELDNAMEN,
  begrenzen, layoutLesen, type Feld, type Rechnungslayout,
} from '../lib/rechnungslayout';

// Der Rechnungsdesigner.
//
// Er zeigt ein Blatt A4 im Massstab und darauf jedes Feld als Kasten mit
// seiner Lage in Millimetern. Ziehen verschiebt, die Pfeiltasten verschieben
// um 1 mm, mit Umschalt um 0,1 mm -- weil man eine Rechnung am Ende auf
// einen halben Millimeter genau haben will und das mit der Maus nicht geht.
//
// Die unteren 105 mm sind gesperrt. Dort liegt der Zahlteil, dessen Masse
// die Swiss-QR-Bill-Richtlinien auf den Millimeter vorschreiben. Sie werden
// angezeigt, damit man sie nachmessen kann -- verstellen laesst sich dort
// nichts. Ein Verein, der den Empfangsschein um 3 mm verschoebe, bekaeme
// einen Beleg, der im Browser gut aussieht und an der Kasse abgewiesen wird.

const PX_JE_MM = 2.1;   // Darstellung; gespeichert werden immer Millimeter

const AdminRechnungsdesigner: React.FC = () => {
  const { t, language } = useTranslation();
  const blatt = useRef<HTMLDivElement>(null);
  const [layout, setLayout] = useState<Rechnungslayout>(VORGABE);
  const [gewaehlt, setGewaehlt] = useState<string>('logo');
  const [zieht, setZieht] = useState<string | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [geaendert, setGeaendert] = useState(false);

  useEffect(() => {
    const ab = onSnapshot(doc(db, 'settings', 'rechnungslayout'), (s: any) => {
      if (s.exists()) setLayout(layoutLesen(s.data()));
    });
    return () => ab();
  }, []);

  const name = (k: string) =>
    FELDNAMEN[k]?.[language as 'de' | 'en' | 'sq'] ?? FELDNAMEN[k]?.de ?? k;

  const setzen = useCallback((k: string, teil: Partial<Feld>) => {
    setLayout(l => ({ ...l, felder: { ...l.felder, [k]: begrenzen({ ...l.felder[k], ...teil }) } }));
    setGeaendert(true);
  }, []);

  // Ziehen. Gerechnet wird in Millimetern, nicht in Pixeln: der Massstab
  // der Darstellung darf das gespeicherte Ergebnis nicht beeinflussen.
  useEffect(() => {
    if (!zieht) return;
    const el = blatt.current;
    if (!el) return;
    const bewegen = (e: PointerEvent) => {
      const r = el.getBoundingClientRect();
      const mmX = ((e.clientX - r.left) / r.width) * BLATT.breite;
      const mmY = ((e.clientY - r.top) / r.height) * BLATT.hoehe;
      const f = layout.felder[zieht];
      setzen(zieht, {
        x: Math.round((mmX - (f.breite ?? 40) / 2) * 10) / 10,
        y: Math.round(mmY * 10) / 10,
      });
    };
    const los = () => setZieht(null);
    window.addEventListener('pointermove', bewegen);
    window.addEventListener('pointerup', los);
    return () => {
      window.removeEventListener('pointermove', bewegen);
      window.removeEventListener('pointerup', los);
    };
  }, [zieht, layout.felder, setzen]);

  // Tastatur: genauer als die Maus, und ohne sie gar nicht bedienbar.
  const taste = (e: React.KeyboardEvent, k: string) => {
    const schritt = e.shiftKey ? 0.1 : 1;
    const f = layout.felder[k];
    const bewegt: Record<string, Partial<Feld>> = {
      ArrowLeft:  { x: Math.round((f.x - schritt) * 10) / 10 },
      ArrowRight: { x: Math.round((f.x + schritt) * 10) / 10 },
      ArrowUp:    { y: Math.round((f.y - schritt) * 10) / 10 },
      ArrowDown:  { y: Math.round((f.y + schritt) * 10) / 10 },
    };
    if (bewegt[e.key]) { e.preventDefault(); setzen(k, bewegt[e.key]); }
  };

  const sichern = async () => {
    setSpeichert(true);
    try {
      await setDoc(doc(db, 'settings', 'rechnungslayout'), layout, { merge: false });
      setGespeichert(true); setGeaendert(false);
      setTimeout(() => setGespeichert(false), 2500);
    } finally { setSpeichert(false); }
  };

  const f = layout.felder[gewaehlt];

  return (
    <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">

      {/* ---------- Das Blatt ---------- */}
      <div className="xl:col-span-7">
        <div ref={blatt}
             className="relative bg-white shadow-xl mx-auto select-none"
             style={{ width: BLATT.breite * PX_JE_MM, height: BLATT.hoehe * PX_JE_MM }}>

          {/* Millimeterraster, nur als Orientierung */}
          <div className="absolute inset-0 pointer-events-none opacity-[0.5]"
               style={{ backgroundImage:
                 'linear-gradient(to right, #e7e5e4 1px, transparent 1px),' +
                 'linear-gradient(to bottom, #e7e5e4 1px, transparent 1px)',
                 backgroundSize: `${10 * PX_JE_MM}px ${10 * PX_JE_MM}px` }} />

          {/* Die gesperrte Zone des Zahlteils */}
          <div className="absolute left-0 right-0 border-t-2 border-dashed border-stone-400
                          bg-[repeating-linear-gradient(135deg,#f5f5f4_0,#f5f5f4_6px,#ffffff_6px,#ffffff_12px)]"
               style={{ top: ZAHLTEIL.oben * PX_JE_MM, height: ZAHLTEIL.hoehe * PX_JE_MM }}>
            <div className="absolute inset-0 flex">
              <div className="border-r-2 border-dashed border-stone-400 flex flex-col justify-between p-2"
                   style={{ width: ZAHLTEIL.empfangsschein * PX_JE_MM }}>
                <p className="text-[8px] font-bold text-stone-500 uppercase tracking-wider">Empfangsschein</p>
                <p className="text-[8px] text-stone-400 tabular-nums">{ZAHLTEIL.empfangsschein} × {ZAHLTEIL.hoehe} mm</p>
              </div>
              <div className="flex-1 p-2 relative">
                <p className="text-[8px] font-bold text-stone-500 uppercase tracking-wider">Zahlteil</p>
                {/* Der Code mit seinen vorgeschriebenen Massen */}
                <div className="absolute border border-stone-400 bg-white/70 flex items-center justify-center"
                     style={{ left: 5 * PX_JE_MM, top: 17 * PX_JE_MM,
                              width: ZAHLTEIL.qrSeite * PX_JE_MM, height: ZAHLTEIL.qrSeite * PX_JE_MM }}>
                  <div className="text-center">
                    <div className="mx-auto border border-stone-500 bg-stone-900"
                         style={{ width: ZAHLTEIL.kreuz * PX_JE_MM, height: ZAHLTEIL.kreuz * PX_JE_MM }} />
                    <p className="text-[7px] text-stone-500 mt-1 tabular-nums">{ZAHLTEIL.qrSeite} × {ZAHLTEIL.qrSeite} mm</p>
                  </div>
                </div>
                <p className="absolute bottom-2 right-2 text-[8px] text-stone-400 tabular-nums">
                  {ZAHLTEIL.zahlteil} × {ZAHLTEIL.hoehe} mm
                </p>
              </div>
            </div>
            <div className="absolute -top-[9px] left-3 bg-white px-2 flex items-center gap-1">
              <Lock size={9} className="text-stone-500" />
              <span className="text-[9px] font-bold text-stone-500 uppercase tracking-wider">
                {t('rdes.gesperrt')}
              </span>
            </div>
          </div>

          {/* Die beweglichen Felder */}
          {Object.values(layout.felder).map(fe => {
            const aktiv = fe.schluessel === gewaehlt;
            return (
              <button key={fe.schluessel} type="button"
                onPointerDown={e => { e.preventDefault(); setGewaehlt(fe.schluessel); setZieht(fe.schluessel); }}
                onFocus={() => setGewaehlt(fe.schluessel)}
                onKeyDown={e => taste(e, fe.schluessel)}
                className={`absolute text-left px-1.5 py-1 rounded-[3px] border transition-colors cursor-move
                  ${!fe.sichtbar ? 'opacity-35 border-dashed' : ''}
                  ${aktiv ? 'border-primary bg-[color:color-mix(in_srgb,var(--primary)_12%,transparent)] z-20 ring-1 ring-primary'
                          : 'border-stone-300 bg-white/85 hover:border-stone-500 z-10'}`}
                style={{
                  left: fe.x * PX_JE_MM, top: fe.y * PX_JE_MM,
                  width: (fe.breite ?? 40) * PX_JE_MM,
                  minHeight: Math.max(6, (fe.groesse / 72) * 25.4) * PX_JE_MM,
                }}>
                <span className="block text-[9px] font-bold leading-tight text-stone-700 truncate">
                  {name(fe.schluessel)}
                </span>
                <span className="block text-[8px] text-stone-400 tabular-nums">
                  {fe.x} · {fe.y} mm
                </span>
              </button>
            );
          })}
        </div>

        <p className="text-[11px] text-stone-400 text-center mt-3">{t('rdes.bedienung')}</p>
      </div>

      {/* ---------- Die Einstellungen ---------- */}
      <div className="xl:col-span-5 space-y-5">

        <div className="bg-white rounded-3xl border border-stone-100 p-5 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <Move size={15} className="text-stone-400" />
            <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{name(gewaehlt)}</h3>
          </div>

          <div className="grid grid-cols-2 gap-3 mb-4">
            {([['x', t('rdes.von_links')], ['y', t('rdes.von_oben')]] as const).map(([s, bez]) => (
              <label key={s} className="block">
                <span className="text-[10px] font-bold text-stone-400 uppercase tracking-wider block mb-1">{bez}</span>
                <div className="flex items-center gap-1.5 bg-stone-50 border border-stone-200 rounded-xl px-3 py-2">
                  <input type="number" step="0.1" value={f[s]}
                         onChange={e => setzen(gewaehlt, { [s]: Number(e.target.value) })}
                         className="w-full bg-transparent text-sm tabular-nums outline-none" />
                  <span className="text-[10px] text-stone-400">mm</span>
                </div>
              </label>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3 mb-4">
            {f.breite !== undefined && (
              <label className="block">
                <span className="text-[10px] font-bold text-stone-400 uppercase tracking-wider block mb-1">{t('rdes.breite')}</span>
                <div className="flex items-center gap-1.5 bg-stone-50 border border-stone-200 rounded-xl px-3 py-2">
                  <input type="number" step="1" value={f.breite}
                         onChange={e => setzen(gewaehlt, { breite: Number(e.target.value) })}
                         className="w-full bg-transparent text-sm tabular-nums outline-none" />
                  <span className="text-[10px] text-stone-400">mm</span>
                </div>
              </label>
            )}
            <label className="block">
              <span className="text-[10px] font-bold text-stone-400 uppercase tracking-wider block mb-1">{t('rdes.schriftgrad')}</span>
              <div className="flex items-center gap-1.5 bg-stone-50 border border-stone-200 rounded-xl px-3 py-2">
                <input type="number" step="0.5" min="6" max="36" value={f.groesse}
                       onChange={e => setzen(gewaehlt, { groesse: Number(e.target.value) })}
                       className="w-full bg-transparent text-sm tabular-nums outline-none" />
                <span className="text-[10px] text-stone-400">pt</span>
              </div>
            </label>
          </div>

          <button type="button" onClick={() => setzen(gewaehlt, { sichtbar: !f.sichtbar })}
            className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl border border-stone-200
                       text-[11px] font-bold uppercase tracking-widest text-stone-500 hover:border-stone-300">
            {f.sichtbar ? <Eye size={13} /> : <EyeOff size={13} />}
            {f.sichtbar ? t('rdes.sichtbar') : t('rdes.verborgen')}
          </button>
        </div>

        <div className="bg-amber-50/60 border border-amber-100 rounded-2xl p-4">
          <p className="text-[11px] text-amber-800 leading-relaxed">{t('rdes.zahlteil_hinweis')}</p>
        </div>

        <div className="flex gap-3">
          <button type="button" onClick={() => { setLayout(VORGABE); setGeaendert(true); }}
            className="flex items-center gap-2 px-4 py-3 rounded-xl border border-stone-200
                       text-[11px] font-bold uppercase tracking-widest text-stone-500 hover:border-stone-300">
            <RotateCcw size={13} /> {t('rdes.zuruecksetzen')}
          </button>
          <button type="button" onClick={sichern} disabled={speichert || !geaendert}
            className="flex-1 knopf-primaer text-white flex items-center justify-center gap-2 px-4 py-3
                       rounded-xl text-[11px] font-bold uppercase tracking-widest disabled:opacity-40">
            {speichert ? <Loader2 size={14} className="animate-spin" />
              : gespeichert ? <Check size={14} /> : <Save size={14} />}
            {gespeichert ? t('rdes.gespeichert') : t('rdes.speichern')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdminRechnungsdesigner;
