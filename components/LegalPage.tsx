
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { db } from '../services/firebase';
import { doc, onSnapshot } from '@/services/supabase-bridge';
import { ShieldCheck, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';

interface LegalPageProps {
    type: 'GDPR' | 'PRIVACY';
}

const LegalPage: React.FC<LegalPageProps> = ({ type }) => {
  const { language } = useTranslation();
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);

  // Helper to get localized string from branding object
  const getLoc = (val: any) => {
      if (!val) return '';
      if (typeof val === 'string') return val;
      return val[language] || val['de'] || ''; 
  };

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'settings', 'branding'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        const rawContent = type === 'GDPR' ? data.gdprText : data.privacyText;
        setContent(getLoc(rawContent));
      }
      setLoading(false);
    });
    return () => unsub();
  }, [type, language]);

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-40 pb-20">
      <div className="max-w-4xl mx-auto px-6">
        <Link to="/" className="inline-flex items-center gap-2 text-stone-400 hover:text-primary font-bold text-xs uppercase tracking-widest mb-12 transition-colors">
            <ArrowLeft size={16} /> Back to Home
        </Link>

        <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-[3rem] p-10 md:p-16 shadow-sm border border-stone-100"
        >
            <div className="w-16 h-16 bg-rose-50 text-primary rounded-2xl flex items-center justify-center mb-8">
                <ShieldCheck size={32} />
            </div>
            
            <h1 className="text-4xl font-display font-bold italic text-stone-900 mb-12">
                {type === 'GDPR' ? 'DSGVO / GDPR' : 'Politika e Privatësisë'}
            </h1>

            {loading ? (
                <div className="space-y-4">
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-full" />
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-5/6" />
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-4/6" />
                </div>
            ) : (
                <div className="prose prose-stone max-w-none">
                    {content ? (
                        content.split('\n').map((para, i) => (
                            <p key={i} className="text-stone-600 leading-relaxed mb-6 font-medium whitespace-pre-wrap">
                                {para}
                            </p>
                        ))
                    ) : (
                        <p className="text-stone-400 italic">No content has been published yet. Please contact the administrator.</p>
                    )}
                </div>
            )}
        </motion.div>
      </div>
    </div>
  );
};

export default LegalPage;
