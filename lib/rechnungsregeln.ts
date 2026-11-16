// Was eine Rechnung darf -- an einer Stelle.
//
// Am 16.11.2026 gemessen (Koretini, offene Rechnungen):
//   - 31 Rechnungen an Adressen im Ausland standen auf "per Post", und
//     eine davon war schon bei Pingen aufgegeben. Pingen stellt nur in
//     der Schweiz zu.
//   - 23 weitere standen auf "per Post" ohne Land oder mit
//     unvollstaendiger Adresse; nichts hielt sie auf. Die Datenbank
//     setzte bei fehlendem Namen sogar "Unbekannt" ein.
//   - 35 Rechnungen an Adressen im Ausland waren in CHF gestellt, weil
//     die Waehrung allein aus der Beitragsgruppe kam.
//
// Diese Datei beantwortet drei Fragen, und alle Wege, die eine Rechnung
// stellen oder verschicken, fragen hier. Die Datenbank prueft die
// Postregel noch einmal (post_einreihen) -- die Oberflaeche ist nur die
// erste Stelle, nicht die einzige.

import { normalizeCountry } from '../services/qrBillService';

export type Anschrift = {
  name?: string | null; adresse?: string | null; plz?: string | null;
  ort?: string | null; land?: string | null;
};

const leer = (v?: string | null) => String(v ?? '').trim() === '';

// Wo wohnt jemand?
//
// Anders als normalizeCountry gilt hier ein leeres Land NICHT als
// Schweiz. Fuer die QR-Rechnung ist das richtig (der Verein ist
// schweizerisch), fuer einen Brief nicht: Oesterreich und Belgien haben
// ebenfalls vierstellige Postleitzahlen. Ohne Land weiss man es nicht.
export type Wohnsitz = 'CH' | 'AUSLAND' | 'UNBEKANNT';
export function wohnsitz(land?: string | null): Wohnsitz {
  if (leer(land)) return 'UNBEKANNT';
  const c = normalizeCountry(String(land));
  if (c === 'CH') return 'CH';
  if (c === 'XX') return 'UNBEKANNT';
  return 'AUSLAND';
}

// ----------------------------------------------------------- Postversand
export type PostGrund = 'AUSLAND' | 'LAND_FEHLT' | 'NAME' | 'STRASSE' | 'PLZ' | 'ORT';
// Ein einfacher Satz statt einer Unterscheidungsvereinigung: das Projekt
// laeuft ohne strictNullChecks, und dort engt TypeScript { ok: false } nicht ein.
export type PostPruefung = { ok: boolean; grund?: PostGrund; text?: string };

const POST_TEXT: Record<PostGrund, string> = {
  AUSLAND: 'Die Adresse liegt im Ausland. Der Briefversand (Pingen) stellt nur in der Schweiz zu.',
  LAND_FEHLT: 'Beim Mitglied ist kein Land eingetragen. Ein Brief geht nur an eine Adresse, die ausdrücklich in der Schweiz liegt.',
  NAME: 'Der Name des Empfängers fehlt.',
  STRASSE: 'Strasse und Hausnummer fehlen.',
  PLZ: 'Die Postleitzahl ist keine Schweizer Postleitzahl (vier Ziffern).',
  ORT: 'Der Ort fehlt.',
};

// Darf diese Anschrift einen Brief bekommen? Nur eine vollstaendige
// Schweizer Adresse. Die Reihenfolge der Pruefungen ist die, in der man
// den Fehler beheben wuerde: erst das Land, dann die Zeilen.
export function postTauglich(a: Anschrift): PostPruefung {
  const nein = (grund: PostGrund): PostPruefung => ({ ok: false, grund, text: POST_TEXT[grund] });
  const w = wohnsitz(a.land);
  if (w === 'AUSLAND') return nein('AUSLAND');
  if (w === 'UNBEKANNT') return nein('LAND_FEHLT');
  if (leer(a.name)) return nein('NAME');
  // Eine Strasse ohne einen einzigen Buchstaben ist keine ("12", "-").
  if (leer(a.adresse) || !/\p{L}/u.test(String(a.adresse))) return nein('STRASSE');
  const plz = String(a.plz ?? '').trim();
  if (!/^\d{4}$/.test(plz) || Number(plz) < 1000) return nein('PLZ');
  if (leer(a.ort)) return nein('ORT');
  return { ok: true };
}

// ----------------------------------------------------------- Waehrung
// Wer im Ausland wohnt, zahlt in Euro. Eine CHF-Rechnung an eine
// deutsche Adresse kostet den Zahler Wechselgebuehren, und der
// europaeische GiroCode, den diese Rechnungen tragen, kennt nur Euro.
export function waehrungFuer(land?: string | null): 'CHF' | 'EUR' | null {
  const w = wohnsitz(land);
  if (w === 'AUSLAND') return 'EUR';
  if (w === 'CH') return 'CHF';
  return null; // unbekannt: nicht raten
}

export function waehrungStimmt(land: string | null | undefined, waehrung: string | null | undefined): boolean {
  const soll = waehrungFuer(land);
  return soll === null || String(waehrung || 'CHF').toUpperCase() === soll;
}

// ----------------------------------------------------------- PayPal
// Ein PayPal.Me-Name ergibt einen Link mit Betrag und Waehrung schon
// eingetragen; ohne ihn bleibt nur die E-Mail-Adresse, und der Zahler
// tippt den Betrag selbst -- die Stelle, an der die falsche Zahl
// entsteht. Der Name wird streng geprueft, weil er in eine Adresse
// eingesetzt wird.
export function paypalLink(name: string | null | undefined, betrag: number, waehrung: string): string | null {
  // Nur der Vorsatz "paypal.me/" darf weg. Was danach kommt, wird nicht
  // zurechtgeschnitten: aus "a/../b" darf nicht still das Konto "a" werden.
  const n = String(name ?? '').trim().replace(/^(https?:\/\/)?(www\.)?paypal\.me\//i, '').replace(/\/$/, '');
  if (!/^[A-Za-z0-9]{1,20}$/.test(n)) return null;
  if (!Number.isFinite(betrag) || betrag <= 0) return null;
  const w = String(waehrung || '').toUpperCase();
  if (!/^[A-Z]{3}$/.test(w)) return null;
  // Ganze Betraege ohne Nachkommastellen, sonst mit zwei.
  const zahl = Number.isInteger(betrag) ? String(betrag) : betrag.toFixed(2);
  return `https://paypal.me/${n}/${zahl}${w}`;
}
