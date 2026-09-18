import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Check } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile } from '../types';
import Konstellation from './platform/Konstellation';

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
  const { t } = useTranslation();
  const angemeldet = !!user;

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
    <div style={{ background: TINTE }} className="min-h-screen">

      {/* ------------------------------------------------ Kopfzeile */}
      <header className="relative z-20 max-w-[1200px] mx-auto px-6 py-5 flex items-center justify-between">
        <span className="text-white font-light" style={{ fontSize: 20, letterSpacing: '-0.01em' }}>
          unityhub
        </span>
        <div className="flex items-center gap-6">
          {angemeldet ? (
            <Knopf to="/super-admin">{t('plat.open_admin')} <ArrowRight size={15} /></Knopf>
          ) : (
            <>
              <Link to="/login" className="text-white hover:opacity-70 transition-opacity uppercase"
                    style={{ fontSize: 13, letterSpacing: '0.05em' }}>
                {t('nav.login')}
              </Link>
              <Knopf to="/login">{t('plat.cta')}</Knopf>
            </>
          )}
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
              <Knopf to="/login">{angemeldet ? t('plat.open_admin') : t('plat.cta')} <ArrowRight size={15} /></Knopf>
              <a href="mailto:info@koretini.me" className="hover:opacity-70 transition-opacity uppercase"
                 style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: NEBEL }}>
                {t('plat.contact')}
              </a>
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
      <section className="relative max-w-[1200px] mx-auto px-6 py-20 md:py-[80px]">
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
      <section className="bg-white">
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
                  {([
                    ['Selmana-jt', 43, 18, 42],
                    ['Haxhia-jt', 48, 8, 17],
                    ['Sylaj-t', 10, 6, 60],
                    ['Bugaqk-t', 17, 4, 24],
                  ] as const).map(([name, mitglieder, zahlend, quote]) => (
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
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* ------------------------------------------------ Trennung */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mt-20 md:mt-[80px]">
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

      {/* ------------------------------------------------ Abschluss */}
      <section style={{ background: TINTE }}>
        <div className="max-w-[1200px] mx-auto px-6 py-20 md:py-[80px] text-center">
          <h2 className="text-white font-light mb-5 mx-auto"
              style={{ fontSize: 'clamp(28px, 4vw, 40px)', lineHeight: 1.3, letterSpacing: '-0.015em', maxWidth: 620 }}>
            {t('plat.end_headline')}
          </h2>
          <p className="mx-auto mb-9" style={{ fontSize: 18, lineHeight: 1.6, color: NEBEL, maxWidth: 520 }}>
            {t('plat.end_text')}
          </p>
          <Knopf to="/login">{angemeldet ? t('plat.open_admin') : t('plat.cta')} <ArrowRight size={15} /></Knopf>
        </div>

        <div style={{ borderTop: `1px solid ${SCHIEFER}` }}>
          <div className="max-w-[1200px] mx-auto px-6 py-7 flex flex-wrap items-center justify-between gap-4">
            <span style={{ fontFamily: mono, fontSize: 11, letterSpacing: '0.085em', color: NEBEL }}>
              UNITYHUB.LI
            </span>
            <span style={{ fontSize: 13, color: NEBEL }}>{t('plat.footer_note')}</span>
          </div>
        </div>
      </section>
    </div>
  );
};

export default PlatformHome;
