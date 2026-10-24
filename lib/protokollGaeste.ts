import { supabase } from '@/services/supabase-bridge';

// Gaeste einer Vorstandssitzung -- fuer beide Protokoll-Editoren (Vorstand
// und Verwaltung).
//
// Der Name steht in attendees (guest: true), wie bei den Vorstands-
// mitgliedern. Die E-Mail steht NUR in board_meeting_guests: ein
// freigegebenes Protokoll lesen alle Mitglieder, diese Tabelle nur der
// Vorstand.

export type Gast = { vorname: string; nachname: string; email: string };

export const gastName = (g: Gast) => `${g.vorname.trim()} ${g.nachname.trim()}`.trim();

export const gastMailFalsch = (g: Gast) =>
  !!g.email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(g.email.trim());

export const gueltigeGaeste = (liste: Gast[]) => liste.filter(g => g.vorname.trim() || g.nachname.trim());

export async function gaesteLaden(meetingId: string): Promise<Gast[]> {
  const { data } = await supabase.from('board_meeting_guests')
    .select('vorname,nachname,email').eq('meetingId', meetingId).order('erstellt_am');
  return ((data as any[]) || []).map(g => ({ vorname: g.vorname || '', nachname: g.nachname || '', email: g.email || '' }));
}

// Die Liste ersetzen -- sie ist kurz, und Ersetzen laesst keinen Gast
// zurueck, der in der Maske entfernt wurde.
export async function gaesteSpeichern(meetingId: string, liste: Gast[]): Promise<void> {
  const weg = await supabase.from('board_meeting_guests').delete().eq('meetingId', meetingId);
  if (weg.error) throw weg.error;
  const g = gueltigeGaeste(liste);
  if (!g.length) return;
  const neu = await supabase.from('board_meeting_guests').insert(g.map(x => ({
    meetingId, vorname: x.vorname.trim(), nachname: x.nachname.trim(), email: x.email.trim() || null,
  })));
  if (neu.error) throw neu.error;
}

// Anwesenheitsliste mit den Gaesten: die alten Gast-Eintraege raus, die
// aktuellen rein -- damit kein Gast doppelt steht.
export function mitGaesten(attendees: any[] | undefined, liste: Gast[]): any[] {
  return [
    ...(attendees || []).filter((a: any) => !a.guest),
    ...gueltigeGaeste(liste).map(g => ({ userId: null, guest: true, role: 'Gast', present: true, name: gastName(g) })),
  ];
}
