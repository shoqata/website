import { supabase } from '@/services/supabase-bridge';

// Textbausteine und Glossar beim Schreiben anwenden.
//
// Drei Dinge passieren hier, und jedes hat einen Grund:
//
// 1. PLATZHALTER. {{betrag}} wird ersetzt, {{unbekannt}} bleibt stehen.
//    Einen unbekannten Platzhalter still zu loeschen waere schlimmer:
//    dann steht im Brief eine Luecke, die niemand bemerkt, bis ein
//    Mitglied nachfragt.
//
// 2. GLOSSAR als {{begriff.NACHBARSCHAFT}}. Bewusst als Platzhalter und
//    nicht als Suchen-und-Ersetzen im Fliesstext: ein Glossar, das
//    Woerter im Text austauscht, trifft frueher oder spaeter eines, das
//    gar nicht gemeint war -- und verstuemmelt den Brief.
//
// 3. SPRACHE. Ist beim Mitglied keine hinterlegt, wird NICHT geraten.
//    Dann gehen beide Sprachen hinaus, Albanisch zuerst -- so wie es im
//    Konzept steht. Eine geratene Sprache ist schlechter als zwei
//    richtige.

export type Sprache = 'de' | 'sq' | 'en';

export type Baustein = {
  schluessel: string; sprache: Sprache;
  betreff: string | null; text: string; aktiv: boolean;
};
export type Begriff = { begriff: string; de: string | null; sq: string | null; en: string | null };

export type Textwerk = { bausteine: Baustein[]; begriffe: Begriff[] };

// Einmal laden, mehrfach verwenden -- bei einem Serienversand an 340
// Mitglieder waere eine Abfrage je Brief Unsinn.
export async function textwerkLaden(): Promise<Textwerk> {
  const [{ data: b }, { data: g }] = await Promise.all([
    supabase.from('textbausteine').select('schluessel,sprache,betreff,text,aktiv'),
    supabase.from('glossar').select('begriff,de,sq,en'),
  ]);
  return { bausteine: (b as Baustein[]) ?? [], begriffe: (g as Begriff[]) ?? [] };
}

// Welche Sprache(n) bekommt diese Person? Leer heisst: beide.
export function sprachenFuer(mitglied: { sprache?: string | null } | null | undefined): Sprache[] {
  const s = (mitglied?.sprache ?? '').trim().toLowerCase();
  if (s === 'de' || s === 'sq' || s === 'en') return [s];
  return ['sq', 'de'];   // Reihenfolge aus dem Konzept: Albanisch oben.
}

const einsetzen = (
  roh: string, werte: Record<string, string | number | null | undefined>,
  begriffe: Begriff[], sprache: Sprache,
): string => {
  let text = roh;

  // Glossarbegriffe zuerst: sie koennen selbst in Werten vorkommen,
  // umgekehrt nicht.
  for (const g of begriffe) {
    const wert = g[sprache] ?? g.de ?? g.sq ?? g.en ?? g.begriff;
    text = text.split(`{{begriff.${g.begriff}}}`).join(wert);
  }

  for (const [k, v] of Object.entries(werte)) {
    if (v === null || v === undefined) continue;
    text = text.split(`{{${k}}}`).join(String(v));
  }
  return text;
};

/**
 * Liefert Betreff und Text fuer einen Baustein, in den Sprachen der
 * Person. Fehlt der Baustein in einer Sprache, wird diese uebersprungen;
 * fehlt er ganz, kommt null zurueck -- dann soll der Aufrufer seinen
 * bisherigen Text verwenden statt einen leeren Brief zu verschicken.
 */
export function textFuer(
  werk: Textwerk,
  schluessel: string,
  sprachen: Sprache[],
  werte: Record<string, string | number | null | undefined>,
): { betreff: string; text: string; sprachen: Sprache[] } | null {
  const treffer = sprachen
    .map(sp => ({ sp, b: werk.bausteine.find(x => x.schluessel === schluessel && x.sprache === sp && x.aktiv !== false) }))
    .filter((x): x is { sp: Sprache; b: Baustein } => !!x.b);

  if (treffer.length === 0) return null;

  const betreffe = treffer.map(({ sp, b }) =>
    einsetzen(b.betreff ?? '', werte, werk.begriffe, sp)).filter(Boolean);
  const texte = treffer.map(({ sp, b }) =>
    einsetzen(b.text, werte, werk.begriffe, sp));

  return {
    // Zweisprachig: ein Betreff mit Trennstrich, damit die Zeile im
    // Posteingang nicht doppelt so lang wird wie das Fenster.
    betreff: [...new Set(betreffe)].join(' · '),
    text: texte.join('\n\n— — —\n\n'),
    sprachen: treffer.map(t => t.sp),
  };
}

// Fuer die Mail: Zeilenumbrueche zu Absaetzen, nichts weiter. Der Text
// stammt aus einem Textfeld, nicht aus einem Editor -- ihn als HTML zu
// behandeln hiesse, dem Verein versehentlich Markup unterzuschieben.
export function alsHtml(text: string): string {
  const schutz = (s: string) => s.replace(/[&<>"]/g, z =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[z] as string));
  return text.split(/\n{2,}/)
    .map(abs => `<p style="margin:0 0 1em">${schutz(abs).split('\n').join('<br/>')}</p>`)
    .join('');
}
