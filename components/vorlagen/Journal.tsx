import React, { useRef } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { useTranslation } from '../../context/LanguageContext';
import { useVereinsinhalt, text } from '../../lib/useVereinsinhalt';
import { useScrollCraft, DUNKLER_GRUND, LEISTE_DUNKEL } from '../../lib/useScrollCraft';

// Vorlage "Journal" -- das Vereinsjahr als Band von oben nach unten.
//
// "Erzaehlung" fuehrt durch Bilder, "Buehne" haelt eines fest. Diese hier
// kommt ohne aus: sie ordnet, was der Verein tut, der Zeit nach. Fuer
// Vereine mit Geschichte und wenig Bildmaterial -- und das sind die
// meisten. Gemessen am 27.09.2026 hatte Koretini 0 von 340 Mitgliedern mit
// Foto; eine Vorlage, die Bilder voraussetzt, waere dort leer.
//
// Die Einblendungen laufen ueber data-sc-in statt ueber data-sc-cue: das
// feuert einmal beim Eintritt und bleibt. Inhalt, der sich beim
// Zurueckscrollen wieder versteckt, ist ein Fehler, kein Effekt.

const Journal: React.FC = () => {
  const { t, language } = useTranslation();
  const wurzel = useRef<HTMLDivElement>(null);
  const { marke, mitgliederZahl, diaspora, anlaesse, beitragsstand, aufrufe, bereit } =
    useVereinsinhalt();

  const titel = text(marke.heroTitle, language) || t('hero.title');
  const unter = text(marke.heroSubtitle, language) || t('hero.subtitle');

  // Das Band: Anlaesse der Zeit nach, dazwischen die Spendenaufrufe. Beides
  // sind Eintraege im selben Jahr, also gehoeren sie in dieselbe Spur.
  const eintraege = [
    ...anlaesse.slice(0, 7).map(a => ({
      art: 'anlass' as const, id: a.id, datum: a.date,
      titel: a.title, text: a.description, ort: a.location,
    })),
    ...aufrufe.slice(0, 3).map((a: any) => ({
      art: 'aufruf' as const, id: `s-${a.id}`, datum: a.beginn || a.erstellt_am,
      titel: a.titel, text: a.text, ort: '',
    })),
  ].filter(e => e.datum)
   .sort((x, y) => new Date(x.datum).getTime() - new Date(y.datum).getTime());

  useScrollCraft(wurzel, bereit, [eintraege.length, mitgliederZahl]);

  return (
    <div ref={wurzel} className="sc-seite journal">
      <style>{`
        .journal { ${DUNKLER_GRUND}
          background: var(--sc-canvas); color: var(--sc-ink); min-height:100vh; }
        ${LEISTE_DUNKEL}
        .journal .spur { position:relative; max-width:46rem; margin:0 auto;
          padding:0 1.5rem 8rem; }
        /* Das Band selbst. Links auf dem Telefon, mittig gibt es nicht --
           zwei Spalten auf 360 px waeren je 14 Zeichen breit. */
        .journal .spur::before { content:''; position:absolute; left:1.5rem; top:0; bottom:8rem;
          width:1px; background:linear-gradient(to bottom,
            transparent, rgba(255,255,255,.18) 8%, rgba(255,255,255,.18) 88%, transparent); }
        .journal .eintrag { position:relative; padding:0 0 3.5rem 2.5rem; }
        .journal .punkt { position:absolute; left:-.3rem; top:.45rem; width:9px; height:9px;
          border-radius:50%; background:var(--sc-accent);
          box-shadow:0 0 0 4px color-mix(in srgb, var(--sc-accent) 18%, transparent); }
        .journal .eintrag--aufruf .punkt { background:transparent;
          border:2px solid var(--sc-accent); box-shadow:none; }
        .journal .wann { font-size:.7rem; letter-spacing:.18em; text-transform:uppercase;
          color:var(--sc-ink-soft); font-family:'IBM Plex Mono',monospace; }
        .journal .was { font-family:'Playfair Display',serif; font-size:1.5rem;
          line-height:1.25; margin:.5rem 0 .55rem; }
        .journal .wozu { color:var(--sc-ink-soft); font-size:.9rem; line-height:1.65;
          display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
        .journal .kennzahlen { display:flex; gap:3rem; flex-wrap:wrap;
          border-top:1px solid rgba(255,255,255,.12); padding-top:2rem; margin-top:1rem; }
        .journal .kennzahlen .zahl { font-family:'Playfair Display',serif; font-size:2.6rem;
          line-height:1; font-variant-numeric:tabular-nums; }
      `}</style>

      <span data-sc-progress aria-hidden="true"></span>

      {/* Kopf: gehefteter Akt, damit der Titel steht, waehrend das Band
          darunter schon hochkommt */}
      <section data-sc-act="pin" data-sc-span="1.6" data-sc-drift="#0b0c10">
        <div data-sc-stage>
          <div className="sc-copy sc-copy--center">
            <p className="sc-label" data-sc-cue="0 0.3">
              {new Date().getFullYear()}
            </p>
            <h1 className="sc-display sc-display--xl" data-sc-kinetic="lines" data-sc-cue="0.05 0.45">
              {titel}
            </h1>
            <p className="sc-lede" data-sc-cue="0.2 0.6">{unter}</p>
          </div>
        </div>
      </section>

      {/* Das Band */}
      <section data-sc-act="flow" className="sc-section">
        <div className="spur" data-sc-in data-sc-stagger="70">
          {eintraege.map(e => (
            <article key={e.id} className={`eintrag eintrag--${e.art}`}>
              <span className="punkt" aria-hidden="true" />
              <p className="wann">
                {new Date(e.datum).toLocaleDateString('de-CH',
                  { day: '2-digit', month: 'long', year: 'numeric' })}
                {e.ort ? ` · ${e.ort}` : ''}
                {e.art === 'aufruf' ? ` · ${t('nav.spenden')}` : ''}
              </p>
              <h3 className="was">{e.titel}</h3>
              {e.text && <p className="wozu">{e.text}</p>}
            </article>
          ))}

          {/* Steht am Ende des Bandes, nicht als eigener Abschnitt: die
              Zahlen sind der Stand, zu dem das Jahr gefuehrt hat. */}
          <div className="kennzahlen">
            <div>
              <p className="zahl">{mitgliederZahl}</p>
              <p className="wann" style={{ marginTop: '.4rem' }}>{t('hero.stats.members')}</p>
            </div>
            <div>
              <p className="zahl">{diaspora}</p>
              <p className="wann" style={{ marginTop: '.4rem' }}>{t('hero.stats.diaspora')}</p>
            </div>
            {beitragsstand && beitragsstand.stellung !== 'AUS' && Number(beitragsstand.anzahl) > 0 && (
              <div>
                <p className="zahl">{beitragsstand.anzahl}</p>
                <p className="wann" style={{ marginTop: '.4rem' }}>{t('prem.beitraege', { jahr: beitragsstand.jahr })}</p>
              </div>
            )}
          </div>

          <Link to="/register"
            style={{ display:'inline-flex', alignItems:'center', gap:'.6rem', marginTop:'3rem',
                     padding:'1rem 2rem', borderRadius:'1rem', fontWeight:700, color:'#fff' }}
            className="knopf-primaer">
            {t('hero.cta.register')} <ArrowRight size={18} />
          </Link>
        </div>
      </section>
    </div>
  );
};

export default Journal;
