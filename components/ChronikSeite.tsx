import React, { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { History, Star, Users, Home, ArrowDownUp } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, onSnapshot } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useChronik, chronikDatum, type ChronikEintrag } from '../lib/useChronik';
import { onImageError } from '../lib/imageFallback';

// Die Chronik: wie sich Verein und Dorf entwickelt haben, als Zeitleiste.
//
// Gruppiert nach Jahr, weil man in einer Chronik nach Jahren sucht ("was
// war 2015?"), nicht nach einzelnen Tagen. Neueste zuerst ist die
// Vorgabe: wer die Seite oefter besucht, will wissen, was dazugekommen
// ist. Wer die Geschichte von vorn lesen will, dreht die Reihenfolge um.
//
// Die Farben kommen aus denselben Bausteinen wie die uebrigen Seiten --
// lib/design.css uebersetzt sie in die gewaehlte Vorlage.

type Filter = 'ALLE' | 'VEREIN' | 'DORF' | 'MEILENSTEIN';

const Eintrag: React.FC<{ e: ChronikEintrag; rechts: boolean }> = ({ e, rechts }) => {
  const { language, loc, t } = useTranslation();
  const text = loc(e.text);
  return (
    <div className={`relative md:w-1/2 pl-10 md:pl-0 ${rechts ? 'md:ml-auto md:pl-12' : 'md:pr-12'}`}>
      {/* Punkt auf der Linie */}
      <span aria-hidden="true"
        className={`absolute top-6 rounded-full border-4 border-[#faf9f6] ${e.meilenstein ? 'bg-primary w-5 h-5' : 'bg-stone-300 w-4 h-4'}
          left-[0.6rem] -translate-x-1/2 ${rechts ? 'md:left-0' : 'md:left-auto md:right-0 md:translate-x-1/2'}`} />
      <article className={`bg-white rounded-[2rem] border overflow-hidden shadow-sm ${e.meilenstein ? 'border-[color:color-mix(in_srgb,var(--primary)_35%,transparent)]' : 'border-stone-100'}`}>
        {e.bild && (
          <img src={e.bild} alt={loc(e.titel)} loading="lazy" onError={onImageError}
               className="w-full aspect-[16/9] object-cover" />
        )}
        <div className="p-6 md:p-7">
          <div className="flex items-center gap-2 flex-wrap mb-3">
            <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
              {chronikDatum(e, language)}
            </span>
            <span className="text-[10px] font-bold uppercase tracking-widest text-stone-300">·</span>
            <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest text-stone-500">
              {e.bereich === 'DORF' ? <Home size={11} /> : <Users size={11} />}
              {t(e.bereich === 'DORF' ? 'chronik.dorf' : 'chronik.verein')}
            </span>
            {e.meilenstein && (
              <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest text-primary">
                <Star size={11} fill="currentColor" /> {t('chronik.meilenstein')}
              </span>
            )}
          </div>
          <h3 className="font-display text-2xl font-bold text-stone-900 leading-snug">{loc(e.titel)}</h3>
          {text && <p className="text-stone-500 leading-relaxed mt-3 whitespace-pre-line">{text}</p>}
        </div>
      </article>
    </div>
  );
};

const ChronikSeite: React.FC = () => {
  const { t, loc } = useTranslation();
  const eintraege = useChronik();
  const [marke, setMarke] = useState<any>({});
  const [filter, setFilter] = useState<Filter>('ALLE');
  const [neuesteZuerst, setNeuesteZuerst] = useState(true);

  useEffect(() => onSnapshot(doc(db, 'public_settings', 'branding'),
    (s: any) => { if (s.exists()) setMarke(s.data()); }), []);

  const sichtbar = useMemo(() => (eintraege ?? []).filter(e =>
    filter === 'ALLE' || (filter === 'MEILENSTEIN' ? e.meilenstein : e.bereich === filter)), [eintraege, filter]);

  // Nach Jahr gruppiert, in der gewaehlten Richtung.
  const jahre = useMemo(() => {
    const m = new Map<number, ChronikEintrag[]>();
    for (const e of sichtbar) m.set(e.jahr, [...(m.get(e.jahr) ?? []), e]);
    const liste = [...m.entries()].sort((a, b) => a[0] - b[0]);
    return neuesteZuerst ? liste.reverse().map(([j, es]) => [j, [...es].reverse()] as const) : liste;
  }, [sichtbar, neuesteZuerst]);

  const alle = eintraege ?? [];
  const erstesJahr = alle.length ? alle[0].jahr : null;
  const gibtDorf = alle.some(e => e.bereich === 'DORF');
  const gibtVerein = alle.some(e => e.bereich === 'VEREIN');
  let zaehler = 0;

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-24">
      <div className="max-w-6xl mx-auto px-6">
        <header className="max-w-3xl mb-14">
          <div className="inline-flex items-center gap-2 bg-rose-50 text-primary px-4 py-2 rounded-full text-xs font-bold mb-6 uppercase tracking-widest">
            <History size={14} /> {t('chronik.badge')}
          </div>
          <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">
            {loc(marke.chronikTitel) || t('chronik.titel')}
          </h1>
          <p className="text-xl text-stone-500 leading-relaxed italic">
            {loc(marke.chronikIntro) || t('chronik.intro')}
          </p>
          {alle.length > 0 && (
            <div className="flex gap-10 mt-8">
              {erstesJahr && (
                <div>
                  <p className="text-4xl font-bold text-primary tabular-nums">{erstesJahr}</p>
                  <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mt-1">{t('chronik.seit')}</p>
                </div>
              )}
              <div>
                <p className="text-4xl font-bold text-primary tabular-nums">{alle.length}</p>
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mt-1">{t('chronik.eintraege')}</p>
              </div>
              <div>
                <p className="text-4xl font-bold text-primary tabular-nums">{alle.filter(e => e.meilenstein).length}</p>
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mt-1">{t('chronik.meilensteine')}</p>
              </div>
            </div>
          )}
        </header>

        {eintraege === null ? (
          <div className="space-y-6">
            {[1, 2, 3].map(i => <div key={i} className="h-40 bg-stone-100 rounded-[2rem] animate-pulse" />)}
          </div>
        ) : alle.length === 0 ? (
          <div className="bg-white rounded-[2rem] border border-stone-100 p-14 text-center">
            <History size={36} className="mx-auto text-stone-300 mb-4" />
            <p className="text-stone-500">{t('chronik.leer')}</p>
            <Link to="/" className="inline-block mt-6 text-sm font-bold text-primary">{t('nav.home')} →</Link>
          </div>
        ) : (
          <>
            {/* Filter und Richtung */}
            <div className="flex items-center justify-between gap-4 flex-wrap mb-12">
              <div className="flex gap-2 flex-wrap">
                {([['ALLE', 'chronik.alle'],
                   ...(gibtVerein && gibtDorf ? [['VEREIN', 'chronik.verein'], ['DORF', 'chronik.dorf']] : []),
                   ['MEILENSTEIN', 'chronik.meilensteine']] as [Filter, string][]).map(([w, k]) => (
                  <button key={w} onClick={() => setFilter(w)}
                    className={`px-4 py-2 rounded-full text-xs font-bold border transition-colors ${
                      filter === w ? 'bg-stone-900 text-white border-stone-900' : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                    {t(k)}
                  </button>
                ))}
              </div>
              <button onClick={() => setNeuesteZuerst(!neuesteZuerst)}
                className="inline-flex items-center gap-2 text-xs font-bold text-stone-500 hover:text-stone-900">
                <ArrowDownUp size={14} /> {t(neuesteZuerst ? 'chronik.neueste' : 'chronik.aelteste')}
              </button>
            </div>

            {sichtbar.length === 0 ? (
              <p className="text-stone-400 italic text-center py-12">{t('chronik.nichts_im_filter')}</p>
            ) : (
              <div className="relative">
                {/* Die Linie: links auf dem Telefon, in der Mitte ab Tablet */}
                <div aria-hidden="true" className="absolute top-0 bottom-0 left-[0.6rem] md:left-1/2 w-px bg-stone-200" />
                <div className="space-y-14">
                  {jahre.map(([jahr, es]) => (
                    <section key={jahr} className="relative">
                      <div className="relative flex md:justify-center mb-8 pl-10 md:pl-0">
                        <span className="relative z-10 bg-stone-900 text-white font-display font-bold text-xl px-5 py-1.5 rounded-full tabular-nums">
                          {jahr}
                        </span>
                      </div>
                      <div className="space-y-8">
                        {es.map(e => <Eintrag key={e.id} e={e} rechts={zaehler++ % 2 === 1} />)}
                      </div>
                    </section>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ChronikSeite;
