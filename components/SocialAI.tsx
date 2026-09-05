
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
  Camera, 
  Upload, 
  Trash2, 
  CheckCircle2,
  Calendar,
  Clock,
  History,
  MoreHorizontal,
  Plus,
  Mail,
  Settings,
  Layout,
  Lock,
  Eye,
  EyeOff,
  Zap,
  Globe,
  Languages
} from 'lucide-react';
import { generateSocialMediaContent, analyzeImageAndSuggestPost } from '../services/geminiService';
import { db } from '../services/firebase';
import { collection, addDoc, onSnapshot, query, orderBy, serverTimestamp, doc, getDoc, setDoc } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';
import { useTranslation } from '../context/LanguageContext';

interface SocialAIProps {
    viewMode?: 'LIST' | 'GRID' | 'KANBAN';
}

interface SocialConfig {
    fbPageId: string;
    fbAccessToken: string;
    igUserId: string;
    igAccessToken: string;
    autoPostingEnabled: boolean;
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
  
  // Config State
  const [socialConfig, setSocialConfig] = useState<SocialConfig>({
      fbPageId: '',
      fbAccessToken: '',
      igUserId: '',
      igAccessToken: '',
      autoPostingEnabled: false
  });
  const [showTokens, setShowTokens] = useState(false);
  const [isSavingConfig, setIsSavingConfig] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const q = query(collection(db, 'socialMediaPosts'), orderBy('timestamp', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setScheduledPosts(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    // Load Config
    const loadConfig = async () => {
        const snap = await getDoc(doc(db, 'settings', 'social'));
        if (snap.exists()) setSocialConfig(snap.data() as SocialConfig);
    };
    loadConfig();

    return () => unsub();
  }, []);

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

  const handleSaveConfig = async () => {
      setIsSavingConfig(true);
      try {
          await setDoc(doc(db, 'settings', 'social'), socialConfig);
          showAlert({ type: 'success', message: t('common.success') });
      } catch (e) {
          showAlert({ type: 'error', message: t('common.error') });
      } finally {
          setIsSavingConfig(false);
      }
  };

  const handlePublish = async (isScheduling: boolean = false) => {
    if (!content) return;
    
    if (isScheduling && !scheduledTime) {
        showAlert({ type: 'warning', message: 'Ju lutem zgjidhni datën dhe orën.' });
        return;
    }

    const triggerAutoPost = !isScheduling && socialConfig.autoPostingEnabled && (socialConfig.fbAccessToken || socialConfig.igAccessToken);
    
    if (triggerAutoPost) {
        const confirm = await showConfirm({
            title: t('social.publish'),
            message: "Ky postim do të dërgohet direkt në Facebook/Instagram përmes API. A dëshironi të vazhdoni?",
            confirmText: t('social.publish'),
            type: 'primary'
        });
        if (!confirm) return;
    }

    setIsLoading(true);
    try {
      // 1. Store in Firebase History
      await addDoc(collection(db, 'socialMediaPosts'), {
        content,
        platforms,
        status: isScheduling ? 'SCHEDULED' : (triggerAutoPost ? 'PUBLISHED' : 'DRAFT'),
        timestamp: serverTimestamp(),
        image: previewImage || null,
        autoPosted: triggerAutoPost,
        scheduledFor: isScheduling ? scheduledTime : null
      });

      // 2. Mock API Call for Automated Posting
      if (triggerAutoPost) {
          // Meta Graph API Integration would go here
          await new Promise(r => setTimeout(r, 1500));
      }

      showAlert({ 
          type: 'success', 
          message: isScheduling 
            ? t('social.schedule') 
            : (triggerAutoPost ? t('social.publish') : t('social.save_draft')) 
      });
      
      // Reset
      setContent('');
      setTopic('');
      setPreviewImage(null);
      setScheduledTime('');
    } catch (error) {
      console.error(error);
      showAlert({ type: 'error', message: t('common.error') });
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
                            <h3 className="text-2xl font-display font-bold italic">AI Content Studio</h3>
                            <p className="text-xs text-stone-400">Gemini Pro content engine.</p>
                        </div>
                    </div>

                    <div className="space-y-6">
                        <div 
                        onClick={() => fileInputRef.current?.click()}
                        className={`p-10 border-2 border-dashed rounded-[2.5rem] flex flex-col items-center gap-4 cursor-pointer transition-all ${previewImage ? 'border-primary bg-rose-50/20' : 'border-stone-100 hover:border-primary/30'}`}
                        >
                            {previewImage ? (
                            <div className="relative group">
                                <img src={previewImage} className="max-h-64 rounded-3xl shadow-2xl" />
                                <button onClick={(e) => { e.stopPropagation(); setPreviewImage(null); }} className="absolute -top-3 -right-3 p-3 bg-white text-red-500 rounded-full shadow-xl border border-stone-100"><Trash2 size={20} /></button>
                            </div>
                            ) : (
                            <>
                                <div className="w-20 h-20 bg-stone-50 rounded-[2rem] flex items-center justify-center text-stone-300"><Upload size={40} /></div>
                                <div className="text-center">
                                    <p className="font-bold text-stone-600">Ngarkoni foto për analizë</p>
                                    <p className="text-xs text-stone-400 mt-1">AI do të shkruajë një përshkrim bazuar në pamje.</p>
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
                                    <option value="inspiring">Frymëzues / Inspiring</option>
                                    <option value="professional">Profesional</option>
                                    <option value="emotional">Emocional</option>
                                    <option value="urgent">Urgjent / Aksion</option>
                                </select>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.lang.label')}</label>
                                <select value={lang} onChange={(e) => setLang(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-100 rounded-xl text-sm font-bold outline-none cursor-pointer">
                                    <option value="sq">Shqip</option>
                                    <option value="de">Deutsch</option>
                                    <option value="en">English</option>
                                    <option value="mixed">Mixed (Diaspora Context)</option>
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
                                    <div className="flex items-center gap-2">
                                        {socialConfig.autoPostingEnabled && <span className="flex items-center gap-1 text-[9px] font-bold text-emerald-400 bg-emerald-500/10 px-2 py-1 rounded-full uppercase tracking-widest"><Zap size={10}/> Auto-Post On</span>}
                                    </div>
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
                                            <Send size={18} /> {socialConfig.autoPostingEnabled ? t('social.publish') : t('social.publish')}
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
                                    {p.image ? <img src={p.image} className="w-full h-full object-cover" /> : <ImageIcon className="text-stone-200" size={24} />}
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
                                        {p.status === 'SCHEDULED' && <span className="text-[8px] font-bold text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded uppercase flex items-center gap-1"><Clock size={8}/> {new Date(p.scheduledFor).toLocaleString()}</span>}
                                        {p.autoPosted && <span className="text-[8px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded inline-block uppercase">Auto-Posted</span>}
                                    </div>
                                </div>
                            </div>
                        ))}
                        {scheduledPosts.length === 0 && (
                            <div className="text-center py-20 bg-stone-50/50 rounded-3xl border border-dashed border-stone-200">
                                <History size={40} className="mx-auto text-stone-200 mb-4" />
                                <p className="text-stone-400 text-sm">No post history yet.</p>
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
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  {/* FACEBOOK CONFIG */}
                  <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-6">
                      <div className="flex items-center gap-3 mb-4">
                          <div className="bg-blue-50 text-blue-600 p-3 rounded-2xl"><Facebook size={24}/></div>
                          <div>
                              <h4 className="font-bold text-stone-900">{t('social.api.fb.title')}</h4>
                              <p className="text-xs text-stone-400">Meta Graph API Settings</p>
                          </div>
                      </div>

                      <div className="space-y-4">
                          <div>
                              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.api.id.label')} (Page ID)</label>
                              <input 
                                value={socialConfig.fbPageId}
                                onChange={e => setSocialConfig({...socialConfig, fbPageId: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl text-sm font-mono outline-none" 
                                placeholder="123456789..."
                              />
                          </div>
                          <div>
                              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1 flex justify-between items-center">
                                  {t('social.api.token.label')}
                                  <button onClick={() => setShowTokens(!showTokens)} className="text-primary hover:underline">{showTokens ? <EyeOff size={12}/> : <Eye size={12}/>}</button>
                              </label>
                              <input 
                                type={showTokens ? "text" : "password"}
                                value={socialConfig.fbAccessToken}
                                onChange={e => setSocialConfig({...socialConfig, fbAccessToken: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl text-sm font-mono outline-none" 
                                placeholder="EAAB..."
                              />
                          </div>
                      </div>
                  </div>

                  {/* INSTAGRAM CONFIG */}
                  <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm space-y-6">
                      <div className="flex items-center gap-3 mb-4">
                          <div className="bg-rose-50 text-rose-600 p-3 rounded-2xl"><Instagram size={24}/></div>
                          <div>
                              <h4 className="font-bold text-stone-900">{t('social.api.ig.title')}</h4>
                              <p className="text-xs text-stone-400">Business Login Required</p>
                          </div>
                      </div>

                      <div className="space-y-4">
                          <div>
                              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.api.id.label')} (IG Business ID)</label>
                              <input 
                                value={socialConfig.igUserId}
                                onChange={e => setSocialConfig({...socialConfig, igUserId: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl text-sm font-mono outline-none" 
                                placeholder="178414..."
                              />
                          </div>
                          <div>
                              <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2 px-1">{t('social.api.token.label')}</label>
                              <input 
                                type={showTokens ? "text" : "password"}
                                value={socialConfig.igAccessToken}
                                onChange={e => setSocialConfig({...socialConfig, igAccessToken: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl text-sm font-mono outline-none" 
                                placeholder="EAAB..."
                              />
                          </div>
                      </div>
                  </div>
              </div>

              {/* GLOBAL AUTOMATION TOGGLE */}
              <div className="bg-stone-900 text-white p-10 rounded-[3rem] border border-stone-800 shadow-2xl relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-primary/10 to-transparent pointer-events-none" />
                  
                  <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-8">
                      <div className="space-y-2 text-center md:text-left">
                          <h3 className="text-2xl font-display font-bold italic flex items-center justify-center md:justify-start gap-3">
                              <Zap className="text-emerald-400" /> {t('social.autopost.label')}
                          </h3>
                          <p className="text-stone-400 text-sm max-w-lg leading-relaxed">
                              {t('social.autopost.desc')}
                          </p>
                      </div>

                      <div className="flex items-center gap-4 bg-white/5 p-4 rounded-2xl border border-white/10">
                          <div 
                              onClick={() => setSocialConfig({...socialConfig, autoPostingEnabled: !socialConfig.autoPostingEnabled})}
                              className={`w-16 h-8 rounded-full relative cursor-pointer transition-colors ${socialConfig.autoPostingEnabled ? 'bg-emerald-500' : 'bg-stone-700'}`}
                          >
                              <motion.div 
                                  animate={{ x: socialConfig.autoPostingEnabled ? 32 : 4 }}
                                  className="absolute top-1 w-6 h-6 bg-white rounded-full shadow-lg"
                              />
                          </div>
                          <span className={`text-xs font-bold uppercase tracking-widest ${socialConfig.autoPostingEnabled ? 'text-emerald-400' : 'text-stone-400'}`}>
                              {socialConfig.autoPostingEnabled ? 'AKTIV / ACTIVE' : 'JO AKTIV / INACTIVE'}
                          </span>
                      </div>
                  </div>
              </div>

              <div className="flex justify-end pt-4">
                  <button 
                    onClick={handleSaveConfig}
                    disabled={isSavingConfig}
                    className="bg-stone-900 text-white px-10 py-4 rounded-2xl font-bold flex items-center gap-2 hover:bg-black transition-all shadow-xl disabled:opacity-50"
                  >
                      {isSavingConfig ? <RefreshCw size={18} className="animate-spin" /> : <Lock size={18} />} 
                      {t('common.save_changes')}
                  </button>
              </div>

              {/* Info Area */}
              <div className="bg-blue-50 border border-blue-100 p-8 rounded-3xl flex gap-6 items-start">
                  <div className="p-3 bg-blue-100 text-blue-600 rounded-2xl"><Globe size={24}/></div>
                  <div className="space-y-4">
                      <h5 className="font-bold text-blue-900">Udhëzime / Instructions / Anleitung</h5>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div className="space-y-2">
                            <p className="text-[10px] font-bold text-blue-400 uppercase tracking-widest">Deutsch</p>
                            <p className="text-xs text-blue-700 leading-relaxed">
                                Um automatisches Posten zu aktivieren, erstelle eine App auf <strong>developers.facebook.com</strong>. Füge die "Graph API" hinzu und generiere ein "Long-lived Token" mit Berechtigungen wie <code>pages_manage_posts</code>.
                            </p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-[10px] font-bold text-blue-400 uppercase tracking-widest">English</p>
                            <p className="text-xs text-blue-700 leading-relaxed">
                                To enable auto-posting, create an App at <strong>developers.facebook.com</strong>. Add "Graph API" and "Instagram Graph API". Generate a "Long-lived Page Access Token" with <code>pages_manage_posts</code> permissions.
                            </p>
                        </div>
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
