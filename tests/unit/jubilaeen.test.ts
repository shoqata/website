import { describe, it, expect } from 'vitest';
import { anstehend } from '../../lib/jubilaeen';

describe('anstehend', () => {
  const heute = new Date(2026, 11, 29); // 29.12.2026
  it('Geburtstag ueber den Jahreswechsel, Alter richtig', () => {
    const a = anstehend([{ id: 'a', displayName: 'A', birthdate: '1980-01-02' }], heute);
    expect(a).toHaveLength(1);
    expect(a[0].jahre).toBe(47);
    expect(a[0].datum.getFullYear()).toBe(2027);
  });
  it('nur runde Jubilaeen, Ausgetretene nicht', () => {
    const a = anstehend([
      { id: 'b', displayName: 'B', joinedAt: '2016-12-30T00:00:00Z' },
      { id: 'c', displayName: 'C', joinedAt: '2017-12-30T00:00:00Z' },
      { id: 'd', displayName: 'D', birthdate: '1990-12-30', membershipStatus: 'INACTIVE' },
    ], heute);
    expect(a.map(x => x.id)).toEqual(['b']);
    expect(a[0].jahre).toBe(10);
  });
});
