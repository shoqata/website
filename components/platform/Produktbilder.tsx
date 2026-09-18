import React from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { TINTE, BLAU, NEBEL, SCHIEFER, LINIE, MONO } from './farben';
import Familienbaum from '../Familienbaum';
import { useTranslation } from '../../context/LanguageContext';

// Drei Bilder fuer die Betreiberseite.
//
// Gezeigt wird die Anwendung selbst, nicht Menschen aus einer Bilddatenbank.
// Wer einen Verein fuehrt, will sehen, wie das Mitgliederverzeichnis aussieht
// und wie eine Rechnung herauskommt -- nicht ein Modell am Laptop. Fotos
// haetten ausserdem die Lizenzfrage und wuerden gegen die Bildsprache dieser
// Seite arbeiten: fast schwarzes Blau, Haarlinien, keine Schatten.
//
// Alle Namen, Adressen und Zahlen sind erfunden. Daten eines Vereins haben
// auf einer oeffentlichen Seite nichts zu suchen -- auch nicht als Beispiel.
// Die IBAN ist die Beispiel-IBAN aus der Dokumentation und gehoert zu keinem
// Konto; der QR-Code ist echt lesbar, fuehrt aber auf genau diese erfundenen
// Angaben.

const Rahmen: React.FC<{ marke: string; titel: string; text: string; children: React.ReactNode }> =
  ({ marke, titel, text, children }) => (
  <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.25fr)] gap-8 lg:gap-14 items-center">
    <div>
      <p className="uppercase mb-3"
         style={{ fontFamily: MONO, fontSize: 11, letterSpacing: '0.12em', color: BLAU }}>
        {marke}
      </p>
      <h3 className="font-light mb-3"
          style={{ fontSize: 27, lineHeight: 1.35, letterSpacing: '-0.012em', color: TINTE }}>
        {titel}
      </h3>
      <p style={{ fontSize: 16, lineHeight: 1.6, color: SCHIEFER }}>{text}</p>
    </div>
    <div className="rounded-lg overflow-hidden" style={{ border: `1px solid ${LINIE}` }}>
      {children}
    </div>
  </div>
);

// --- 1. Mitgliederverzeichnis ---------------------------------------------
const Mitgliederbild: React.FC = () => {
  const { t } = useTranslation();
  const zeilen = [
    ['plat.bild_m1', 'plat.nb1', 'bezahlt', '120'],
    ['plat.bild_m2', 'plat.nb1', 'bezahlt', '120'],
    ['plat.bild_m3', 'plat.nb2', 'offen',   '120'],
    ['plat.bild_m4', 'plat.nb3', 'bezahlt', '100'],
    ['plat.bild_m5', 'plat.nb2', 'offen',   '120'],
  ] as const;

  return (
    <div className="bg-white">
      <div className="flex items-center justify-between px-5 py-3.5"
           style={{ borderBottom: `1px solid ${LINIE}` }}>
        <span className="uppercase"
              style={{ fontFamily: MONO, fontSize: 10, letterSpacing: '0.12em', color: SCHIEFER }}>
          {t('plat.bild_mitglieder_kopf')}
        </span>
        <span style={{ fontFamily: MONO, fontSize: 10, color: '#8185a0' }}>350</span>
      </div>
      <table className="w-full" style={{ fontSize: 13 }}>
        <tbody>
          {zeilen.map(([name, lagje, stand, betrag], i) => (
            <tr key={i} style={{ borderBottom: i < zeilen.length - 1 ? `1px solid #f0efee` : 'none' }}>
              <td className="px-5 py-3" style={{ color: TINTE }}>{t(name)}</td>
              <td className="px-2 py-3 hidden sm:table-cell" style={{ color: '#8185a0' }}>{t(lagje)}</td>
              <td className="px-2 py-3">
                <span className="inline-block px-2 py-0.5 rounded uppercase"
                      style={{
                        fontFamily: MONO, fontSize: 9, letterSpacing: '0.08em',
                        background: stand === 'bezahlt' ? '#e8f5ec' : '#fdf0e6',
                        color: stand === 'bezahlt' ? '#1f7a3f' : '#a8600f',
                      }}>
                  {t(stand === 'bezahlt' ? 'plat.bild_bezahlt' : 'plat.bild_offen')}
                </span>
              </td>
              <td className="px-5 py-3 text-right tabular-nums"
                  style={{ fontFamily: MONO, fontSize: 12, color: TINTE }}>{betrag}.—</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

// --- 2. Swiss-QR-Rechnung --------------------------------------------------
const Rechnungsbild: React.FC = () => {
  const { t } = useTranslation();
  // Erfundener Zahlteil. Die IBAN ist die Beispiel-IBAN aus der
  // Dokumentation -- sie gehoert zu keinem Konto.
  const inhalt = [
    'SPC', '0200', '1', 'CH9300762011623852957', 'S',
    'Shoqata Shembull', 'Rruga e Shembullit 8', '12', '8000', 'Zürich', 'CH',
    '', '', '', '', '', '', '', '120.00', 'CHF', 'S',
    t('plat.bild_m1'), 'Weg 4', '7', '8400', 'Winterthur', 'CH',
    'QRR', '210000000003139471430009017', t('plat.bild_zweck'), 'EPD',
  ].join('\n');

  const zeile = (marke: string, wert: string) => (
    <div className="mb-2.5">
      <p className="uppercase" style={{ fontFamily: MONO, fontSize: 8, letterSpacing: '0.1em', color: '#8185a0' }}>
        {marke}
      </p>
      <p style={{ fontSize: 12, color: TINTE, lineHeight: 1.45 }}>{wert}</p>
    </div>
  );

  return (
    <div className="bg-white p-5 sm:p-7 flex gap-6 flex-wrap sm:flex-nowrap">
      <div className="shrink-0">
        <div className="relative" style={{ width: 132, height: 132 }}>
          <QRCodeSVG value={inhalt} size={132} level="M" bgColor="#ffffff" fgColor="#000000" />
          {/* Das Schweizerkreuz gehoert nach der Richtlinie in die Mitte. */}
          <div className="absolute" style={{ left: 55, top: 55, width: 22, height: 22, background: '#fff' }}>
            <div style={{ position: 'absolute', inset: 2, background: '#000' }}>
              <div style={{ position: 'absolute', left: 7.5, top: 3.5, width: 3, height: 11, background: '#fff' }} />
              <div style={{ position: 'absolute', left: 3.5, top: 7.5, width: 11, height: 3, background: '#fff' }} />
            </div>
          </div>
        </div>
        <p className="mt-2 uppercase"
           style={{ fontFamily: MONO, fontSize: 8, letterSpacing: '0.1em', color: '#8185a0' }}>
          {t('plat.bild_qr_hinweis')}
        </p>
      </div>
      <div className="min-w-0 flex-1">
        {zeile(t('plat.bild_konto'), 'CH93 0076 2011 6238 5295 7')}
        {zeile(t('plat.bild_zahlbar_an'), 'Shoqata Shembull · 8000 Zürich')}
        {zeile(t('plat.bild_referenz'), '21 00000 00003 13947 14300 09017')}
        {zeile(t('plat.bild_zahlbar_durch'), `${t('plat.bild_m1')} · 8400 Winterthur`)}
        <div className="flex gap-8 mt-4 pt-3" style={{ borderTop: `1px solid ${LINIE}` }}>
          <div>
            <p className="uppercase" style={{ fontFamily: MONO, fontSize: 8, letterSpacing: '0.1em', color: '#8185a0' }}>
              {t('plat.bild_waehrung')}
            </p>
            <p style={{ fontSize: 13, color: TINTE }}>CHF</p>
          </div>
          <div>
            <p className="uppercase" style={{ fontFamily: MONO, fontSize: 8, letterSpacing: '0.1em', color: '#8185a0' }}>
              {t('plat.bild_betrag')}
            </p>
            <p className="tabular-nums" style={{ fontFamily: MONO, fontSize: 13, color: TINTE }}>120.00</p>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- 3. Stammbaum ----------------------------------------------------------
// Verwendet dieselbe Komponente wie die Verwaltung. Ein nachgebautes Bild
// wuerde frueher oder spaeter etwas zeigen, was die Anwendung nicht kann.
const Stammbaumbild: React.FC = () => {
  const { t } = useTranslation();
  const n = (s: string) => t(s);
  const leute = [
    { person:'a', name:n('plat.bild_s1'), geburtsdatum:'1949', eltern:[], geschwister:[],
      partner:[{id:'b',name:n('plat.bild_s2')}],
      kinder:[{id:'c',name:n('plat.bild_s3')},{id:'e',name:n('plat.bild_s5')}] },
    { person:'b', name:n('plat.bild_s2'), geburtsdatum:'1952', eltern:[], geschwister:[],
      partner:[{id:'a',name:n('plat.bild_s1')}],
      kinder:[{id:'c',name:n('plat.bild_s3')},{id:'e',name:n('plat.bild_s5')}] },
    { person:'c', name:n('plat.bild_s3'), geburtsdatum:'1977', geschwister:[],
      eltern:[{id:'a',name:n('plat.bild_s1')},{id:'b',name:n('plat.bild_s2')}],
      partner:[{id:'d',name:n('plat.bild_s4')}],
      kinder:[{id:'f',name:n('plat.bild_s6')},{id:'g',name:n('plat.bild_s7')}] },
    { person:'d', name:n('plat.bild_s4'), geburtsdatum:'1980', eltern:[], geschwister:[],
      partner:[{id:'c',name:n('plat.bild_s3')}],
      kinder:[{id:'f',name:n('plat.bild_s6')},{id:'g',name:n('plat.bild_s7')}] },
    { person:'e', name:n('plat.bild_s5'), geburtsdatum:'1981', geschwister:[],
      eltern:[{id:'a',name:n('plat.bild_s1')},{id:'b',name:n('plat.bild_s2')}],
      partner:[], kinder:[] },
    { person:'f', name:n('plat.bild_s6'), geburtsdatum:'2004', geschwister:[],
      eltern:[{id:'c',name:n('plat.bild_s3')},{id:'d',name:n('plat.bild_s4')}],
      partner:[], kinder:[] },
    { person:'g', name:n('plat.bild_s7'), geburtsdatum:'2008', geschwister:[],
      eltern:[{id:'c',name:n('plat.bild_s3')},{id:'d',name:n('plat.bild_s4')}],
      partner:[], kinder:[] },
  ];
  return (
    <div className="bg-white p-4 sm:p-6">
      <Familienbaum leute={leute} einpassen />
    </div>
  );
};

const Produktbilder: React.FC = () => {
  const { t } = useTranslation();
  return (
    <div className="space-y-16 md:space-y-24 mt-20 md:mt-24">
      <Rahmen marke={t('plat.bild1_marke')} titel={t('plat.bild1_titel')} text={t('plat.bild1_text')}>
        <Mitgliederbild />
      </Rahmen>
      <Rahmen marke={t('plat.bild2_marke')} titel={t('plat.bild2_titel')} text={t('plat.bild2_text')}>
        <Rechnungsbild />
      </Rahmen>
      <Rahmen marke={t('plat.bild3_marke')} titel={t('plat.bild3_titel')} text={t('plat.bild3_text')}>
        <Stammbaumbild />
      </Rahmen>
    </div>
  );
};

export default Produktbilder;
