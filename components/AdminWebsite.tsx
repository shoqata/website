
import React, { useState, useEffect, useRef } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { 
  Save, 
  RefreshCw, 
  Image as ImageIcon, 
  Check, 
  Palette, 
  Trash2, 
  Mail, 
  MapPin, 
  Heart, 
  Monitor, 
  Smartphone,
  Plus,
  Loader2,
  X,
  Milestone,
  ShieldAlert,
  Home,
  Zap,
  Activity,
  Briefcase,
  Upload,
  Type,
  ChevronDown,
  ChevronUp,
  Globe,
  LayoutTemplate,
  Link as LinkIcon,
  Languages
} from 'lucide-react';
import { db, storage } from '../services/firebase';
import { doc, setDoc, onSnapshot, serverTimestamp, collection, deleteDoc, addDoc } from '@/services/supabase-bridge';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';
import { UserProfile, BoardMember } from '../types';
import HyperTextParagraph from './ui/HyperText'; // Import for Preview
import { useFeedback } from '../context/FeedbackContext';

// --- TYPES ---
// Helper type for localized strings
type LocalizedString = string | { [key: string]: string };

interface RoadmapEntry {
  title: LocalizedString;
  description: LocalizedString;
}

interface MissionEntry {
  title: LocalizedString;
  description: LocalizedString;
  type: 'MISSION' | 'COMMUNITY' | 'TRANSPARENCY';
}

interface LiveSelectorEntry {
  title: LocalizedString;
  description: LocalizedString;
  image: string;
}

interface BrandingSettings {
  primary: string;
  secondary: string;
  logoUrl: string;
  logoHeight?: string; 
  footerText: LocalizedString;
  footerAddress: string;
  footerEmail: string;
  heroTitle: LocalizedString;
  heroSubtitle: LocalizedString;
  heroBadge: LocalizedString;
  heroImages: string[]; 
  roadmap: RoadmapEntry[];
  missions: MissionEntry[];
  liveSelectors: LiveSelectorEntry[];
  gdprText: LocalizedString;
  privacyText: LocalizedString;
  whyJoinText: LocalizedString;
  whyJoinHighlightWords: string[];
}

type Tab = 'GLOBAL' | 'HOME' | 'ABOUT' | 'LIVE' | 'LEGAL';
type LangCode = 'de' | 'en' | 'sq';

const AdminWebsite: React.FC = () => {
  const { showAlert, showPrompt } = useFeedback();
  const [activeTab, setActiveTab] = useState<Tab>('HOME');
  const [editLang, setEditLang] = useState<LangCode>('de'); // Editor Language State
  const [isSaving, setIsSaving] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [showPreview, setShowPreview] = useState(true);
  const [previewMode, setPreviewMode] = useState<'DESKTOP' | 'MOBILE'>('DESKTOP');
  const [expandedSection, setExpandedSection] = useState<string | null>('hero'); 
  
  // Highlight Word Input State
  const [newHighlightWord, setNewHighlightWord] = useState('');

  // Board Member State
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [boardMembers, setBoardMembers] = useState<BoardMember[]>([]);
  const [newBoardMember, setNewBoardMember] = useState<{userId: string, role: string, quote: string, image: string}>({ 
      userId: '', role: '', quote: '', image: '' 
  });
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const heroInputRef = useRef<HTMLInputElement>(null);
  const boardImageInputRef = useRef<HTMLInputElement>(null);

  const [branding, setBranding] = useState<BrandingSettings>({
    primary: '#f43f5e',
    secondary: '#1c1917',
    logoUrl: '',
    logoHeight: '2.5rem',
    footerText: 'Bashkë për vendlindjen tonë.',
    footerAddress: 'Koretin, Kosovë',
    footerEmail: 'info@koretini.org',
    heroTitle: 'Zemra e fshatit tonë.',
    heroSubtitle: 'Lidhja e diasporës me vendlindjen.',
    heroBadge: 'Për Koretinin',
    heroImages: [],
    roadmap: [],
    missions: [],
    liveSelectors: [],
    gdprText: '',
    privacyText: '',
    whyJoinText: '',
    whyJoinHighlightWords: []
  });

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'settings', 'branding'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        setBranding(prev => ({ 
            ...prev, 
            ...data,
            // Ensure arrays exist
            heroImages: data.heroImages || [],
            roadmap: data.roadmap || [],
            missions: data.missions || [],
            liveSelectors: data.liveSelectors || [],
            whyJoinHighlightWords: data.whyJoinHighlightWords || []
        }));
      }
    });
    return () => unsub();
  }, []);

  // Fetch Users and Board Members
  useEffect(() => {
      const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
          setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile)));
      });
      const unsubBoard = onSnapshot(collection(db, 'board_members'), (snap) => {
          setBoardMembers(snap.docs.map(d => ({ id: d.id, ...d.data() } as BoardMember)));
      });
      return () => { unsubUsers(); unsubBoard(); };
  }, []);

  const handleSaveBranding = async () => {
    setIsSaving(true);
    try {
      const dataToSave = { ...branding, updatedAt: serverTimestamp() };
      await setDoc(doc(db, 'settings', 'branding'), dataToSave, { merge: true });
      setIsSaved(true);
      setTimeout(() => setIsSaved(false), 3000);
    } catch (error) {
      console.error(error);
      showAlert({ type: 'error', message: 'Speichern fehlgeschlagen.' });
    } finally {
      setIsSaving(false);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, path: string, callback: (url: string) => void) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setIsUploading(true);
      try {
          const storageRef = ref(storage, `${path}/${Date.now()}_${file.name}`);
          const snapshot = await uploadBytes(storageRef, file);
          const url = await getDownloadURL(snapshot.ref);
          callback(url);
      } catch (err: any) { 
          console.error(err);
          showAlert({ type: 'error', message: 'Upload Failed' });
      } finally { 
          setIsUploading(false); 
      }
  };

  const handleManualLink = async (field: 'logo' | 'hero' | 'board') => {
      const url = await showPrompt({
          title: "Image URL",
          message: "Enter the direct link to the image:",
          placeholder: "https://example.com/image.jpg"
      });
      
      if (url) {
          if (field === 'logo') updateField('logoUrl', url); // Not localized
          if (field === 'hero') updateField('heroImages', [...branding.heroImages, url]); // Not localized
          if (field === 'board') setNewBoardMember(prev => ({ ...prev, image: url }));
      }
  };

  // --- LOCALIZATION HELPERS ---
  
  // Get value for current edit language
  const getLoc = (val: LocalizedString | undefined): string => {
      if (!val) return '';
      if (typeof val === 'string') return val; // Legacy string support
      return val[editLang] || '';
  };

  // Generic Update for simple fields
  const updateField = (key: string, val: any, localized = false) => {
    setBranding(prev => {
        let newVal = val;
        if (localized) {
            const current = (prev as any)[key];
            const currentObj = typeof current === 'object' && current !== null && !Array.isArray(current) 
                ? current 
                : { de: typeof current === 'string' ? current : '' }; // Preserve existing string as DE default
            newVal = { ...currentObj, [editLang]: val };
        }
        
        const newState = { ...prev, [key]: newVal };
        if (key === 'primary' || key === 'secondary') {
            document.documentElement.style.setProperty(`--${key}`, val);
        }
        return newState;
    });
  };

  // Generic Update for Arrays of Objects (Missions, Roadmap, Selectors)
  const updateArrayField = (arrayKey: keyof BrandingSettings, index: number, subKey: string, val: any, localized = false) => {
      setBranding(prev => {
          const arr = [...(prev[arrayKey] as any[])];
          const currentItem = arr[index];
          let newVal = val;

          if (localized) {
              const currentSubVal = currentItem[subKey];
              const currentObj = typeof currentSubVal === 'object' && currentSubVal !== null
                  ? currentSubVal
                  : { de: typeof currentSubVal === 'string' ? currentSubVal : '' };
              newVal = { ...currentObj, [editLang]: val };
          }

          arr[index] = { ...currentItem, [subKey]: newVal };
          return { ...prev, [arrayKey]: arr };
      });
  };

  // --- Highlights Logic ---
  const addHighlightWord = () => {
      if (!newHighlightWord.trim()) return;
      if (!branding.whyJoinHighlightWords.includes(newHighlightWord.trim())) {
          setBranding(prev => ({
              ...prev,
              whyJoinHighlightWords: [...prev.whyJoinHighlightWords, newHighlightWord.trim()]
          }));
      }
      setNewHighlightWord('');
  };

  const removeHighlightWord = (wordToRemove: string) => {
      setBranding(prev => ({
          ...prev,
          whyJoinHighlightWords: prev.whyJoinHighlightWords.filter(w => w !== wordToRemove)
      }));
  };

  // --- Board Actions ---
  const handleBoardImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setIsUploading(true);
      try {
          const storageRef = ref(storage, `board/${Date.now()}_${file.name}`);
          const snapshot = await uploadBytes(storageRef, file);
          const url = await getDownloadURL(snapshot.ref);
          setNewBoardMember(prev => ({ ...prev, image: url }));
      } catch (err) { console.error(err); } finally { setIsUploading(false); }
  };

  const handleAddBoardMember = async () => {
      if (!newBoardMember.userId || !newBoardMember.role) return;
      await addDoc(collection(db, 'board_members'), {
          ...newBoardMember,
          createdAt: serverTimestamp()
      });
      setNewBoardMember({ userId: '', role: '', quote: '', image: '' });
  };

  const handleDeleteBoardMember = async (id: string) => {
      await deleteDoc(doc(db, 'board_members', id));
  };

  const addArrayItem = (key: keyof BrandingSettings, defaultItem: any) => {
      setBranding(prev => ({ ...prev, [key]: [...(prev[key] as any[]), defaultItem] }));
  };

  const removeArrayItem = (key: keyof BrandingSettings, index: number) => {
      setBranding(prev => ({ ...prev, [key]: (prev[key] as any[]).filter((_, i) => i !== index) }));
  };

  // Reusable Section Component
  const BuilderSection = ({ id, title, icon, children }: { id: string, title: string, icon: React.ReactNode, children?: React.ReactNode }) => (
      <div className={`bg-stone-50 rounded-3xl border transition-all duration-300 ${expandedSection === id ? 'border-primary/50 shadow-lg bg-white' : 'border-stone-200'}`}>
          <button 
              onClick={() => setExpandedSection(expandedSection === id ? null : id)}
              className="w-full flex items-center justify-between p-6 text-left"
          >
              <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-xl transition-colors ${expandedSection === id ? 'bg-primary text-white' : 'bg-white text-stone-400'}`}>
                      {icon}
                  </div>
                  <span className={`font-bold text-sm uppercase tracking-wider ${expandedSection === id ? 'text-stone-900' : 'text-stone-500'}`}>{title}</span>
              </div>
              {expandedSection === id ? <ChevronUp size={18} className="text-primary"/> : <ChevronDown size={18} className="text-stone-300"/>}
          </button>
          <AnimatePresence>
              {expandedSection === id && (
                  <motion.div 
                      initial={{ height: 0, opacity: 0 }} 
                      animate={{ height: 'auto', opacity: 1 }} 
                      exit={{ height: 0, opacity: 0 }}
                      className="overflow-hidden"
                  >
                      <div className="p-6 pt-0 border-t border-stone-100">
                          <div className="pt-6 space-y-6">
                              {children}
                          </div>
                      </div>
                  </motion.div>
              )}
          </AnimatePresence>
      </div>
  );

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 h-[calc(100vh-140px)]">
      {/* CMS Sidebar */}
      <div className="lg:col-span-5 flex flex-col h-full bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
          
          {/* Tabs */}
          <div className="flex border-b border-stone-100 overflow-x-auto bg-stone-50/50 p-2 gap-1 shrink-0">
             {(['GLOBAL', 'HOME', 'ABOUT', 'LIVE', 'LEGAL'] as const).map(t => (
                 <button key={t} onClick={() => { setActiveTab(t); setExpandedSection(null); }} className={`flex-1 px-4 py-3 rounded-xl text-[10px] font-bold uppercase tracking-widest transition-all whitespace-nowrap ${activeTab === t ? 'bg-white text-primary shadow-sm' : 'text-stone-400 hover:text-stone-900'}`}>
                     {t}
                 </button>
             ))}
          </div>

          {/* LANGUAGE SWITCHER */}
          <div className="px-6 pt-6 pb-2">
              <div className="bg-stone-100 p-1 rounded-xl flex">
                  {(['de', 'en', 'sq'] as const).map(lang => (
                      <button 
                        key={lang}
                        onClick={() => setEditLang(lang)}
                        className={`flex-1 py-2 rounded-lg text-xs font-bold uppercase transition-all flex items-center justify-center gap-2 ${editLang === lang ? 'bg-white shadow-sm text-primary' : 'text-stone-400 hover:text-stone-600'}`}
                      >
                          <Languages size={14} /> {lang}
                      </button>
                  ))}
              </div>
              <p className="text-[10px] text-stone-400 text-center mt-2 italic">
                  Editing content for: <span className="font-bold uppercase text-stone-600">{editLang}</span>
              </p>
          </div>

          <div className="flex-1 overflow-y-auto custom-scrollbar p-6 space-y-4">
            
            {activeTab === 'GLOBAL' && (
                <>
                    <BuilderSection id="branding" title="Identity & Colors" icon={<Palette size={18}/>}>
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">Primary Color</label>
                                <div className="flex items-center gap-2 bg-stone-50 p-2 rounded-xl border border-stone-100">
                                    <input type="color" value={branding.primary} onChange={(e) => updateField('primary', e.target.value)} className="w-8 h-8 rounded-lg cursor-pointer bg-transparent" />
                                    <span className="text-[10px] font-mono">{branding.primary}</span>
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">Secondary Color</label>
                                <div className="flex items-center gap-2 bg-stone-50 p-2 rounded-xl border border-stone-100">
                                    <input type="color" value={branding.secondary} onChange={(e) => updateField('secondary', e.target.value)} className="w-8 h-8 rounded-lg cursor-pointer bg-transparent" />
                                    <span className="text-[10px] font-mono">{branding.secondary}</span>
                                </div>
                            </div>
                        </div>
                        <div className="p-4 border-2 border-dashed border-stone-100 rounded-2xl flex flex-col gap-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    {branding.logoUrl ? <img src={branding.logoUrl} className="h-8 object-contain" /> : <div className="w-8 h-8 bg-stone-100 rounded-lg flex items-center justify-center"><ImageIcon size={16} className="text-stone-300"/></div>}
                                    <span className="text-xs font-bold text-stone-500">Logo Asset</span>
                                </div>
                                <div className="flex gap-2">
                                    <button onClick={() => handleManualLink('logo')} className="text-[10px] font-bold bg-white border border-stone-200 px-3 py-1.5 rounded-lg hover:bg-stone-50 transition-colors flex items-center gap-1"><LinkIcon size={12}/> URL</button>
                                    <button onClick={() => fileInputRef.current?.click()} className="text-[10px] font-bold bg-stone-100 px-3 py-1.5 rounded-lg hover:bg-stone-200 transition-colors flex items-center gap-1"><Upload size={12}/> Upload</button>
                                </div>
                                <input type="file" ref={fileInputRef} hidden accept="image/*" onChange={(e) => handleFileUpload(e, 'branding', (url) => updateField('logoUrl', url))} />
                            </div>
                            
                            <div className="pt-4 border-t border-stone-100">
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">Logo Height</label>
                                <div className="flex gap-4 items-center">
                                    <input 
                                        value={branding.logoHeight} 
                                        onChange={e => updateField('logoHeight', e.target.value)} 
                                        className="flex-1 p-2 bg-stone-50 rounded-lg text-sm border border-stone-100 outline-none" 
                                        placeholder="e.g. 40px, 3rem"
                                    />
                                    <div className="text-xs text-stone-400">Default: 2.5rem</div>
                                </div>
                            </div>
                        </div>
                    </BuilderSection>

                    <BuilderSection id="footer" title="Footer & Contact" icon={<Mail size={18}/>}>
                        <div className="space-y-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">Address</label>
                                <input value={branding.footerAddress} onChange={e => updateField('footerAddress', e.target.value)} className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-primary/30" />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">Public Email</label>
                                <input value={branding.footerEmail} onChange={e => updateField('footerEmail', e.target.value)} className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-primary/30" />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Mission Text (Footer) <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.footerText)} 
                                    onChange={e => updateField('footerText', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-primary/30 h-24" 
                                />
                            </div>
                        </div>
                    </BuilderSection>
                </>
            )}

            {activeTab === 'HOME' && (
                <>
                    <BuilderSection id="hero" title="Hero Section" icon={<LayoutTemplate size={18}/>}>
                        <div className="space-y-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Top Badge <Languages size={10} className="text-primary"/></label>
                                <input 
                                    value={getLoc(branding.heroBadge)} 
                                    onChange={e => updateField('heroBadge', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-bold" 
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Headline <Languages size={10} className="text-primary"/></label>
                                <input 
                                    value={getLoc(branding.heroTitle)} 
                                    onChange={e => updateField('heroTitle', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-display font-bold" 
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Subtitle <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.heroSubtitle)} 
                                    onChange={e => updateField('heroSubtitle', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 h-20" 
                                />
                            </div>
                            
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">Slideshow Images</label>
                                <div className="grid grid-cols-3 gap-2">
                                    {branding.heroImages.map((img, idx) => (
                                        <div key={idx} className="aspect-video relative rounded-lg overflow-hidden group">
                                            <img src={img} className="w-full h-full object-cover" />
                                            <button onClick={() => updateField('heroImages', branding.heroImages.filter((_, i) => i !== idx))} className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white"><Trash2 size={16}/></button>
                                        </div>
                                    ))}
                                    <div className="flex flex-col gap-2">
                                        <button onClick={() => heroInputRef.current?.click()} className="flex-1 aspect-video border-2 border-dashed border-stone-200 rounded-lg flex items-center justify-center text-stone-300 hover:text-primary hover:border-primary/50 transition-all flex-col gap-1 text-[10px] font-bold">
                                            <Plus size={16}/> Upload
                                        </button>
                                        <button onClick={() => handleManualLink('hero')} className="py-2 bg-stone-100 text-stone-500 rounded-lg text-[10px] font-bold hover:bg-stone-200">
                                            Add URL
                                        </button>
                                    </div>
                                    <input type="file" ref={heroInputRef} hidden accept="image/*" onChange={(e) => handleFileUpload(e, 'hero', (url) => updateField('heroImages', [...branding.heroImages, url]))} />
                                </div>
                            </div>
                        </div>
                    </BuilderSection>

                    <BuilderSection id="hypertext" title="Interactive Mission" icon={<Type size={18}/>}>
                        <div className="space-y-6">
                            <div className="p-4 bg-primary/5 border border-primary/10 rounded-2xl">
                                <p className="text-xs text-primary/80 italic">This text appears below the hero. Words added to the <strong>Highlights</strong> list will animate on hover.</p>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Main Paragraph <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.whyJoinText)} 
                                    onChange={e => updateField('whyJoinText', e.target.value, true)} 
                                    className="w-full p-4 bg-stone-50 rounded-2xl text-sm border border-stone-100 h-32 focus:border-primary/30 outline-none leading-relaxed"
                                    placeholder="Enter your mission text here..."
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">Magic Words (Highlights)</label>
                                <div className="flex gap-2 mb-3">
                                    <input 
                                        value={newHighlightWord}
                                        onChange={(e) => setNewHighlightWord(e.target.value)}
                                        onKeyDown={(e) => e.key === 'Enter' && addHighlightWord()}
                                        placeholder="Type word & press Enter..."
                                        className="flex-1 p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none focus:border-primary"
                                    />
                                    <button onClick={addHighlightWord} className="p-3 bg-stone-900 text-white rounded-xl"><Plus size={18}/></button>
                                </div>
                                <div className="flex flex-wrap gap-2">
                                    {branding.whyJoinHighlightWords.map((word, idx) => (
                                        <div key={idx} className="bg-white border border-stone-200 px-3 py-1.5 rounded-full flex items-center gap-2 shadow-sm animate-in fade-in zoom-in duration-200">
                                            <span className="text-xs font-bold text-primary">{word}</span>
                                            <button onClick={() => removeHighlightWord(word)} className="text-stone-300 hover:text-red-500"><X size={12}/></button>
                                        </div>
                                    ))}
                                    {branding.whyJoinHighlightWords.length === 0 && <span className="text-xs text-stone-400 italic">No highlights added yet.</span>}
                                </div>
                            </div>
                        </div>
                    </BuilderSection>
                </>
            )}

            {activeTab === 'ABOUT' && (
                <>
                    <BuilderSection id="board" title="Board Members" icon={<Briefcase size={18}/>}>
                        <div className="space-y-6">
                            <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200 space-y-3">
                                <h5 className="text-[10px] font-bold uppercase tracking-widest text-stone-500">New Entry</h5>
                                <div className="flex gap-3">
                                    <div 
                                        className="w-16 h-16 bg-white border-2 border-dashed border-stone-200 rounded-xl flex flex-col items-center justify-center cursor-pointer hover:border-primary overflow-hidden relative"
                                    >
                                        {newBoardMember.image ? (
                                            <img src={newBoardMember.image} className="w-full h-full object-cover"/> 
                                        ) : (
                                            <div className="flex flex-col items-center gap-1">
                                                <button onClick={() => boardImageInputRef.current?.click()} className="text-[8px] font-bold text-stone-400 hover:text-primary">Upload</button>
                                                <div className="h-px w-8 bg-stone-200" />
                                                <button onClick={() => handleManualLink('board')} className="text-[8px] font-bold text-stone-400 hover:text-primary">URL</button>
                                            </div>
                                        )}
                                        <input type="file" ref={boardImageInputRef} hidden accept="image/*" onChange={handleBoardImageUpload} />
                                    </div>
                                    <div className="flex-1 space-y-2">
                                        <select value={newBoardMember.userId} onChange={e => setNewBoardMember({...newBoardMember, userId: e.target.value})} className="w-full p-2 bg-white rounded-lg text-xs border border-stone-200 outline-none">
                                            <option value="">Select User...</option>
                                            {users.map(u => <option key={u.id} value={u.id}>{u.displayName}</option>)}
                                        </select>
                                        <input placeholder="Role (e.g. Kryetar)" value={newBoardMember.role} onChange={e => setNewBoardMember({...newBoardMember, role: e.target.value})} className="w-full p-2 bg-white rounded-lg text-xs border border-stone-200 outline-none" />
                                    </div>
                                </div>
                                <textarea placeholder="Quote..." value={newBoardMember.quote} onChange={e => setNewBoardMember({...newBoardMember, quote: e.target.value})} className="w-full p-2 bg-white rounded-lg text-xs border border-stone-200 outline-none h-16" />
                                <button onClick={handleAddBoardMember} disabled={!newBoardMember.userId} className="w-full py-2 bg-stone-900 text-white rounded-lg text-xs font-bold disabled:opacity-50">Add Member</button>
                            </div>

                            <div className="space-y-3">
                                {boardMembers.map(bm => {
                                    const u = users.find(user => user.id === bm.userId);
                                    return (
                                        <div key={bm.id} className="flex items-center justify-between p-3 bg-white border border-stone-100 rounded-xl shadow-sm">
                                            <div className="flex items-center gap-3">
                                                <img src={bm.image || u?.photoFileName} className="w-8 h-8 rounded-full object-cover bg-stone-200"/>
                                                <div>
                                                    <p className="text-xs font-bold">{u?.displayName}</p>
                                                    <p className="text-[10px] text-stone-500">{bm.role}</p>
                                                </div>
                                            </div>
                                            <button onClick={() => handleDeleteBoardMember(bm.id)} className="text-stone-300 hover:text-red-500"><Trash2 size={14}/></button>
                                        </div>
                                    )
                                })}
                            </div>
                        </div>
                    </BuilderSection>

                    <BuilderSection id="missions" title="Mission Cards" icon={<Activity size={18}/>}>
                        <div className="space-y-4">
                            {branding.missions.map((m, idx) => (
                                <div key={idx} className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                                    <div className="flex justify-between mb-2">
                                        <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{m.type}</span>
                                    </div>
                                    <input 
                                        value={getLoc(m.title)} 
                                        onChange={e => updateArrayField('missions', idx, 'title', e.target.value, true)} 
                                        className="w-full p-2 mb-2 bg-white rounded-lg text-sm font-bold border border-stone-100 outline-none" 
                                        placeholder={`Title (${editLang})`} 
                                    />
                                    <textarea 
                                        value={getLoc(m.description)} 
                                        onChange={e => updateArrayField('missions', idx, 'description', e.target.value, true)} 
                                        className="w-full p-2 bg-white rounded-lg text-xs border border-stone-100 outline-none h-16" 
                                        placeholder={`Description (${editLang})`} 
                                    />
                                </div>
                            ))}
                        </div>
                    </BuilderSection>

                    <BuilderSection id="roadmap" title="Timeline / Roadmap" icon={<Milestone size={18}/>}>
                        <div className="space-y-4">
                            {branding.roadmap.map((r, idx) => (
                                <div key={idx} className="flex gap-2">
                                    <div className="flex-1 space-y-2">
                                        <input 
                                            value={getLoc(r.title)} 
                                            onChange={e => updateArrayField('roadmap', idx, 'title', e.target.value, true)} 
                                            className="w-full p-2 bg-stone-50 rounded-lg text-sm font-bold outline-none" 
                                            placeholder={`Year / Milestone (${editLang})`} 
                                        />
                                        <textarea 
                                            value={getLoc(r.description)} 
                                            onChange={e => updateArrayField('roadmap', idx, 'description', e.target.value, true)} 
                                            className="w-full p-2 bg-stone-50 rounded-lg text-xs outline-none" 
                                            placeholder={`Description (${editLang})`} 
                                        />
                                    </div>
                                    <button onClick={() => removeArrayItem('roadmap', idx)} className="text-stone-300 hover:text-red-500 self-start mt-2"><X size={16}/></button>
                                </div>
                            ))}
                            <button onClick={() => addArrayItem('roadmap', { title: '', description: '' })} className="w-full py-2 border-2 border-dashed border-stone-200 rounded-xl text-stone-400 text-xs font-bold hover:text-primary hover:border-primary/50 transition-colors">+ Add Milestone</button>
                        </div>
                    </BuilderSection>
                </>
            )}

            {activeTab === 'LIVE' && (
                <BuilderSection id="selectors" title="Live Features" icon={<Zap size={18}/>}>
                    <div className="space-y-4">
                        {branding.liveSelectors.map((s, idx) => (
                            <div key={idx} className="p-4 bg-stone-50 rounded-2xl border border-stone-200 flex gap-4">
                                {/* Image Box */}
                                <div className="relative group w-16 h-16 shrink-0">
                                     <div className="w-full h-full bg-white rounded-xl border border-stone-200 overflow-hidden flex items-center justify-center">
                                         {s.image ? <img src={s.image} className="w-full h-full object-cover"/> : <ImageIcon size={16} className="text-stone-300"/>}
                                     </div>
                                     
                                     {/* Hover Overlay with 2 buttons */}
                                     <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 flex flex-col items-center justify-center gap-1 transition-opacity rounded-xl backdrop-blur-sm">
                                         <button 
                                            onClick={() => {
                                                const input = document.createElement('input');
                                                input.type = 'file';
                                                input.onchange = (e: any) => handleFileUpload(e, 'live', (url) => updateArrayField('liveSelectors', idx, 'image', url));
                                                input.click();
                                            }}
                                            className="p-1 bg-white/20 hover:bg-white text-white hover:text-stone-900 rounded-full"
                                            title="Upload"
                                         >
                                            <Upload size={10}/>
                                         </button>
                                         <button 
                                            onClick={() => {
                                                showPrompt({
                                                    title: "Image URL",
                                                    message: "Enter direct link:",
                                                    placeholder: "https://..."
                                                }).then(url => {
                                                    if(url) updateArrayField('liveSelectors', idx, 'image', url);
                                                })
                                            }}
                                            className="p-1 bg-white/20 hover:bg-white text-white hover:text-stone-900 rounded-full"
                                            title="Paste URL"
                                         >
                                            <LinkIcon size={10}/>
                                         </button>
                                     </div>
                                </div>
                                <div className="flex-1 space-y-2">
                                    <input 
                                        value={getLoc(s.title)} 
                                        onChange={e => updateArrayField('liveSelectors', idx, 'title', e.target.value, true)} 
                                        className="w-full p-2 bg-white rounded-lg text-sm font-bold outline-none border border-stone-100" 
                                        placeholder={`Title (${editLang})`}
                                    />
                                    <input 
                                        value={getLoc(s.description)} 
                                        onChange={e => updateArrayField('liveSelectors', idx, 'description', e.target.value, true)} 
                                        className="w-full p-2 bg-white rounded-lg text-xs outline-none border border-stone-100" 
                                        placeholder={`Desc (${editLang})`}
                                    />
                                </div>
                            </div>
                        ))}
                    </div>
                </BuilderSection>
            )}

            {activeTab === 'LEGAL' && (
                <BuilderSection id="legal" title="Privacy & GDPR" icon={<ShieldAlert size={18}/>}>
                    <div className="space-y-4">
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">GDPR Text <Languages size={10} className="text-primary"/></label>
                            <textarea 
                                value={getLoc(branding.gdprText)} 
                                onChange={e => updateField('gdprText', e.target.value, true)} 
                                className="w-full p-4 bg-stone-50 rounded-2xl text-xs font-mono border border-stone-100 outline-none h-48" 
                                placeholder={`GDPR Content for ${editLang}...`}
                            />
                        </div>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">Privacy Policy <Languages size={10} className="text-primary"/></label>
                            <textarea 
                                value={getLoc(branding.privacyText)} 
                                onChange={e => updateField('privacyText', e.target.value, true)} 
                                className="w-full p-4 bg-stone-50 rounded-2xl text-xs font-mono border border-stone-100 outline-none h-48" 
                                placeholder={`Privacy Content for ${editLang}...`}
                            />
                        </div>
                    </div>
                </BuilderSection>
            )}

          </div>

          <div className="p-6 border-t border-stone-100 bg-stone-50 shrink-0">
              <button 
                onClick={handleSaveBranding}
                disabled={isSaving || isUploading}
                className={`w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-3 transition-all ${isSaved ? 'bg-green-500 text-white' : 'bg-primary text-white shadow-xl shadow-rose-200 hover:scale-[1.02]'}`}
              >
                {isSaving || isUploading ? <Loader2 className="animate-spin" /> : isSaved ? <Check /> : <Save />} 
                {isUploading ? 'Uploading...' : 'Publish Changes'}
              </button>
          </div>
      </div>

      {/* Preview Panel */}
      <div className={`lg:col-span-7 transition-all duration-500 hidden lg:block ${showPreview ? 'opacity-100 scale-100' : 'opacity-0 scale-95 pointer-events-none'}`}>
        <div className="sticky top-12 h-full flex flex-col">
          <div className="flex justify-center mb-6 gap-4 shrink-0">
              <button onClick={() => setPreviewMode('DESKTOP')} className={`p-3 rounded-xl transition-all ${previewMode === 'DESKTOP' ? 'bg-primary text-white' : 'bg-white text-stone-400'}`}><Monitor size={18} /></button>
              <button onClick={() => setPreviewMode('MOBILE')} className={`p-3 rounded-xl transition-all ${previewMode === 'MOBILE' ? 'bg-primary text-white' : 'bg-white text-stone-400'}`}><Smartphone size={18} /></button>
          </div>
          
          <div className="bg-stone-900 rounded-[3.5rem] p-4 shadow-2xl border-[12px] border-stone-800 relative mx-auto flex-1 w-full max-h-[800px]">
            <div className={`bg-[#faf9f6] rounded-[2.5rem] h-full overflow-y-auto custom-scrollbar transition-all duration-500 mx-auto ${previewMode === 'MOBILE' ? 'max-w-[375px]' : 'w-full'}`}>
               
               {/* Preview Header */}
               <div className="px-8 py-4 border-b border-stone-100 flex justify-between items-center sticky top-0 bg-white/80 backdrop-blur-md z-10">
                  <div className="flex items-center gap-2">
                     {branding.logoUrl ? <img src={branding.logoUrl} style={{ height: branding.logoHeight || '2.5rem' }} className="w-auto object-contain" /> : <div className="bg-primary p-1 rounded-lg text-white"><Heart size={12} fill="white" /></div>}
                     <span className="font-display font-bold italic text-sm text-stone-800">Koretini</span>
                  </div>
                  <div className="flex gap-1">
                      <div className="w-8 h-3 bg-stone-200 rounded-full" />
                      <div className="w-8 h-3 bg-stone-200 rounded-full" />
                  </div>
               </div>

               {/* PREVIEW CONTENT (Uses getLoc to show current editing language) */}
               <div className="p-8">
                  
                  {/* Hero Section */}
                  <div className="mb-12 text-center">
                      <div className="inline-block bg-rose-50 text-primary px-3 py-1 rounded-full text-[10px] font-bold mb-4 italic tracking-wide uppercase border border-rose-100 shadow-sm">{getLoc(branding.heroBadge)}</div>
                      <h1 className="font-display text-4xl font-bold mb-6 italic leading-tight text-stone-900">{getLoc(branding.heroTitle)}</h1>
                      <p className="text-stone-500 text-sm mb-8 italic leading-relaxed">{getLoc(branding.heroSubtitle)}</p>
                      
                      <div className="w-full aspect-video rounded-3xl bg-stone-200 overflow-hidden mb-12 shadow-xl border-4 border-white relative">
                          {branding.heroImages[0] && <img src={branding.heroImages[0]} className="w-full h-full object-cover" />}
                          <div className="absolute inset-0 bg-gradient-to-t from-stone-900/40 to-transparent" />
                      </div>
                  </div>

                  {/* HyperText Preview */}
                  {getLoc(branding.whyJoinText) && (
                      <div className="mb-16 text-center relative">
                          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-rose-100/30 blur-3xl rounded-full -z-10" />
                          <p className="text-[10px] font-bold text-stone-400 uppercase tracking-[0.2em] mb-4">Mission Interactive Preview</p>
                          <div className="bg-white/50 backdrop-blur-sm p-8 rounded-3xl border border-white/50 shadow-sm">
                              <HyperTextParagraph 
                                  text={getLoc(branding.whyJoinText)}
                                  highlightWords={branding.whyJoinHighlightWords}
                                  className="text-xl md:text-2xl font-display text-stone-800 leading-normal"
                              />
                          </div>
                      </div>
                  )}

                  <div className="h-px bg-gradient-to-r from-transparent via-stone-200 to-transparent mb-12" />

                  {/* About Preview */}
                  <h4 className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-6 text-center">Section: About & Values</h4>
                  <div className="grid grid-cols-1 gap-4 mb-12">
                      {branding.missions.map((m, i) => (
                          <div key={i} className="p-6 bg-white rounded-3xl border border-stone-100 shadow-sm">
                              <h5 className="font-bold text-lg mb-2 text-stone-900">{getLoc(m.title)}</h5>
                              <p className="text-xs text-stone-500 italic leading-relaxed">{getLoc(m.description)}</p>
                          </div>
                      ))}
                  </div>

                  {/* Footer Preview */}
                  <div className="bg-stone-900 text-white p-8 rounded-3xl mt-8 text-center">
                      <h4 className="font-display italic text-xl mb-4">Koretini</h4>
                      <p className="text-white/50 text-xs mb-6 italic">{getLoc(branding.footerText)}</p>
                      <div className="flex justify-center gap-4 text-[10px] text-white/30 uppercase tracking-widest">
                          <span>{branding.footerEmail}</span>
                          <span>•</span>
                          <span>{branding.footerAddress}</span>
                      </div>
                  </div>

               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminWebsite;
