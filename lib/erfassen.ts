import { hasUsableEmail } from './memberEmail';
import type { UserProfile } from '../types';

// Die Schreibschicht wird in den beiden Schreibfunktionen geholt, nicht
// hier oben. Zwei Gruende, und der erste ist mir erst beim Testlauf
// aufgefallen:
//
//   Die Entscheidungen -- Zustellweg, Zahlungsart, Rechnungsnummer,
//   Pruefung -- haengen an keiner Datenbank. Sie oben einzubinden machte
//   die ganze Datei untestbar, weil der Testlauf die Browser-Bausteine
//   dahinter nicht aufloesen kann. Ein Modul, dessen Regeln sich nicht
//   pruefen lassen, ist genau das Gegenteil von dem, wofuer es hier
//   steht.
//
//   Und: wer nur die Regel braucht (etwa eine Liste, die den Zustellweg
//   anzeigt), zieht damit nicht die ganze Schreibschicht ins Buendel.
const schreiben = async () => {
  const [bridge, zugriff] = await Promise.all([
    import('@/services/supabase-bridge'),
    import('@/services/datenzugriff'),
  ]);
  return { ...bridge, db: zugriff.db };
};

// Mitglied und Rechnung erfassen -- an einer Stelle.
//
// Vorher gab es das dreimal, mit drei verschiedenen Rechnungsnummern und
// zwei verschiedenen Zustellregeln:
//
//   AdminPanel    INV-<letzte 5 Stellen der Zeit>        deliveryMethod: 'EMAIL'
//   AdminFinance  INV-<6 Stellen>-<3 Zufallsstellen>     deliveryMethod: 'EMAIL'
//   AdminFinance  INV-<6 Stellen>-<Index><Zufall>        Regel aus dem Mitglied
//
// Nur die dritte Variante ist richtig. Die beiden anderen schreiben
// jedem Mitglied EMAIL in die Rechnung -- gemessen wollen 241 von 348
// Rechnungen Post, und fuenf Mitglieder haben das ausdruecklich
// hinterlegt. Eine Rechnung mit EMAIL an jemanden ohne brauchbare
// Adresse geht nirgendwohin und faellt niemandem auf.
//
// Die Rechnungsnummer aus fuenf Stellen der Zeit wiederholt sich alle
// hundert Sekunden. Gemessen: bei 348 Rechnungen noch keine Doppelung --
// aufgetreten ist es also nicht, moeglich ist es sehr wohl.
//
// Und das Beitragsjahr fehlte im Adminweg ganz. Drei Rechnungen haben
// keines; sie fallen damit aus jeder Jahresauswertung heraus, weil
// billingYearOf nur auf den Zeitstempel zurueckfaellt.

// ---------------------------------------------------------- Zustellweg
//
// Die Regel des Serienlaufs, wortgleich uebernommen -- sie ist die
// einzige, die das Mitglied fragt.
export function zustellweg(m: Partial<UserProfile>): 'EMAIL' | 'POST' | 'BOTH' {
  const brauchbar = hasUsableEmail(m as any);
  if (!brauchbar || (m as any).invoiceDeliveryMethod === 'POST') return 'POST';
  if ((m as any).invoiceDeliveryMethod === 'BOTH') return 'BOTH';
  return 'EMAIL';
}

// Zahlungsart: in der Schweiz die QR-Rechnung, sonst Ueberweisung.
export function zahlungsart(m: Partial<UserProfile>): 'QR_BILL' | 'BANK_TRANSFER' {
  return (m.country ?? '').trim() === 'Switzerland' ? 'QR_BILL' : 'BANK_TRANSFER';
}

// ------------------------------------------------------ Rechnungsnummer
//
// Jahr, damit sie lesbar bleibt und sich nach Jahr sortieren laesst, und
// ein Zufallsteil aus genuegend Zeichen, damit zwei gleichzeitige
// Erfassungen nicht kollidieren. Kein Zaehler: der braeuchte eine
// Sperre in der Datenbank, und zwei Vorstandsmitglieder, die zugleich
// erfassen, bekaemen sonst dieselbe Nummer.
export function rechnungsnummer(jahr: number, zufall: () => string): string {
  return `INV-${jahr}-${zufall().slice(0, 6).toUpperCase()}`;
}

const standardZufall = () =>
  (crypto.randomUUID?.() ?? Math.random().toString(36).slice(2)).replace(/-/g, '');

// --------------------------------------------------------- Erfassen
export type NeuesMitglied = {
  firstName: string;
  lastName: string;
  neighborhoodId: string;
  email?: string;
  phone?: string;
  street?: string;
  zip?: string;
  city?: string;
  country?: string;
  birthdate?: string;
  membershipCategory?: string;
  billingGroup?: string;
  invoiceDeliveryMethod?: 'EMAIL' | 'POST' | 'BOTH';
  // Willkommensnachricht einreihen? Ausdruecklich und nicht als
  // Vorgabe: wer einen Altbestand nachtraegt, will keine 300 Briefe
  // ausloesen. Der Wizard fragt danach.
  willkommen?: boolean;
};

// Hat diese Adresse schon jemand?
//
// users.email ist GLOBAL eindeutig, nicht je Verein -- gemessen:
// UNIQUE (email) auf public.users, ohne tenantId. Ein zweiter Eintrag
// mit derselben Adresse scheitert darum mit 23505, und der Rohtext
// "duplicate key value violates unique constraint users_email_key"
// sagt niemandem, was zu tun ist.
//
// Die Vorabsuche findet den haeufigen Fall: die Person ist im eigenen
// Verein schon erfasst. Liegt die Adresse bei einem ANDEREN Verein,
// findet sie nichts -- die Leseregel laesst fremde Zeilen nicht
// durch -- und dann traegt die uebersetzte Fehlermeldung unten.
export async function mitgliedMitAdresse(
  email: string,
): Promise<{ id: string; displayName: string } | null> {
  const adresse = email.trim().toLowerCase();
  if (!adresse) return null;
  const { supabase } = await import('@/services/supabase-bridge');
  const { data } = await supabase
    .from('users')
    .select('id,"displayName"')
    .ilike('email', adresse)
    .limit(1);
  const z = (data as any[])?.[0];
  return z ? { id: z.id, displayName: z.displayName || z.id } : null;
}

// Die Rohmeldung von PostgreSQL in einen Satz verwandeln, mit dem man
// etwas anfangen kann.
export function fehlerKlartext(meldung: string): string {
  const m = String(meldung ?? '');
  if (/users_email_key|users_email_partial_key/.test(m)) {
    return 'Diese E-Mail-Adresse ist bereits vergeben. Jede Adresse darf nur '
      + 'einmal vorkommen — auch über Vereine hinweg. Bitte die bestehende '
      + 'Person bearbeiten oder eine andere Adresse verwenden.';
  }
  if (/users_auth_user_id_key/.test(m)) {
    return 'Dieses Anmeldekonto ist bereits mit einem anderen Mitglied verbunden.';
  }
  if (/duplicate key value/.test(m)) {
    return `Dieser Eintrag gibt es schon (${m.match(/constraint "([^"]+)"/)?.[1] ?? 'doppelt'}).`;
  }
  return m;
}

export function mitgliedPruefen(e: NeuesMitglied): string | null {
  if (!e.firstName?.trim() || !e.lastName?.trim()) return 'name';
  // Ohne Nachbarschaft gehoert das Mitglied niemandem: es erscheint in
  // keiner Betreuungsliste und in keiner Nachbarschaftsauswertung. 325
  // von 333 haben eine -- die acht ohne sind genau die, die immer
  // wieder auffallen.
  if (!e.neighborhoodId?.trim()) return 'neighborhood';
  if (e.email?.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e.email.trim())) return 'email';
  return null;
}

export async function mitgliedErfassen(e: NeuesMitglied): Promise<string> {
  const fehlt = mitgliedPruefen(e);
  if (fehlt) throw new Error(`unvollstaendig:${fehlt}`);

  const { addDoc, collection, serverTimestamp, db } = await schreiben();
  const vorname = e.firstName.trim();
  const nachname = e.lastName.trim();
  let angelegt: { id: string };
  try {
    angelegt = await addDoc(collection(db, 'users'), {
    firstName: vorname,
    lastName: nachname,
    displayName: `${vorname} ${nachname}`,
    neighborhoodId: e.neighborhoodId.trim(),
    // Rolle und Status ausdruecklich, nicht per Vorgabe der Spalte: wer
    // hier erfasst wird, ist ein gewoehnliches Mitglied. Ein Vorstand
    // soll ueber diesen Weg keinen zweiten Vorstand anlegen koennen --
    // die Rollenvergabe hat ihren eigenen Ort und ihre eigene Pruefung.
    role: 'MEMBER',
    membershipStatus: 'ACTIVE',
    email: e.email?.trim() || null,
    phone: e.phone?.trim() || null,
    street: e.street?.trim() || null,
    zip: e.zip?.trim() || null,
    city: e.city?.trim() || null,
    country: e.country?.trim() || 'Switzerland',
    // Die Adresszeile wird mitgefuehrt, weil beide Spalten in den Daten
    // dasselbe enthalten und Auswertungen auf address zugreifen.
    address: e.street?.trim() || null,
    birthdate: e.birthdate?.trim() || null,
    membershipCategory: e.membershipCategory?.trim() || null,
    billingGroup: e.billingGroup?.trim() || null,
    invoiceDeliveryMethod: e.invoiceDeliveryMethod || null,
    timestamp: serverTimestamp(),
    });
  } catch (err: any) {
    // Die Rohmeldung der Datenbank hilft niemandem weiter.
    throw new Error(fehlerKlartext(err?.message ?? String(err)));
  }
  const id = angelegt.id;

  // Die Nachricht wird EINGEREIHT, nicht verschickt -- den Versand macht
  // der Postausgang. Scheitert das Einreihen, ist das Mitglied trotzdem
  // erfasst: eine missglueckte Begruessung darf keine Aufnahme
  // rueckgaengig machen.
  if (e.willkommen) {
    try {
      const { supabase } = await import('@/services/supabase-bridge');
      const { error } = await supabase.rpc('willkommen_einreihen', { p_member: id });
      if (error) console.error('[erfassen] Willkommensnachricht:', error.message);
    } catch (err) {
      console.error('[erfassen] Willkommensnachricht:', err);
    }
  }

  return id;
}

export type NeueRechnung = {
  mitglied: Partial<UserProfile> & { id: string };
  amount: number;
  description: string;
  dueDate: string;
  billingYear: number;
  invoiceType?: 'MEMBERSHIP' | 'OTHER';
  currency?: string;
};

export function rechnungPruefen(e: NeueRechnung): string | null {
  if (!e.mitglied?.id) return 'member';
  if (!Number.isFinite(e.amount) || e.amount <= 0) return 'amount';
  if (!e.description?.trim()) return 'description';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(e.dueDate ?? '')) return 'due';
  if (!Number.isInteger(e.billingYear) || e.billingYear < 2000) return 'year';
  return null;
}

export async function rechnungErfassen(
  e: NeueRechnung,
  zufall: () => string = standardZufall,
): Promise<{ id: string; invoiceNumber: string; deliveryMethod: string }> {
  const fehlt = rechnungPruefen(e);
  if (fehlt) throw new Error(`unvollstaendig:${fehlt}`);

  const { addDoc, collection, serverTimestamp, db } = await schreiben();
  const nummer = rechnungsnummer(e.billingYear, zufall);
  const weg = zustellweg(e.mitglied);
  const { id } = await addDoc(collection(db, 'payments'), {
    userId: e.mitglied.id,
    neighborhoodId: (e.mitglied as any).neighborhoodId ?? null,
    amount: e.amount,
    currency: e.currency || 'CHF',
    type: 'FEE',
    invoiceType: e.invoiceType || 'MEMBERSHIP',
    // Das Beitragsjahr fehlte im Adminweg. Ohne es faellt die Rechnung
    // aus der Jahresauswertung -- billingYearOf greift dann auf den
    // Zeitstempel zurueck, und eine im Januar gestellte Rechnung fuers
    // Vorjahr landet im falschen Jahr.
    billingYear: e.billingYear,
    description: e.description.trim(),
    dueDate: e.dueDate,
    status: 'PENDING',
    method: zahlungsart(e.mitglied),
    deliveryMethod: weg,
    invoiceNumber: nummer,
    dunningLevel: 0,
    timestamp: serverTimestamp(),
  });
  return { id, invoiceNumber: nummer, deliveryMethod: weg };
}
