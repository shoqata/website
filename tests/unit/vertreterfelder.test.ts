import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  VERTRETER_GRUPPEN, VERTRETER_FELD_KEYS, OHNE_EIGENES_FELD,
} from '../../lib/vertreterfelder';

// Der Fehler, den dieser Test verhindert, ist schon passiert.
//
// Der Verein hatte 18 Felder freigegeben, die Betreuungsmaske bot 11 an
// -- darunter fehlte der Name. Ein Verantwortlicher, der einen
// Schreibfehler im Nachnamen berichtigen wollte, fand kein Feld dafuer
// und hielt es fuer ein fehlendes Recht. Server, Zugriffsregel und
// Ausloeser waren in Ordnung; gemessen hat ein Schreibversuch in seinem
// Namen eine Zeile geaendert. Es fehlte die Maske.
//
// Die Richtung des Fehlers ist das Schlimmere: der Admin kreuzt ein Feld
// an, und nichts geschieht. Eine Einstellung ohne Wirkung ist schlechter
// als keine, weil sie behauptet, etwas geregelt zu haben.
//
// Darum liest dieser Test die Maske als Text und vergleicht sie mit dem
// Katalog. Das ist ungewoehnlich fuer einen Test -- aber die Alternative
// waere, die Maske zu rendern und 20 Felder durchzuklicken, und dieser
// Vergleich trifft genau die Eigenschaft, die gebrochen war.

const maske = readFileSync(
  join(__dirname, '../../components/NeighborhoodStewardPanel.tsx'), 'utf-8');

const bedingt = new Set(
  [...maske.matchAll(/erlaubt\.has\('(\w+)'\)/g)].map(m => m[1]));

describe('Vertreterrechte: Katalog und Maske', () => {
  it('jedes freigebbare Feld hat ein Eingabefeld in der Betreuungsmaske', () => {
    const fehlt = VERTRETER_FELD_KEYS
      .filter(k => !OHNE_EIGENES_FELD.includes(k))
      .filter(k => !bedingt.has(k));
    expect(fehlt).toEqual([]);
  });

  it('jedes Eingabefeld haengt an der Freigabe, keines ist unbedingt', () => {
    // Ohne das koennte ein Verantwortlicher etwas aendern, was die
    // Administration ihm nicht erlaubt hat -- der Ausloeser in der
    // Datenbank weist es dann zurueck, und der ganze Vorgang scheitert,
    // auch die erlaubten Felder.
    for (const k of VERTRETER_FELD_KEYS) {
      if (OHNE_EIGENES_FELD.includes(k)) continue;
      expect(bedingt.has(k), `${k} ist nicht an erlaubt.has gebunden`).toBe(true);
    }
  });

  it('der Speicherweg schickt genau die Katalogfelder', () => {
    const abschnitt = maske.slice(maske.indexOf('const zuSchicken'));
    const geschickt = new Set(
      [...abschnitt.slice(0, 2600).matchAll(/^\s{8}(\w+):/gm)].map(m => m[1]));
    const fehlt = VERTRETER_FELD_KEYS.filter(k => !geschickt.has(k));
    expect(fehlt).toEqual([]);
  });

  it('kein Feld doppelt im Katalog', () => {
    // Zwei Gruppen mit demselben Schluessel ergeben zwei Haekchen fuer
    // eine Sache -- und eines davon zeigt dann den falschen Stand.
    expect(VERTRETER_FELD_KEYS.length).toBe(new Set(VERTRETER_FELD_KEYS).size);
  });

  it('die gesperrten Felder stehen nicht im Katalog', () => {
    // Rolle, Nachbarschaft und Mitgliedsstatus. Wer sich selbst
    // befoerdern oder Mitglieder in die eigene Lagje ziehen kann,
    // pflegt keine Daten mehr, sondern erweitert seine Zustaendigkeit.
    for (const gesperrt of ['role', 'neighborhoodId', 'membershipStatus',
                            'id', 'tenantId', 'authUserId']) {
      expect(VERTRETER_FELD_KEYS).not.toContain(gesperrt);
    }
  });

  it('jede Gruppe hat einen Titel und mindestens ein Feld', () => {
    for (const g of VERTRETER_GRUPPEN) {
      expect(g.titel.trim().length).toBeGreaterThan(0);
      expect(g.felder.length).toBeGreaterThan(0);
    }
  });

  it('die Maske meldet keinen Erfolg, wenn nichts freigegeben ist', () => {
    // Vorher ergab eine leere Freigabeliste ein updateDoc({}), das ohne
    // Fehler durchlief: "gespeichert", und geaendert war nichts.
    expect(maske).toMatch(/Object\.keys\(zuSchicken\)\.length === 0/);
    const stelle = maske.indexOf('Object.keys(zuSchicken).length === 0');
    const danach = maske.slice(stelle, stelle + 300);
    expect(danach).toContain('nothing_allowed');
    expect(danach).toContain('return');
  });
});
