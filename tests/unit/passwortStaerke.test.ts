import { describe, it, expect } from 'vitest';
import { bewertePasswort, enthaeltNaheliegendes, MINDESTLAENGE } from '../../lib/passwortStaerke';

describe('bewertePasswort', () => {
  it('weist alles unter der Mindestlaenge ab', () => {
    expect(bewertePasswort('Kurz1!').genuegt).toBe(false);
    expect(bewertePasswort('Kurz1!').staerke).toBe('ZU_KURZ');
    expect(MINDESTLAENGE).toBe(10);
  });

  it('weist ab, was jede uebliche Regel erfuellt und trotzdem schlecht ist', () => {
    // Gross, klein, Ziffer, Sonderzeichen, lang genug -- und in Sekunden
    // geraten. Genau der Fall, den eine reine Zeichenklassenregel durchlaesst.
    const b = bewertePasswort('Passwort1!');
    expect(b.genuegt).toBe(false);
    expect(b.hinweise).toContain('pw.rule_common');
  });

  it('laesst eine lange Wortfolge ohne Sonderzeichen zu', () => {
    // Keine Sonderzeichen, aber um Groessenordnungen besser als das obige.
    const b = bewertePasswort('vier ruhige braune Pferde');
    expect(b.genuegt).toBe(true);
    expect(['GUT', 'STARK']).toContain(b.staerke);
  });

  it('erkennt den eigenen Namen und die eigene Adresse im Passwort', () => {
    const b = bewertePasswort('Dervishi2026x', ['Burim Dervishi', 'burim@dervishi.ch']);
    expect(b.genuegt).toBe(false);
    expect(b.hinweise).toContain('pw.rule_personal');
  });

  it('erkennt Tastaturfolgen und Wiederholungen', () => {
    expect(bewertePasswort('abcdefghij').hinweise).toContain('pw.rule_pattern');
    expect(bewertePasswort('Haaaallo123').hinweise).toContain('pw.rule_pattern');
  });

  it('erkennt Naheliegendes aus dieser Umgebung', () => {
    expect(enthaeltNaheliegendes('koretini2026')).toBe('koretini');
    expect(enthaeltNaheliegendes('meinFjalekalimi')).toBe('fjalekalimi');
    expect(enthaeltNaheliegendes('Quergedacht7!')).toBeNull();
  });

  it('nimmt ein solides Passwort an', () => {
    const b = bewertePasswort('Quergedacht7!Ufer');
    expect(b.genuegt).toBe(true);
    expect(b.balken).toBeGreaterThanOrEqual(3);
  });

  it('haelt eine leere Eingabe aus', () => {
    const b = bewertePasswort('');
    expect(b.genuegt).toBe(false);
    expect(b.balken).toBe(0);
  });

  it('bewertet das erzeugte Einmalpasswort als brauchbar', () => {
    // So sehen die Passwoerter aus, die reset_member_password vergibt --
    // 14 Stellen, Gross, Klein, Ziffern. Wuerde die Regel sie abweisen,
    // waere sie mit der eigenen Anwendung im Widerspruch.
    const b = bewertePasswort('BhLJ6qdSHVRLxg');
    expect(b.genuegt).toBe(true);
  });
});
