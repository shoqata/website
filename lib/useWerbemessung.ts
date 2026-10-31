import { useEffect, useState } from 'react';
import { messungStarten, zustimmungLesen, type Entscheid } from './werbemessung';

// Die Werbemessung in Gang setzen, sobald sie erlaubt ist.
//
// Zwei Zeitpunkte, und der zweite wird leicht vergessen:
//
//   beim Laden      ein wiederkehrender Besucher hat schon zugestimmt
//   nach dem Klick  ein neuer Besucher stimmt gerade zu
//
// Ohne den zweiten wuerde ein Besucher, der annimmt, erst beim naechsten
// Besuch gemessen -- und genau der Besuch, in dem er sich meldet, fehlte
// in der Auswertung. Darum horcht der Haken auf das Ereignis, das der
// Hinweis beim Entscheiden auslöst.
//
// Die IDs stehen in der Umgebung und nicht in der Datenbank: sie
// gehoeren dem Betreiber, nicht einem Verein, und sie aendern sich
// praktisch nie. Fehlen sie, laedt nichts -- siehe darfMessen().

export const ZUSTIMMUNG_EREIGNIS = 'zustimmung-geaendert';

// Den Hinweis erneut zeigen -- aus der Fusszeile, jederzeit. Ohne diesen
// Weg liesse sich eine Zustimmung nur ueber das Loeschen der
// Websitedaten zuruecknehmen.
export const EINSTELLUNGEN_EREIGNIS = 'zustimmung-oeffnen';
export const zustimmungOeffnen = () => window.dispatchEvent(new Event(EINSTELLUNGEN_EREIGNIS));

export function useWerbemessung(istPlattform: boolean | null): Entscheid | null {
  const [entscheid, setEntscheid] = useState<Entscheid | null>(null);

  useEffect(() => {
    const pruefen = () => {
      const e = messungStarten({
        istPlattform,
        zustimmung: zustimmungLesen(istPlattform),
        metaPixel: import.meta.env.VITE_META_PIXEL_ID,
        googleAds: import.meta.env.VITE_GOOGLE_ADS_ID,
      });
      setEntscheid(e);
    };
    pruefen();
    window.addEventListener(ZUSTIMMUNG_EREIGNIS, pruefen);
    return () => window.removeEventListener(ZUSTIMMUNG_EREIGNIS, pruefen);
  }, [istPlattform]);

  return entscheid;
}
