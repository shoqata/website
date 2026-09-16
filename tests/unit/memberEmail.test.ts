import { describe, it, expect } from 'vitest';
import {
  isPlaceholderEmail,
  looksLikeEmail,
  hasUsableEmail,
  deliveryNeedsEmail,
  emailMissingForDelivery,
} from '../../lib/memberEmail';

describe('Ersatzadressen aus dem Datenimport', () => {
  it('erkennt die Form aus dem Import als keine Adresse', () => {
    // Genau die Form, die beim Uebernehmen der alten Liste vergeben wurde.
    expect(isPlaceholderEmail('.no-email-55840024@koretini.legacy')).toBe(true);
    expect(isPlaceholderEmail('filan.fisteku.no-email-1712@koretini.legacy')).toBe(true);
  });

  it('erkennt die Altbestands-Domain unabhaengig vom Namensteil', () => {
    expect(isPlaceholderEmail('irgendwer@koretini.legacy')).toBe(true);
    expect(isPlaceholderEmail('IRGENDWER@KORETINI.LEGACY')).toBe(true);
  });

  it('behandelt eine fehlende Adresse wie eine Ersatzadresse', () => {
    expect(isPlaceholderEmail(undefined)).toBe(true);
    expect(isPlaceholderEmail('')).toBe(true);
    expect(isPlaceholderEmail('   ')).toBe(true);
  });

  it('laesst echte Adressen in Ruhe', () => {
    expect(isPlaceholderEmail('anna@beispiel.ch')).toBe(false);
    expect(isPlaceholderEmail('a.b@verein-koretini.ch')).toBe(false);
  });
});

describe('Form einer Adresse', () => {
  it('verlangt Klammeraffe und Punkt in der Domain', () => {
    expect(looksLikeEmail('anna@beispiel.ch')).toBe(true);
    expect(looksLikeEmail('anna(at)beispiel.ch')).toBe(false);
    expect(looksLikeEmail('anna@beispiel')).toBe(false);
    expect(looksLikeEmail('anna @ beispiel.ch')).toBe(false);
  });
});

describe('brauchbare Adresse', () => {
  it('ist brauchbar, wenn sie echt ist und wie eine Adresse aussieht', () => {
    expect(hasUsableEmail({ email: 'anna@beispiel.ch' })).toBe(true);
  });

  it('ist unbrauchbar bei Ersatzadresse, leer oder kaputter Form', () => {
    expect(hasUsableEmail({ email: '.no-email-55840024@koretini.legacy' })).toBe(false);
    expect(hasUsableEmail({ email: '' })).toBe(false);
    expect(hasUsableEmail({ email: 'kaputt' })).toBe(false);
    expect(hasUsableEmail(undefined)).toBe(false);
  });
});

describe('E-Mail-Pflicht beim Rechnungsversand', () => {
  it('verlangt eine Adresse bei Versandart E-Mail', () => {
    expect(deliveryNeedsEmail({ invoiceDeliveryMethod: 'EMAIL' })).toBe(true);
  });

  it('verlangt eine Adresse auch bei "beides"', () => {
    // Wer Post *und* E-Mail gewaehlt hat, erwartet die E-Mail.
    expect(deliveryNeedsEmail({ invoiceDeliveryMethod: 'BOTH' })).toBe(true);
  });

  it('verlangt keine Adresse bei reinem Postversand', () => {
    expect(deliveryNeedsEmail({ invoiceDeliveryMethod: 'POST' })).toBe(false);
  });

  it('meldet den Konflikt: E-Mail-Versand ohne brauchbare Adresse', () => {
    expect(emailMissingForDelivery({
      invoiceDeliveryMethod: 'EMAIL',
      email: '.no-email-55840024@koretini.legacy',
    })).toBe(true);

    expect(emailMissingForDelivery({ invoiceDeliveryMethod: 'EMAIL', email: '' })).toBe(true);
    expect(emailMissingForDelivery({ invoiceDeliveryMethod: 'BOTH', email: undefined })).toBe(true);
  });

  it('meldet keinen Konflikt, wenn die Adresse taugt', () => {
    expect(emailMissingForDelivery({
      invoiceDeliveryMethod: 'EMAIL',
      email: 'anna@beispiel.ch',
    })).toBe(false);
  });

  it('meldet keinen Konflikt bei Postversand ohne Adresse', () => {
    // Ohne E-Mail-Versand ist eine fehlende Adresse kein Hindernis.
    expect(emailMissingForDelivery({ invoiceDeliveryMethod: 'POST', email: '' })).toBe(false);
  });
});
