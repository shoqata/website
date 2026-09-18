import { useEffect, useState } from 'react';
import { resolveTenantId } from '@/services/supabase-bridge';

// Gehoert die aufgerufene Adresse zu einem Verein?
//
// Die Betreiber-Domain ist bewusst in keinem tenant_domains-Eintrag
// verzeichnet. resolveTenantId() gibt dort deshalb null zurueck -- und genau
// daran ist sie zu erkennen, ohne eine zweite Liste pflegen zu muessen, die
// mit der Datenbank auseinanderlaufen koennte.
//
// Liegt hier, weil inzwischen mehrere Stellen die Antwort brauchen: die
// Startseite und die Anmeldung. Eine zweite Fassung waere genau die Sorte
// Verdopplung, die spaeter auseinanderlaeuft.
//
// Waehrend der Pruefung ist das Ergebnis null. Aufrufer sollen in diesem Fall
// bei der Vereinsdarstellung bleiben: ein kurzes Aufblitzen der falschen
// Seite waere schlechter als eine Verzoegerung von Sekundenbruchteilen.
export function useIstPlattformDomain(): boolean | null {
  const [istPlattform, setIstPlattform] = useState<boolean | null>(null);

  useEffect(() => {
    let lebt = true;
    resolveTenantId()
      .then((verein) => { if (lebt) setIstPlattform(!verein); })
      // Bei einem Fehler lieber die Vereinsseite zeigen als eine leere: ein
      // voruebergehend nicht erreichbarer Server soll die Website nicht
      // umbauen.
      .catch(() => { if (lebt) setIstPlattform(false); });
    return () => { lebt = false; };
  }, []);

  return istPlattform;
}
