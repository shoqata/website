// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { camtLesen, zuordnen } from '../../lib/camt';

const XML = `<?xml version="1.0"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.08"><BkToCstmrDbtCdtNtfctn><Ntfctn>
 <Ntry><Amt Ccy="CHF">160.00</Amt><CdtDbtInd>CRDT</CdtDbtInd><Sts><Cd>BOOK</Cd></Sts>
  <BookgDt><Dt>2026-10-20</Dt></BookgDt><AcctSvcrRef>B1</AcctSvcrRef>
  <NtryDtls>
   <TxDtls><Refs><AcctSvcrRef>T1</AcctSvcrRef></Refs><Amt Ccy="CHF">120.00</Amt><CdtDbtInd>CRDT</CdtDbtInd>
    <RltdPties><Dbtr><Pty><Nm>Arta Krasniqi</Nm></Pty></Dbtr></RltdPties>
    <RmtInf><Strd><CdtrRefInf><Ref>21 00000 00003 13947 14300 09017</Ref></CdtrRefInf></Strd></RmtInf></TxDtls>
   <TxDtls><Refs><AcctSvcrRef>T2</AcctSvcrRef></Refs><Amt Ccy="CHF">40.00</Amt><CdtDbtInd>CRDT</CdtDbtInd>
    <RmtInf><Ustrd>Beitrag INV-633546-00173 danke</Ustrd></RmtInf></TxDtls>
  </NtryDtls></Ntry>
 <Ntry><Amt Ccy="CHF">55.00</Amt><CdtDbtInd>DBIT</CdtDbtInd><BookgDt><Dt>2026-10-21</Dt></BookgDt></Ntry>
</Ntfctn></BkToCstmrDbtCdtNtfctn></Document>`;

describe('camt', () => {
  it('liest Gutschriften aus einer Sammelbuchung, ignoriert Belastungen', () => {
    const g = camtLesen(XML);
    expect(g).toHaveLength(2);
    expect(g[0]).toMatchObject({ betrag: 120, datum: '2026-10-20', referenz: '210000000003139471430009017', auftraggeber: 'Arta Krasniqi' });
    expect(g[1].mitteilung).toContain('INV-633546-00173');
    expect(new Set(g.map(x => x.schluessel)).size).toBe(2);
  });
  it('ordnet ueber Referenz und Rechnungsnummer zu, nie ueber den Betrag allein', () => {
    const z = zuordnen(camtLesen(XML), [
      { id: 'a', reference: '210000000003139471430009017', amount: 120, status: 'PENDING' },
      { id: 'b', invoiceNumber: 'INV-633546-00173', amount: 40, status: 'PENDING' },
      { id: 'c', amount: 120, status: 'PENDING' },
    ]);
    expect(z.map(x => x.rechnung?.id)).toEqual(['a', 'b']);
    expect(z.map(x => x.wie)).toEqual(['REFERENZ', 'RECHNUNGSNUMMER']);
  });
  it('weist anderes XML ab', () => {
    expect(() => camtLesen('<foo/>')).toThrow();
  });
});
