import { useEffect, type RefObject } from 'react';

// Den scroll-craft-Kern an ein Markup haengen -- und beim Verlassen wieder
// loesen.
//
// Die Mechanik stand zuerst in StartseitePremium.tsx. Mit drei erzaehlenden
// Vorlagen muesste sie dreimal dort stehen, samt der beiden Fallen, die sie
// umgeht:
//
// 1. Das Stylesheet des Kerns setzt body global -- Hintergrund, Textfarbe,
//    Schriftart. Einmal geladen faerbte es auch Anlaesse, Nachrichten und
//    die Verwaltung um, sobald jemand einmal auf der Startseite war. Es
//    wird deshalb beim Betreten eingehaengt und beim Verlassen entfernt.
//
// 2. destroy() ist ein Zusatz dieser Anwendung (siehe
//    public/scrollcraft/HERKUNFT.md). Ohne ihn liefe die Bildschleife auf
//    abgehaengtem Markup weiter.

const KERN_JS = '/scrollcraft/scrollcraft.js';
const KERN_CSS = '/scrollcraft/scrollcraft.css';

function stilEinhaengen(): HTMLLinkElement {
  let l = document.querySelector(`link[href="${KERN_CSS}"]`) as HTMLLinkElement | null;
  if (!l) {
    l = document.createElement('link');
    l.rel = 'stylesheet'; l.href = KERN_CSS;
    document.head.appendChild(l);
  }
  return l;
}

// Das Skript darf bleiben: es tut von sich aus nichts, solange niemand
// ScrollCraft.mount() ruft. Ein zweites Laden waere nur Verkehr.
function kernLaden(): Promise<void> {
  return new Promise((fertig, scheitern) => {
    if ((window as any).ScrollCraft) return fertig();
    let s = document.querySelector(`script[src="${KERN_JS}"]`) as HTMLScriptElement | null;
    if (s) { s.addEventListener('load', () => fertig()); return; }
    s = document.createElement('script');
    s.src = KERN_JS; s.async = true;
    s.onload = () => fertig();
    s.onerror = () => scheitern(new Error('scrollcraft konnte nicht geladen werden'));
    document.head.appendChild(s);
  });
}

// bereit: erst einhaengen, wenn das Markup wirklich steht. Der Kern misst
// Zeilenhoehen und Positionen, und auf halb gefuelltem Markup misst er
// falsch.
//
// abhaengig: woran sich das Markup noch aendern kann (Zahlen, Anzahl der
// Anlaesse). Aendert sich etwas davon, wird neu gemessen.
export function useScrollCraft(
  wurzel: RefObject<HTMLElement | null>,
  bereit: boolean,
  abhaengig: unknown[] = [],
) {
  useEffect(() => {
    if (!bereit || !wurzel.current) return;
    let instanz: any = null;
    let abgebrochen = false;
    const stil = stilEinhaengen();
    // Die Navigationsleiste liegt ausserhalb der Seite und ist fuer hellen
    // Grund gemacht. Hier kennzeichnen statt dort umbauen: so bleibt sie
    // ueberall sonst unveraendert.
    document.documentElement.dataset.startseite = 'premium';

    kernLaden().then(() => {
      if (abgebrochen || !wurzel.current) return;
      const SC = (window as any).ScrollCraft;
      if (!SC) return;
      instanz = SC.mount(wurzel.current);
    }).catch(() => { /* ohne Kern bleibt die Seite lesbar, nur ohne Bewegung */ });

    return () => {
      abgebrochen = true;
      if (instanz && typeof instanz.destroy === 'function') instanz.destroy();
      stil.remove();
      delete document.documentElement.dataset.startseite;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bereit, ...abhaengig]);
}

// Das Farbschema der erzaehlenden Vorlagen. Es leitet sich aus der
// Vereinsfarbe ab -- ein zweites Schema waere ein zweiter Ort, an dem eine
// Umfaerbung vergessen wird.
export const DUNKLER_GRUND = `
  --sc-canvas: #0b0c10;
  --sc-surface: #14161d;
  --sc-ink: #f6f5f3;
  --sc-ink-soft: #9b9ca4;
  --sc-accent: var(--primary, #f43f5e);
  --sc-accent-ink: #0b0c10;
`;

// Die Leiste liegt ausserhalb der Seite, deshalb ueber das Kennzeichen am
// Wurzelelement. Gilt fuer jede erzaehlende Vorlage gleich.
export const LEISTE_DUNKEL = `
  html[data-startseite="premium"] nav > div {
    background: rgba(11,12,16,.62) !important;
    border: 1px solid rgba(255,255,255,.12);
    box-shadow: 0 10px 30px -18px rgba(0,0,0,.9);
  }
  html[data-startseite="premium"] nav a,
  html[data-startseite="premium"] nav button { color: #e9e8e6 !important; }
`;
