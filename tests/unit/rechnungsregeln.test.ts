import { describe, it, expect } from 'vitest';
import { postTauglich, wohnsitz, waehrungFuer, waehrungStimmt, paypalLink } from '../../lib/rechnungsregeln';

const ch = { name: 'Arta Demaj', adresse: 'Weidgartenstrasse 8', plz: '8909', ort: 'Zwillikon', land: 'Schweiz' };

describe('Postversand nur in die Schweiz, nur vollstaendig', () => {
  it('vollstaendige Schweizer Adresse geht', () => {
    expect(postTauglich(ch).ok).toBe(true);
    expect(postTauglich({ ...ch, land: 'Switzerland' }).ok).toBe(true);
    expect(postTauglich({ ...ch, land: 'CH' }).ok).toBe(true);
  });
  // Der gemessene Fall: Wels, Oesterreich, vierstellige PLZ -- ging zu Pingen.
  it('Oesterreich mit vierstelliger PLZ geht nicht', () => {
    const r = postTauglich({ ...ch, plz: '4600', ort: 'Wels', land: 'Österreich' });
    expect(r.ok).toBe(false);
    expect(!r.ok && r.grund).toBe('AUSLAND');
  });
  it('ohne Land geht nicht, auch wenn die PLZ schweizerisch aussieht', () => {
    const r = postTauglich({ ...ch, land: '' });
    expect(!r.ok && r.grund).toBe('LAND_FEHLT');
  });
  it('fehlende Zeilen werden benannt', () => {
    expect((postTauglich({ ...ch, name: ' ' }) as any).grund).toBe('NAME');
    expect((postTauglich({ ...ch, adresse: '12' }) as any).grund).toBe('STRASSE');
    expect((postTauglich({ ...ch, plz: '89090' }) as any).grund).toBe('PLZ');
    expect((postTauglich({ ...ch, plz: '0123' }) as any).grund).toBe('PLZ');
    expect((postTauglich({ ...ch, ort: '' }) as any).grund).toBe('ORT');
  });
});

describe('Waehrung nach Wohnsitz', () => {
  it('Ausland heisst EUR, Schweiz CHF, unbekannt wird nicht geraten', () => {
    expect(waehrungFuer('Deutschland')).toBe('EUR');
    expect(waehrungFuer('Belgien')).toBe('EUR');
    expect(waehrungFuer('Schweiz')).toBe('CHF');
    expect(waehrungFuer('')).toBeNull();
    expect(wohnsitz('Atlantis')).toBe('UNBEKANNT');
  });
  it('CHF ins Ausland ist falsch, bei unbekanntem Land kein Urteil', () => {
    expect(waehrungStimmt('Deutschland', 'CHF')).toBe(false);
    expect(waehrungStimmt('Deutschland', 'EUR')).toBe(true);
    expect(waehrungStimmt('', 'CHF')).toBe(true);
  });
});

describe('PayPal-Link', () => {
  it('traegt Betrag und Waehrung', () => {
    expect(paypalLink('koretini', 120, 'EUR')).toBe('https://paypal.me/koretini/120EUR');
    expect(paypalLink('https://paypal.me/koretini', 12.5, 'eur')).toBe('https://paypal.me/koretini/12.50EUR');
  });
  it('setzt nichts Fremdes in die Adresse', () => {
    expect(paypalLink('info@koretini.me', 120, 'EUR')).toBeNull();
    expect(paypalLink('a/../b', 120, 'EUR')).toBeNull();
    expect(paypalLink('koretini', 0, 'EUR')).toBeNull();
  });
});
