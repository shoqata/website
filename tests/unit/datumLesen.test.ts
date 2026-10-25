import { describe, it, expect } from 'vitest';
import { datumLesen } from '../../lib/datumLesen';
describe('datumLesen', () => {
  it('Postgres-Text mit kurzem Versatz', () => expect(datumLesen('2026-10-13 14:23:40+00')?.toISOString()).toBe('2026-10-13T14:23:40.000Z'));
  it('ISO und Datum', () => { expect(datumLesen('2019-07-05T00:00:00+00:00')?.getUTCFullYear()).toBe(2019); expect(datumLesen('2020-01-02')?.getUTCFullYear()).toBe(2020); });
  it('Unsinn ergibt null', () => { expect(datumLesen('abc')).toBeNull(); expect(datumLesen(null)).toBeNull(); });
});
