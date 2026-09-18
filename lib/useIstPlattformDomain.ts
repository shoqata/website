import { useEffect, useState } from 'react';
import { resolveTenantId, tenantIdAusSpeicher } from '@/services/supabase-bridge';

// Gehoert die aufgerufene Adresse zu einem Verein?
//
// Die Betreiber-Domain ist bewusst in keinem tenant_domains-Eintrag
// verzeichnet. resolveTenantId() gibt dort deshalb null zurueck -- und genau
// daran ist sie zu erkennen, ohne eine zweite Liste pflegen zu muessen, die
// mit der Datenbank auseinanderlaufen koennte.
//
// Liegt hier, weil inzwischen mehrere Stellen die Antwort brauchen: die
// Startseite, die Anmeldung und der Cookie-Hinweis.
//
// null bedeutet: noch nicht bekannt. Aufrufer duerfen sich in diesem Fall auf
// KEINE der beiden Darstellungen festlegen -- die frueher an dieser Stelle
// gewaehlte Vereinsdarstellung war der Grund, weshalb auf der
// Betreiber-Domain zuerst die Vereinsseite erschien. Erst nach dem ersten
// Besuch kennt der Speicher die Antwort, und dann steht sie sofort fest.
export function useIstPlattformDomain(): boolean | null {
  const [istPlattform, setIstPlattform] = useState<boolean | null>(() => {
    const bekannt = tenantIdAusSpeicher();
    return bekannt === undefined ? null : !bekannt;
  });

  useEffect(() => {
    let lebt = true;
    // Auch wenn der Speicher schon eine Antwort hatte, wird nachgeprueft: eine
    // Domain kann einem Verein zugeordnet werden, nachdem jemand die Seite
    // zuletzt besucht hat. Der gespeicherte Wert bestimmt das erste Bild, die
    // Datenbank das endgueltige.
    resolveTenantId()
      .then((verein) => { if (lebt) setIstPlattform(!verein); })
      // Bei einem Fehler bleibt es beim zuletzt bekannten Stand. Ein
      // voruebergehend nicht erreichbarer Server soll die Darstellung nicht
      // umbauen -- und beim allerersten Besuch lieber nichts behaupten.
      .catch(() => {})
      .finally(() => {
        if (!lebt) return;
        // Beim allerersten Besuch ohne erreichbaren Server bliebe die Seite
        // sonst dauerhaft unentschieden. Dann lieber die Vereinsdarstellung:
        // sie ist der weitaus haeufigere Fall.
        setIstPlattform((bisher) => (bisher === null ? false : bisher));
      });
    return () => { lebt = false; };
  }, []);

  // Der Grundton der Seite steht in index.html an <html data-domain> und wird
  // dort schon vor dem ersten Rendern aus dem Speicher gesetzt. Hier wird er
  // nachgefuehrt, sobald die Datenbank geantwortet hat.
  useEffect(() => {
    document.documentElement.dataset.domain =
      istPlattform === null ? 'unbekannt' : istPlattform ? 'plattform' : 'verein';
  }, [istPlattform]);

  return istPlattform;
}
