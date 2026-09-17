import { describe, it, expect } from 'vitest';
import { neighborhoodsLedBy, isSteward } from '../../lib/stewardship';

// Nachgebildet nach den echten Daten: Canaj-t hat Selami in contactPersonIds,
// vier Nachbarschaften tragen noch Platzhalter aus der Erstbefuellung.
const nachbarschaften = [
  { id: '2dfxYzVnwHgXPatyu34F', name: 'Canaj-t', contactPersonIds: ['51cgZtxNAIS11JdXa3MH'] },
  { id: 'lagjja-e-re', name: 'Lagjja e Re', representativeId: 'rep-user-1', contactPersonIds: [] },
  { id: 'diaspora-schweiz', name: 'Diaspora Zvicër', representativeId: 'board-member-1', contactPersonIds: [] },
  { id: 'Gw8s5lNhSTd54MqCjczI', name: 'Selmana-jt', managerId: 'w23ECDS4EWXcBxg4O73nT11pKLm1', contactPersonIds: [] },
  { id: 'JQM71uI7qbLu1WoLEgcq', name: 'Haxhia-jt', contactPersonIds: [] },
] as any[];

describe('neighborhoodsLedBy', () => {
  it('findet die Nachbarschaft ueber contactPersonIds', () => {
    const r = neighborhoodsLedBy('51cgZtxNAIS11JdXa3MH', nachbarschaften);
    expect(r.map(n => n.name)).toEqual(['Canaj-t']);
    expect(isSteward('51cgZtxNAIS11JdXa3MH', nachbarschaften)).toBe(true);
  });

  it('beruecksichtigt die beiden aelteren Felder', () => {
    expect(neighborhoodsLedBy('rep-user-1', nachbarschaften).map(n => n.name)).toEqual(['Lagjja e Re']);
    expect(neighborhoodsLedBy('w23ECDS4EWXcBxg4O73nT11pKLm1', nachbarschaften).map(n => n.name)).toEqual(['Selmana-jt']);
  });

  it('gibt ein gewoehnliches Mitglied nicht als verantwortlich aus', () => {
    expect(neighborhoodsLedBy('irgendwer', nachbarschaften)).toEqual([]);
    expect(isSteward('irgendwer', nachbarschaften)).toBe(false);
  });

  it('kommt mit mehreren Nachbarschaften derselben Person zurecht', () => {
    const mehrere = [
      ...nachbarschaften,
      { id: 'x', name: 'Zweite', contactPersonIds: ['51cgZtxNAIS11JdXa3MH'] },
    ] as any[];
    expect(neighborhoodsLedBy('51cgZtxNAIS11JdXa3MH', mehrere).map(n => n.name)).toEqual(['Canaj-t', 'Zweite']);
  });

  it('haelt fehlende Angaben aus, statt zu scheitern', () => {
    expect(neighborhoodsLedBy(undefined, nachbarschaften)).toEqual([]);
    expect(neighborhoodsLedBy('51cgZtxNAIS11JdXa3MH', null)).toEqual([]);
    expect(neighborhoodsLedBy('a', [{ id: 'y', name: 'Ohne Liste' } as any])).toEqual([]);
  });
});
