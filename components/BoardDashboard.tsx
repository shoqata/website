
import React, { useState, useEffect, useMemo } from 'react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile, Payment, Neighborhood, Inquiry, BoardMeeting } from '../types';
import { db } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, doc, updateDoc } from '@/services/supabase-bridge';
import { 
  Briefcase, 
  CalendarDays, 
  Search, 
  UserCog, 
  CheckCircle2, 
  AlertCircle, 
  FileText, 
  MessageSquare, 
  Users, 
  MapPin, 
  X,
  Save,
  Phone,
  Mail,
  Home,
  TrendingUp,
  TrendingDown,
  BarChart3,
  CreditCard
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useFeedback } from '../context/FeedbackContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, CartesianGrid } from 'recharts';

import { neighborhoodCity } from '../lib/neighborhood';
interface BoardDashboardProps {
  user: UserProfile;
}

const BoardDashboard: React.FC<BoardDashboardProps> = ({ user }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  
  // Data State
  const [selectedYear, setSelectedYear] = useState<number>(new Date().getFullYear());
  const [payments, setPayments] = useState<Payment[]>([]);
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  const [meetings, setMeetings] = useState<BoardMeeting[]>([]);
  
  // UI State
  const [searchTerm, setSearchTerm] = useState('');
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [profileData, setProfileData] = useState<Partial<UserProfile>>({});
  const [selectedMeeting, setSelectedMeeting] = useState<BoardMeeting | null>(null);
  
  // New UI States
  const [selectedMember, setSelectedMember] = useState<UserProfile | null>(null); // For Search Result Modal
  const [showInvoiceListModal, setShowInvoiceListModal] = useState<'PAID' | 'OPEN' | null>(null); // For KPI Drilldown

  // FETCH DATA
  useEffect(() => {
    // 1. Payments
    const unsubPayments = onSnapshot(collection(db, 'payments'), (snap) => {
        setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() } as Payment)));
    });

    // 2. Users
    const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
        setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile)));
    });

    // 3. Neighborhoods
    const unsubNeighborhoods = onSnapshot(collection(db, 'neighborhoods'), (snap) => {
        setNeighborhoods(snap.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)));
    });

    // 4. Inquiries (Requests)
    const qInquiries = query(collection(db, 'inquiries'), orderBy('createdAt', 'desc'));
    const unsubInquiries = onSnapshot(qInquiries, (snap) => {
        setInquiries(snap.docs.map(d => ({ id: d.id, ...d.data() } as Inquiry)));
    });

    // 5. Board Meetings (Protocols)
    const qMeetings = query(collection(db, 'board_meetings'), orderBy('date', 'desc'));
    const unsubMeetings = onSnapshot(qMeetings, (snap) => {
        setMeetings(snap.docs.map(d => ({ id: d.id, ...d.data() } as BoardMeeting)));
    });

    return () => { unsubPayments(); unsubUsers(); unsubNeighborhoods(); unsubInquiries(); unsubMeetings(); };
  }, []);

  // DERIVED STATS & ANALYTICS
  const yearPayments = useMemo(() => payments.filter(p => p.timestamp?.toDate().getFullYear() === selectedYear), [payments, selectedYear]);
  
  const stats = useMemo(() => {
      const paid = yearPayments.filter(p => p.status === 'PAID');
      const open = yearPayments.filter(p => p.status === 'PENDING' || p.status === 'OVERDUE');
      
      const totalRevenue = paid.reduce((acc, p) => acc + p.amount, 0);
      const openRevenue = open.reduce((acc, p) => acc + p.amount, 0);

      // Payment Percentage Calculation
      const totalVolume = totalRevenue + openRevenue;
      const paidPercentage = totalVolume > 0 ? Math.round((totalRevenue / totalVolume) * 100) : 0;

      return {
          paidCount: paid.length,
          openCount: open.length,
          totalRevenue,
          openRevenue,
          paidPercentage,
          paidInvoices: paid, // Store for modal list
          openInvoices: open  // Store for modal list
      };
  }, [yearPayments]);

  const neighborhoodAnalytics = useMemo(() => {
      const data = neighborhoods.map(n => {
          const nUsers = users.filter(u => u.neighborhoodId === n.id);
          const uIds = nUsers.map(u => u.id);
          const collected = yearPayments
              .filter(p => uIds.includes(p.userId) && p.status === 'PAID')
              .reduce((sum, p) => sum + p.amount, 0);
          
          return { name: n.name, value: collected, city: neighborhoodCity(n) };
      });

      // Sort by Value Descending
      const sorted = [...data].sort((a, b) => b.value - a.value);
      
      return {
          top5: sorted.slice(0, 5),
          bottom5: sorted.slice(-5).reverse() // Show least paying, reverse so least is first if needed or just slice
      };
  }, [neighborhoods, users, yearPayments]);

  const searchResults = useMemo(() => {
      if (!searchTerm) return { users: [], neighborhoods: [] };
      const term = searchTerm.toLowerCase();
      return {
          users: users.filter(u => u.displayName?.toLowerCase().includes(term) || u.email?.toLowerCase().includes(term)),
          neighborhoods: neighborhoods.filter(n => n.name.toLowerCase().includes(term))
      };
  }, [searchTerm, users, neighborhoods]);

  // PROFILE ACTIONS
  const handleOpenProfile = () => {
      setProfileData({ ...user });
      setShowProfileModal(true);
  };

  const handleUpdateProfile = async () => {
      if (!user.id) return;
      try {
          const displayName = `${profileData.firstName || ''} ${profileData.lastName || ''}`.trim() || profileData.displayName;
          const address = `${profileData.street || ''}, ${profileData.zip || ''} ${profileData.city || ''}, ${profileData.country || ''}`;

          await updateDoc(doc(db, 'users', user.id), {
              ...profileData,
              displayName,
              address
          });
          
          showAlert({ type: 'success', message: t('common.success') });
          setShowProfileModal(false);
      } catch (err) {
          console.error(err);
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  return (
    <div className="pt-32 pb-20 px-6 max-w-7xl mx-auto bg-[#faf9f6] min-h-screen">
        
        {/* HEADER */}
        <div className="flex flex-col md:flex-row justify-between items-end mb-12 gap-6">
            <div>
                <div className="inline-flex items-center gap-2 bg-stone-900 text-white px-3 py-1 rounded-full text-xs font-bold mb-4 shadow-lg">
                    <Briefcase size={12} /> Vorstands-Dashboard
                </div>
                <h1 className="text-4xl font-display font-bold italic text-stone-900 mb-2">
                    {t('dash.welcome')}, {user.displayName}
                </h1>
                <p className="text-stone-500">Übersicht über Verein, Finanzen und Anfragen.</p>
            </div>
            
            <div className="flex items-center gap-3">
                {/* Year Selector */}
                <div className="bg-white px-4 py-3 rounded-2xl shadow-sm border border-stone-100 flex items-center gap-3">
                    <CalendarDays size={18} className="text-primary"/>
                    <select 
                        value={selectedYear} 
                        onChange={(e) => setSelectedYear(parseInt(e.target.value))}
                        className="bg-transparent font-bold text-stone-800 outline-none cursor-pointer"
                    >
                        {Array.from({length: 5}, (_, i) => new Date().getFullYear() - i).map(y => (
                            <option key={y} value={y}>{y}</option>
                        ))}
                    </select>
                </div>

                <button 
                    onClick={handleOpenProfile}
                    className="p-3 bg-white rounded-2xl shadow-sm border border-stone-100 hover:border-primary/50 transition-colors group"
                    title={t('profile.edit')}
                >
                    <UserCog size={20} className="text-stone-400 group-hover:text-primary"/>
                </button>
            </div>
        </div>

        {/* --- STATS & ANALYTICS SECTION --- */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            
            {/* 1. Paid Invoices (Clickable) */}
            <motion.div 
                whileHover={{ y: -5 }}
                onClick={() => setShowInvoiceListModal('PAID')}
                className="bg-emerald-50 p-6 rounded-3xl border border-emerald-100 cursor-pointer shadow-sm hover:shadow-md transition-all group"
            >
                <div className="flex justify-between items-start mb-2">
                    <p className="text-emerald-600 font-bold text-xs uppercase tracking-widest">Bezahlt ({selectedYear})</p>
                    <div className="bg-white p-2 rounded-full shadow-sm opacity-50 group-hover:opacity-100 transition-opacity">
                        <CheckCircle2 size={16} className="text-emerald-500"/>
                    </div>
                </div>
                <div className="flex items-end gap-2">
                    <h3 className="text-3xl font-display font-bold text-emerald-900">{stats.paidCount}</h3>
                    <span className="text-sm font-bold text-emerald-600/60 mb-1">Rechnungen</span>
                </div>
                <p className="text-emerald-700/60 text-sm mt-1 font-mono">{stats.totalRevenue.toLocaleString()} CHF</p>
            </motion.div>
            
            {/* 2. Open Invoices (Clickable) */}
            <motion.div 
                whileHover={{ y: -5 }}
                onClick={() => setShowInvoiceListModal('OPEN')}
                className="bg-amber-50 p-6 rounded-3xl border border-amber-100 cursor-pointer shadow-sm hover:shadow-md transition-all group"
            >
                <div className="flex justify-between items-start mb-2">
                    <p className="text-amber-600 font-bold text-xs uppercase tracking-widest">Offen ({selectedYear})</p>
                    <div className="bg-white p-2 rounded-full shadow-sm opacity-50 group-hover:opacity-100 transition-opacity">
                        <AlertCircle size={16} className="text-amber-500"/>
                    </div>
                </div>
                <div className="flex items-end gap-2">
                    <h3 className="text-3xl font-display font-bold text-amber-900">{stats.openCount}</h3>
                    <span className="text-sm font-bold text-amber-600/60 mb-1">Rechnungen</span>
                </div>
                <p className="text-amber-700/60 text-sm mt-1 font-mono">{stats.openRevenue.toLocaleString()} CHF</p>
            </motion.div>

            {/* 3. Search Bar */}
            <div className="bg-white p-6 rounded-3xl border border-stone-100 lg:col-span-2 shadow-sm flex flex-col">
                <div className="flex items-center gap-2 mb-4">
                    <Search size={18} className="text-stone-400"/>
                    <input 
                        type="text" 
                        placeholder="Mitglied oder Nachbarschaft suchen..." 
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full bg-transparent outline-none font-bold text-stone-800 placeholder-stone-300"
                    />
                </div>
                {searchTerm ? (
                    <div className="space-y-2 max-h-32 overflow-y-auto custom-scrollbar flex-1">
                        {searchResults.users.map(u => (
                            <div 
                                key={u.id} 
                                onClick={() => setSelectedMember(u)}
                                className="flex justify-between items-center text-sm p-2 hover:bg-stone-50 rounded-lg cursor-pointer"
                            >
                                <div className="flex items-center gap-2">
                                    <div className="w-6 h-6 rounded-full bg-stone-100 flex items-center justify-center text-[10px] font-bold text-stone-500">
                                        {u.displayName?.charAt(0)}
                                    </div>
                                    <span className="font-bold">{u.displayName}</span>
                                </div>
                                <span className={`text-[10px] px-2 py-0.5 rounded ${u.membershipStatus === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-stone-100 text-stone-500'}`}>{u.membershipStatus}</span>
                            </div>
                        ))}
                        {searchResults.neighborhoods.map(n => (
                            <div key={n.id} className="flex justify-between items-center text-sm p-2 hover:bg-stone-50 rounded-lg cursor-default">
                                <span className="font-bold flex items-center gap-1"><MapPin size={12}/> {n.name}</span>
                                <span className="text-xs text-stone-400">{neighborhoodCity(n)}</span>
                            </div>
                        ))}
                        {searchResults.users.length === 0 && searchResults.neighborhoods.length === 0 && (
                            <p className="text-stone-400 text-xs italic">Keine Ergebnisse.</p>
                        )}
                    </div>
                ) : (
                    <div className="flex-1 flex items-center justify-center text-stone-300 text-sm italic">
                        <p>Suche nach Mitgliedern für Details...</p>
                    </div>
                )}
            </div>
        </div>

        {/* --- CHARTS ROW --- */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-12">
            
            {/* Global Payment % */}
            <div className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm flex flex-col justify-center items-center text-center">
                <h4 className="text-stone-500 text-xs font-bold uppercase tracking-widest mb-4">Zahlungsquote {selectedYear}</h4>
                <div className="relative w-40 h-40 flex items-center justify-center">
                    <svg className="w-full h-full transform -rotate-90">
                        <circle cx="80" cy="80" r="70" stroke="#f5f5f4" strokeWidth="12" fill="transparent" />
                        <circle cx="80" cy="80" r="70" stroke={stats.paidPercentage > 80 ? '#10b981' : stats.paidPercentage > 50 ? '#f59e0b' : '#f43f5e'} strokeWidth="12" fill="transparent" strokeDasharray={440} strokeDashoffset={440 - (440 * stats.paidPercentage) / 100} className="transition-all duration-1000" />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center">
                        <span className="text-4xl font-display font-bold text-stone-900">{stats.paidPercentage}%</span>
                        <span className="text-[10px] text-stone-400 font-bold uppercase">Bezahlt</span>
                    </div>
                </div>
            </div>

            {/* Top 5 Neighborhoods */}
            <div className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="flex items-center gap-2 mb-6">
                    <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg"><TrendingUp size={16}/></div>
                    <h4 className="font-bold text-stone-900 text-sm">Top 5 Quartiere (CHF)</h4>
                </div>
                <div className="h-48 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={neighborhoodAnalytics.top5} layout="vertical" margin={{ left: 0, right: 20 }}>
                            <CartesianGrid horizontal={false} stroke="#f5f5f4" />
                            <XAxis type="number" hide />
                            <YAxis dataKey="name" type="category" width={80} tick={{fontSize: 10}} interval={0} />
                            <Tooltip cursor={{fill: '#f5f5f4'}} contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)'}} />
                            <Bar dataKey="value" fill="#10b981" radius={[0, 4, 4, 0]} barSize={16} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Bottom 5 Neighborhoods */}
            <div className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="flex items-center gap-2 mb-6">
                    <div className="p-2 bg-rose-50 text-rose-600 rounded-lg"><TrendingDown size={16}/></div>
                    <h4 className="font-bold text-stone-900 text-sm">Geringste Beiträge (CHF)</h4>
                </div>
                <div className="h-48 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={neighborhoodAnalytics.bottom5} layout="vertical" margin={{ left: 0, right: 20 }}>
                            <CartesianGrid horizontal={false} stroke="#f5f5f4" />
                            <XAxis type="number" hide />
                            <YAxis dataKey="name" type="category" width={80} tick={{fontSize: 10}} interval={0} />
                            <Tooltip cursor={{fill: '#f5f5f4'}} contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)'}} />
                            <Bar dataKey="value" fill="#fb7185" radius={[0, 4, 4, 0]} barSize={16} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>

        </div>

        {/* MAIN CONTENT GRID (Protocols & Inquiries) */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            
            {/* LEFT: Protocols */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm h-[600px] flex flex-col">
                <h3 className="text-xl font-bold flex items-center gap-2 mb-6"><FileText size={20} className="text-primary"/> Vorstandsprotokolle</h3>
                
                <div className="overflow-y-auto custom-scrollbar flex-1 space-y-3">
                    {meetings.map(m => (
                        <div key={m.id} onClick={() => setSelectedMeeting(m)} className="p-4 rounded-2xl border border-stone-100 hover:border-primary/30 hover:shadow-md transition-all cursor-pointer group">
                            <div className="flex justify-between items-start mb-2">
                                <h4 className="font-bold text-stone-800 group-hover:text-primary transition-colors">{m.title}</h4>
                                <span className="text-[10px] font-bold bg-stone-100 px-2 py-1 rounded text-stone-500">{new Date(m.date).toLocaleDateString()}</span>
                            </div>
                            <div className="text-xs text-stone-500 line-clamp-2">
                                {m.agendaItems?.map((item, i) => `${i+1}. ${item.title}`).join(', ')}
                            </div>
                        </div>
                    ))}
                    {meetings.length === 0 && <p className="text-stone-400 italic text-center py-10">Keine Protokolle vorhanden.</p>}
                </div>
            </div>

            {/* RIGHT: Inquiries */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm h-[600px] flex flex-col">
                <h3 className="text-xl font-bold flex items-center gap-2 mb-6"><MessageSquare size={20} className="text-blue-500"/> Anfragen & Feedback</h3>
                
                <div className="overflow-y-auto custom-scrollbar flex-1 space-y-3">
                    {inquiries.map(req => (
                        <div key={req.id} className="p-4 rounded-2xl bg-stone-50 border border-stone-100">
                            <div className="flex justify-between items-start mb-2">
                                <div className="flex items-center gap-2">
                                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase ${req.type === 'DONATION' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'}`}>{req.type}</span>
                                    <span className="text-xs font-bold text-stone-600">{req.userName}</span>
                                </div>
                                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${req.status === 'DONE' ? 'bg-green-200 text-green-800' : req.status === 'OPEN' ? 'bg-red-100 text-red-600' : 'bg-stone-200'}`}>{req.status}</span>
                            </div>
                            <h5 className="font-bold text-sm mb-1">{req.subject}</h5>
                            <p className="text-xs text-stone-500 leading-relaxed line-clamp-3">{req.message}</p>
                            {req.adminNote && (
                                <div className="mt-3 pl-3 border-l-2 border-stone-300">
                                    <p className="text-[10px] text-stone-400 uppercase font-bold">Admin Notiz</p>
                                    <p className="text-xs text-stone-600 italic">{req.adminNote}</p>
                                </div>
                            )}
                        </div>
                    ))}
                    {inquiries.length === 0 && <p className="text-stone-400 italic text-center py-10">Keine Anfragen vorhanden.</p>}
                </div>
            </div>
        </div>

        {/* MODALS */}

        {/* 1. MEMBER DETAIL MODAL */}
        <AnimatePresence>
            {selectedMember && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-lg rounded-[2.5rem] p-8 shadow-2xl relative">
                        <button onClick={() => setSelectedMember(null)} className="absolute top-6 right-6 p-2 bg-stone-50 rounded-full hover:bg-stone-100 text-stone-500"><X size={20}/></button>
                        
                        <div className="flex flex-col items-center mb-6">
                            <div className="w-24 h-24 bg-stone-100 rounded-full flex items-center justify-center text-3xl font-bold text-stone-400 mb-4 overflow-hidden border-4 border-white shadow-md">
                                {selectedMember.photoFileName ? <img src={selectedMember.photoFileName} className="w-full h-full object-cover"/> : selectedMember.displayName?.charAt(0)}
                            </div>
                            <h3 className="text-2xl font-bold text-stone-900">{selectedMember.displayName}</h3>
                            <span className={`text-xs font-bold px-3 py-1 rounded-full mt-2 ${selectedMember.membershipStatus === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-stone-100 text-stone-500'}`}>
                                {selectedMember.membershipStatus}
                            </span>
                        </div>

                        <div className="space-y-4 bg-stone-50 p-6 rounded-2xl border border-stone-100">
                            <div className="flex items-center gap-3 text-sm">
                                <Mail size={16} className="text-stone-400"/> 
                                <span className="font-medium">{selectedMember.email}</span>
                            </div>
                            <div className="flex items-center gap-3 text-sm">
                                <Phone size={16} className="text-stone-400"/> 
                                <span className="font-medium">{selectedMember.phone || '-'}</span>
                            </div>
                            <div className="flex items-center gap-3 text-sm">
                                <MapPin size={16} className="text-stone-400"/> 
                                <span className="font-medium">{selectedMember.address || '-'}</span>
                            </div>
                            <div className="flex items-center gap-3 text-sm">
                                <CreditCard size={16} className="text-stone-400"/> 
                                <span className="font-medium">{selectedMember.billingGroup || 'STANDARD'}</span>
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* 2. INVOICE LIST MODAL (Drilldown) */}
        <AnimatePresence>
            {showInvoiceListModal && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[80vh]">
                        <div className={`p-6 flex justify-between items-center ${showInvoiceListModal === 'PAID' ? 'bg-emerald-50' : 'bg-amber-50'}`}>
                            <h3 className={`font-bold text-lg flex items-center gap-2 ${showInvoiceListModal === 'PAID' ? 'text-emerald-800' : 'text-amber-800'}`}>
                                {showInvoiceListModal === 'PAID' ? <CheckCircle2 size={20}/> : <AlertCircle size={20}/>}
                                {showInvoiceListModal === 'PAID' ? 'Bezahlte Rechnungen' : 'Offene Rechnungen'} ({selectedYear})
                            </h3>
                            <button onClick={() => setShowInvoiceListModal(null)} className="p-2 bg-white/50 rounded-full hover:bg-white transition-colors"><X size={20}/></button>
                        </div>
                        
                        <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
                            <table className="w-full text-left text-sm">
                                <thead className="text-xs font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                    <tr>
                                        <th className="pb-3">Mitglied</th>
                                        <th className="pb-3">Datum</th>
                                        <th className="pb-3 text-right">Betrag</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-stone-50">
                                    {(showInvoiceListModal === 'PAID' ? stats.paidInvoices : stats.openInvoices).map(inv => {
                                        const u = users.find(user => user.id === inv.userId);
                                        return (
                                            <tr key={inv.id} className="hover:bg-stone-50">
                                                <td className="py-3 font-bold text-stone-800">{u?.displayName || 'Unknown'}</td>
                                                <td className="py-3 text-stone-500 font-mono text-xs">{new Date(inv.timestamp?.toDate()).toLocaleDateString()}</td>
                                                <td className="py-3 text-right font-mono font-bold">{inv.amount} {inv.currency}</td>
                                            </tr>
                                        )
                                    })}
                                    {(showInvoiceListModal === 'PAID' ? stats.paidInvoices : stats.openInvoices).length === 0 && (
                                        <tr><td colSpan={3} className="text-center py-8 text-stone-400 italic">Keine Einträge.</td></tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* 3. PROTOCOL MODAL (READ ONLY) */}
        <AnimatePresence>
            {selectedMeeting && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
                        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                            <div>
                                <h3 className="font-bold text-lg text-stone-900">{selectedMeeting.title}</h3>
                                <p className="text-xs text-stone-500">{new Date(selectedMeeting.date).toLocaleDateString()}</p>
                            </div>
                            <button onClick={() => setSelectedMeeting(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                        </div>
                        <div className="p-8 overflow-y-auto custom-scrollbar flex-1 space-y-8">
                            <div>
                                <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-3 border-b border-stone-100 pb-2">Teilnehmer</h4>
                                <div className="flex flex-wrap gap-2">
                                    {selectedMeeting.attendees?.map((att, i) => (
                                        <div key={i} className={`text-xs px-3 py-1.5 rounded-lg border ${att.present ? 'bg-white border-stone-200 text-stone-800' : 'bg-stone-50 border-stone-100 text-stone-400 line-through'}`}>
                                            {att.name}
                                        </div>
                                    ))}
                                </div>
                            </div>
                            <div>
                                <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">Agenda & Beschlüsse</h4>
                                <div className="space-y-6">
                                    {selectedMeeting.agendaItems?.map((item, i) => (
                                        <div key={i}>
                                            <h5 className="font-bold text-stone-900 text-sm flex items-center gap-2 mb-2">
                                                <span className="bg-stone-100 w-5 h-5 flex items-center justify-center rounded-full text-[10px]">{i+1}</span> 
                                                {item.title}
                                            </h5>
                                            <div className="pl-7 text-sm text-stone-600 leading-relaxed prose prose-sm" dangerouslySetInnerHTML={{ __html: item.content }} />
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* 4. PROFILE EDIT MODAL (Reused) */}
        <AnimatePresence>
            {showProfileModal && (
                <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div 
                        initial={{ scale: 0.95, opacity: 0 }} 
                        animate={{ scale: 1, opacity: 1 }} 
                        exit={{ scale: 0.95, opacity: 0 }}
                        className="bg-white w-full max-w-xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[90vh]"
                    >
                        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                            <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
                                <UserCog className="text-primary"/> {t('profile.edit')}
                            </h3>
                            <button onClick={() => setShowProfileModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors">
                                <X size={20}/>
                            </button>
                        </div>
                        
                        <div className="flex-1 overflow-y-auto p-8 space-y-6 custom-scrollbar">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.firstName')}</label>
                                    <input value={profileData.firstName || ''} onChange={e => setProfileData({...profileData, firstName: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.lastName')}</label>
                                    <input value={profileData.lastName || ''} onChange={e => setProfileData({...profileData, lastName: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.phone')}</label>
                                <input value={profileData.phone || ''} onChange={e => setProfileData({...profileData, phone: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.street')}</label>
                                <input value={profileData.street || ''} onChange={e => setProfileData({...profileData, street: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                            </div>
                            <div className="grid grid-cols-3 gap-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.zip')}</label>
                                    <input value={profileData.zip || ''} onChange={e => setProfileData({...profileData, zip: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                                </div>
                                <div className="col-span-2">
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.city')}</label>
                                    <input value={profileData.city || ''} onChange={e => setProfileData({...profileData, city: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-medium outline-none" />
                                </div>
                            </div>
                        </div>

                        <div className="p-6 border-t border-stone-100 bg-stone-50 flex justify-end gap-3">
                            <button onClick={() => setShowProfileModal(false)} className="px-6 py-3 rounded-xl font-bold text-stone-500 hover:bg-stone-200 transition-colors text-sm">{t('common.cancel')}</button>
                            <button onClick={handleUpdateProfile} className="px-8 py-3 bg-primary text-white rounded-xl font-bold shadow-lg hover:scale-105 transition-all text-sm flex items-center gap-2"><Save size={16}/> {t('common.save_changes')}</button>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

    </div>
  );
};

export default BoardDashboard;
