import React from 'react';
import SwissQRBill from './SwissQRBill';
import { QrBillData } from '../services/qrBillService';
import { BLATT, ZAHLTEIL, type Feld, type Rechnungslayout } from '../lib/rechnungslayout';
import { onImageError } from '../lib/imageFallback';

// Das Rechnungsblatt -- gezeichnet aus dem Layout, nicht aus festem Markup.
//
// Vorher stand der Aufbau als eine lange Zeile in AdminFinance.tsx. Damit
// konnte ein Designer zwar Positionen speichern, aber nichts bewegen: die
// Rechnung las sie nicht. Ein Designer, der nichts aendert, ist Zierde.
//
// Jetzt gibt es eine Zeichnung und zwei, die sie benutzen: der Designer als
// Vorschau und die Rechnungsansicht zum Drucken. Was man im Designer sieht,
// ist damit das, was gedruckt wird -- und nicht eine zweite Nachbildung
// davon, die beim naechsten Umbau auseinanderlaeuft.
//
// Der Zahlteil unten wird NICHT aus dem Layout gezeichnet. Seine Masse sind
// vorgeschrieben; er sitzt fest auf den unteren 105 mm.

export type Rechnungsdaten = {
  nummer: string;
  datum: string;
  beschreibung: string;
  betrag: number;
  waehrung: string;
  verein: { name: string; strasse?: string; plz?: string; ort?: string; land?: string; email?: string };
  logoUrl?: string;
  qr?: QrBillData | null;
  schlusswort?: string;
  ueberschrift: string;
  beschriftung: { nummer: string; datum: string; an: string; was: string; betrag: string };
};

const mm = (w: number) => `${w}mm`;

// Ein Feld an seinen Platz setzen. pt in mm: 1 pt = 25.4/72 mm.
const platz = (f: Feld): React.CSSProperties => ({
  position: 'absolute',
  left: mm(f.x), top: mm(f.y),
  width: f.breite !== undefined ? mm(f.breite) : undefined,
  fontSize: `${(f.groesse * 25.4) / 72}mm`,
  lineHeight: 1.35,
  textAlign: f.ausrichtung === 'rechts' ? 'right' : 'left',
});

// nurKopf: nur der gestaltbare Teil (die oberen 192 mm), ohne Zahlteil.
//
// Die Rechnungsansicht kennt drei Zahlungswege -- QR-Beleg, TWINT und den
// SEPA-Code -- und zeichnet sie unterhalb selbst. Die wollte ich nicht in
// dieses Blatt ziehen; sie haben mit der Gestaltung nichts zu tun und ihr
// Aufbau haengt am gewaehlten Weg. Der Kopf wird also absolut gesetzt, der
// Rest bleibt im Fluss darunter.
const Rechnungsblatt: React.FC<{
  layout: Rechnungslayout;
  daten: Rechnungsdaten;
  id?: string;
  nurKopf?: boolean;
}> = ({ layout, daten, id, nurKopf }) => {
  const F = layout.felder;
  const zeig = (k: string) => F[k]?.sichtbar !== false;

  return (
    <div id={id}
         className="bg-white text-stone-900 relative"
         style={{ width: mm(BLATT.breite),
                  height: mm(nurKopf ? ZAHLTEIL.oben : BLATT.hoehe),
                  boxSizing: 'border-box' }}>

      {zeig('logo') && (
        <div style={platz(F.logo)} className="flex items-center gap-2">
          {daten.logoUrl
            ? <img src={daten.logoUrl} alt="" onError={onImageError}
                   style={{ height: mm(F.logo.groesse), width: 'auto', objectFit: 'contain' }} />
            : <span className="font-display font-bold italic">{daten.verein.name}</span>}
        </div>
      )}

      {zeig('absender') && (
        <div style={platz(F.absender)} className="leading-snug">
          <p className="font-bold">{daten.verein.name}</p>
          {daten.verein.strasse && <p>{daten.verein.strasse}</p>}
          <p>{[daten.verein.plz, daten.verein.ort].filter(Boolean).join(' ')}</p>
          {daten.verein.land && <p>{daten.verein.land}</p>}
          {daten.verein.email && <p className="text-stone-500">{daten.verein.email}</p>}
        </div>
      )}

      {zeig('titel') && (
        <h1 style={platz(F.titel)} className="font-bold tracking-tight">{daten.ueberschrift}</h1>
      )}

      {zeig('nummer') && (
        <p style={platz(F.nummer)} className="font-mono text-stone-500">
          {daten.beschriftung.nummer} {daten.nummer}
        </p>
      )}

      {zeig('datum') && (
        <p style={platz(F.datum)} className="text-stone-500">
          {daten.beschriftung.datum} {daten.datum}
        </p>
      )}

      {zeig('empfaenger') && daten.qr && (
        <div style={platz(F.empfaenger)} className="leading-snug">
          <p className="text-[0.6em] font-bold text-stone-400 uppercase tracking-widest mb-1">
            {daten.beschriftung.an}
          </p>
          <p className="font-bold">{daten.qr.debtor.name}</p>
          <p>{daten.qr.debtor.address}</p>
          <p>{[daten.qr.debtor.zip, daten.qr.debtor.city].filter(Boolean).join(' ')}</p>
        </div>
      )}

      {zeig('tabelle') && (
        <table style={platz(F.tabelle)} className="border-collapse">
          <thead>
            <tr className="border-b-2 border-stone-900">
              <th className="text-left py-1 font-bold uppercase tracking-wider text-[0.75em]">
                {daten.beschriftung.was}
              </th>
              <th className="text-right py-1 font-bold uppercase tracking-wider text-[0.75em] whitespace-nowrap">
                {daten.beschriftung.betrag}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr className="border-b border-stone-200">
              <td className="py-2 align-top">{daten.beschriftung.was === '' ? '' : daten.beschreibung}</td>
              <td className="py-2 text-right tabular-nums whitespace-nowrap">
                {daten.waehrung} {Number(daten.betrag).toFixed(2)}
              </td>
            </tr>
            <tr>
              <td className="py-2 font-bold">{/* Summenzeile */}</td>
              <td className="py-2 text-right font-bold tabular-nums whitespace-nowrap">
                {daten.waehrung} {Number(daten.betrag).toFixed(2)}
              </td>
            </tr>
          </tbody>
        </table>
      )}

      {zeig('hinweis') && daten.schlusswort && (
        <p style={platz(F.hinweis)} className="text-stone-500 italic">{daten.schlusswort}</p>
      )}

      {/* Der Zahlteil. Fest auf den unteren 105 mm -- nicht aus dem Layout. */}
      {!nurKopf && daten.qr && (
        <div style={{ position: 'absolute', left: 0, top: mm(ZAHLTEIL.oben),
                      width: mm(BLATT.breite), height: mm(ZAHLTEIL.hoehe) }}>
          <SwissQRBill data={daten.qr} />
        </div>
      )}
    </div>
  );
};

export default Rechnungsblatt;
