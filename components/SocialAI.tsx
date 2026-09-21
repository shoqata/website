
import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Sparkles, 
  Send, 
  RefreshCw, 
  Wand2, 
  Image as ImageIcon, 
  Facebook, 
  Instagram, 
  Upload, 
  Trash2, 
  CheckCircle2,
  Calendar,
  Clock,
  History,
  Mail,
  Settings,
  Layout,
  Lock,
  Globe,
  Link2,
  Unlink,
  AlertTriangle
} from 'lucide-react';
import { generateSocialMediaContent, analyzeImageAndSuggestPost } from '../services/geminiService';
import { db } from '../services/firebase';
import { collection, addDoc, onSnapshot, query, orderBy, serverTimestamp, supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';
import { useTranslation } from '../context/LanguageContext';

import { onImageError } from '../lib/imageFallback';
interface SocialAIProps {
    viewMode?: 'LIST' | 'GRID' | 'KANBAN';
}

const SocialAI: React.FC<SocialAIProps> = ({ viewMode = 'LIST' }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [activeSubTab, setActiveSubTab] = useState<'STUDIO' | 'CONFIG'>('STUDIO');
  
  // Generation State
  const [topic, setTopic] = useState('');
  const [tone, setTone] = useState('inspiring');
  const [lang, setLang] = useState('sq');
  const [content, setContent] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [platforms, setPlatforms] = useState<string[]>(['FACEBOOK', 'INSTAGRAM']);
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [scheduledPosts, setScheduledPosts] = useState<any[]>([]);
  const [scheduledTime, setScheduledTime] = useState<string>('');
  

  // Welche Kanaele verbunden sind. Der Zugriffstoken kommt hier nie an --
  // social_verbindungen() gibt ihn nicht heraus, und die Tabelle selbst ist
  // fuer angemeldete Clients gesperrt.
  const [verbindungen, setVerbindungen] = useState<any[]>([]);
  const [verbindeGerade, setVerbindeGerade] = useState(false);

  const fbVerbindung = verbindungen.find(v => v.plattform === 'FACEBOOK');
  const igVerbindung = verbindungen.find(v => v.plattform === 'INSTAGRAM');
  const kannSenden = verbindungen.some(v => v.zustand === 'AKTIV');
  const zurWahl = fbVerbindung?.zustand === 'WAEHLEN' ? (fbVerbindung.kandidaten || []) : [];

  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const q = query(collection(db, 'socialmediaposts'), orderBy('timestamp', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setScheduledPosts(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    ladeVerbindungen();

    // Meta schickt den Browser mit ?social=... zurueck. Der Hinweis wird
    // einmal gezeigt und danach aus der Adresse entfernt, damit er beim
    // Neuladen nicht wieder auftaucht.
    const roh = window.location.hash.split('?')[1] || '';
    const zurueck = new URLSearchParams(roh).get('social');
    if (zurueck) {
      const grund = new URLSearchParams(roh).get('grund') || '';
      showAlert({
        type: zurueck === 'verbunden' || zurueck === 'nur_facebook' ? 'success' : 'warning',
        message: t('social.rueck.' + zurueck, { grund }) || grund,
      });
      window.location.hash = window.location.hash.split('?')[0];
    }

    return () => unsub();
  }, []);

  const ladeVerbindungen = async () => {
    const { data, error } = await supabase.rpc('social_verbindungen');
    if (!error) setVerbindungen(data || []);
  };

  const verbindenStarten = async () => {
    setVerbindeGerade(true);
    try {
      const { data, error } = await supabase.rpc('social_verbinden_starten', {
        p_zurueck: window.location.origin + window.location.pathname + '#/admin',
      });
      if (error) throw error;
      window.location.href = data as string;
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || t('common.error') });
      setVerbindeGerade(false);
    }
  };

  const seiteWaehlen = async (kontoId: string) => {
    const { error } = await supabase.rpc('social_seite_waehlen', { p_konto_id: kontoId });
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    await ladeVerbindungen();
    showAlert({ type: 'success', message: t('social.rueck.verbunden') });
  };

  const trennen = async () => {
    const ja = await showConfirm({
      title: t('social.trennen'), message: t('social.trennen_frage'),
      confirmText: t('social.trennen'), type: 'danger',
    });
    if (!ja) return;
    const { error } = await supabase.rpc('social_trennen', { p_plattform: null });
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    await ladeVerbindungen();
  };

  const handleGenerate = async () => {
    if (!topic && !previewImage) return;
    setIsLoading(true);
    try {
      if (previewImage) {
        const analysis = await analyzeImageAndSuggestPost(previewImage);
        setContent(analysis || '');
      } else {
        const generatedContent = await generateSocialMediaContent(topic, tone, lang);
        setContent(generatedContent || '');
      }
    } catch (error) {
      console.error(error);
      showAlert({ type: 'error', message: t('common.error') });
    } finally {
      setIsLoading(false);
    }
  };

  // Hier wurde bis zum 21.09.2026 ein Erfolg vorgetaeuscht: der Beitrag ging
  // als PUBLISHED in die Datenbank, danach wartete die Funktion 1500 ms
  // ("Mock API Call") und meldete "veroeffentlicht". Gesendet wurde nie
  // etwas. Solange die Anbindung an Meta fehlt, entstehen hier Entwuerfe und
  // Vormerkungen -- und die Meldung sagt genau das.
  //
  // Ausserdem wurden die Felder autoPosted und scheduledFor geschrieben, die
  // es in socialmediaposts nicht gibt; die Spalte heisst scheduledTime. Der
  // einzige gespeicherte Beitrag stand deshalb auf SCHEDULED ohne Termin.
  const handlePublish = async (isScheduling: boolean = false) => {
    if (!content) return;

    if (isScheduling && !scheduledTime) {
        showAlert({ type: 'warning', message: t('ai.pick_datetime') });
        return;
    }

    // Gesendet wird nur, wenn wirklich ein Kanal verbunden ist. Ohne
    // Verbindung entsteht ein Entwurf -- und die Meldung sagt das auch.
    // Bis zum 21.09.2026 stand hier ein "Mock API Call": der Beitrag ging
    // als PUBLISHED in die Datenbank, die Funktion wartete 1500 ms und
    // meldete Erfolg, ohne je etwas gesendet zu haben.
    const sendenJetzt = !isScheduling && kannSenden;

    if (sendenJetzt) {
        const ja = await showConfirm({
            title: t('social.publish'),
            message: t('social.senden_frage', {
                kanaele: platforms.map(x => x === 'FACEBOOK' ? 'Facebook' : 'Instagram').join(' + '),
            }),
            confirmText: t('social.publish'),
            type: 'primary',
        });
        if (!ja) return;
    }

    setIsLoading(true);
    try {
      const { id } = await addDoc(collection(db, 'socialmediaposts'), {
        content,
        platforms,
        status: isScheduling ? 'SCHEDULED' : (sendenJetzt ? 'QUEUED' : 'DRAFT'),
        timestamp: serverTimestamp(),
        image: previewImage || null,
        scheduledTime: isScheduling ? scheduledTime : null,
      });

      if (sendenJetzt) {
        const { error } = await supabase.rpc('social_jetzt_senden', { p_beitrag: id });
        if (error) throw error;
      }

      showAlert({
          type: 'success',
          message: isScheduling ? t('social.vorgemerkt')
                 : sendenJetzt ? t('social.unterwegs')
                 : t('social.gesichert')
      });

      setContent('');
      setTopic('');
      setPreviewImage(null);
      setScheduledTime('');
    } catch (error: any) {
      console.error(error);
      showAlert({ type: 'error', message: error?.message || t('common.error') });
    } finally {
      setIsLoading(false);
    }
  };

  const togglePlatform = (p: string) => {
    setPlatforms(prev => prev.includes(p) ? prev.filter(x => x !== p) : [...prev, p]);
  };

  return (
    <div className="space-y-8 h-full flex flex-col">
      {/* Internal Tabs */}
      <div className="flex bg-stone-100 p-1 rounded-2xl w-fit shrink-0">
          <button 
            onClick={() => setActiveSubTab('STUDIO')}
            className={`px-8 py-2.5 rounded-xl text-sm font-bold transition-all flex items-center gap-2 ${activeSubTab === 'STUDIO' ? 'bg-white text-primary shadow-sm' : 'text-stone-500 hover:text-stone-900'}`}
          >
              <Layout size={16}/> {t('social.studio')}
          </button>
          <button 
            onClick={() => setActiveSubTab('CONFIG')}
            className={`px-8 py-2.5 rounded-xl text-sm font-bold transition-all flex items-center gap-2 ${activeSubTab === 'CONFIG' ? 'bg-white text-primary shadow-sm' : 'text-stone-500 hover:text-stone-900'}`}
          >
              <Settings size={16}/> {t('social.config')}
          </button>
      </div>

      <AnimatePresence mode="wait">
        {activeSubTab === 'STUDIO' ? (
          <motion.div 
            key="studio"
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 10 }}
            className="grid grid-cols-1 lg:grid-cols-12 gap-8 flex-1 overflow-hidden"
          >
            {/* Left side generation */}
            <div className="lg:col-span-7 space-y-6 overflow-y-auto custom-scrollbar pb-10">
                <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                    <div className="flex items-center gap-3 mb-8">
                        <div className="bg-rose-50 text-primary p-3 rounded-2xl"><Sparkles size={24} /></div>
                        <div>
                            <h3 className="text-2xl font-display font-bold italic">{t('ai.title')}</h3>
                            <p className="text-xs text-stone-400">{t('ai.subtitle')}</p>
                        </div>
                    </div>

                    <div className="space-y-6">
                        <div 
                        onClick={() => fileInputRef.current?.click()}
                        className={`p-10 border-2 border-dashed rounded-[2.5rem] flex flex-col items-center gap-4 cursor-pointer transition-all ${previewImage ? 'border-primary bg-rose-50/20' : 'border-stone-100 hover:border-primary/30'}`}
                        >
                            {previewImage ? (
                            <div className="relative group">
                                <img src={previewImage} className="max-h-64 rounded-3xl shadow-2xl"  onError={onImageError}/>
                                <button onClick={(e) => { e.stopPropagation(); setPreviewImage(null); }} className="absolute -top-3 -right-3 p-3 bg-white text-red-500 rounded-full shadow-xl border border-stone-100"><Trash2 size={20} /></button>
                            </div>
                            ) : (
                            <>
                                <div className="w-20 h-20 bg-stone-50 rounded-[2rem] flex items-center justify-center text-stone-300"><Upload size={40} /></div>
                                <div className="text-center">
                                    <p className="font-bold text-stone-600">{t('ai.upload_photo')}</p>
                                    <p className="text-xs text-stone-400 mt-1">{t('ai.upload_hint')}</p>
                                </div>
                            </>
                            )}
                            <input type="file" ref={fileInputRef} hidden accept="image/*" onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (file) {
                                const reader = new FileReader();
                                reader.onload = (re) => setPreviewImage(re.target?.result as string);
                                reader.readAsDataURL(file);
                            }
                            }} />
                        </div>

                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.topic.label')}</label>
                            <textarea 
                            value={topic}
                            onChange={(e) => setTopic(e.target.value)}
                            placeholder={t('social.topic.placeholder')}
                            className="w-full p-5 bg-stone-50 border border-stone-100 rounded-[1.5rem] outline-none focus:border-primary/30 h-32 transition-all font-medium text-stone-700 leading-relaxed"
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.tone.label')}</label>
                                <select value={tone} onChange={(e) => setTone(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-100 rounded-xl text-sm font-bold outline-none cursor-pointer">
                                    <option value="inspiring">{t('ai.tone_inspiring')}</option>
                                    <option value="professional">{t('ai.tone_professional')}</option>
                                    <option value="emotional">{t('ai.tone_emotional')}</option>
                                    <option value="urgent">{t('ai.tone_urgent')}</option>
                                </select>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.lang.label')}</label>
                                <select value={lang} onChange={(e) => setLang(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-100 rounded-xl text-sm font-bold outline-none cursor-pointer">
                                    <option value="sq">Shqip</option>
                                    <option value="de">Deutsch</option>
                                    <option value="en">English</option>
                                    <option value="mixed">{t('ai.lang_mixed')}</option>
                                </select>
                            </div>
                        </div>

                        <button 
                            onClick={handleGenerate}
                            disabled={isLoading || (!topic && !previewImage)}
                            className="w-full py-5 bg-stone-900 text-white rounded-[1.5rem] font-bold flex items-center justify-center gap-3 shadow-xl hover:bg-black transition-all disabled:opacity-50 group"
                        >
                            {isLoading ? <RefreshCw className="animate-spin" /> : <Wand2 size={20} className="group-hover:rotate-12 transition-transform" />} 
                            {previewImage ? t('social.analyze') : t('social.generate')}
                        </button>
                    </div>
                </div>

                <AnimatePresence>
                    {content && (
                        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-stone-900 text-white p-8 rounded-[2.5rem] border border-stone-800 shadow-2xl relative overflow-hidden group">
                            <div className="absolute top-0 right-0 w-64 h-64 bg-primary/10 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/2" />
                            <div className="relative z-10">
                                <div className="flex justify-between items-center mb-6">
                                    <div className="flex gap-2">
                                        <button onClick={() => togglePlatform('FACEBOOK')} className={`p-2.5 rounded-xl transition-all ${platforms.includes('FACEBOOK') ? 'bg-blue-600 text-white' : 'bg-stone-800 text-stone-500'}`}><Facebook size={18} /></button>
                                        <button onClick={() => togglePlatform('INSTAGRAM')} className={`p-2.5 rounded-xl transition-all ${platforms.includes('INSTAGRAM') ? 'bg-gradient-to-tr from-yellow-500 via-rose-500 to-purple-600 text-white' : 'bg-stone-800 text-stone-500'}`}><Instagram size={18} /></button>
                                    </div>
                                    <span className={`text-[9px] font-bold px-2.5 py-1 rounded-full uppercase tracking-widest ${kannSenden ? 'text-emerald-400 bg-emerald-500/10' : 'text-stone-500 bg-white/5'}`}>
                                        {kannSenden ? t('social.verbunden_kurz') : t('social.nur_vorbereiten')}
                                    </span>
                                </div>
                                <div className="min-h-[150px] bg-white/5 p-6 rounded-2xl border border-white/5 text-stone-300 text-sm leading-relaxed mb-8 whitespace-pre-wrap italic">
                                    {content}
                                </div>
                                
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-500 uppercase tracking-widest block mb-2">{t('social.schedule')}</label>
                                        <div className="relative">
                                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-500" size={14}/>
                                            <input 
                                                type="datetime-local" 
                                                value={scheduledTime}
                                                onChange={e => setScheduledTime(e.target.value)}
                                                className="w-full pl-10 pr-3 py-2 bg-white/5 border border-white/10 rounded-xl text-xs outline-none focus:border-primary/50 text-white"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="flex justify-between items-center border-t border-white/5 pt-6 gap-4">
                                    <button 
                                        onClick={() => handlePublish(false)}
                                        className="flex-1 py-3.5 bg-stone-800 text-stone-300 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-stone-700 transition-all"
                                    >
                                        <Mail size={18}/> {t('social.save_draft')}
                                    </button>
                                    {scheduledTime ? (
                                        <button onClick={() => handlePublish(true)} className="flex-[2] bg-emerald-600 text-white py-3.5 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-emerald-700 transition-all shadow-lg shadow-emerald-900/20">
                                            <Clock size={18} /> {t('social.schedule')}
                                        </button>
                                    ) : (
                                        <button onClick={() => handlePublish(false)} className="flex-[2] bg-primary text-white py-3.5 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-rose-600 transition-all shadow-lg shadow-rose-900/20">
                                            <Send size={18} /> {kannSenden ? t('social.publish') : t('social.sichern')}
                                        </button>
                                    )}
                                </div>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>

            {/* Right side history */}
            <div className="lg:col-span-5 space-y-6 overflow-y-auto custom-scrollbar pb-10 px-1">
                <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm h-full">
                    <div className="flex justify-between items-center mb-8">
                        <h4 className="font-bold text-lg text-stone-900 flex items-center gap-2"><History size={20} className="text-stone-400" /> {t('social.history')}</h4>
                    </div>
                    
                    <div className="space-y-4">
                        {scheduledPosts.map(p => (
                            <div key={p.id} className="p-4 bg-stone-50 rounded-2xl border border-stone-100 flex gap-4 items-start group hover:bg-white hover:shadow-md transition-all cursor-pointer">
                                <div className="w-16 h-16 bg-white rounded-xl flex items-center justify-center shrink-0 border border-stone-200 overflow-hidden shadow-inner">
                                    {p.image ? <img src={p.image} className="w-full h-full object-cover"  onError={onImageError}/> : <ImageIcon className="text-stone-200" size={24} />}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <div className="flex justify-between items-center mb-1">
                                        <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{p.timestamp?.toDate().toLocaleDateString()}</p>
                                        <div className="flex gap-1">
                                            {p.platforms?.map((plat: string) => (
                                                <div key={plat} className="text-stone-300">
                                                    {plat === 'FACEBOOK' ? <Facebook size={10}/> : <Instagram size={10}/>}
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                    <p className="text-xs font-medium text-stone-800 line-clamp-2 italic leading-relaxed">"{p.content}"</p>
                                    <div className="flex gap-2 items-center mt-2">
                                        {p.status === 'SCHEDULED' && p.scheduledTime && <span className="text-[8px] font-bold text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded uppercase flex items-center gap-1"><Clock size={8}/> {new Date(p.scheduledTime).toLocaleString()}</span>}
                                        {p.status === 'DRAFT' && <span className="text-[8px] font-bold text-stone-500 bg-stone-100 px-1.5 py-0.5 rounded inline-block uppercase">{t('social.entwurf')}</span>}
                                        {(p.status === 'QUEUED' || p.status === 'PUBLISHING') && <span className="text-[8px] font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded uppercase flex items-center gap-1"><RefreshCw size={8} className="animate-spin"/> {t('social.unterwegs_kurz')}</span>}
                                        {p.status === 'PUBLISHED' && <span className="text-[8px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded inline-block uppercase">{t('ai.autoposted')}</span>}
                                        {p.status === 'FAILED' && <span title={p.lastError || ''} className="text-[8px] font-bold text-rose-600 bg-rose-50 px-1.5 py-0.5 rounded uppercase flex items-center gap-1"><AlertTriangle size={8}/> {t('social.gescheitert')}</span>}
                                    </div>
                                </div>
                            </div>
                        ))}
                        {scheduledPosts.length === 0 && (
                            <div className="text-center py-20 bg-stone-50/50 rounded-3xl border border-dashed border-stone-200">
                                <History size={40} className="mx-auto text-stone-200 mb-4" />
                                <p className="text-stone-400 text-sm">{t('ai.no_history')}</p>
                            </div>
                        )}
                    </div>
                </div>
            </div>
          </motion.div>
        ) : (
          <motion.div 
            key="config"
            initial={{ opacity: 0, x: 10 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -10 }}
            className="max-w-4xl space-y-8 flex-1 pb-20"
          >
              {/* Es gibt hier bewusst kein Feld fuer ein Zugriffstoken mehr.
                  Ein Token, das ein Mensch in ein Formular tippt, landet im
                  Browser, im Netzwerkprotokoll und frueher oder spaeter in
                  einer Sicht, die jemand oeffentlich lesen kann -- genau das
                  ist im September passiert. Verbunden wird ueber die
                  Anmeldung bei Facebook; der Token entsteht dabei auf dem
                  Server und bleibt dort. */}

              {zurWahl.length > 0 ? (
                <div className="bg-white p-10 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-6">
                    <div className="flex items-start gap-5">
                        <div className="p-3 bg-blue-50 text-blue-600 rounded-2xl shrink-0"><Facebook size={24}/></div>
                        <div className="space-y-2">
                            <h4 className="font-bold text-xl text-stone-900">{t('social.seite_waehlen')}</h4>
                            <p className="text-sm text-stone-500 leading-relaxed max-w-2xl">{t('social.seite_waehlen_text')}</p>
                        </div>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        {zurWahl.map((k: any) => (
                            <button key={k.id} onClick={() => seiteWaehlen(k.id)}
                                className="text-left p-5 rounded-2xl border border-stone-200 hover:border-primary/40 hover:bg-stone-50 transition-all">
                                <p className="font-bold text-stone-900 text-sm">{k.name}</p>
                                <p className="text-[10px] text-stone-400 font-mono mt-1">{k.id}</p>
                            </button>
                        ))}
                    </div>
                </div>
              ) : kannSenden ? (
                <div className="bg-white p-10 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-8">
                    <div className="flex items-start justify-between gap-6 flex-wrap">
                        <div className="flex items-start gap-5">
                            <div className="p-3 bg-emerald-50 text-emerald-600 rounded-2xl shrink-0"><Link2 size={24}/></div>
                            <div className="space-y-2">
                                <h4 className="font-bold text-xl text-stone-900">{t('social.verbunden')}</h4>
                                <p className="text-sm text-stone-500 leading-relaxed max-w-xl">{t('social.verbunden_text')}</p>
                            </div>
                        </div>
                        <button onClick={trennen}
                            className="px-5 py-2.5 rounded-xl text-xs font-bold text-stone-500 border border-stone-200 hover:border-rose-200 hover:text-rose-600 transition-colors flex items-center gap-2">
                            <Unlink size={14}/> {t('social.trennen')}
                        </button>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {[fbVerbindung, igVerbindung].filter(Boolean).map((v: any) => (
                            <div key={v.plattform} className="p-5 rounded-2xl bg-stone-50 border border-stone-100 flex items-center gap-4">
                                <div className={`p-2.5 rounded-xl ${v.plattform === 'FACEBOOK' ? 'bg-blue-50 text-blue-600' : 'bg-rose-50 text-rose-600'}`}>
                                    {v.plattform === 'FACEBOOK' ? <Facebook size={18}/> : <Instagram size={18}/>}
                                </div>
                                <div className="min-w-0">
                                    <p className="font-bold text-stone-900 text-sm truncate">{v.konto_name || '—'}</p>
                                    <p className={`text-[10px] font-bold uppercase tracking-widest ${v.zustand === 'AKTIV' ? 'text-emerald-600' : 'text-amber-600'}`}>
                                        {v.zustand === 'AKTIV' ? t('social.aktiv') : t('social.abgelaufen')}
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>

                    {verbindungen.some(v => v.letzter_fehler) && (
                        <div className="flex gap-3 p-5 rounded-2xl bg-amber-50 border border-amber-100">
                            <AlertTriangle size={18} className="text-amber-500 shrink-0 mt-0.5"/>
                            <p className="text-xs text-amber-800 leading-relaxed">
                                {verbindungen.find(v => v.letzter_fehler)?.letzter_fehler}
                            </p>
                        </div>
                    )}
                </div>
              ) : (
                <div className="bg-white p-10 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-8">
                    <div className="flex items-start gap-5">
                        <div className="p-3 bg-stone-100 text-stone-500 rounded-2xl shrink-0"><Lock size={24}/></div>
                        <div className="space-y-3">
                            <h4 className="font-bold text-xl text-stone-900">{t('social.nicht_verbunden')}</h4>
                            <p className="text-sm text-stone-500 leading-relaxed max-w-2xl">{t('social.nicht_verbunden_text')}</p>
                        </div>
                    </div>
                    <button onClick={verbindenStarten} disabled={verbindeGerade}
                        className="bg-[#1877F2] text-white px-8 py-4 rounded-2xl font-bold flex items-center gap-3 hover:bg-[#0f5fce] transition-colors disabled:opacity-50">
                        {verbindeGerade ? <RefreshCw size={18} className="animate-spin"/> : <Facebook size={18}/>}
                        {t('social.verbinden')}
                    </button>
                </div>
              )}

              <div className="bg-white p-10 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-6">
                  <h4 className="font-bold text-stone-900 flex items-center gap-2">
                      <CheckCircle2 size={18} className="text-stone-300" /> {t('social.voraussetzung')}
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div className="flex gap-3">
                          <div className="bg-blue-50 text-blue-600 p-2.5 rounded-xl h-fit"><Facebook size={18}/></div>
                          <p className="text-xs text-stone-500 leading-relaxed">{t('social.v1')}</p>
                      </div>
                      <div className="flex gap-3">
                          <div className="bg-rose-50 text-rose-600 p-2.5 rounded-xl h-fit"><Instagram size={18}/></div>
                          <p className="text-xs text-stone-500 leading-relaxed">{t('social.v2')}</p>
                      </div>
                      <div className="flex gap-3">
                          <div className="bg-stone-100 text-stone-500 p-2.5 rounded-xl h-fit"><Globe size={18}/></div>
                          <p className="text-xs text-stone-500 leading-relaxed">{t('social.v3')}</p>
                      </div>
                  </div>
              </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default SocialAI;
