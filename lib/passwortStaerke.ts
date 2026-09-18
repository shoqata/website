// Wie sicher ist ein Passwort?
//
// Die Anmeldung ueber Google ist entfernt; damit ist das Passwort der einzige
// Weg herein, und es traegt allein, was vorher zwei Wege trugen. Ein Konto in
// dieser Anwendung gibt Zugriff auf Anschriften, Beitraege und Rechnungen --
// bei einem Vorstandskonto auf die aller Mitglieder.
//
// Bewertet wird nicht nach Zeichenklassen allein. "Passwort1!" erfuellt jede
// uebliche Regel und ist trotzdem in Sekunden geraten, waehrend "vier ruhige
// braune pferde" keine Sonderzeichen hat und um Groessenordnungen besser ist.
// Massgeblich sind deshalb Laenge und Vielfalt zusammen, und offensichtlich
// Schlechtes wird ausdruecklich abgewiesen.

export type Staerke = 'ZU_KURZ' | 'SCHWACH' | 'MITTEL' | 'GUT' | 'STARK';

export const MINDESTLAENGE = 10;

// Was in dieser Umgebung naheliegt: der Verein, die Sprache, die Region.
// Eine vollstaendige Liste bekannter Passwoerter waere im Buendel zu gross;
// diese Auswahl faengt die Faelle, die hier tatsaechlich vorkommen.
const NAHELIEGEND = [
  'passwort', 'password', 'kalimi', 'fjalekalimi', 'qwertz', 'qwerty', 'asdfgh',
  'koretini', 'unityhub', 'shoqata', 'dervishi', 'schweiz', 'zvicer', 'kosova',
  'admin', 'administrator', 'willkommen', 'mirsevini', 'geheim', 'secret',
  '123456', '12345678', '1234567890', 'abc123', 'letmein', 'iloveyou',
];

const hatKleinbuchstaben = (p: string) => /[a-zäöüàéèç]/.test(p);
const hatGrossbuchstaben = (p: string) => /[A-ZÄÖÜÀÉÈÇ]/.test(p);
const hatZiffern         = (p: string) => /\d/.test(p);
const hatSonderzeichen   = (p: string) => /[^A-Za-zÄÖÜäöüÀÉÈÇàéèç0-9]/.test(p);

// Drei gleiche Zeichen hintereinander oder eine Folge wie "abcd" / "1234".
const hatMuster = (p: string): boolean => {
  const k = p.toLowerCase();
  if (/(.)\1\1/.test(k)) return true;
  for (let i = 0; i + 3 < k.length; i++) {
    const a = k.charCodeAt(i);
    let auf = true, ab = true;
    for (let j = 1; j < 4; j++) {
      if (k.charCodeAt(i + j) !== a + j) auf = false;
      if (k.charCodeAt(i + j) !== a - j) ab = false;
    }
    if (auf || ab) return true;
  }
  return false;
};

export const enthaeltNaheliegendes = (passwort: string): string | null => {
  const k = passwort.toLowerCase();
  // Der laengste Treffer, nicht der erste: in "fjalekalimi" steckt auch
  // "kalimi", und die laengere Uebereinstimmung ist die aussagekraeftigere,
  // falls das Wort je genannt wird.
  const treffer = NAHELIEGEND.filter((w) => k.includes(w));
  if (!treffer.length) return null;
  return treffer.reduce((a, b) => (b.length > a.length ? b : a));
};

export interface Bewertung {
  staerke: Staerke;
  /** Ab hier darf gespeichert werden. */
  genuegt: boolean;
  /** Uebersetzungsschluessel dessen, was noch fehlt. */
  hinweise: string[];
  /** 0 bis 4, fuer die Anzeige. */
  balken: number;
}

export const bewertePasswort = (passwort: string, kontext: string[] = []): Bewertung => {
  const p = passwort || '';
  const hinweise: string[] = [];

  if (p.length < MINDESTLAENGE) {
    return {
      staerke: 'ZU_KURZ', genuegt: false, balken: p.length === 0 ? 0 : 1,
      hinweise: ['pw.rule_length'],
    };
  }

  // Die eigene Adresse oder der eigene Name im Passwort ist der erste Versuch,
  // den jemand unternimmt, der die Person kennt.
  const eigenes = kontext
    .filter((w) => w && w.length >= 4)
    .flatMap((w) => w.toLowerCase().split(/[^a-zäöüà-ÿ0-9]+/i))
    .filter((w) => w.length >= 4)
    .find((w) => p.toLowerCase().includes(w));
  if (eigenes) hinweise.push('pw.rule_personal');

  const naheliegend = enthaeltNaheliegendes(p);
  if (naheliegend) hinweise.push('pw.rule_common');

  let vielfalt = 0;
  if (hatKleinbuchstaben(p)) vielfalt++;
  if (hatGrossbuchstaben(p)) vielfalt++;
  if (hatZiffern(p)) vielfalt++;
  if (hatSonderzeichen(p)) vielfalt++;

  if (hatMuster(p)) hinweise.push('pw.rule_pattern');

  // Laenge wiegt schwerer als Vielfalt -- deshalb darf ein langes Passwort mit
  // wenig Vielfalt trotzdem gut sein.
  let punkte = 0;
  if (p.length >= 10) punkte += 1;
  if (p.length >= 14) punkte += 1;
  if (p.length >= 20) punkte += 1;
  if (vielfalt >= 2) punkte += 1;
  if (vielfalt >= 3) punkte += 1;

  if (naheliegend || eigenes) punkte = Math.min(punkte, 1);
  if (hatMuster(p)) punkte = Math.max(0, punkte - 1);

  // Ohne mindestens zwei Zeichenarten reicht die Laenge allein nicht.
  if (vielfalt < 2 && p.length < 16) hinweise.push('pw.rule_variety');

  const staerke: Staerke =
      punkte >= 4 ? 'STARK'
    : punkte === 3 ? 'GUT'
    : punkte === 2 ? 'MITTEL'
    : 'SCHWACH';

  // Angenommen wird ab MITTEL und nur ohne die schweren Einwaende. Alles
  // darunter waere eine Empfehlung, die niemand befolgt.
  const genuegt = (staerke === 'MITTEL' || staerke === 'GUT' || staerke === 'STARK')
    && !naheliegend && !eigenes;

  return {
    staerke, genuegt, hinweise,
    balken: Math.max(1, Math.min(4, punkte)),
  };
};
