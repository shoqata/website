import { supabase } from '@/services/supabase-bridge';
import { mahnungSenden } from './mahnung';

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
      // Auch hier hat id keinen Vorgabewert. Die Buchhaltungsmaske geht
      // ueber addDoc, das die Kennung erzeugt -- hier muss sie mit.
      id: crypto.randomUUID(),
      date: alsDatum(w.datum), description: String(w.text || ''),
      debitCode: String(w.soll), creditCode: String(w.haben), amount: betrag,
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data || data.length === 0) throw new Error('Nicht gebucht — fehlende Berechtigung?');
    return 'Gebucht.';
  }

  if (k.art === 'mahnung_vorschlagen') {
    if (!w.rechnung_id) throw new Error('Der Karte fehlt die Rechnung.');
    // Die Werte werden hier NEU gelesen, nicht von der Karte uebernommen.
    // Was auf der Karte stand, war zur Anzeige da; was verschickt wird,
    // richtet sich nach dem, was jetzt in der Datenbank steht.
    const { data: z, error: e1 } = await supabase.from('payments')
      .select('*').eq('id', String(w.rechnung_id)).maybeSingle();
    if (e1) throw new Error(e1.message);
    if (!z) throw new Error('Diese Rechnung gibt es nicht mehr.');
    if (z.status === 'PAID') throw new Error('Diese Rechnung ist inzwischen bezahlt.');

    const { data: m } = await supabase.from('users')
      .select('id,displayName,email,sprache').eq('id', z.userId).maybeSingle();
    const { data: marke } = await supabase.from('settings')
      .select('data').eq('id', 'branding').maybeSingle();
    const verein = (marke?.data as any)?.associationName || '';

    const r = await mahnungSenden(z, m, typeof verein === 'string' ? verein
      : (verein?.de || verein?.sq || verein?.en || ''));
    return `Mahnung ${r.stufe} an ${r.empfaenger} verschickt (${r.sprachen.join('/')}).`;
  }

  if (k.art === 'text_entwerfen') {
    if (!w.titel || !w.text) throw new Error('Der Karte fehlt Titel oder Text.');
    // Ausdruecklich DRAFT. Floky veroeffentlicht nichts -- auch nicht,
    // wenn jemand die Karte bestaetigt: bestaetigt wurde ein Entwurf.
    // news.id hat keinen Vorgabewert -- ohne Kennung schlaegt das Einfuegen
    // fehl. Die Bruecke erzeugt sie in addDoc genauso.
    const { data, error } = await supabase.from('news').insert({
      id: crypto.randomUUID(),
      title: String(w.titel), content: String(w.text),
      status: 'DRAFT', timestamp: new Date().toISOString(),
      author: 'Floky (Entwurf)',
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data || data.length === 0) throw new Error('Nicht abgelegt — fehlende Berechtigung?');
    return 'Als Entwurf abgelegt. Unter Webseite → Neuigkeiten freigeben.';
  }

  if (k.art === 'mitglied_erfassen') {
    if (!w.vorname || !w.nachname) throw new Error('Der Karte fehlt der Name.');
    const email = String(w.email || '').trim().toLowerCase();

    // users.email ist eindeutig (users_email_key). Ohne diese Pruefung
    // scheiterte das Einfuegen mit einem Datenbankfehler, den niemand
    // liest -- und der Verein wuesste nicht, dass die Person schon da ist.
    if (email) {
      const { data: schon } = await supabase.from('users')
        .select('id,displayName').eq('email', email).maybeSingle();
      if (schon) {
        throw new Error(`Diese E-Mail gehört bereits zu „${schon.displayName}". `
          + 'Bitte dort ändern statt ein zweites Mitglied anzulegen.');
      }
    }

    let lagje: string | null = null;
    if (w.nachbarschaft) {
      const { data: n } = await supabase.from('neighborhoods')
        .select('id').ilike('name', String(w.nachbarschaft)).maybeSingle();
      lagje = n?.id ?? null;
    }

    const { data, error } = await supabase.from('users').insert({
      id: crypto.randomUUID(),
      firstName: String(w.vorname), lastName: String(w.nachname),
      displayName: `${w.vorname} ${w.nachname}`.trim(),
      email: email || null, phone: w.telefon || null,
      street: w.strasse || null, zip: w.plz || null, city: w.ort || null,
      membershipCategory: w.kategorie || null, billingGroup: w.beitragsgruppe || 'STANDARD',
      neighborhoodId: lagje, sprache: w.sprache || null,
      // Ausdruecklich gesetzt, nicht dem Zufall ueberlassen: ein neues
      // Mitglied ist ein Mitglied, kein Vorstand, und es bekommt KEIN
      // Konto -- das vergibt die Verwaltung eigens.
      role: 'MEMBER', membershipStatus: 'ACTIVE',
      joinedAt: new Date().toISOString().slice(0, 10),
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data?.length) throw new Error('Nicht angelegt — fehlende Berechtigung?');
    return `${w.vorname} ${w.nachname} ist aufgenommen. Ein Zugang wurde nicht erstellt.`;
  }

  if (k.art === 'anlass_anlegen') {
    if (!w.titel || !w.datum) throw new Error('Der Karte fehlt Titel oder Datum.');
    const { data, error } = await supabase.from('events').insert({
      id: crypto.randomUUID(),
      title: String(w.titel), date: alsDatum(w.datum), time: w.zeit || null,
      location: w.ort || null, description: w.beschreibung || null,
      isRegistrable: !!w.anmeldung, status: 'DRAFT',
      createdAt: new Date().toISOString(),
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data?.length) throw new Error('Nicht angelegt — fehlende Berechtigung?');
    return 'Als Entwurf angelegt. Unter Anlässe freigeben.';
  }

  if (k.art === 'spendenaufruf_entwerfen') {
    if (!w.titel || !w.text) throw new Error('Der Karte fehlt Titel oder Text.');
    const { data, error } = await supabase.from('spendenaufrufe').insert({
      titel: String(w.titel), text: String(w.text),
      ziel_betrag: w.zielbetrag ? Number(w.zielbetrag) : null,
      endet_am: w.endet_am ? alsDatum(w.endet_am) : null,
      status: 'ENTWURF',
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data?.length) throw new Error('Nicht abgelegt — fehlende Berechtigung?');
    return 'Als Entwurf abgelegt. Unter Spenden freigeben.';
  }

  if (k.art === 'protokoll_entwerfen') {
    if (!w.titel) throw new Error('Der Karte fehlt der Titel.');
    // Die Form von agendaItems und decisions ist vorgegeben; gemessen an
    // bestehenden Sitzungen: {id, title, content, dueDate, responsible,
    // linkedTaskIds}. Eine eigene Form haette die Maske nicht gelesen.
    const posten = (liste: any[], mitFrist: boolean) =>
      (Array.isArray(liste) ? liste : []).map((x: any) => ({
        id: crypto.randomUUID().slice(0, 9),
        title: String(x.titel ?? ''), content: String(x.inhalt ?? ''),
        dueDate: mitFrist ? String(x.frist ?? '') : '',
        responsible: mitFrist ? String(x.zustaendig ?? '') : '',
        linkedTaskIds: [],
      })).filter((x: any) => x.title);

    const { data, error } = await supabase.from('board_meetings').insert({
      id: crypto.randomUUID(),
      title: String(w.titel),
      date: alsDatum(w.datum), location: w.ort || null,
      agendaItems: posten(w.traktanden, false),
      decisions: posten(w.beschluesse, true),
      status: 'PLANNED', createdAt: new Date().toISOString(),
    }).select('id');
    if (error) throw new Error(error.message);
    if (!data?.length) throw new Error('Nicht abgelegt — fehlende Berechtigung?');
    return 'Sitzung als Entwurf abgelegt. Unter Vorstand öffnen und ergänzen.';
  }

  throw new Error(`Unbekannte Karte: ${k.art}`);
}
