
import React from 'react';
import { Newspaper } from 'lucide-react';
import { NewsSection } from './NewsSection';
import { useTranslation } from '../context/LanguageContext';

const NewsPage: React.FC = () => {
  const { t } = useTranslation();

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-20">
      <div className="max-w-7xl mx-auto px-6 mb-8">
         <div className="inline-flex items-center gap-2 bg-blue-50 text-blue-600 px-4 py-2 rounded-full text-xs font-bold mb-6">
             <Newspaper size={14} /> Diaspora News
          </div>
          <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">{t('nav.news.title')}</h1>
          <p className="text-xl text-stone-500 max-w-2xl leading-relaxed italic">
             {t('nav.news.desc')}
          </p>
      </div>
      
      {/* We reuse the NewsSection logic but render it here */}
      <NewsSection />
    </div>
  );
};

export default NewsPage;
