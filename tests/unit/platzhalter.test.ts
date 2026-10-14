import { describe, it, expect } from 'vitest';
import { offenePlatzhalter } from '../../lib/textbaustein';

describe('Offene Platzhalter finden', () => {
  it('findet keinen in einem fertigen Text', () => {
    expect(offenePlatzhalter('Guten Tag Adrian, Ihr Beitrag von CHF 120.')).toEqual([]);
  });

  it('findet die der Einladung, die der Rundbrief nicht liefert', () => {
    // Der echte Fall: EINLADUNG_GV aus dem Rundbrief verschickt. Ohne
    // diesen Hinweis liest das Mitglied woertlich "{{datum}}".
    const t = 'Ju ftojmë në Kuvendin e përgjithshëm 2026.\nData: {{datum}}\nVendi: {{ort}}\n{{traktanden}}';
    expect(offenePlatzhalter(t)).toEqual(['datum', 'ort', 'traktanden']);
  });

  it('nennt jeden nur einmal, auch bei mehrfachem Vorkommen', () => {
    expect(offenePlatzhalter('{{verein}} — {{verein}}')).toEqual(['verein']);
  });

  it('sucht in Betreff und Text zusammen', () => {
    expect(offenePlatzhalter('Beitrag {{jahr}}', 'Hallo {{name}}')).toEqual(['jahr', 'name']);
  });

  it('erkennt Glossarbegriffe, die nicht aufgeloest wurden', () => {
    // Ein fehlender Glossareintrag bleibt genauso stehen wie ein
    // fehlender Wert -- und muss genauso auffallen.
    expect(offenePlatzhalter('die {{begriff.NACHBARSCHAFT}} meldet')).toEqual(['begriff.NACHBARSCHAFT']);
  });

  it('vertraegt Leerzeichen in den Klammern', () => {
    expect(offenePlatzhalter('{{ betrag }}')).toEqual(['betrag']);
  });

  it('vertraegt leere Eingaben', () => {
    expect(offenePlatzhalter(null, undefined, '')).toEqual([]);
  });
});
