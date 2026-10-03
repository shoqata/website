import React, { useRef } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, MapPin } from 'lucide-react';
import { useTranslation } from '../../context/LanguageContext';
import { useVereinsinhalt, text } from '../../lib/useVereinsinhalt';
import { useScrollCraft, DUNKLER_GRUND, LEISTE_DUNKEL } from '../../lib/useScrollCraft';
import { onImageError } from '../../lib/imageFallback';

// Vorlage "Buehne" -- ein Bild, ueber die ganze Breite, und die Zahlen des
// Vereins darueber.
//
// Der Unterschied zur "Erzaehlung": die laeuft durch fuenf Bilder und
// erzaehlt eine Folge. Diese hier haelt ein einziges Bild fest und laesst
// alles andere darueber geschehen. Fuer Vereine mit einem starken Bild --
// dem Dorf, dem Bau, der Halle -- und wenig Lust auf lange Seiten.
//
// Drei Akte: das Bild mit den Zahlen, die Anlaesse seitlich, der Schluss.
// Mehr nicht; ein vierter waere Fuellung.

const Buehne: React.FC = () => {
  const { t, language } = useTranslation();
  const wurzel = useRef<HTMLDivElement>(null);
  const { marke, bilder, mitgliederZahl, diaspora, anlaesse, beitragsstand, aufrufe, bereit } =
    useVereinsinhalt();

  const titel = text(marke.heroTitle, language) || t('hero.title');
  const unter = text(marke.heroSubtitle, language) || t('hero.subtitle');
  const kommende = anlaesse.slice(0, 6);

  useScrollCraft(wurzel, bereit, [mitgliederZahl, diaspora, kommende.length]);

  return (
    <div ref={wurzel} className="sc-seite buehne">
      <style>{`
        .buehne { ${DUNKLER_GRUND}
          background: var(--sc-canvas); color: var(--sc-ink); min-height: 100vh; }
        ${LEISTE_DUNKEL}
        .buehne .buehne-stage { overflow:hidden; }
        .buehne .bild-voll { position:absolute; inset:0; width:100%; height:100%;
          object-fit:cover; opacity:.5; }
        .buehne .zahlenband { display:grid; grid-template-columns:repeat(3,1fr);
          gap:1.5rem; max-width:52rem; }
        .buehne .zahl { font-variant-numeric:tabular-nums; line-height:1; }
        .buehne .band { display:flex; gap:1.25rem; padding:0 6vw; }
        .buehne .karte { flex:0 0 clamp(16rem,26vw,22rem);
          background:var(--sc-surface); border:1px solid rgba(255,255,255,.09);
          border-radius:1.25rem; overflow:hidden; }
        .buehne .karte img { width:100%; aspect-ratio:16/10; object-fit:cover; }
        .buehne .karte .inhalt { padding:1.25rem 1.35rem 1.5rem; }
        @media (max-width:640px){ .buehne .zahlenband{grid-template-columns:1fr;gap:1rem} }
      `}</style>

      <span data-sc-progress aria-hidden="true"></span>

      {/* 1 — Das Bild haelt, Titel und Zahlen kommen darueber */}
      <section data-sc-act="pin" data-sc-span="2.6" data-sc-drift="#0b0c10">
        {/* KEIN position hier. Der Kern heftet die Buehne mit
            position:sticky; ein eigenes position:relative ueberschreibt das,
            der Akt wird nie geheftet, kein Fortschritt laeuft -- und alles
            mit data-sc-cue bleibt dauerhaft auf Deckkraft 0. Der Kern warnt
            genau davor in der Konsole. Das Bild braucht den Bezugsrahmen
            nicht selbst: sticky ist bereits positioniert, inset:0 richtet
            sich daran aus. */}
        <div data-sc-stage className="buehne-stage">
          <img className="bild-voll" src={bilder[0]} onError={onImageError} alt=""
               data-sc-parallax="-0.14" />
          {/* Der Verlauf des Kerns statt eines eigenen: er kennt die
              Lesbarkeitsschwelle und passt sich der Buehne an. */}
          <div className="sc-scrim sc-scrim--lead" aria-hidden="true"></div>

          {/* Die Einblendung gehoert auf den Umschlag, nicht auf jedes Kind.
              Mit einem Hinweis je Zeile blieb hier alles unsichtbar --
              gemessen, nicht vermutet. Der dritte Wert ist der Haltepunkt. */}
          <div className="sc-copy sc-copy--lead" data-sc-cue="0 0.8 0">
            <p className="sc-label">
              {text(marke.heroBadge, language) || t('hero.badge')}
            </p>
            <h1 className="sc-display sc-display--xl" data-sc-kinetic="lines">
              {titel}
            </h1>
            <p className="sc-lede">{unter}</p>

            <div className="zahlenband" style={{ marginTop: '2.5rem' }}>
              <div>
                <p className="sc-display sc-display--lg zahl" data-sc-count={`0 ${mitgliederZahl}`}>0</p>
                <p className="sc-label">{t('hero.stats.members')}</p>
              </div>
              <div>
                <p className="sc-display sc-display--lg zahl" data-sc-count={`0 ${diaspora}`}>0</p>
                <p className="sc-label">{t('hero.stats.diaspora')}</p>
              </div>
              {/* Nur zeigen, wenn der Verein die Beitraege auch zeigen will --
                  die Datenbank entscheidet das, nicht diese Vorlage. */}
              {beitragsstand && beitragsstand.stellung !== 'AUS' && Number(beitragsstand.anzahl) > 0 && (
                <div>
                  <p className="sc-display sc-display--lg zahl"
                     data-sc-count={`0 ${beitragsstand.anzahl}`}>0</p>
                  <p className="sc-label">{t('prem.beitraege', { jahr: beitragsstand.jahr })}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* 2 — Die Anlaesse ziehen seitlich vorbei */}
      {kommende.length > 0 && (
        <section data-sc-act="pan" data-sc-span="2.2">
          <div data-sc-stage>
            <div className="sc-copy" style={{ paddingLeft: '6vw', paddingBottom: '2rem' }}>
              <p className="sc-label">{t('prem.naechstes')}</p>
            </div>
            <div className="band" data-sc-pan="0.62">
              {kommende.map(a => (
                <article className="karte" key={a.id}>
                  {a.image && <img src={a.image} onError={onImageError} alt="" />}
                  <div className="inhalt">
                    <p className="sc-label" style={{ color: 'var(--sc-accent)' }}>
                      {new Date(a.date).toLocaleDateString('de-CH',
                        { day: '2-digit', month: 'long' })}
                    </p>
                    <h3 className="sc-display sc-display--md" style={{ margin: '.5rem 0 .6rem' }}>
                      {a.title}
                    </h3>
                    <p style={{ color: 'var(--sc-ink-soft)', fontSize: '.82rem',
                                display: 'flex', alignItems: 'center', gap: '.4rem' }}>
                      <MapPin size={12} /> {a.location}
                    </p>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 3 — Schluss. Ein fliessender Akt: data-sc-stage waere hier wirkungslos,
             der Kern macht daraus nur bei gehefteten Akten eine Buehne. */}
      <section data-sc-act="flow" className="sc-section">
        <div className="sc-copy sc-copy--center">
          <h2 className="sc-display sc-display--lg" data-sc-kinetic="words" data-sc-cue="0 0.6">
            {text(marke.whyJoinText, language) || t('hero.cta.register')}
          </h2>
          <div data-sc-cue="0.25 0.8"
               style={{ display: 'flex', gap: '.9rem', justifyContent: 'center',
                        flexWrap: 'wrap', marginTop: '2.5rem' }}>
            <Link to="/register" className="knopf-primaer"
                  style={{ color: '#fff', padding: '1rem 2rem', borderRadius: '1rem',
                           fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '.6rem' }}>
              {t('hero.cta.register')} <ArrowRight size={18} />
            </Link>
            {aufrufe.length > 0 && (
              <Link to="/spenden"
                    style={{ padding: '1rem 2rem', borderRadius: '1rem', fontWeight: 700,
                             border: '1px solid rgba(255,255,255,.22)', color: 'var(--sc-ink)' }}>
                {t('nav.spenden')}
              </Link>
            )}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Buehne;
