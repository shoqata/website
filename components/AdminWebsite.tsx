
import React, { useState, useEffect, useRef } from 'react';
import { vereinsbildHochladen, type BildZweck } from '../lib/bildPruefen';
import { useTranslation } from '../context/LanguageContext';
import MemberPicker from './ui/MemberPicker';
import { AnimatePresence, motion } from 'framer-motion';
import { Activity, Briefcase, Check, ChevronDown, ChevronUp, Globe, Heart, History, Home, Image as ImageIcon, Languages, LayoutTemplate, Link as LinkIcon, Loader2, Mail, MapPin, Milestone, Monitor, Palette, Plus, RefreshCw, Save, ShieldAlert, Smartphone, Trash2, Trophy, Type, Upload, X, Zap } from 'lucide-react';
import { db, storage } from '../services/datenzugriff';
import { doc, setDoc, onSnapshot, serverTimestamp, collection, deleteDoc, addDoc } from '@/services/supabase-bridge';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';
import { UserProfile, BoardMember } from '../types';
import HyperTextParagraph from './ui/HyperText'; // Import for Preview
import { useFeedback } from '../context/FeedbackContext';

import { onImageError } from '../lib/imageFallback';
import { useModule } from '../lib/useModule';
import AdminVorlagen from './AdminVorlagen';
import AdminSeiten from './AdminSeiten';
import AdminNavigation from './AdminNavigation';
import AdminUeberUns from './AdminUeberUns';
import AdminChronik from './AdminChronik';
import AdminKontakt from './AdminKontakt';
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
  // Das Turnier. Die Seite /fussball liest diese vier Felder seit immer
  // -- nur gab es keine Stelle, sie zu setzen, und ohne Wert fiel sie auf
  // das Turnier von Koretini zurueck. Ein anderer Verein zeigte damit
  // unter seiner eigenen Adresse ein fremdes Turnier.
  tournamentTitle?: LocalizedString;
  tournamentIntro?: LocalizedString;
  tournamentEmbedUrl?: string;
  tournamentDetailUrl?: string;
}

type Tab = 'DESIGN' | 'GLOBAL' | 'NAVIGATION' | 'HOME' | 'ABOUT' | 'CHRONIK' | 'KONTAKT' | 'SEITEN' | 'LIVE' | 'TURNIER' | 'LEGAL';
type LangCode = 'de' | 'en' | 'sq';

// Aufklappbarer Bereich im Editor. Auf Modulebene, nicht innerhalb von
// AdminWebsite: dort definiert, war er bei jedem Tastendruck eine neue
// Komponente -- React baute ihn neu auf, und das Eingabefeld verlor nach
// jedem Buchstaben den Fokus.
const BuilderSection = ({ id, title, icon, children, offen, setOffen }: {
  id: string, title: string, icon: React.ReactNode, children?: React.ReactNode,
  offen: string | null, setOffen: (id: string | null) => void }) => (
      <div className={`bg-stone-50 rounded-3xl border transition-all duration-300 ${offen === id ? 'border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)] shadow-lg bg-white' : 'border-stone-200'}`}>
          <button 
              onClick={() => setOffen(offen === id ? null : id)}
              className="w-full flex items-center justify-between p-6 text-left"
          >
              <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-xl transition-colors ${offen === id ? 'bg-primary text-white' : 'bg-white text-stone-400'}`}>
                      {icon}
                  </div>
                  <span className={`font-bold text-sm uppercase tracking-wider ${offen === id ? 'text-stone-900' : 'text-stone-500'}`}>{title}</span>
              </div>
              {offen === id ? <ChevronUp size={18} className="text-primary"/> : <ChevronDown size={18} className="text-stone-300"/>}
          </button>
          <AnimatePresence>
              {offen === id && (
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

const AdminWebsite: React.FC = () => {
  const { t } = useTranslation();
  // Der Turnierreiter erscheint nur mit gebuchtem Modul -- ein Reiter
  // fuer eine Seite, die der Verein nicht hat, ist eine Einladung zum
  // Ausfuellen ins Leere.
  const { aktiv: modulAktiv } = useModule();
  const { showAlert, showPrompt } = useFeedback();
  const [activeTab, setActiveTab] = useState<Tab>('DESIGN');
  const [editLang, setEditLang] = useState<LangCode>('de'); // Editor Language State
  const [isSaving, setIsSaving] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [showPreview, setShowPreview] = useState(true);
  // Der Rahmen laedt die echte Seite. Nach dem Wechsel der Vorlage muss er
  // neu laden -- ein Schluessel, der sich aendert, erzwingt das.
  const [vorschauSchluessel, setVorschauSchluessel] = useState(0);
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

  // Leere Vorgaben, keine Inhalte.
  //
  // Hier standen bis zum 29.09.2026 Koretinis eigene Texte: "Koretin,
  // Kosovë", info@koretini.org, "Zemra e fshatit tonë." Das ist eine
  // Plattform fuer mehrere Vereine -- der zweite Verein, der diesen Reiter
  // einmal oeffnet und speichert, haette Koretinis Adresse und E-Mail auf
  // SEINE Website geschrieben, ohne je etwas eingetippt zu haben.
  // handleSaveBranding schreibt naemlich das ganze Objekt.
  //
  // Dass es bisher niemanden getroffen hat, liegt allein daran, dass es
  // bis heute nur einen Verein gibt.
  const [branding, setBranding] = useState<BrandingSettings>({
    primary: '#f43f5e',
    secondary: '#1c1917',
    logoUrl: '',
    logoHeight: '2.5rem',
    footerText: '',
    footerAddress: '',
    footerEmail: '',
    heroTitle: '',
    heroSubtitle: '',
    heroBadge: '',
    heroImages: [],
    tournamentTitle: '',
    tournamentIntro: '',
    tournamentEmbedUrl: '',
    tournamentDetailUrl: '',
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
      setVorschauSchluessel(k => k + 1);
      setTimeout(() => setIsSaved(false), 3000);
    } catch (error) {
      console.error(error);
      showAlert({ type: 'error', message: t('web.save_failed') });
    } finally {
      setIsSaving(false);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, path: string, callback: (url: string) => void) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setIsUploading(true);
      try {
          // Ueber die Bildpruefung (bild-pruefen): neu erzeugt aus Pixeln.
          const url = await vereinsbildHochladen(file, path as BildZweck);
          callback(url);
      } catch (err: any) { 
          console.error(err);
          showAlert({ type: 'error', message: err?.message || t('web.upload_failed') });
      } finally { 
          setIsUploading(false); 
      }
  };

  const handleManualLink = async (field: 'logo' | 'hero' | 'board') => {
      const url = await showPrompt({
          title: t('web.image_url'),
          message: t('web.image_url_prompt'),
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
  // Name im Vorschaufenster: bisher fest "Koretini", also fuer jeden anderen
  // Verein falsch.
  const previewName = (() => {
      const v: any = (branding as any).associationName;
      if (!v) return '';
      return typeof v === 'string' ? v : (v[editLang] || v.de || v.sq || v.en || '');
  })();

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
          const url = await vereinsbildHochladen(file, 'board');
          setNewBoardMember(prev => ({ ...prev, image: url }));
      } catch (err: any) {
        console.error('[AdminWebsite] Bild konnte nicht hochgeladen werden:', err);
        showAlert({ type: 'error', message: t('upload.failed', { reason: err?.message || '?' }) });
      } finally { setIsUploading(false); }
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

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 h-[calc(100dvh-140px)]">
      {/* CMS Sidebar */}
      {/* Im Seiten-Reiter die volle Breite: der Editor hat seine eigene
          Vorschau, und die Geraetevorschau rechts zeigt die STARTSEITE --
          daneben gestellt behauptet sie, man saehe die bearbeitete Seite. */}
      <div className={`${activeTab === 'SEITEN' || activeTab === 'NAVIGATION' ? 'lg:col-span-12' : 'lg:col-span-5'} flex flex-col h-full bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden`}>
          
          {/* Tabs */}
          <div className="flex border-b border-stone-100 overflow-x-auto bg-stone-50/50 p-2 gap-1 shrink-0">
             {/* Die Reiter zeigten bisher ihren Schluessel: DESIGN, GLOBAL,
                 LIVE. Verstaendlich fuer den, der den Quelltext kennt. */}
             {(([['DESIGN','Design'], ['GLOBAL','Allgemein'], ['NAVIGATION','Navigation'], ['HOME','Startseite'],
                ['ABOUT','Über uns'], ['CHRONIK','Chronik'], ['KONTAKT','Kontakt'], ['SEITEN','Eigene Seiten'],
                ...(modulAktiv('DORFLEBEN') ? [['LIVE', t('nav.live')]] : []),
                ...(modulAktiv('TURNIER') ? [['TURNIER', t('nav.turnier')]] : []),
                ['LEGAL','Rechtliches']]) as [Tab, string][]).map(([k, name]) => (
                 <button key={k} onClick={() => { setActiveTab(k); setExpandedSection(null); }} className={`flex-1 px-4 py-3 rounded-xl text-[10px] font-bold uppercase tracking-widest transition-all whitespace-nowrap ${activeTab === k ? 'bg-white text-primary shadow-sm' : 'text-stone-400 hover:text-stone-900'}`}>
                     {name}
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
                  {t('web.editing_for')} <span className="font-bold uppercase text-stone-600">{editLang}</span>
              </p>
          </div>

          <div className="flex-1 overflow-y-auto custom-scrollbar p-6 space-y-4">
            
            {/* Welche Vorlage die Website ueberhaupt benutzt. Steht vor
                allem anderen, weil die Entscheidung alles darunter
                einrahmt -- und weil sie vorher in den Einstellungen lag,
                also dort, wo sie niemand suchte. */}
            {/* Eigene Seiten. Bis hierher waren alle Seiten im Quelltext
                festgelegt; ein Verein mit einer eigenen Idee musste warten,
                bis jemand sie programmiert. */}
            {activeTab === 'SEITEN' && <AdminSeiten />}
            {activeTab === 'NAVIGATION' && <AdminNavigation />}
            {activeTab === 'DESIGN' && <AdminVorlagen onGewaehlt={() => setVorschauSchluessel(k => k + 1)} />}

            {activeTab === 'GLOBAL' && (
                <>
                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="branding" title={t('web.identity')} icon={<Palette size={18}/>}>
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">{t('web.primary_color')}</label>
                                <div className="flex items-center gap-2 bg-stone-50 p-2 rounded-xl border border-stone-100">
                                    <input type="color" value={branding.primary} onChange={(e) => updateField('primary', e.target.value)} className="w-8 h-8 rounded-lg cursor-pointer bg-transparent" />
                                    <span className="text-[10px] font-mono">{branding.primary}</span>
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">{t('web.secondary_color')}</label>
                                <div className="flex items-center gap-2 bg-stone-50 p-2 rounded-xl border border-stone-100">
                                    <input type="color" value={branding.secondary} onChange={(e) => updateField('secondary', e.target.value)} className="w-8 h-8 rounded-lg cursor-pointer bg-transparent" />
                                    <span className="text-[10px] font-mono">{branding.secondary}</span>
                                </div>
                            </div>
                        </div>
                        <div className="p-4 border-2 border-dashed border-stone-100 rounded-2xl flex flex-col gap-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    {branding.logoUrl ? <img src={branding.logoUrl} className="h-8 object-contain"  onError={onImageError}/> : <div className="w-8 h-8 bg-stone-100 rounded-lg flex items-center justify-center"><ImageIcon size={16} className="text-stone-300"/></div>}
                                    <span className="text-xs font-bold text-stone-500">{t('web.logo')}</span>
                                </div>
                                <div className="flex gap-2">
                                    <button onClick={() => handleManualLink('logo')} className="text-[10px] font-bold bg-white border border-stone-200 px-3 py-1.5 rounded-lg hover:bg-stone-50 transition-colors flex items-center gap-1"><LinkIcon size={12}/> {t('web.image_url')}</button>
                                    <button onClick={() => fileInputRef.current?.click()} className="text-[10px] font-bold bg-stone-100 px-3 py-1.5 rounded-lg hover:bg-stone-200 transition-colors flex items-center gap-1"><Upload size={12}/> {t('web.upload')}</button>
                                </div>
                                <input type="file" ref={fileInputRef} hidden accept="image/*" onChange={(e) => handleFileUpload(e, 'logo', (url) => updateField('logoUrl', url))} />
                            </div>
                            
                            <div className="pt-4 border-t border-stone-100">
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">{t('web.logo_height')}</label>
                                <div className="flex gap-4 items-center">
                                    <input 
                                        value={branding.logoHeight} 
                                        onChange={e => updateField('logoHeight', e.target.value)} 
                                        className="flex-1 p-2 bg-stone-50 rounded-lg text-sm border border-stone-100 outline-none" 
                                        placeholder={t('web.logo_height_ph')}
                                    />
                                    <div className="text-xs text-stone-400">{t('web.default_value', { value: '2.5rem' })}</div>
                                </div>
                            </div>
                        </div>
                    </BuilderSection>

                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="footer" title={t('web.footer_contact')} icon={<Mail size={18}/>}>
                        <div className="space-y-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">{t('field.address')}</label>
                                <input value={branding.footerAddress} onChange={e => updateField('footerAddress', e.target.value)} className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]" />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">{t('web.public_email')}</label>
                                <input value={branding.footerEmail} onChange={e => updateField('footerEmail', e.target.value)} className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]" />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.mission_footer')} <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.footerText)} 
                                    onChange={e => updateField('footerText', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)] h-24" 
                                />
                            </div>
                        </div>
                    </BuilderSection>
                </>
            )}

            {activeTab === 'HOME' && (
                <>
                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="hero" title={t('web.hero')} icon={<LayoutTemplate size={18}/>}>
                        <div className="space-y-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.top_badge')} <Languages size={10} className="text-primary"/></label>
                                <input 
                                    value={getLoc(branding.heroBadge)} 
                                    onChange={e => updateField('heroBadge', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-bold" 
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.headline')} <Languages size={10} className="text-primary"/></label>
                                <input 
                                    value={getLoc(branding.heroTitle)} 
                                    onChange={e => updateField('heroTitle', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-display font-bold" 
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.subtitle')} <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.heroSubtitle)} 
                                    onChange={e => updateField('heroSubtitle', e.target.value, true)} 
                                    className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 h-20" 
                                />
                            </div>
                            
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">{t('web.slideshow')}</label>
                                <div className="grid grid-cols-3 gap-2">
                                    {branding.heroImages.map((img, idx) => (
                                        <div key={idx} className="aspect-video relative rounded-lg overflow-hidden group">
                                            <img src={img} className="w-full h-full object-cover"  onError={onImageError}/>
                                            <button onClick={() => updateField('heroImages', branding.heroImages.filter((_, i) => i !== idx))} className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white"><Trash2 size={16}/></button>
                                        </div>
                                    ))}
                                    <div className="flex flex-col gap-2">
                                        <button onClick={() => heroInputRef.current?.click()} className="flex-1 aspect-video border-2 border-dashed border-stone-200 rounded-lg flex items-center justify-center text-stone-300 hover:text-primary hover:border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)] transition-all flex-col gap-1 text-[10px] font-bold">
                                            <Plus size={16}/> {t('web.upload')}
                                        </button>
                                        <button onClick={() => handleManualLink('hero')} className="py-2 bg-stone-100 text-stone-500 rounded-lg text-[10px] font-bold hover:bg-stone-200">
                                            {t('web.add_url')}
                                        </button>
                                    </div>
                                    <input type="file" ref={heroInputRef} hidden accept="image/*" onChange={(e) => handleFileUpload(e, 'hero', (url) => updateField('heroImages', [...branding.heroImages, url]))} />
                                </div>
                            </div>
                        </div>
                    </BuilderSection>

                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="hypertext" title={t('web.mission_interactive')} icon={<Type size={18}/>}>
                        <div className="space-y-6">
                            <div className="p-4 bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)] border border-[color:color-mix(in_srgb,var(--primary)_10%,transparent)] rounded-2xl">
                                <p className="text-xs text-[color:color-mix(in_srgb,var(--primary)_80%,transparent)] italic">{t('web.highlights_hint')}</p>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.main_paragraph')} <Languages size={10} className="text-primary"/></label>
                                <textarea 
                                    value={getLoc(branding.whyJoinText)} 
                                    onChange={e => updateField('whyJoinText', e.target.value, true)} 
                                    className="w-full p-4 bg-stone-50 rounded-2xl text-sm border border-stone-100 h-32 focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)] outline-none leading-relaxed"
                                    placeholder={t('web.mission_ph')}
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase mb-2 block">{t('web.magic_words')}</label>
                                <div className="flex gap-2 mb-3">
                                    <input 
                                        value={newHighlightWord}
                                        onChange={(e) => setNewHighlightWord(e.target.value)}
                                        onKeyDown={(e) => e.key === 'Enter' && addHighlightWord()}
                                        placeholder={t('web.magic_words_ph')}
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
                                    {branding.whyJoinHighlightWords.length === 0 && <span className="text-xs text-stone-400 italic">{t('web.no_highlights')}</span>}
                                </div>
                            </div>
                        </div>
                    </BuilderSection>
                </>
            )}

            {activeTab === 'ABOUT' && (
                <>
                    {/* Aufbau und Inhalte der Seite. Hier standen nur Werte-Karten
                        (fest drei, nicht erweiterbar) und eine Zeitleiste;
                        Titel und Einleitung liessen sich gar nicht setzen. */}
                    <AdminUeberUns branding={branding} setBranding={setBranding as any} sprache={editLang} />
                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="board" title={t('web.board')} icon={<Briefcase size={18}/>}>
                        <div className="space-y-6">
                            <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200 space-y-3">
                                <h5 className="text-[10px] font-bold uppercase tracking-widest text-stone-500">{t('web.new_entry')}</h5>
                                <div className="flex gap-3">
                                    <div 
                                        className="w-16 h-16 bg-white border-2 border-dashed border-stone-200 rounded-xl flex flex-col items-center justify-center cursor-pointer hover:border-primary overflow-hidden relative"
                                    >
                                        {newBoardMember.image ? (
                                            <img src={newBoardMember.image} className="w-full h-full object-cover" onError={onImageError}/> 
                                        ) : (
                                            <div className="flex flex-col items-center gap-1">
                                                <button onClick={() => boardImageInputRef.current?.click()} className="text-[8px] font-bold text-stone-400 hover:text-primary">{t('web.upload')}</button>
                                                <div className="h-px w-8 bg-stone-200" />
                                                <button onClick={() => handleManualLink('board')} className="text-[8px] font-bold text-stone-400 hover:text-primary">{t('web.image_url')}</button>
                                            </div>
                                        )}
                                        <input type="file" ref={boardImageInputRef} hidden accept="image/*" onChange={handleBoardImageUpload} />
                                    </div>
                                    <div className="flex-1 space-y-2">
                                        <MemberPicker
                                            single
                                            users={users}
                                            value={newBoardMember.userId ? [newBoardMember.userId] : []}
                                            onChange={(ids) => setNewBoardMember({ ...newBoardMember, userId: ids[0] || '' })}
                                            placeholder={t('web.select_user')}
                                        />
                                        <input placeholder={t('web.role_ph')} value={newBoardMember.role} onChange={e => setNewBoardMember({...newBoardMember, role: e.target.value})} className="w-full p-2 bg-white rounded-lg text-xs border border-stone-200 outline-none" />
                                    </div>
                                </div>
                                <textarea placeholder={t('web.quote_ph')} value={newBoardMember.quote} onChange={e => setNewBoardMember({...newBoardMember, quote: e.target.value})} className="w-full p-2 bg-white rounded-lg text-xs border border-stone-200 outline-none h-16" />
                                <button onClick={handleAddBoardMember} disabled={!newBoardMember.userId} className="w-full py-2 bg-stone-900 text-white rounded-lg text-xs font-bold disabled:opacity-50">{t('web.add_member')}</button>
                            </div>

                            <div className="space-y-3">
                                {boardMembers.map(bm => {
                                    const u = users.find(user => user.id === bm.userId);
                                    return (
                                        <div key={bm.id} className="flex items-center justify-between p-3 bg-white border border-stone-100 rounded-xl shadow-sm">
                                            <div className="flex items-center gap-3">
                                                <img src={bm.image || u?.photoFileName} className="w-8 h-8 rounded-full object-cover bg-stone-200" onError={onImageError}/>
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

                </>
            )}

            {activeTab === 'CHRONIK' && (
                <>
                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="chronik-kopf" title="Titel und Einleitung" icon={<History size={18}/>}>
                        <div className="space-y-3">
                            <input value={getLoc((branding as any).chronikTitel)}
                                onChange={e => updateField('chronikTitel', e.target.value, true)}
                                placeholder={`${t('chronik.titel')} (${editLang})`}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-display font-bold" />
                            <textarea rows={3} value={getLoc((branding as any).chronikIntro)}
                                onChange={e => updateField('chronikIntro', e.target.value, true)}
                                placeholder={`${t('chronik.intro')} (${editLang})`}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100" />
                            <p className="text-[10px] text-stone-400">Wird mit „Veröffentlichen“ unten gespeichert.</p>
                        </div>
                    </BuilderSection>
                    <AdminChronik sprache={editLang} onGespeichert={() => setVorschauSchluessel(k => k + 1)} />
                </>
            )}

            {activeTab === 'KONTAKT' && (
                <>
                    <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="kontakt-seite" title="Seite Kontakt" icon={<Mail size={18}/>}>
                        <div className="space-y-3">
                            <input value={getLoc((branding as any).kontaktTitel)}
                                onChange={e => updateField('kontaktTitel', e.target.value, true)}
                                placeholder={`${t('kontakt.titel')} (${editLang})`}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-display font-bold" />
                            <textarea rows={3} value={getLoc((branding as any).kontaktIntro)}
                                onChange={e => updateField('kontaktIntro', e.target.value, true)}
                                placeholder={`${t('kontakt.intro')} (${editLang})`}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100" />
                            <input value={(branding as any).kontaktTelefon || ''}
                                onChange={e => updateField('kontaktTelefon', e.target.value)}
                                placeholder="Telefon (freiwillig), z. B. +41 79 123 45 67"
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100" />
                            <p className="text-[10px] text-stone-400">Adresse und E-Mail kommen aus Allgemein → Fusszeile. Gespeichert wird mit „Veröffentlichen“ unten.</p>
                        </div>
                    </BuilderSection>
                    <AdminKontakt />
                </>
            )}

            {activeTab === 'TURNIER' && (
                <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="turnier" title={t('nav.turnier')} icon={<Trophy size={18}/>}>
                    <div className="space-y-4">
                        <p className="text-xs text-stone-500 leading-relaxed">
                            {t('web.turnier_hinweis')}
                        </p>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">
                                {t('web.turnier_titel')} <Languages size={10} className="text-primary"/>
                            </label>
                            <input
                                value={getLoc(branding.tournamentTitle)}
                                onChange={e => updateField('tournamentTitle', e.target.value, true)}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-display font-bold"
                            />
                        </div>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">
                                {t('web.turnier_intro')} <Languages size={10} className="text-primary"/>
                            </label>
                            <textarea rows={3}
                                value={getLoc(branding.tournamentIntro)}
                                onChange={e => updateField('tournamentIntro', e.target.value, true)}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100"
                            />
                        </div>
                        {/* Die zwei Adressen sind nicht uebersetzt: eine
                            Turnierplanung hat eine Adresse, keine drei. */}
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">
                                {t('web.turnier_embed')}
                            </label>
                            <input type="url" placeholder="https://www.turnierplanung.ch/veranstaltung/embed/000/"
                                value={branding.tournamentEmbedUrl || ''}
                                onChange={e => updateField('tournamentEmbedUrl', e.target.value)}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-mono"
                            />
                            <p className="text-[11px] text-stone-400 mt-1">{t('web.turnier_embed_hinweis')}</p>
                        </div>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 block">
                                {t('web.turnier_detail')}
                            </label>
                            <input type="url" placeholder="https://www.turnierplanung.ch/veranstaltung/detail/000"
                                value={branding.tournamentDetailUrl || ''}
                                onChange={e => updateField('tournamentDetailUrl', e.target.value)}
                                className="w-full p-3 bg-stone-50 rounded-xl text-sm border border-stone-100 font-mono"
                            />
                            <p className="text-[11px] text-stone-400 mt-1">{t('web.turnier_detail_hinweis')}</p>
                        </div>
                        {/* Ohne Spielplan steht die Seite trotzdem -- mit
                            einem ehrlichen Hinweis statt mit einem leeren
                            Rahmen. Das muss hier dastehen, sonst sucht
                            jemand den Fehler auf der Website. */}
                        {!branding.tournamentEmbedUrl && (
                            <p className="text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-xl p-3 leading-relaxed">
                                {t('web.turnier_ohne_plan')}
                            </p>
                        )}
                    </div>
                </BuilderSection>
            )}

            {activeTab === 'LIVE' && (
                <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="selectors" title={t('web.live_features')} icon={<Zap size={18}/>}>
                    <div className="space-y-4">
                        {branding.liveSelectors.map((s, idx) => (
                            <div key={idx} className="p-4 bg-stone-50 rounded-2xl border border-stone-200 flex gap-4">
                                {/* Image Box */}
                                <div className="relative group w-16 h-16 shrink-0">
                                     <div className="w-full h-full bg-white rounded-xl border border-stone-200 overflow-hidden flex items-center justify-center">
                                         {s.image ? <img src={s.image} className="w-full h-full object-cover" onError={onImageError}/> : <ImageIcon size={16} className="text-stone-300"/>}
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
                                            title={t('web.upload')}
                                         >
                                            <Upload size={10}/>
                                         </button>
                                         <button 
                                            onClick={() => {
                                                showPrompt({
                                                    title: t('web.image_url'),
                                                    message: t('web.image_url_prompt'),
                                                    placeholder: "https://..."
                                                }).then(url => {
                                                    if(url) updateArrayField('liveSelectors', idx, 'image', url);
                                                })
                                            }}
                                            className="p-1 bg-white/20 hover:bg-white text-white hover:text-stone-900 rounded-full"
                                            title={t('web.paste_url')}
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
                <BuilderSection offen={expandedSection} setOffen={setExpandedSection} id="legal" title={t('web.privacy')} icon={<ShieldAlert size={18}/>}>
                    <div className="space-y-4">
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.gdpr_text')} <Languages size={10} className="text-primary"/></label>
                            <textarea 
                                value={getLoc(branding.gdprText)} 
                                onChange={e => updateField('gdprText', e.target.value, true)} 
                                className="w-full p-4 bg-stone-50 rounded-2xl text-xs font-mono border border-stone-100 outline-none h-48" 
                                placeholder={`GDPR Content for ${editLang}...`}
                            />
                        </div>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase mb-1 flex items-center gap-1">{t('web.privacy_policy')} <Languages size={10} className="text-primary"/></label>
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

          {/* Dieser Knopf speichert das Branding -- nicht die eigenen
              Seiten. Die haben ihr eigenes Speichern, und ein grosser
              roter Knopf darunter, der etwas anderes tut, waere eine
              Falle: wer ihn drueckt, glaubt seine Seite gesichert zu
              haben. */}
          {activeTab !== 'SEITEN' && activeTab !== 'NAVIGATION' && (
          <div className="p-6 border-t border-stone-100 bg-stone-50 shrink-0">
              <button 
                onClick={handleSaveBranding}
                disabled={isSaving || isUploading}
                className={`w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-3 transition-all ${isSaved ? 'bg-green-500 text-white' : 'bg-primary text-white shadow-xl shadow-rose-200 hover:scale-[1.02]'}`}
              >
                {isSaving || isUploading ? <Loader2 className="animate-spin" /> : isSaved ? <Check /> : <Save />} 
                {isUploading ? t('web.uploading') : t('web.publish')}
              </button>
          </div>
          )}
      </div>

      {/* Preview Panel */}
      <div className={`lg:col-span-7 transition-all duration-500 ${
        activeTab === 'SEITEN' || activeTab === 'NAVIGATION' ? 'hidden' : 'hidden lg:block'} ${showPreview ? 'opacity-100 scale-100' : 'opacity-0 scale-95 pointer-events-none'}`}>
        {/* Im Design-Reiter die ECHTE Seite, nicht die Nachbildung.
            Die Nachbildung darunter kennt nur die klassische Vorlage -- wer
            Magazin oder Buehne waehlte, sah rechts weiter Klassisch und
            glaubte, die Wahl habe nicht gewirkt. Sie fuer sechs Vorlagen
            nachzubauen hiesse, jede Vorlage zweimal zu pflegen; die zweite
            laeuft dann irgendwann der ersten davon.
            Nachteil, bewusst in Kauf genommen: der Rahmen zeigt den
            gespeicherten Stand, keine ungesicherten Textaenderungen. Im
            Design-Reiter aendert man aber keine Texte. */}
        {activeTab === 'DESIGN' || activeTab === 'ABOUT' || activeTab === 'CHRONIK' || activeTab === 'KONTAKT' ? (
          <div className="sticky top-12 h-full flex flex-col">
            <div className="flex items-center justify-between mb-4 shrink-0 px-1">
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                {t('web.echte_seite')}
              </p>
              <button type="button" onClick={() => setVorschauSchluessel(k => k + 1)}
                className="text-[10px] font-bold uppercase tracking-widest text-stone-400 hover:text-stone-700">
                {t('web.neu_laden')}
              </button>
            </div>
            <div className="bg-stone-900 rounded-[2.5rem] p-3 shadow-2xl border-[10px] border-stone-800 flex-1 max-h-[800px]">
              <iframe key={vorschauSchluessel} src={activeTab === 'ABOUT' ? '/#/about' : activeTab === 'CHRONIK' ? '/#/chronik' : activeTab === 'KONTAKT' ? '/#/kontakt' : '/'} title={t('web.echte_seite')}
                      className="w-full h-full rounded-[1.6rem] bg-white border-0" />
            </div>
            <p className="text-[11px] text-stone-400 mt-3 text-center">{t('web.vorschau_hinweis')}</p>
          </div>
        ) : (
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
                     {branding.logoUrl ? <img src={branding.logoUrl} style={{ height: branding.logoHeight || '2.5rem' }} className="w-auto object-contain"  onError={onImageError}/> : <div className="bg-primary p-1 rounded-lg text-white"><Heart size={12} fill="white" /></div>}
                     <span className="font-display font-bold italic text-sm text-stone-800">{previewName}</span>
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
                          {branding.heroImages[0] && <img src={branding.heroImages[0]} className="w-full h-full object-cover"  onError={onImageError}/>}
                          <div className="absolute inset-0 bg-gradient-to-t from-stone-900/40 to-transparent" />
                      </div>
                  </div>

                  {/* HyperText Preview */}
                  {getLoc(branding.whyJoinText) && (
                      <div className="mb-16 text-center relative">
                          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-rose-100/30 blur-3xl rounded-full -z-10" />
                          <p className="text-[10px] font-bold text-stone-400 uppercase tracking-[0.2em] mb-4">{t('web.mission_preview')}</p>
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
                  <h4 className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-6 text-center">{t('web.section_about')}</h4>
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
                      <h4 className="font-display italic text-xl mb-4">{previewName}</h4>
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
        )}
      </div>
    </div>
  );
};

export default AdminWebsite;
