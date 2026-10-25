import React, { useEffect, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { ArrowLeft, MapPin, Users, X, ChevronLeft, ChevronRight, Home } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useNachbarschaftenOeffentlich, hatFlaeche } from '../lib/nachbarschaften';
import { absaetze } from '../lib/news';
import { FlaechenKarte } from './NachbarschaftKarte';
import NachbarschaftenAbschnitt, { NbKarte } from './NachbarschaftenAbschnitt';
import { onImageError } from '../lib/imageFallback';

// /nachbarschaften          alle eingeschalteten, mit Karte
// /nachbarschaften/<id>     eine: Titelbild, Text, Bilder, Gebiet

export const NachbarschaftenUebersicht: React.FC = () => {
  const { t } = useTranslation();
  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-24 px-6">
      <div className="max-w-7xl mx-auto mb-10">
        <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-primary mb-3">{t('nb.marke')}</p>
        <h1 className="font-display text-5xl md:text-6xl font-bold italic text-stone-900">{t('nb.titel')}</h1>
      </div>
      <NachbarschaftenAbschnitt seite />
    </div>
  );
};

const NachbarschaftSeite: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { t, loc } = useTranslation();
  const alle = useNachbarschaftenOeffentlich();
  const [gross, setGross] = useState<number | null>(null);
  const n = alle?.find(x => x.id === id);

  useEffect(() => { window.scrollTo(0, 0); setGross(null); }, [id]);
  useEffect(() => {
    if (gross === null || !n) return;
    const taste = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setGross(null);
      if (e.key === 'ArrowRight') setGross(g => g === null ? g : (g + 1) % n.bilder.length);
      if (e.key === 'ArrowLeft') setGross(g => g === null ? g : (g - 1 + n.bilder.length) % n.bilder.length);
    };
    document.addEventListener('keydown', taste);
    return () => document.removeEventListener('keydown', taste);
  }, [gross, n?.id]);

  if (alle === null) return (
    <div className="min-h-[60vh] flex items-center justify-center">
      <div className="w-6 h-6 border-2 border-stone-200 border-t-stone-900 rounded-full animate-spin" />
    </div>
  );
  if (!n) return <Navigate to="/nachbarschaften" replace />;

  const text = absaetze(loc(n.text));
  const bilder = n.bilder || [];
  const andere = alle.filter(x => x.id !== n.id).slice(0, 3);
  const flaechen = alle.filter(x => hatFlaeche(x.gebiet)).map(x => ({ id: x.id, name: x.name, gebiet: x.gebiet }));

  return (
    <div className="bg-[#faf9f6] min-h-screen pb-24">
      {/* Titelbild */}
      <div className="relative h-[52vh] min-h-[22rem] overflow-hidden">
        {bilder[0] ? (
          <img src={bilder[0].url} alt={n.name} onError={onImageError} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full tupfer-primaer flex items-center justify-center"><Home size={64} className="opacity-30" /></div>
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-black/30" />
        <div className="absolute inset-x-0 bottom-0">
          <div className="max-w-5xl mx-auto px-6 pb-10 text-white">
            <Link to="/nachbarschaften" className="inline-flex items-center gap-2 text-sm font-bold text-white/80 hover:text-white mb-6">
              <ArrowLeft size={16} /> {t('nb.titel')}
            </Link>
            <h1 className="font-display text-5xl md:text-6xl font-bold leading-tight">{n.name}</h1>
            <div className="flex flex-wrap gap-5 mt-4 text-sm font-bold text-white/85">
              {(n.ort || n.city) && <span className="inline-flex items-center gap-1.5"><MapPin size={15} /> {n.ort || n.city}</span>}
              {n.mitglieder > 0 && <span className="inline-flex items-center gap-1.5"><Users size={15} /> {n.mitglieder} {t('nb.mitglieder')}</span>}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-6 mt-14 grid grid-cols-1 lg:grid-cols-5 gap-12">
        <div className="lg:col-span-3 text-lg text-stone-700 leading-relaxed space-y-6">
          {text.length ? text.map((a, i) => (
            <p key={i} className={`whitespace-pre-line ${i === 0 ? 'text-xl text-stone-900' : ''}`}>{a}</p>
          )) : <p className="text-stone-400 italic">{t('nb.noch_kein_text')}</p>}
        </div>
        <div className="lg:col-span-2">
          {hatFlaeche(n.gebiet) ? (
            <>
              <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-stone-400 mb-3">{t('nb.gebiet')}</p>
              <FlaechenKarte flaechen={flaechen} hervor={n.id} hoehe="22rem" />
            </>
          ) : null}
        </div>
      </div>

      {bilder.length > 1 && (
        <div className="max-w-6xl mx-auto px-6 mt-16">
          <h2 className="font-display text-3xl font-bold text-stone-900 mb-6">{t('nb.bilder')}</h2>
          <div className="columns-1 sm:columns-2 lg:columns-3 gap-4 [column-fill:_balance]">
            {bilder.map((b, i) => (
              <button key={b.url + i} onClick={() => setGross(i)} className="block w-full mb-4 break-inside-avoid group text-left">
                <img src={b.url} alt={loc(b.text) || n.name} loading="lazy" onError={onImageError}
                     className="w-full rounded-2xl group-hover:opacity-90 transition-opacity" />
                {loc(b.text) && <span className="block text-xs text-stone-500 mt-2">{loc(b.text)}</span>}
              </button>
            ))}
          </div>
        </div>
      )}

      {andere.length > 0 && (
        <div className="max-w-6xl mx-auto px-6 mt-20">
          <h2 className="font-display text-3xl font-bold text-stone-900 mb-6">{t('nb.weitere')}</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">{andere.map(x => <NbKarte key={x.id} n={x} />)}</div>
        </div>
      )}

      {gross !== null && bilder[gross] && (
        <div className="fixed inset-0 z-[200] bg-black/90 flex items-center justify-center p-4" onClick={() => setGross(null)}>
          <button className="absolute top-5 right-5 text-white/80 hover:text-white"><X size={28} /></button>
          {bilder.length > 1 && (
            <>
              <button onClick={e => { e.stopPropagation(); setGross((gross - 1 + bilder.length) % bilder.length); }}
                className="absolute left-4 w-12 h-12 rounded-full bg-white/10 text-white flex items-center justify-center"><ChevronLeft /></button>
              <button onClick={e => { e.stopPropagation(); setGross((gross + 1) % bilder.length); }}
                className="absolute right-4 w-12 h-12 rounded-full bg-white/10 text-white flex items-center justify-center"><ChevronRight /></button>
            </>
          )}
          <figure onClick={e => e.stopPropagation()} className="max-w-5xl">
            <img src={bilder[gross].url} alt="" className="max-h-[80vh] w-auto mx-auto rounded-xl" />
            {loc(bilder[gross].text) && <figcaption className="text-white/80 text-sm text-center mt-3">{loc(bilder[gross].text)}</figcaption>}
          </figure>
        </div>
      )}
    </div>
  );
};

export default NachbarschaftSeite;
