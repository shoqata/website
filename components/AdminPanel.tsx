
import React, { useState, useEffect, useMemo, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Users, Trash2, Search, Filter, Zap, Loader2, Database, RefreshCw, Globe, Plus, Layout, 
  BarChart3, Mail, X, MapPin, Save, Calendar, Sparkles, Clock, ChevronRight, Bell, 
  Phone, User as UserIcon, Tag, AlertCircle, Download, ListFilter, CheckCircle2, 
  Newspaper, AlignLeft, Link as LinkIcon, ImageIcon, MoreHorizontal, 
  CreditCard, ArrowLeft, Settings, LayoutGrid, LayoutList, Kanban, Upload, Map, 
  Crown, BookOpen, Shield, Activity, DollarSign, FileText, Eye, Home, KeyRound, 
  PieChart as LucidePieChart, Lock, Unlock, CalendarDays, Sliders, CheckSquare, Square, MousePointer2, 
  FileInput, Briefcase, Megaphone, ClipboardList, Copy, Receipt, Menu, LogOut, 
  Command, ChevronLeft, ArrowUp, ArrowDown, ArrowUpDown, TrendingUp, UserPlus, 
  ClipboardCheck, Send, Ban, Coins, LayoutDashboard, MessageSquare, ToggleRight, 
  ToggleLeft, Printer, Files, UserCog, MoreVertical, ExternalLink, Info, MapPinned, Target, UserCheck,
  ShieldAlert, Activity as ActivityIcon, ArrowRight, Wallet, BarChart2, Hash, History, StickyNote, Image as LucideImage,
  UserPlus2, UserMinus, UserCheck2, FileEdit, AlertTriangle
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { UserProfile, UserRole, Neighborhood, SolidarityEvent, NewsArticle, Payment, FiscalYear, BillingGroup, GlobalPaymentSettings, EventRegistration, ContentStatus } from '../types';
import { db, auth, storage } from '../services/firebase';
import { collection, doc, serverTimestamp, query, orderBy, onSnapshot, updateDoc, deleteDoc, where, addDoc, setDoc, getDocs, writeBatch, getDoc, Timestamp } from '@/services/supabase-bridge';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';
import { signOut } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import Papa from 'papaparse';

// Sub-components
import AdminAnalytics from './AdminAnalytics';
import AdminWebsite from './AdminWebsite';
import SocialAI from './SocialAI';
import AdminFinance from './AdminFinance';
import AdminPaymentReports from './AdminPaymentReports';
import AdminData from './AdminData';
import AdminAccounting from './AdminAccounting';
import AdminStatistics from './AdminStatistics';
import AdminSettings from './AdminSettings';
import AdminBoard from './AdminBoard';
import AdminTasks from './AdminTasks';
import AdminCommunication from './AdminCommunication';
import AdminExpenses from './AdminExpenses'; 

import { neighborhoodPlace } from '../lib/neighborhood';
import { onImageError } from '../lib/imageFallback';
import AdminNeighborhoodEditor from './AdminNeighborhoodEditor';
import CountrySelect from './ui/CountrySelect';
import AdminPasswordReset from './AdminPasswordReset';
import { missingFieldKeys, qualityScore, feeStateFor, hasDeliveryConflict } from '../lib/memberQuality';
import { isPlaceholderEmail, hasUsableEmail, emailMissingForDelivery, deliveryNeedsEmail } from '../lib/memberEmail';
type AdminTabId = 'USERS' | 'NEIGHBORHOODS' | 'ANALYTICS' | 'STATISTICS' | 'WEBSITE' | 'SOCIAL_AI' | 'EVENTS' | 'NEWS' | 'FINANCE' | 'EXPENSES' | 'DATA' | 'ACCOUNTING' | 'SETTINGS' | 'BOARD' | 'COMMUNICATION' | 'DATA_QUALITY';

interface NavItem {
    id: AdminTabId;
    label: string;
    icon: React.ReactNode;
    badge?: number;
}

interface NavGroup {
    title: string;
    items: NavItem[];
}

const AdminPanel: React.FC = () => {
  const { t, language, setLanguage } = useTranslation();
  const { showConfirm, showAlert, showPrompt } = useFeedback();
  
  const [activeTab, setActiveTab] = useState<AdminTabId>('ANALYTICS');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  
  // Navigation View State
  const [selectedNeighborhoodId, setSelectedNeighborhoodId] = useState<string | null>(null);

  // Data State
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [events, setEvents] = useState<SolidarityEvent[]>([]);
  const [news, setNews] = useState<NewsArticle[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  // Die Beitragssaetze kommen aus den Einstellungen, damit der Drawer denselben
  // Betrag vorschlaegt wie der Sammellauf in AdminFinance. Vorher stand hier
  // eine fest verdrahtete 100, waehrend konfiguriert 120 gilt -- eine aus dem
  // Mitglieder-Drawer erstellte Rechnung lautete also ueber 20 Franken zu wenig.
  const [feeSettings, setFeeSettings] = useState<any>(null);
  const [registrations, setRegistrations] = useState<EventRegistration[]>([]);
  const [selectedYear, setSelectedYear] = useState<number>(new Date().getFullYear());

  // Management UI States
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  
  // Member Drawer State
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [pwResetFor, setPwResetFor] = useState<any>(null);
  const [isUserDrawerOpen, setIsUserDrawerOpen] = useState(false);
  const [userDrawerTab, setUserDrawerTab] = useState<'GENERAL' | 'ADDRESS' | 'FINANCE' | 'HISTORY' | 'INTERNAL'>('GENERAL');
  
  // Content Modals & Drawers
  const [showEventModal, setShowEventModal] = useState(false);
  const [editingEvent, setEditingEvent] = useState<Partial<SolidarityEvent> | null>(null);
  const [showNewsModal, setShowNewsModal] = useState(false);
  const [editingNews, setEditingNews] = useState<Partial<NewsArticle> | null>(null);
  
  const [managingEventRegistrations, setManagingEventRegistrations] = useState<SolidarityEvent | null>(null);

  const [showNeighborhoodModal, setShowNeighborhoodModal] = useState(false);
  const [editingNeighborhood, setEditingNeighborhood] = useState<Partial<Neighborhood> | null>(null);

  // Data Sync
  useEffect(() => {
    const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile))));
    const unsubNeighborhoods = onSnapshot(query(collection(db, 'neighborhoods'), orderBy('name')), (snap) => setNeighborhoods(snap.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood))));
    const unsubEvents = onSnapshot(query(collection(db, 'events'), orderBy('date', 'desc')), (snap) => setEvents(snap.docs.map(d => ({ id: d.id, ...d.data() } as SolidarityEvent))));
    const unsubNews = onSnapshot(query(collection(db, 'news'), orderBy('timestamp', 'desc')), (snap) => setNews(snap.docs.map(d => ({ id: d.id, ...d.data() } as NewsArticle))));
    const unsubPayments = onSnapshot(collection(db, 'payments'), (snap) => { setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() } as Payment))); setIsLoading(false); });
    const unsubRegs = onSnapshot(collection(db, 'event_registrations'), (snap) => setRegistrations(snap.docs.map(d => ({ id: d.id, ...d.data() } as EventRegistration))));
    getDoc(doc(db, 'public_settings', 'payment'))
      .then(snap => { if (snap.exists()) setFeeSettings(snap.data()); })
      .catch(e => console.error('[AdminPanel] Beitragssätze nicht ladbar:', e));

    return () => { unsubUsers(); unsubNeighborhoods(); unsubEvents(); unsubNews(); unsubPayments(); unsubRegs(); };
  }, []);

  const incompleteUsersCount = useMemo(() => {
      return users.filter(u => u.membershipStatus !== 'INACTIVE'
          && (!u.phone || !u.street || !u.city || !u.zip || !u.birthdate || !u.neighborhoodId)).length;
  }, [users]);

  const filteredUsers = useMemo(() => {
      return users.filter(u => {
          const matchSearch = u.displayName?.toLowerCase().includes(search.toLowerCase()) || u.email?.toLowerCase().includes(search.toLowerCase());
          // Ohne ausdrueckliche Wahl bleiben entfernte Mitglieder ausgeblendet.
          const matchStatus = statusFilter === 'ALL'
              ? u.membershipStatus !== 'INACTIVE'
              : u.membershipStatus === statusFilter;
          const matchRole = roleFilter === 'ALL' || u.role === roleFilter;
          return matchSearch && matchStatus && matchRole;
      });
  }, [users, search, statusFilter, roleFilter]);

  const navGroups: NavGroup[] = [
      {
          title: t('admin.group.management'),
          items: [
              { id: 'ANALYTICS', label: t('admin.tab.analytics'), icon: <LayoutDashboard size={18} /> },
              { id: 'USERS', label: t('admin.tab.users'), icon: <Users size={18} /> },
              { id: 'DATA_QUALITY', label: t('admin.tab.data_quality'), icon: <ShieldAlert size={18} />, badge: incompleteUsersCount },
              { id: 'NEIGHBORHOODS', label: t('admin.tab.neighborhoods'), icon: <MapPin size={18} /> },
              { id: 'BOARD', label: t('admin.tab.board'), icon: <Briefcase size={18} /> },
          ]
      },
      {
          title: t('admin.group.finance'),
          items: [
              { id: 'FINANCE', label: t('admin.tab.finance'), icon: <DollarSign size={18} /> },
              { id: 'EXPENSES', label: t('admin.tab.expenses'), icon: <Receipt size={18} /> },
              { id: 'ACCOUNTING', label: t('admin.tab.accounting'), icon: <BookOpen size={18} /> },
              { id: 'STATISTICS', label: t('admin.tab.statistics'), icon: <BarChart2 size={18} /> },
          ]
      },
      {
          title: t('admin.group.content'),
          items: [
              { id: 'EVENTS', label: t('admin.tab.events'), icon: <Calendar size={18} /> },
              { id: 'NEWS', label: t('admin.tab.news'), icon: <Newspaper size={18} /> },
              { id: 'WEBSITE', label: t('admin.tab.website'), icon: <Globe size={18} /> },
              { id: 'SOCIAL_AI', label: 'Social AI', icon: <Zap size={18} /> },
          ]
      },
      {
          title: t('admin.group.system'),
          items: [
              { id: 'DATA', label: t('admin.tab.data'), icon: <Database size={18} /> },
              { id: 'COMMUNICATION', label: t('admin.tab.communication'), icon: <MessageSquare size={18} /> },
              { id: 'SETTINGS', label: t('admin.tab.settings'), icon: <Settings size={18} /> },
          ]
      }
  ];

  // Derselbe Vorrang wie im Sammellauf: eigener Beitrag, sonst Gruppensatz,
  // sonst Standard. Ein eigener Beitrag von 0 bleibt 0 -- er wird mit ?? statt
  // mit || geprueft, sonst wuerde eine Beitragsbefreiung still ueberschrieben.
  const suggestedFeeFor = (u: UserProfile | null): number => {
      if (u?.customAnnualFee !== undefined && u?.customAnnualFee !== null) return u.customAnnualFee;
      const fees = feeSettings?.fees;
      const groupFee = u?.billingGroup === 'KOSOVO' ? fees?.KOSOVO?.amount
          : u?.billingGroup === 'REDUCED' ? fees?.REDUCED?.amount
          : fees?.STANDARD?.amount;
      return groupFee ?? feeSettings?.annualFeeAmount ?? 120;
  };

  const handleSaveUser = async () => {
      if(!selectedUser) return;
      
      // Ersatzadresse aus dem Import gilt als keine Adresse.
      if (isPlaceholderEmail(selectedUser.email) && selectedUser.email) {
          showAlert({ type: 'error', message: t('admin.members.legacy_email') });
          return;
      }

      // Wer die Rechnung per E-Mail bekommen soll, braucht auch eine.
      if (emailMissingForDelivery(selectedUser)) {
          showAlert({ type: 'error', message: t('email.required_for_delivery') });
          return;
      }

      try {
          const displayName = `${selectedUser.firstName || ''} ${selectedUser.lastName || ''}`.trim() || selectedUser.displayName;

          if (selectedUser.id) {
              await updateDoc(doc(db, 'users', selectedUser.id), { ...selectedUser, displayName } as any);
              showAlert({ type: 'success', message: t('admin.members.updated') });
          } else {
              // Neuanlage: der Drawer startet mit id: '', die Datenbank vergibt die id.
              const { id: _unused, ...newUser } = selectedUser as any;
              const created = await addDoc(collection(db, 'users'), { ...newUser, displayName });
              setSelectedUser({ ...selectedUser, id: created.id, displayName } as any);
              showAlert({ type: 'success', message: t('admin.members.created') });
          }
          setIsUserDrawerOpen(false);
      } catch (e: any) {
          // Den echten Grund zeigen statt ihn zu verschlucken -- eine Meldung
          // ohne Ursache kostet bei jedem Fehler eine Testrunde.
          console.error('[AdminPanel] Mitglied speichern fehlgeschlagen:', e);
          showAlert({ type: 'error', message: t('admin.members.save_failed', { reason: e?.message || e?.code || '?' }) });
      }
  };

  // Mitglieder werden nie geloescht, sondern auf INACTIVE gesetzt: an ihnen
  // haengen Zahlungen, Journalbuchungen und Vorstandsmandate. Entfernte
  // Mitglieder verschwinden aus der Liste und aus der oeffentlichen Ansicht,
  // bleiben aber ueber den Statusfilter erreichbar und wiederherstellbar.
  const handleToggleMembership = async () => {
      if (!selectedUser?.id) return;
      const deactivate = selectedUser.membershipStatus !== 'INACTIVE';

      if (deactivate) {
          const ok = await showConfirm({
              title: t('admin.members.remove_title'),
              message: t('admin.members.remove_text', { name: selectedUser.displayName || t('field.member') }),
              confirmText: t('admin.members.remove'),
              type: 'danger'
          });
          if (!ok) return;
      }

      const nextStatus: UserProfile['membershipStatus'] = deactivate ? 'INACTIVE' : 'ACTIVE';
      try {
          await updateDoc(doc(db, 'users', selectedUser.id), { membershipStatus: nextStatus });
          setSelectedUser({ ...selectedUser, membershipStatus: nextStatus });
          setIsUserDrawerOpen(false);
          showAlert({ type: 'success', message: deactivate ? t('admin.members.removed') : t('admin.members.reactivated') });
      } catch (e: any) {
          console.error('[AdminPanel] Statuswechsel fehlgeschlagen:', e);
          showAlert({ type: 'error', message: `Dështoi: ${e?.message || e?.code || ''}` });
      }
  };

  // --- CONTENT ACTIONS ---
  const handleSaveEvent = async () => {
    if (!editingEvent?.title) return;
    try {
        if (editingEvent.id) {
            await updateDoc(doc(db, 'events', editingEvent.id), editingEvent as any);
        } else {
            await addDoc(collection(db, 'events'), { ...editingEvent, createdAt: serverTimestamp() });
        }
        setShowEventModal(false);
        showAlert({ type: 'success', message: t('admin.events.saved') });
    } catch (e: any) {
        console.error('[AdminPanel] Speichern fehlgeschlagen:', e);
        showAlert({ type: 'error', message: `Dështoi ruajtja: ${e?.message || e?.code || ''}` });
    }
  };

  const handleSaveNews = async () => {
    if (!editingNews?.title) return;
    try {
        const data = {
            ...editingNews,
            publishAt: editingNews.publishAt ? (typeof editingNews.publishAt === 'string' ? Timestamp.fromDate(new Date(editingNews.publishAt)) : editingNews.publishAt) : null
        };

        if (editingNews.id) {
            await updateDoc(doc(db, 'news', editingNews.id), data as any);
        } else {
            await addDoc(collection(db, 'news'), { ...data, timestamp: serverTimestamp() });
        }
        setShowNewsModal(false);
        showAlert({ type: 'success', message: t('admin.news.saved') });
    } catch (e: any) {
        console.error('[AdminPanel] Speichern fehlgeschlagen:', e);
        showAlert({ type: 'error', message: `Dështoi ruajtja: ${e?.message || e?.code || ''}` });
    }
  };

  const handleDeleteContent = async (collectionName: string, id: string) => {
    if (await showConfirm({ title: t('admin.confirm_delete'), message: t('admin.delete_permanent'), type: 'danger' })) {
        await deleteDoc(doc(db, collectionName, id));
        showAlert({ type: 'success', message: t('admin.deleted') });
    }
  };

  const getEventTimeBadge = (dateStr: string) => {
      const eventDate = new Date(dateStr);
      const today = new Date();
      const diffDays = Math.ceil((eventDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      
      if (diffDays < 0) return { label: t('admin.events.past'), color: 'bg-stone-100 text-stone-500' };
      if (diffDays <= 30) return { label: t('admin.events.current'), color: 'bg-emerald-100 text-emerald-700' };
      return { label: t('admin.events.upcoming'), color: 'bg-blue-100 text-blue-700' };
  };

  // --- REGISTRATION MANAGEMENT ---
  const handleUpdateRegistrationStatus = async (regId: string, status: 'APPROVED' | 'REJECTED' | 'PENDING') => {
      try {
          await updateDoc(doc(db, 'event_registrations', regId), { status });
          showAlert({ type: 'success', message: `Statusi u përditësua në ${status}.` });
      } catch (e: any) {
          console.error('[AdminPanel] Aktualisierung fehlgeschlagen:', e);
          showAlert({ type: 'error', message: `Dështoi përditësimi: ${e?.message || e?.code || ''}` });
      }
  };

  const exportRegistrationsCSV = (event: SolidarityEvent) => {
      const eventRegs = registrations.filter(r => r.eventId === event.id);
      if (eventRegs.length === 0) {
          showAlert({ type: 'info', message: t('admin.events.nothing_to_export') });
          return;
      }
      const csvData = eventRegs.map(r => ({
          Emri: r.name,
          Email: r.email,
          Telefoni: r.phone || '',
          Lloji: r.type,
          Data: new Date(r.registeredAt).toLocaleDateString(),
          Statusi: r.status
      }));
      const csv = Papa.unparse(csvData);
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.setAttribute('download', `Gästeliste_${event.title.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
  };

  if (isLoading) return <div className="min-h-screen flex items-center justify-center bg-[#faf9f6]"><Loader2 className="animate-spin text-primary" size={40} /></div>;

  return (
    <div className="flex min-h-screen bg-[#faf9f6]">
      {/* Sidebar */}
      <aside className={`fixed lg:sticky top-0 left-0 h-screen w-72 bg-white border-r border-stone-200 z-50 transition-transform duration-300 transform ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'} flex flex-col`}>
          <div className="p-6 border-b border-stone-100 flex items-center justify-between">
              <Link to="/dashboard" className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-rose-200"><Shield size={20} /></div>
                  <div><h1 className="font-display font-bold text-xl italic text-stone-900 leading-none">{t('admin.hub.title')}</h1><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">{t('admin.brand.label')}</p></div>
              </Link>
              <button onClick={() => setIsSidebarOpen(false)} className="lg:hidden p-2 text-stone-400"><X size={20}/></button>
          </div>
          <div className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-6">
              {navGroups.map((group, idx) => (
                  <div key={idx}>
                      <h3 className="px-4 text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{group.title}</h3>
                      <div className="space-y-1">
                          {group.items.map(item => (
                              <button key={item.id} onClick={() => { setActiveTab(item.id); setSelectedNeighborhoodId(null); setIsSidebarOpen(false); }} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-bold transition-all ${activeTab === item.id ? 'bg-primary/5 text-primary border-r-4 border-primary shadow-sm' : 'text-stone-500 hover:bg-stone-50 hover:text-stone-900'}`}>
                                  {item.icon}<span className="flex-1 text-left">{item.label}</span>
                                  {item.badge !== undefined && <span className={`text-[9px] px-1.5 py-0.5 rounded-full ${item.id === 'DATA_QUALITY' ? 'bg-amber-500 text-white' : 'bg-red-500 text-white'}`}>{item.badge}</span>}
                              </button>
                          ))}
                      </div>
                  </div>
              ))}
          </div>
          <div className="p-4 border-t border-stone-100"><button onClick={() => signOut(auth)} className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-stone-500 hover:text-red-500 transition-colors font-bold text-sm"><LogOut size={18} /> {t('nav.logout')}</button></div>
      </aside>

      <main className="flex-1 h-screen overflow-y-auto relative flex flex-col">
          <header className="sticky top-0 z-30 bg-white/80 backdrop-blur-md border-b border-stone-100 px-6 py-4 flex justify-between items-center">
              <div className="flex items-center gap-4">
                  <button onClick={() => setIsSidebarOpen(true)} className="lg:hidden p-2 text-stone-500 bg-stone-100 rounded-lg"><Menu size={20}/></button>
                  <h2 className="text-2xl font-display font-bold italic text-stone-900">
                    {selectedNeighborhoodId ? 'Pamja 360° e Lagjes' : navGroups.flatMap(g => g.items).find(i => i.id === activeTab)?.label}
                  </h2>
              </div>
              <div className="flex items-center gap-3">
                  <div className="bg-stone-100 px-3 py-1.5 rounded-xl flex items-center gap-2"><CalendarDays size={14} className="text-stone-400"/><select value={selectedYear} onChange={(e) => setSelectedYear(parseInt(e.target.value))} className="bg-transparent text-xs font-bold text-stone-600 outline-none">{Array.from({length: 5}, (_, i) => new Date().getFullYear() - i).map(y => <option key={y} value={y}>{y}</option>)}</select></div>
                  <div className="flex gap-1 bg-stone-100 p-1 rounded-xl">{['sq', 'de', 'en'].map(l => (<button key={l} onClick={() => setLanguage(l as any)} className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${language === l ? 'bg-white shadow-sm text-primary' : 'text-stone-400'}`}>{l}</button>))}</div>
              </div>
          </header>

          <div className="p-6 md:p-10 flex-1">
              <AnimatePresence mode="wait">
                  {activeTab === 'NEIGHBORHOODS' && selectedNeighborhoodId ? (
                      <AdminNeighborhoodDetail 
                        neighborhoodId={selectedNeighborhoodId} 
                        neighborhoods={neighborhoods} 
                        users={users} 
                        payments={payments}
                        selectedYear={selectedYear}
                        onBack={() => setSelectedNeighborhoodId(null)}
                        onEdit={(n: any) => { setEditingNeighborhood(n); setShowNeighborhoodModal(true); }}
                        onEditUser={(u: UserProfile) => { setSelectedUser(u); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }}
                      />
                  ) : (
                      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                        {activeTab === 'ANALYTICS' && <AdminAnalytics payments={payments} users={users} neighborhoods={neighborhoods} selectedYear={selectedYear} />}
                        
                        {activeTab === 'DATA_QUALITY' && (
                            <AdminDataQuality 
                                users={users} 
                                neighborhoods={neighborhoods} 
                                onEditUser={(u: UserProfile) => { setSelectedUser(u); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} 
                            />
                        )}

                        {activeTab === 'USERS' && (
                            <div className="space-y-6">
                                <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-white p-4 rounded-3xl border border-stone-100 shadow-sm">
                                    <div className="flex gap-2 w-full md:w-auto">
                                        <div className="relative flex-1 md:w-64"><Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={16}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('admin.members.search')} className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/30" /></div>
                                        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="p-2.5 bg-stone-50 border border-stone-100 rounded-xl text-xs font-bold outline-none"><option value="ALL">{t('status.all')}</option><option value="ACTIVE">{t('status.active')}</option><option value="PENDING">{t('status.pending')}</option><option value="INACTIVE">{t('status.inactive')}</option></select>
                                    </div>
                                    <button onClick={() => { setSelectedUser({ id: '', email: '', role: UserRole.MEMBER, membershipStatus: 'PENDING', joinedAt: new Date().toISOString(), tenantId: 'koretini' }); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><UserPlus size={16}/> {t('admin.members.add_new')}</button>
                                </div>
                                <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                                    <table className="w-full text-left">
                                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                            <tr><th className="px-6 py-4">{t('field.member')}</th><th className="px-6 py-4">{t('admin.members.neighborhood')}</th><th className="px-6 py-4">{t('field.status')}</th><th className="px-6 py-4 text-right">{t('common.actions')}</th></tr>
                                        </thead>
                                        <tbody className="divide-y divide-stone-50">
                                            {filteredUsers.map(u => {
                                                const isLegacyEmail = isPlaceholderEmail(u.email);
                                                return (
                                                <tr key={u.id} onClick={() => { setSelectedUser(u); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} className="hover:bg-stone-50/50 transition-colors group cursor-pointer">
                                                    <td className="px-6 py-4">
                                                        <div className="flex items-center gap-3">
                                                            <div className="w-10 h-10 rounded-full bg-stone-100 overflow-hidden flex items-center justify-center font-bold text-stone-400">
                                                                {u.photoFileName ? <img src={u.photoFileName} className="w-full h-full object-cover" onError={onImageError}/> : u.displayName?.charAt(0)}
                                                            </div>
                                                            <div>
                                                                <p className="font-bold text-stone-900 flex items-center gap-2">
                                                                    {u.displayName}
                                                                    {isLegacyEmail && <span className="px-1.5 py-0.5 bg-red-100 text-red-600 rounded text-[9px] uppercase tracking-wider font-bold flex items-center gap-1" title={t('admin.members.invalid_email_title')}><AlertTriangle size={10}/> {t('admin.members.invalid_email')}</span>}
                                                                </p>
                                                                <p className={`text-[10px] uppercase ${isLegacyEmail ? 'text-red-400 font-bold' : 'text-stone-400'}`}>{u.email}</p>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    <td className="px-6 py-4"><p className="text-sm text-stone-600">{neighborhoods.find(n => n.id === u.neighborhoodId)?.name || '-'}</p></td>
                                                    <td className="px-6 py-4"><span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${u.membershipStatus === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>{u.membershipStatus}</span></td>
                                                    <td className="px-6 py-4 text-right"><div className="flex justify-end gap-1"><button onClick={(e) => { e.stopPropagation(); setSelectedUser(u); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} className="p-2 text-stone-400 hover:text-stone-900 bg-white border border-stone-200 rounded-lg shadow-sm"><Eye size={14}/></button></div></td>
                                                </tr>
                                            )})}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}

                        {activeTab === 'NEIGHBORHOODS' && (
                          <div className="space-y-6">
                            <div className="flex justify-between items-center bg-white p-4 rounded-3xl border border-stone-100 shadow-sm">
                                <h3 className="font-bold text-stone-900 flex items-center gap-2 px-2"><MapPin size={18} className="text-primary"/> {t('admin.tab.neighborhoods')}</h3>
                                <button onClick={() => { setEditingNeighborhood({ name: '', status: 'ACTIVE' }); setShowNeighborhoodModal(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16}/> {t('admin.nb.new')}</button>
                            </div>
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                {neighborhoods.map(n => (
                                    <div key={n.id} onClick={() => setSelectedNeighborhoodId(n.id)} className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm group hover:shadow-xl transition-all relative overflow-hidden cursor-pointer">
                                        <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity">
                                          <button onClick={(e) => { e.stopPropagation(); setEditingNeighborhood(n); setShowNeighborhoodModal(true); }} className="p-2 bg-stone-50 text-stone-400 hover:text-stone-900 rounded-xl border border-stone-100 transition-colors"><Settings size={16}/></button>
                                        </div>
                                        <div className="flex justify-between items-start mb-4"><div className="p-3 bg-stone-50 rounded-2xl text-primary group-hover:bg-primary group-hover:text-white transition-colors shadow-inner"><MapPin size={24}/></div></div>
                                        <h4 className="font-bold text-lg text-stone-900 mb-1">{n.name}</h4>
                                        <p className="text-xs text-stone-400 uppercase tracking-widest mb-6">{neighborhoodPlace(n)}</p>
                                        <div className="space-y-3">
                                            <div className="flex justify-between items-center p-3 bg-stone-50 rounded-2xl"><span className="text-xs font-bold text-stone-400 uppercase">{t('admin.members.count')}</span><span className="font-bold text-stone-900">{users.filter(u => u.neighborhoodId === n.id).length}</span></div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                          </div>
                        )}

                        {activeTab === 'FINANCE' && (
                            <div className="space-y-8">
                                {/* Meldungen aus den Nachbarschaften zuerst: sie warten
                                    auf eine Entscheidung, alles andere nicht. */}
                                <AdminPaymentReports />
                                <AdminFinance viewMode="GRID" selectedYear={selectedYear} />
                            </div>
                        )}
                        {activeTab === 'EXPENSES' && <AdminExpenses />}
                        {activeTab === 'ACCOUNTING' && <AdminAccounting selectedYear={selectedYear} />}
                        {activeTab === 'STATISTICS' && <AdminStatistics users={users} payments={payments} neighborhoods={neighborhoods} selectedYear={selectedYear} />}
                        {activeTab === 'WEBSITE' && <AdminWebsite />}
                        {activeTab === 'SOCIAL_AI' && <SocialAI />}
                        {activeTab === 'DATA' && <AdminData />}
                        {activeTab === 'SETTINGS' && <AdminSettings />}
                        {activeTab === 'BOARD' && <AdminBoard users={users} />}
                        {activeTab === 'COMMUNICATION' && <AdminCommunication />}
                        
                        {activeTab === 'EVENTS' && (
                            <div className="space-y-6">
                                <div className="flex justify-between items-center bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                                    <h3 className="font-bold text-stone-900 text-xl flex items-center gap-2"><Calendar size={20} className="text-primary"/> {t('admin.events.title')}</h3>
                                    <button onClick={() => { setEditingEvent({ title: '', description: '', date: new Date().toISOString().split('T')[0], time: '19:00', location: 'Koretin', category: 'SOCIAL', status: 'DRAFT', isRegistrable: true }); setShowEventModal(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16}/> {t('admin.events.add')}</button>
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                    {events.map(event => {
                                        const timeBadge = getEventTimeBadge(event.date);
                                        return (
                                            <div key={event.id} className={`bg-white rounded-[2rem] overflow-hidden border transition-all relative group hover:shadow-xl ${event.status === 'ARCHIVED' ? 'opacity-50 border-stone-200' : 'border-stone-100 shadow-sm'}`}>
                                                <div className="aspect-video relative overflow-hidden">
                                                    <img src={event.image || 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=800&q=80'} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"  onError={onImageError}/>
                                                    <div className="absolute top-4 left-4 flex flex-col gap-2">
                                                        <span className={`text-[9px] font-bold px-2 py-1 rounded-lg uppercase tracking-widest shadow-lg ${event.status === 'PUBLISHED' ? 'bg-emerald-500 text-white' : event.status === 'DRAFT' ? 'bg-amber-500 text-white' : 'bg-stone-500 text-white'}`}>
                                                            {event.status}
                                                        </span>
                                                        <span className={`text-[9px] font-bold px-2 py-1 rounded-lg uppercase tracking-widest shadow-lg ${timeBadge.color}`}>
                                                            {timeBadge.label}
                                                        </span>
                                                    </div>
                                                    <div className="absolute top-4 right-4 flex gap-2">
                                                        <button onClick={() => { setEditingEvent(event); setShowEventModal(true); }} className="p-2 bg-white/90 backdrop-blur-md rounded-lg text-stone-600 hover:text-primary transition-colors"><FileEdit size={16}/></button>
                                                        <button onClick={() => handleDeleteContent('events', event.id)} className="p-2 bg-white/90 backdrop-blur-md rounded-lg text-stone-400 hover:text-red-500 transition-colors"><Trash2 size={16}/></button>
                                                    </div>
                                                </div>
                                                <div className="p-6">
                                                    <div className="flex justify-between items-start mb-2"><span className="text-[10px] font-bold text-primary uppercase tracking-widest">{event.category}</span><span className="text-xs text-stone-400 font-bold">{new Date(event.date).toLocaleDateString()}</span></div>
                                                    <h4 className="font-bold text-stone-900 mb-4 line-clamp-1">{event.title}</h4>
                                                    
                                                    <div className="flex gap-2">
                                                        {event.isRegistrable && (
                                                            <button 
                                                                onClick={() => setManagingEventRegistrations(event)}
                                                                className="flex-1 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-black transition-colors"
                                                            >
                                                                <Users size={14}/> Regjistrimet ({registrations.filter(r => r.eventId === event.id).length})
                                                            </button>
                                                        )}
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                    {events.length === 0 && <div className="col-span-full py-20 text-center text-stone-400 italic">{t('admin.events.none')}</div>}
                                </div>
                            </div>
                        )}

                        {activeTab === 'NEWS' && (
                            <div className="space-y-6">
                                <div className="flex justify-between items-center bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                                    <h3 className="font-bold text-stone-900 text-xl flex items-center gap-2"><Newspaper size={20} className="text-blue-600"/> {t('admin.news.title')}</h3>
                                    <button onClick={() => { setEditingNews({ title: '', category: 'DIASPORA', subcategory: 'Updates', location: 'Zürich', content: [''], image: '', status: 'DRAFT' }); setShowNewsModal(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16}/> {t('admin.news.add')}</button>
                                </div>
                                <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                                    <table className="w-full text-left">
                                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                            <tr><th className="px-6 py-4">{t('admin.tab.news')}</th><th className="px-6 py-4">{t('field.status')}</th><th className="px-6 py-4">{t('field.category')}</th><th className="px-6 py-4">{t('admin.news.date_scheduled')}</th><th className="px-6 py-4 text-right">{t('common.actions')}</th></tr>
                                        </thead>
                                        <tbody className="divide-y divide-stone-50">
                                            {news.map(item => (
                                                <tr key={item.id} className={`hover:bg-stone-50/50 transition-colors group ${item.status === 'ARCHIVED' ? 'opacity-50' : ''}`}>
                                                    <td className="px-6 py-4">
                                                        <div className="flex items-center gap-3">
                                                            <div className="w-12 h-12 rounded-xl bg-stone-100 overflow-hidden shrink-0 border border-stone-200">
                                                                {item.image ? <img src={item.image} className="w-full h-full object-cover"  onError={onImageError}/> : <LucideImage className="m-auto text-stone-300" size={20}/>}
                                                            </div>
                                                            <div><p className="font-bold text-stone-900 line-clamp-1">{item.title}</p><p className="text-[10px] text-stone-400 uppercase">{item.location}</p></div>
                                                        </div>
                                                    </td>
                                                    <td className="px-6 py-4">
                                                        <span className={`text-[9px] font-bold px-2 py-1 rounded uppercase tracking-widest ${item.status === 'PUBLISHED' ? 'bg-emerald-100 text-emerald-700' : item.status === 'DRAFT' ? 'bg-amber-100 text-amber-700' : 'bg-stone-100 text-stone-500'}`}>
                                                            {item.status}
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-4"><span className="text-xs font-bold text-stone-500 bg-stone-100 px-2 py-1 rounded uppercase">{item.category}</span></td>
                                                    <td className="px-6 py-4">
                                                        <div className="flex flex-col">
                                                            <p className="text-xs text-stone-900 font-medium">{item.timestamp?.toDate().toLocaleDateString()}</p>
                                                            {item.publishAt && (
                                                                <p className="text-[10px] text-primary font-bold flex items-center gap-1"><Clock size={10}/> {item.publishAt.toDate().toLocaleString()}</p>
                                                            )}
                                                        </div>
                                                    </td>
                                                    <td className="px-6 py-4 text-right">
                                                        <div className="flex justify-end gap-2">
                                                            <button onClick={() => { setEditingNews(item); setShowNewsModal(true); }} className="p-2 text-stone-400 hover:text-stone-900 bg-white border border-stone-200 rounded-lg shadow-sm"><FileEdit size={14}/></button>
                                                            <button onClick={() => handleDeleteContent('news', item.id)} className="p-2 text-stone-400 hover:text-red-500 bg-white border border-stone-200 rounded-lg shadow-sm"><Trash2 size={14}/></button>
                                                        </div>
                                                    </td>
                                                </tr>
                                            ))}
                                            {news.length === 0 && <tr><td colSpan={5} className="py-10 text-center text-stone-400 italic">{t('admin.news.none')}</td></tr>}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}
                      </motion.div>
                  )}
              </AnimatePresence>
          </div>
      </main>

      {/* DIALOG: NACHBARSCHAFT BEARBEITEN */}
      <AnimatePresence>
        {showNeighborhoodModal && editingNeighborhood && (
          <AdminNeighborhoodEditor
            neighborhood={editingNeighborhood}
            users={users}
            memberCount={users.filter(u => u.neighborhoodId === editingNeighborhood.id).length}
            onClose={() => { setShowNeighborhoodModal(false); setEditingNeighborhood(null); }}
          />
        )}
      </AnimatePresence>

      {/* MODAL: EVENT EDITOR */}
      <AnimatePresence>
        {showEventModal && editingEvent && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white w-full max-w-xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[90vh]">
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2"><Calendar className="text-primary"/> {t('admin.events.details')}</h3>
                        <button onClick={() => setShowEventModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                    </div>
                    <div className="p-8 space-y-4 overflow-y-auto custom-scrollbar">
                        <div className="grid grid-cols-2 gap-4 mb-4">
                            <div className="flex items-center justify-between p-4 bg-stone-50 rounded-2xl border border-stone-200">
                                <div>
                                    <p className="text-[10px] font-bold text-stone-400 uppercase">{t('admin.events.registration')}</p>
                                    <p className="text-xs font-bold text-stone-800">{editingEvent.isRegistrable ? t('status.active') : t('status.inactive')}</p>
                                </div>
                                <button 
                                    onClick={() => setEditingEvent({...editingEvent, isRegistrable: !editingEvent.isRegistrable})}
                                    className={`w-10 h-5 rounded-full relative transition-colors ${editingEvent.isRegistrable ? 'bg-primary' : 'bg-stone-300'}`}
                                >
                                    <motion.div 
                                        animate={{ x: editingEvent.isRegistrable ? 20 : 4 }}
                                        className="absolute top-1 w-3 h-3 bg-white rounded-full shadow-sm"
                                    />
                                </button>
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.publish.status')}</label>
                                <select 
                                    value={editingEvent.status} 
                                    onChange={e => setEditingEvent({...editingEvent, status: e.target.value as ContentStatus})} 
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                >
                                    <option value="DRAFT">{t('admin.publish.draft')}</option>
                                    <option value="PUBLISHED">{t('admin.publish.published')}</option>
                                    <option value="ARCHIVED">{t('admin.publish.archived')}</option>
                                </select>
                            </div>
                        </div>

                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.title')}</label><input value={editingEvent.title} onChange={e => setEditingEvent({...editingEvent, title: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold" /></div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.description')}</label><textarea value={editingEvent.description} onChange={e => setEditingEvent({...editingEvent, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none h-24 text-sm" /></div>
                        <div className="grid grid-cols-2 gap-4">
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.date')}</label><input type="date" value={editingEvent.date} onChange={e => setEditingEvent({...editingEvent, date: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.category')}</label><select value={editingEvent.category} onChange={e => setEditingEvent({...editingEvent, category: e.target.value as any})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"><option value="HEALTH">{t('cat.health')}</option><option value="EDUCATION">{t('cat.education')}</option><option value="CULTURE">{t('cat.culture')}</option><option value="SPORT">{t('cat.sport')}</option><option value="SOCIAL">{t('cat.social')}</option></select></div>
                        </div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.image_url')}</label><input value={editingEvent.image} onChange={e => setEditingEvent({...editingEvent, image: e.target.value})} placeholder="https://..." className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-mono" /></div>
                    </div>
                    <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3"><button onClick={() => setShowEventModal(false)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button><button onClick={handleSaveEvent} className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg">{t('admin.events.save')}</button></div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* DRAWER: REGISTRATION MANAGEMENT */}
      <AnimatePresence>
          {managingEventRegistrations && (
              <div className="fixed inset-0 z-[400] flex justify-end">
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setManagingEventRegistrations(null)} className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" />
                  <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }} className="relative w-full max-w-2xl bg-white shadow-2xl h-screen flex flex-col overflow-hidden">
                      <div className="p-8 bg-stone-900 text-white shrink-0">
                          <button onClick={() => setManagingEventRegistrations(null)} className="absolute top-6 right-6 p-2 text-white/50 hover:text-white transition-colors"><X size={24}/></button>
                          <div className="mb-4">
                              <span className="text-[10px] font-bold text-primary uppercase tracking-widest mb-1 block">{t('admin.events.registrations')}</span>
                              <h2 className="text-3xl font-display font-bold italic truncate">{managingEventRegistrations.title}</h2>
                          </div>
                          <div className="flex gap-4">
                              <div className="flex items-center gap-2 bg-white/10 px-4 py-2 rounded-xl text-xs font-bold">
                                  <Users size={16} className="text-primary"/> {registrations.filter(r => r.eventId === managingEventRegistrations.id).length} Të regjistruar
                              </div>
                              <button 
                                onClick={() => exportRegistrationsCSV(managingEventRegistrations)}
                                className="flex items-center gap-2 bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 px-4 py-2 rounded-xl text-xs font-bold hover:bg-emerald-500/30 transition-colors"
                              >
                                  <Download size={16}/> {t('admin.events.export_csv')}
                              </button>
                          </div>
                      </div>

                      <div className="flex-1 overflow-y-auto p-8 bg-[#faf9f6] custom-scrollbar">
                          <div className="space-y-4">
                              {registrations.filter(r => r.eventId === managingEventRegistrations.id).map(reg => (
                                  <div key={reg.id} className="bg-white p-5 rounded-2xl border border-stone-100 shadow-sm flex items-center justify-between group hover:shadow-md transition-all">
                                      <div className="flex items-center gap-4">
                                          <div className="w-12 h-12 rounded-xl bg-stone-100 flex items-center justify-center font-bold text-stone-400">
                                              {reg.name.charAt(0)}
                                          </div>
                                          <div>
                                              <p className="font-bold text-stone-900">{reg.name}</p>
                                              <div className="flex items-center gap-3 text-xs text-stone-400">
                                                  <span className="flex items-center gap-1"><Mail size={10}/> {reg.email}</span>
                                                  {reg.phone && <span className="flex items-center gap-1"><Phone size={10}/> {reg.phone}</span>}
                                              </div>
                                          </div>
                                      </div>

                                      <div className="flex items-center gap-3">
                                          <div className="text-right mr-4">
                                              <span className={`text-[10px] font-bold px-2 py-1 rounded uppercase tracking-wider ${
                                                  reg.status === 'APPROVED' ? 'bg-emerald-100 text-emerald-700' :
                                                  reg.status === 'REJECTED' ? 'bg-rose-100 text-rose-700' :
                                                  'bg-amber-100 text-amber-700'
                                              }`}>
                                                  {reg.status}
                                              </span>
                                          </div>
                                          
                                          <div className="flex gap-1">
                                              {reg.status !== 'APPROVED' && (
                                                  <button 
                                                    onClick={() => handleUpdateRegistrationStatus(reg.id, 'APPROVED')}
                                                    className="p-2 bg-emerald-50 text-emerald-600 rounded-lg hover:bg-emerald-100 transition-colors"
                                                    title={t('admin.events.approve')}
                                                  >
                                                      <UserCheck size={16}/>
                                                  </button>
                                              )}
                                              {reg.status !== 'REJECTED' && (
                                                  <button 
                                                    onClick={() => handleUpdateRegistrationStatus(reg.id, 'REJECTED')}
                                                    className="p-2 bg-rose-50 text-rose-600 rounded-lg hover:bg-rose-100 transition-colors"
                                                    title={t('admin.events.reject')}
                                                  >
                                                      <UserMinus size={16}/>
                                                  </button>
                                              )}
                                              <button 
                                                onClick={() => handleDeleteContent('event_registrations', reg.id)}
                                                className="p-2 bg-stone-50 text-stone-400 hover:text-red-500 rounded-lg transition-colors"
                                                title={t('common.delete')}
                                              >
                                                  <Trash2 size={16}/>
                                              </button>
                                          </div>
                                      </div>
                                  </div>
                              ))}
                              {registrations.filter(r => r.eventId === managingEventRegistrations.id).length === 0 && (
                                  <div className="text-center py-20 bg-white rounded-3xl border border-dashed border-stone-200">
                                      <Users size={48} className="mx-auto text-stone-200 mb-4"/>
                                      <p className="text-stone-400 italic">{t('admin.events.no_registrations')}</p>
                                  </div>
                              )}
                          </div>
                      </div>
                  </motion.div>
              </div>
          )}
      </AnimatePresence>

      {/* MODAL: NEWS EDITOR */}
      <AnimatePresence>
        {showNewsModal && editingNews && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white w-full max-w-xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[90vh]">
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2"><Newspaper className="text-blue-600"/> {t('admin.news.details')}</h3>
                        <button onClick={() => setShowNewsModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                    </div>
                    <div className="p-8 space-y-4 overflow-y-auto custom-scrollbar">
                        <div className="grid grid-cols-2 gap-4 mb-2">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.status')}</label>
                                <select 
                                    value={editingNews.status} 
                                    onChange={e => setEditingNews({...editingNews, status: e.target.value as ContentStatus})} 
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                >
                                    <option value="DRAFT">{t('admin.publish.draft')}</option>
                                    <option value="PUBLISHED">{t('admin.publish.published')}</option>
                                    <option value="ARCHIVED">{t('admin.publish.archived')}</option>
                                </select>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.news.schedule')}</label>
                                <input 
                                    type="datetime-local"
                                    value={editingNews.publishAt ? (typeof editingNews.publishAt === 'string' ? editingNews.publishAt : editingNews.publishAt.toDate().toISOString().slice(0, 16)) : ''}
                                    onChange={e => setEditingNews({...editingNews, publishAt: e.target.value})}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                />
                            </div>
                        </div>

                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.title')}</label><input value={editingNews.title} onChange={e => setEditingNews({...editingNews, title: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold" /></div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.news.body_first')}</label><textarea value={editingNews.content?.[0] || ''} onChange={e => setEditingNews({...editingNews, content: [e.target.value]})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none h-32 text-sm" /></div>
                        <div className="grid grid-cols-2 gap-4">
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.news.location')}</label><input value={editingNews.location} onChange={e => setEditingNews({...editingNews, location: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.category')}</label><select value={editingNews.category} onChange={e => setEditingNews({...editingNews, category: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"><option value="DIASPORA">{t('cat.diaspora')}</option><option value="LOCAL">{t('cat.local')}</option><option value="PROJECT">{t('cat.project')}</option></select></div>
                        </div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.image_url')}</label><input value={editingNews.image} onChange={e => setEditingNews({...editingNews, image: e.target.value})} placeholder="https://..." className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-mono" /></div>
                    </div>
                    <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3"><button onClick={() => setShowNewsModal(false)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button><button onClick={handleSaveNews} className="flex-[2] py-3 bg-blue-600 text-white rounded-xl font-bold shadow-lg">{t('admin.news.save')}</button></div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* DETAILED USER DRAWER */}
      <AnimatePresence>
          <AdminPasswordReset member={pwResetFor} onClose={() => setPwResetFor(null)} />

          {isUserDrawerOpen && selectedUser && (
              <div className="fixed inset-0 z-[200] flex justify-end">
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setIsUserDrawerOpen(false)} className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" />
                  <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }} className="relative w-full max-w-2xl bg-white shadow-2xl h-screen flex flex-col overflow-hidden">
                      
                      {/* Drawer Header */}
                      <div className="relative pt-12 pb-6 px-10 bg-stone-900 text-white shrink-0">
                          <button onClick={() => setIsUserDrawerOpen(false)} className="absolute top-6 right-6 p-2 hover:bg-white/10 rounded-full text-white/50 hover:text-white transition-colors"><X size={24}/></button>
                          <div className="flex items-center gap-8">
                              <div className="w-28 h-28 rounded-[2rem] bg-white/10 border-2 border-white/20 p-1 flex items-center justify-center text-4xl font-bold shrink-0 overflow-hidden shadow-2xl">
                                  {selectedUser.photoFileName ? <img src={selectedUser.photoFileName} className="w-full h-full object-cover" onError={onImageError}/> : selectedUser.displayName?.charAt(0)}
                              </div>
                              <div className="flex-1 min-w-0">
                                  <h2 className="text-3xl font-display font-bold italic truncate mb-2">{selectedUser.displayName || 'Anëtar i ri'}</h2>
                                  <div className="flex flex-wrap gap-2">
                                      <span className="bg-white/10 px-3 py-1 rounded-lg text-[10px] font-bold uppercase border border-white/10">{selectedUser.role}</span>
                                      <span className={`px-3 py-1 rounded-lg text-[10px] font-bold uppercase ${selectedUser.membershipStatus === 'ACTIVE' ? 'bg-emerald-500/20 text-emerald-300' : 'bg-amber-500/20 text-amber-300'}`}>{selectedUser.membershipStatus}</span>
                                      <span className="bg-white/10 px-3 py-1 rounded-lg text-[10px] font-bold uppercase border border-white/10">{selectedUser.billingGroup || 'STANDARD'}</span>
                                  </div>
                              </div>
                          </div>

                          {/* Inner Tabs */}
                          <div className="flex mt-8 gap-4 border-b border-white/10">
                              {(['GENERAL', 'ADDRESS', 'FINANCE', 'HISTORY', 'INTERNAL'] as const).map(tab => (
                                  <button 
                                    key={tab} 
                                    onClick={() => setUserDrawerTab(tab)}
                                    className={`pb-3 text-[10px] font-bold uppercase tracking-widest transition-colors relative ${userDrawerTab === tab ? 'text-primary' : 'text-stone-400 hover:text-white'}`}
                                  >
                                      {tab === 'GENERAL' ? t('admin.drawer.identity') : tab === 'ADDRESS' ? t('admin.drawer.address') : tab === 'FINANCE' ? t('admin.drawer.finance') : tab === 'HISTORY' ? t('admin.drawer.history') : t('admin.drawer.internal')}
                                      {userDrawerTab === tab && <motion.div layoutId="drawerTab" className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />}
                                  </button>
                              ))}
                          </div>
                      </div>

                      {/* Drawer Body */}
                      <div className="flex-1 overflow-y-auto p-10 space-y-8 bg-[#faf9f6] custom-scrollbar">
                          {userDrawerTab === 'GENERAL' && (
                              <div className="space-y-6">
                                  <div className="grid grid-cols-2 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.salutation')}</label><select value={selectedUser.salutation || ''} onChange={e => setSelectedUser({...selectedUser, salutation: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none"><option value="">{t('common.select')}</option><option value="Z.">{t('salutation.mr')}</option><option value="Znj.">{t('salutation.ms')}</option></select></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.birthdate')}</label><input type="date" value={selectedUser.birthdate || ''} onChange={e => setSelectedUser({...selectedUser, birthdate: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div className="grid grid-cols-2 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.firstName')}</label><input value={selectedUser.firstName || ''} onChange={e => setSelectedUser({...selectedUser, firstName: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.lastName')}</label><input value={selectedUser.lastName || ''} onChange={e => setSelectedUser({...selectedUser, lastName: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div>
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.email')}</label>
                                      {isPlaceholderEmail(selectedUser.email) && (
                                          <div className="mb-2 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2 text-red-700">
                                              <AlertTriangle size={16} className="mt-0.5 shrink-0" />
                                              <div>
                                                  <p className="text-xs font-bold uppercase tracking-wider mb-0.5">
                                                      {selectedUser.email ? t('admin.members.legacy_hint') : t('email.no_address')}
                                                  </p>
                                                  <p className="text-xs">
                                                      {selectedUser.email ? t('email.placeholder_warning') : t('email.required_for_delivery')}
                                                  </p>
                                              </div>
                                          </div>
                                      )}
                                      <input value={selectedUser.email} onChange={e => setSelectedUser({...selectedUser, email: e.target.value})} className={`w-full p-4 bg-white border rounded-xl outline-none ${selectedUser.email?.endsWith('@koretini.legacy') ? 'border-red-300 focus:border-red-500' : 'border-stone-200'}`} />
                                  </div>
                                  <div className="grid grid-cols-2 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.phone_primary')}</label><input value={selectedUser.phone || ''} onChange={e => setSelectedUser({...selectedUser, phone: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.phone_secondary')}</label><input value={selectedUser.phoneSecondary || ''} onChange={e => setSelectedUser({...selectedUser, phoneSecondary: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                              </div>
                          )}

                          {userDrawerTab === 'ADDRESS' && (
                              <div className="space-y-6">
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.street_no')}</label><input value={selectedUser.street || ''} onChange={e => setSelectedUser({...selectedUser, street: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  <div className="grid grid-cols-3 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.zip')}</label><input value={selectedUser.zip || ''} onChange={e => setSelectedUser({...selectedUser, zip: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div className="col-span-2"><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.city')}</label><input value={selectedUser.city || ''} onChange={e => setSelectedUser({...selectedUser, city: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.country')}</label><CountrySelect value={selectedUser.country} onChange={(v) => setSelectedUser({...selectedUser, country: v})} /></div>
                                  <div className="pt-6 border-t border-stone-200">
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-4">{t('admin.members.invoice_delivery')}</label>
                                      {emailMissingForDelivery(selectedUser) && (
                                          <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2 text-amber-800">
                                              <AlertTriangle size={16} className="mt-0.5 shrink-0" />
                                              <div className="flex-1">
                                                  <p className="text-xs leading-relaxed">{t('email.required_for_delivery')}</p>
                                                  <button
                                                      onClick={() => setSelectedUser({ ...selectedUser, invoiceDeliveryMethod: 'POST' })}
                                                      className="mt-2 text-[10px] font-bold uppercase tracking-wider underline hover:text-amber-950"
                                                  >
                                                      {t('email.switch_to_post')}
                                                  </button>
                                              </div>
                                          </div>
                                      )}
                                      <div className="flex gap-4">
                                          {(['EMAIL', 'POST', 'BOTH'] as const).map(method => (
                                              <button key={method} onClick={() => setSelectedUser({...selectedUser, invoiceDeliveryMethod: method})} className={`flex-1 py-4 rounded-xl text-xs font-bold border-2 transition-all ${selectedUser.invoiceDeliveryMethod === method ? 'border-primary bg-primary/5 text-primary' : 'border-stone-200 bg-white text-stone-400'}`}>
                                                  {method}
                                              </button>
                                          ))}
                                      </div>
                                  </div>
                              </div>
                          )}

                          {userDrawerTab === 'FINANCE' && (
                              <div className="space-y-8">
                                  <div className="bg-white p-6 rounded-2xl border border-stone-200 shadow-sm space-y-4">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.billing_group')}</label><select value={selectedUser.billingGroup || 'STANDARD'} onChange={e => setSelectedUser({...selectedUser, billingGroup: e.target.value as any})} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold text-sm"><option value="STANDARD">{t('admin.members.billing.standard')}</option><option value="KOSOVO">{t('admin.members.billing.kosovo')}</option><option value="REDUCED">{t('admin.members.billing.reduced')}</option></select></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.custom_fee')}</label><div className="relative"><input type="number" value={selectedUser.customAnnualFee || ''} onChange={e => setSelectedUser({...selectedUser, customAnnualFee: parseFloat(e.target.value)})} className="w-full pl-4 pr-12 py-4 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold" /><span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">CHF</span></div></div>
                                  </div>
                                  <div className="bg-stone-900 text-white p-6 rounded-2xl shadow-xl flex items-center justify-between">
                                      <div className="flex items-center gap-4">
                                          <div className="p-3 bg-white/10 rounded-xl"><Hash size={20}/></div>
                                          <div><p className="text-[10px] text-stone-400 uppercase font-bold tracking-widest">{t('admin.members.family_id')}</p><p className="font-mono font-bold text-lg">{selectedUser.familyId || 'Pa ID'}</p></div>
                                      </div>
                                      <button onClick={async () => { const id = await showPrompt({ title: t('admin.members.family_id'), message: t('admin.members.family_id_prompt') }); if(id) setSelectedUser({...selectedUser, familyId: id}); }} className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-[10px] font-bold uppercase transition-colors">{t('common.edit')}</button>
                                  </div>

                                  <div className="bg-white p-6 rounded-2xl border border-stone-200 shadow-sm">
                                      <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 flex items-center gap-2"><FileText size={14}/> {t('admin.invoice.new')}</h4>
                                      <div className="space-y-4">
                                          <div>
                                              <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.description')}</label>
                                              <input type="text" id="invoice-desc" defaultValue={`Mitgliederbeitrag ${selectedYear}`} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-bold" />
                                          </div>
                                          <div className="grid grid-cols-2 gap-4">
                                              <div>
                                                  <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('field.amount')}</label>
                                                  <div className="relative">
                                                      <input type="number" id="invoice-amount" defaultValue={suggestedFeeFor(selectedUser)} className="w-full pl-4 pr-12 py-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold text-sm" />
                                                      <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">CHF</span>
                                                  </div>
                                              </div>
                                              <div>
                                                  <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.invoice.due')}</label>
                                                  <input type="date" id="invoice-due" defaultValue={new Date(new Date().setMonth(new Date().getMonth() + 1)).toISOString().split('T')[0]} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-bold" />
                                              </div>
                                          </div>
                                          <button 
                                              onClick={async () => {
                                                  const desc = (document.getElementById('invoice-desc') as HTMLInputElement).value;
                                                  const amount = parseFloat((document.getElementById('invoice-amount') as HTMLInputElement).value);
                                                  const due = (document.getElementById('invoice-due') as HTMLInputElement).value;
                                                  
                                                  if (!desc || Number.isNaN(amount) || !due) {
                                                      showAlert({ type: 'error', message: t('dash.fill_all') });
                                                      return;
                                                  }

                                                  try {
                                                      const method = selectedUser.country === 'Switzerland' ? 'QR_BILL' : 'BANK_TRANSFER';
                                                      const invoiceNumber = `INV-${Date.now().toString().slice(-5)}`;
                                                      
                                                      await addDoc(collection(db, 'payments'), {
                                                          userId: selectedUser.id,
                                                          amount,
                                                          currency: 'CHF',
                                                          description: desc,
                                                          dueDate: due,
                                                          status: 'PENDING',
                                                          method,
                                                          deliveryMethod: 'EMAIL',
                                                          invoiceNumber,
                                                          timestamp: serverTimestamp()
                                                      });
                                                      
                                                      showAlert({ type: 'success', message: t('admin.invoice.created') });
                                                      setUserDrawerTab('HISTORY');
                                                  } catch (e: any) {
                                                      showAlert({ type: 'error', message: t('admin.invoice.failed', { reason: e.message }) });
                                                  }
                                              }}
                                              className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold text-sm hover:bg-stone-800 transition-colors flex items-center justify-center gap-2"
                                          >
                                              <Plus size={16} /> {t('admin.invoice.create')}
                                          </button>
                                      </div>
                                  </div>
                              </div>
                          )}

                          {userDrawerTab === 'HISTORY' && (
                              <div className="space-y-4">
                                  <div className="flex items-center justify-between px-2 mb-2"><h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('admin.members.payment_history')}</h4><span className="text-[10px] font-bold text-stone-400">{payments.filter(p => p.userId === selectedUser.id).length} Einträge</span></div>
                                  {payments.filter(p => p.userId === selectedUser.id).sort((a,b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0)).map(p => (
                                      <div key={p.id} className="bg-white p-4 rounded-xl border border-stone-100 flex justify-between items-center group hover:shadow-md transition-all">
                                          <div className="flex items-center gap-3">
                                              <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${p.status === 'PAID' ? 'bg-emerald-50 text-emerald-600' : 'bg-amber-50 text-amber-600'}`}><FileText size={18}/></div>
                                              <div><p className="font-bold text-sm text-stone-800">{p.description}</p><p className="text-[10px] text-stone-400 uppercase font-mono">{new Date(p.timestamp?.toDate()).toLocaleDateString()}</p></div>
                                          </div>
                                          <div className="text-right">
                                              <p className="font-mono font-bold text-sm">{p.amount.toFixed(2)} {p.currency}</p>
                                              <span className={`text-[9px] font-bold uppercase ${p.status === 'PAID' ? 'text-emerald-500' : 'text-amber-500'}`}>{p.status}</span>
                                          </div>
                                      </div>
                                  ))}
                                  {payments.filter(p => p.userId === selectedUser.id).length === 0 && (
                                      <div className="text-center py-20 bg-white rounded-3xl border border-dashed border-stone-200"><History size={40} className="mx-auto text-stone-200 mb-4"/><p className="text-stone-400 text-sm italic">{t('admin.members.no_payments')}</p></div>
                                  )}
                              </div>
                          )}

                          {userDrawerTab === 'INTERNAL' && (
                              <div className="space-y-6">
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.neighborhood')}</label><select value={selectedUser.neighborhoodId || ''} onChange={e => setSelectedUser({...selectedUser, neighborhoodId: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none font-bold">{neighborhoods.map(n => <option key={n.id} value={n.id}>{n.name}</option>)}</select></div>
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">{t('admin.members.role')}</label><select value={selectedUser.role} onChange={e => setSelectedUser({...selectedUser, role: e.target.value as any})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none font-bold"><option value={UserRole.MEMBER}>{t('role.member')}</option><option value={UserRole.BOARD}>{t('role.board')}</option><option value={UserRole.REPRESENTATIVE}>{t('role.representative')}</option><option value={UserRole.ADMIN}>{t('role.admin')}</option></select></div>
                                  <div>
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1 flex items-center gap-2"><StickyNote size={12}/> {t('admin.members.notes_board')}</label>
                                      <textarea value={selectedUser.internalNotes || ''} onChange={e => setSelectedUser({...selectedUser, internalNotes: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none h-48 text-sm leading-relaxed" placeholder={t('admin.members.notes_ph')} />
                                  </div>
                              </div>
                          )}
                      </div>

                      {/* Drawer Footer */}
                      <div className="p-10 border-t border-stone-100 bg-white flex gap-4 shrink-0">
                          {selectedUser.id && (
                              <button onClick={() => setPwResetFor(selectedUser)} title={t('pw.title')} className="px-5 py-4 bg-stone-100 text-stone-600 rounded-2xl font-bold hover:bg-stone-200 transition-colors flex items-center gap-2"><KeyRound size={20}/> {t('pw.short')}</button>
                          )}
                          {selectedUser.id && (
                              selectedUser.membershipStatus === 'INACTIVE' ? (
                                  <button onClick={handleToggleMembership} title={t('admin.members.reactivate_title')} className="px-5 py-4 bg-emerald-50 text-emerald-700 rounded-2xl font-bold hover:bg-emerald-100 transition-colors flex items-center gap-2"><UserCheck2 size={20}/> {t('admin.members.reactivate')}</button>
                              ) : (
                                  <button onClick={handleToggleMembership} title={t('admin.members.remove_action')} className="px-5 py-4 bg-red-50 text-red-600 rounded-2xl font-bold hover:bg-red-100 transition-colors flex items-center gap-2"><UserMinus size={20}/> {t('admin.members.remove')}</button>
                              )
                          )}
                          <button onClick={() => setIsUserDrawerOpen(false)} className="flex-1 py-4 bg-stone-100 text-stone-500 rounded-2xl font-bold hover:bg-stone-200 transition-colors">{t('common.cancel')}</button>
                          <button onClick={handleSaveUser} className="flex-[2] py-4 bg-primary text-white rounded-2xl font-bold shadow-xl shadow-rose-100 flex items-center justify-center gap-2 hover:bg-rose-600 transition-all"><Save size={20}/> {t('common.save_changes')}</button>
                      </div>
                  </motion.div>
              </div>
          )}
      </AnimatePresence>
    </div>
  );
};

// --- SUB-COMPONENT: DATA QUALITY MONITOR ---
const AdminDataQuality = ({ users, neighborhoods, onEditUser }: any) => {
  const { t } = useTranslation();
    const { showAlert, showConfirm } = useFeedback();
    const [switching, setSwitching] = useState(false);

    // Mitglieder, bei denen die Zustellart E-Mail verspricht, aber keine
    // brauchbare Adresse hinterlegt ist.
    const deliveryConflicts = useMemo(
        () => users.filter((u: UserProfile) => hasDeliveryConflict(u)),
        [users]
    );

    const switchConflictsToPost = async () => {
        const ok = await showConfirm({
            title: t('admin.dq.delivery_conflict_title'),
            message: t('admin.dq.switch_confirm'),
            confirmText: t('admin.dq.switch_all_to_post', { count: deliveryConflicts.length }),
            type: 'primary',
        });
        if (!ok) return;
        setSwitching(true);
        try {
            const batch = writeBatch(db);
            deliveryConflicts.forEach((u: UserProfile) => {
                batch.set(doc(db, 'users', u.id), { invoiceDeliveryMethod: 'POST' }, { merge: true });
            });
            await batch.commit();
            showAlert({ type: 'success', message: t('admin.dq.switched', { count: deliveryConflicts.length }) });
        } catch (e: any) {
            showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
        } finally {
            setSwitching(false);
        }
    };
    const qualityReport = useMemo(() => {
        return users.map((u: UserProfile) => {
            // Dieselben Regeln wie im Nachbarschafts-Detail, zentral in
            // lib/memberQuality. Die Feldnamen sind Uebersetzungsschluessel.
            const missing = missingFieldKeys(u).map(k => t(k));
            const score = qualityScore(missing.length);
            // `user` bleibt der unveraenderte Datensatz -- `missing`/`score`
            // sind nur fuer die Anzeige und duerfen beim Speichern aus dem
            // Drawer niemals in der users-Tabelle landen.
            return { ...u, missing, score, user: u };
        }).sort((a: any, b: any) => a.score - b.score);
    }, [users, t]);

    const avgQuality = Math.round(qualityReport.reduce((acc: number, u: any) => acc + u.score, 0) / (users.length || 1));

    return (
        <div className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm flex flex-col items-center justify-center text-center">
                    <div className="w-20 h-20 rounded-full border-4 border-emerald-50 flex items-center justify-center mb-4">
                        <span className="text-3xl font-display font-bold text-emerald-600">{avgQuality}%</span>
                    </div>
                    <p className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('admin.dq.avg')}</p>
                </div>
                <div className="bg-rose-50 p-8 rounded-[2.5rem] border border-rose-100 shadow-sm col-span-2">
                    <h3 className="text-lg font-bold text-rose-900 mb-2">{t('admin.dq.action_needed')}</h3>
                    <p className="text-sm text-rose-700">{t('admin.dq.action_text', { count: qualityReport.filter((u: any) => u.score < 60).length })}</p>
                </div>
            </div>

            {deliveryConflicts.length > 0 && (
                <div className="bg-amber-50 border border-amber-200 rounded-[2.5rem] p-8 flex flex-wrap items-start justify-between gap-6">
                    <div className="flex gap-4 max-w-3xl">
                        <AlertTriangle size={22} className="text-amber-600 shrink-0 mt-0.5" />
                        <div>
                            <h3 className="text-lg font-bold text-amber-900 mb-1">{t('admin.dq.delivery_conflict_title')}</h3>
                            <p className="text-sm text-amber-800 leading-relaxed">
                                {t('admin.dq.delivery_conflict_text', { count: deliveryConflicts.length })}
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={switchConflictsToPost}
                        disabled={switching}
                        className="bg-amber-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:bg-amber-700 transition-colors shadow-sm disabled:opacity-60 shrink-0"
                    >
                        {t('admin.dq.switch_all_to_post', { count: deliveryConflicts.length })}
                    </button>
                </div>
            )}

            <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="p-8 border-b border-stone-100 flex justify-between items-center">
                    <h3 className="font-bold text-stone-900 flex items-center gap-2"><CheckSquare size={20} className="text-primary"/> {t('admin.dq.monitor')}</h3>
                    <div className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('admin.dq.total', { count: users.length })}</div>
                </div>
                <div className="max-h-[600px] overflow-y-auto custom-scrollbar">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100 sticky top-0 z-10">
                            <tr>
                                <th className="px-8 py-4">{t('field.member')}</th>
                                <th className="px-8 py-4">{t('admin.dq.missing')}</th>
                                <th className="px-8 py-4">{t('admin.dq.quality')}</th>
                                <th className="px-8 py-4 text-right">{t('common.actions')}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-stone-50">
                            {qualityReport.map((u: any) => (
                                <tr key={u.id} className="hover:bg-stone-50/50 transition-colors">
                                    <td className="px-8 py-4">
                                        <div className="font-bold text-stone-900">{u.displayName}</div>
                                        <div className="text-[10px] text-stone-400">{neighborhoods.find((n:any) => n.id === u.neighborhoodId)?.name || 'Pa lagje'}</div>
                                    </td>
                                    <td className="px-8 py-4">
                                        <div className="flex flex-wrap gap-1">
                                            {u.missing.map((m: string) => (
                                                <span key={m} className="px-2 py-0.5 bg-rose-50 text-rose-600 rounded text-[9px] font-bold uppercase border border-rose-100">{m}</span>
                                            ))}
                                            {u.missing.length === 0 && <span className="text-emerald-500 font-bold text-[10px] uppercase">{t('admin.dq.complete')}</span>}
                                        </div>
                                    </td>
                                    <td className="px-8 py-4">
                                        <div className="flex items-center gap-2">
                                            <div className="w-16 h-1.5 bg-stone-100 rounded-full overflow-hidden">
                                                <div className={`h-full ${u.score > 80 ? 'bg-emerald-500' : u.score > 50 ? 'bg-amber-500' : 'bg-rose-500'}`} style={{ width: `${u.score}%` }} />
                                            </div>
                                            <span className="text-[10px] font-bold">{u.score}%</span>
                                        </div>
                                    </td>
                                    <td className="px-8 py-4 text-right">
                                        <button onClick={() => onEditUser(u.user)} className="p-2 bg-stone-900 text-white rounded-lg hover:bg-primary transition-all shadow-sm">
                                            <ArrowRight size={14}/>
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

// --- SUB-COMPONENT: NEIGHBORHOOD 360° DETAIL VIEW ---
const AdminNeighborhoodDetail = ({ neighborhoodId, neighborhoods, users, payments, selectedYear, onBack, onEdit, onEditUser }: any) => {
  const { t } = useTranslation();
    const [memberFilter, setMemberFilter] = useState<'ALL' | 'OPEN' | 'INCOMPLETE'>('ALL');
    const neighborhood = neighborhoods.find((n: any) => n.id === neighborhoodId);
    const neighborhoodMembers = users.filter((u: any) => u.neighborhoodId === neighborhoodId);
    const manager = users.find((u: any) => u.id === neighborhood?.managerId);
    // Mehrere Verantwortliche moeglich; die erste gilt als federfuehrend.
    const responsibleIds: string[] = neighborhood?.contactPersonIds?.length
        ? neighborhood.contactPersonIds
        : neighborhood?.managerId ? [neighborhood.managerId] : [];
    const responsible = responsibleIds
        .map((id: string) => users.find((u: any) => u.id === id))
        .filter(Boolean);

    // Je Mitglied: Beitragsstand des Jahres und welche Angaben fehlen.
    const memberRows = useMemo(() => neighborhoodMembers.map((u: any) => {
        const missing = missingFieldKeys(u);
        return { ...u, fee: feeStateFor(u.id, payments, selectedYear), missing, score: qualityScore(missing.length) };
    }), [neighborhoodMembers, payments, selectedYear]);

    const openAmount = useMemo(() => {
        const ids = new Set(neighborhoodMembers.map((u: any) => u.id));
        return payments
            .filter((p: any) => ids.has(p.userId) && p.status !== 'PAID' && p.status !== 'CANCELLED' && p.status !== 'WRITTEN_OFF')
            .filter((p: any) => Number(p.billingYear || 0) === selectedYear
                || (p.timestamp?.toDate ? p.timestamp.toDate().getFullYear() === selectedYear : false))
            .reduce((sum: number, p: any) => sum + (Number(p.amount) || 0), 0);
    }, [neighborhoodMembers, payments, selectedYear]);

    const visibleRows = memberRows.filter((u: any) =>
        memberFilter === 'OPEN' ? u.fee !== 'PAID'
        : memberFilter === 'INCOMPLETE' ? u.missing.length > 0
        : true);

    const openCount = memberRows.filter((u: any) => u.fee !== 'PAID').length;
    const incompleteCount = memberRows.filter((u: any) => u.missing.length > 0).length;
    
    const neighborhoodStats = useMemo(() => {
        const memberIds = neighborhoodMembers.map((u: any) => u.id);
        const neighborhoodPayments = payments.filter((p: any) => 
            memberIds.includes(p.userId) && 
            p.timestamp?.toDate().getFullYear() === selectedYear
        );

        const paidCount = neighborhoodPayments.filter((p: any) => p.status === 'PAID').length;
        const pendingCount = neighborhoodPayments.filter((p: any) => p.status !== 'PAID').length;
        const totalAmount = neighborhoodPayments.filter((p: any) => p.status === 'PAID').reduce((sum: number, p: any) => sum + p.amount, 0);

        const chartData = [
            { name: t('admin.nb.fee.PAID'), value: paidCount, color: '#10b981' },
            { name: t('admin.nb.fee.OPEN'), value: pendingCount, color: '#e7e5e4' }
        ];

        const roleData = [
            { name: t('role.member'), value: neighborhoodMembers.filter((u:any) => u.role === 'MEMBER').length, color: '#f43f5e' },
            { name: t('role.representative'), value: neighborhoodMembers.filter((u:any) => u.role === 'REPRESENTATIVE').length, color: '#3b82f6' },
            { name: t('role.board'), value: neighborhoodMembers.filter((u:any) => u.role === 'BOARD').length, color: '#fbbf24' }
        ].filter(d => d.value > 0);

        return { paidCount, pendingCount, totalAmount, chartData, roleData };
    }, [neighborhoodMembers, payments, selectedYear]);

    if (!neighborhood) return null;

    return (
        <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.98 }} className="space-y-8 pb-20">
            <div className="flex justify-between items-center">
                <button onClick={onBack} className="flex items-center gap-2 text-stone-400 hover:text-stone-900 font-bold text-sm transition-colors">
                    <ArrowLeft size={16}/> {t('admin.members.back_to_list')}
                </button>
                <button onClick={() => onEdit?.(neighborhood)} className="flex items-center gap-2 bg-white border border-stone-200 text-stone-700 px-5 py-2.5 rounded-xl font-bold text-sm hover:border-primary/40 hover:text-primary transition-colors shadow-sm">
                    <Settings size={16}/> {t('admin.nb.edit_button')}
                </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <div className="lg:col-span-8 bg-white p-10 rounded-[3rem] border border-stone-100 shadow-sm relative overflow-hidden flex flex-col justify-between min-h-[320px]">
                    <div className="absolute top-0 right-0 w-96 h-96 bg-primary/5 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/2" />
                    <div className="relative z-10 flex justify-between items-start">
                        <div>
                            <div className="inline-flex items-center gap-2 bg-rose-50 text-rose-600 px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest mb-4">{t('admin.nb.local_unit')}</div>
                            <h2 className="text-5xl font-display font-bold italic text-stone-900 leading-tight mb-2">{neighborhood.name}</h2>
                            <p className="text-stone-400 font-bold uppercase tracking-[0.2em] text-xs flex items-center gap-2">
                                <MapPin size={14} className="text-primary"/> {neighborhoodPlace(neighborhood)}
                            </p>
                        </div>
                        <div className="bg-stone-50 p-6 rounded-[2rem] border border-stone-100 shadow-inner">
                            <MapPinned size={40} className="text-primary"/>
                        </div>
                    </div>
                    <div className="mt-8 pt-8 border-t border-stone-50 flex gap-12 relative z-10">
                        <div><p className="text-2xl font-bold text-stone-900">{neighborhoodMembers.length}</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">{t('admin.members.count')}</p></div>
                        <div><p className="text-2xl font-bold text-stone-900">{neighborhoodStats.totalAmount.toLocaleString()} CHF</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">{t('admin.nb.contributions', { year: selectedYear })}</p></div>
                        <div><p className="text-2xl font-bold text-stone-900">{((neighborhoodStats.paidCount / (neighborhoodMembers.length || 1)) * 100).toFixed(0)}%</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">{t('admin.nb.participation')}</p></div>
                        <div><p className={`text-2xl font-bold ${openAmount > 0 ? 'text-amber-600' : 'text-stone-900'}`}>{openAmount.toLocaleString()} CHF</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">{t('admin.nb.open_amount')}</p></div>
                    </div>
                </div>

                <div className="lg:col-span-4 bg-white p-10 rounded-[3rem] border border-stone-100 shadow-sm flex flex-col items-center text-center justify-center">
                    <h3 className="text-sm font-bold text-stone-400 uppercase tracking-widest mb-6">{t('admin.nb.payment_status', { year: selectedYear })}</h3>
                    <div className="w-full h-48 relative">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie data={neighborhoodStats.chartData} innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                                    {neighborhoodStats.chartData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.color} stroke="none" />
                                    ))}
                                </Pie>
                                <Tooltip />
                            </PieChart>
                        </ResponsiveContainer>
                        <div className="absolute inset-0 flex flex-col items-center justify-center">
                            <p className="text-2xl font-bold text-stone-900">{neighborhoodStats.paidCount}</p>
                            <p className="text-[8px] text-stone-400 font-bold uppercase tracking-tighter">{t('admin.nb.paid_suffix')}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <div className="lg:col-span-8 bg-white rounded-[3rem] border border-stone-100 shadow-sm overflow-hidden flex flex-col min-h-[500px]">
                    <div className="p-8 border-b border-stone-100 flex flex-wrap justify-between items-center gap-4 bg-stone-50/50">
                        <h3 className="font-bold text-stone-900 text-lg flex items-center gap-3">
                            <Users size={22} className="text-primary"/> {t('admin.members.register')}
                        </h3>
                        <div className="flex bg-white p-1 rounded-xl border border-stone-200">
                            {([['ALL', t('admin.nb.filter_all'), memberRows.length],
                               ['OPEN', t('admin.nb.filter_open'), openCount],
                               ['INCOMPLETE', t('admin.nb.filter_incomplete'), incompleteCount]] as const).map(([key, lbl, n]) => (
                                <button key={key} onClick={() => setMemberFilter(key as any)}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${memberFilter === key ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                                    {lbl} <span className={memberFilter === key ? 'opacity-70' : 'opacity-50'}>{n}</span>
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="flex-1 overflow-x-auto">
                        <table className="w-full text-left text-sm">
                            <thead className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100 bg-white sticky top-0">
                                <tr><th className="px-8 py-4">{t('field.member')}</th><th className="px-8 py-4">{t('admin.nb.fee_year', { year: selectedYear })}</th><th className="px-8 py-4">{t('admin.nb.data_column')}</th><th className="px-8 py-4">{t('field.status')}</th><th className="px-8 py-4 text-right">{t('common.actions')}</th></tr>
                            </thead>
                            <tbody className="divide-y divide-stone-50">
                                {visibleRows.length === 0 && (
                                    <tr><td colSpan={5} className="px-8 py-12 text-center text-stone-400 italic text-sm">{t('admin.nb.no_members_filter')}</td></tr>
                                )}
                                {visibleRows.map((u:any) => (
                                    <tr key={u.id} className="hover:bg-stone-50/50 group transition-colors">
                                        <td className="px-8 py-4">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-xl bg-stone-100 flex items-center justify-center font-bold text-stone-400 overflow-hidden shadow-sm">
                                                    {u.photoFileName ? <img src={u.photoFileName} className="w-full h-full object-cover" onError={onImageError}/> : u.displayName?.charAt(0)}
                                                </div>
                                                <div><p className="font-bold text-stone-800">{u.displayName}</p><p className="text-[10px] text-stone-400">{u.phone || t('admin.nb.no_phone')}</p></div>
                                            </div>
                                        </td>
                                        <td className="px-8 py-4">
                                            <span className={`px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider ${
                                                u.fee === 'PAID' ? 'bg-emerald-100 text-emerald-700'
                                                : u.fee === 'OPEN' ? 'bg-amber-100 text-amber-700'
                                                : 'bg-stone-100 text-stone-400'}`}>
                                                {t('admin.nb.fee.' + u.fee)}
                                            </span>
                                        </td>
                                        <td className="px-8 py-4">
                                            {u.missing.length === 0 ? (
                                                <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-600 flex items-center gap-1"><CheckCircle2 size={12}/> {t('admin.nb.data_ok')}</span>
                                            ) : (
                                                <span className="text-[10px] text-rose-600 font-bold flex items-center gap-1" title={u.missing.map((k:string) => t(k)).join(', ')}>
                                                    <AlertTriangle size={12}/> {t('admin.nb.data_missing', { fields: u.missing.map((k:string) => t(k)).join(', ') })}
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-8 py-4"><span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${u.membershipStatus === 'ACTIVE' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>{u.membershipStatus}</span></td>
                                        <td className="px-8 py-4 text-right"><button onClick={() => onEditUser?.(u.user || u)} title={t('common.edit')} className="p-2 text-stone-400 hover:text-primary transition-colors"><ExternalLink size={16}/></button></td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

                <div className="lg:col-span-4 space-y-8">
                    <div className="bg-stone-900 text-white p-8 rounded-[3rem] shadow-xl relative overflow-hidden">
                        <div className="absolute top-0 right-0 p-4 opacity-10"><Crown size={80}/></div>
                        <h4 className="text-[10px] font-bold text-stone-400 uppercase tracking-[0.2em] mb-8">{t('admin.nb.manager')}</h4>
                        <div className="flex items-center gap-6 mb-8 relative z-10">
                            <div className="w-20 h-20 rounded-[1.5rem] bg-white/10 flex items-center justify-center font-bold text-2xl border border-white/20 shadow-2xl overflow-hidden">
                                {manager?.photoFileName ? <img src={manager.photoFileName} className="w-full h-full object-cover" onError={onImageError}/> : manager?.displayName?.charAt(0) || '?'}
                            </div>
                            <div><p className="font-bold text-xl">{manager?.displayName || t('admin.nb.no_manager')}</p><p className="text-xs text-stone-500 font-mono italic">{responsible.length > 1 ? t('admin.nb.lead') : t('admin.nb.manager_badge')}</p></div>
                        </div>
                        <div className="space-y-4 relative z-10">
                            {manager?.email && <div className="flex items-center gap-3 text-xs text-stone-300 bg-white/5 p-3 rounded-xl border border-white/5"><Mail size={14} className="text-primary"/> {manager.email}</div>}
                            {manager?.phone && <div className="flex items-center gap-3 text-xs text-stone-300 bg-white/5 p-3 rounded-xl border border-white/5"><Phone size={14} className="text-primary"/> {manager.phone}</div>}
                        </div>

                        {responsible.length > 1 && (
                            <div className="mt-8 pt-6 border-t border-white/10 relative z-10">
                                <p className="text-[10px] font-bold text-stone-500 uppercase tracking-[0.2em] mb-4">{t('admin.nb.responsible')}</p>
                                <div className="space-y-2">
                                    {responsible.slice(1).map((u: any) => (
                                        <div key={u.id} className="flex items-center gap-3 text-xs text-stone-300 bg-white/5 p-3 rounded-xl border border-white/5">
                                            <div className="w-6 h-6 rounded-lg bg-white/10 flex items-center justify-center text-[10px] font-bold shrink-0">
                                                {u.displayName?.charAt(0)}
                                            </div>
                                            <span className="truncate">{u.displayName}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </motion.div>
    );
};

export default AdminPanel;
