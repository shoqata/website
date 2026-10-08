import { supabase } from '@/services/supabase-bridge';
import { sendEmail } from '../services/mailService';
import { hasUsableEmail } from './memberEmail';
import { textwerkLaden, textFuer, alsHtml, sprachenFuer, type Textwerk } from './textbaustein';

// Eine Mahnung verschicken -- an genau einer Stelle.
//
// Vorher stand das in AdminFinance, und die Floky-Karte haette es
// nachgebaut. Zwei Fassungen desselben Vorgangs laufen auseinander: die
// eine lernt die Sprache des Mitglieds, die andere nicht; die eine hebt die
// Mahnstufe erst nach erfolgreichem Versand, die andere davor. Deshalb
// liegt der Vorgang hier und wird von beiden gerufen.
//
// Reihenfolge ist Absicht: erst schreiben, dann merken. Eine Mahnstufe zu
// erhoehen, ohne dass der Brief hinausging, ist derselbe Fehler wie gar
// nicht zu verschicken -- nur stiller.

export type Mahnergebnis = { stufe: number; empfaenger: string; sprachen: string[] };

export async function mahnungSenden(
  zahlung: any,
  mitglied: any | null | undefined,
  verein: string,
  werkVorab?: Textwerk,
): Promise<Mahnergebnis> {
  const stufe = (zahlung.dunningLevel || 0) + 1;
  const email = mitglied?.email || zahlung.customRecipient?.email || '';
  const name = mitglied?.displayName || zahlung.customRecipient?.name || '';

  if (!hasUsableEmail({ email } as any)) {
    throw new Error('Für dieses Mitglied ist keine brauchbare E-Mail-Adresse hinterlegt.');
  }

  const werk = werkVorab ?? await textwerkLaden();
  const schluessel = stufe >= 2 ? 'MAHNUNG_2' : 'MAHNUNG_1';
  const frist = new Date(Date.now() + 14 * 864e5).toLocaleDateString('de-CH');
  const gebaut = textFuer(werk, schluessel, sprachenFuer(mitglied), {
    anrede: name,
    verein,
    jahr: zahlung.billingYear ?? new Date().getFullYear(),
    betrag: `${zahlung.currency || 'CHF'} ${Number(zahlung.amount || 0).toFixed(2)}`,
    frist,
  });

  // Lieber nichts verschicken als einen leeren Brief. Der Verein sieht,
  // woran es liegt, und kann es beheben.
  if (!gebaut) {
    throw new Error(`Kein Textbaustein „${schluessel}" hinterlegt — `
      + 'unter Einstellungen → Texte und Begriffe anlegen.');
  }

  await sendEmail({ to: email, subject: gebaut.betreff, html: alsHtml(gebaut.text) });

  const { data, error } = await supabase.from('payments').update({
    status: 'OVERDUE', dunningLevel: stufe, lastDunningDate: new Date().toISOString(),
  }).eq('id', zahlung.id).select('id');
  if (error) throw new Error(error.message);
  // Ein UPDATE ohne Treffer wirft keinen Fehler. Der Brief ist dann aber
  // draussen -- das muss der Verein erfahren, sonst mahnt er morgen erneut.
  if (!data || data.length === 0) {
    throw new Error(`Die Mahnung ging an ${email}, aber die Mahnstufe liess sich `
      + 'nicht erhöhen — fehlende Berechtigung?');
  }

  return { stufe, empfaenger: email, sprachen: gebaut.sprachen };
}
