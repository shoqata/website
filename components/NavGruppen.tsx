import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { ChevronDown, ArrowRight, UserPlus } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import type { NavEintrag, NavGruppe } from './kopfzeile';

// Ein Untermenue in der Kopfzeile -- als kleine Liste (Kopfzeile) oder als
// breites Feld mit Beschreibungen (Megamenue).
//
// Oeffnet beim Darueberfahren und beim Klicken: mit der Maus genuegt das
// Zeigen, auf dem Tablet und mit der Tastatur braucht es den Klick. Esc
// und ein Klick daneben schliessen.
//
// Das Megamenue oeffnet sich unter seinem Knopf, mittig und hoechstens
// 44rem breit -- nicht ueber die ganze Leiste: ein Feld ueber die volle
// Breite mit drei Eintraegen sah leer aus und loeste sich vom Knopf.

const Tafel = 'nav-tafel border rounded-2xl shadow-2xl';

export const KopfGruppe: React.FC<{
  gruppe: NavGruppe; eintraege: NavEintrag[]; mega: boolean; angemeldet: boolean;
}> = ({ gruppe, eintraege, mega, angemeldet }) => {
  const { t, loc } = useTranslation();
  const { pathname } = useLocation();
  const [offen, setOffen] = useState(false);
  const rahmen = useRef<HTMLDivElement>(null);
  const zu = useRef<number | null>(null);
  // Wann das Zeigen geoeffnet hat: ein Klick kurz danach soll nicht
  // wieder schliessen -- mit der Maus fuehrt man beides fast gleichzeitig aus.
  const geoeffnetAm = useRef(0);
  const aktiv = eintraege.some(e => e.pfad === pathname);
  const label = (e: NavEintrag) => e.uebersetzen ? t(e.label) : e.label;

  useEffect(() => { setOffen(false); }, [pathname]);
  useEffect(() => {
    if (!offen) return;
    const klick = (e: MouseEvent) => { if (!rahmen.current?.contains(e.target as Node)) setOffen(false); };
    const taste = (e: KeyboardEvent) => { if (e.key === 'Escape') setOffen(false); };
    document.addEventListener('mousedown', klick);
    document.addEventListener('keydown', taste);
    return () => { document.removeEventListener('mousedown', klick); document.removeEventListener('keydown', taste); };
  }, [offen]);

  const rein = () => {
    if (zu.current) window.clearTimeout(zu.current);
    if (!offen) geoeffnetAm.current = Date.now();
    setOffen(true);
  };
  const klick = () => setOffen(o => (o && Date.now() - geoeffnetAm.current < 600) ? true : !o);
  const raus = () => { zu.current = window.setTimeout(() => setOffen(false), 160); };

  return (
    <div ref={rahmen} className="relative" onMouseEnter={rein} onMouseLeave={raus}>
      <button type="button" aria-expanded={offen} aria-haspopup="true" onClick={klick}
        className={`flex items-center gap-1.5 px-3 py-2 rounded-xl transition ${aktiv || offen ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
        <span className="font-bold text-sm">{loc(gruppe.label)}</span>
        <ChevronDown size={14} className={`transition-transform ${offen ? 'rotate-180' : ''}`} />
      </button>

      {offen && !mega && (
        <div className="absolute left-0 top-full pt-3 z-50 min-w-[15rem]">
          <div className={`${Tafel} p-2`}>
            {eintraege.map(e => (
              <Link key={e.schluessel} to={e.pfad}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-bold nav-tafel-eintrag ${e.pfad === pathname ? 'nav-tafel-aktiv' : ''}`}>
                {e.icon}<span>{label(e)}</span>
              </Link>
            ))}
          </div>
        </div>
      )}

      {offen && mega && (
        <div className="absolute left-1/2 -translate-x-1/2 top-full pt-3 z-50"
             style={{ width: `min(${angemeldet ? (eintraege.length > 4 ? 40 : 30) : 44}rem, calc(100vw - 2rem))` }}>
          <div className={`${Tafel} p-5 grid grid-cols-1 ${angemeldet ? '' : 'md:grid-cols-3'} gap-5`}>
            <div className={angemeldet ? '' : 'md:col-span-2'}>
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-primary mb-4">{loc(gruppe.label)}</p>
              <div className={`grid gap-1 ${eintraege.length > 4 ? 'grid-cols-2' : 'grid-cols-1'}`}>
                {eintraege.map(e => {
                  const b = e.beschreibung ? t(e.beschreibung) : '';
                  return (
                    <Link key={e.schluessel} to={e.pfad}
                      className={`flex items-start gap-3 p-3 rounded-xl nav-tafel-eintrag ${e.pfad === pathname ? 'nav-tafel-aktiv' : ''}`}>
                      <span className="w-9 h-9 rounded-xl tupfer-primaer flex items-center justify-center shrink-0">{e.icon}</span>
                      <span className="min-w-0">
                        <span className="block text-sm font-bold">{label(e)}</span>
                        {b && b !== e.beschreibung && <span className="block text-xs nav-tafel-leise leading-snug mt-0.5">{b}</span>}
                      </span>
                    </Link>
                  );
                })}
              </div>
            </div>
            {!angemeldet && (
              <div className="rounded-xl tupfer-primaer p-5 flex flex-col">
                <p className="font-display text-lg font-bold leading-snug">{t('about.mitmachen.titel')}</p>
                <p className="text-xs leading-relaxed mt-2 opacity-80">{t('about.mitmachen.text')}</p>
                <Link to="/register" className="mt-auto pt-4 inline-flex items-center gap-1.5 text-sm font-bold">
                  <UserPlus size={15} /> {t('nav.join')} <ArrowRight size={14} />
                </Link>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

// Seitenleiste und Handymenue: die Gruppe als Zwischentitel.
export const GruppenTitel: React.FC<{ gruppe: NavGruppe; dunkel?: boolean }> = ({ gruppe }) => {
  const { loc } = useTranslation();
  return <p className="px-3 pt-4 pb-1 text-[10px] font-bold uppercase tracking-[0.18em] text-stone-400">{loc(gruppe.label)}</p>;
};
