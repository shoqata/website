import { describe, it, expect, beforeEach } from 'vitest';
import { darfMessen, zustimmungSchluessel } from '../../lib/werbemessung';

const IDS = { metaPixel: '123456789', googleAds: 'AW-987654321' };

describe('Werbemessung: wann darf geladen werden', () => {
  it('lädt mit Zustimmung, Betreiberseite und IDs', () => {
    const e = darfMessen({ istPlattform: true, zustimmung: 'accepted', ...IDS });
    expect(e).toMatchObject({ meta: true, google: true });
  });

  it('lädt NICHTS auf einer Vereinsseite — auch mit Zustimmung und IDs', () => {
    // Die wichtigste Regel. Die Mitglieder von koretini.me haben sich
    // bei ihrem Verein angemeldet, nicht bei einer Werbeplattform.
    const e = darfMessen({ istPlattform: false, zustimmung: 'accepted', ...IDS });
    expect(e.meta).toBe(false);
    expect(e.google).toBe(false);
    expect(e.grund).toMatch(/Vereinsseite/);
  });

  it('lädt nichts, solange unbekannt ist, wem die Adresse gehört', () => {
    // Unbekannt ist nicht "ja". Sonst entscheidet der Zufall des ersten
    // Bildes, ob ein Vereinsbesucher gemessen wird.
    const e = darfMessen({ istPlattform: null, zustimmung: 'accepted', ...IDS });
    expect(e.meta).toBe(false);
    expect(e.grund).toMatch(/Noch nicht bekannt/);
  });

  it('lädt nichts ohne Zustimmung', () => {
    const e = darfMessen({ istPlattform: true, zustimmung: null, ...IDS });
    expect(e.meta).toBe(false);
    expect(e.grund).toMatch(/keine Zustimmung/);
  });

  it('lädt nichts bei Ablehnung', () => {
    // Bisher las die Antwort niemand — der Hinweis zeichnete sie
    // folgenlos auf. Wer ablehnt, bekommt jetzt wirklich nichts.
    const e = darfMessen({ istPlattform: true, zustimmung: 'declined', ...IDS });
    expect(e.meta).toBe(false);
    expect(e.google).toBe(false);
    expect(e.grund).toMatch(/abgelehnt/);
  });

  it('lädt nur das, wofür eine ID eingetragen ist', () => {
    const nurMeta = darfMessen({ istPlattform: true, zustimmung: 'accepted', metaPixel: '123' });
    expect(nurMeta).toMatchObject({ meta: true, google: false });
    const nurGoogle = darfMessen({ istPlattform: true, zustimmung: 'accepted', googleAds: 'AW-1' });
    expect(nurGoogle).toMatchObject({ meta: false, google: true });
  });

  it('lädt nichts ohne jede ID, und sagt das', () => {
    const e = darfMessen({ istPlattform: true, zustimmung: 'accepted' });
    expect(e.meta).toBe(false);
    expect(e.grund).toMatch(/Keine Pixel- oder Conversion-ID/);
  });

  it('zählt Leerzeichen nicht als ID', () => {
    // Eine leere Umgebungsvariable kommt als '' oder '  ' an, nicht als
    // undefined — mit || wäre '  ' eine gültige ID.
    const e = darfMessen({ istPlattform: true, zustimmung: 'accepted', metaPixel: '   ' });
    expect(e.meta).toBe(false);
  });

  it('nennt immer einen Grund', () => {
    for (const lage of [
      { istPlattform: true, zustimmung: 'accepted' as const, ...IDS },
      { istPlattform: false, zustimmung: 'accepted' as const, ...IDS },
      { istPlattform: true, zustimmung: null, ...IDS },
    ]) {
      expect(darfMessen(lage).grund.length).toBeGreaterThan(5);
    }
  });
});

describe('Zustimmungsschlüssel', () => {
  it('ist je Darstellung ein anderer — wie im Hinweis selbst', () => {
    expect(zustimmungSchluessel(true)).toBe('cookie-consent-unityhub');
    expect(zustimmungSchluessel(false)).toBe('cookie-consent-koretini');
  });
});

import { anfragePlan } from '../../lib/werbemessung';

describe('Wie eine Anfrage gemeldet wird', () => {
  it('meldet Meta als Standardereignis Lead', () => {
    expect(anfragePlan({ meta: true, google: false })).toEqual([{ ziel: 'meta', name: 'Lead' }]);
  });

  it('meldet Google MIT Label als echte Ads-Conversion', () => {
    // Genau so verlangt es Google Ads. Ein anderer Aufruf läuft ohne
    // Fehler durch und wird nirgends gezählt.
    expect(anfragePlan({ meta: false, google: true }, 'AW-123/abcDEF'))
      .toEqual([{ ziel: 'google', name: 'conversion', daten: { send_to: 'AW-123/abcDEF' } }]);
  });

  it('meldet Google OHNE Label als generate_lead — und nennt es so', () => {
    // Ohne Label ist es keine Ads-Conversion. Es wäre unredlich, den
    // Aufruf 'conversion' zu nennen und zu hoffen.
    expect(anfragePlan({ meta: false, google: true }))
      .toEqual([{ ziel: 'google', name: 'generate_lead' }]);
  });

  it('behandelt ein leeres Label wie keines', () => {
    expect(anfragePlan({ meta: false, google: true }, '   ')[0].name).toBe('generate_lead');
  });

  it('meldet nichts, wenn nichts geladen ist', () => {
    expect(anfragePlan({ meta: false, google: false }, 'AW-1/x')).toEqual([]);
  });

  it('meldet an beide, wenn beide geladen sind', () => {
    expect(anfragePlan({ meta: true, google: true }, 'AW-1/x').map(m => m.ziel))
      .toEqual(['meta', 'google']);
  });
});

import { zustimmungLesen, zustimmungSpeichern, ZUSTIMMUNG_VERSION } from '../../lib/werbemessung';

describe('Zustimmung: Fassung und Widerruf', () => {
  const k = zustimmungSchluessel(true);
  beforeEach(() => localStorage.clear());

  it('eine alte Antwort ohne Stand gilt als Fassung 1', () => {
    localStorage.setItem(k, 'accepted');
    expect(zustimmungLesen(true)).toBe(ZUSTIMMUNG_VERSION === 1 ? 'accepted' : null);
  });

  it('eine Antwort zu einer anderen Fassung gilt als keine', () => {
    localStorage.setItem(k, 'accepted');
    localStorage.setItem(k + '-stand', JSON.stringify({ wert: 'accepted', version: ZUSTIMMUNG_VERSION + 1, zeit: '' }));
    expect(zustimmungLesen(true)).toBeNull();
  });

  it('Speichern legt Fassung und Zeit ab', () => {
    zustimmungSpeichern(true, 'accepted');
    const stand = JSON.parse(localStorage.getItem(k + '-stand')!);
    expect(stand.version).toBe(ZUSTIMMUNG_VERSION);
    expect(stand.wert).toBe('accepted');
    expect(zustimmungLesen(true)).toBe('accepted');
  });

  it('nur Ablehnen nach Zustimmen ist ein Widerruf', () => {
    expect(zustimmungSpeichern(true, 'declined')).toBe(false);
    expect(zustimmungSpeichern(true, 'accepted')).toBe(false);
    expect(zustimmungSpeichern(true, 'declined')).toBe(true);
    expect(zustimmungLesen(true)).toBe('declined');
  });
});
