import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { createRoot } from 'react-dom/client';
import { act } from 'react';

// Der Jahresvergleich rechnet, was er anzeigt, selbst. Darum hier mit Zahlen,
// deren Ergebnis von Hand feststeht -- nicht nur "baut sich auf".

const spende = { status: 'BEZAHLT', betrag: 100, eingegangen_am: '2026-03-01' };
vi.mock('../../services/supabase-bridge', () => ({
  db: {}, collection: () => ({}),
  onSnapshot: (_q: any, cb: any) => { cb({ docs: [{ data: () => spende }] }); return () => {}; },
}));
vi.mock('../../context/LanguageContext', () => ({
  useTranslation: () => ({ t: (k: string) => k }),
}));

const r = (id: string, userId: string, jahr: number, amount: number, status: string) =>
  ({ id, userId, billingYear: jahr, amount, status, type: 'FEE', currency: 'CHF', method: 'QR_BILL' });

const payments = [
  r('a', 'u1', 2025, 50, 'PAID'), r('b', 'u2', 2025, 50, 'PAID'),
  r('c', 'u3', 2025, 50, 'OVERDUE'), r('d', 'u4', 2025, 50, 'CANCELLED'),
  r('e', 'u1', 2026, 60, 'PAID'), r('f', 'u2', 2026, 60, 'SENT'),
  r('g', 'u3', 2026, 60, 'WRITTEN_OFF'), r('h', 'u5', 2026, 60, 'DRAFT'),
];
const users = [
  { id: 'u1', neighborhoodId: 'n1', joinedAt: '2025-02-01' },
  { id: 'u2', neighborhoodId: 'n1', joinedAt: '2026-01-15' },
  { id: 'u3', neighborhoodId: 'n2', joinedAt: '2020-01-01' },
];
const neighborhoods = [{ id: 'n1', name: 'Lindenquartier' }, { id: 'n2', name: 'Talacker' }];

describe('Jahresvergleich', () => {
  it('stellt die Jahre richtig nebeneinander', async () => {
    const { default: J } = await import('../../components/AdminJahresvergleich');
    const ort = document.createElement('div');
    document.body.appendChild(ort);
    const wurzel = createRoot(ort);
    await act(async () => { wurzel.render(<J users={users as any} payments={payments as any} neighborhoods={neighborhoods as any} />); });

    const zeile = (k: string) =>
      [...ort.querySelectorAll('tr')].find(tr => tr.querySelector('td')?.textContent === k)!
        .querySelectorAll('td');
    const werte = (k: string) => [...zeile(k)].slice(1).map(td => td.firstElementChild?.textContent ?? td.textContent);

    // Storno und Entwurf zaehlen nicht; u4 und u5 fehlen deshalb.
    expect(werte('jv.mitglieder')).toEqual(['3', '3']);
    expect(werte('jv.bezahlt')).toEqual(['2', '1']);
    expect(werte('jv.quote')).toEqual(['66.7 %', '33.3 %']);
    expect(werte('jv.gestellt')).toEqual(['150', '180']);
    expect(werte('jv.eingegangen')).toEqual(['100', '60']);
    expect(werte('jv.offen')).toEqual(['50', '60']);
    expect(werte('jv.abgeschrieben')).toEqual(['0', '60']);
    expect(werte('jv.eintritte')).toEqual(['1', '1']);
    expect(werte('jv.spenden')).toEqual(['0', '100']);

    // Quote in Prozentpunkten, und ein Rueckgang ist rot.
    const quote2026 = zeile('jv.quote')[2];
    expect(quote2026.textContent).toContain('−33.3 Pkt.');
    expect(quote2026.querySelector('.text-rose-500')).not.toBeNull();
    // Mehr Offenes ist schlecht, auch wenn die Zahl steigt.
    expect(zeile('jv.offen')[2].querySelector('.text-rose-500')).not.toBeNull();

    // Nachbarschaft: Lindenquartier 2/2 bezahlt, dann 1/2.
    const nb = [...ort.querySelectorAll('tr')].find(tr => tr.textContent?.startsWith('Lindenquartier'))!;
    expect([...nb.querySelectorAll('td')].slice(1).map(td => td.textContent)).toEqual(['100 %', '50 %']);
    wurzel.unmount();
  });
});
