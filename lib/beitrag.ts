import type { UserProfile } from '../types';

// Was zahlt dieses Mitglied?
//
// Die Rechnung stand an zwei Stellen -- im Adminbereich als
// suggestedFeeFor und im Sammellauf in AdminFinance -- und soll jetzt
// an einer dritten gebraucht werden, im Vorstandsbereich. Drei Kopien
// einer Geldrechnung sind drei Gelegenheiten, sie verschieden falsch zu
// machen; genau das ist heute bei den Rechnungsnummern und den
// Zustellwegen passiert.
//
// Der Vorrang ist: eigener Beitrag, sonst Gruppensatz, sonst Standard.
//
// Entscheidend ist dabei ein Detail, das leicht verlorengeht: ein
// eigener Beitrag von NULL bleibt null. Er wird mit ?? geprueft und
// nicht mit || -- sonst wuerde eine Beitragsbefreiung still
// ueberschrieben, und das betroffene Mitglied bekaeme eine Rechnung,
// von der es nichts weiss.

export type Beitragssaetze = {
  annualFeeAmount?: number;
  currency?: string;
  fees?: Record<string, { amount?: number; currency?: string; label?: string }>;
};

export type Beitrag = {
  betrag: number;
  waehrung: string;
  // Woher die Zahl kommt. Die Maske soll sagen koennen, wovon ein
  // individueller Betrag abweicht -- eine Zahl ohne Herkunft laedt dazu
  // ein, sie fuer den Gruppensatz zu halten.
  quelle: 'EIGEN' | 'GRUPPE' | 'STANDARD' | 'RUECKFALL';
  gruppe?: string;
  // Was ohne eigenen Betrag gelten wuerde.
  ohne_eigenen: number;
};

const zahl = (v: any): number | null => {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};

export function gruppensatz(
  gruppe: string | undefined | null, s: Beitragssaetze | null | undefined,
): { betrag: number | null; waehrung?: string } {
  const g = String(gruppe ?? '').trim().toUpperCase();
  const eintrag = g ? s?.fees?.[g] : undefined;
  const aus_gruppe = zahl(eintrag?.amount);
  if (aus_gruppe !== null) return { betrag: aus_gruppe, waehrung: eintrag?.currency };
  // Ohne Gruppe oder ohne Satz dafuer: der Standardsatz. Nicht die
  // Gruppe STANDARD -- die kann fehlen -- sondern annualFeeAmount.
  const standard = zahl(s?.fees?.STANDARD?.amount) ?? zahl(s?.annualFeeAmount);
  return { betrag: standard, waehrung: s?.fees?.STANDARD?.currency ?? s?.currency };
}

export function beitragFuer(
  m: Partial<UserProfile> | null | undefined,
  s: Beitragssaetze | null | undefined,
): Beitrag {
  const g = (m as any)?.billingGroup as string | undefined;
  const satz = gruppensatz(g, s);
  const ohne = satz.betrag ?? 120;

  const eigen = zahl((m as any)?.customAnnualFee);
  if (eigen !== null) {
    return {
      betrag: eigen,
      waehrung: satz.waehrung ?? s?.currency ?? 'CHF',
      quelle: 'EIGEN', gruppe: g, ohne_eigenen: ohne,
    };
  }

  return {
    betrag: ohne,
    waehrung: satz.waehrung ?? s?.currency ?? 'CHF',
    quelle: satz.betrag === null ? 'RUECKFALL'
          : g && s?.fees?.[g.toUpperCase()]?.amount !== undefined ? 'GRUPPE'
          : 'STANDARD',
    gruppe: g, ohne_eigenen: ohne,
  };
}
