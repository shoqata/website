
import React, { useState, useEffect } from 'react';
import AdminPostausgang from './AdminPostausgang';
import { useTranslation } from '../context/LanguageContext';
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
  Server,
  Banknote,
  Eye,
  Users
} from 'lucide-react';
import { db } from '../services/firebase';
import { doc, onSnapshot, setDoc, serverTimestamp, supabase } from '@/services/supabase-bridge';
import { SystemSettings, GlobalPaymentSettings } from '../types';
import { useFeedback } from '../context/FeedbackContext';

const AdminSettings: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [loading, setLoading] = useState(false);
  // Was oeffentlich ueber die Beitraege steht. Die Stellung liegt in
  // settings/system; entschieden wird sie aber in der Datenbank, nicht hier
  // -- beitragsstand_oeffentlich() liest sie selbst, sonst koennte jeder die
  // Sicht direkt abfragen und den Schalter umgehen.
  const [vorschau, setVorschau] = useState<any>(null);
  const [widersprueche, setWidersprueche] = useState(0);
  
  // System Settings
  const [settings, setSettings] = useState<SystemSettings>({
    maintenanceMode: false,
    allowRegistration: true,
    modules: {
      villageLive: true,
      events: true,
      news: true
    },
    systemEmail: 'admin@koretini.org',
    beitraegeOeffentlich: 'AUS'
  });

  // Payment Settings (for Fee Structure)
  const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings>({
      iban: '', bankName: '', bic: '', accountHolder: '', street: '', zip: '', city: '', country: '', paypalEmail: '', currency: 'CHF', annualFeeAmount: 100,
      fees: {
          STANDARD: { amount: 120, currency: 'CHF', label: t('admin.members.billing.standard') },
          KOSOVO: { amount: 12, currency: 'EUR', label: t('admin.members.billing.kosovo') },
          REDUCED: { amount: 100, currency: 'EUR', label: t('admin.members.billing.reduced') }
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
                    STANDARD: { amount: 120, currency: 'CHF', label: t('admin.members.billing.standard'), ...data.fees?.STANDARD },
                    KOSOVO: { amount: 12, currency: 'EUR', label: t('admin.members.billing.kosovo'), ...data.fees?.KOSOVO },
                    REDUCED: { amount: 100, currency: 'EUR', label: t('admin.members.billing.reduced'), ...data.fees?.REDUCED },
                }
            }));
        }
    });

    return () => { unsubSystem(); unsubPayment(); };
  }, []);

  useEffect(() => {
    (async () => {
      const [{ data: stand }, { data: wid }] = await Promise.all([
        supabase.rpc('beitragsstand_oeffentlich'),
        supabase.rpc('widersprueche_zaehlen'),
      ]);
      setVorschau(stand);
      setWidersprueche(typeof wid === 'number' ? wid : 0);
    })();
  }, [settings.beitraegeOeffentlich, loading]);

  const handleSave = async () => {
    setLoading(true);
    try {
      await setDoc(doc(db, 'settings', 'system'), {
          ...settings,
          updatedAt: serverTimestamp()
      }, { merge: true });

      await setDoc(doc(db, 'settings', 'payment'), paymentSettings, { merge: true });
      
      showAlert({ type: 'success', message: t('set.saved') });
    } catch (err) {
      console.error(err);
      showAlert({ type: 'error', message: t('set.save_failed') });
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
                <h2 className="text-3xl font-display font-bold italic mb-2">{t('set.title')}</h2>
                <p className="text-stone-500">{t('set.subtitle')}</p>
            </div>
            
            <div className={`px-6 py-3 rounded-2xl border flex items-center gap-3 ${settings.maintenanceMode ? 'bg-amber-50 border-amber-200 text-amber-700' : 'bg-green-50 border-green-200 text-green-700'}`}>
                <Server size={20} />
                <div>
                    <p className="text-xs font-bold uppercase tracking-widest">{t('set.status')}</p>
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
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.access')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <Toggle 
                        label={t('set.maintenance')} 
                        description="Only admins can access the dashboard."
                        checked={settings.maintenanceMode} 
                        onChange={v => setSettings({...settings, maintenanceMode: v})} 
                    />
                    <Toggle 
                        label={t('set.allow_registration')} 
                        description="New users can sign up via the wizard."
                        checked={settings.allowRegistration} 
                        onChange={v => setSettings({...settings, allowRegistration: v})} 
                    />
                </div>
            </section>

            {/* Was die Website ueber die Beitraege sagt.
                Drei Stellungen statt ein/aus, weil zwischen "nichts" und
                "Namensliste" ein Schritt liegt, der oft der richtige ist: die
                blosse Zahl zeigt den Rueckhalt des Vereins, ohne dass
                jemand durch Abwesenheit als saeumig dasteht. */}
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Eye size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('oeff.titel')}</h3>
                </div>

                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
                    <p className="text-xs text-stone-500 leading-relaxed max-w-2xl">{t('oeff.hinweis')}</p>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        {([
                            { wert: 'AUS',   titel: t('oeff.aus'),   text: t('oeff.aus_text') },
                            { wert: 'ZAHL',  titel: t('oeff.zahl'),  text: t('oeff.zahl_text') },
                            { wert: 'NAMEN', titel: t('oeff.namen'), text: t('oeff.namen_text') },
                        ]).map(o => {
                            const aktiv = (settings.beitraegeOeffentlich || 'AUS') === o.wert;
                            return (
                                <button key={o.wert} type="button"
                                    onClick={() => setSettings({ ...settings, beitraegeOeffentlich: o.wert as SystemSettings['beitraegeOeffentlich'] })}
                                    className={`text-left p-5 rounded-2xl border transition-all ${aktiv
                                        ? 'bg-white border-primary shadow-sm'
                                        : 'bg-white/60 border-stone-200 hover:border-stone-300'}`}>
                                    <p className={`font-bold text-sm mb-1 ${aktiv ? 'text-primary' : 'text-stone-900'}`}>{o.titel}</p>
                                    <p className="text-[11px] text-stone-500 leading-relaxed">{o.text}</p>
                                </button>
                            );
                        })}
                    </div>

                    {/* Die Vorschau kommt aus derselben Funktion, die auch die
                        Website aufruft -- was hier steht, steht dort. */}
                    <div className="bg-white rounded-2xl border border-stone-100 p-5">
                        <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-3">{t('oeff.vorschau')}</p>
                        {!vorschau || vorschau.stellung === 'AUS' ? (
                            <p className="text-sm text-stone-400 italic">{t('oeff.vorschau_nichts')}</p>
                        ) : vorschau.stellung === 'ZAHL' ? (
                            <p className="text-sm text-stone-800">
                                <strong>{vorschau.anzahl}</strong> {t('oeff.vorschau_zahl', { jahr: vorschau.jahr, gesamt: vorschau.gesamt })}
                            </p>
                        ) : (
                            <div className="space-y-2">
                                <p className="text-sm text-stone-800">
                                    <strong>{(vorschau.namen || []).length}</strong> {t('oeff.vorschau_namen', { jahr: vorschau.jahr })}
                                </p>
                                <p className="text-xs text-stone-500 leading-relaxed">
                                    {(vorschau.namen || []).slice(0, 12).join(' · ')}
                                    {(vorschau.namen || []).length > 12 ? ' …' : ''}
                                </p>
                            </div>
                        )}
                        {vorschau && vorschau.stellung !== 'AUS' && (
                            <p className="text-[11px] text-stone-400 mt-3 flex items-center gap-1.5 pt-3 border-t border-stone-100">
                                <Users size={12} /> {t('oeff.widersprueche', { anzahl: widersprueche })}
                            </p>
                        )}
                        {(settings.beitraegeOeffentlich || 'AUS') !== (vorschau?.stellung || 'AUS') && (
                            <p className="text-[11px] text-amber-600 mt-3">{t('oeff.erst_speichern')}</p>
                        )}
                    </div>
                </div>
            </section>

            {/* Die frueheren Modulschalter sind entfallen.
                Gemessen: sie wurden gespeichert und an keiner einzigen Stelle
                ausgewertet -- "Events aus" liess die Seite erreichbar und die
                Daten ueber die Schnittstelle abrufbar. Ein Schalter, der nur
                die Oberflaeche verbirgt, ist schlimmer als keiner: er
                behauptet eine Wirkung, die es nicht gibt.
                Ersetzt durch den Marktplatz, dessen Schalter in den
                Zeilenregeln sitzt. */}
            <section className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <LayoutTemplate size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.modules')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100">
                    <p className="text-xs text-stone-500 leading-relaxed">{t('set.modules_verschoben')}</p>
                </div>
            </section>

            {/* FEE STRUCTURE */}
            <section className="space-y-4 md:col-span-2">
                <div className="flex items-center gap-2 mb-2">
                    <Banknote size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.fees')}</h3>
                </div>
                <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm grid grid-cols-1 md:grid-cols-3 gap-6">
                    {/* STANDARD */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-stone-200 text-stone-500 px-2 py-1 rounded">STANDARD</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_standard_desc')}</p>
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
                            <span className="text-[10px] font-bold bg-blue-100 text-blue-600 px-2 py-1 rounded">{t('set.fee_resident')}</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_resident_desc')}</p>
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
                            <span className="text-[10px] font-bold bg-amber-100 text-amber-600 px-2 py-1 rounded">{t('set.fee_reduced')}</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_reduced_desc')}</p>
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
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.communication')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 block">{t('set.reply_to')}</label>
                        <input 
                            type="email" 
                            value={settings.systemEmail} 
                            onChange={e => setSettings({...settings, systemEmail: e.target.value})}
                            className="w-full p-4 bg-white border border-stone-200 rounded-xl font-bold text-stone-700 outline-none focus:border-primary/50"
                        />
                        <p className="text-xs text-stone-400 mt-2">{t('set.reply_to_hint')}</p>
                    </div>
                </div>

                {/* Der Postausgang. Hier stand ein Hinweis aus der
                    Firebase-Zeit -- "Trigger Email", "Firebase Console" --,
                    der seit der Umstellung auf Supabase nicht mehr zutraf und
                    hinter dem sich nichts einstellen liess. */}
                <AdminPostausgang />
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
