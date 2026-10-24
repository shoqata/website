// Aufbau der Seite "Ueber uns" -- welche Abschnitte, in welcher Reihenfolge.
//
// Steht im Branding (branding.ueberUns), weil die Seite es ohnehin liest
// und der Website-Editor es ohnehin speichert. Die festen Abschnitte holen
// ihren Inhalt von dort, wo er schon gepflegt wird (Vorstand, Chronik,
// Mitgliederzahlen); eigene Abschnitte bestehen aus Bausteinen wie die
// eigenen Seiten.
//
// Ein Abschnitt ohne Inhalt erscheint nicht, auch wenn er eingeschaltet
// ist: eine Ueberschrift "Unsere Ziele" ueber nichts sieht aus wie ein
// vergessener Verein.

import type { Baustein } from '../components/BausteinEditor';

export type Sprachfeld = { de?: string; sq?: string; en?: string } | string;

export type FesterAbschnitt =
  'einleitung' | 'zahlen' | 'werte' | 'geschichte' | 'ziele' | 'vorstand' | 'mitmachen';

export type Abschnitt = {
  id: string;
  art: FesterAbschnitt | 'eigen';
  an: boolean;
  /** Eigene Ueberschrift; leer = die vorgegebene. */
  titel?: Sprachfeld;
  /** Nur bei art 'eigen'. */
  bloecke?: Baustein[];
};

export const FESTE: { art: FesterAbschnitt; name: string; titel: string; hinweis: string }[] = [
  { art: 'einleitung', name: 'Einleitung',      titel: 'about.title',          hinweis: 'Titel, Text und Globus oder Bild' },
  { art: 'zahlen',     name: 'Zahlen',          titel: 'about.zahlen.titel',   hinweis: 'Mitglieder, Nachbarschaften, Länder, Jahre — und eigene' },
  { art: 'werte',      name: 'Werte',           titel: 'about.werte.titel',    hinweis: 'Karten mit dem, wofür der Verein steht' },
  { art: 'geschichte', name: 'Geschichte',      titel: 'about.geschichte.titel', hinweis: 'Meilensteine aus der Chronik' },
  { art: 'ziele',      name: 'Ziele',           titel: 'about.ziele.titel',    hinweis: 'Was der Verein vorhat' },
  { art: 'vorstand',   name: 'Vorstand',        titel: 'about.vorstand.titel', hinweis: 'Gesichter und Zitate des Vorstands' },
  { art: 'mitmachen',  name: 'Mitmachen',       titel: 'about.mitmachen.titel', hinweis: 'Aufruf zum Beitritt und Kontakt' },
];

// Gespeicherte Reihenfolge zuerst, was fehlt (neu dazugekommen) hinten an.
export function abschnitte(gespeichert: any): Abschnitt[] {
  const liste: Abschnitt[] = Array.isArray(gespeichert?.abschnitte)
    ? gespeichert.abschnitte.filter((a: any) => a && typeof a.id === 'string' && a.art) : [];
  const da = new Set(liste.map(a => a.art));
  for (const f of FESTE) if (!da.has(f.art)) liste.push({ id: f.art, art: f.art, an: true });
  return liste;
}

// Werte-Karten: das Symbol. Die drei alten Arten bleiben gueltig.
export const WERT_SYMBOLE = ['ZIEL', 'GEMEINSCHAFT', 'TRANSPARENZ', 'HERZ', 'BILDUNG', 'HEIMAT', 'HILFE', 'WELT'] as const;
export const WERT_NAMEN: Record<string, string> = {
  ZIEL: 'Ziel', GEMEINSCHAFT: 'Gemeinschaft', TRANSPARENZ: 'Transparenz', HERZ: 'Herz',
  BILDUNG: 'Bildung', HEIMAT: 'Heimat', HILFE: 'Hilfe', WELT: 'Welt',
};
export const wertSymbol = (typ: string | undefined): string =>
  typ === 'MISSION' ? 'ZIEL' : typ === 'COMMUNITY' ? 'GEMEINSCHAFT'
  : typ === 'TRANSPARENCY' ? 'TRANSPARENZ' : (typ && WERT_NAMEN[typ] ? typ : 'WELT');
