import React, { useEffect, useRef, useState } from 'react';
import { Heart, Share2, Link2, Mail, Check, X } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { nachrichtLink } from '../lib/news';

// Like und Teilen -- die beiden einzigen Reaktionen auf eine Nachricht.

export const LikeKnopf: React.FC<{ anzahl: number; gelikt: boolean; onClick: () => void; klein?: boolean }> =
  ({ anzahl, gelikt, onClick, klein }) => {
  const { t } = useTranslation();
  return (
    <button type="button" aria-pressed={gelikt} title={t(gelikt ? 'news.like_weg' : 'news.like')}
      onClick={e => { e.stopPropagation(); onClick(); }}
      className={`inline-flex items-center gap-1.5 rounded-full font-bold transition-all border ${klein ? 'px-3 py-1.5 text-xs' : 'px-4 py-2.5 text-sm'} ${
        gelikt ? 'bg-primary text-white border-primary' : 'bg-white text-stone-600 border-stone-200 hover:border-stone-400'}`}>
      <Heart size={klein ? 13 : 16} fill={gelikt ? 'currentColor' : 'none'}
        className={gelikt ? 'scale-110 transition-transform' : 'transition-transform'} />
      <span className="tabular-nums">{anzahl > 0 ? anzahl : ''}</span>
      {!klein && <span>{t('news.like')}</span>}
    </button>
  );
};

export const TeilenKnopf: React.FC<{ id: string; titel: string; klein?: boolean }> = ({ id, titel, klein }) => {
  const { t } = useTranslation();
  const [offen, setOffen] = useState(false);
  const [kopiert, setKopiert] = useState(false);
  const rahmen = useRef<HTMLDivElement>(null);
  const link = nachrichtLink(id);

  useEffect(() => {
    if (!offen) return;
    const zu = (e: MouseEvent) => { if (!rahmen.current?.contains(e.target as Node)) setOffen(false); };
    document.addEventListener('mousedown', zu);
    return () => document.removeEventListener('mousedown', zu);
  }, [offen]);

  const teilen = async (e: React.MouseEvent) => {
    e.stopPropagation();
    // Auf dem Telefon das Teilen des Geraets: WhatsApp, Telegram, was
    // dort installiert ist. Am Computer die Auswahl darunter.
    if (navigator.share && window.matchMedia('(pointer: coarse)').matches) {
      try { await navigator.share({ title: titel, url: link }); } catch { /* abgebrochen */ }
      return;
    }
    setOffen(!offen);
  };

  const kopieren = async () => {
    try { await navigator.clipboard.writeText(link); setKopiert(true); setTimeout(() => setKopiert(false), 2000); }
    catch { window.prompt(t('news.link_kopieren'), link); }
  };

  const ziele = [
    { name: 'WhatsApp', href: `https://wa.me/?text=${encodeURIComponent(`${titel} ${link}`)}` },
    { name: 'Facebook', href: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(link)}` },
    { name: 'Telegram', href: `https://t.me/share/url?url=${encodeURIComponent(link)}&text=${encodeURIComponent(titel)}` },
  ];

  return (
    <div ref={rahmen} className="relative inline-block" onClick={e => e.stopPropagation()}>
      <button type="button" onClick={teilen} title={t('news.teilen')}
        className={`inline-flex items-center gap-1.5 rounded-full font-bold border bg-white text-stone-600 border-stone-200 hover:border-stone-400 ${klein ? 'px-3 py-1.5 text-xs' : 'px-4 py-2.5 text-sm'}`}>
        <Share2 size={klein ? 13 : 16} /> {!klein && t('news.teilen')}
      </button>
      {offen && (
        <div className="absolute z-30 bottom-full mb-2 right-0 w-56 bg-white rounded-2xl border border-stone-100 shadow-xl p-2">
          <div className="flex items-center justify-between px-2 py-1">
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('news.teilen')}</p>
            <button type="button" onClick={() => setOffen(false)} className="text-stone-300 hover:text-stone-600"><X size={14} /></button>
          </div>
          {ziele.map(z => (
            <a key={z.name} href={z.href} target="_blank" rel="noopener noreferrer"
               className="block px-3 py-2 rounded-xl text-sm font-bold text-stone-700 hover:bg-stone-50">{z.name}</a>
          ))}
          <a href={`mailto:?subject=${encodeURIComponent(titel)}&body=${encodeURIComponent(link)}`}
             className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-bold text-stone-700 hover:bg-stone-50">
            <Mail size={14} /> E-Mail
          </a>
          <button type="button" onClick={kopieren}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-bold text-stone-700 hover:bg-stone-50">
            {kopiert ? <Check size={14} className="text-emerald-600" /> : <Link2 size={14} />}
            {t(kopiert ? 'news.kopiert' : 'news.link_kopieren')}
          </button>
        </div>
      )}
    </div>
  );
};
