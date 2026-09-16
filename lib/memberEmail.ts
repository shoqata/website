import { UserProfile } from '../types';

// Ersatzadressen aus dem Datenimport.
//
// Beim Uebernehmen der alten Mitgliederliste bekam jede Person ohne Adresse
// eine erfundene der Form `vorname.nachname.no-email-1234@koretini.legacy`,
// damit der Datensatz ueberhaupt angelegt werden konnte. Fachlich ist das
// keine Adresse -- an sie laesst sich nichts zustellen.
//
// Die Pruefung stand bisher an sechs Stellen in drei Varianten: einmal
// endsWith, einmal includes, einmal gar nicht. Jetzt an einer Stelle.
const PLACEHOLDER_DOMAIN = '@koretini.legacy';

export const isPlaceholderEmail = (email?: string | null): boolean => {
  const e = (email || '').trim().toLowerCase();
  if (!e) return true;
  if (e.includes(PLACEHOLDER_DOMAIN)) return true;
  if (e.includes('no-email-')) return true;
  return false;
};

// Sieht die Adresse ueberhaupt wie eine aus?
export const looksLikeEmail = (email?: string | null): boolean =>
  /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test((email || '').trim());

// Kann an diese Person elektronisch zugestellt werden?
export const hasUsableEmail = (u: Partial<UserProfile> | null | undefined): boolean =>
  !!u && !isPlaceholderEmail(u.email) && looksLikeEmail(u.email);

// Verlangt die gewaehlte Zustellart eine E-Mail-Adresse?
// 'BOTH' zaehlt mit -- wer Post *und* E-Mail gewaehlt hat, erwartet die E-Mail.
export const deliveryNeedsEmail = (u: Partial<UserProfile> | null | undefined): boolean =>
  u?.invoiceDeliveryMethod === 'EMAIL' || u?.invoiceDeliveryMethod === 'BOTH';

// Die eigentliche Regel: E-Mail-Versand gewaehlt, aber keine brauchbare Adresse.
export const emailMissingForDelivery = (u: Partial<UserProfile> | null | undefined): boolean =>
  deliveryNeedsEmail(u) && !hasUsableEmail(u);
