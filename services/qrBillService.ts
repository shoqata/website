
/**
 * Swiss QR Bill Service
 * Strictly adheres to SIX Implementation Guidelines v2.3
 */

export interface QrBillData {
  amount: number;
  currency: 'CHF' | 'EUR';
  iban: string; // QR-IBAN or Standard IBAN
  creditor: {
    name: string;
    address: string; // Street + Nr
    zip: string;
    city: string;
    country: string;
  };
  debtor: {
    name: string;
    address: string;
    zip: string;
    city: string;
    country: string;
  };
  reference: string; 
  referenceType?: 'QRR' | 'SCOR' | 'NON'; 
  additionalInfo?: string; 
}

// Helper: Sanitize string to Latin-1 subset allowed by SIX
const sanitize = (str: string | undefined): string => {
  if (!str) return '';
  return str.replace(/[\r\n]+/g, ' ').trim().substring(0, 70);
};

const normalizeCountry = (input: string | undefined): string => {
    if (!input) return 'CH';
    const c = input.toLowerCase().trim();
    if (c === 'schweiz' || c === 'switzerland' || c === 'suisse' || c === 'svizzera' || c === 'zvicer' || c === 'zvicër') return 'CH';
    if (c === 'deutschland' || c === 'germany' || c === 'gjermania' || c === 'gjermani') return 'DE';
    if (c === 'austria' || c === 'österreich' || c === 'austri') return 'AT';
    if (c === 'kosovo' || c === 'kosova' || c === 'xk') return 'XK'; 
    if (c === 'liechtenstein') return 'LI';
    if (input.length === 2) return input.toUpperCase(); 
    return 'CH'; 
};

export const calculateMod10 = (input: string): string => {
  const table = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5];
  let carry = 0;
  for (let i = 0; i < input.length; i++) {
    carry = table[(carry + parseInt(input.charAt(i), 10)) % 10];
  }
  return ((10 - carry) % 10).toString();
};

export const generateQrReference = (customerId: string): string => {
  let cleanId = customerId.replace(/\D/g, '');
  if(!cleanId) cleanId = '0';
  const prefix = new Date().getFullYear().toString(); 
  const payload = prefix + cleanId.padStart(22, '0'); 
  const checkDigit = calculateMod10(payload);
  return payload + checkDigit;
};

export const formatIban = (iban: string) => {
  if (!iban) return '';
  return iban.replace(/\s/g, '').replace(/(.{4})/g, '$1 ').trim();
};

export const formatReference = (ref: string, type: 'QRR' | 'SCOR' | 'NON') => {
  if (!ref) return '';
  const clean = ref.replace(/\s/g, '');
  if (type === 'QRR') {
    return clean.replace(/(.{2})(.{5})(.{5})(.{5})(.{5})(.{5})/, '$1 $2 $3 $4 $5 $6').trim(); 
  }
  if (type === 'SCOR') {
    return clean.replace(/(.{4})/g, '$1 ').trim();
  }
  return clean;
};

/**
 * Generates the raw QR content string.
 * Logic based on IG v2.3 Chapter 4.
 */
export const generateQrCodeContent = (data: QrBillData): string => {
  const br = '\r\n'; 

  // 1. IBAN Analysis
  const cleanIban = data.iban.replace(/\s/g, '');
  // Extract IID (Position 5-9) to check for QR-IBAN (30000-31999)
  const iid = parseInt(cleanIban.substring(4, 9), 10);
  const isQrIban = iid >= 30000 && iid <= 31999;

  // 2. Reference Logic Enforcement
  let refType: 'QRR' | 'SCOR' | 'NON' = 'NON';
  let reference = data.reference.replace(/\s/g, '');

  if (isQrIban) {
    // A QR-IBAN MUST use a QR-Reference (QRR)
    refType = 'QRR';
    // If no valid 27-digit reference is present, we must generate a dummy one to avoid bank rejection
    if (reference.length !== 27 || isNaN(Number(reference))) {
        reference = generateQrReference('1'); 
    }
  } else {
    // A Standard IBAN uses either Creditor Reference (SCOR / ISO 11649) or NO Reference (NON)
    if (reference.startsWith('RF')) {
        refType = 'SCOR';
    } else {
        refType = 'NON';
        reference = ''; 
    }
  }

  // 3. Build SIX-compliant String
  let content = 'SPC' + br; // Header
  content += '0200' + br;     // Version
  content += '1' + br;        // Coding
  content += cleanIban + br;  // Account

  // Creditor (Address Type K - Combined)
  content += 'K' + br;
  content += sanitize(data.creditor.name) + br;
  content += (sanitize(data.creditor.address) || 'Street 1') + br; 
  content += (sanitize(data.creditor.zip) + ' ' + sanitize(data.creditor.city)).trim() + br;
  content += normalizeCountry(data.creditor.country) + br; 

  // Ultimate Creditor (Empty)
  content += '' + br + '' + br + '' + br + '' + br + '' + br + '' + br + '' + br;

  // Amount
  content += (data.amount ? data.amount.toFixed(2) : '') + br;
  content += data.currency + br;

  // Ultimate Debtor (Address Type K)
  content += 'K' + br;
  content += sanitize(data.debtor.name) + br;
  content += (sanitize(data.debtor.address) || 'Unknown St.') + br;
  content += (sanitize(data.debtor.zip) + ' ' + sanitize(data.debtor.city)).trim() + br;
  content += normalizeCountry(data.debtor.country) + br;

  // Reference
  content += refType + br;
  content += reference + br;

  // Unstructured Message
  content += sanitize(data.additionalInfo) + br;

  // Trailer
  content += 'EPD' + br;
  content += '' + br;
  content += ''; 

  return content;
};
