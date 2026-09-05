
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Mail, ArrowRight, ArrowLeft, User, Phone, Home, MapPin, Heart, CheckCircle2, ShieldCheck, Loader2, Search, X, Flag, Lock, Eye, EyeOff, Chrome, Camera, FileText } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';

// Firebase
import { auth, db } from '../services/firebase';
import { 
  createUserWithEmailAndPassword, 
  sendEmailVerification, 
  signOut,
  GoogleAuthProvider,
  signInWithPopup
} from '@/services/supabase-bridge';
import { collection, getDocs, query, orderBy, doc, setDoc } from '@/services/supabase-bridge';
import { Neighborhood } from '../types';

const RegistrationWizard: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    salutation: '',
    firstName: '',
    lastName: '',
    phone: '',
    street: '',
    zip: '',
    city: '',
    country: 'Zvicër', // Default to Switzerland
    neighborhoodId: '',
    photoFileName: '',
    invoiceDeliveryMethod: 'EMAIL' as 'EMAIL' | 'POST' | 'BOTH'
  });

  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);

  useEffect(() => {
    const fetchNeighborhoods = async () => {
      const q = query(collection(db, 'neighborhoods'), orderBy('name'));
      const snap = await getDocs(q);
      setNeighborhoods(snap.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)));
    };
    fetchNeighborhoods();
  }, []);

  const filteredNeighborhoods = neighborhoods.filter(n => 
    n.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    n.location.city.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleNext = () => {
    if (step < 4) setStep(step + 1);
  };

  const handlePrev = () => {
    if (step > 1) setStep(step - 1);
  };

  const handleGoogleSignUp = async () => {
    setIsLoading(true);
    setError(null);
    const provider = new GoogleAuthProvider();
    try {
      const result = await signInWithPopup(auth, provider);
      // If user doc doesn't exist, they'll be redirected to profile setup by App.tsx logic
      navigate('/dashboard');
    } catch (err: any) {
      console.error(err);
      setError(t('common.error'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // 1. Create User with Email and Password
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      const user = userCredential.user;

      // 2. Save Profile Data to Firestore
      const profileData = {
        email: formData.email,
        role: 'MEMBER',
        salutation: formData.salutation,
        firstName: formData.firstName,
        lastName: formData.lastName,
        displayName: `${formData.firstName} ${formData.lastName}`,
        phone: formData.phone,
        street: formData.street,
        zip: formData.zip,
        city: formData.city,
        country: formData.country,
        address: `${formData.street}, ${formData.zip} ${formData.city}, ${formData.country}`,
        neighborhoodId: formData.neighborhoodId,
        invoiceDeliveryMethod: formData.invoiceDeliveryMethod, // Save preference
        membershipStatus: 'PENDING',
        joinedAt: new Date().toISOString(),
        profileComplete: true,
        photoFileName: formData.photoFileName || ''
      };
      
      await setDoc(doc(db, 'users', user.uid), profileData);

      // 3. Send Email Verification
      await sendEmailVerification(user);

      // 4. Sign out automatically as per request
      await signOut(auth);
      
      setStep(4);
    } catch (err: any) {
      console.error(err);
      if (err.code === 'auth/email-already-in-use') {
        setError(t('common.error') + ": Email used.");
      } else {
        setError(err.message || t('common.error'));
      }
    } finally {
      setIsLoading(false);
    }
  };

  const steps = [
    { id: 1, label: t('wizard.step.1'), icon: <Mail size={18} /> },
    { id: 2, label: t('wizard.step.2'), icon: <User size={18} /> },
    { id: 3, label: t('wizard.step.3'), icon: <MapPin size={18} /> },
    { id: 4, label: t('wizard.step.4'), icon: <ShieldCheck size={18} /> },
  ];

  const isStep1Valid = formData.email && formData.password.length >= 6;
  const isStep2Valid = formData.salutation && formData.firstName && formData.lastName && formData.phone;
  const isStep3Valid = formData.street && formData.zip && formData.city && formData.country && formData.neighborhoodId;

  return (
    <div className="min-h-screen bg-[#faf9f6] flex items-center justify-center p-6">
      <div className="absolute top-8 left-8">
        <Link to="/" className="flex items-center gap-2 text-stone-500 hover:text-primary transition-colors font-bold text-sm uppercase tracking-widest">
          <ArrowLeft size={18} /> {t('login.back')}
        </Link>
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-5xl w-full bg-white rounded-[3rem] shadow-2xl overflow-hidden border border-stone-100 flex flex-col md:flex-row min-h-[650px]"
      >
        {/* Left Info Panel */}
        <div className="w-full md:w-1/3 bg-primary p-12 text-white flex flex-col justify-between relative overflow-hidden">
          <div className="relative z-10">
            <Heart fill="white" size={48} className="mb-12" />
            <h2 className="text-4xl font-display font-bold italic mb-6 leading-tight">{t('wizard.title')}</h2>
            <p className="text-rose-50/80 italic text-lg leading-relaxed">
              {t('hero.subtitle')}
            </p>
          </div>
          
          <div className="relative z-10 pt-12">
            <div className="flex flex-col gap-6">
              {steps.map((s) => (
                <div key={s.id} className={`flex items-center gap-4 transition-opacity duration-500 ${step === s.id ? 'opacity-100' : 'opacity-40'}`}>
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center border ${step === s.id ? 'bg-white text-primary' : 'border-white/30 text-white'}`}>
                    {s.icon}
                  </div>
                  <span className="text-[10px] font-bold uppercase tracking-[0.2em]">{s.label}</span>
                </div>
              ))}
            </div>
          </div>
          
          <div className="absolute -bottom-20 -left-20 w-64 h-64 bg-white/10 rounded-full blur-3xl" />
        </div>

        {/* Right Form Panel */}
        <div className="flex-1 p-8 lg:p-12 flex flex-col">
          <AnimatePresence mode="wait">
            {step === 1 && (
              <motion.div key="s1" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="flex-1">
                <h3 className="text-3xl font-display font-bold mb-8 italic text-stone-900">{t('wizard.step.1')}</h3>
                
                {error && (step === 1) && (
                  <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-sm italic">
                    {error}
                  </div>
                )}

                <div className="space-y-6">
                  <button 
                    onClick={handleGoogleSignUp}
                    disabled={isLoading}
                    className="w-full flex items-center justify-center gap-4 py-5 bg-white border-2 border-stone-100 rounded-2xl font-bold text-stone-700 hover:bg-stone-50 transition-all shadow-sm hover:shadow-md disabled:opacity-50"
                  >
                    <Chrome size={22} className="text-blue-500" /> {t('login.google')}
                  </button>

                  <div className="relative py-4">
                    <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-stone-100"></div></div>
                    <div className="relative flex justify-center text-[10px] uppercase tracking-[0.4em] font-bold text-stone-300 bg-white px-6">{t('common.or')}</div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-stone-400 mb-3 uppercase tracking-widest">{t('login.email.label')}</label>
                    <div className="relative">
                      <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                      <input 
                        type="email" 
                        required
                        value={formData.email}
                        onChange={(e) => setFormData({...formData, email: e.target.value})}
                        placeholder={t('login.email.placeholder')}
                        className="w-full pl-16 pr-6 py-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-stone-400 mb-3 uppercase tracking-widest">{t('login.password.label')}</label>
                    <div className="relative">
                      <Lock className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                      <input 
                        type={showPassword ? "text" : "password"} 
                        required
                        value={formData.password}
                        onChange={(e) => setFormData({...formData, password: e.target.value})}
                        placeholder="••••••••"
                        className="w-full pl-16 pr-14 py-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                      />
                      <button 
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-6 top-1/2 -translate-y-1/2 text-stone-300 hover:text-stone-500 transition-colors"
                      >
                        {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                      </button>
                    </div>
                  </div>
                  <p className="text-sm text-stone-400 italic text-center">{t('auth.has_account')} <Link to="/login" className="text-primary font-bold hover:underline">{t('nav.login')}</Link></p>
                </div>
              </motion.div>
            )}

            {step === 2 && (
              <motion.div key="s2" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="flex-1">
                <h3 className="text-3xl font-display font-bold mb-8 italic text-stone-900">{t('wizard.step.2')}</h3>
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="space-y-3">
                      <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('field.salutation')}</label>
                      <select 
                        value={formData.salutation}
                        onChange={(e) => setFormData({...formData, salutation: e.target.value})}
                        className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium appearance-none"
                      >
                        <option value="">{t('common.select')}</option>
                        <option value="Z.">Z.</option>
                        <option value="Znj.">Znj.</option>
                      </select>
                    </div>
                    <div className="md:col-span-2 space-y-3">
                      <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('field.firstName')}</label>
                      <div className="relative">
                        <User className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                        <input 
                          type="text" 
                          value={formData.firstName}
                          onChange={(e) => setFormData({...formData, firstName: e.target.value})}
                          placeholder="Filan"
                          className="w-full pl-16 pr-6 py-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-3">
                      <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('field.lastName')}</label>
                      <div className="relative">
                        <User className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                        <input 
                          type="text" 
                          value={formData.lastName}
                          onChange={(e) => setFormData({...formData, lastName: e.target.value})}
                          placeholder="Fisteku"
                          className="w-full pl-16 pr-6 py-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                        />
                      </div>
                    </div>
                    <div className="space-y-3">
                      <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('field.phone')}</label>
                      <div className="relative">
                        <Phone className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                        <input 
                          type="tel" 
                          value={formData.phone}
                          onChange={(e) => setFormData({...formData, phone: e.target.value})}
                          placeholder="+41 79 000 00 00"
                          className="w-full pl-16 pr-6 py-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {step === 3 && (
              <motion.div key="s3" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="flex-1">
                <h3 className="text-3xl font-display font-bold mb-6 italic text-stone-900">{t('wizard.step.3')}</h3>
                
                {error && (step === 3) && (
                  <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-sm italic">
                    {error}
                  </div>
                )}

                <div className="space-y-6">
                  {/* Address Fields */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest">{t('field.street')}</label>
                      <div className="relative">
                        <Home className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-300" size={16} />
                        <input 
                          type="text"
                          value={formData.street}
                          onChange={(e) => setFormData({...formData, street: e.target.value})}
                          placeholder="Bahnhofstrasse 12"
                          className="w-full pl-12 pr-4 py-3 bg-stone-50 border-2 border-stone-100 rounded-xl outline-none focus:border-primary/30 text-sm font-medium"
                        />
                      </div>
                    </div>
                    <div className="grid grid-cols-3 gap-3">
                      <div className="space-y-2 col-span-1">
                        <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest">{t('field.zip')}</label>
                        <input 
                          type="text"
                          value={formData.zip}
                          onChange={(e) => setFormData({...formData, zip: e.target.value})}
                          placeholder="8000"
                          className="w-full px-4 py-3 bg-stone-50 border-2 border-stone-100 rounded-xl outline-none focus:border-primary/30 text-sm font-medium"
                        />
                      </div>
                      <div className="space-y-2 col-span-2">
                        <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest">{t('field.city')}</label>
                        <input 
                          type="text"
                          value={formData.city}
                          onChange={(e) => setFormData({...formData, city: e.target.value})}
                          placeholder="Zürich"
                          className="w-full px-4 py-3 bg-stone-50 border-2 border-stone-100 rounded-xl outline-none focus:border-primary/30 text-sm font-medium"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                     <div className="space-y-2">
                        <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest">{t('field.country')}</label>
                        <div className="relative">
                          <Flag className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-300" size={16} />
                          <input 
                            type="text"
                            value={formData.country}
                            onChange={(e) => setFormData({...formData, country: e.target.value})}
                            placeholder="Zvicër"
                            className="w-full pl-12 pr-4 py-3 bg-stone-50 border-2 border-stone-100 rounded-xl outline-none focus:border-primary/30 text-sm font-medium"
                          />
                        </div>
                      </div>
                      
                      {/* Invoice Delivery Preference */}
                      <div className="space-y-2">
                        <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-1"><FileText size={10} /> Invoice Delivery</label>
                        <div className="grid grid-cols-3 gap-2">
                            {(['EMAIL', 'POST', 'BOTH'] as const).map(method => (
                                <button
                                    key={method}
                                    type="button"
                                    onClick={() => setFormData({...formData, invoiceDeliveryMethod: method})}
                                    className={`py-2 px-1 rounded-xl border-2 text-[10px] font-bold uppercase tracking-wider transition-all ${formData.invoiceDeliveryMethod === method ? 'border-primary bg-primary/10 text-primary' : 'border-stone-100 text-stone-400 hover:border-stone-200 bg-white'}`}
                                >
                                    {method}
                                </button>
                            ))}
                        </div>
                      </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-[9px] font-bold text-stone-400 uppercase tracking-widest">{t('dash.neighborhood.title')}</label>
                    <div className="relative">
                      <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-300" size={16} />
                      <input 
                        type="text"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        placeholder="Search neighborhood..."
                        className="w-full pl-12 pr-4 py-3 bg-stone-50 border-2 border-stone-100 rounded-xl outline-none focus:border-primary/30 text-sm font-medium"
                      />
                    </div>
                  </div>

                  {/* Contained Neighborhood Selection Box */}
                  <div className="bg-stone-50 border-2 border-stone-100 rounded-2xl p-3">
                    <div className="h-32 overflow-y-auto pr-2 custom-scrollbar grid grid-cols-1 gap-2">
                      {filteredNeighborhoods.length > 0 ? (
                        filteredNeighborhoods.map(n => (
                          <button
                            key={n.id}
                            type="button"
                            onClick={() => setFormData({...formData, neighborhoodId: n.id})}
                            className={`p-3 rounded-xl border-2 text-left transition-all flex items-center justify-between group ${formData.neighborhoodId === n.id ? 'border-primary bg-white shadow-md' : 'border-white bg-white/50 hover:bg-white hover:border-stone-100'}`}
                          >
                            <div className="flex items-center gap-3">
                              <div className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors ${formData.neighborhoodId === n.id ? 'bg-primary text-white' : 'bg-stone-100 text-stone-400 group-hover:bg-stone-200'}`}>
                                <MapPin size={12} />
                              </div>
                              <div>
                                <p className={`font-bold text-xs transition-colors ${formData.neighborhoodId === n.id ? 'text-primary' : 'text-stone-800'}`}>{n.name}</p>
                                <p className="text-[8px] text-stone-400 uppercase tracking-widest">{n.location.city}</p>
                              </div>
                            </div>
                            {formData.neighborhoodId === n.id && (
                              <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }}>
                                <CheckCircle2 className="text-primary" size={16} />
                              </motion.div>
                            )}
                          </button>
                        ))
                      ) : (
                        <div className="flex flex-col items-center justify-center h-full text-stone-400 py-4 italic">
                          <p className="text-[10px]">...</p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {step === 4 && (
              <motion.div key="s4" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="flex-1 text-center flex flex-col items-center justify-center py-12">
                <div className="w-24 h-24 bg-green-50 text-green-500 rounded-3xl flex items-center justify-center mb-8 shadow-inner relative">
                  <ShieldCheck size={48} />
                  <div className="absolute inset-0 bg-green-500/10 rounded-3xl animate-ping" />
                </div>
                <h3 className="text-4xl font-display font-bold mb-4 italic text-stone-900">{t('wizard.success.title')}</h3>
                <p className="text-stone-500 text-lg leading-relaxed max-w-sm mx-auto mb-10 italic">
                  {t('wizard.success.desc')} <br/>
                  <span className="font-bold text-stone-900 border-b-2 border-rose-100">{formData.email}</span>. 
                </p>
                <Link 
                  to="/login" 
                  className="bg-primary text-white px-10 py-4 rounded-2xl font-bold flex items-center gap-3 shadow-xl shadow-rose-200 hover:scale-105 transition-all"
                >
                  <ArrowLeft size={20} /> {t('login.submit')}
                </Link>
              </motion.div>
            )}
          </AnimatePresence>

          {step < 4 && (
            <div className="mt-auto pt-8 border-t border-stone-50 flex items-center justify-between">
              <button 
                onClick={handlePrev} 
                disabled={step === 1}
                className="flex items-center gap-2 text-stone-400 font-bold hover:text-stone-900 transition-colors uppercase tracking-widest text-xs disabled:opacity-0"
              >
                <ArrowLeft size={16} /> {t('wizard.prev')}
              </button>
              
              <div className="flex gap-4">
                <button 
                  onClick={step === 3 ? handleSubmit : handleNext}
                  disabled={isLoading || (step === 1 && !isStep1Valid) || (step === 2 && !isStep2Valid) || (step === 3 && !isStep3Valid)}
                  className="bg-primary text-white px-10 py-4 rounded-2xl font-bold flex items-center gap-3 shadow-xl shadow-rose-200 hover:scale-105 transition-all disabled:opacity-50"
                >
                  {isLoading ? <Loader2 className="animate-spin" /> : step === 3 ? t('wizard.finish') : t('wizard.next')} <ArrowRight size={20} />
                </button>
              </div>
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default RegistrationWizard;
