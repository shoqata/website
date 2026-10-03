import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';
import { useTranslation } from '../../context/LanguageContext';
import { useVereinsinhalt, text } from '../../lib/useVereinsinhalt';
import { onImageError } from '../../lib/imageFallback';

// Vorlage "Kompakt" -- eine Spalte, eine Aussage, ein Bild.
//
// Gebaut fuer den Verein, der gerade gegruendet wurde: keine Anlaesse,
// keine Spendenaufrufe, zwoelf Mitglieder. In der klassischen Vorlage
// bleiben dann Abschnitte leer, und die Seite sieht aus, als waere der
// Verein eingeschlafen.
//
// Hier gibt es nichts, was leer bleiben koennte. Was fehlt, erscheint
// einfach nicht -- und weil die Seite ohnehin aus wenig besteht, faellt
// nicht auf, dass wenig da ist. Grosse Schrift, viel Luft, drei Wege
// hinaus. Mehr braucht ein junger Verein nicht, und weniger geht nicht.

const Kompakt: React.FC = () => {
  const { t, language } = useTranslation();
  const { marke, bilder, mitgliederZahl, anlaesse, aufrufe } = useVereinsinhalt();

  const titel = text(marke.heroTitle, language) || t('hero.title');
  const unter = text(marke.heroSubtitle, language) || t('hero.subtitle');

  // Nur was es gibt. Ein Verweis auf eine leere Anlassliste ist schlechter
  // als gar keiner.
  const wege = [
    { zu: '/register', wort: t('hero.cta.register'), immer: true },
    { zu: '/events',   wort: t('events.title'),        immer: anlaesse.length > 0 },
    { zu: '/spenden',  wort: t('nav.spenden'),        immer: aufrufe.length > 0 },
    { zu: '/login',    wort: t('hero.cta.login'),    immer: true },
  ].filter(w => w.immer);

  return (
    <div className="min-h-screen bg-white text-stone-900 flex flex-col">
      <main className="flex-1 flex items-center">
        <div className="max-w-3xl mx-auto px-6 py-28 w-full">

          <h1 className="font-display text-[2.75rem] sm:text-6xl leading-[1.08] tracking-tight mb-8"
              style={{ textWrap: 'balance' } as React.CSSProperties}>
            {titel}
          </h1>

          <p className="text-lg sm:text-xl text-stone-500 leading-relaxed max-w-xl mb-14">
            {unter}
          </p>

          <div className="aspect-[3/2] w-full overflow-hidden rounded-sm mb-14">
            <img src={bilder[0]} onError={onImageError} alt=""
                 className="w-full h-full object-cover" />
          </div>

          {/* Die Wege als Liste, nicht als Knopfreihe: eine Zeile je Weg,
              durch Linien getrennt. Auf dem Telefon ist das besser zu
              treffen als vier Knoepfe nebeneinander. */}
          <nav className="border-t border-stone-200">
            {wege.map(w => (
              <Link key={w.zu} to={w.zu}
                className="group flex items-center justify-between py-5 border-b border-stone-200
                           hover:px-2 transition-all duration-300">
                <span className="text-lg font-medium group-hover:text-primary transition-colors">
                  {w.wort}
                </span>
                <ArrowUpRight size={20}
                  className="text-stone-300 group-hover:text-primary group-hover:-translate-y-0.5
                             group-hover:translate-x-0.5 transition-all" />
              </Link>
            ))}
          </nav>

          {mitgliederZahl > 0 && (
            <p className="mt-10 text-xs text-stone-400 tabular-nums">
              {mitgliederZahl} {t('hero.stats.members')}
            </p>
          )}
        </div>
      </main>
    </div>
  );
};

export default Kompakt;
