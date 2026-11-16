import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { createRoot } from 'react-dom/client';
import { act } from 'react';
import { FeedbackProvider, useFeedback } from '../../context/FeedbackContext';

// Erfolg ist kein Sackgassen-Dialog: Umkehrbares meldet sich als Toast mit
// "Rueckgaengig", Wichtiges sagt konkret, was geschah, und bietet genau
// einen naechsten Schritt.

let fb: ReturnType<typeof useFeedback>;
const Fang = () => { fb = useFeedback(); return null; };

const aufbauen = async () => {
  const el = document.createElement('div');
  document.body.appendChild(el);
  await act(async () => { createRoot(el).render(<FeedbackProvider><Fang /></FeedbackProvider>); });
  return el;
};

describe('Rueckmeldung', () => {
  it('Toast: Rueckgaengig ruft die Umkehr auf und schliesst', async () => {
    await aufbauen();
    const undo = vi.fn();
    await act(async () => { fb.showToast({ message: 'Anna: CHF 120.00 als bezahlt gebucht.', undo, undoLabel: 'Rückgängig' }); });
    const knopf = [...document.querySelectorAll('button')].find(b => b.textContent === 'Rückgängig')!;
    expect(document.body.textContent).toContain('CHF 120.00');
    await act(async () => { knopf.click(); });
    expect(undo).toHaveBeenCalledTimes(1);
  });

  it('Meldung zeigt Details und den naechsten Schritt', async () => {
    await aufbauen();
    const ansehen = vi.fn();
    await act(async () => { void fb.showAlert({ type: 'success', title: 'Rechnung an Anna verschickt', message: 'unterwegs',
      details: [{ label: 'Betrag', value: 'CHF 120.00' }, { label: 'An', value: 'anna@example.org' }],
      action: { label: 'Rechnung ansehen', onClick: ansehen }, buttonText: 'Zurück zur Liste' }); });
    expect(document.body.textContent).toContain('anna@example.org');
    expect(document.body.textContent).toContain('Zurück zur Liste');
    const knopf = [...document.querySelectorAll('button')].find(b => b.textContent === 'Rechnung ansehen')!;
    await act(async () => { knopf.click(); });
    expect(ansehen).toHaveBeenCalledTimes(1);
  });
});
