
import React, { useState, useEffect } from 'react';
import { useTranslation } from '../context/LanguageContext';
import { motion, AnimatePresence } from 'framer-motion';
import { scrollArt } from '../lib/bewegung';
import { ArrowUp } from 'lucide-react';

const BackToTop: React.FC = () => {
  const { t } = useTranslation();
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const toggleVisibility = () => {
      if (window.scrollY > 300) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener('scroll', toggleVisibility);
    return () => window.removeEventListener('scroll', toggleVisibility);
  }, []);

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: scrollArt(),
    });
  };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.button
          initial={{ opacity: 0, scale: 0.9, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.9, y: 20 }}
          onClick={scrollToTop}
          className="ueber-leiste nach-oben fixed bottom-[max(2rem,env(safe-area-inset-bottom))] right-8 z-40 bg-white text-stone-900 p-4 rounded-full shadow-xl border border-stone-100 hover:bg-primary hover:text-white transition-colors duration-300 group"
          aria-label={t('a11y.back_to_top')}
        >
          <ArrowUp size={20} className="group-hover:-translate-y-1 transition-transform duration-300" />
        </motion.button>
      )}
    </AnimatePresence>
  );
};

export default BackToTop;
