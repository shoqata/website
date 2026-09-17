import { UserProfile } from '../types';
import { hasUsableEmail, emailMissingForDelivery } from './memberEmail';

// Welche Angaben an einem Mitglied fehlen.
//
// Die Regeln standen bisher nur in der Datenqualitaets-Ansicht und waren dort
// mit albanischen Feldnamen fest verdrahtet. Sie liegen jetzt zentral und
// geben Uebersetzungsschluessel zurueck, damit Nachbarschafts-Detail und
// Datenqualitaet dieselbe Aussage treffen.
export interface MissingOptions {
  // Nur Felder, die das Mitglied im eigenen Profil selbst ausfuellen kann.
  // Die Nachbarschaft gehoert nicht dazu -- sie wird vom Vorstand zugeordnet,
  // und ein Hinweis auf etwas, das man nicht aendern kann, hilft niemandem.
  selfServiceOnly?: boolean;
}

export const missingFieldKeys = (u: Partial<UserProfile>, opts: MissingOptions = {}): string[] => {
  const missing: string[] = [];
  if (!u.phone) missing.push('field.phone');
  if (!u.birthdate) missing.push('field.birthdate');
  if (!u.street || !u.zip || !u.city) missing.push('field.address');
  if (!opts.selfServiceOnly && !u.neighborhoodId) missing.push('admin.members.neighborhood');
  if (!hasUsableEmail(u)) missing.push('field.email');
  return missing;
};

// Wiegt schwerer als eine bloss fehlende Angabe: die Zustellart verspricht
// E-Mail, es gibt aber keine brauchbare Adresse. Die Rechnung geht dann
// still per Post -- oder gar nicht.
export const hasDeliveryConflict = (u: Partial<UserProfile>): boolean =>
  emailMissingForDelivery(u);

// 100 Prozent bei vollstaendigen Angaben, je fehlendes Feld 20 Prozent weniger.
export const qualityScore = (missingCount: number): number =>
  Math.max(0, 100 - missingCount * 20);

export type FeeState = 'PAID' | 'OPEN' | 'NONE';

// Stand des Mitgliederbeitrags fuer ein Jahr.
//   PAID  eine bezahlte Rechnung liegt vor
//   OPEN  eine Rechnung ist gestellt, aber nicht bezahlt
//   NONE  fuer dieses Jahr wurde nichts verrechnet
export const feeStateFor = (userId: string, payments: any[], year: number): FeeState => {
  const own = payments.filter((p) => p.userId === userId && billingYearOf(p) === year);
  if (own.length === 0) return 'NONE';
  return own.some((p) => p.status === 'PAID') ? 'PAID' : 'OPEN';
};

// Muss dieses Mitglied durch den Einrichtungsassistenten?
//
// Die Weiche fragte bisher nur profileComplete ab. Bei 295 der 350 Mitglieder
// stand dort nichts, obwohl Name, Adresse und Nachbarschaft laengst erfasst
// waren -- sie wurden bei jeder Anmeldung durch einen Assistenten geschickt,
// der ihnen leere Felder zeigte.
//
// Geprueft wird deshalb, was der Assistent tatsaechlich erhebt, und nichts
// darueber hinaus. Das Geburtsdatum steht bewusst nicht in der Liste: der
// Assistent fragt es nicht ab, es hier zu verlangen wuerde jemanden in eine
// Maske schicken, in der sich das Fehlende gar nicht nachtragen laesst.
//
// Das Land fehlt bei 343 Mitgliedern, steht aber ebenfalls nicht in der
// Liste. Alle betroffenen Adressen sind schweizerisch (vierstellige
// Postleitzahl, Schweizer Ort); der Assistent waehlt Schweiz vor. Dafuer
// dreihundert Leute durch eine Maske zu schicken waere Aufwand ohne Ertrag.
export const needsProfileSetup = (u: Partial<UserProfile>): boolean => {
  if (!u) return true;
  const leer = (v: any) => !v || !String(v).trim();
  return (
    leer(u.displayName) ||
    leer(u.phone) ||
    leer(u.street) ||
    leer(u.zip) ||
    leer(u.city) ||
    leer(u.neighborhoodId)
  );
};

// Zu welchem Beitragsjahr gehoert eine Zahlung?
//
// Massgeblich ist billingYear: dort steht, fuer welches Jahr der Beitrag
// erhoben wird. Der Zeitstempel sagt nur, wann der Datensatz entstand -- eine
// im Januar 2026 gestellte Rechnung fuer 2025 wuerde danach im falschen Jahr
// landen. Genau das passierte in der Vorstandsansicht: sie zaehlte 324
// Zahlungen fuer 2026, waehrend die Rechnungsansicht 321 auswies, und
// 80 bezahlte gegen 79.
//
// Der Zeitstempel bleibt als Rueckfall, weil zwei Zahlungen kein billingYear
// tragen. Ohne ihn fielen sie aus jeder Jahresauswertung heraus.
export const billingYearOf = (p: any): number => {
  if (p?.billingYear) return Number(p.billingYear);
  const ts = p?.timestamp?.toDate ? p.timestamp.toDate()
           : p?.timestamp ? new Date(p.timestamp) : null;
  return ts ? ts.getFullYear() : NaN;
};
