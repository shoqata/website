
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ShieldCheck, X } from 'lucide-react';
import { Link } from 'react-router-dom';

const CookieConsent: React.FC = () => {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const consent = localStorage.getItem('cookie-consent-koretini');
    if (!consent) {
      const timer = setTimeout(() => setIsVisible(true), 2000);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleAccept = () => {
    localStorage.setItem('cookie-consent-koretini', 'accepted');
    setIsVisible(false);
  };

  const handleDecline = () => {
    localStorage.setItem('cookie-consent-koretini', 'declined');
    setIsVisible(false);
  };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div 
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          className="fixed bottom-6 left-6 right-6 md:left-auto md:max-w-md z-[1000]"
        >
          <div className="bg-stone-900 text-white p-6 rounded-[2rem] shadow-2xl border border-white/10 backdrop-blur-xl">
             <div className="flex items-start gap-4 mb-6">
                <div className="p-3 bg-primary/20 text-primary rounded-xl shrink-0">
                    <ShieldCheck size={24} />
                </div>
                <div>
                    <h4 className="font-bold text-lg mb-1 italic">Privatësia & Cookies</h4>
                    <p className="text-stone-400 text-xs leading-relaxed">
                        Ne përdorim cookies për të përmirësuar përvojën tuaj. Duke vazhduar, ju pranoni kushtet tona. 
                        Lexoni më shumë te <Link to="/privacy" onClick={() => setIsVisible(false)} className="text-white underline hover:text-primary transition-colors">Privatësia</Link>.
                    </p>
                </div>
             </div>
             
             <div className="flex gap-3">
                <button 
                    onClick={handleAccept}
                    className="flex-1 py-3 bg-white text-stone-900 rounded-xl text-xs font-bold hover:bg-stone-100 transition-colors shadow-lg"
                >
                    Pranoj
                </button>
                <button 
                    onClick={handleDecline}
                    className="py-3 px-6 bg-stone-800 text-stone-400 rounded-xl text-xs font-bold hover:bg-stone-700 transition-colors"
                >
                    Refuzoj
                </button>
             </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default CookieConsent;
