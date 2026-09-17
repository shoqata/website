// Laender, in denen Mitglieder des Vereins leben.
//
// Die Adresse wurde bisher als freies Feld erfasst -- im Bestand stehen
// dadurch "DE", "Holland", "FR" und "Schweiz" nebeneinander, und 343 von 350
// Zeilen sind leer. Eine feste Auswahl macht die Angabe auswertbar; "anderes"
// bleibt fuer die Faelle, die nicht in der Liste stehen.
export const COUNTRY_OPTIONS = [
  'Schweiz',
  'Deutschland',
  'Kosovo',
  'Österreich',
  'Frankreich',
  'Italien',
  'Spanien',
  'Belgien',
  'Niederlande',
  'England',
  'USA',
] as const;

export const OTHER_COUNTRY = '__ANDERES__';

// Altbestand einordnen: Kuerzel und Schreibvarianten auf die Auswahl abbilden.
const ALIASES: Record<string, string> = {
  ch: 'Schweiz', che: 'Schweiz', switzerland: 'Schweiz', zvicer: 'Schweiz', 'zvicër': 'Schweiz',
  de: 'Deutschland', deu: 'Deutschland', germany: 'Deutschland', gjermani: 'Deutschland',
  xk: 'Kosovo', kos: 'Kosovo', kosova: 'Kosovo', 'kosovë': 'Kosovo',
  at: 'Österreich', aut: 'Österreich', austria: 'Österreich', oesterreich: 'Österreich',
  fr: 'Frankreich', fra: 'Frankreich', france: 'Frankreich',
  it: 'Italien', ita: 'Italien', italy: 'Italien',
  es: 'Spanien', esp: 'Spanien', spain: 'Spanien',
  be: 'Belgien', bel: 'Belgien', belgium: 'Belgien',
  nl: 'Niederlande', nld: 'Niederlande', holland: 'Niederlande', netherlands: 'Niederlande',
  uk: 'England', gb: 'England', 'united kingdom': 'England', grossbritannien: 'England',
  us: 'USA', usa: 'USA', 'united states': 'USA',
};

// Liefert den Listeneintrag zu einem gespeicherten Wert -- oder null, wenn es
// ein Sonderfall ist, der im Freitextfeld stehen bleibt.
export const matchCountry = (value?: string | null): string | null => {
  const v = (value || '').trim();
  if (!v) return null;
  const exact = COUNTRY_OPTIONS.find((c) => c.toLowerCase() === v.toLowerCase());
  if (exact) return exact;
  return ALIASES[v.toLowerCase()] || null;
};
