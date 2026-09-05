
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowRight, Heart, UserPlus, LogIn, ChevronRight, X, Smartphone } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';
import { db } from '../services/firebase';
import { collection, query, where, onSnapshot, doc, getDoc, getDocs } from '@/services/supabase-bridge';
import { SolidarityEvent, UserProfile, GlobalPaymentSettings } from '../types';
import { Marquee } from './ui/Marquee';
import HyperTextParagraph from './ui/HyperText';
import { QRCodeSVG } from 'qrcode.react';

const DEFAULT_HERO_IMAGES = [
  "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&q=80&w=1000",
  "https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=1000",
  "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80&w=2000"
];

const Hero: React.FC = () => {
  const { t, language } = useTranslation();
  const [featuredEvents, setFeaturedEvents] = useState<SolidarityEvent[]>([]);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [heroImages, setHeroImages] = useState<string[]>(DEFAULT_HERO_IMAGES);
  const [members, setMembers] = useState<UserProfile[]>([]);
  const [diasporaCount, setDiasporaCount] = useState(0);
  const [branding, setBranding] = useState<any>({});
  
  // Payment Settings for TWINT
  const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings | null>(null);
  const [showTwintModal, setShowTwintModal] = useState(false);

  // Helper to get localized string from branding object
  const getLoc = (val: any) => {
      if (!val) return '';
      if (typeof val === 'string') return val;
      return val[language] || val['de'] || ''; 
  };

  // 1. Fetch Branding & Images
  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'branding'), (doc) => {
      if (doc.exists()) {
        const data = doc.data();
        setBranding(data);
        if (data.heroImages && data.heroImages.length > 0) {
          setHeroImages(data.heroImages);
        }
      }
    });
    return () => unsubscribe();
  }, []);

  // 2. Slider Timer
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImageIndex((prev) => (prev + 1) % heroImages.length);
    }, 5000);
    return () => clearInterval(timer);
  }, [heroImages]);

  // 3. Fetch Events & Members
  useEffect(() => {
    const qEvents = query(
      collection(db, 'events'),
      where('status', '==', 'UPCOMING')
    );
    const unsubEvents = onSnapshot(qEvents, (snap) => {
      const allEvents = snap.docs.map(d => ({ id: d.id, ...d.data() } as SolidarityEvent));
      const sorted = allEvents.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
      setFeaturedEvents(sorted.slice(0, 3));
    });

    const unsubUsers = onSnapshot(collection(db, 'public_members'), (snap) => {
        const allMembers = snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile));
        const activeMembers = allMembers.filter(m => m.membershipStatus === 'ACTIVE');
        setDiasporaCount(activeMembers.filter(m => !m.livesInKoretin).length);
        setMembers(activeMembers.slice(0, 30));
    });

    return () => { unsubEvents(); unsubUsers(); };
  }, []);

  // 4. Fetch Payment Settings
  useEffect(() => {
      const fetchSettings = async () => {
          const sSnap = await getDoc(doc(db, 'settings', 'payment'));
          if (sSnap.exists()) {
              setPaymentSettings(sSnap.data() as GlobalPaymentSettings);
          }
      };
      fetchSettings();
  }, []);

  return (
    <div className="relative overflow-hidden pt-32 pb-0 min-h-screen bg-[#faf9f6]">
      {/* Background Blobs */}
      <div className="absolute top-0 left-0 w-full h-full -z-10">
        <div className="absolute top-[-10%] right-[-5%] w-[600px] h-[600px] bg-rose-100/20 rounded-full blur-3xl animate-blob"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[500px] h-[500px] bg-amber-50/40 rounded-full blur-3xl animate-blob animation-delay-2000"></div>
      </div>

      <div className="max-w-7xl mx-auto px-6 pb-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center mb-20">
          {/* Left Side: Text */}
          <motion.div initial={{ opacity: 0, x: -30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.8 }}>
            <div className="inline-flex items-center gap-2 bg-white/80 border border-rose-100 text-rose-600 px-4 py-2 rounded-full text-xs font-bold mb-8 shadow-sm">
              <Heart size={14} fill="currentColor" /> {getLoc(branding.heroBadge) || t('hero.badge')}
            </div>
            
            <h1 className="font-display text-5xl lg:text-7xl font-bold leading-tight mb-8 tracking-tight text-stone-900 italic">
              {getLoc(branding.heroTitle) || t('hero.title')}
            </h1>
            
            <p className="text-lg text-stone-500 mb-10 leading-relaxed max-w-lg italic">
              {getLoc(branding.heroSubtitle) || t('hero.subtitle')}
            </p>

            <div className="flex flex-col sm:flex-row gap-4 mb-8">
              <Link to="/register" className="bg-primary text-white px-8 py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-3 hover:scale-105 transition-all shadow-xl shadow-rose-200">
                <UserPlus size={22} /> {t('hero.cta.register')} <ArrowRight size={20} />
              </Link>
              <Link to="/login" className="bg-white text-stone-800 border-2 border-stone-100 px-8 py-4 rounded-2xl text-lg font-bold hover:bg-stone-50 transition-all flex items-center justify-center gap-3">
                <LogIn size={20} className="text-primary" /> {t('hero.cta.login')}
              </Link>
            </div>

            {/* TWINT Donation Button */}
            {paymentSettings?.twintUrl && (
                <div className="mt-6 flex items-center gap-4">
                    <button onClick={() => setShowTwintModal(true)} className="flex items-center gap-3 bg-[#eb3333] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg hover:bg-[#d62d2d] transition-all group">
                       <Smartphone size={18} /> Support us with TWINT
                    </button>
                    <span className="text-xs text-stone-400 font-medium italic">Instant & Secure Donation</span>
                </div>
            )}
          </motion.div>

          {/* Right Side: Image Slider */}
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }} 
            animate={{ opacity: 1, scale: 1 }} 
            transition={{ duration: 1 }} 
            className="relative h-[600px] w-full flex items-center justify-center"
          >
             <div className="relative w-full h-full rounded-[3rem] overflow-hidden shadow-2xl border-4 border-white rotate-2 hover:rotate-0 transition-all duration-500">
                <AnimatePresence mode="wait">
                  <motion.img
                    key={currentImageIndex}
                    src={heroImages[currentImageIndex]}
                    initial={{ opacity: 0, scale: 1.1 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.8 }}
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                </AnimatePresence>
                <div className="absolute inset-0 bg-gradient-to-t from-stone-900/60 to-transparent" />
                <div className="absolute bottom-8 left-8 flex gap-2">
                  {heroImages.map((_, idx) => (
                    <div 
                      key={idx} 
                      className={`h-1 rounded-full transition-all duration-300 ${idx === currentImageIndex ? 'w-8 bg-white' : 'w-2 bg-white/40'}`} 
                    />
                  ))}
                </div>
             </div>
             
             <div className="absolute -bottom-6 -left-6 bg-white p-6 rounded-3xl shadow-xl animate-bounce duration-[3000ms]">
                <div className="flex items-center gap-3">
                   <div className="w-12 h-12 bg-rose-50 rounded-full flex items-center justify-center text-primary font-bold text-xl">
                      {diasporaCount > 0 ? diasporaCount : '2k+'}
                   </div>
                   <div>
                      <p className="font-bold text-stone-900 leading-none">Anëtarë</p>
                      <p className="text-xs text-stone-400">Aktive në diasporë</p>
                   </div>
                </div>
             </div>
          </motion.div>
        </div>

        {/* HyperText Interactive Section */}
        {getLoc(branding.whyJoinText) && (
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="max-w-4xl mx-auto mb-24 px-4"
            >
                <div className="bg-white rounded-[2.5rem] p-10 md:p-14 shadow-sm border border-stone-100 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-rose-50 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2" />
                    <div className="relative z-10 text-center">
                        <p className="text-xs font-bold text-stone-400 uppercase tracking-[0.2em] mb-6">Misioni Ynë</p>
                        <HyperTextParagraph 
                            text={getLoc(branding.whyJoinText)}
                            highlightWords={branding.whyJoinHighlightWords || []}
                            className="text-2xl md:text-4xl font-display text-stone-800 leading-normal"
                        />
                    </div>
                </div>
            </motion.div>
        )}

        {/* Member Marquee */}
        <div className="mb-32">
            <div className="text-center mb-8">
                <p className="text-xs font-bold text-stone-400 uppercase tracking-[0.2em]">Komuniteti ynë</p>
            </div>
            <div className="relative flex w-full flex-col items-center justify-center overflow-hidden">
                <Marquee pauseOnHover className="[--duration:60s]">
                    {members.map((member) => (
                        <div key={member.id} className="mx-4 flex items-center gap-3 bg-white px-6 py-3 rounded-full shadow-sm border border-stone-100">
                            <div className="w-8 h-8 rounded-full bg-stone-100 overflow-hidden border border-stone-200">
                                {member.photoFileName ? (
                                    <img src={member.photoFileName} className="w-full h-full object-cover" alt={member.displayName} />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-[10px] font-bold text-stone-400">
                                        {member.displayName?.charAt(0)}
                                    </div>
                                )}
                            </div>
                            <div>
                                <p className="text-xs font-bold text-stone-900">{member.displayName}</p>
                                <p className="text-[9px] text-stone-400 uppercase">{member.city || 'Member'}</p>
                            </div>
                        </div>
                    ))}
                </Marquee>
                <div className="pointer-events-none absolute inset-y-0 left-0 w-1/3 bg-gradient-to-r from-[#faf9f6] to-transparent"></div>
                <div className="pointer-events-none absolute inset-y-0 right-0 w-1/3 bg-gradient-to-l from-[#faf9f6] to-transparent"></div>
            </div>
        </div>

        {/* Featured Events */}
        {featuredEvents.length > 0 && (
          <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }}>
            <div className="flex items-center justify-between mb-12">
               <div>
                  <h2 className="text-4xl font-display font-bold italic text-stone-900 mb-2">{t('events.title')}</h2>
                  <p className="text-stone-500">{t('events.subtitle')}</p>
               </div>
               <Link to="/events" className="text-primary font-bold flex items-center gap-2 group">
                  {t('events.view_all')} <ChevronRight className="group-hover:translate-x-1 transition-transform" />
               </Link>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
               {featuredEvents.map((event) => (
                 <div key={event.id} className="bg-white rounded-[2.5rem] overflow-hidden border border-stone-100 shadow-sm hover:shadow-xl transition-all group cursor-pointer">
                    <Link to="/events">
                        <div className="aspect-[16/10] overflow-hidden relative">
                           <img src={event.image} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
                           <div className="absolute top-4 left-4 bg-white/90 backdrop-blur-md px-4 py-2 rounded-xl text-center shadow-sm">
                              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{new Date(event.date).toLocaleString('default', { month: 'short' })}</p>
                              <p className="text-xl font-bold text-primary">{new Date(event.date).getDate()}</p>
                           </div>
                        </div>
                        <div className="p-8">
                           <span className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 block">{event.category}</span>
                           <h3 className="text-2xl font-display font-bold mb-4 italic text-stone-900">{event.title}</h3>
                           <p className="text-stone-500 text-sm mb-6 line-clamp-2 leading-relaxed italic">"{event.description}"</p>
                        </div>
                    </Link>
                 </div>
               ))}
            </div>
          </motion.div>
        )}
      </div>

      {/* TWINT MODAL */}
      <AnimatePresence>
          {showTwintModal && paymentSettings?.twintUrl && (
              <div className="fixed inset-0 z-[1000] flex items-center justify-center p-6">
                  <motion.div 
                      initial={{ opacity: 0 }} 
                      animate={{ opacity: 1 }} 
                      exit={{ opacity: 0 }} 
                      onClick={() => setShowTwintModal(false)}
                      className="absolute inset-0 bg-stone-900/80 backdrop-blur-md"
                  />
                  <motion.div 
                      initial={{ scale: 0.9, opacity: 0, y: 20 }} 
                      animate={{ scale: 1, opacity: 1, y: 0 }} 
                      exit={{ scale: 0.9, opacity: 0, y: 20 }}
                      className="relative bg-white rounded-[3rem] p-10 max-w-sm w-full shadow-2xl text-center overflow-hidden"
                  >
                      <div className="absolute top-0 left-0 w-full h-2 bg-[#eb3333]" />
                      <button onClick={() => setShowTwintModal(false)} className="absolute top-6 right-6 p-2 bg-stone-50 rounded-full hover:bg-stone-100"><X size={20}/></button>
                      
                      <div className="mb-8">
                          <h3 className="text-3xl font-display font-bold italic mb-2">Scan & Pay</h3>
                          <p className="text-stone-500">Use your TWINT app to scan the code.</p>
                      </div>

                      <div className="bg-stone-50 p-6 rounded-[2rem] border border-stone-100 shadow-inner mb-8 inline-block">
                          <QRCodeSVG value={paymentSettings.twintUrl} size={180} level="M" />
                      </div>

                      <a href={paymentSettings.twintUrl} target="_blank" rel="noreferrer" className="w-full bg-[#eb3333] text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-[#d62d2d] transition-all shadow-xl">
                          Open TWINT App <ArrowRight size={18} />
                      </a>
                  </motion.div>
              </div>
          )}
      </AnimatePresence>
    </div>
  );
};

export default Hero;
