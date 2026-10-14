// Zeigen, laden oder umleiten?
//
// Drei Zustaende, und der mittlere ist der, der gern vergessen wird:
// solange nicht bekannt ist, welche Module der Verein hat, darf die
// Seite NICHT umgeleitet werden. Sonst wirft sie einen Besucher hinaus,
// dessen Verein das Modul laengst gebucht hat -- der Fehler faellt
// niemandem auf, weil ein zweiter Aufruf meist klappt.
//
// Umgekehrt darf sie auch nicht schon anzeigen: dann blitzt eine Seite
// auf, die dem Verein nicht gehoert.
//
// Die Entscheidung stand als Kette im JSX und galt fuer drei Routen.
// Hier steht sie einmal und ist pruefbar.

export type Seitenzustand = 'LAEDT' | 'ZEIGEN' | 'UMLEITEN';

export function seitenZustand(
  module: Set<string> | null | undefined,
  schluessel: string,
  istPlattformDomain?: boolean | null,
): Seitenzustand {
  // Die Betreiberseite zeigt keine Vereinsseiten. Ein unbekannter
  // Zustand (null) gilt dabei als "kein Betreiber" -- so war es vorher
  // auch, und die Vereinsseite ist der haeufigere Fall.
  if (istPlattformDomain === true) return 'UMLEITEN';
  if (module === null || module === undefined) return 'LAEDT';
  return module.has(schluessel) ? 'ZEIGEN' : 'UMLEITEN';
}
