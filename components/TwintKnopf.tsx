import React, { useEffect, useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { db } from '../services/datenzugriff';
import { doc, getDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Twint, wenn der Verein einen Link hinterlegt hat (public_settings/payment,
// jeder Verein seinen eigenen). Auf dem Handy der Knopf, am Computer
// zusaetzlich der QR-Code zum Scannen.
export function useTwintLink(): string | null {
  const [link, setLink] = useState<string | null>(null);
  useEffect(() => {
    getDoc(doc(db, 'public_settings', 'payment'))
      .then((s: any) => { if (s.exists()) setLink(s.data()?.twintUrl || null); })
      .catch(() => setLink(null));
  }, []);
  return link;
}

const TwintKnopf: React.FC<{ text?: string; mitQr?: boolean }> = ({ text, mitQr = true }) => {
  const { t } = useTranslation();
  const link = useTwintLink();
  if (!link) return null;
  return (
    <div className="flex flex-col sm:flex-row items-center gap-4 p-5 bg-stone-50 rounded-2xl">
      {mitQr && <div className="hidden sm:block bg-white p-2 rounded-xl"><QRCodeSVG value={link} size={96} level="M" /></div>}
      <div className="flex-1 text-center sm:text-left">
        <p className="text-sm font-bold text-stone-800 mb-1">{text || t('twint.titel')}</p>
        <p className="text-xs text-stone-500 mb-3">{t('twint.hinweis')}</p>
        <a href={link} target="_blank" rel="noopener noreferrer"
           className="inline-flex items-center justify-center px-6 py-3 bg-[#eb3333] hover:bg-[#d62d2d] text-white rounded-xl text-sm font-bold">
          {t('dash.twint')}
        </a>
      </div>
    </div>
  );
};

export default TwintKnopf;
