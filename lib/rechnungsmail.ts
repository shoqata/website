import { Payment } from '../types';
import { istSchweiz } from '../services/qrBillService';
import { erzeugeRechnungPdf } from './rechnungpdf';

// Die Rechnungsmail: Betreff, Text und die Rechnung als PDF.
//
// Stand bis zum 22.10.2026 in AdminFinance. Seit auch der Verantwortliche
// einer Nachbarschaft eine Rechnung weiterleiten kann, braucht es sie an
// zwei Stellen -- und zwei Fassungen derselben Rechnung laufen frueher
// oder spaeter auseinander: andere Zahlungsangaben, ein anderer Betreff,
// beim Mitglied zwei verschiedene Rechnungen fuer denselben Beitrag.
//
// Verschickt wird hier nichts. Wer die Mail baut, entscheidet auch, auf
// welchem Weg sie hinausgeht: der Vorstand direkt in die Warteschlange,
// der Verantwortliche ueber vertreter_rechnung_senden(), das den
// Empfaenger selbst bestimmt.

export type Anschrift = { adresse?: string; plz?: string; ort?: string; land?: string };

export async function rechnungsmailBauen(a: {
  payment: Payment;
  recipientName: string;
  anschrift: Anschrift;
  paymentSettings: any;
  association: string;
  t: (k: string, p?: any) => string;
}): Promise<{ subject: string; html: string; anhaenge: { filename: string; content: string }[] }> {
  const { payment, recipientName, anschrift, paymentSettings, association, t } = a;
  const subject = t('mail.invoice.subject', { number: payment.invoiceNumber || '', association });

  const bankRows = (iban: string) =>
      `<p><strong>${t('field.bank')}:</strong> ${paymentSettings.bankName}<br/>` +
      `<strong>${t('field.account_holder')}:</strong> ${paymentSettings.accountHolder}<br/>` +
      `<strong>${t('field.iban')}:</strong> ${iban}<br/>` +
      `${payment.reference ? `<strong>${t('field.reference')}:</strong> ${payment.reference}<br/>` : ''}</p>`;

  // Nicht mehr nach payment.method verzweigen, sondern nach dem
  // Wohnsitz: eine Schweizer QR-Rechnung kann eine auslaendische
  // Bank nicht lesen, und umgekehrt braucht in der Schweiz
  // niemand PayPal, wenn der QR danebensteht.
  const wohntInCh = istSchweiz(anschrift.land);

  let paymentInfoHtml = '';
  if (wohntInCh) {
      paymentInfoHtml = `
          <h3>${t('mail.pay.bank_qr')}</h3>
          ${bankRows(paymentSettings.qrIban || paymentSettings.iban)}
          ${paymentSettings.twintNumber ? `
          <div style="margin-top: 20px; padding: 15px; background-color: #f0f0f0; border-radius: 8px;">
              <h4 style="margin-top: 0;">${t('mail.pay.twint_title')}</h4>
              <p>${t('mail.pay.twint_intro')} <strong>${paymentSettings.twintNumber}</strong></p>
              ${paymentSettings.twintUrl ? `<p><a href="${paymentSettings.twintUrl}" style="display: inline-block; padding: 10px 20px; background-color: #000; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold;">${t('mail.pay.twint_button')}</a></p>` : ''}
          </div>` : ''}
      `;
  } else {
      // Ausserhalb der Schweiz: Bankverbindung und PayPal. Eine
      // QR-Rechnung nuetzt dort niemandem.
      paymentInfoHtml = `
          <h3>${t('mail.pay.sepa')}</h3>
          <p><strong>${t('field.bank')}:</strong> ${paymentSettings.bankName}<br/>
          <strong>${t('field.account_holder')}:</strong> ${paymentSettings.accountHolder}<br/>
          <strong>${t('field.iban')}:</strong> ${paymentSettings.iban}<br/>
          <strong>${t('field.bic')}:</strong> ${paymentSettings.bic || t('field.not_specified')}<br/>
          <strong>${t('field.purpose')}:</strong> ${payment.invoiceNumber}</p>
          ${paymentSettings.paypalEmail ? `
          <div style="margin-top: 20px; padding: 15px; background-color: #f0f0f0; border-radius: 8px;">
              <h4 style="margin-top: 0;">${t('mail.pay.paypal')}</h4>
              <p>${t('mail.pay.paypal_intro')} <strong>${paymentSettings.paypalEmail}</strong></p>
              <p>${t('mail.pay.paypal_reference')} <strong>${payment.invoiceNumber}</strong></p>
          </div>` : ''}
      `;
  }

  const html = `
      <div style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
          <h2>${t('mail.invoice.heading')}</h2>
          <p>${t('mail.invoice.greeting')} <strong>${recipientName}</strong>,</p>
          <p>${t('mail.invoice.intro')}</p>
          <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; border: 1px solid #eee; margin: 20px 0;">
              <table style="width: 100%;">
                  <tr><td style="padding: 5px 0;"><strong>${t('mail.invoice.number')}:</strong></td><td style="text-align: right;">${payment.invoiceNumber}</td></tr>
                  <tr><td style="padding: 5px 0;"><strong>${t('field.description')}:</strong></td><td style="text-align: right;">${payment.description}</td></tr>
                  <tr><td style="padding: 5px 0;"><strong>${t('field.amount')}:</strong></td><td style="text-align: right; font-size: 1.2em; font-weight: bold;">${payment.amount.toFixed(2)} ${payment.currency}</td></tr>
                  <tr><td style="padding: 5px 0;"><strong>${t('mail.invoice.due')}:</strong></td><td style="text-align: right;">${payment.dueDate || t('mail.invoice.due_immediate')}</td></tr>
              </table>
          </div>
          ${paymentInfoHtml}
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;"/>
          <p style="font-size: 0.9em; color: #666;">${t('mail.invoice.thanks')}</p>
      </div>
  `;
  // Die Rechnung als Datei, nicht nur als Mailtext: zum Ablegen,
  // zum Weitergeben, zum Ausdrucken. Scheitert das PDF, geht die
  // Mail trotzdem hinaus -- eine Rechnung ohne Anhang ist
  // aergerlich, eine nicht verschickte ist schlimmer.
  let anhaenge: { filename: string; content: string }[] = [];
  try {
      const pdf = await erzeugeRechnungPdf({
          nummer: payment.invoiceNumber || '',
          datum: (payment as any).issuedAt || new Date().toISOString(),
          faellig: payment.dueDate || null,
          betrag: Number(payment.amount || 0),
          waehrung: (payment.currency as 'CHF' | 'EUR') || 'CHF',
          zweck: payment.description || '',
          // Ohne Referenz leitet referenzBestimmen() aus den
          // Ziffern ab -- bei leerer Referenz also fuer JEDE
          // Rechnung dieselbe Nummer, und keine Zahlung liesse
          // sich mehr zuordnen. Die Rechnungsnummer ist je
          // Rechnung verschieden und damit der richtige Rueckfall.
          referenz: payment.reference || payment.invoiceNumber || undefined,
          verein: {
              name: paymentSettings.accountHolder || association,
              adresse: paymentSettings.street, plz: paymentSettings.zip,
              ort: paymentSettings.city, land: paymentSettings.country,
              iban: paymentSettings.iban, qrIban: paymentSettings.qrIban,
              bic: paymentSettings.bic, bank: paymentSettings.bankName,
              paypal: paymentSettings.paypalEmail, twint: paymentSettings.twintNumber,
          },
          empfaenger: {
              name: recipientName, adresse: anschrift.adresse,
              plz: anschrift.plz, ort: anschrift.ort, land: anschrift.land,
          },
      });
      anhaenge = [{ filename: pdf.dateiname, content: pdf.base64 }];
  } catch (e) {
      console.warn('[Rechnung] PDF nicht erzeugt, Mail geht ohne Anhang:', e);
  }

  return { subject, html, anhaenge };
}
