// Gemeinsame Kurven und Dauern fuer Bewegung, nach emilkowalski/skills.
//
// Bisher lief fast alles auf den Vorgaben von framer-motion und Tailwind.
// Die sind zu weich fuer Bewegung, die man sehen soll: ein Element, das
// erscheint, soll schnell da sein und weich ankommen (ease-out), nicht
// langsam loslaufen. Dieselben Werte stehen als CSS-Variablen in index.html.
export const EASE_OUT = [0.23, 1, 0.32, 1] as const;
export const EASE_IN_OUT = [0.77, 0, 0.175, 1] as const;
export const EASE_DRAWER = [0.32, 0.72, 0, 1] as const;

// Erscheinen: kurz, ease-out.
export const EINBLENDEN = { duration: 0.2, ease: EASE_OUT };
// Feder fuer seltene, betonte Momente (Abschluss, Erfolg).
export const FEDER = { type: 'spring' as const, duration: 0.5, bounce: 0.2 };

// Fuer Bewegung, die in JavaScript laeuft (Schleifen, Intervalle, scrollTo):
// die CSS-Regel fuer reduzierte Bewegung erreicht sie nicht.
export const wenigerBewegung = (): boolean =>
  typeof window !== 'undefined' && !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
export const scrollArt = (): ScrollBehavior => (wenigerBewegung() ? 'auto' : 'smooth');
