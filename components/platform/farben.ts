// Farben und Schriften der Betreiberdarstellung.
//
// Lagen bisher als Konstanten in PlatformHome, LoginPage und der Wortmarke --
// drei Kopien derselben Werte. Mit dem Cookie-Hinweis waere eine vierte
// dazugekommen, und spaetestens dann laufen sie auseinander. Deshalb hier an
// einer Stelle.
//
// Die Vereinsdarstellung hat ihre eigenen Werte in index.html (--primary,
// --accent); beide Welten beruehren sich nicht.
export const TINTE = '#00052e';     // Grund: fast schwarzes Blau
export const BLAU = '#0428cb';      // Aktionsfarbe
export const LEUCHTEN = '#34fcff';  // einzelner Akzent, sparsam
export const NEBEL = '#6b6b83';     // Fliesstext auf dunklem Grund
export const SCHIEFER = '#4f5166';  // Haarlinien
export const LINIE = '#dbdcdf';     // Haarlinien auf hellem Grund

// Schreibmaschinenschrift fuer Systemangaben -- in der Vorlage ausdruecklich
// von der Fliesstextschrift getrennt, damit Maschinelles als solches lesbar
// bleibt.
export const MONO = "'IBM Plex Mono', ui-monospace, SFMono-Regular, Menlo, monospace";
