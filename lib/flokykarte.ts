import { supabase } from '@/services/supabase-bridge';

// Eine bestaetigte Karte ausfuehren.
//
// Der Kern: hier wird NICHTS neu erfunden. Jede Karte laeuft durch genau die
// Funktion, die auch die Handarbeit benutzt -- mark_payment_paid,
// report_payment_paid, der Journaleintrag. Daraus folgt alles Weitere von
// selbst: Belegnummer, Buchungsprotokoll und Jahressperre gelten fuer eine
// Karte genau wie fuer einen Menschen, weil es dieselben Trigger sind.
//
// Eine eigene, schnellere Schreibroutine waere der Fehler gewesen: dann
// gaebe es zwei Wege in die Buchhaltung, und einer davon kaeme irgendwann
// an einer Pruefung vorbei.

export type Karte = {
  art: string; titel: string;
  felder: [string, string][];
  werte: Record<string, any>;
};

const alsDatum = (v: any): string => {
  const s = String(v ?? '').trim();
  if (!s) return new Date().toISOString().slice(0, 10);
  // TT.MM.JJJJ -> JJJJ-MM-TT
  const m = s.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`;
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10);
  return new Date().toISOString().slice(0, 10);
};

export async function karteAusfuehren(k: Karte): Promise<string> {
  const w = k.werte ?? {};

  if (k.art === 'zahlung_erfassen') {
    if (!w.rechnung_id) throw new Error('Der Karte fehlt die Rechnung.');
    const { error } = await supabase.rpc('mark_payment_paid', {
      p_payment: String(w.rechnung_id),
      p_method: String(w.weg || 'CASH'),
      p_paid_on: alsDatum(w.datum),
    });
    if (error) throw new Error(error.message);
    return 'Zahlung erfasst und verbucht.';
  }

  if (k.art === 'barzahlung_melden') {
    if (!w.rechnung_id) throw new Error('Der Karte fehlt die Rechnung.');
    const { error } = await supabase.rpc('report_payment_paid', {
      p_payment: String(w.rechnung_id), p_method: 'CASH',
      p_paid_on: alsDatum(w.datum), p_note: String(w.bemerkung || ''),
    });
    if (error) throw new Error(error.message);
    return 'Gemeldet. Die Vereinsverwaltung entscheidet.';
  }

  if (k.art === 'buchung_vorschlagen') {
    const betrag = Number(w.betrag);
    if (!w.soll || !w.haben) throw new Error('Der Karte fehlt ein Konto.');
    if (!Number.isFinite(betrag) || betrag <= 0) throw new Error('Der Betrag fehlt.');
    // Derselbe Einfuegeweg wie in der Buchhaltungsmaske. Die Jahressperre
    // sitzt als Trigger (geschlossenes_jahr_schuetzen) in der Datenbank und
    // greift hier ebenso -- sie im Browser noch einmal zu pruefen, hiesse
    // zwei Pruefungen zu fuehren, die auseinanderlaufen koennen.
    const { data, error } = await supabase.from('accounting_journal').insert({
      date: alsDatum(w.datum), description: String(w.text || ''),
      debitCode: String(w.soll), creditCode: String(w.haben), amount: betrag,
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data || data.length === 0) throw new Error('Nicht gebucht — fehlende Berechtigung?');
    return 'Gebucht.';
  }

  throw new Error(`Unbekannte Karte: ${k.art}`);
}
