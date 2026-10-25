// Bankauszug im ISO-20022-Format lesen (camt.054 Gutschriftsanzeige,
// camt.053 Kontoauszug). Schweizer Banken liefern beide; uns interessieren
// nur Gutschriften (CdtDbtInd = CRDT) mit Betrag, Datum, Referenz und
// Mitteilung. Mehrere Zahlungen in einer Sammelbuchung (Batch) stehen als
// einzelne TxDtls -- jede wird ein Eingang.

export type Gutschrift = {
  schluessel: string;          // eindeutig je Transaktion, gegen Doppelbuchung
  betrag: number;
  waehrung: string;
  datum: string;               // JJJJ-MM-TT
  referenz: string | null;     // QR-Referenz (QRR) oder Creditor Reference (SCOR)
  mitteilung: string;          // unstrukturierte Mitteilung
  auftraggeber: string | null;
};

const kinder = (el: Element | null | undefined, name: string): Element[] =>
  el ? Array.from(el.getElementsByTagNameNS('*', name)) : [];
const eins = (el: Element | null | undefined, name: string): Element | null => kinder(el, name)[0] ?? null;
const text = (el: Element | null | undefined, name: string): string => eins(el, name)?.textContent?.trim() ?? '';

export function camtLesen(xml: string): Gutschrift[] {
  const doc = new DOMParser().parseFromString(xml, 'application/xml');
  if (doc.getElementsByTagName('parsererror').length) throw new Error('Die Datei ist kein lesbares XML.');
  const wurzel = doc.documentElement?.localName;
  if (wurzel !== 'Document') throw new Error('Kein ISO-20022-Bankauszug (camt.053/054).');

  const raus: Gutschrift[] = [];
  kinder(doc.documentElement, 'Ntry').forEach((ntry, ni) => {
    if (text(ntry, 'CdtDbtInd') && text(ntry, 'CdtDbtInd') !== 'CRDT') return;
    if (text(eins(ntry, 'Sts'), 'Cd') && !['BOOK', ''].includes(text(eins(ntry, 'Sts'), 'Cd'))) return;
    const datum = (text(eins(ntry, 'BookgDt'), 'Dt') || text(eins(ntry, 'BookgDt'), 'DtTm') || text(eins(ntry, 'ValDt'), 'Dt')).slice(0, 10);
    const ntryRef = text(ntry, 'AcctSvcrRef') || text(ntry, 'NtryRef');
    const txs = kinder(ntry, 'TxDtls');
    const quellen = txs.length ? txs : [ntry];
    quellen.forEach((tx, ti) => {
      // Betrag der Transaktion; ohne eigene Angabe der des Eintrags.
      const amtEl = eins(eins(tx, 'AmtDtls'), 'TxAmt') ? eins(eins(eins(tx, 'AmtDtls'), 'TxAmt'), 'Amt')
                  : (tx === ntry ? kinder(ntry, 'Amt')[0] : (Array.from(tx.children).find(c => c.localName === 'Amt') ?? kinder(ntry, 'Amt')[0]));
      if (tx !== ntry && text(tx, 'CdtDbtInd') && text(tx, 'CdtDbtInd') !== 'CRDT') return;
      const betrag = Number(amtEl?.textContent?.trim() ?? NaN);
      if (!isFinite(betrag) || betrag <= 0) return;
      const ref = text(eins(eins(tx, 'Strd'), 'CdtrRefInf'), 'Ref').replace(/\s+/g, '') || null;
      const mitteilung = kinder(tx, 'Ustrd').map(u => u.textContent?.trim() ?? '').filter(Boolean).join(' ');
      const auftraggeber = text(eins(eins(tx, 'RltdPties'), 'Dbtr'), 'Nm') || text(eins(eins(eins(tx, 'RltdPties'), 'Dbtr'), 'Pty'), 'Nm') || null;
      const txRef = text(eins(tx, 'Refs'), 'AcctSvcrRef') || text(eins(tx, 'Refs'), 'EndToEndId');
      raus.push({
        schluessel: [ntryRef || `n${ni}`, txRef || `t${ti}`, datum, betrag.toFixed(2), ref ?? ''].join('|'),
        betrag, waehrung: amtEl?.getAttribute('Ccy') || 'CHF', datum, referenz: ref, mitteilung, auftraggeber,
      });
    });
  });
  return raus;
}

export type Rechnung = { id: string; reference?: string | null; invoiceNumber?: string | null; amount: number; status: string; userId?: string; bezahlt?: number };
export type Zuordnung = { g: Gutschrift; rechnung: Rechnung | null; wie: 'REFERENZ' | 'RECHNUNGSNUMMER' | null };

// Zuordnung: zuerst die QR-Referenz (eindeutig), sonst die Rechnungsnummer
// in der Mitteilung. Betrag allein ordnet nie zu -- bei Vereinsbeitraegen
// zahlen viele denselben Betrag.
export function zuordnen(gutschriften: Gutschrift[], rechnungen: Rechnung[]): Zuordnung[] {
  const nachRef = new Map<string, Rechnung>();
  for (const r of rechnungen) if (r.reference) nachRef.set(r.reference.replace(/\s+/g, ''), r);
  return gutschriften.map(g => {
    if (g.referenz && nachRef.has(g.referenz)) return { g, rechnung: nachRef.get(g.referenz)!, wie: 'REFERENZ' as const };
    const m = g.mitteilung.toUpperCase();
    const treffer = rechnungen.filter(r => r.invoiceNumber && r.invoiceNumber.length >= 5 && m.includes(r.invoiceNumber.toUpperCase()));
    if (treffer.length === 1) return { g, rechnung: treffer[0], wie: 'RECHNUNGSNUMMER' as const };
    return { g, rechnung: null, wie: null };
  });
}
