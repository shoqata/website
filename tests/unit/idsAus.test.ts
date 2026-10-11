import { describe, it, expect } from 'vitest';
import { idsAus } from '../../services/supabase-bridge';

// Dieser Test haette drei Runden Suche erspart.
//
// my_neighborhoods() gibt TABLE(id text) zurueck, PostgREST liefert also
// [{ id: "..." }]. Die Bruecke las z.my_neighborhoods -- den
// FUNKTIONSnamen -- und das anschliessende filter(Boolean) warf alles
// weg. Ergebnis: im Browser immer ein leeres Array.
//
// Sichtbar war davon nur die Wirkung, und die sah nach etwas anderem
// aus: kein Zugang zur Betreuungsmaske auf dem Dashboard, ein Klick auf
// einen Nachbarn, der nichts tut, und die Meldung "Sie sind für diese
// Nachbarschaft nicht als Kontaktperson hinterlegt" bei jemandem, der
// es nachweislich war. Gesucht habe ich zweimal in den Zugriffsregeln,
// wo alles stimmte.
//
// Die Lehre steckt in der Form des Tests: geprueft wird nicht EINE
// Antwortform, sondern jede, die vorkommen kann. Die alte Fassung war
// nicht etwa unvollstaendig -- sie hat auf eine Form gesetzt, die
// PostgREST nie liefert.

describe('idsAus', () => {
  it('nimmt die echte Form von PostgREST: Objekte mit id', () => {
    expect(idsAus([{ id: 'nb1' }, { id: 'nb2' }])).toEqual(['nb1', 'nb2']);
  });

  it('nimmt blosse Zeichenketten', () => {
    expect(idsAus(['nb1', 'nb2'])).toEqual(['nb1', 'nb2']);
  });

  it('nimmt ein Objekt mit anders benanntem Feld', () => {
    // Genau der Fall, an dem die alte Fassung scheiterte -- nur
    // umgekehrt: sie erwartete den Funktionsnamen und bekam "id".
    expect(idsAus([{ my_neighborhoods: 'nb1' }])).toEqual(['nb1']);
    expect(idsAus([{ irgendwas: 'nb1' }])).toEqual(['nb1']);
  });

  it('nimmt eine einzelne Antwort ohne Array', () => {
    expect(idsAus({ id: 'nb1' })).toEqual(['nb1']);
    expect(idsAus('nb1')).toEqual(['nb1']);
  });

  it('null und leer ergeben eine leere Liste, keinen Fehler', () => {
    expect(idsAus(null)).toEqual([]);
    expect(idsAus(undefined)).toEqual([]);
    expect(idsAus([])).toEqual([]);
  });

  it('wirft leere und unbrauchbare Werte weg', () => {
    expect(idsAus([{ id: '' }, { id: '   ' }, { id: 'nb1' }])).toEqual(['nb1']);
    expect(idsAus([null, 42, { id: null }, 'nb2'])).toEqual(['nb2']);
  });

  it('id gewinnt gegen andere Zeichenkettenfelder', () => {
    // Bei TABLE(id text, name text) soll die Kennung kommen, nicht der
    // Name -- sonst filtert die Betreuungsmaske nach Anzeigetexten.
    expect(idsAus([{ name: 'Selmana-jt', id: 'nb1' }])).toEqual(['nb1']);
  });
});
