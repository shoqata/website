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

export type DemoRolle = 'SUPER_ADMIN' | 'BOARD' | 'MEMBER';

export const DEMO_ROLLEN: { wert: DemoRolle; name: string; was: string }[] = [
  { wert: 'SUPER_ADMIN', name: 'Vereinsadministration', was: 'Sieht alles: Mitglieder, Finanzen, Buchhaltung, Website.' },
  { wert: 'BOARD',       name: 'Vorstand',              was: 'Sitzungen, Protokolle, Anlässe — keine Beitragsverwaltung.' },
  { wert: 'MEMBER',      name: 'Mitglied',              was: 'Eigenes Profil, eigene Beiträge, Anlässe, Neuigkeiten.' },
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

  return { erlaubt, rolle: erlaubt ? rolle : null, setRolle };
}
