
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
import { collection, doc, serverTimestamp, query, orderBy, onSnapshot, updateDoc, deleteDoc, where, addDoc, setDoc, getDocs, writeBatch, getDoc, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { signOut } from 'firebase/auth';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import Papa from 'papaparse';

// Sub-components
import AdminAnalytics from './AdminAnalytics';
import AdminWebsite from './AdminWebsite';
import SocialAI from './SocialAI';
import AdminFinance from './AdminFinance';
import AdminData from './AdminData';
import AdminAccounting from './AdminAccounting';
import AdminStatistics from './AdminStatistics';
import AdminSettings from './AdminSettings';
import AdminBoard from './AdminBoard';
import AdminTasks from './AdminTasks';
import AdminCommunication from './AdminCommunication';
import AdminExpenses from './AdminExpenses'; 

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
  const [registrations, setRegistrations] = useState<EventRegistration[]>([]);
  const [selectedYear, setSelectedYear] = useState<number>(new Date().getFullYear());

  // Management UI States
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  
  // Member Drawer State
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
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
    return () => { unsubUsers(); unsubNeighborhoods(); unsubEvents(); unsubNews(); unsubPayments(); unsubRegs(); };
  }, []);

  const incompleteUsersCount = useMemo(() => {
      return users.filter(u => !u.phone || !u.street || !u.city || !u.zip || !u.birthdate || !u.neighborhoodId).length;
  }, [users]);

  const filteredUsers = useMemo(() => {
      return users.filter(u => {
          const matchSearch = u.displayName?.toLowerCase().includes(search.toLowerCase()) || u.email?.toLowerCase().includes(search.toLowerCase());
          const matchStatus = statusFilter === 'ALL' || u.membershipStatus === statusFilter;
          const matchRole = roleFilter === 'ALL' || u.role === roleFilter;
          return matchSearch && matchStatus && matchRole;
      });
  }, [users, search, statusFilter, roleFilter]);

  const navGroups: NavGroup[] = [
      {
          title: 'Management',
          items: [
              { id: 'ANALYTICS', label: t('admin.tab.analytics'), icon: <LayoutDashboard size={18} /> },
              { id: 'USERS', label: t('admin.tab.users'), icon: <Users size={18} /> },
              { id: 'DATA_QUALITY', label: t('admin.tab.data_quality'), icon: <ShieldAlert size={18} />, badge: incompleteUsersCount },
              { id: 'NEIGHBORHOODS', label: t('admin.tab.neighborhoods'), icon: <MapPin size={18} /> },
              { id: 'BOARD', label: t('admin.tab.board'), icon: <Briefcase size={18} /> },
          ]
      },
      {
          title: 'Financat',
          items: [
              { id: 'FINANCE', label: t('admin.tab.finance'), icon: <DollarSign size={18} /> },
              { id: 'EXPENSES', label: t('admin.tab.expenses'), icon: <Receipt size={18} /> },
              { id: 'ACCOUNTING', label: t('admin.tab.accounting'), icon: <BookOpen size={18} /> },
              { id: 'STATISTICS', label: t('admin.tab.statistics'), icon: <BarChart2 size={18} /> },
          ]
      },
      {
          title: 'Përmbajtja',
          items: [
              { id: 'EVENTS', label: t('admin.tab.events'), icon: <Calendar size={18} /> },
              { id: 'NEWS', label: 'News Feed', icon: <Newspaper size={18} /> },
              { id: 'WEBSITE', label: t('admin.tab.website'), icon: <Globe size={18} /> },
              { id: 'SOCIAL_AI', label: 'Social AI', icon: <Zap size={18} /> },
          ]
      },
      {
          title: 'Sistemi',
          items: [
              { id: 'DATA', label: 'Data Center', icon: <Database size={18} /> },
              { id: 'COMMUNICATION', label: 'Komunikimi', icon: <MessageSquare size={18} /> },
              { id: 'SETTINGS', label: t('admin.tab.settings'), icon: <Settings size={18} /> },
          ]
      }
  ];

  const handleSaveUser = async () => {
      if(!selectedUser) return;
      
      if (selectedUser.email?.endsWith('@koretini.legacy')) {
          showAlert({ type: 'error', message: 'Ju lutem përditësoni email-in e përkohshëm (@koretini.legacy) para se të ruani.' });
          return;
      }

      try {
          const displayName = `${selectedUser.firstName || ''} ${selectedUser.lastName || ''}`.trim() || selectedUser.displayName;
          await updateDoc(doc(db, 'users', selectedUser.id), { ...selectedUser, displayName } as any);
          showAlert({ type: 'success', message: 'Mitglied erfolgreich aktualisiert.' });
          setIsUserDrawerOpen(false);
      } catch (e) { showAlert({ type: 'error', message: 'Fehler beim Speichern.' }); }
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
        showAlert({ type: 'success', message: 'Event u ruajt me sukses.' });
    } catch (e) { showAlert({ type: 'error', message: 'Dështoi ruajtja.' }); }
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
        showAlert({ type: 'success', message: 'Lajmi u ruajt me sukses.' });
    } catch (e) { showAlert({ type: 'error', message: 'Dështoi ruajtja.' }); }
  };

  const handleDeleteContent = async (collectionName: string, id: string) => {
    if (await showConfirm({ title: 'A jeni i sigurt?', message: 'Ky veprim nuk mund të kthehet.', type: 'danger' })) {
        await deleteDoc(doc(db, collectionName, id));
        showAlert({ type: 'success', message: 'U fshi me sukses.' });
    }
  };

  const getEventTimeBadge = (dateStr: string) => {
      const eventDate = new Date(dateStr);
      const today = new Date();
      const diffDays = Math.ceil((eventDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      
      if (diffDays < 0) return { label: 'Kaluar', color: 'bg-stone-100 text-stone-500' };
      if (diffDays <= 30) return { label: 'Aktual', color: 'bg-emerald-100 text-emerald-700' };
      return { label: 'Në të ardhmen', color: 'bg-blue-100 text-blue-700' };
  };

  // --- REGISTRATION MANAGEMENT ---
  const handleUpdateRegistrationStatus = async (regId: string, status: 'APPROVED' | 'REJECTED' | 'PENDING') => {
      try {
          await updateDoc(doc(db, 'event_registrations', regId), { status });
          showAlert({ type: 'success', message: `Statusi u përditësua në ${status}.` });
      } catch (e) { showAlert({ type: 'error', message: 'Dështoi përditësimi.' }); }
  };

  const exportRegistrationsCSV = (event: SolidarityEvent) => {
      const eventRegs = registrations.filter(r => r.eventId === event.id);
      if (eventRegs.length === 0) {
          showAlert({ type: 'info', message: 'Nuk ka regjistrime për të eksportuar.' });
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
                  <div><h1 className="font-display font-bold text-xl italic text-stone-900 leading-none">Admin</h1><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">Koretini</p></div>
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
                                        <div className="relative flex-1 md:w-64"><Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={16}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Kërko..." className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/30" /></div>
                                        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="p-2.5 bg-stone-50 border border-stone-100 rounded-xl text-xs font-bold outline-none"><option value="ALL">Statusi</option><option value="ACTIVE">Aktiv</option><option value="PENDING">Pendent</option></select>
                                    </div>
                                    <button onClick={() => { setSelectedUser({ id: '', email: '', role: UserRole.MEMBER, membershipStatus: 'PENDING', joinedAt: new Date().toISOString(), tenantId: 'koretini' }); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><UserPlus size={16}/> Shto Anëtar</button>
                                </div>
                                <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                                    <table className="w-full text-left">
                                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                            <tr><th className="px-6 py-4">Anëtari</th><th className="px-6 py-4">Lagjja</th><th className="px-6 py-4">Statusi</th><th className="px-6 py-4 text-right">Aksioni</th></tr>
                                        </thead>
                                        <tbody className="divide-y divide-stone-50">
                                            {filteredUsers.map(u => {
                                                const isLegacyEmail = u.email?.endsWith('@koretini.legacy');
                                                return (
                                                <tr key={u.id} onClick={() => { setSelectedUser(u); setUserDrawerTab('GENERAL'); setIsUserDrawerOpen(true); }} className="hover:bg-stone-50/50 transition-colors group cursor-pointer">
                                                    <td className="px-6 py-4">
                                                        <div className="flex items-center gap-3">
                                                            <div className="w-10 h-10 rounded-full bg-stone-100 overflow-hidden flex items-center justify-center font-bold text-stone-400">
                                                                {u.photoFileName ? <img src={u.photoFileName} className="w-full h-full object-cover"/> : u.displayName?.charAt(0)}
                                                            </div>
                                                            <div>
                                                                <p className="font-bold text-stone-900 flex items-center gap-2">
                                                                    {u.displayName}
                                                                    {isLegacyEmail && <span className="px-1.5 py-0.5 bg-red-100 text-red-600 rounded text-[9px] uppercase tracking-wider font-bold flex items-center gap-1" title="Invalid/Temporary Email"><AlertTriangle size={10}/> Invalid Email</span>}
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
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                {neighborhoods.map(n => (
                                    <div key={n.id} onClick={() => setSelectedNeighborhoodId(n.id)} className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm group hover:shadow-xl transition-all relative overflow-hidden cursor-pointer">
                                        <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity">
                                          <button onClick={(e) => { e.stopPropagation(); setEditingNeighborhood(n); setShowNeighborhoodModal(true); }} className="p-2 bg-stone-50 text-stone-400 hover:text-stone-900 rounded-xl border border-stone-100 transition-colors"><Settings size={16}/></button>
                                        </div>
                                        <div className="flex justify-between items-start mb-4"><div className="p-3 bg-stone-50 rounded-2xl text-primary group-hover:bg-primary group-hover:text-white transition-colors shadow-inner"><MapPin size={24}/></div></div>
                                        <h4 className="font-bold text-lg text-stone-900 mb-1">{n.name}</h4>
                                        <p className="text-xs text-stone-400 uppercase tracking-widest mb-6">{n.location.city}, {n.location.country}</p>
                                        <div className="space-y-3">
                                            <div className="flex justify-between items-center p-3 bg-stone-50 rounded-2xl"><span className="text-xs font-bold text-stone-400 uppercase">Anëtarë</span><span className="font-bold text-stone-900">{users.filter(u => u.neighborhoodId === n.id).length}</span></div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}

                        {activeTab === 'FINANCE' && <AdminFinance viewMode="GRID" selectedYear={selectedYear} />}
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
                                    <h3 className="font-bold text-stone-900 text-xl flex items-center gap-2"><Calendar size={20} className="text-primary"/> Menaxhimi i Ngjarjeve</h3>
                                    <button onClick={() => { setEditingEvent({ title: '', description: '', date: new Date().toISOString().split('T')[0], time: '19:00', location: 'Koretin', category: 'SOCIAL', status: 'DRAFT', isRegistrable: true }); setShowEventModal(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16}/> Shto Event</button>
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                    {events.map(event => {
                                        const timeBadge = getEventTimeBadge(event.date);
                                        return (
                                            <div key={event.id} className={`bg-white rounded-[2rem] overflow-hidden border transition-all relative group hover:shadow-xl ${event.status === 'ARCHIVED' ? 'opacity-50 border-stone-200' : 'border-stone-100 shadow-sm'}`}>
                                                <div className="aspect-video relative overflow-hidden">
                                                    <img src={event.image || 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=800&q=80'} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
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
                                    {events.length === 0 && <div className="col-span-full py-20 text-center text-stone-400 italic">Asnjë event i regjistruar.</div>}
                                </div>
                            </div>
                        )}

                        {activeTab === 'NEWS' && (
                            <div className="space-y-6">
                                <div className="flex justify-between items-center bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                                    <h3 className="font-bold text-stone-900 text-xl flex items-center gap-2"><Newspaper size={20} className="text-blue-600"/> News Feed Editor</h3>
                                    <button onClick={() => { setEditingNews({ title: '', category: 'DIASPORA', subcategory: 'Updates', location: 'Zürich', content: [''], image: '', status: 'DRAFT' }); setShowNewsModal(true); }} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16}/> Shto Lajm</button>
                                </div>
                                <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                                    <table className="w-full text-left">
                                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                            <tr><th className="px-6 py-4">Lajmi</th><th className="px-6 py-4">Statusi</th><th className="px-6 py-4">Kategoria</th><th className="px-6 py-4">Data / Programuar</th><th className="px-6 py-4 text-right">Aksioni</th></tr>
                                        </thead>
                                        <tbody className="divide-y divide-stone-50">
                                            {news.map(item => (
                                                <tr key={item.id} className={`hover:bg-stone-50/50 transition-colors group ${item.status === 'ARCHIVED' ? 'opacity-50' : ''}`}>
                                                    <td className="px-6 py-4">
                                                        <div className="flex items-center gap-3">
                                                            <div className="w-12 h-12 rounded-xl bg-stone-100 overflow-hidden shrink-0 border border-stone-200">
                                                                {item.image ? <img src={item.image} className="w-full h-full object-cover" /> : <LucideImage className="m-auto text-stone-300" size={20}/>}
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
                                            {news.length === 0 && <tr><td colSpan={5} className="py-10 text-center text-stone-400 italic">Nuk ka lajme të publikuara.</td></tr>}
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

      {/* MODAL: EVENT EDITOR */}
      <AnimatePresence>
        {showEventModal && editingEvent && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white w-full max-w-xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[90vh]">
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2"><Calendar className="text-primary"/> Detajet e Eventit</h3>
                        <button onClick={() => setShowEventModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                    </div>
                    <div className="p-8 space-y-4 overflow-y-auto custom-scrollbar">
                        <div className="grid grid-cols-2 gap-4 mb-4">
                            <div className="flex items-center justify-between p-4 bg-stone-50 rounded-2xl border border-stone-200">
                                <div>
                                    <p className="text-[10px] font-bold text-stone-400 uppercase">Regjistrimi</p>
                                    <p className="text-xs font-bold text-stone-800">{editingEvent.isRegistrable ? 'Aktiv' : 'Jo Aktiv'}</p>
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
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Statusi i Publikimit</label>
                                <select 
                                    value={editingEvent.status} 
                                    onChange={e => setEditingEvent({...editingEvent, status: e.target.value as ContentStatus})} 
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                >
                                    <option value="DRAFT">Entwurf (Draft)</option>
                                    <option value="PUBLISHED">Publikuar (Published)</option>
                                    <option value="ARCHIVED">Fshirë / Arkivuar</option>
                                </select>
                            </div>
                        </div>

                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Titulli</label><input value={editingEvent.title} onChange={e => setEditingEvent({...editingEvent, title: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold" /></div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Përshkrimi</label><textarea value={editingEvent.description} onChange={e => setEditingEvent({...editingEvent, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none h-24 text-sm" /></div>
                        <div className="grid grid-cols-2 gap-4">
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Data</label><input type="date" value={editingEvent.date} onChange={e => setEditingEvent({...editingEvent, date: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Kategoria</label><select value={editingEvent.category} onChange={e => setEditingEvent({...editingEvent, category: e.target.value as any})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"><option value="HEALTH">Health</option><option value="EDUCATION">Education</option><option value="CULTURE">Culture</option><option value="SPORT">Sport</option><option value="SOCIAL">Social</option></select></div>
                        </div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">URL e Fotos</label><input value={editingEvent.image} onChange={e => setEditingEvent({...editingEvent, image: e.target.value})} placeholder="https://..." className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-mono" /></div>
                    </div>
                    <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3"><button onClick={() => setShowEventModal(false)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">Anulo</button><button onClick={handleSaveEvent} className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg">Ruaj Eventin</button></div>
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
                              <span className="text-[10px] font-bold text-primary uppercase tracking-widest mb-1 block">Menaxhimi i Regjistrimeve</span>
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
                                  <Download size={16}/> Shkarko Listën (CSV)
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
                                                    title="Mirato"
                                                  >
                                                      <UserCheck size={16}/>
                                                  </button>
                                              )}
                                              {reg.status !== 'REJECTED' && (
                                                  <button 
                                                    onClick={() => handleUpdateRegistrationStatus(reg.id, 'REJECTED')}
                                                    className="p-2 bg-rose-50 text-rose-600 rounded-lg hover:bg-rose-100 transition-colors"
                                                    title="Refuzo"
                                                  >
                                                      <UserMinus size={16}/>
                                                  </button>
                                              )}
                                              <button 
                                                onClick={() => handleDeleteContent('event_registrations', reg.id)}
                                                className="p-2 bg-stone-50 text-stone-400 hover:text-red-500 rounded-lg transition-colors"
                                                title="Fshij"
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
                                      <p className="text-stone-400 italic">Asnjë regjistrim ende për këtë event.</p>
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
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2"><Newspaper className="text-blue-600"/> Detajet e Lajmit</h3>
                        <button onClick={() => setShowNewsModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                    </div>
                    <div className="p-8 space-y-4 overflow-y-auto custom-scrollbar">
                        <div className="grid grid-cols-2 gap-4 mb-2">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Statusi</label>
                                <select 
                                    value={editingNews.status} 
                                    onChange={e => setEditingNews({...editingNews, status: e.target.value as ContentStatus})} 
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                >
                                    <option value="DRAFT">Entwurf (Draft)</option>
                                    <option value="PUBLISHED">Publikuar (Published)</option>
                                    <option value="ARCHIVED">Fshirë / Arkivuar</option>
                                </select>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Termino Publikimin</label>
                                <input 
                                    type="datetime-local"
                                    value={editingNews.publishAt ? (typeof editingNews.publishAt === 'string' ? editingNews.publishAt : editingNews.publishAt.toDate().toISOString().slice(0, 16)) : ''}
                                    onChange={e => setEditingNews({...editingNews, publishAt: e.target.value})}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"
                                />
                            </div>
                        </div>

                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Titulli</label><input value={editingNews.title} onChange={e => setEditingNews({...editingNews, title: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold" /></div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Përmbajtja (Paragrafi i parë)</label><textarea value={editingNews.content?.[0] || ''} onChange={e => setEditingNews({...editingNews, content: [e.target.value]})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none h-32 text-sm" /></div>
                        <div className="grid grid-cols-2 gap-4">
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Lokacioni</label><input value={editingNews.location} onChange={e => setEditingNews({...editingNews, location: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Kategoria</label><select value={editingNews.category} onChange={e => setEditingNews({...editingNews, category: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold"><option value="DIASPORA">Diaspora</option><option value="LOCAL">Local</option><option value="PROJECT">Project</option></select></div>
                        </div>
                        <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">URL e Fotos</label><input value={editingNews.image} onChange={e => setEditingNews({...editingNews, image: e.target.value})} placeholder="https://..." className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-mono" /></div>
                    </div>
                    <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3"><button onClick={() => setShowNewsModal(false)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">Anulo</button><button onClick={handleSaveNews} className="flex-[2] py-3 bg-blue-600 text-white rounded-xl font-bold shadow-lg">Ruaj Lajmin</button></div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* DETAILED USER DRAWER */}
      <AnimatePresence>
          {isUserDrawerOpen && selectedUser && (
              <div className="fixed inset-0 z-[200] flex justify-end">
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setIsUserDrawerOpen(false)} className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" />
                  <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }} className="relative w-full max-w-2xl bg-white shadow-2xl h-screen flex flex-col overflow-hidden">
                      
                      {/* Drawer Header */}
                      <div className="relative pt-12 pb-6 px-10 bg-stone-900 text-white shrink-0">
                          <button onClick={() => setIsUserDrawerOpen(false)} className="absolute top-6 right-6 p-2 hover:bg-white/10 rounded-full text-white/50 hover:text-white transition-colors"><X size={24}/></button>
                          <div className="flex items-center gap-8">
                              <div className="w-28 h-28 rounded-[2rem] bg-white/10 border-2 border-white/20 p-1 flex items-center justify-center text-4xl font-bold shrink-0 overflow-hidden shadow-2xl">
                                  {selectedUser.photoFileName ? <img src={selectedUser.photoFileName} className="w-full h-full object-cover"/> : selectedUser.displayName?.charAt(0)}
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
                                      {tab === 'GENERAL' ? 'Identiteti' : tab === 'ADDRESS' ? 'Adresa' : tab === 'FINANCE' ? 'Financat' : tab === 'HISTORY' ? 'Historia' : 'Intern'}
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
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Përshëndetja</label><select value={selectedUser.salutation || ''} onChange={e => setSelectedUser({...selectedUser, salutation: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none"><option value="">Zgjidh...</option><option value="Z.">Z.</option><option value="Znj.">Znj.</option></select></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Datëlindja</label><input type="date" value={selectedUser.birthdate || ''} onChange={e => setSelectedUser({...selectedUser, birthdate: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div className="grid grid-cols-2 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Emri</label><input value={selectedUser.firstName || ''} onChange={e => setSelectedUser({...selectedUser, firstName: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Mbiemri</label><input value={selectedUser.lastName || ''} onChange={e => setSelectedUser({...selectedUser, lastName: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div>
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Email</label>
                                      {selectedUser.email?.endsWith('@koretini.legacy') && (
                                          <div className="mb-2 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2 text-red-700">
                                              <AlertTriangle size={16} className="mt-0.5 shrink-0" />
                                              <div>
                                                  <p className="text-xs font-bold uppercase tracking-wider mb-0.5">Email i pavlefshëm (Legacy)</p>
                                                  <p className="text-xs">Ky përdorues ka një email të përkohshëm. Ju lutem përditësoni me një email të vërtetë.</p>
                                              </div>
                                          </div>
                                      )}
                                      <input value={selectedUser.email} onChange={e => setSelectedUser({...selectedUser, email: e.target.value})} className={`w-full p-4 bg-white border rounded-xl outline-none ${selectedUser.email?.endsWith('@koretini.legacy') ? 'border-red-300 focus:border-red-500' : 'border-stone-200'}`} />
                                  </div>
                                  <div className="grid grid-cols-2 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Telefoni Primar</label><input value={selectedUser.phone || ''} onChange={e => setSelectedUser({...selectedUser, phone: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Telefoni Sekondar</label><input value={selectedUser.phoneSecondary || ''} onChange={e => setSelectedUser({...selectedUser, phoneSecondary: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                              </div>
                          )}

                          {userDrawerTab === 'ADDRESS' && (
                              <div className="space-y-6">
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Rruga & Nr.</label><input value={selectedUser.street || ''} onChange={e => setSelectedUser({...selectedUser, street: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  <div className="grid grid-cols-3 gap-6">
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">PLZ</label><input value={selectedUser.zip || ''} onChange={e => setSelectedUser({...selectedUser, zip: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                      <div className="col-span-2"><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Qyteti</label><input value={selectedUser.city || ''} onChange={e => setSelectedUser({...selectedUser, city: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  </div>
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Shteti</label><input value={selectedUser.country || ''} onChange={e => setSelectedUser({...selectedUser, country: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none" /></div>
                                  <div className="pt-6 border-t border-stone-200">
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-4">Mënyra e dërgimit të faturës</label>
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
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Grupi i faturimit</label><select value={selectedUser.billingGroup || 'STANDARD'} onChange={e => setSelectedUser({...selectedUser, billingGroup: e.target.value as any})} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl outline-none font-bold text-sm"><option value="STANDARD">STANDARD (Diaspora)</option><option value="KOSOVO">KOSOVO (Resident)</option><option value="REDUCED">REDUCED (Special)</option></select></div>
                                      <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Anëtarësia e personalizuar (Override)</label><div className="relative"><input type="number" value={selectedUser.customAnnualFee || ''} onChange={e => setSelectedUser({...selectedUser, customAnnualFee: parseFloat(e.target.value)})} className="w-full pl-4 pr-12 py-4 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold" /><span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">CHF</span></div></div>
                                  </div>
                                  <div className="bg-stone-900 text-white p-6 rounded-2xl shadow-xl flex items-center justify-between">
                                      <div className="flex items-center gap-4">
                                          <div className="p-3 bg-white/10 rounded-xl"><Hash size={20}/></div>
                                          <div><p className="text-[10px] text-stone-400 uppercase font-bold tracking-widest">Familje ID</p><p className="font-mono font-bold text-lg">{selectedUser.familyId || 'Pa ID'}</p></div>
                                      </div>
                                      <button onClick={async () => { const id = await showPrompt({ title: "Family ID", message: "Shëno ID-në e familjes:" }); if(id) setSelectedUser({...selectedUser, familyId: id}); }} className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-[10px] font-bold uppercase transition-colors">Ndrysho</button>
                                  </div>

                                  <div className="bg-white p-6 rounded-2xl border border-stone-200 shadow-sm">
                                      <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 flex items-center gap-2"><FileText size={14}/> Krijo Faturë të Re</h4>
                                      <div className="space-y-4">
                                          <div>
                                              <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Përshkrimi</label>
                                              <input type="text" id="invoice-desc" defaultValue={`Mitgliederbeitrag ${selectedYear}`} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-bold" />
                                          </div>
                                          <div className="grid grid-cols-2 gap-4">
                                              <div>
                                                  <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Shuma</label>
                                                  <div className="relative">
                                                      <input type="number" id="invoice-amount" defaultValue={selectedUser.customAnnualFee || 100} className="w-full pl-4 pr-12 py-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold text-sm" />
                                                      <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">CHF</span>
                                                  </div>
                                              </div>
                                              <div>
                                                  <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Afati</label>
                                                  <input type="date" id="invoice-due" defaultValue={new Date(new Date().setMonth(new Date().getMonth() + 1)).toISOString().split('T')[0]} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-bold" />
                                              </div>
                                          </div>
                                          <button 
                                              onClick={async () => {
                                                  const desc = (document.getElementById('invoice-desc') as HTMLInputElement).value;
                                                  const amount = parseFloat((document.getElementById('invoice-amount') as HTMLInputElement).value);
                                                  const due = (document.getElementById('invoice-due') as HTMLInputElement).value;
                                                  
                                                  if (!desc || !amount || !due) {
                                                      showAlert({ type: 'error', message: 'Ju lutem plotësoni të gjitha fushat.' });
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
                                                      
                                                      showAlert({ type: 'success', message: 'Fatura u krijua me sukses.' });
                                                      setUserDrawerTab('HISTORY');
                                                  } catch (e: any) {
                                                      showAlert({ type: 'error', message: 'Gabim gjatë krijimit të faturës: ' + e.message });
                                                  }
                                              }}
                                              className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold text-sm hover:bg-stone-800 transition-colors flex items-center justify-center gap-2"
                                          >
                                              <Plus size={16} /> Krijo Faturën
                                          </button>
                                      </div>
                                  </div>
                              </div>
                          )}

                          {userDrawerTab === 'HISTORY' && (
                              <div className="space-y-4">
                                  <div className="flex items-center justify-between px-2 mb-2"><h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest">Zahlungshistorie</h4><span className="text-[10px] font-bold text-stone-400">{payments.filter(p => p.userId === selectedUser.id).length} Einträge</span></div>
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
                                      <div className="text-center py-20 bg-white rounded-3xl border border-dashed border-stone-200"><History size={40} className="mx-auto text-stone-200 mb-4"/><p className="text-stone-400 text-sm italic">Ende asnjë pagesë të regjistruar.</p></div>
                                  )}
                              </div>
                          )}

                          {userDrawerTab === 'INTERNAL' && (
                              <div className="space-y-6">
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Lagjja / Quartier</label><select value={selectedUser.neighborhoodId || ''} onChange={e => setSelectedUser({...selectedUser, neighborhoodId: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none font-bold">{neighborhoods.map(n => <option key={n.id} value={n.id}>{n.name}</option>)}</select></div>
                                  <div><label className="text-[10px] font-bold text-stone-400 uppercase block mb-1">Roli i përdoruesit</label><select value={selectedUser.role} onChange={e => setSelectedUser({...selectedUser, role: e.target.value as any})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none font-bold"><option value={UserRole.MEMBER}>MEMBER</option><option value={UserRole.BOARD}>BOARD</option><option value={UserRole.REPRESENTATIVE}>REPRESENTATIVE</option><option value={UserRole.ADMIN}>ADMIN</option></select></div>
                                  <div>
                                      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1 flex items-center gap-2"><StickyNote size={12}/> Shënime Interne (Board Only)</label>
                                      <textarea value={selectedUser.internalNotes || ''} onChange={e => setSelectedUser({...selectedUser, internalNotes: e.target.value})} className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none h-48 text-sm leading-relaxed" placeholder="Shëno detaje shtesë për anëtarin..." />
                                  </div>
                              </div>
                          )}
                      </div>

                      {/* Drawer Footer */}
                      <div className="p-10 border-t border-stone-100 bg-white flex gap-4 shrink-0">
                          <button onClick={() => setIsUserDrawerOpen(false)} className="flex-1 py-4 bg-stone-100 text-stone-500 rounded-2xl font-bold hover:bg-stone-200 transition-colors">Anulo</button>
                          <button onClick={handleSaveUser} className="flex-[2] py-4 bg-primary text-white rounded-2xl font-bold shadow-xl shadow-rose-100 flex items-center justify-center gap-2 hover:bg-rose-600 transition-all"><Save size={20}/> Ruaj Ndryshimet</button>
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
    const qualityReport = useMemo(() => {
        return users.map((u: UserProfile) => {
            const missing = [];
            if (!u.phone) missing.push('Telefoni');
            if (!u.birthdate) missing.push('Datëlindja');
            if (!u.street || !u.zip || !u.city) missing.push('Adresa');
            if (!u.neighborhoodId) missing.push('Lagja');
            if (!u.email || u.email.includes('@koretini.legacy')) missing.push('Email Valid');
            
            let score = 100 - (missing.length * 20);
            return { ...u, missing, score };
        }).sort((a: any, b: any) => a.score - b.score);
    }, [users]);

    const avgQuality = Math.round(qualityReport.reduce((acc: number, u: any) => acc + u.score, 0) / (users.length || 1));

    return (
        <div className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm flex flex-col items-center justify-center text-center">
                    <div className="w-20 h-20 rounded-full border-4 border-emerald-50 flex items-center justify-center mb-4">
                        <span className="text-3xl font-display font-bold text-emerald-600">{avgQuality}%</span>
                    </div>
                    <p className="text-xs font-bold text-stone-400 uppercase tracking-widest">Cilësia Mesatare</p>
                </div>
                <div className="bg-rose-50 p-8 rounded-[2.5rem] border border-rose-100 shadow-sm col-span-2">
                    <h3 className="text-lg font-bold text-rose-900 mb-2">Veprim i kërkuar</h3>
                    <p className="text-sm text-rose-700">{qualityReport.filter((u: any) => u.score < 60).length} anëtarë kanë mungesë të theksuar të dhënash. Pa këtë informacion, faturimi fizik und njoftimet nuk mund të garantohen.</p>
                </div>
            </div>

            <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="p-8 border-b border-stone-100 flex justify-between items-center">
                    <h3 className="font-bold text-stone-900 flex items-center gap-2"><CheckSquare size={20} className="text-primary"/> Monitorimi i të dhënave</h3>
                    <div className="text-xs font-bold text-stone-400 uppercase tracking-widest">Gjithsej: {users.length} Anëtarë</div>
                </div>
                <div className="max-h-[600px] overflow-y-auto custom-scrollbar">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100 sticky top-0 z-10">
                            <tr>
                                <th className="px-8 py-4">Anëtari</th>
                                <th className="px-8 py-4">Mungon</th>
                                <th className="px-8 py-4">Cilësia</th>
                                <th className="px-8 py-4 text-right">Aksioni</th>
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
                                            {u.missing.length === 0 && <span className="text-emerald-500 font-bold text-[10px] uppercase">E kompletuar ✓</span>}
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
                                        <button onClick={() => onEditUser(u)} className="p-2 bg-stone-900 text-white rounded-lg hover:bg-primary transition-all shadow-sm">
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
const AdminNeighborhoodDetail = ({ neighborhoodId, neighborhoods, users, payments, selectedYear, onBack }: any) => {
    const neighborhood = neighborhoods.find((n: any) => n.id === neighborhoodId);
    const neighborhoodMembers = users.filter((u: any) => u.neighborhoodId === neighborhoodId);
    const manager = users.find((u: any) => u.id === neighborhood?.managerId);
    
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
            { name: 'Paguar', value: paidCount, color: '#10b981' },
            { name: 'Pendent', value: pendingCount, color: '#e7e5e4' }
        ];

        const roleData = [
            { name: 'Member', value: neighborhoodMembers.filter((u:any) => u.role === 'MEMBER').length, color: '#f43f5e' },
            { name: 'Rep', value: neighborhoodMembers.filter((u:any) => u.role === 'REPRESENTATIVE').length, color: '#3b82f6' },
            { name: 'Board', value: neighborhoodMembers.filter((u:any) => u.role === 'BOARD').length, color: '#fbbf24' }
        ].filter(d => d.value > 0);

        return { paidCount, pendingCount, totalAmount, chartData, roleData };
    }, [neighborhoodMembers, payments, selectedYear]);

    if (!neighborhood) return null;

    return (
        <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.98 }} className="space-y-8 pb-20">
            <div className="flex justify-between items-center">
                <button onClick={onBack} className="flex items-center gap-2 text-stone-400 hover:text-stone-900 font-bold text-sm transition-colors">
                    <ArrowLeft size={16}/> Mbrapa te Lista
                </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <div className="lg:col-span-8 bg-white p-10 rounded-[3rem] border border-stone-100 shadow-sm relative overflow-hidden flex flex-col justify-between min-h-[320px]">
                    <div className="absolute top-0 right-0 w-96 h-96 bg-primary/5 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/2" />
                    <div className="relative z-10 flex justify-between items-start">
                        <div>
                            <div className="inline-flex items-center gap-2 bg-rose-50 text-rose-600 px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest mb-4">Njësi Lokale</div>
                            <h2 className="text-5xl font-display font-bold italic text-stone-900 leading-tight mb-2">{neighborhood.name}</h2>
                            <p className="text-stone-400 font-bold uppercase tracking-[0.2em] text-xs flex items-center gap-2">
                                <MapPin size={14} className="text-primary"/> {neighborhood.location.city}, {neighborhood.location.country}
                            </p>
                        </div>
                        <div className="bg-stone-50 p-6 rounded-[2rem] border border-stone-100 shadow-inner">
                            <MapPinned size={40} className="text-primary"/>
                        </div>
                    </div>
                    <div className="mt-8 pt-8 border-t border-stone-50 flex gap-12 relative z-10">
                        <div><p className="text-2xl font-bold text-stone-900">{neighborhoodMembers.length}</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">Anëtarë</p></div>
                        <div><p className="text-2xl font-bold text-stone-900">{neighborhoodStats.totalAmount.toLocaleString()} CHF</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">Kontributet {selectedYear}</p></div>
                        <div><p className="text-2xl font-bold text-stone-900">{((neighborhoodStats.paidCount / (neighborhoodMembers.length || 1)) * 100).toFixed(0)}%</p><p className="text-[10px] text-stone-400 font-bold uppercase tracking-widest">Pjesëmarrja</p></div>
                    </div>
                </div>

                <div className="lg:col-span-4 bg-white p-10 rounded-[3rem] border border-stone-100 shadow-sm flex flex-col items-center text-center justify-center">
                    <h3 className="text-sm font-bold text-stone-400 uppercase tracking-widest mb-6">Statusi i Pagesave {selectedYear}</h3>
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
                            <p className="text-[8px] text-stone-400 font-bold uppercase tracking-tighter">të paguara</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <div className="lg:col-span-8 bg-white rounded-[3rem] border border-stone-100 shadow-sm overflow-hidden flex flex-col min-h-[500px]">
                    <div className="p-8 border-b border-stone-100 flex justify-between items-center bg-stone-50/50">
                        <h3 className="font-bold text-stone-900 text-lg flex items-center gap-3">
                            <Users size={22} className="text-primary"/> Regjistri i Anëtarëve
                        </h3>
                    </div>
                    <div className="flex-1 overflow-x-auto">
                        <table className="w-full text-left text-sm">
                            <thead className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100 bg-white sticky top-0">
                                <tr><th className="px-8 py-4">Anëtari</th><th className="px-8 py-4">Roli</th><th className="px-8 py-4">Statusi</th><th className="px-8 py-4 text-right">Info</th></tr>
                            </thead>
                            <tbody className="divide-y divide-stone-50">
                                {neighborhoodMembers.map((u:any) => (
                                    <tr key={u.id} className="hover:bg-stone-50/50 group transition-colors">
                                        <td className="px-8 py-4">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-xl bg-stone-100 flex items-center justify-center font-bold text-stone-400 overflow-hidden shadow-sm">
                                                    {u.photoFileName ? <img src={u.photoFileName} className="w-full h-full object-cover"/> : u.displayName?.charAt(0)}
                                                </div>
                                                <div><p className="font-bold text-stone-800">{u.displayName}</p><p className="text-[10px] text-stone-400">{u.phone || 'Pa telefon'}</p></div>
                                            </div>
                                        </td>
                                        <td className="px-8 py-4"><span className="text-[10px] font-bold text-stone-500 uppercase tracking-widest border border-stone-200 px-2 py-0.5 rounded-lg">{u.role}</span></td>
                                        <td className="px-8 py-4"><span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${u.membershipStatus === 'ACTIVE' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>{u.membershipStatus}</span></td>
                                        <td className="px-8 py-4 text-right"><button className="p-2 text-stone-400 hover:text-primary"><ExternalLink size={16}/></button></td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

                <div className="lg:col-span-4 space-y-8">
                    <div className="bg-stone-900 text-white p-8 rounded-[3rem] shadow-xl relative overflow-hidden">
                        <div className="absolute top-0 right-0 p-4 opacity-10"><Crown size={80}/></div>
                        <h4 className="text-[10px] font-bold text-stone-400 uppercase tracking-[0.2em] mb-8">Përgjegjësi i Njësisë</h4>
                        <div className="flex items-center gap-6 mb-8 relative z-10">
                            <div className="w-20 h-20 rounded-[1.5rem] bg-white/10 flex items-center justify-center font-bold text-2xl border border-white/20 shadow-2xl overflow-hidden">
                                {manager?.photoFileName ? <img src={manager.photoFileName} className="w-full h-full object-cover"/> : manager?.displayName?.charAt(0) || '?'}
                            </div>
                            <div><p className="font-bold text-xl">{manager?.displayName || 'Pa Manager'}</p><p className="text-xs text-stone-500 font-mono italic">Lagje-Manager</p></div>
                        </div>
                        <div className="space-y-4 relative z-10">
                            {manager?.email && <div className="flex items-center gap-3 text-xs text-stone-300 bg-white/5 p-3 rounded-xl border border-white/5"><Mail size={14} className="text-primary"/> {manager.email}</div>}
                            {manager?.phone && <div className="flex items-center gap-3 text-xs text-stone-300 bg-white/5 p-3 rounded-xl border border-white/5"><Phone size={14} className="text-primary"/> {manager.phone}</div>}
                        </div>
                    </div>
                </div>
            </div>
        </motion.div>
    );
};

export default AdminPanel;
