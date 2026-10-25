import React, { useEffect } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { ArrowLeft, MapPin, User } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useNachrichten, useLikes, absaetze, nachrichtDatum, datumLang, vorZeit } from '../lib/news';
import { LikeKnopf, TeilenKnopf } from './NachrichtAktionen';
import { kategorieName } from './NewsSection';
import { onImageError } from '../lib/imageFallback';

// Eine Nachricht auf ihrer eigenen Seite: /news/<id>. Erst die eigene
// Adresse macht Teilen moeglich -- ein Fenster ueber der Liste hat keine.

const NachrichtSeite: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { t, language } = useTranslation();
  const alle = useNachrichten();
  const n = alle?.find(x => x.id === id);
  const weitere = (alle ?? []).filter(x => x.id !== id).slice(0, 3);
  const { stand, umschalten } = useLikes(n ? [n.id] : []);

  useEffect(() => { window.scrollTo(0, 0); }, [id]);
  useEffect(() => {
    if (!n) return;
    const vorher = document.title;
    document.title = n.title;
    return () => { document.title = vorher; };
  }, [n?.title]);

  if (alle === null) return (
    <div className="min-h-[60dvh] flex items-center justify-center">
      <div className="w-6 h-6 border-2 border-stone-200 border-t-stone-900 rounded-full animate-spin" />
    </div>
  );
  if (!n) return <Navigate to="/news" replace />;

  const text = absaetze(n.content);
  const datum = nachrichtDatum(n);

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-28 pb-24">
      <article className="max-w-3xl mx-auto px-6">
        <Link to="/news" className="inline-flex items-center gap-2 text-sm font-bold text-stone-500 hover:text-stone-900 mb-8">
          <ArrowLeft size={16} /> {t('nav.news.title')}
        </Link>

        <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 flex items-center gap-3 flex-wrap">
          {n.category && <span className="text-primary">{kategorieName(n.category, t)}</span>}
          {datum && <span title={vorZeit(datum, language)}>{datumLang(datum, language)}</span>}
          {n.location && <span className="inline-flex items-center gap-1"><MapPin size={11} />{n.location}</span>}
        </p>
        <h1 className="font-display text-4xl md:text-5xl font-bold text-stone-900 leading-tight mt-4">{n.title}</h1>
        {n.author && !/floky/i.test(n.author) && (
          <p className="text-sm text-stone-500 mt-4 inline-flex items-center gap-2"><User size={14} /> {n.author}</p>
        )}

        <div className="flex items-center gap-2 mt-8">
          <LikeKnopf anzahl={stand[n.id]?.anzahl ?? 0} gelikt={!!stand[n.id]?.gelikt} onClick={() => umschalten(n.id)} />
          <TeilenKnopf id={n.id} titel={n.title} />
        </div>
      </article>

      {n.image && (
        <div className="max-w-5xl mx-auto px-6 mt-10">
          <img src={n.image} alt={n.title} onError={onImageError}
               className="w-full max-h-[34rem] object-cover rounded-[2.5rem] shadow-sm" />
        </div>
      )}

      <div className="max-w-3xl mx-auto px-6 mt-12">
        <div className="text-lg text-stone-700 leading-relaxed space-y-6">
          {text.length ? text.map((a, i) => (
            <p key={i} className={`whitespace-pre-line ${i === 0 ? 'text-xl text-stone-900' : ''}`}>{a}</p>
          )) : <p className="text-stone-400 italic">{t('news.no_content')}</p>}
        </div>

        <div className="mt-14 pt-8 border-t border-stone-200 flex items-center justify-between gap-4 flex-wrap">
          <p className="text-sm font-bold text-stone-500">{t('news.gefallen')}</p>
          <div className="flex items-center gap-2">
            <LikeKnopf anzahl={stand[n.id]?.anzahl ?? 0} gelikt={!!stand[n.id]?.gelikt} onClick={() => umschalten(n.id)} />
            <TeilenKnopf id={n.id} titel={n.title} />
          </div>
        </div>
      </div>

      {weitere.length > 0 && (
        <div className="max-w-5xl mx-auto px-6 mt-20">
          <h2 className="font-display text-2xl font-bold text-stone-900 mb-6">{t('news.weitere')}</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {weitere.map(w => (
              <Link key={w.id} to={`/news/${encodeURIComponent(w.id)}`}
                className="bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden group">
                {w.image && <img src={w.image} alt="" loading="lazy" onError={onImageError} className="w-full h-40 object-cover" />}
                <div className="p-5">
                  <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{datumLang(nachrichtDatum(w), language)}</p>
                  <h3 className="font-display font-bold text-lg text-stone-900 leading-snug mt-2 group-hover:text-primary transition-colors line-clamp-2">{w.title}</h3>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default NachrichtSeite;
