import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { createRoot } from 'react-dom/client';
import { act } from 'react';

// Rauchtest: die Finanzseite baut sich auf, ohne abzubrechen.
//
// Am 24.10.2026 brach sie beim Oeffnen ab ("Diese Seite konnte nicht
// geladen werden"): eine Hilfsfunktion war als Konstante HINTER der Liste
// definiert, die sie beim ersten Aufbau schon brauchte. Typpruefung und
// Build sehen das nicht -- nur ein Aufbau.

const leer = { docs: [], exists: () => false, data: () => ({}) };
// Mit leeren Listen laeuft der Fehler nicht auf -- die Filter rufen ihre
// Pruefung erst fuer eine vorhandene Rechnung auf. Darum eine Rechnung.
const rechnung = {
  id: 'p1', userId: 'u1', amount: 50, currency: 'CHF', status: 'PENDING', type: 'FEE',
  billingYear: 2026, deliveryMethod: 'BOTH', method: 'QR_BILL', invoiceNumber: 'INV-1',
  timestamp: { toDate: () => new Date('2026-01-10') },
};
const mitRechnung = { docs: [{ id: 'p1', data: () => rechnung }], exists: () => true, data: () => ({}) };
vi.mock('@/services/supabase-bridge', () => {
  const kette: any = new Proxy(() => kette, {
    get: (_t, k) => (k === 'then' ? (ok: any) => Promise.resolve({ data: [], error: null }).then(ok) : kette),
    apply: () => kette,
  });
  return {
    supabase: { rpc: () => Promise.resolve({ data: null, error: null }), from: () => kette,
                functions: { invoke: () => Promise.resolve({ data: null, error: null }) } },
    collection: () => ({}), query: () => ({}), orderBy: () => ({}), where: () => ({}),
    onSnapshot: (_q: any, cb: any) => { cb(mitRechnung); return () => {}; },
    doc: () => ({ id: 'x' }), getDoc: () => Promise.resolve(leer), getDocs: () => Promise.resolve(leer),
    addDoc: vi.fn(), setDoc: vi.fn(), updateDoc: vi.fn(), deleteDoc: vi.fn(),
    writeBatch: () => ({ set: vi.fn(), commit: vi.fn() }), serverTimestamp: () => null,
    markPaymentPaid: vi.fn(), zahlungDifferenzSetzen: vi.fn(),
  };
});
vi.mock('../../services/datenzugriff', () => ({ db: {} }));
vi.mock('../../context/FeedbackContext', () => ({
  useFeedback: () => ({ showAlert: vi.fn(), showConfirm: vi.fn(), showPrompt: vi.fn() }),
}));
vi.mock('../../context/LanguageContext', () => ({
  useTranslation: () => ({ t: (k: string) => k, loc: (v: any) => (typeof v === 'string' ? v : ''), language: 'de' }),
}));

describe('AdminFinance', () => {
  it('baut sich auf, ohne abzubrechen', async () => {
    const { default: AdminFinance } = await import('../../components/AdminFinance');
    const fehler: any[] = [];
    const spion = vi.spyOn(console, 'error').mockImplementation((...a: any[]) => { fehler.push(a); });
    const ort = document.createElement('div');
    document.body.appendChild(ort);
    const wurzel = createRoot(ort, { onUncaughtError: (e: any) => fehler.push(['uncaught', e]) } as any);
    await act(async () => { wurzel.render(<AdminFinance {...({ viewMode: 'OVERVIEW', selectedYear: 2026 } as any)} />); });
    spion.mockRestore();
    const abbrueche = fehler.filter(f => f[0] === 'uncaught' || String(f[0]).includes('ReferenceError') || f.some((x: any) => x instanceof ReferenceError));
    expect(abbrueche.map(f => String(f[1]?.message || f[0]))).toEqual([]);
    expect(ort.innerHTML.length).toBeGreaterThan(0);
    wurzel.unmount();
  });
});
