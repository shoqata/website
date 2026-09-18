import { useEffect } from 'react';
import { TINTE, BLAU, LEUCHTEN } from '@/components/platform/farben';

// Titel und Symbol im Browserreiter.
//
// Beide Domains teilen sich eine index.html, deren Titel "Koretini" lautet --
// fuer die Betreiber-Domain falsch. Das Skript dort setzt ihn schon vor dem
// ersten Anstrich, sobald die Zuordnung aus dem Speicher bekannt ist; beim
// allerersten Besuch steht dort so lange die Adresse selbst.
//
// Hier wird nachgefuehrt, sobald die Datenbank geantwortet hat. Das lag
// vorher in PlatformHome -- also nur auf der Startseite. Auf /#/login oder
// /#/dashboard blieb der Reiter deshalb beim Erstbesuch bei "unityhub.li"
// stehen. Deshalb jetzt an einer Stelle, die fuer jede Seite der Domain gilt.
export function useReiterKennzeichen(istPlattform: boolean | null) {
  useEffect(() => {
    // Der hinterlegte Titel aus index.html, bevor das Skript dort ihn im
    // unbekannten Zustand durch die Adresse ersetzt hat.
    const vorgabe = document.documentElement.dataset.titelVorgabe;

    if (istPlattform === false) {
      // Vereinsadresse: der Zwischentitel muss wieder weichen.
      if (vorgabe && document.title !== vorgabe) document.title = vorgabe;
      return;
    }
    if (istPlattform !== true) return;

    const vorher = vorgabe ?? document.title;
    document.title = 'unityhub';

    const zeichen = encodeURIComponent(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">' +
      `<rect width="48" height="48" rx="8" fill="${TINTE}"/>` +
      `<g fill="${BLAU}">` +
      '<circle cx="24" cy="11" r="3"/><circle cx="35.3" cy="17.5" r="3"/>' +
      '<circle cx="35.3" cy="30.5" r="3"/><circle cx="24" cy="37" r="3"/>' +
      '<circle cx="12.7" cy="30.5" r="3"/></g>' +
      `<circle cx="12.7" cy="17.5" r="3" fill="${LEUCHTEN}"/>` +
      `<circle cx="24" cy="24" r="5.4" fill="${BLAU}"/>` +
      `<circle cx="24" cy="24" r="2.1" fill="${TINTE}"/></svg>`
    );
    const link = document.querySelector<HTMLLinkElement>('link[rel="icon"]')
      ?? document.head.appendChild(Object.assign(document.createElement('link'), { rel: 'icon' }));
    const vorherIcon = link.href;
    link.type = 'image/svg+xml';
    link.href = `data:image/svg+xml,${zeichen}`;

    return () => {
      document.title = vorher;
      if (vorherIcon) link.href = vorherIcon;
    };
  }, [istPlattform]);
}
