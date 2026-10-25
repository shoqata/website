import { describe, it, expect } from 'vitest';
import { anlassIcs } from '../../lib/kalender';

describe('anlassIcs', () => {
  it('mit Uhrzeit: zwei Stunden', () => {
    const s = anlassIcs({ id: 'a1', title: 'Sommerfest, 2026', date: '2026-07-04', time: '18:30', location: 'Vaduz' });
    expect(s).toContain('DTSTART:20260704T183000');
    expect(s).toContain('DTEND:20260704T203000');
    expect(s).toContain('SUMMARY:Sommerfest\\, 2026');
  });
  it('ohne Uhrzeit: ganztaegig, Ende am Folgetag (auch Monatsende)', () => {
    const s = anlassIcs({ id: 'a2', title: 'GV', date: '2026-10-31' });
    expect(s).toContain('DTSTART;VALUE=DATE:20261031');
    expect(s).toContain('DTEND;VALUE=DATE:20261101');
  });
});
