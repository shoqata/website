import type { UserProfile } from '../types';

// Der Postausgang des Vorstands.
//
// Drei Regeln stehen hier, weil sie sonst in der Maske stuenden und
// nicht zu pruefen waeren.
//
// 1. WER IST ERREICHBAR. Ein Mitglied ohne brauchbare Adresse ist kein
//    Fehler, sondern ein Normalfall -- 56 der 353 haben keine. Die Maske
//    muss das VORHER sagen: "an 297 von 353" ist eine Auskunft,
//    "verschickt" nach einem Lauf, der 56 stillschweigend uebersprungen
//    hat, ist eine Falschmeldung.
//
// 2. WELCHE ADRESSE DARF ABSENDER SEIN. Nur eine auf einer Domain des
//    Vereins. Liesse man jede zu, waere die Maske ein Werkzeug, um unter
//    fremdem Namen zu schreiben -- und die Antwort ginge an den
//    Fremden.
//
// 3. WAS BEDEUTET DIE WEITERLEITUNGSLISTE. Sie kommt als Text, Zeile um
//    Zeile, "a@verein.ch -> b@gmail.com". Ein Parser dafuer ist kurz und
//    erspart fuenf Eingabefelder.

export type Empfaengerwahl = 'ALLE' | 'AUSWAHL';

export type Aufbereitet = {
  erreichbar: { id: string; name: string; email: string; sprache?: string | null }[];
  ohne_adresse: { id: string; name: string }[];
};

const brauchbar = (e?: string | null): boolean => {
  const s = String(e ?? '').trim().toLowerCase();
  if (!s || !s.includes('@')) return false;
  // Platzhalter, die im Bestand stehen. Eine Adresse, die niemandem
  // gehoert, ist schlimmer als keine: sie erzeugt eine Rueckweisung und
  // laesst den Lauf nach Erfolg aussehen.
  if (/^(keine|none|-|n\/a|unbekannt)@/.test(s)) return false;
  if (s.endsWith('@example.com') || s.endsWith('@test.local')) return false;
  const [lokal, domain] = s.split('@');
  return !!lokal && !!domain && domain.includes('.');
};

const nameVon = (m: any): string =>
  String(m?.displayName ?? '').trim()
  || [m?.firstName, m?.lastName].filter(Boolean).join(' ').trim()
  || String(m?.id ?? '');

export function empfaengerAufbereiten(
  mitglieder: Partial<UserProfile>[] | null | undefined,
  ausgewaehlt?: Set<string> | string[] | null,
): Aufbereitet {
  const wahl = ausgewaehlt
    ? (ausgewaehlt instanceof Set ? ausgewaehlt : new Set(ausgewaehlt))
    : null;
  const erreichbar: Aufbereitet['erreichbar'] = [];
  const ohne_adresse: Aufbereitet['ohne_adresse'] = [];

  for (const m of mitglieder ?? []) {
    const id = String((m as any)?.id ?? '');
    if (!id) continue;
    if (wahl && !wahl.has(id)) continue;
    // Ausgetretene bekommen keine Vereinspost. Das steht hier und nicht
    // in der Maske, damit es bei JEDER Auswahl gilt -- auch bei "alle".
    if (String((m as any)?.membershipStatus ?? '') === 'INACTIVE') continue;
    const email = String((m as any)?.email ?? '').trim();
    if (brauchbar(email)) {
      erreichbar.push({ id, name: nameVon(m), email, sprache: (m as any)?.sprache ?? null });
    } else {
      ohne_adresse.push({ id, name: nameVon(m) });
    }
  }
  return { erreichbar, ohne_adresse };
}

// Darf diese Adresse als Absender gelten?
//
// Sie muss auf einer Domain des Vereins liegen. Die Pruefung ist nicht
// Kosmetik: die Antwort des Mitglieds geht an diese Adresse.
export function absenderPruefen(
  adresse: string | null | undefined,
  domains: string[] | null | undefined,
): { ok: boolean; grund?: string } {
  const a = String(adresse ?? '').trim().toLowerCase();
  if (!a) return { ok: false, grund: 'Es fehlt die Adresse.' };
  if (!/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(a)) {
    return { ok: false, grund: `"${adresse}" ist keine Adresse.` };
  }
  const domain = a.split('@')[1];
  const erlaubt = (domains ?? [])
    .map(d => String(d ?? '').trim().toLowerCase().replace(/^www\./, ''))
    .filter(Boolean);
  if (erlaubt.length === 0) {
    return { ok: false, grund: 'Für diesen Verein ist keine Domain hinterlegt.' };
  }
  // Registriert ist bei Koretini "www.koretini.me", die Adressen liegen
  // aber auf "koretini.me" -- darum wird beim Normalisieren oben ein
  // fuehrendes www. entfernt. Die Adresse selbst wird NICHT so
  // behandelt: eine Maildomain traegt kein www., und x@www.verein.ch
  // ist falsch, nicht gleichwertig. Eine Unterdomain reicht ebenfalls
  // nicht -- @mail.verein.ch ist eine andere Zustellung.
  const passt = erlaubt.includes(domain);
  if (!passt) {
    return { ok: false, grund:
      `${domain} gehört nicht zum Verein. Erlaubt: ${erlaubt.join(', ')}.` };
  }
  return { ok: true };
}

// Die Weiterleitungsliste, wie sie geliefert wird.
//
// "valton.rexha@koretini.me -> valton.rexha@gmail.com", eine Zeile je
// Person, mit oder ohne Leerzeichen, mit -> oder → oder =>. Eine Zeile,
// die nicht passt, wird GEMELDET und nicht uebergangen: eine stillschweigend
// verworfene Zeile heisst, dass eine Person keine Post bekommt.
export type Weiterleitung = { adresse: string; ziel: string };

export function weiterleitungenLesen(
  text: string | null | undefined,
): { eintraege: Weiterleitung[]; unklar: string[] } {
  const eintraege: Weiterleitung[] = [];
  const unklar: string[] = [];
  const gesehen = new Set<string>();

  for (const rohzeile of String(text ?? '').split(/[\r\n,;]+/)) {
    const zeile = rohzeile.trim();
    if (!zeile) continue;
    const m = zeile.match(/^(\S+@\S+?)\s*(?:->|→|=>|>)\s*(\S+@\S+)$/);
    if (!m) { unklar.push(zeile); continue; }
    const adresse = m[1].trim().toLowerCase().replace(/[.,;]+$/, '');
    // Das Ziel bleibt in seiner Schreibweise: Ismetklaiqi6@gmail.com ist
    // so gemeldet worden, und der lokale Teil einer Adresse darf
    // Gross- und Kleinschreibung unterscheiden.
    const ziel = m[2].trim().replace(/[.,;]+$/, '');
    if (gesehen.has(adresse)) { unklar.push(`${zeile} (Adresse doppelt)`); continue; }
    gesehen.add(adresse);
    eintraege.push({ adresse, ziel });
  }
  return { eintraege, unklar };
}


// Die Liste den Personen zuordnen.
//
// Die Liste nennt Adressen, die Datenbank kennt Namen. Der lokale Teil
// ist bei allen fuenf gemeldeten Adressen "vorname.nachname" -- daran
// laesst sich zuordnen, und nur daran: ein Rateverfahren ueber
// Aehnlichkeit wuerde bei zwei Mehmetis die Post des einen dem anderen
// geben.
//
// Wer nicht eindeutig zugeordnet werden kann, bleibt UNZUGEORDNET und
// wird gemeldet. Die Alternative -- "nimm den aehnlichsten" -- ist bei
// Adressen die falsche: eine Mail beim falschen Empfaenger ist kein
// kleiner Fehler.

const entfeinern = (s: string): string =>
  String(s ?? '')
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')   // Akzente weg
    .replace(/ë/g, 'e').replace(/ç/g, 'c')
    .replace(/[^a-z0-9]+/g, '.')
    .replace(/^\.+|\.+$/g, '');

// "Valton Rexha" -> "valton.rexha"; "Rexha Valton" ergibt dasselbe,
// weil die Teile sortiert verglichen werden. Die Reihenfolge von Vor-
// und Nachnamen ist in den Daten nicht verlaesslich.
export function namensschluessel(name: string | null | undefined): string {
  const teile = entfeinern(name ?? '').split('.').filter(Boolean);
  return teile.sort().join('.');
}

export type Person = { id: string; name: string };
export type Zuordnung = {
  treffer: { person: Person; adresse: string; ziel: string }[];
  offen: { adresse: string; ziel: string; grund: string }[];
};

export function zuordnen(
  eintraege: Weiterleitung[] | null | undefined,
  personen: Person[] | null | undefined,
): Zuordnung {
  const treffer: Zuordnung['treffer'] = [];
  const offen: Zuordnung['offen'] = [];

  // Schluessel -> Personen. Eine Liste und kein einzelner Wert: zwei
  // Personen mit demselben Namen muessen auffallen und nicht die eine
  // die andere verdecken.
  const nach = new Map<string, Person[]>();
  for (const p of personen ?? []) {
    const k = namensschluessel(p.name);
    if (!k) continue;
    nach.set(k, [...(nach.get(k) ?? []), p]);
  }

  const schonVergeben = new Set<string>();
  for (const e of eintraege ?? []) {
    const lokal = String(e.adresse ?? '').split('@')[0] ?? '';
    const k = namensschluessel(lokal);
    const kandidaten = nach.get(k) ?? [];
    if (kandidaten.length === 0) {
      offen.push({ ...e, grund: 'kein Mitglied mit diesem Namen' });
      continue;
    }
    if (kandidaten.length > 1) {
      offen.push({ ...e, grund: `${kandidaten.length} Mitglieder heissen so` });
      continue;
    }
    const person = kandidaten[0];
    if (schonVergeben.has(person.id)) {
      offen.push({ ...e, grund: 'diese Person hat in der Liste schon eine Adresse' });
      continue;
    }
    schonVergeben.add(person.id);
    treffer.push({ person, adresse: e.adresse, ziel: e.ziel });
  }
  return { treffer, offen };
}
