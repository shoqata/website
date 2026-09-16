import { UserProfile } from '../types';
import { hasUsableEmail, emailMissingForDelivery } from './memberEmail';

// Welche Angaben an einem Mitglied fehlen.
//
// Die Regeln standen bisher nur in der Datenqualitaets-Ansicht und waren dort
// mit albanischen Feldnamen fest verdrahtet. Sie liegen jetzt zentral und
// geben Uebersetzungsschluessel zurueck, damit Nachbarschafts-Detail und
// Datenqualitaet dieselbe Aussage treffen.
export const missingFieldKeys = (u: Partial<UserProfile>): string[] => {
  const missing: string[] = [];
  if (!u.phone) missing.push('field.phone');
  if (!u.birthdate) missing.push('field.birthdate');
  if (!u.street || !u.zip || !u.city) missing.push('field.address');
  if (!u.neighborhoodId) missing.push('admin.members.neighborhood');
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
  const yearOf = (p: any) => {
    if (p?.billingYear) return Number(p.billingYear);
    const ts = p?.timestamp?.toDate ? p.timestamp.toDate() : p?.timestamp ? new Date(p.timestamp) : null;
    return ts ? ts.getFullYear() : NaN;
  };
  const own = payments.filter((p) => p.userId === userId && yearOf(p) === year);
  if (own.length === 0) return 'NONE';
  return own.some((p) => p.status === 'PAID') ? 'PAID' : 'OPEN';
};
