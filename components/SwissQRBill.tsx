
import React from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { QrBillData, formatIban, formatReference, generateQrCodeContent } from '../services/qrBillService';
import { Scissors } from 'lucide-react';

// Style Guide Specs
// Receipt: 62mm x 105mm
// Payment Part: 148mm x 105mm
// Total: 210mm x 105mm (A6 landscape width)

const Label = ({ children }: { children?: React.ReactNode }) => (
  <p className="text-[6pt] font-bold leading-[8pt] mt-2 mb-0.5 text-black">{children}</p>
);

const Value = ({ children }: { children?: React.ReactNode }) => (
  <p className="text-[8pt] leading-[10pt] font-normal text-black break-words">{children}</p>
);

const SwissQRBill: React.FC<{ data: QrBillData }> = ({ data }) => {
  const qrContent = generateQrCodeContent(data);
  
  // Recalculate reference type for display formatting based on content logic
  const cleanIban = data.iban.replace(/\s/g, '');
  const iid = parseInt(cleanIban.substring(4, 9), 10);
  const isQrIban = iid >= 30000 && iid <= 31999;
  const refType = isQrIban ? 'QRR' : (data.reference?.startsWith('RF') ? 'SCOR' : 'NON');

  return (
    <div className="bg-white text-black font-sans relative select-none mx-auto print:mx-0 overflow-hidden" 
         style={{ width: '210mm', height: '105mm', boxSizing: 'border-box' }}>
      
      {/* Print Styles for A4 page bottom placement */}
      <style>{`
        @media print {
          @page { 
            size: A4 portrait; 
            margin: 0; 
          }
          body * { visibility: hidden; }
          #qr-bill-root, #qr-bill-root * { visibility: visible; }
          #qr-bill-root { 
            position: absolute; 
            bottom: 0; 
            left: 0; 
            width: 210mm; 
            height: 105mm; 
          }
        }
      `}</style>

      <div id="qr-bill-root" className="w-full h-full flex border-t border-dashed border-black relative">
        
        {/* SCISSORS ICON (Centered visually on the cut line) */}
        <div className="absolute top-[-3mm] left-[62mm] transform -translate-x-1/2 bg-white px-1 z-10 hidden print:block">
            <span className="text-[10pt] text-black">✂️</span>
        </div>

        {/* 1. EMPFANGSSCHEIN (Receipt) - Left Side (62mm) */}
        <div className="flex-none p-[5mm] flex flex-col justify-between border-r border-dashed border-black" style={{ width: '62mm' }}>
          <div>
            <h2 className="text-[11pt] font-bold mb-[2mm] leading-none">Empfangsschein</h2>
            
            <Label>Konto / Zahlbar an</Label>
            <Value>{formatIban(data.iban)}</Value>
            <Value>{data.creditor.name}</Value>
            <Value>{data.creditor.address}</Value>
            <Value>{data.creditor.zip} {data.creditor.city}</Value>

            {refType !== 'NON' && (
              <>
                <Label>Referenz</Label>
                <Value>{formatReference(data.reference, refType)}</Value>
              </>
            )}

            <Label>Zahlbar durch</Label>
            <Value>{data.debtor.name}</Value>
            <Value>{data.debtor.address}</Value>
            <Value>{data.debtor.zip} {data.debtor.city}</Value>
          </div>

          <div className="flex justify-between items-end">
            <div className="w-[30%]">
              <Label>Währung</Label>
              <Value>{data.currency}</Value>
            </div>
            <div className="w-[70%]">
              <Label>Betrag</Label>
              <Value>{data.amount.toFixed(2)}</Value>
            </div>
          </div>
        </div>

        {/* 2. ZAHLTEIL (Payment Part) - Right Side (148mm) */}
        <div className="flex-1 p-[5mm] flex flex-col" style={{ width: '148mm' }}>
          <div className="flex h-full">
            
            {/* QR Section */}
            <div className="w-[46mm] mr-[5mm]">
                <h2 className="text-[11pt] font-bold mb-[5mm] leading-none">Zahlteil</h2>
                <div style={{ width: '46mm', height: '46mm' }} className="border border-black/10 relative">
                    <QRCodeSVG 
                        value={qrContent} 
                        size={174} // Approx 46mm in pixels at screen DPI, but SVG scales
                        style={{ width: '100%', height: '100%' }}
                        level="M"
                        imageSettings={{
                            src: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Flag_of_Switzerland.svg/512px-Flag_of_Switzerland.svg.png",
                            height: 28,
                            width: 28,
                            excavate: true,
                        }}
                    />
                </div>
                
                <div className="mt-4 flex gap-2">
                    <div className="w-12">
                        <Label>Währung</Label>
                        <Value>{data.currency}</Value>
                    </div>
                    <div>
                        <Label>Betrag</Label>
                        <Value>{data.amount.toFixed(2)}</Value>
                    </div>
                </div>
            </div>

            {/* Information Section */}
            <div className="flex-1">
                {/* Account */}
                <Label>Konto / Zahlbar an</Label>
                <Value>{formatIban(data.iban)}</Value>
                <Value>{data.creditor.name}</Value>
                <Value>{data.creditor.address}</Value>
                <Value>{data.creditor.zip} {data.creditor.city}</Value>

                {/* Reference */}
                {refType !== 'NON' && (
                    <>
                        <Label>Referenz</Label>
                        <Value>{formatReference(data.reference, refType)}</Value>
                    </>
                )}

                {/* Additional Info */}
                {data.additionalInfo && (
                    <>
                        <Label>Zusätzliche Informationen</Label>
                        <Value>{data.additionalInfo}</Value>
                    </>
                )}

                {/* Debtor */}
                <Label>Zahlbar durch</Label>
                <Value>{data.debtor.name}</Value>
                <Value>{data.debtor.address}</Value>
                <Value>{data.debtor.zip} {data.debtor.city}</Value>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SwissQRBill;
