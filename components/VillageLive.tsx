
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
// Fix: Add missing Link import
import { Link } from 'react-router-dom';
import { 
  HeartPulse, 
  Droplets, 
  Sprout, 
  Calendar, 
  Mail, 
  Send, 
  MapPin, 
  Sparkles,
  Award,
  Sun,
  BookOpen,
  Clock
} from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import NeighborhoodMap3D from './NeighborhoodMap3D';
import { db } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, doc } from 'firebase/firestore';
import { SolidarityEvent } from '../types';

const VillageLive: React.FC = () => {
  const { t, language } = useTranslation();
  const [branding, setBranding] = useState<any>({});

  // Helper to get localized string from branding object
  const getLoc = (val: any) => {
      if (!val) return '';
      if (typeof val === 'string') return val;
      return val[language] || val['de'] || ''; 
  };

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'settings', 'branding'), (snap) => {
      if (snap.exists()) setBranding(snap.data());
    });
    return () => unsub();
  }, []);

  return (
    <div className="bg-[#faf9f6]">
      {/* 1. Header & 3D Map */}
      <section className="pt-32 pb-12 px-6 overflow-hidden">
        <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="text-left">
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 bg-rose-50 text-rose-600 px-4 py-1.5 rounded-full text-sm font-bold mb-6"
            >
              <Sparkles size={16} /> {t('live.header.badge') || "Koretini Live"}
            </motion.div>
            <motion.h1 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="font-display text-5xl md:text-7xl font-bold mb-6 leading-tight italic"
            >
              {getLoc(branding.heroTitle) || t('hero.title')}
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-xl text-stone-500 max-w-xl leading-relaxed italic"
            >
              {getLoc(branding.heroSubtitle) || t('hero.subtitle')}
            </motion.p>
          </div>
          <motion.div 
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1 }}
            className="relative"
          >
            <div className="absolute inset-0 bg-rose-200/20 blur-3xl rounded-full" />
            <NeighborhoodMap3D />
          </motion.div>
        </div>
      </section>

      {/* 2. Interactive Selector */}
      <section className="py-12 flex flex-col items-center">
        <VillageSelector data={branding.liveSelectors} getLoc={getLoc} />
      </section>

      {/* 3. Actions & Events */}
      <section className="py-24 bg-white border-y border-stone-100">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-20">
            <EventTimeline />
            <RecentActions branding={branding} getLoc={getLoc} />
          </div>
        </div>
      </section>

      {/* 4. Contact Section */}
      <ContactSection branding={branding} getLoc={getLoc} />
    </div>
  );
};

const VillageSelector = ({ data, getLoc }: { data?: any[], getLoc: (v: any) => string }) => {
  const [activeIndex, setActiveIndex] = useState(0);
  
  const defaultOptions = [
    { title: "Shëndetësia", description: "Përkrahje për ambulancën", image: "https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80", icon: <HeartPulse size={24} className="text-white" /> },
    { title: "Uji & Natyra", description: "Mirëmbajtja e ambientit", image: "https://images.unsplash.com/photo-1541819616035-64552467b7e2?auto=format&fit=crop&w=800&q=80", icon: <Droplets size={24} className="text-white" /> },
    { title: "Energjia", description: "Infrastruktura moderne", image: "https://images.unsplash.com/photo-1509391366360-feaffa64e4c9?auto=format&fit=crop&w=800&q=80", icon: <Sun size={24} className="text-white" /> },
    { title: "Arsimi", description: "Edukimi i gjeneratave", image: "https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80", icon: <BookOpen size={24} className="text-white" /> },
    { title: "Sporti", description: "Aktivitete sportive", image: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=800&q=80", icon: <Award size={24} className="text-white" /> }
  ];

  const options = data && data.length > 0 ? data.map((d, i) => ({
      ...d,
      // Apply localization here
      title: getLoc(d.title),
      description: getLoc(d.description),
      icon: defaultOptions[i % defaultOptions.length].icon,
      image: d.image || defaultOptions[i % defaultOptions.length].image
  })) : defaultOptions;

  return (
    <div className="w-full max-w-7xl px-6">
      <div className="flex w-full h-[500px] items-stretch overflow-hidden rounded-[3rem] shadow-2xl border-4 border-white bg-stone-900">
        {options.map((option, index) => (
          <div
            key={index}
            className={`relative flex flex-col justify-end overflow-hidden transition-all duration-700 ease-in-out cursor-pointer ${activeIndex === index ? 'flex-[5]' : 'flex-[1] opacity-60 hover:opacity-100'}`}
            style={{
              backgroundImage: `url('${option.image}')`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
            }}
            onClick={() => setActiveIndex(index)}
          >
            <div className={`absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent transition-opacity ${activeIndex === index ? 'opacity-100' : 'opacity-40'}`} />
            <div className="absolute left-0 right-0 bottom-8 flex items-center h-16 z-20 px-6 gap-4">
              <div className={`w-14 h-14 min-w-[3.5rem] flex items-center justify-center rounded-2xl backdrop-blur-md border border-white/20 transition-all ${activeIndex === index ? 'bg-primary scale-110' : 'bg-white/10'}`}>
                {option.icon}
              </div>
              <AnimatePresence>
                {activeIndex === index && (
                  <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="text-white">
                    <h3 className="font-bold text-2xl whitespace-nowrap">{option.title}</h3>
                    <p className="text-stone-300 text-sm italic">{option.description}</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

const EventTimeline = () => {
  const { t } = useTranslation();
  const [events, setEvents] = useState<SolidarityEvent[]>([]);

  useEffect(() => {
    const q = query(collection(db, 'events'), orderBy('date', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setEvents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as SolidarityEvent)));
    });
    return () => unsubscribe();
  }, []);

  return (
    <div>
      <h2 className="text-3xl font-display font-bold mb-8 flex items-center gap-3">
        <Calendar className="text-primary" /> {t('events.title')}
      </h2>
      
      {events.length === 0 ? (
        <div className="p-8 bg-stone-50 rounded-3xl text-center border border-dashed border-stone-200">
          <p className="text-stone-400 italic">No events scheduled yet.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {events.map((e) => (
            <div key={e.id} className="flex gap-6 items-start group">
              <div className="w-12 h-12 bg-white rounded-xl border border-stone-100 flex items-center justify-center shadow-sm shrink-0 overflow-hidden">
                {e.image ? (
                   <img src={e.image} className="w-full h-full object-cover" alt="icon" />
                ) : (
                   <Award className="text-rose-500" />
                )}
              </div>
              <div className="bg-stone-50 p-6 rounded-3xl border border-transparent group-hover:bg-white group-hover:shadow-xl transition-all w-full">
                <div className="flex justify-between items-start mb-1">
                   <span className="text-[10px] font-bold text-primary uppercase tracking-widest">{e.category}</span>
                   <span className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-1">
                     <Clock size={10} /> {new Date(e.date).toLocaleDateString()}
                   </span>
                </div>
                <h4 className="text-xl font-bold mb-1">{e.title}</h4>
                <p className="text-stone-500 text-sm flex items-center gap-1">
                  <MapPin size={12} /> {e.location}
                </p>
                <p className="mt-4 text-sm text-stone-600 line-clamp-2 italic">"{e.description}"</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const RecentActions = ({ branding, getLoc }: { branding: any, getLoc: (v: any) => string }) => {
  const { t } = useTranslation();
  return (
    <div className="bg-primary rounded-[3rem] p-12 text-white relative overflow-hidden">
      <div className="relative z-10">
        <h3 className="text-3xl font-bold mb-4 italic">{getLoc(branding.heroTitle) || t('hero.title')}</h3>
        <p className="text-white/80 text-lg mb-8 max-w-sm italic">"{getLoc(branding.heroSubtitle) || t('hero.subtitle')}"</p>
        <Link to="/register" className="bg-white text-primary px-8 py-4 rounded-2xl font-bold hover:scale-105 transition-transform shadow-xl inline-block">
          {t('hero.cta.register')}
        </Link>
      </div>
      <Sparkles className="absolute -right-10 -bottom-10 w-64 h-64 text-white/10" />
    </div>
  );
};

const ContactSection = ({ branding, getLoc }: { branding: any, getLoc: (v: any) => string }) => {
  return (
    <section className="py-24 bg-stone-900 text-white text-center px-6">
      <div className="max-w-2xl mx-auto">
        <h2 className="text-4xl font-display font-bold mb-6 italic">Na kontaktoni</h2>
        <p className="text-white/40 text-lg mb-12 italic">{getLoc(branding.footerText)}</p>
        <div className="flex flex-col md:flex-row justify-center gap-8 mb-12">
          <div className="flex items-center gap-3"><Mail className="text-primary" /> {branding.footerEmail || "info@koretini.org"}</div>
          <div className="flex items-center gap-3"><MapPin className="text-primary" /> {branding.footerAddress || "Koretin, Kosovë"}</div>
        </div>
        <div className="flex justify-center gap-4">
          <div className="w-12 h-12 bg-white/5 rounded-2xl flex items-center justify-center hover:bg-primary transition-colors cursor-pointer shadow-lg shadow-black/20"><Send size={20} /></div>
        </div>
      </div>
    </section>
  );
};

export default VillageLive;
