
import React, { useState, useEffect } from 'react';
import CountrySelect from './ui/CountrySelect';
import { motion, AnimatePresence } from 'framer-motion';
import { UserProfile, Neighborhood, BillingGroup } from '../types';
import { db } from '../services/firebase';
import { doc, setDoc, updateDoc, collection, getDocs, query, orderBy } from '@/services/supabase-bridge';
import { MapPin, User, Phone, CheckCircle2, ArrowRight, ArrowLeft, Loader2, Mail, Home, Heart, FileText } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { emailMissingForDelivery } from '../lib/memberEmail';

import { neighborhoodCity } from '../lib/neighborhood';
import { matchCountry } from '../lib/countries';
const ProfileSetup: React.FC<{ user: UserProfile, onComplete: (u: UserProfile) => void }> = ({ user, onComplete }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [step, setStep] = useState(1);
  // Vorbelegung aus dem bestehenden Datensatz.
  //
  // Vorher stand hier ueberall der Leerstring: wer seit Jahren Mitglied ist,
  // sah Telefon, Adresse und Nachbarschaft leer und musste alles noch einmal
  // eintippen -- obwohl es in der Datenbank steht. Gefuellt wird aus den
  // getrennten Feldern street/zip/city; das alte Sammelfeld address dient nur
  // noch als Rueckfall fuer Datensaetze, bei denen street leer blieb.
  const [formData, setFormData] = useState({
    name: user.displayName || [user.firstName, user.lastName].filter(Boolean).join(' ') || '',
    phone: user.phone || '',
    street: user.street || (user as any).address || '',
    zip: user.zip || '',
    city: user.city || '',
    country: matchCountry(user.country) || 'Schweiz',
    neighborhoodId: user.neighborhoodId || '',
    invoiceDeliveryMethod: (user.invoiceDeliveryMethod || 'EMAIL') as 'EMAIL' | 'POST' | 'BOTH'
  });
  
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchNeighborhoods = async () => {
      const q = query(collection(db, 'neighborhoods'), orderBy('name'));
      const snap = await getDocs(q);
      setNeighborhoods(snap.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)));
    };
    fetchNeighborhoods();
  }, []);

  const handleNext = () => setStep(s => s + 1);
  const handlePrev = () => setStep(s => s - 1);

  const handleSubmit = async () => {
    // Wer die Rechnung per E-Mail will, braucht eine E-Mail-Adresse.
    if (emailMissingForDelivery({ ...user, ...formData } as any)) {
      showAlert({ type: 'error', message: t('email.required_for_delivery') });
      return;
    }
    setIsLoading(true);

    // Auto-determine billing group based on country
    let billingGroup: BillingGroup = 'STANDARD';
    const c = formData.country.toLowerCase().trim();
    if (c === 'kosovo' || c === 'kosova' || c === 'albania' || c === 'shqiperi' || c === 'shqipëri') {
        billingGroup = 'KOSOVO';
    }

    const teile = formData.name.trim().split(/\s+/);

    const updatedProfile: UserProfile = {
      ...user,
      displayName: formData.name.trim(),
      // Vor- und Nachname mitfuehren, sonst stehen sie im Mitglieder-Detail
      // weiterhin leer -- dieselbe Luecke, die im Bestand schon einmal
      // nachtraeglich geschlossen werden musste.
      firstName: user.firstName || (teile.length > 1 ? teile.slice(0, -1).join(' ') : teile[0] || ''),
      lastName: user.lastName || (teile.length > 1 ? teile[teile.length - 1] : ''),
      street: formData.street.trim(),
      zip: formData.zip.trim(),
      city: formData.city.trim(),
      // Das alte Sammelfeld gleich mitfuehren: die QR-Rechnung liest address
      // vor street, ein stehengebliebener Wert wuerde die berichtigte Strasse
      // auf der Rechnung ueberstimmen.
      address: formData.street.trim(),
      phone: formData.phone.trim(),
      country: formData.country,
      neighborhoodId: formData.neighborhoodId,
      invoiceDeliveryMethod: formData.invoiceDeliveryMethod,
      billingGroup: billingGroup, // Set detected group
      profileComplete: true,
      joinedAt: user.joinedAt || new Date().toISOString()
    };

    try {
      // Aendern, nicht einfuegen.
      //
      // setDoc schreibt als Upsert, und PostgreSQL prueft dabei die
      // INSERT-Regel. Deren Selbst-Zweig verlangt id = auth.uid(); die
      // Kennungen der 339 uebernommenen Mitglieder stammen aber aus dem
      // Altbestand. Das Speichern scheiterte deshalb mit "new row violates
      // row-level security policy" -- obwohl die UPDATE-Regel den Zugriff auf
      // die eigene Zeile ausdruecklich erlaubt, sobald sie dem Konto
      // zugeordnet ist. Die Zeile existiert; sie gehoert geaendert.
      //
      // Geschrieben werden nur die Felder dieses Assistenten. role bleibt
      // aussen vor: die UPDATE-Regel verlangt, dass die Rolle unveraendert
      // bleibt, und was nicht mitgeschickt wird, kann sich nicht aendern.
      await updateDoc(doc(db, 'users', user.id), {
        displayName: updatedProfile.displayName,
        firstName: updatedProfile.firstName,
        lastName: updatedProfile.lastName,
        street: updatedProfile.street,
        zip: updatedProfile.zip,
        city: updatedProfile.city,
        address: updatedProfile.address,
        phone: updatedProfile.phone,
        country: updatedProfile.country,
        neighborhoodId: updatedProfile.neighborhoodId,
        invoiceDeliveryMethod: updatedProfile.invoiceDeliveryMethod,
        billingGroup: updatedProfile.billingGroup,
        profileComplete: true,
      } as any);
      onComplete(updatedProfile);
      setStep(4); // Success step
    } catch (error: any) {
      // Frueher landete der Fehler nur auf der Konsole. Nach aussen sah das
      // aus, als bewege sich nichts -- der Knopf war gedrueckt und die Seite
      // blieb stehen. Wer scheitert, muss es sagen.
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: error?.message || '?' }) });
    } finally {
      setIsLoading(false);
    }
  };

  const steps = [
    { id: 1, label: t('wizard.step.1'), icon: <User size={18} /> },
    { id: 2, label: t('wizard.step.2'), icon: <Home size={18} /> },
    { id: 3, label: t('wizard.step.3'), icon: <MapPin size={18} /> },
    { id: 4, label: t('wizard.step.4'), icon: <Heart size={18} /> },
  ];

  return (
    <div className="min-h-screen bg-[#faf9f6] flex items-center justify-center p-6">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="max-w-3xl w-full bg-white rounded-[3rem] shadow-2xl overflow-hidden border border-stone-100"
      >
        {/* Progress Header */}
        <div className="bg-stone-900 p-10 text-white relative">
          <div className="relative z-10">
            <h2 className="text-3xl font-display font-bold mb-8 italic">{t('wizard.title')}</h2>
            
            <div className="flex justify-between relative">
              <div className="absolute top-1/2 left-0 w-full h-px bg-white/10 -z-10 -translate-y-1/2" />
              {steps.map((s) => (
                <div key={s.id} className="flex flex-col items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all border ${step >= s.id ? 'bg-primary border-primary text-white' : 'bg-stone-800 border-stone-700 text-stone-500'}`}>
                    {s.icon}
                  </div>
                  <span className={`text-[9px] font-bold uppercase tracking-widest ${step >= s.id ? 'text-white' : 'text-stone-600'}`}>
                    {s.label}
                  </span>
                </div>
              ))}
            </div>
          </div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/20 blur-3xl rounded-full -translate-y-1/2 translate-x-1/2" />
        </div>

        <div className="p-12 min-h-[450px] flex flex-col">
          <AnimatePresence mode="wait">
            {step === 1 && (
              <motion.div 
                key="step1"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="space-y-8 flex-1"
              >
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div className="space-y-3">
                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-2">
                      <User size={14} className="text-primary" /> {t('setup.name.label')}
                    </label>
                    <input 
                      type="text" 
                      value={formData.name}
                      onChange={(e) => setFormData({...formData, name: e.target.value})}
                      placeholder={t('ph.fullname')}
                      className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                    />
                  </div>
                  <div className="space-y-3">
                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-2">
                      <Phone size={14} className="text-primary" /> {t('setup.phone.label')}
                    </label>
                    <input 
                      type="tel" 
                      value={formData.phone}
                      onChange={(e) => setFormData({...formData, phone: e.target.value})}
                      placeholder={t('ph.phone')}
                      className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                    />
                  </div>
                </div>
                <div className="p-6 bg-rose-50 rounded-2xl border border-rose-100 flex items-start gap-4">
                  <Mail className="text-primary shrink-0" size={20} />
                  <p className="text-sm text-stone-600 italic">E-Maili juaj <b>{user.email}</b> do të përdoret për të dërguar faturën e anëtarësisë çdo vit.</p>
                </div>
              </motion.div>
            )}

            {step === 2 && (
              <motion.div 
                key="step2"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="space-y-8 flex-1"
              >
                <div className="space-y-3">
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-2">
                    <Home size={14} className="text-primary" /> {t('wizard.step.2')}
                  </label>
                  <input
                    value={formData.street}
                    onChange={(e) => setFormData({...formData, street: e.target.value})}
                    placeholder={t('admin.members.street_no')}
                    className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                  />
                  <div className="grid grid-cols-3 gap-4">
                    <input
                      value={formData.zip}
                      onChange={(e) => setFormData({...formData, zip: e.target.value})}
                      placeholder={t('field.zip')}
                      className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                    />
                    <input
                      value={formData.city}
                      onChange={(e) => setFormData({...formData, city: e.target.value})}
                      placeholder={t('field.city')}
                      className="col-span-2 w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="space-y-3">
                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-2">
                            <MapPin size={14} className="text-primary" /> {t('field.country')}
                        </label>
                        <CountrySelect
                            value={formData.country}
                            onChange={(v) => setFormData({...formData, country: v})}
                            className="w-full p-5 bg-stone-50 border-2 border-stone-100 rounded-2xl outline-none focus:border-primary/30 transition-all text-lg font-medium"
                        />
                        <p className="text-xs text-stone-400 italic">{t('form.fee_hint')}</p>
                    </div>

                    <div className="space-y-3">
                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-2">
                            <FileText size={14} className="text-primary" /> {t('form.invoice_preference')}
                        </label>
                        <div className="grid grid-cols-3 gap-4">
                            {(['EMAIL', 'POST', 'BOTH'] as const).map(method => (
                                <button
                                    key={method}
                                    type="button"
                                    onClick={() => setFormData({...formData, invoiceDeliveryMethod: method})}
                                    className={`p-4 rounded-2xl border-2 text-sm font-bold transition-all ${formData.invoiceDeliveryMethod === method ? 'border-primary bg-primary/5 text-primary' : 'border-stone-100 text-stone-400 hover:border-stone-200'}`}
                                >
                                    {method}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>
              </motion.div>
            )}

            {step === 3 && (
              <motion.div 
                key="step3"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="space-y-6 flex-1"
              >
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {neighborhoods.map(n => (
                    <button
                      key={n.id}
                      type="button"
                      onClick={() => setFormData({...formData, neighborhoodId: n.id})}
                      className={`p-6 rounded-2xl border-2 text-left transition-all flex items-center justify-between group ${formData.neighborhoodId === n.id ? 'border-primary bg-primary/5 shadow-lg' : 'border-stone-100 hover:border-stone-200 hover:bg-stone-50'}`}
                    >
                      <div>
                        <p className={`font-bold transition-colors ${formData.neighborhoodId === n.id ? 'text-primary' : 'text-stone-900'}`}>{n.name}</p>
                        <p className="text-xs text-stone-500 uppercase tracking-widest">{neighborhoodCity(n)}</p>
                      </div>
                      <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all ${formData.neighborhoodId === n.id ? 'bg-primary border-primary text-white' : 'border-stone-200'}`}>
                        {formData.neighborhoodId === n.id && <CheckCircle2 size={14} />}
                      </div>
                    </button>
                  ))}
                </div>
              </motion.div>
            )}

            {step === 4 && (
              <motion.div 
                key="step4"
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                className="text-center py-10 space-y-8 flex-1"
              >
                <div className="w-24 h-24 bg-green-50 text-green-500 rounded-3xl flex items-center justify-center mx-auto shadow-inner relative">
                  <CheckCircle2 size={48} />
                  <motion.div 
                    animate={{ scale: [1, 1.5, 1], opacity: [0.5, 0, 0.5] }}
                    transition={{ duration: 2, repeat: Infinity }}
                    className="absolute inset-0 bg-green-500/20 rounded-3xl"
                  />
                </div>
                <div>
                  <h3 className="text-4xl font-display font-bold mb-4 italic text-stone-900">{t('wizard.success.title')}</h3>
                  <p className="text-stone-500 text-lg leading-relaxed max-w-sm mx-auto italic">{t('wizard.success.desc')}</p>
                </div>
                <button 
                  onClick={() => navigate('/dashboard')}
                  className="bg-stone-900 text-white px-10 py-5 rounded-2xl font-bold flex items-center justify-center gap-3 mx-auto hover:bg-stone-800 transition-all shadow-xl"
                >
                  {t('wizard.finish')} <ArrowRight size={20} />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {step < 4 && (
            <div className="flex justify-between items-center mt-auto pt-10 border-t border-stone-50">
              <button 
                onClick={handlePrev} 
                disabled={step === 1}
                className="flex items-center gap-2 text-stone-400 font-bold disabled:opacity-0 hover:text-stone-900 transition-colors uppercase tracking-widest text-xs"
              >
                <ArrowLeft size={16} /> {t('wizard.prev')}
              </button>
              
              <button 
                onClick={step === 3 ? handleSubmit : handleNext}
                disabled={isLoading || (step === 1 && !formData.name) || (step === 2 && (!formData.street.trim() || !formData.zip.trim() || !formData.city.trim() || !formData.country)) || (step === 3 && !formData.neighborhoodId)}
                className="bg-primary text-white px-10 py-4 rounded-2xl font-bold flex items-center gap-3 hover:opacity-90 transition-all shadow-xl shadow-rose-100 disabled:opacity-50"
              >
                {isLoading ? <Loader2 className="animate-spin" /> : step === 3 ? t('wizard.finish') : t('wizard.next')} <ArrowRight size={18} />
              </button>
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default ProfileSetup;
