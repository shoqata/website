// Seitenaufrufe zaehlen, vom Browser aus.
//
// Drei Entscheidungen, die den Unterschied machen:
//
// 1. Gezaehlt werden nur OEFFENTLICHE Seiten. Der Adminbereich, das
//    Dashboard und die Betreuungsmaske bleiben draussen. Wer wissen
//    will, wie die Website laeuft, will nicht die eigenen Klicks des
//    Vorstands mitzaehlen -- bei 6 angemeldeten Konten und wenigen
//    Besuchern wuerde das die Zahlen kippen.
//
// 2. Die Verweildauer wird beim Verlassen nachgetragen, nicht geschaetzt.
//    Gemessen wird die Zeit, in der die Seite SICHTBAR war: ein Reiter
//    im Hintergrund ist kein Lesen. Ohne das ergaebe ein offener Reiter
//    ueber Nacht eine Durchschnittsdauer von Stunden.
//
// 3. Fehler bleiben still. Ein Zaehler, der die Seite kaputtmacht, ist
//    schlimmer als keiner. Jede Zusage hier ist "wenn es geht".

const AUSGENOMMEN = [
  '/admin', '/super-admin', '/dashboard', '/nachbarschaft', '/login',
  '/register', '/setup-profile', '/vorstellen', '/revision',
];

export const oeffentlich = (pfad: string): boolean =>
  !AUSGENOMMEN.some(a => pfad === a || pfad.startsWith(a + '/'));

type Lauf = { id: string | null; seit: number; sichtbar: number; pfad: string };
let lauf: Lauf | null = null;

const jetzt = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());

// Die sichtbare Zeit fortschreiben. Wird beim Wechsel der Sichtbarkeit
// und beim Verlassen aufgerufen.
const sichtbarkeitBuchen = () => {
  if (!lauf) return;
  if (typeof document !== 'undefined' && document.visibilityState === 'visible') {
    lauf.seit = jetzt();
  } else {
    lauf.sichtbar += jetzt() - lauf.seit;
  }
};

const dauerSenden = async () => {
  if (!lauf?.id) return;
  const sekunden = Math.round(
    (lauf.sichtbar + (document?.visibilityState === 'visible' ? jetzt() - lauf.seit : 0)) / 1000);
  if (sekunden < 1) return;
  const id = lauf.id;
  lauf.id = null;   // nur einmal je Aufruf
  try {
    const { supabase } = await import('@/services/supabase-bridge');
    // keepalive, damit der Aufruf das Schliessen des Reiters ueberlebt.
    await supabase.rpc('seitenaufruf_dauer', { p_id: id, p_sekunden: sekunden });
  } catch { /* still */ }
};

/**
 * Einen Aufruf zaehlen. Gibt true zurueck, wenn tatsaechlich gezaehlt
 * wurde -- nuetzlich im Test, sonst gleichgueltig.
 */
export async function aufrufZaehlen(
  pfad: string, titel?: string, ziel?: string,
): Promise<boolean> {
  if (!oeffentlich(pfad)) return false;

  // Vorherigen Aufruf abschliessen, bevor der neue beginnt.
  if (lauf && lauf.pfad !== pfad) await dauerSenden();

  lauf = { id: null, seit: jetzt(), sichtbar: 0, pfad };
  try {
    const { supabase } = await import('@/services/supabase-bridge');
    const { data, error } = await supabase.rpc('seitenaufruf_zaehlen', {
      p_pfad: pfad,
      p_titel: titel ?? (typeof document !== 'undefined' ? document.title : null),
      // Der Verweis aus dem Browser ist bei einem Wechsel innerhalb der
      // Seite richtiger als die Kopfzeile der Anfrage -- die zeigt dann
      // auf die eigene Seite.
      p_verweis: typeof document !== 'undefined' ? document.referrer || null : null,
      p_ziel: ziel ?? null,
    });
    if (error) return false;
    if (lauf) lauf.id = (data as string) ?? null;
    return !!data;
  } catch {
    return false;
  }
}

/**
 * Ein erreichtes Ziel vermerken -- Anfrage abgeschickt, Anmeldung
 * abgeschlossen, Spende begonnen.
 *
 * Eigener Aufruf und kein Feld am Seitenaufruf: ein Ziel kann mehrfach
 * und auf jeder Seite erreicht werden, und es soll sich dem Pfad
 * zuordnen lassen, auf dem es geschah.
 */
export async function zielErreicht(name: string, pfad?: string): Promise<void> {
  const p = pfad ?? (typeof location !== 'undefined' ? location.hash.replace(/^#/, '') || '/' : '/');
  try {
    const { supabase } = await import('@/services/supabase-bridge');
    await supabase.rpc('seitenaufruf_zaehlen', {
      p_pfad: p, p_titel: null, p_verweis: null, p_ziel: name,
    });
  } catch { /* still */ }
}

let gebunden = false;

/** Einmal beim Start aufrufen. Bindet Sichtbarkeit und Verlassen. */
export function zaehlerStarten(): void {
  if (gebunden || typeof window === 'undefined') return;
  gebunden = true;
  document.addEventListener('visibilitychange', sichtbarkeitBuchen);
  // pagehide statt unload: unload wird von Browsern zunehmend nicht mehr
  // ausgeloest, wenn die Seite in den Zwischenspeicher wandert.
  window.addEventListener('pagehide', () => { void dauerSenden(); });
}
