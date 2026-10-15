import { describe, it, expect } from 'vitest';
import {
  empfaengerAufbereiten, absenderPruefen, weiterleitungenLesen,
} from '../../lib/vorstandsmail';

const M = (id: string, email: any, mehr: any = {}) =>
  ({ id, displayName: id, email, ...mehr }) as any;

describe('Empfänger aufbereiten', () => {
  it('trennt erreichbar von ohne Adresse', () => {
    const a = empfaengerAufbereiten([M('a', 'a@x.ch'), M('b', ''), M('c', 'c@y.ch')]);
    expect(a.erreichbar.map(e => e.id)).toEqual(['a', 'c']);
    expect(a.ohne_adresse.map(e => e.id)).toEqual(['b']);
  });

  it('verschweigt die ohne Adresse nicht', () => {
    // Der Punkt der ganzen Funktion: 56 von 353 haben keine Adresse.
    // Ein Lauf, der sie still ueberspringt und "verschickt" meldet, ist
    // eine Falschmeldung.
    const a = empfaengerAufbereiten([M('a', 'a@x.ch'), M('b', null)]);
    expect(a.ohne_adresse).toHaveLength(1);
  });

  it('achtet die Auswahl', () => {
    const a = empfaengerAufbereiten(
      [M('a', 'a@x.ch'), M('b', 'b@x.ch'), M('c', 'c@x.ch')], ['a', 'c']);
    expect(a.erreichbar.map(e => e.id)).toEqual(['a', 'c']);
  });

  it('nimmt Ausgetretene auch bei "alle" nicht mit', () => {
    const a = empfaengerAufbereiten([
      M('a', 'a@x.ch'), M('weg', 'weg@x.ch', { membershipStatus: 'INACTIVE' })]);
    expect(a.erreichbar.map(e => e.id)).toEqual(['a']);
    expect(a.ohne_adresse).toHaveLength(0);
  });

  it('lehnt Platzhalteradressen ab', () => {
    // Eine Adresse, die niemandem gehoert, ist schlimmer als keine: sie
    // erzeugt eine Rueckweisung und laesst den Lauf gelungen aussehen.
    const a = empfaengerAufbereiten([
      M('a', 'keine@koretini.me'), M('b', 'x@example.com'), M('c', 'echt@gmx.ch')]);
    expect(a.erreichbar.map(e => e.id)).toEqual(['c']);
  });

  it('lehnt eine Adresse ohne Punkt in der Domain ab', () => {
    expect(empfaengerAufbereiten([M('a', 'a@localhost')]).erreichbar).toHaveLength(0);
  });

  it('nimmt die Sprache mit, damit zweisprachig geschrieben werden kann', () => {
    const a = empfaengerAufbereiten([M('a', 'a@x.ch', { sprache: 'sq' })]);
    expect(a.erreichbar[0].sprache).toBe('sq');
  });
});

describe('Absenderadresse prüfen', () => {
  const D = ['koretini.me', 'www.koretini.me'];

  it('nimmt eine Adresse auf der Vereinsdomain', () => {
    expect(absenderPruefen('valton.rexha@koretini.me', D).ok).toBe(true);
  });

  it('nimmt die blanke Domain, obwohl nur www registriert ist', () => {
    // Der echte Fall bei Koretini: in tenant_domains steht
    // www.koretini.me, die Postfaecher liegen auf koretini.me. Ohne
    // diese Normalisierung waere jede Vorstandsadresse abgelehnt.
    expect(absenderPruefen('sokol.axhija@koretini.me', ['www.koretini.me']).ok).toBe(true);
  });

  it('lehnt eine Maildomain mit www ab', () => {
    // Maildomains tragen kein www. x@www.verein.ch ist falsch, nicht
    // gleichwertig -- und eine falsche Absenderadresse heisst, dass die
    // Antwort des Mitglieds nirgends ankommt.
    expect(absenderPruefen('sokol.axhija@www.koretini.me', D).ok).toBe(false);
  });

  it('lehnt eine fremde Domain ab', () => {
    // Der Kern: liesse man das zu, waere die Maske ein Werkzeug, um
    // unter fremdem Namen zu schreiben -- und die Antwort ginge an den
    // Fremden.
    const z = absenderPruefen('valton.rexha@gmail.com', D);
    expect(z.ok).toBe(false);
    expect(z.grund).toMatch(/gehört nicht zum Verein/);
  });

  it('lehnt eine Unterdomain ab', () => {
    expect(absenderPruefen('x@mail.koretini.me', D).ok).toBe(false);
  });

  it('lehnt Unfug ab', () => {
    expect(absenderPruefen('kein-at-zeichen', D).ok).toBe(false);
    expect(absenderPruefen('', D).ok).toBe(false);
  });

  it('lehnt ab, wenn der Verein keine Domain hat', () => {
    expect(absenderPruefen('x@koretini.me', []).ok).toBe(false);
  });
});

describe('Weiterleitungsliste lesen', () => {
  const liste = `valton.rexha@koretini.me -> valton.rexha@gmail.com
sokol.axhija@koretini.me -> axhija.sokol@gmail.com
gazmend.mehmeti@koretini.me ->gazmend.mehmeti@multinetcom.ch
ismet.klaiqi@koretini.me ->Ismetklaiqi6@gmail.com
bajram.shillova@koretini.me -> shillovabajram@gmail.com`;

  it('liest alle fünf, auch ohne Leerzeichen vor dem Ziel', () => {
    const { eintraege, unklar } = weiterleitungenLesen(liste);
    expect(eintraege).toHaveLength(5);
    expect(unklar).toEqual([]);
  });

  it('behält die Schreibweise des Ziels', () => {
    // Ismetklaiqi6@gmail.com ist so gemeldet. Der lokale Teil einer
    // Adresse DARF Gross- und Kleinschreibung unterscheiden -- ihn
    // kleinzuschreiben waere eine stille Aenderung an einer Adresse.
    const { eintraege } = weiterleitungenLesen(liste);
    expect(eintraege[3].ziel).toBe('Ismetklaiqi6@gmail.com');
  });

  it('schreibt die Vereinsadresse klein', () => {
    const { eintraege } = weiterleitungenLesen('Valton.Rexha@Koretini.me -> a@b.ch');
    expect(eintraege[0].adresse).toBe('valton.rexha@koretini.me');
  });

  it('versteht →, => und >', () => {
    const { eintraege } = weiterleitungenLesen('a@x.ch → b@y.ch\nc@x.ch => d@y.ch\ne@x.ch > f@y.ch');
    expect(eintraege).toHaveLength(3);
  });

  it('meldet eine unklare Zeile statt sie zu verwerfen', () => {
    // Eine stillschweigend verworfene Zeile heisst: diese Person
    // bekommt keine Post, und niemand weiss es.
    const { eintraege, unklar } = weiterleitungenLesen('a@x.ch -> b@y.ch\nirgendwas');
    expect(eintraege).toHaveLength(1);
    expect(unklar).toEqual(['irgendwas']);
  });

  it('meldet eine doppelte Vereinsadresse', () => {
    const { eintraege, unklar } = weiterleitungenLesen('a@x.ch -> b@y.ch\na@x.ch -> c@y.ch');
    expect(eintraege).toHaveLength(1);
    expect(unklar[0]).toMatch(/doppelt/);
  });

  it('verträgt leeren Text', () => {
    expect(weiterleitungenLesen('').eintraege).toEqual([]);
    expect(weiterleitungenLesen(null).unklar).toEqual([]);
  });
});

import { namensschluessel, zuordnen } from '../../lib/vorstandsmail';

describe('Zuordnung der Liste zu den Personen', () => {
  const personen = [
    { id: 'u1', name: 'Valton Rexha' },
    { id: 'u2', name: 'Sokol Axhija' },
    { id: 'u3', name: 'Gazmend Mehmeti' },
    { id: 'u4', name: 'Ismet Klaiqi' },
    { id: 'u5', name: 'Bajram Shillova' },
  ];
  const liste = [
    { adresse: 'valton.rexha@koretini.me', ziel: 'valton.rexha@gmail.com' },
    { adresse: 'sokol.axhija@koretini.me', ziel: 'axhija.sokol@gmail.com' },
    { adresse: 'gazmend.mehmeti@koretini.me', ziel: 'gazmend.mehmeti@multinetcom.ch' },
    { adresse: 'ismet.klaiqi@koretini.me', ziel: 'Ismetklaiqi6@gmail.com' },
    { adresse: 'bajram.shillova@koretini.me', ziel: 'shillovabajram@gmail.com' },
  ];

  it('ordnet alle fünf richtig zu', () => {
    const z = zuordnen(liste, personen);
    expect(z.offen).toEqual([]);
    expect(z.treffer.map(x => x.person.id)).toEqual(['u1', 'u2', 'u3', 'u4', 'u5']);
  });

  it('ist unabhängig von der Reihenfolge der Namensteile', () => {
    // In den Daten steht nicht verlaesslich Vorname zuerst.
    expect(namensschluessel('Valton Rexha')).toBe(namensschluessel('Rexha Valton'));
    const z = zuordnen([liste[0]], [{ id: 'u1', name: 'Rexha Valton' }]);
    expect(z.treffer).toHaveLength(1);
  });

  it('verträgt albanische Zeichen', () => {
    const z = zuordnen([{ adresse: 'arber.krasniqi@koretini.me', ziel: 'a@b.ch' }],
                       [{ id: 'x', name: 'Arbër Krasniqi' }]);
    expect(z.treffer).toHaveLength(1);
  });

  it('ordnet NICHT zu, wenn zwei gleich heissen', () => {
    // Der Kern: raten heisst hier, die Post des einen dem anderen zu
    // geben. Lieber offen melden.
    const z = zuordnen([liste[2]], [
      { id: 'a', name: 'Gazmend Mehmeti' }, { id: 'b', name: 'Gazmend Mehmeti' }]);
    expect(z.treffer).toEqual([]);
    expect(z.offen[0].grund).toMatch(/2 Mitglieder/);
  });

  it('meldet einen Namen, den es nicht gibt', () => {
    const z = zuordnen([{ adresse: 'niemand.hier@koretini.me', ziel: 'a@b.ch' }], personen);
    expect(z.offen[0].grund).toMatch(/kein Mitglied/);
  });

  it('gibt einer Person nicht zwei Adressen', () => {
    const z = zuordnen([liste[0], { adresse: 'valton.rexha@koretini.me', ziel: 'x@y.ch' }],
                       personen);
    // Die zweite ist schon beim Lesen als Dublette gefallen; hier zählt
    // der Fall, dass zwei verschiedene Adressen auf eine Person zeigen.
    expect(z.treffer).toHaveLength(1);
  });

  it('verträgt leere Eingaben', () => {
    expect(zuordnen(null, personen).treffer).toEqual([]);
    expect(zuordnen(liste, null).offen).toHaveLength(5);
  });
});
