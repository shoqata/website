
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ShieldCheck } from 'lucide-react';
import { Link } from 'react-router-dom';

import { useTranslation } from '../context/LanguageContext';
import { useIstPlattformDomain } from '../lib/useIstPlattformDomain';
import { TINTE, BLAU, NEBEL, SCHIEFER, MONO } from './platform/farben';

// Der Hinweis erscheint auf beiden Domains, aber nicht in derselben Sprache
// der Form: die Vereinsseite arbeitet mit warmem Grund, weichen Radien und
// kursiven Ueberschriften, die Betreiberseite mit fast schwarzem Blau,
// kleinen Radien, Haarlinien statt Schatten und Schreibmaschinenschrift fuer
// Systemangaben. Ein Hinweis im Vereinsgewand auf unityhub.li fiel sofort als
// Fremdkoerper auf.
const CookieConsent: React.FC = () => {
  const { t } = useTranslation();
  const istPlattform = useIstPlattformDomain();
  const [isVisible, setIsVisible] = useState(false);

  // Eigener Schluessel je Darstellung. localStorage ist ohnehin pro Herkunft
  // getrennt, die Trennung ist also nicht noetig, aber ehrlich: ein Eintrag
  // namens "koretini" auf unityhub.li waere schlicht falsch beschriftet.
  const schluessel = istPlattform ? 'cookie-consent-unityhub' : 'cookie-consent-koretini';

  useEffect(() => {
    // Solange nicht feststeht, wem die Adresse gehoert, wird nichts gezeigt --
    // sonst erschiene der Hinweis im falschen Gewand und wechselte danach.
    if (istPlattform === null) return;
    const consent = localStorage.getItem(schluessel);
    if (!consent) {
      const timer = setTimeout(() => setIsVisible(true), 2000);
      return () => clearTimeout(timer);
    }
  }, [istPlattform, schluessel]);

  const entscheide = (wert: 'accepted' | 'declined') => {
    localStorage.setItem(schluessel, wert);
    setIsVisible(false);
  };

  if (istPlattform === null) return null;

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div 
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          className={istPlattform
            ? 'fixed bottom-0 left-0 right-0 md:bottom-6 md:left-auto md:right-6 md:max-w-[420px] z-[1000]'
            : 'fixed bottom-6 left-6 right-6 md:left-auto md:max-w-md z-[1000]'}
        >
          {istPlattform ? (
            /* ---------------------------------------- Betreiberdarstellung */
            <div className="p-6 md:rounded-[4px]"
                 style={{ background: TINTE, border: `1px solid ${SCHIEFER}` }}>
              <p className="uppercase mb-3"
                 style={{ fontFamily: MONO, fontSize: 11, letterSpacing: '0.12em', color: NEBEL }}>
                {t('cookie.title')}
              </p>
              <p className="mb-5" style={{ fontSize: 14, lineHeight: 1.65, color: '#c9cad4' }}>
                {t('cookie.body')}
              </p>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => entscheide('accepted')}
                  className="px-5 py-2.5 uppercase transition-opacity hover:opacity-85"
                  style={{ background: BLAU, color: '#ffffff', borderRadius: 4,
                           fontFamily: MONO, fontSize: 12, letterSpacing: '0.08em' }}
                >
                  {t('cookie.accept')}
                </button>
                <button
                  onClick={() => entscheide('declined')}
                  className="px-5 py-2.5 uppercase transition-colors hover:text-white"
                  style={{ background: 'transparent', color: NEBEL,
                           border: `1px solid ${SCHIEFER}`, borderRadius: 4,
                           fontFamily: MONO, fontSize: 12, letterSpacing: '0.08em' }}
                >
                  {t('cookie.decline')}
                </button>
              </div>
              {/* Kein Verweis auf /privacy: diese Seite bezieht ihren Text aus
                  den Vereinsangaben, die es fuer die Betreiber-Domain nicht
                  gibt -- der Verweis fuehrte auf eine leere Seite. Sobald eine
                  eigene Datenschutzerklaerung vorliegt, gehoert sie hierhin. */}
            </div>
          ) : (
            /* ---------------------------------------- Vereinsdarstellung */
            <div className="bg-stone-900 text-white p-6 rounded-[2rem] shadow-2xl border border-white/10 backdrop-blur-xl">
               <div className="flex items-start gap-4 mb-6">
                  <div className="p-3 bg-primary/20 text-primary rounded-xl shrink-0">
                      <ShieldCheck size={24} />
                  </div>
                  <div>
                      <h4 className="font-bold text-lg mb-1 italic">{t('cookie.title')}</h4>
                      <p className="text-stone-400 text-xs leading-relaxed">
                          {t('cookie.body')}{' '}
                          {t('cookie.more')} <Link to="/privacy" onClick={() => setIsVisible(false)} className="text-white underline hover:text-primary transition-colors">{t('cookie.privacy_link')}</Link>.
                      </p>
                  </div>
               </div>
               
               <div className="flex gap-3">
                  <button 
                      onClick={() => entscheide('accepted')}
                      className="flex-1 py-3 bg-white text-stone-900 rounded-xl text-xs font-bold hover:bg-stone-100 transition-colors shadow-lg"
                  >
                      {t('cookie.accept')}
                  </button>
                  <button 
                      onClick={() => entscheide('declined')}
                      className="py-3 px-6 bg-stone-800 text-stone-400 rounded-xl text-xs font-bold hover:bg-stone-700 transition-colors"
                  >
                      {t('cookie.decline')}
                  </button>
               </div>
            </div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default CookieConsent;
