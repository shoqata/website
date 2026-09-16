import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Trophy, Heart, ArrowRight, ExternalLink, Handshake } from 'lucide-react';
import { db } from '../services/firebase';
import { doc, onSnapshot } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Der Verein kann Turnier und Anmeldelink spaeter im Branding hinterlegen.
// Bis dahin gelten diese Werte, damit die Seite sofort steht.
const DEFAULT_EMBED = 'https://www.turnierplanung.ch/veranstaltung/embed/758/';
const DEFAULT_DETAIL = 'https://www.turnierplanung.ch/veranstaltung/detail/758';

const FutsalPage: React.FC = () => {
  const { t, loc } = useTranslation();
  const [branding, setBranding] = useState<any>({});

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'public_settings', 'branding'), (snap) => {
      if (snap.exists()) setBranding(snap.data());
    });
    return () => unsub();
  }, []);

  const embedUrl = loc(branding.tournamentEmbedUrl) || DEFAULT_EMBED;
  const detailUrl = loc(branding.tournamentDetailUrl) || DEFAULT_DETAIL;

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-20">
      <div className="max-w-7xl mx-auto px-6">

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="mb-14 max-w-3xl">
          <div className="inline-flex items-center gap-2 bg-amber-50 text-amber-700 px-4 py-2 rounded-full text-xs font-bold mb-6 uppercase tracking-widest">
            <Trophy size={14} /> {t('futsal.badge')}
          </div>
          <h1 className="font-display text-4xl md:text-6xl font-bold italic mb-6 text-stone-900 leading-tight">
            {loc(branding.tournamentTitle) || t('futsal.title')}
          </h1>
          <p className="text-xl text-stone-500 leading-relaxed mb-4 italic">
            {loc(branding.tournamentIntro) || t('futsal.intro')}
          </p>
          <p className="text-lg text-stone-500 leading-relaxed italic">
            {t('futsal.intro2')}
          </p>

          <div className="flex flex-col sm:flex-row gap-4 mt-10">
            <a
              href={detailUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="bg-primary text-white px-8 py-4 rounded-2xl font-bold text-sm flex items-center justify-center gap-2 shadow-lg shadow-rose-200 hover:bg-rose-600 transition-colors"
            >
              <Trophy size={18} /> {t('futsal.register_team')} <ExternalLink size={14} />
            </a>
            <Link
              to="/fussball/sponsoren"
              className="bg-white border border-stone-200 text-stone-800 px-8 py-4 rounded-2xl font-bold text-sm flex items-center justify-center gap-2 hover:border-primary/40 hover:text-primary transition-colors"
            >
              <Handshake size={18} /> {t('futsal.become_sponsor')} <ArrowRight size={16} />
            </Link>
          </div>
        </motion.div>

        {/* Spielplan aus der Turnierverwaltung */}
        <div className="mb-8">
          <h2 className="font-display text-2xl font-bold italic text-stone-900 mb-1">{t('futsal.plan_title')}</h2>
          <p className="text-sm text-stone-400 italic">{t('futsal.plan_hint')}</p>
        </div>

        <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden mb-16">
          <iframe
            src={embedUrl}
            title={t('futsal.plan_title')}
            loading="lazy"
            className="w-full block border-0"
            style={{ height: '1500px' }}
          />
          <div className="px-6 py-4 border-t border-stone-100 text-xs text-stone-400 flex flex-wrap items-center gap-2">
            {t('futsal.plan_fallback')}
            <a href={detailUrl} target="_blank" rel="noopener noreferrer" className="text-primary font-bold hover:underline inline-flex items-center gap-1">
              {detailUrl.replace(/^https?:\/\//, '')} <ExternalLink size={11} />
            </a>
          </div>
        </div>

        {/* Sponsoren-Aufruf */}
        <div className="bg-stone-900 text-white rounded-[2.5rem] p-10 md:p-14 relative overflow-hidden">
          <div className="absolute -right-16 -top-16 w-64 h-64 bg-primary/20 rounded-full blur-3xl" />
          <div className="relative z-10 max-w-2xl">
            <Heart size={32} className="text-primary mb-6" fill="currentColor" />
            <h2 className="font-display text-3xl md:text-4xl font-bold italic mb-4">{t('futsal.sponsor_hint')}</h2>
            <p className="text-white/60 text-lg leading-relaxed mb-8 italic">{t('futsal.closing')}</p>
            <Link
              to="/fussball/sponsoren"
              className="inline-flex items-center gap-2 bg-primary text-white px-8 py-4 rounded-2xl font-bold text-sm hover:bg-rose-600 transition-colors shadow-lg"
            >
              <Handshake size={18} /> {t('futsal.become_sponsor')} <ArrowRight size={16} />
            </Link>
          </div>
        </div>

      </div>
    </div>
  );
};

export default FutsalPage;
