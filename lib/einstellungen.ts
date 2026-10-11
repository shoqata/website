// Einstellungen laden -- aus der richtigen Spalte.
//
// Die Tabelle settings hat eine Zeile je Bereich und je Bereich eine
// EIGENE Spalte:
//
//   id='payment'   -> Spalte payment
//   id='branding'  -> Spalte branding
//   id='company'   -> Spalte company
//   id='system'    -> Spalte system
//
// Es gibt zusaetzlich eine Spalte "data". Sie ist bei allen vier Zeilen
// {} -- ein Rest aus der Firebase-Zeit, in der alles in einem Dokument
// lag.
//
// Zwei Stellen haben sie gelesen, und beide still falsch gearbeitet:
//
//   lib/mahnung.ts      select('data').eq('id','payment')
//                       -> z = {} -> QR-Rechnung ohne IBAN, ohne
//                          Kontoinhaber, ohne Adresse -> das PDF
//                          scheiterte -> die Mahnung wurde abgelehnt
//
//   lib/flokykarte.ts   select('data').eq('id','branding')
//                       -> Vereinsname leer -> die Mahnung ging ohne
//                          Absendernamen hinaus
//
// Der erste Fall hat mich selbst in die Irre gefuehrt: ich sah die
// Meldung "Die Rechnung liess sich nicht erzeugen" und schloss daraus
// auf eine fehlende IBAN. Die IBAN war da -- gemessen, in zwei Zeilen --
// nur gelesen wurde die falsche Spalte. Daraufhin habe ich dem Verein
// mehrfach berichtet, er muesse eine IBAN eintragen, die er laengst
// eingetragen hatte.
//
// Eine falsche Spalte wirft keinen Fehler. PostgREST liefert die Zeile
// mit null, der Aufrufer macht daraus {} und arbeitet weiter. Darum
// diese Stelle: der Bereich bestimmt die Spalte, und zwar an einem Ort.

export type Bereich = 'payment' | 'branding' | 'company' | 'system';

export async function einstellungLaden<T = any>(bereich: Bereich): Promise<T> {
  const { supabase } = await import('@/services/supabase-bridge');
  const { data, error } = await supabase
    .from('settings')
    .select(bereich)
    .eq('id', bereich)
    .maybeSingle();
  if (error) throw new Error(`Einstellungen ${bereich}: ${error.message}`);
  return (((data as any) ?? {})[bereich] ?? {}) as T;
}

// Mehrsprachige Werte aus dem Branding zu einer Zeichenkette machen.
// Steht hier, weil beide Aufrufer es brauchen und beide es verschieden
// gelost hatten.
export function alsText(wert: any, sprache: 'de' | 'sq' | 'en' = 'de'): string {
  if (!wert) return '';
  if (typeof wert === 'string') return wert.trim();
  if (typeof wert === 'object') {
    const o = wert as Record<string, string>;
    return String(o[sprache] ?? o.de ?? o.sq ?? o.en ?? '').trim();
  }
  return String(wert).trim();
}
