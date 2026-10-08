import { useCallback, useEffect, useState } from 'react';

// Der Rollenschalter fuer die Vorfuehrung.
//
// Zweck: einem Verein zeigen, was Vereinsadministration, Vorstand und
// einfaches Mitglied jeweils SEHEN. Fuer ein Verkaufsgespraech ist genau
// das die Frage -- nicht, ob die Zeilenregeln halten.
//
// Was er ausdruecklich NICHT tut: an app_role() oder an den Zeilenregeln
// drehen. Diese Funktion haengt an is_staff() und damit an praktisch
// jeder Regel der Datenbank; ein Fehler dort waere ein plattformweites
// Loch, und gewinnen wuerde man wenig -- alles, was an
// is_platform_admin() haengt, bliebe fuer den Betreiber ohnehin offen.
// Der Schalter aendert also die ANSICHT, nicht die Rechte. Wer das
// verwechselt, haelt eine Vorfuehrung fuer einen Sicherheitsnachweis.
//
// Zwei Bedingungen, beide notwendig:
//   * nur der Plattformbetreiber,
//   * nur im Demo-Verein.
// Damit kann der Schalter in keiner echten Vereinsoberflaeche auftauchen,
// auch nicht versehentlich.

export const DEMO_VEREIN = 'demo';

export type DemoRolle = 'SUPER_ADMIN' | 'BOARD' | 'MEMBER' | 'VERTRETER';

// `ziel` ist die Seite, auf der diese Rolle etwas zu sehen bekommt --
// ohne sie landet man beim Umschalten auf der Seite der vorigen Rolle
// und sieht eine leere Maske.
//
// VERTRETER ist bewusst anders: das ist KEINE Rolle in users, sondern
// haengt daran, ob jemand bei einer Nachbarschaft eingetragen ist
// (my_neighborhoods). Die Ansicht wird deshalb nicht ueber user.role
// erreicht, sondern ueber die Seite /nachbarschaft.
export const DEMO_ROLLEN: {
  wert: DemoRolle; name: string; was: string; ziel: string; ueberschreibtRolle: boolean;
}[] = [
  { wert: 'SUPER_ADMIN', name: 'Vereinsadministration',
    was: 'Sieht alles: Mitglieder, Finanzen, Buchhaltung, Website.',
    ziel: '/admin', ueberschreibtRolle: true },
  { wert: 'BOARD', name: 'Vorstand',
    was: 'Sitzungen, Protokolle, Anlässe — keine Beitragsverwaltung.',
    ziel: '/dashboard', ueberschreibtRolle: true },
  { wert: 'MEMBER', name: 'Mitglied',
    was: 'Eigenes Profil, eigene Beiträge, Anlässe, Neuigkeiten.',
    ziel: '/dashboard', ueberschreibtRolle: true },
  { wert: 'VERTRETER', name: 'Vertreter vor Ort',
    was: 'Seine Nachbarschaft in Koretin: wer offen ist, Barzahlung melden. Die Verwaltung entscheidet darüber.',
    ziel: '/nachbarschaft', ueberschreibtRolle: false },
];

const SPEICHER = 'demo-rollenansicht';

export function useDemoRolle(istBetreiber: boolean, verein: string | null) {
  const erlaubt = istBetreiber && verein === DEMO_VEREIN;
  const [rolle, setRolleIntern] = useState<DemoRolle | null>(null);

  // Beim Laden wiederherstellen -- aber nur, wenn es erlaubt IST. Sonst
  // traegt ein alter Eintrag im Browser die Ansicht in einen echten
  // Verein hinueber.
  useEffect(() => {
    if (!erlaubt) { setRolleIntern(null); return; }
    try {
      const g = localStorage.getItem(SPEICHER) as DemoRolle | null;
      if (g && DEMO_ROLLEN.some(r => r.wert === g)) setRolleIntern(g);
    } catch { /* kein Speicher, kein Problem */ }
  }, [erlaubt]);

  const setRolle = useCallback((neu: DemoRolle | null) => {
    if (!erlaubt) return;
    setRolleIntern(neu);
    try {
      if (neu) localStorage.setItem(SPEICHER, neu);
      else localStorage.removeItem(SPEICHER);
    } catch { /* ignorieren */ }
  }, [erlaubt]);

  // VERTRETER ist keine users-Rolle -- sie darf user.role nicht
  // ueberschreiben, sonst waere der Betreiber ploetzlich REPRESENTATIVE
  // und saehe weder Admin noch Nachbarschaft.
  const rolleFuerApp = (rolle && DEMO_ROLLEN.find(r => r.wert === rolle)?.ueberschreibtRolle)
    ? (rolle as Exclude<DemoRolle, 'VERTRETER'>) : null;

  return { erlaubt, rolle: erlaubt ? rolle : null, rolleFuerApp: erlaubt ? rolleFuerApp : null, setRolle };
}
