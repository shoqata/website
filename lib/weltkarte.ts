// Die Weltkarte auf "Ueber uns": wo die Mitglieder leben, je Land gezaehlt.
//
// Die Karte zeigt Laender, keine Personen. Bis zum 31.10.2026 stand dort ein
// Punkt je Mitglied, bei unbekannter Stadt fest versetzt innerhalb des
// Landes -- also nie die echte Lage, aber doch einer pro Kopf. Jetzt traegt
// jedes Land einen Pin mit der Zahl, und eine Stadt wird erst genannt, wenn
// dort mindestens STADT_AB Mitglieder wohnen: "1 Mitglied in Bruessel" waere
// sonst eine Adresse.

import { matchCountry } from './countries';

export const STADT_AB = 3;

type Sprache = 'de' | 'en' | 'sq';

// Lage fuer den Pin: ungefaehr dort, wo die meisten Menschen des Landes
// wohnen, nicht der geometrische Mittelpunkt.
const LAENDER: Record<string, { code: string; lat: number; lng: number; name: Record<Sprache, string> }> = {
  'Schweiz':     { code: 'CH', lat: 47.2,  lng: 8.3,   name: { de: 'Schweiz', en: 'Switzerland', sq: 'Zvicër' } },
  'Deutschland': { code: 'DE', lat: 50.9,  lng: 9.9,   name: { de: 'Deutschland', en: 'Germany', sq: 'Gjermani' } },
  'Kosovo':      { code: 'XK', lat: 42.6,  lng: 20.9,  name: { de: 'Kosovo', en: 'Kosovo', sq: 'Kosovë' } },
  'Österreich':  { code: 'AT', lat: 47.9,  lng: 14.6,  name: { de: 'Österreich', en: 'Austria', sq: 'Austri' } },
  'Frankreich':  { code: 'FR', lat: 46.8,  lng: 2.6,   name: { de: 'Frankreich', en: 'France', sq: 'Francë' } },
  'Italien':     { code: 'IT', lat: 43.2,  lng: 12.0,  name: { de: 'Italien', en: 'Italy', sq: 'Itali' } },
  'Spanien':     { code: 'ES', lat: 40.3,  lng: -3.7,  name: { de: 'Spanien', en: 'Spain', sq: 'Spanjë' } },
  'Belgien':     { code: 'BE', lat: 50.7,  lng: 4.5,   name: { de: 'Belgien', en: 'Belgium', sq: 'Belgjikë' } },
  'Niederlande': { code: 'NL', lat: 52.2,  lng: 5.3,   name: { de: 'Niederlande', en: 'Netherlands', sq: 'Holandë' } },
  'England':     { code: 'GB', lat: 52.5,  lng: -1.5,  name: { de: 'England', en: 'England', sq: 'Angli' } },
  'USA':         { code: 'US', lat: 39.5,  lng: -95.0, name: { de: 'USA', en: 'USA', sq: 'SHBA' } },
};

export type Land = {
  schluessel: string;
  code: string;
  name: string;
  lat: number;
  lng: number;
  anzahl: number;
  /** Staedte mit mindestens STADT_AB Mitgliedern, die groessten zuerst, hoechstens drei. */
  staedte: string[];
};

export type Heimat = { name: string; lat: number; lng: number };

// Liest einen gespeicherten Heimatort; unvollstaendig heisst: keiner.
export function heimatLesen(wert: any): Heimat | null {
  // Komma oder Punkt: "42,54" tippt sich so natuerlich wie "42.54".
  const zahl = (v: any) => (v === '' || v == null ? NaN : Number(String(v).trim().replace(',', '.')));
  const lat = zahl(wert?.lat);
  const lng = zahl(wert?.lng);
  const name = String(wert?.name ?? '').trim();
  if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return { name, lat, lng };
}

export function laenderZaehlen(
  mitglieder: { city?: string | null; country?: string | null }[],
  sprache: Sprache,
): { laender: Land[]; ohneLand: number } {
  const je = new Map<string, { anzahl: number; staedte: Map<string, number> }>();
  let ohneLand = 0;
  for (const m of mitglieder) {
    const land = matchCountry(m.country);
    if (!land || !LAENDER[land]) { ohneLand++; continue; }
    const e = je.get(land) ?? { anzahl: 0, staedte: new Map() };
    e.anzahl++;
    const stadt = (m.city ?? '').trim();
    if (stadt) e.staedte.set(stadt, (e.staedte.get(stadt) ?? 0) + 1);
    je.set(land, e);
  }
  const laender = [...je.entries()].map(([schluessel, e]) => {
    const l = LAENDER[schluessel];
    return {
      schluessel,
      code: l.code,
      name: l.name[sprache] ?? l.name.de,
      lat: l.lat,
      lng: l.lng,
      anzahl: e.anzahl,
      staedte: [...e.staedte.entries()]
        .filter(([, n]) => n >= STADT_AB)
        .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
        .slice(0, 3)
        .map(([s]) => s),
    };
  });
  // Von Ost nach West: so dreht die Abfolge den Globus in seine eigene Richtung.
  laender.sort((a, b) => b.lng - a.lng);
  return { laender, ohneLand };
}
