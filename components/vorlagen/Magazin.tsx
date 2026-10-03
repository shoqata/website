import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, UserPlus, Calendar, MapPin } from 'lucide-react';
import { useTranslation } from '../../context/LanguageContext';
import { useVereinsinhalt, text } from '../../lib/useVereinsinhalt';
import { onImageError } from '../../lib/imageFallback';

// Vorlage "Magazin" -- die Seite als Zeitungsseite.
//
// Der Gedanke dahinter: ein Verein mit vielen Anlaessen und Neuigkeiten
// bekommt in der klassischen Vorlage eine sehr lange Seite, auf der alles
// gleich gross untereinander steht. Eine Zeitungsseite loest das seit
// hundert Jahren anders -- eine Sache gross, der Rest nebeneinander in
// Spalten, getrennt durch duenne Linien statt durch Abstand.
//
// Deshalb hier: Haarlinien statt Schatten, Serifen fuer den Titel, und die
// Farbe des Vereins nur an zwei Stellen. Das Papier traegt, nicht die
// Dekoration.

const datum = (s: string, sprache: string) => {
  try {
    return new Date(s).toLocaleDateString(sprache === 'de' ? 'de-CH' : sprache, {
      day: '2-digit', month: 'short',
    });
  } catch { return s; }
};

const Magazin: React.FC = () => {
  const { t, language } = useTranslation();
  const { marke, bilder, mitgliederZahl, diaspora, anlaesse, beitragsstand, aufrufe } =
    useVereinsinhalt();

  const titel = text(marke.heroTitle, language) || t('hero.title');
  const unter = text(marke.heroSubtitle, language) || t('hero.subtitle');
  const name  = text(marke.siteName, language) || text(marke.vereinsname, language) || '';

  const aufmacher = anlaesse[0];
  const weitere   = anlaesse.slice(1, 7);

  return (
    <div className="min-h-screen bg-[#f7f5f0] text-[#141210] pt-28">
      <div className="max-w-6xl mx-auto px-6">

        {/* Kopfleiste -- wie der Zeitungskopf: Name, zwei Linien, Datum */}
        <header className="border-y-2 border-[#141210] py-3 flex items-baseline justify-between gap-6 flex-wrap">
          <p className="font-display text-xl tracking-tight">{name || t('hero.badge')}</p>
          <p className="text-[10px] uppercase tracking-[0.25em] text-[#8a8275] font-mono">
            {new Date().toLocaleDateString('de-CH', { day: '2-digit', month: 'long', year: 'numeric' })}
          </p>
        </header>

        {/* Aufmacher */}
        <section className="grid grid-cols-1 lg:grid-cols-12 gap-x-10 gap-y-8 py-12 border-b border-[#d8d2c6]">
          <div className="lg:col-span-7 order-2 lg:order-1">
            <h1 className="font-display text-4xl md:text-6xl leading-[1.05] tracking-tight mb-6">
              {titel}
            </h1>
            {/* Zweispaltig wie eine Zeitung -- aber erst ab Tablet. Auf dem
                Telefon waeren zwei Spalten je 20 Zeichen breit. */}
            <p className="text-[15px] leading-relaxed text-[#4a443c] md:columns-2 md:gap-8 mb-8">
              {unter}
            </p>
            <div className="flex flex-wrap gap-3">
              <Link to="/register"
                className="knopf-primaer text-white px-6 py-3 rounded-none text-sm font-bold inline-flex items-center gap-2">
                <UserPlus size={16} /> {t('hero.cta.register')}
              </Link>
              <Link to="/login"
                className="border border-[#141210] px-6 py-3 text-sm font-bold inline-flex items-center gap-2 hover:bg-[#141210] hover:text-[#f7f5f0] transition-colors">
                {t('hero.cta.login')} <ArrowRight size={15} />
              </Link>
            </div>
          </div>

          <div className="lg:col-span-5 order-1 lg:order-2">
            <img src={bilder[0]} onError={onImageError} alt=""
                 className="w-full aspect-[4/5] object-cover grayscale-[18%]" />
            <p className="text-[10px] uppercase tracking-[0.2em] text-[#8a8275] mt-2 font-mono">
              {name}
            </p>
          </div>
        </section>

        {/* Die Zahlen -- als Kennziffernband, nicht als Kacheln */}
        <section className="grid grid-cols-2 md:grid-cols-4 border-b border-[#d8d2c6]">
          {[
            { wert: mitgliederZahl, bez: t('hero.stats.members') },
            { wert: diaspora,       bez: t('hero.stats.diaspora') },
            { wert: anlaesse.length, bez: t('events.title') },
            beitragsstand && beitragsstand.stellung !== 'AUS' && Number(beitragsstand.anzahl) > 0
              ? { wert: beitragsstand.anzahl, bez: t('prem.beitraege', { jahr: beitragsstand.jahr }) }
              : { wert: aufrufe.length, bez: t('nav.spenden') },
          ].map((z, i) => (
            <div key={i}
                 className={`py-8 px-4 ${i % 2 === 0 ? 'border-r' : ''} md:border-r last:border-r-0 border-[#d8d2c6] ${i < 2 ? 'border-b md:border-b-0' : ''}`}>
              <p className="font-display text-4xl tabular-nums leading-none">{z.wert}</p>
              <p className="text-[10px] uppercase tracking-[0.2em] text-[#8a8275] mt-2 font-mono">{z.bez}</p>
            </div>
          ))}
        </section>

        {/* Anlaesse in Spalten */}
        {aufmacher && (
          <section className="py-12">
            <h2 className="text-[10px] uppercase tracking-[0.3em] text-[#8a8275] font-mono mb-6 pb-2 border-b border-[#141210]">
              {t('events.title')}
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-x-8 gap-y-10">
              <article className="md:col-span-2 md:row-span-2">
                <img src={aufmacher.image || bilder[1]} onError={onImageError} alt=""
                     className="w-full aspect-[16/9] object-cover mb-4" />
                <p className="text-[10px] uppercase tracking-[0.2em] text-primary font-mono mb-2">
                  {datum(aufmacher.date, language)} · {aufmacher.location}
                </p>
                <h3 className="font-display text-2xl md:text-3xl leading-tight mb-3">{aufmacher.title}</h3>
                <p className="text-sm text-[#4a443c] leading-relaxed line-clamp-4">{aufmacher.description}</p>
              </article>

              {weitere.map(a => (
                <article key={a.id} className="border-t border-[#d8d2c6] pt-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-[#8a8275] font-mono mb-2 flex items-center gap-2">
                    <Calendar size={11} /> {datum(a.date, language)}
                  </p>
                  <h3 className="font-display text-lg leading-tight mb-2">{a.title}</h3>
                  <p className="text-[10px] text-[#8a8275] flex items-center gap-1.5">
                    <MapPin size={10} /> {a.location}
                  </p>
                </article>
              ))}
            </div>
          </section>
        )}

        {/* Spendenaufrufe als Randspalte unten */}
        {aufrufe.length > 0 && (
          <section className="py-12 border-t-2 border-[#141210]">
            <h2 className="text-[10px] uppercase tracking-[0.3em] text-[#8a8275] font-mono mb-6">
              {t('nav.spenden')}
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {aufrufe.slice(0, 2).map((a: any) => (
                <Link key={a.id} to="/spenden" className="group block">
                  <h3 className="font-display text-xl mb-2 group-hover:text-primary transition-colors">{a.titel}</h3>
                  <p className="text-sm text-[#4a443c] leading-relaxed line-clamp-3 mb-3">{a.text}</p>
                  {a.ziel > 0 && (
                    <div className="h-[3px] bg-[#d8d2c6]">
                      <div className="h-full bg-primary"
                           style={{ width: `${Math.min(100, Math.round((a.stand / a.ziel) * 100))}%` }} />
                    </div>
                  )}
                </Link>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default Magazin;
