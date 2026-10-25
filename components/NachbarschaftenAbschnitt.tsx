import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { MapPin, Users, ArrowRight, Home } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useNachbarschaftenOeffentlich, hatFlaeche, type NbOeffentlich } from '../lib/nachbarschaften';
import { absaetze } from '../lib/news';
import { FlaechenKarte } from './NachbarschaftKarte';
import { onImageError } from '../lib/imageFallback';

// "Unsere Nachbarschaften" -- auf der Seite Dorf und auf /nachbarschaften.
// Nur, was die Verwaltung eingeschaltet hat; ohne eine einzige
// eingeschaltete Nachbarschaft erscheint der Abschnitt nicht.

export const NbKarte: React.FC<{ n: NbOeffentlich }> = ({ n }) => {
  const { t, loc } = useTranslation();
  const titelbild = n.bilder?.[0]?.url;
  const anriss = absaetze(loc(n.text))[0];
  return (
    <Link to={`/nachbarschaften/${encodeURIComponent(n.id)}`}
      className="group bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden flex flex-col hover:shadow-xl transition-shadow">
      <div className="relative h-52 overflow-hidden">
        {titelbild ? (
          <img src={titelbild} alt={n.name} loading="lazy" onError={onImageError}
               className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" />
        ) : (
          <div className="w-full h-full tupfer-primaer flex items-center justify-center"><Home size={40} className="opacity-40" /></div>
        )}
        <div className="absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-black/60 to-transparent" />
        <div className="absolute bottom-4 left-5 right-5 text-white">
          <h3 className="font-display text-2xl font-bold leading-tight">{n.name}</h3>
          {(n.ort || n.city) && <p className="text-xs text-white/80 mt-1 flex items-center gap-1"><MapPin size={12} /> {n.ort || n.city}</p>}
        </div>
      </div>
      <div className="p-6 flex flex-col flex-1">
        {anriss && <p className="text-sm text-stone-500 leading-relaxed line-clamp-3">{anriss}</p>}
        <div className="mt-auto pt-5 flex items-center justify-between text-sm">
          {n.mitglieder > 0
            ? <span className="inline-flex items-center gap-1.5 font-bold text-stone-700"><Users size={15} className="text-primary" /> {n.mitglieder} {t('nb.mitglieder')}</span>
            : <span />}
          <span className="inline-flex items-center gap-1 font-bold text-primary group-hover:gap-2 transition-[gap] duration-200 ease-out-strong">{t('nb.kennenlernen')} <ArrowRight size={15} /></span>
        </div>
      </div>
    </Link>
  );
};

const NachbarschaftenAbschnitt: React.FC<{ seite?: boolean }> = ({ seite }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const liste = useNachbarschaftenOeffentlich();
  if (!liste || liste.length === 0) return seite && liste
    ? <p className="text-center text-stone-400 italic py-16">{t('nb.keine')}</p> : null;

  const flaechen = liste.filter(n => hatFlaeche(n.gebiet)).map(n => ({ id: n.id, name: n.name, gebiet: n.gebiet }));
  const mitglieder = liste.reduce((s, n) => s + (n.mitglieder || 0), 0);

  return (
    <section className={seite ? '' : 'py-24 px-6'}>
      <div className="max-w-7xl mx-auto">
        {!seite && (
          <div className="flex items-end justify-between gap-6 flex-wrap mb-10">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-primary mb-3">{t('nb.marke')}</p>
              <h2 className="font-display text-4xl md:text-5xl font-bold italic text-stone-900">{t('nb.titel')}</h2>
              <p className="text-stone-500 leading-relaxed mt-4">
                {t('nb.intro', { anzahl: String(liste.length), mitglieder: String(mitglieder) })}
              </p>
            </div>
            <Link to="/nachbarschaften" className="inline-flex items-center gap-2 text-sm font-bold text-primary">
              {t('nb.alle')} <ArrowRight size={16} />
            </Link>
          </div>
        )}
        {flaechen.length > 0 && (
          <div className="mb-10">
            <FlaechenKarte flaechen={flaechen} hoehe={seite ? '30rem' : '24rem'}
              onWahl={id => navigate(`/nachbarschaften/${encodeURIComponent(id)}`)} />
          </div>
        )}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {liste.map(n => <NbKarte key={n.id} n={n} />)}
        </div>
      </div>
    </section>
  );
};

export default NachbarschaftenAbschnitt;
