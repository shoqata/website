import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Check } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile } from '../types';
import Konstellation from './platform/Konstellation';
import Kontaktformular from './platform/Kontaktformular';
import Wortmarke, { Knotenpunkt } from './platform/Wortmarke';

interface Props { user: UserProfile | null; }

// Startseite der Betreiber-Domain.
//
// Diese Adresse gehoert keinem Verein. Ohne eigene Seite erschiene hier die
// Vereinsseite ohne Inhalte -- Ueberschriften ueber leeren Listen, was wie eine
// Stoerung aussieht statt wie Absicht.
//
// Gestaltung nach der uebergebenen Vorlage: dunkle Buehne, eine einzige
// gesaettigte Aktionsfarbe, Ueberschriften in leichtem Schnitt mit enger
// Laufweite, Datenbeschriftungen in Schreibmaschinenschrift, kleine Radien,
// Haarlinien statt Schatten. Uebernommen ist die Haltung, nicht der Inhalt:
// die Vorlage stammt aus der Lieferkettenueberwachung, hier geht es um
// Vereine. Das Signaturbild ist deshalb keine Partikelkugel, sondern eine
// Konstellation aus Nachbarschaften.
//
// Inter in Gewicht 300 steht als Ersatz fuer F37 Bolton -- so nennt es die
// Vorlage selbst -- und ist ohnehin schon geladen.
const PlatformHome: React.FC<Props> = ({ user }) => {
  const { t, language, setLanguage } = useTranslation();
  const angemeldet = !!user;

  // Seitentitel und Symbol im Browserreiter.
  //
  // Beide Domains teilen sich eine index.html, deren Titel "Koretini" lautet
  // -- fuer die Betreiber-Domain falsch. Gesetzt wird deshalb zur Laufzeit,
  // und nur hier: diese Komponente erscheint ausschliesslich dort.
  useEffect(() => {
    const vorher = document.title;
    document.title = 'unityhub';

    const zeichen = encodeURIComponent(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">' +
      '<rect width="48" height="48" rx="8" fill="#00052e"/>' +
      '<g fill="#0428cb">' +
      '<circle cx="24" cy="11" r="3"/><circle cx="35.3" cy="17.5" r="3"/>' +
      '<circle cx="35.3" cy="30.5" r="3"/><circle cx="24" cy="37" r="3"/>' +
      '<circle cx="12.7" cy="30.5" r="3"/></g>' +
      '<circle cx="12.7" cy="17.5" r="3" fill="#34fcff"/>' +
      '<circle cx="24" cy="24" r="5.4" fill="#0428cb"/>' +
      '<circle cx="24" cy="24" r="2.1" fill="#00052e"/></svg>'
    );
    const link = document.querySelector<HTMLLinkElement>('link[rel="icon"]')
      ?? document.head.appendChild(Object.assign(document.createElement('link'), { rel: 'icon' }));
    const vorherIcon = link.href;
    link.type = 'image/svg+xml';
    link.href = `data:image/svg+xml,${zeichen}`;

    return () => {
      document.title = vorher;
      if (vorherIcon) link.href = vorherIcon;
    };
  }, []);

  const TINTE = '#00052e';
  const BLAU = '#0428cb';
  const NEBEL = '#6b6b83';
  const SCHIEFER = '#4f5166';
  const LINIE = '#dbdcdf';

  const mono = "'IBM Plex Mono', ui-monospace, SFMono-Regular, Menlo, monospace";

  // Kleinschrift fuer Systemangaben -- in der Vorlage ausdruecklich von der
  // Fliesstextschrift getrennt, damit Maschinelles als solches lesbar bleibt.
  const Marke: React.FC<{ children: React.ReactNode; farbe?: string; className?: string }> =
    ({ children, farbe = NEBEL, className = '' }) => (
      <p className={`uppercase ${className}`}
         style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: farbe, lineHeight: 1.82 }}>
        {children}
      </p>
    );

  // Sprung zu einem Abschnitt derselben Seite.
  //
  // Nicht ueber href="#ziel": die Anwendung laeuft mit HashRouter, und eine
  // Raute in der Adresse ist dort der Pfad. Ein solcher Verweis wuerde als
  // Route gelesen, faende keine und liesse die Seite zum Anfang
  // zurueckspringen. Also von Hand scrollen.
  const zuAbschnitt = (id: string) => (e: React.MouseEvent) => {
    e.preventDefault();
    const ziel = document.getElementById(id);
    if (!ziel) return;
    const sparsam = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    ziel.scrollIntoView({ behavior: sparsam ? 'auto' : 'smooth', block: 'start' });
  };

  const Sprung: React.FC<{ ziel: string; children: React.ReactNode }> = ({ ziel, children }) => (
    <button type="button" onClick={zuAbschnitt(ziel)}
      className="inline-flex items-center gap-2 px-6 py-4 rounded-lg text-white font-normal transition-opacity hover:opacity-90"
      style={{ background: BLAU, fontSize: 14, letterSpacing: '0.01em' }}>
      {children}
    </button>
  );

  const Knopf: React.FC<{ to: string; children: React.ReactNode }> = ({ to, children }) => (
    <Link to={to}
      className="inline-flex items-center gap-2 px-6 py-4 rounded-lg text-white font-normal transition-opacity hover:opacity-90"
      style={{ background: BLAU, fontSize: 14, letterSpacing: '0.01em' }}>
      {children}
    </Link>
  );

  // Schwebende Karten wie in der Vorlage: voller Fond, Haarlinie, kein
  // Schatten. Sie zeigen Vorgaenge aus der Anwendung -- beispielhafte Werte,
  // keine Daten eines Vereins.
  const Karte: React.FC<{ marke: string; text: string; punkt: string; className?: string }> =
    ({ marke, text, punkt, className = '' }) => (
      <div className={`rounded-lg p-5 ${className}`}
           style={{ background: TINTE, border: `1px solid ${SCHIEFER}` }}>
        <div className="flex items-center gap-2 mb-2">
          <span className="w-2 h-2 rounded-full shrink-0" style={{ background: punkt }} />
          <span style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: NEBEL }}>
            {marke}
          </span>
        </div>
        <p className="text-white" style={{ fontSize: 14, lineHeight: 1.5 }}>{text}</p>
      </div>
    );

  return (
    <div id="oben" style={{ background: TINTE }} className="min-h-screen scroll-smooth">

      {/* ------------------------------------------------ Kopfzeile */}
      <header className="relative z-20 border-b" style={{ borderColor: 'rgba(79,81,102,0.4)' }}>
        <div className="max-w-[1200px] mx-auto px-6 py-4 flex items-center justify-between gap-6">
          <button type="button" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                  className="shrink-0" aria-label="unityhub">
            <Wortmarke size={30} grund={TINTE} />
          </button>

          {/* Verweise auf die Abschnitte dieser Seite. Die Vorlage sieht sie in
              der Mitte vor; auf schmalen Geraeten entfallen sie, weil die Seite
              dort ohnehin am Stueck durchgescrollt wird. */}
          <nav className="hidden lg:flex items-center gap-1">
            {([
              ['leistung', 'plat.nav_what'],
              ['verwaltung', 'plat.nav_product'],
              ['trennung', 'plat.nav_separation'],
            ] as const).map(([ziel, schluessel]) => (
              <button key={ziel} type="button" onClick={zuAbschnitt(ziel)}
                 className="px-4 py-2 uppercase transition-colors hover:text-white"
                 style={{ fontSize: 13, letterSpacing: '0.05em', color: NEBEL }}>
                {t(schluessel)}
              </button>
            ))}
          </nav>

          <div className="flex items-center gap-4 shrink-0">
            {/* Sprachwahl in derselben Schreibmaschinenschrift wie die uebrigen
                Systemangaben -- sie ist eine Einstellung, kein Inhalt. */}
            <div className="flex items-center rounded-lg p-0.5" style={{ border: `1px solid ${SCHIEFER}` }}>
              {(['sq', 'de', 'en'] as const).map((l) => (
                <button key={l} onClick={() => setLanguage(l)}
                  aria-pressed={language === l}
                  className="px-2.5 py-1 rounded-md uppercase transition-colors"
                  style={{
                    fontFamily: mono, fontSize: 11, letterSpacing: '0.085em',
                    background: language === l ? BLAU : 'transparent',
                    color: language === l ? '#ffffff' : NEBEL,
                  }}>
                  {l}
                </button>
              ))}
            </div>

            {angemeldet ? (
              <Knopf to="/super-admin">{t('plat.open_admin')} <ArrowRight size={15} /></Knopf>
            ) : (
              <>
                <Link to="/login" className="hidden sm:inline text-white hover:opacity-70 transition-opacity uppercase"
                      style={{ fontSize: 13, letterSpacing: '0.05em' }}>
                  {t('nav.login')}
                </Link>
                <Sprung ziel="anfrage">{t('plat.cta')}</Sprung>
              </>
            )}
          </div>
        </div>
      </header>

      {/* ------------------------------------------------ Bühne */}
      <section className="relative overflow-hidden">
        {/* Ein einziger radialer Verlauf fuer Tiefe -- die Vorlage untersagt
            Verlaeufe auf Bedienelementen, erlaubt sie fuer die Atmosphaere. */}
        <div className="absolute inset-0 pointer-events-none"
             style={{ background: `radial-gradient(ellipse 60% 55% at 50% 42%, #06105a 0%, ${TINTE} 70%)` }} />
        <Konstellation className="absolute inset-0 w-full h-full pointer-events-none opacity-90" />

        <div className="relative max-w-[1200px] mx-auto px-6 pt-20 pb-28 md:pt-28 md:pb-36">
          <motion.div initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }} className="max-w-[760px] mx-auto text-center">
            <Marke className="mb-5">{t('plat.eyebrow')}</Marke>
            <h1 className="text-white font-light mb-7"
                style={{ fontSize: 'clamp(38px, 6vw, 59px)', lineHeight: 1.16, letterSpacing: '-0.019em' }}>
              {t('plat.headline')}
            </h1>
            <p className="mx-auto mb-10" style={{ fontSize: 18, lineHeight: 1.6, color: NEBEL, maxWidth: 560 }}>
              {t('plat.sub')}
            </p>
            <div className="flex flex-wrap items-center justify-center gap-5">
              {angemeldet
                ? <Knopf to="/super-admin">{t('plat.open_admin')} <ArrowRight size={15} /></Knopf>
                : <Sprung ziel="anfrage">{t('plat.cta')} <ArrowRight size={15} /></Sprung>}
              <button type="button" onClick={zuAbschnitt('anfrage')}
                 className="hover:opacity-70 transition-opacity uppercase"
                 style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: NEBEL }}>
                {t('plat.contact')}
              </button>
            </div>
          </motion.div>

          {/* Vorgaenge aus der Anwendung, um die Buehne gelegt */}
          <div className="relative mt-20 grid grid-cols-1 md:grid-cols-3 gap-5 max-w-[1000px] mx-auto">
            <Karte marke={t('plat.card1_label')} text={t('plat.card1')} punkt="#34fcff" />
            <Karte marke={t('plat.card2_label')} text={t('plat.card2')} punkt={BLAU} className="md:mt-8" />
            <Karte marke={t('plat.card3_label')} text={t('plat.card3')} punkt="#34fcff" />
          </div>
        </div>
      </section>

      {/* ------------------------------------------------ Was es tut */}
      <section id="leistung" className="relative max-w-[1200px] mx-auto px-6 py-20 md:py-[80px] scroll-mt-20">
        <Marke farbe="#34fcff" className="mb-4">{t('plat.what_eyebrow')}</Marke>
        <h2 className="text-white font-light mb-14"
            style={{ fontSize: 'clamp(28px, 4vw, 40px)', lineHeight: 1.3, letterSpacing: '-0.015em', maxWidth: 700 }}>
          {t('plat.what_headline')}
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-10 md:gap-14">
          {([1, 2, 3] as const).map((i) => (
            <div key={i}>
              <Marke farbe={NEBEL} className="mb-3">{t(`plat.f${i}_label`)}</Marke>
              <h3 className="text-white font-light mb-3"
                  style={{ fontSize: 27, lineHeight: 1.41, letterSpacing: '-0.012em' }}>
                {t(`plat.f${i}_title`)}
              </h3>
              <p style={{ fontSize: 16, lineHeight: 1.6, color: NEBEL }}>{t(`plat.f${i}_text`)}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Übergang von der dunklen Bühne in die helle Produktfläche */}
      <div className="h-32" style={{ background: `linear-gradient(180deg, ${TINTE} 0%, #2a1a5e 45%, #ffffff 100%)` }} />

      {/* ------------------------------------------------ Das Produkt */}
      <section id="verwaltung" className="bg-white scroll-mt-20">
        <div className="max-w-[1200px] mx-auto px-6 py-20 md:py-[80px]">
          <Marke farbe={BLAU} className="mb-4">{t('plat.product_eyebrow')}</Marke>
          <h2 className="font-light mb-4" style={{
            fontSize: 'clamp(28px, 4vw, 40px)', lineHeight: 1.3,
            letterSpacing: '-0.015em', color: TINTE, maxWidth: 720 }}>
            {t('plat.product_headline')}
          </h2>
          <p className="mb-12" style={{ fontSize: 18, lineHeight: 1.6, color: SCHIEFER, maxWidth: 620 }}>
            {t('plat.product_sub')}
          </p>

          {/* Nachbau der Verwaltungsansicht. Die Zahlen sind Beispiele -- Daten
              eines Vereins haben auf einer oeffentlichen Seite nichts zu suchen. */}
          <div className="rounded-lg overflow-hidden" style={{ border: `1px solid ${LINIE}` }}>
            <div className="flex items-center gap-2 px-4 py-3" style={{ background: '#2a2a2a' }}>
              <span className="w-2.5 h-2.5 rounded-full" style={{ background: '#ff5f57' }} />
              <span className="w-2.5 h-2.5 rounded-full" style={{ background: '#febc2e' }} />
              <span className="w-2.5 h-2.5 rounded-full" style={{ background: '#28c840' }} />
              <span className="ml-4" style={{ fontFamily: mono, fontSize: 11, color: '#8185a0' }}>
                verein.unityhub.li/admin
              </span>
            </div>

            <div className="bg-white p-6 md:p-10">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-10">
                {([
                  ['plat.stat1', '350'],
                  ['plat.stat2', '27'],
                  ['plat.stat3', '42%'],
                  ['plat.stat4', '9 144'],
                ] as const).map(([schluessel, wert]) => (
                  <div key={schluessel}>
                    <p style={{ fontSize: 14, color: SCHIEFER, marginBottom: 6 }}>{t(schluessel)}</p>
                    <p className="font-light tabular-nums"
                       style={{ fontSize: 'clamp(30px, 4vw, 44px)', lineHeight: 1.1, letterSpacing: '-0.02em', color: TINTE }}>
                      {wert}
                    </p>
                  </div>
                ))}
              </div>

              <div style={{ borderTop: `1px solid ${LINIE}` }} className="pt-8">
                <div className="flex items-baseline justify-between mb-5">
                  <Marke farbe={SCHIEFER}>{t('plat.table_label')}</Marke>
                  <span style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: '#8185a0' }}>
                    2026
                  </span>
                </div>
                <div className="space-y-3">
                  {/* Erfundene Namen, und zwar in der gewaehlten Sprache. Auf
                      einer oeffentlichen Seite haben weder die Nachbarschaften
                      noch die Zahlen eines Vereins etwas zu suchen -- auch
                      nicht als Beispiel. Ein deutscher Flurname mitten in
                      einer albanischen Seite waere zudem ein Fremdkoerper. */}
                  {([
                    ['plat.nb1', 43, 18, 42],
                    ['plat.nb2', 48, 8, 17],
                    ['plat.nb3', 10, 6, 60],
                    ['plat.nb4', 17, 4, 24],
                  ] as const).map(([schluessel, mitglieder, zahlend, quote]) => {
                    const name = t(schluessel);
                    return (
                    <div key={name} className="flex items-center gap-4">
                      <span style={{ fontSize: 14, color: TINTE, width: 130 }} className="shrink-0 truncate">
                        {name}
                      </span>
                      <span className="tabular-nums shrink-0"
                            style={{ fontFamily: mono, fontSize: 11, color: '#8185a0', width: 74 }}>
                        {zahlend}/{mitglieder}
                      </span>
                      <div className="flex-1 h-1.5 rounded-sm overflow-hidden" style={{ background: '#f1f1f4' }}>
                        <div className="h-full rounded-sm" style={{ width: `${quote}%`, background: BLAU }} />
                      </div>
                      <span className="tabular-nums shrink-0 text-right"
                            style={{ fontFamily: mono, fontSize: 11, color: SCHIEFER, width: 38 }}>
                        {quote}%
                      </span>
                    </div>
                  );})}
                </div>
              </div>
            </div>
          </div>

          {/* ------------------------------------------------ Trennung */}
          <div id="trennung" className="grid grid-cols-1 md:grid-cols-2 gap-12 mt-20 md:mt-[80px] scroll-mt-20">
            <div>
              <Marke farbe={BLAU} className="mb-4">{t('plat.sep_eyebrow')}</Marke>
              <h2 className="font-light mb-4"
                  style={{ fontSize: 'clamp(26px, 3vw, 35px)', lineHeight: 1.38, letterSpacing: '-0.014em', color: TINTE }}>
                {t('plat.sep_headline')}
              </h2>
              <p style={{ fontSize: 16, lineHeight: 1.6, color: SCHIEFER }}>{t('plat.sep_text')}</p>
            </div>
            <ul className="space-y-4 md:pt-12">
              {([1, 2, 3, 4] as const).map((i) => (
                <li key={i} className="flex items-start gap-3">
                  <Check size={16} className="mt-1 shrink-0" style={{ color: BLAU }} />
                  <span style={{ fontSize: 16, lineHeight: 1.55, color: SCHIEFER }}>{t(`plat.sep${i}`)}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ------------------------------------------------ Anfrage */}
      <section id="anfrage" style={{ background: TINTE }} className="scroll-mt-8">
        <div className="max-w-[760px] mx-auto px-6 py-20 md:py-[80px]">
          <Marke farbe="#34fcff" className="mb-4">{t('plat.end_eyebrow')}</Marke>
          <h2 className="text-white font-light mb-4"
              style={{ fontSize: 'clamp(28px, 4vw, 40px)', lineHeight: 1.3, letterSpacing: '-0.015em' }}>
            {t('plat.end_headline')}
          </h2>
          <p className="mb-10" style={{ fontSize: 18, lineHeight: 1.6, color: NEBEL, maxWidth: 560 }}>
            {t('plat.end_text')}
          </p>
          <Kontaktformular farben={{ tinte: TINTE, blau: BLAU, nebel: NEBEL, schiefer: SCHIEFER, linie: LINIE, mono }} />
        </div>

        <div style={{ borderTop: `1px solid ${SCHIEFER}` }}>
          <div className="max-w-[1200px] mx-auto px-6 py-7 flex flex-wrap items-center justify-between gap-4">
            <span className="inline-flex items-center gap-2.5">
              <Knotenpunkt size={18} grund={TINTE} />
              <span style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: NEBEL }}>
                UNITYHUB.LI
              </span>
            </span>
            <span style={{ fontSize: 13, color: NEBEL }}>{t('plat.footer_note')}</span>
          </div>
        </div>
      </section>
    </div>
  );
};

export default PlatformHome;
