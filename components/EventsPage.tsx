
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Calendar, MapPin, Clock, ChevronRight, Heart, X, CheckCircle2, User, Mail, Phone, Loader2, Info } from 'lucide-react';
import { auth, db } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, doc, getDoc, where } from '@/services/supabase-bridge';
import { SolidarityEvent, UserProfile, EventRegistration } from '../types';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

const EventsPage: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [events, setEvents] = useState<SolidarityEvent[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Registration State
  const [selectedEvent, setSelectedEvent] = useState<SolidarityEvent | null>(null);
  const [currentUserProfile, setCurrentUserProfile] = useState<UserProfile | null>(null);
  const [regLoading, setRegLoading] = useState(false);
  const [regSuccess, setRegSuccess] = useState(false);
  
  // Guest Form State
  const [guestForm, setGuestForm] = useState({ name: '', email: '', phone: '' });

  useEffect(() => {
    // 1. Fetch Events - Filtered for Public/Published
    const q = query(
        collection(db, 'events'), 
        where('status', '==', 'PUBLISHED'),
        orderBy('date', 'desc')
    );
    const unsubscribeEvents = onSnapshot(q, (snapshot) => {
      setEvents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as SolidarityEvent)));
      setLoading(false);
    });

    // 2. Check if user is logged in
    const checkUser = async () => {
        if (auth.currentUser) {
            const snap = await getDoc(doc(db, 'users', auth.currentUser.uid));
            if (snap.exists()) {
                setCurrentUserProfile({ id: snap.id, ...snap.data() } as UserProfile);
            }
        }
    };
    checkUser();

    return () => unsubscribeEvents();
  }, []);

  const openRegistration = (event: SolidarityEvent) => {
      if (!event.isRegistrable) return;
      setSelectedEvent(event);
      setRegSuccess(false);
      setGuestForm({ name: '', email: '', phone: '' });
  };

  const handleRegister = async (e: React.FormEvent) => {
      e.preventDefault();
      if (!selectedEvent) return;
      setRegLoading(true);

      try {
          const registrationData = {
              eventId: selectedEvent.id,
              eventTitle: selectedEvent.title,
              registeredAt: new Date().toISOString(),
              type: currentUserProfile ? 'MEMBER' : 'GUEST',
              name: currentUserProfile ? (currentUserProfile.displayName || 'Member') : guestForm.name,
              email: currentUserProfile ? currentUserProfile.email : guestForm.email,
              phone: currentUserProfile ? (currentUserProfile.phone || '') : guestForm.phone,
              userId: currentUserProfile ? currentUserProfile.id : null, 
              status: 'PENDING' // Added default pending status
          };

          await addDoc(collection(db, 'event_registrations'), registrationData);
          setRegSuccess(true);
      } catch (err: any) {
          console.error("Registration failed", err);
          showAlert({ 
            type: 'error', 
            title: 'Registration Failed',
            message: err.message || t('common.error') 
          });
      } finally {
          setRegLoading(false);
      }
  };

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-20">
      <div className="max-w-7xl mx-auto px-6">
        <div className="mb-16">
          <div className="inline-flex items-center gap-2 bg-rose-50 text-primary px-4 py-2 rounded-full text-xs font-bold mb-6">
             <Calendar size={14} /> Koretini Events
          </div>
          <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">{t('events.title')}</h1>
          <p className="text-xl text-stone-500 max-w-2xl leading-relaxed italic">
             {t('events.desc')}
          </p>
        </div>

        {loading ? (
           <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
               {[1,2,3].map(i => <div key={i} className="h-96 bg-stone-100 rounded-[2.5rem] animate-pulse" />)}
           </div>
        ) : (
           <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
             {events.map((event, index) => {
               const eventDate = new Date(event.date);
               const today = new Date();
               const diffDays = Math.ceil((eventDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
               
               return (
                 <motion.div 
                   key={event.id} 
                   initial={{ opacity: 0, y: 20 }}
                   animate={{ opacity: 1, y: 0 }}
                   transition={{ delay: index * 0.1 }}
                   className="bg-white rounded-[2.5rem] overflow-hidden border border-stone-100 shadow-sm hover:shadow-2xl hover:-translate-y-2 transition-all duration-300 group"
                 >
                    <div className="aspect-[4/3] overflow-hidden relative">
                       <img src={event.image} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" alt={event.title} />
                       <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-60" />
                       <div className="absolute top-4 left-4 bg-white/90 backdrop-blur-md px-4 py-2 rounded-xl text-center shadow-sm z-10">
                          <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{new Date(event.date).toLocaleString('default', { month: 'short' })}</p>
                          <p className="text-xl font-bold text-primary">{new Date(event.date).getDate()}</p>
                       </div>
                       <div className="absolute top-4 right-4 flex flex-col items-end gap-2">
                          {event.isFeatured && (
                            <div className="bg-amber-400 text-white p-2 rounded-xl shadow-lg">
                               <Heart size={16} fill="white" />
                            </div>
                          )}
                          {!event.isRegistrable && (
                            <div className="bg-blue-500/90 backdrop-blur-md text-white px-3 py-2 rounded-xl text-[9px] font-bold uppercase tracking-widest shadow-lg flex items-center gap-1">
                               <Info size={12} /> Info Only
                            </div>
                          )}
                          {diffDays > 30 && (
                            <div className="bg-emerald-500/90 backdrop-blur-md text-white px-3 py-2 rounded-xl text-[9px] font-bold uppercase tracking-widest shadow-lg">
                               Së shpejti
                            </div>
                          )}
                       </div>
                       <div className="absolute bottom-6 left-6 text-white">
                          <span className="bg-primary px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-widest mb-2 inline-block">{event.category}</span>
                       </div>
                    </div>
                    <div className="p-8">
                       <h3 className="text-2xl font-display font-bold mb-4 italic text-stone-900 leading-tight">{event.title}</h3>
                       <p className="text-stone-500 text-sm mb-8 line-clamp-3 leading-relaxed italic">"{event.description}"</p>
                       
                       <div className="space-y-3 pt-6 border-t border-stone-50">
                          <div className="flex items-center gap-3 text-sm text-stone-500">
                             <Clock size={16} className="text-primary" /> {event.time}
                          </div>
                          <div className="flex items-center gap-3 text-sm text-stone-500">
                             <MapPin size={16} className="text-primary" /> {event.location}
                          </div>
                       </div>
                       
                       {event.isRegistrable ? (
                          <button onClick={() => openRegistration(event)} className="w-full mt-6 bg-primary text-white py-4 rounded-xl text-sm font-bold transition-all flex items-center justify-center gap-2 group/btn shadow-lg shadow-rose-200">
                             {t('events.join')} <ChevronRight size={16} className="group-hover/btn:translate-x-1 transition-transform" />
                          </button>
                       ) : (
                          <div className="w-full mt-6 bg-stone-50 text-stone-400 py-4 rounded-xl text-xs font-bold flex items-center justify-center gap-2 border border-stone-100">
                             <Info size={14} /> Entry is free & public
                          </div>
                       )}
                    </div>
                 </motion.div>
               );
             })}
           </div>
        )}
      </div>

      {/* Registration Modal */}
      <AnimatePresence>
          {selectedEvent && (
              <div className="fixed inset-0 z-[200] flex items-center justify-center p-6">
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setSelectedEvent(null)} className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" />
                  <motion.div initial={{ scale: 0.9, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }} exit={{ scale: 0.9, opacity: 0, y: 20 }} className="bg-white w-full max-w-md rounded-[2.5rem] p-8 relative z-10 shadow-2xl">
                      <button onClick={() => setSelectedEvent(null)} className="absolute top-6 right-6 p-2 bg-stone-50 rounded-full hover:bg-stone-100 transition-colors"><X size={18}/></button>
                      
                      {regSuccess ? (
                          <div className="text-center py-8">
                              <div className="w-20 h-20 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
                                  <CheckCircle2 size={40} />
                              </div>
                              <h3 className="text-2xl font-bold text-stone-900 mb-2">{t('common.success')}</h3>
                              <p className="text-stone-500 mb-8">Ju keni kërkuar regjistrimin për <b>{selectedEvent.title}</b>. Ju do të njoftoheni kur të miratohet.</p>
                              <button onClick={() => setSelectedEvent(null)} className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold">Mbyll</button>
                          </div>
                      ) : (
                          <>
                              <div className="mb-8">
                                  <span className="text-[10px] font-bold text-primary uppercase tracking-widest">{selectedEvent.category}</span>
                                  <h3 className="text-2xl font-bold text-stone-900 mb-2">{selectedEvent.title}</h3>
                                  <p className="text-xs text-stone-500 flex items-center gap-1"><Calendar size={12}/> {new Date(selectedEvent.date).toLocaleDateString()} • {selectedEvent.time}</p>
                              </div>

                              <form onSubmit={handleRegister} className="space-y-4">
                                  {currentUserProfile ? (
                                      <div className="bg-stone-50 p-4 rounded-2xl border border-stone-100 flex items-center gap-4 mb-6">
                                          <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center font-bold text-primary shadow-sm border border-stone-100">
                                              {currentUserProfile.displayName?.charAt(0)}
                                          </div>
                                          <div>
                                              <p className="font-bold text-sm text-stone-900">{currentUserProfile.displayName}</p>
                                              <p className="text-xs text-stone-400">{currentUserProfile.email}</p>
                                          </div>
                                      </div>
                                  ) : (
                                      <>
                                          <p className="text-sm text-stone-500 mb-2">Ju lutem shënoni detajet tuaja për regjistrim.</p>
                                          <div className="relative">
                                              <User size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
                                              <input required type="text" placeholder="Emri i Plotë" value={guestForm.name} onChange={e => setGuestForm({...guestForm, name: e.target.value})} className="w-full pl-10 pr-4 py-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/50" />
                                          </div>
                                          <div className="relative">
                                              <Mail size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
                                              <input required type="email" placeholder="Email Adresa" value={guestForm.email} onChange={e => setGuestForm({...guestForm, email: e.target.value})} className="w-full pl-10 pr-4 py-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/50" />
                                          </div>
                                          <div className="relative">
                                              <Phone size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
                                              <input type="tel" placeholder="Telefoni (Opsionale)" value={guestForm.phone} onChange={e => setGuestForm({...guestForm, phone: e.target.value})} className="w-full pl-10 pr-4 py-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/50" />
                                          </div>
                                      </>
                                  )}

                                  <button type="submit" disabled={regLoading} className="w-full py-4 bg-primary text-white font-bold rounded-xl shadow-lg shadow-rose-200 flex items-center justify-center gap-2 hover:scale-[1.02] transition-all disabled:opacity-50">
                                      {regLoading ? <Loader2 className="animate-spin" /> : 'Konfirmo Regjistrimin'}
                                  </button>
                              </form>
                          </>
                      )}
                  </motion.div>
              </div>
          )}
      </AnimatePresence>
    </div>
  );
};

export default EventsPage;
