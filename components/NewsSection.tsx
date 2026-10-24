import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Loader2, MapPin, ArrowRight, Newspaper } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useNachrichten, useLikes, absaetze, nachrichtDatum, vorZeit, type Nachricht } from '../lib/news';
import { LikeKnopf, TeilenKnopf } from './NachrichtAktionen';
import { onImageError } from '../lib/imageFallback';

// Die Liste der Neuigkeiten.
//
// Vorher: sechs gleich grosse Karten, ein Lesezeichen, das nichts
// speicherte, und ein Fenster, das bei jeder Nachricht abstuerzte (der
// Inhalt ist Text, die Ansicht erwartete eine Liste). Jetzt: die neueste
// gross, die uebrigen darunter, jede mit eigener Seite und eigenem Link --
// sonst laesst sich nichts teilen.

export const kategorieName = (k: string | null | undefined, t: (s: string) => string) => {
  if (!k) return '';
  const s = `cat.${k.toLowerCase()}`;
  const w = t(s);
  return w === s ? k : w;
};

const Bild: React.FC<{ n: Nachricht; className: string }> = ({ n, className }) => n.image ? (
  <img src={n.image} alt={n.title} loading="lazy" onError={onImageError} className={`${className} object-cover`} />
) : (
  <div className={`${className} tupfer-primaer flex items-center justify-center`}>
    <Newspaper size={40} className="opacity-40" />
  </div>
);

export function NewsSection() {
  const { t, language } = useTranslation();
  const nachrichten = useNachrichten();
  const [kategorie, setKategorie] = useState<string | null>(null);
  const { stand, umschalten } = useLikes((nachrichten ?? []).map(n => n.id));

  const kategorien = useMemo(() =>
    [...new Set((nachrichten ?? []).map(n => n.category).filter(Boolean) as string[])], [nachrichten]);
  const sichtbar = (nachrichten ?? []).filter(n => !kategorie || n.category === kategorie);

  if (nachrichten === null) return (
    <div className="flex justify-center py-24"><Loader2 className="animate-spin text-stone-300" size={32} /></div>
  );
  if (nachrichten.length === 0) return (
    <div className="max-w-7xl mx-auto px-6">
      <div className="bg-white rounded-[2rem] border border-stone-100 p-14 text-center text-stone-400 italic">{t('news.empty')}</div>
    </div>
  );

  const [erste, ...rest] = sichtbar;
  const aktionen = (n: Nachricht, klein = true) => (
    <div className="flex items-center gap-2">
      <LikeKnopf klein={klein} anzahl={stand[n.id]?.anzahl ?? 0} gelikt={!!stand[n.id]?.gelikt} onClick={() => umschalten(n.id)} />
      <TeilenKnopf klein={klein} id={n.id} titel={n.title} />
    </div>
  );
  const kopfzeile = (n: Nachricht) => (
    <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 flex items-center gap-2 flex-wrap">
      {n.category && <span className="text-primary">{kategorieName(n.category, t)}</span>}
      <span>{vorZeit(nachrichtDatum(n), language)}</span>
      {n.location && <span className="inline-flex items-center gap-1"><MapPin size={10} />{n.location}</span>}
    </p>
  );

  return (
    <div className="max-w-7xl mx-auto px-6 pb-12">
      {kategorien.length > 1 && (
        <div className="flex gap-2 flex-wrap mb-10">
          {[null, ...kategorien].map(k => (
            <button key={k ?? 'alle'} onClick={() => setKategorie(k)}
              className={`px-4 py-2 rounded-full text-xs font-bold border transition-colors ${
                kategorie === k ? 'bg-stone-900 text-white border-stone-900' : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
              {k ? kategorieName(k, t) : t('chronik.alle')}
            </button>
          ))}
        </div>
      )}

      {erste && (
        <article className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden grid md:grid-cols-2 mb-10 group">
          <Link to={`/news/${encodeURIComponent(erste.id)}`} className="block overflow-hidden">
            <Bild n={erste} className="w-full h-64 md:h-full md:min-h-[22rem] group-hover:scale-[1.02] transition-transform duration-700" />
          </Link>
          <div className="p-8 md:p-12 flex flex-col">
            {kopfzeile(erste)}
            <Link to={`/news/${encodeURIComponent(erste.id)}`}>
              <h2 className="font-display text-3xl md:text-4xl font-bold text-stone-900 leading-tight mt-4 group-hover:text-primary transition-colors">
                {erste.title}
              </h2>
            </Link>
            <p className="text-stone-500 leading-relaxed mt-4 line-clamp-4">{absaetze(erste.content)[0]}</p>
            <div className="mt-auto pt-8 flex items-center justify-between gap-4 flex-wrap">
              {aktionen(erste, false)}
              <Link to={`/news/${encodeURIComponent(erste.id)}`} className="inline-flex items-center gap-2 text-sm font-bold text-primary">
                {t('news.weiterlesen')} <ArrowRight size={16} />
              </Link>
            </div>
          </div>
        </article>
      )}

      {rest.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 lg:gap-8">
          {rest.map(n => (
            <article key={n.id} className="bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden flex flex-col group">
              <Link to={`/news/${encodeURIComponent(n.id)}`} className="block overflow-hidden">
                <Bild n={n} className="w-full h-52 group-hover:scale-[1.03] transition-transform duration-700" />
              </Link>
              <div className="p-6 flex flex-col flex-1">
                {kopfzeile(n)}
                <Link to={`/news/${encodeURIComponent(n.id)}`}>
                  <h3 className="font-display text-xl font-bold text-stone-900 leading-snug mt-3 line-clamp-2 group-hover:text-primary transition-colors">{n.title}</h3>
                </Link>
                <p className="text-stone-500 text-sm leading-relaxed mt-2 line-clamp-3">{absaetze(n.content)[0]}</p>
                <div className="mt-auto pt-5">{aktionen(n)}</div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
