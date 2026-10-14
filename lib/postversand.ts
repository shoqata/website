import type { RechnungDaten } from './rechnungpdf';

// Eine Rechnung per Post aufgeben.
//
// Die Kette ist: PDF bauen -> post_einreihen -> der Arbeiter
// pingen-versand holt sich die wartenden Briefe und gibt sie bei Pingen
// auf. Hier steht nur das Einreihen; aufgegeben wird nicht von Hand,
// damit ein abgebrochener Klick keinen halb aufgegebenen Brief
// hinterlaesst.
//
// Die offene Frage ist der Zahlungsteil.
//
// Pingen erzeugt den Swiss-QR-Teil fuer Postrechnungen selbst -- so hat
// es der Betreiber von Pingen mitgeteilt. Dann duerfen wir ihn nicht
// auch zeichnen: zwei Zahlungsteile auf einem Blatt sind schlimmer als
// einer, weil beide gescannt werden koennen und einer zur falschen
// Referenz fuehrt.
//
// Nur: in der Briefschnittstelle des SDK gibt es kein Feld dafuer. Ohne
// dieses Feld hiesse "Pingen macht den QR" in Wahrheit "niemand macht
// den QR" -- und dann ginge eine Rechnung hinaus, die man nicht
// bezahlen kann. Das ist der schlimmste der drei moeglichen Zustaende,
// schlimmer als zwei QR und schlimmer als ein ungewollt selbst
// gezeichneter.
//
// Darum steht der Schalter hier auf SELBST, bis das Feld dokumentiert
// und eingebaut ist, und PINGEN wird abgelehnt statt stillschweigend zu
// SELBST zu werden. Wer den Schalter umlegen will, muss zuerst
// PINGEN_ZAHLUNGSTEIL_FERTIG umstellen -- und das geht erst, wenn die
// Uebergabe wirklich gebaut ist.

export type Zahlungsteil = 'SELBST' | 'PINGEN';

// Steht auf false, solange die Uebergabe der Zahlungsangaben an Pingen
// nicht gebaut ist. Eine einzige Stelle, damit es nicht an drei Orten
// halb umgestellt wird.
export const PINGEN_ZAHLUNGSTEIL_FERTIG = false;

export type Entscheidung = {
  weg: Zahlungsteil;
  ohneZahlungsteil: boolean;
  hinweis: string;
};

export function zahlungsteilEntscheiden(gewuenscht?: Zahlungsteil | null): Entscheidung {
  if (gewuenscht === 'PINGEN' && !PINGEN_ZAHLUNGSTEIL_FERTIG) {
    throw new Error(
      'Der Zahlungsteil kann noch nicht an Pingen uebergeben werden: das Feld '
      + 'dafuer ist in der Briefschnittstelle nicht dokumentiert. Bis dahin '
      + 'zeichnet die Rechnung den Swiss QR selbst.');
  }
  if (gewuenscht === 'PINGEN') {
    return { weg: 'PINGEN', ohneZahlungsteil: true,
             hinweis: 'Pingen fuegt den Zahlungsteil an.' };
  }
  return { weg: 'SELBST', ohneZahlungsteil: false,
           hinweis: 'Die Rechnung traegt den Zahlungsteil selbst.' };
}

// Kann man diese Rechnung ueberhaupt bezahlen?
//
// Die Regel stand schon einmal da -- als zahlwegFehlt() mitten in
// AdminFinance, nur fuer den Mailversand. Sie ist jetzt hier, weil der
// Postversand sie genauso braucht und eine zweite Fassung der Regel
// bedeutet, dass eine der beiden irgendwann milder wird.
//
// Streng ist sie an einer Stelle, die leicht untergeht: zur Swiss-QR-
// Rechnung gehoert der Kontoinhaber. Ohne ihn ist der Beleg nach der
// Spezifikation unvollstaendig, und Banken weisen ihn zurueck. Eine
// Bankadresse oder eine BIC allein genuegt dagegen nicht -- ohne IBAN
// kann niemand ueberweisen.
//
// Das ist kein erfundener Fall: heute hat eine falsch gelesene Spalte
// dazu gefuehrt, dass Mahnungen ohne IBAN hinausgingen. Beim Brief
// kostet das zweimal Geld -- den Versand und die Mahnung danach.
export function zahlungsangabenPruefen(
  verein: RechnungDaten['verein'] | null | undefined,
): { ok: boolean; grund?: string } {
  const hat = (v?: string | null) => String(v ?? '').trim() !== '';
  if (hat(verein?.qrIban) || hat(verein?.iban)) {
    if (!hat(verein?.name)) {
      return { ok: false, grund:
        'Der Kontoinhaber fehlt. Zur Swiss-QR-Rechnung gehoert er dazu; '
        + 'ohne ihn ist der Beleg unvollstaendig. Er steht unter Finanzen, '
        + 'Einstellungen.' };
    }
    return { ok: true };
  }
  if (hat(verein?.paypal) || hat(verein?.twint)) return { ok: true };
  return { ok: false, grund:
    'Es ist keine Zahlungsverbindung hinterlegt (IBAN, PayPal oder TWINT). '
    + 'Eine Rechnung ohne Zahlungsverbindung kann niemand bezahlen; die '
    + 'Angaben stehen unter Finanzen, Einstellungen.' };
}

// Die Antwort von post_einreihen lesen.
//
// Die Funktion wirft NICHT, wenn fuer diese Rechnung schon ein Brief
// erfasst ist -- sie antwortet mit eingereiht: false und einem Grund.
// Wer nur auf error prueft, meldet "Brief eingereiht" fuer einen Brief,
// den es schon gibt, und der Anwender denkt, er sei ein zweites Mal
// unterwegs. Darum wird hier die Antwort selbst gelesen und nicht nur
// die Abwesenheit eines Fehlers.
export function einreihAntwortLesen(data: any): { id: string } {
  if (!data || typeof data !== 'object') {
    throw new Error('Die Datenbank hat auf das Einreihen nicht geantwortet.');
  }
  if (data.eingereiht === false) {
    throw new Error(String(data.grund || 'Der Brief wurde nicht eingereiht.'));
  }
  if (data.eingereiht !== true || !data.id) {
    throw new Error('Das Einreihen hat keine Briefnummer geliefert.');
  }
  return { id: String(data.id) };
}

export type EinreihOptionen = {
  // cheap ist der Standard: B-Post. fast waere A-Post, bulk ab 500.
  produkt?: 'cheap' | 'fast' | 'bulk' | 'premium' | 'registered';
  farbe?: 'color' | 'grayscale';
  duplex?: boolean;
  adresslage?: 'left' | 'right';
  zahlungsteil?: Zahlungsteil | null;
};

export type Eingereiht = {
  id: string;
  dateiname: string;
  bytes: number;
  hinweis: string;
};

export async function briefEinreihen(
  paymentId: string,
  daten: RechnungDaten,
  o: EinreihOptionen = {},
): Promise<Eingereiht> {
  const e = zahlungsteilEntscheiden(o.zahlungsteil ?? null);

  // Vor dem PDF und vor dem Porto: traegt die Rechnung ueberhaupt
  // bezahlbare Angaben?
  if (e.weg === 'SELBST') {
    const z = zahlungsangabenPruefen(daten.verein);
    if (!z.ok) throw new Error(z.grund);
  }

  // Erst hier geladen, damit die Entscheidung oben ohne Datenbank und
  // ohne jsPDF geprueft werden kann.
  const { erzeugeRechnungPdf } = await import('./rechnungpdf');
  const { supabase } = await import('../services/supabase-bridge');

  const pdf = await erzeugeRechnungPdf({ ...daten, ohneZahlungsteil: e.ohneZahlungsteil });

  const { data, error } = await supabase.rpc('post_einreihen', {
    p_payment: paymentId,
    p_dateiname: pdf.dateiname,
    p_pdf: pdf.base64,
    p_produkt: o.produkt ?? 'cheap',
    p_farbe: o.farbe ?? 'grayscale',
    p_duplex: o.duplex ?? true,
    p_adresslage: o.adresslage ?? 'left',
  });
  if (error) throw new Error(error.message);

  const gelesen = einreihAntwortLesen(data);
  return {
    id: gelesen.id,
    dateiname: pdf.dateiname,
    bytes: pdf.bytes,
    hinweis: e.hinweis,
  };
}

// Den Arbeiter anstossen. Ohne das liegen die Briefe bis zum naechsten
// Lauf -- was in Ordnung ist, aber niemand will nach dem Klick nicht
// wissen, ob etwas passiert.
export async function postArbeiterAnstossen(menge = 10): Promise<any> {
  const { supabase } = await import('../services/supabase-bridge');
  const { data, error } = await supabase.functions.invoke('pingen-versand', {
    body: { menge },
  });
  if (error) throw new Error(error.message);
  return data;
}

// Nur nachsehen, ob der Zugang gilt -- gibt nichts auf.
export async function pingenZugangPruefen(): Promise<any> {
  const { supabase } = await import('../services/supabase-bridge');
  const { data, error } = await supabase.functions.invoke('pingen-versand', {
    body: { pruefen: true },
  });
  if (error) throw new Error(error.message);
  return data;
}
