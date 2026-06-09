
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  Settings, 
  Power, 
  Shield, 
  Globe, 
  Save, 
  Loader2, 
  LayoutTemplate,
  ToggleLeft,
  ToggleRight,
  Mail,
  AlertTriangle,
  Server,
  Banknote
} from 'lucide-react';
import { db } from '../services/firebase';
import { doc, onSnapshot, setDoc, serverTimestamp } from 'firebase/firestore';
import { SystemSettings, GlobalPaymentSettings } from '../types';
import { useFeedback } from '../context/FeedbackContext';

const AdminSettings: React.FC = () => {
  const { showAlert } = useFeedback();
  const [loading, setLoading] = useState(false);
  
  // System Settings
  const [settings, setSettings] = useState<SystemSettings>({
    maintenanceMode: false,
    allowRegistration: true,
    modules: {
      villageLive: true,
      events: true,
      news: true
    },
    systemEmail: 'admin@koretini.org'
  });

  // Payment Settings (for Fee Structure)
  const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings>({
      iban: '', bankName: '', bic: '', accountHolder: '', street: '', zip: '', city: '', country: '', paypalEmail: '', currency: 'CHF', annualFeeAmount: 100,
      fees: {
          STANDARD: { amount: 120, currency: 'CHF', label: 'Standard (Diaspora)' },
          KOSOVO: { amount: 12, currency: 'EUR', label: 'Resident (Kosovo)' },
          REDUCED: { amount: 100, currency: 'EUR', label: 'Reduced (Special)' }
      }
  });

  useEffect(() => {
    const unsubSystem = onSnapshot(doc(db, 'settings', 'system'), (snap) => {
      if (snap.exists()) {
        const data = snap.data() as SystemSettings;
        setSettings(prev => ({
            ...prev,
            ...data,
            modules: { ...prev.modules, ...(data.modules || {}) }
        }));
      }
    });

    const unsubPayment = onSnapshot(doc(db, 'settings', 'payment'), (snap) => {
        if(snap.exists()) {
            const data = snap.data() as GlobalPaymentSettings;
            setPaymentSettings(prev => ({
                ...prev,
                ...data,
                fees: {
                    STANDARD: { amount: 120, currency: 'CHF', label: 'Standard', ...data.fees?.STANDARD },
                    KOSOVO: { amount: 12, currency: 'EUR', label: 'Resident', ...data.fees?.KOSOVO },
                    REDUCED: { amount: 100, currency: 'EUR', label: 'Reduced', ...data.fees?.REDUCED },
                }
            }));
        }
    });

    return () => { unsubSystem(); unsubPayment(); };
  }, []);

  const handleSave = async () => {
    setLoading(true);
    try {
      await setDoc(doc(db, 'settings', 'system'), {
          ...settings,
          updatedAt: serverTimestamp()
      }, { merge: true });

      await setDoc(doc(db, 'settings', 'payment'), paymentSettings, { merge: true });
      
      showAlert({ type: 'success', message: 'System settings updated successfully.' });
    } catch (err) {
      console.error(err);
      showAlert({ type: 'error', message: 'Failed to update settings.' });
    } finally {
      setLoading(false);
    }
  };

  const Toggle = ({ checked, onChange, label, description }: { checked: boolean, onChange: (val: boolean) => void, label: string, description?: string }) => (
    <div className="flex items-center justify-between p-4 bg-white rounded-2xl border border-stone-100 shadow-sm">
        <div className="flex items-center gap-4">
            <div onClick={() => onChange(!checked)} className={`cursor-pointer transition-colors ${checked ? 'text-primary' : 'text-stone-300'}`}>
                {checked ? <ToggleRight size={40} /> : <ToggleLeft size={40} />}
            </div>
            <div>
                <p className="font-bold text-stone-900 text-sm">{label}</p>
                {description && <p className="text-xs text-stone-400">{description}</p>}
            </div>
        </div>
        <div className={`w-3 h-3 rounded-full ${checked ? 'bg-green-500 animate-pulse' : 'bg-stone-200'}`} />
    </div>
  );

  return (
    <div className="max-w-5xl mx-auto space-y-8 min-h-[600px] p-2">
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div>
                <h2 className="text-3xl font-display font-bold italic mb-2">System Control</h2>
                <p className="text-stone-500">Global platform configuration and feature flags.</p>
            </div>
            
            <div className={`px-6 py-3 rounded-2xl border flex items-center gap-3 ${settings.maintenanceMode ? 'bg-amber-50 border-amber-200 text-amber-700' : 'bg-green-50 border-green-200 text-green-700'}`}>
                <Server size={20} />
                <div>
                    <p className="text-xs font-bold uppercase tracking-widest">System Status</p>
                    <p className="font-bold">{settings.maintenanceMode ? 'MAINTENANCE MODE' : 'OPERATIONAL'}</p>
                </div>
                <div className={`w-3 h-3 rounded-full ml-2 ${settings.maintenanceMode ? 'bg-amber-500' : 'bg-green-500'} animate-pulse`} />
            </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            
            {/* Access Control */}
            <section className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <Shield size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Access & Security</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <Toggle 
                        label="Maintenance Mode" 
                        description="Only admins can access the dashboard."
                        checked={settings.maintenanceMode} 
                        onChange={v => setSettings({...settings, maintenanceMode: v})} 
                    />
                    <Toggle 
                        label="Allow Registration" 
                        description="New users can sign up via the wizard."
                        checked={settings.allowRegistration} 
                        onChange={v => setSettings({...settings, allowRegistration: v})} 
                    />
                </div>
            </section>

            {/* Modules */}
            <section className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <LayoutTemplate size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Module Visibility</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <Toggle 
                        label="Village Live 3D" 
                        checked={settings.modules.villageLive} 
                        onChange={v => setSettings({...settings, modules: {...settings.modules, villageLive: v}})} 
                    />
                    <Toggle 
                        label="Events Calendar" 
                        checked={settings.modules.events} 
                        onChange={v => setSettings({...settings, modules: {...settings.modules, events: v}})} 
                    />
                    <Toggle 
                        label="News Feed" 
                        checked={settings.modules.news} 
                        onChange={v => setSettings({...settings, modules: {...settings.modules, news: v}})} 
                    />
                </div>
            </section>

            {/* FEE STRUCTURE */}
            <section className="space-y-4 md:col-span-2">
                <div className="flex items-center gap-2 mb-2">
                    <Banknote size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Fee Structure (Billing Groups)</h3>
                </div>
                <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm grid grid-cols-1 md:grid-cols-3 gap-6">
                    {/* STANDARD */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-stone-200 text-stone-500 px-2 py-1 rounded">STANDARD</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">Diaspora & Switzerland</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.STANDARD.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, STANDARD: { ...paymentSettings.fees!.STANDARD, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.STANDARD.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, STANDARD: { ...paymentSettings.fees!.STANDARD, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>

                    {/* KOSOVO */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-blue-100 text-blue-600 px-2 py-1 rounded">RESIDENT (XK)</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">Locals in Kosovo</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.KOSOVO.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, KOSOVO: { ...paymentSettings.fees!.KOSOVO, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.KOSOVO.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, KOSOVO: { ...paymentSettings.fees!.KOSOVO, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>

                    {/* REDUCED */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-amber-100 text-amber-600 px-2 py-1 rounded">REDUCED</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">Students / Special</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.REDUCED.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, REDUCED: { ...paymentSettings.fees!.REDUCED, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.REDUCED.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, REDUCED: { ...paymentSettings.fees!.REDUCED, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>
                </div>
            </section>

            {/* Communication */}
            <section className="space-y-4 md:col-span-2">
                <div className="flex items-center gap-2 mb-2">
                    <Mail size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Communication</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 block">System Reply-To Email</label>
                        <input 
                            type="email" 
                            value={settings.systemEmail} 
                            onChange={e => setSettings({...settings, systemEmail: e.target.value})}
                            className="w-full p-4 bg-white border border-stone-200 rounded-xl font-bold text-stone-700 outline-none focus:border-primary/50"
                        />
                        <p className="text-xs text-stone-400 mt-2">Used for automated invoice notifications.</p>
                    </div>
                    <div className="flex items-center justify-center p-4 bg-amber-50 rounded-2xl border border-amber-100">
                        <div className="flex gap-4 items-start">
                            <AlertTriangle className="text-amber-500 shrink-0" size={24} />
                            <div>
                                <p className="font-bold text-amber-800 text-sm">SMTP Configuration</p>
                                <p className="text-xs text-amber-600/80 mt-1">
                                    Email delivery relies on the Firebase Extension "Trigger Email". 
                                    Configure SMTP directly in the Firebase Console.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

        </div>

        <div className="pt-8 border-t border-stone-100 flex justify-end">
            <button 
                onClick={handleSave} 
                disabled={loading}
                className="bg-stone-900 text-white px-8 py-4 rounded-2xl font-bold flex items-center gap-3 shadow-xl hover:scale-105 transition-all disabled:opacity-50"
            >
                {loading ? <Loader2 className="animate-spin" /> : <Save size={20} />} Save Configuration
            </button>
        </div>
    </div>
  );
};

export default AdminSettings;
