
import React, { useState, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile, Payment, Task, GlobalPaymentSettings, Expense, Neighborhood } from '../types';
import { db, storage, auth } from '../services/firebase';
import { collection, query, where, orderBy, onSnapshot, doc, updateDoc, addDoc, serverTimestamp, getDocs } from '@/services/supabase-bridge';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';
import { 
  Users, 
  Banknote, 
  Hammer, 
  MapPin, 
  CheckCircle2, 
  X, 
  Search, 
  Plus, 
  Camera, 
  Upload, 
  Briefcase, 
  ArrowUpRight, 
  ArrowDownLeft, 
  Filter, 
  Loader2, 
  Globe, 
  UserPlus, 
  Save, 
  CheckSquare, 
  Clock 
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useFeedback } from '../context/FeedbackContext';

interface RepresentativeDashboardProps {
  user: UserProfile;
}

const RepresentativeDashboard: React.FC<RepresentativeDashboardProps> = ({ user }) => {
  const { t, setLanguage, language } = useTranslation();
  const { showAlert, showConfirm, showPrompt } = useFeedback();
  
  // View State
  const [activeTab, setActiveTab] = useState<'INKASO' | 'KASA' | 'MIREMBAJTJA'>('INKASO');
  
  // Data State
  const [residents, setResidents] = useState<UserProfile[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  
  // Inkasim State
  const [searchTerm, setSearchTerm] = useState('');
  const [showPayModal, setShowPayModal] = useState(false);
  const [selectedResident, setSelectedResident] = useState<UserProfile | null>(null);
  const [customAmount, setCustomAmount] = useState<string>('12');

  // Ad-Hoc Member State
  const [showMemberModal, setShowMemberModal] = useState(false);
  const [newMember, setNewMember] = useState({
      firstName: '',
      lastName: '',
      phone: '',
      street: '',
      city: 'Koretin',
      birthdate: '',
      neighborhoodId: ''
  });

  // Expense State
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [newExpense, setNewExpense] = useState({ vendor: '', amount: '', description: '', date: new Date().toISOString().split('T')[0] });
  const expenseFileRef = useRef<HTMLInputElement>(null);
  const [expenseImage, setExpenseImage] = useState<string>('');
  const [isUploading, setIsUploading] = useState(false);

  // Task State
  const [newTaskTitle, setNewTaskTitle] = useState('');

  const currentYear = new Date().getFullYear();

  useEffect(() => {
    // 1. Fetch All Residents (Removed billingGroup filter to allow finding everyone)
    const qResidents = query(collection(db, 'users'), orderBy('displayName'));
    const unsubResidents = onSnapshot(qResidents, (snap) => {
        setResidents(snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile)));
    });

    // 2. Fetch Neighborhoods (For Registration)
    const qNeighborhoods = query(collection(db, 'neighborhoods'), orderBy('name'));
    const unsubNeighborhoods = onSnapshot(qNeighborhoods, (snap) => {
        setNeighborhoods(snap.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)));
    });

    // 3. Fetch Payments (Current Year)
    const qPayments = query(collection(db, 'payments'), orderBy('timestamp', 'desc'));
    const unsubPayments = onSnapshot(qPayments, (snap) => {
        setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() } as Payment)));
    });

    // 4. Fetch Expenses
    const qExpenses = query(collection(db, 'expenses'), orderBy('date', 'desc'));
    const unsubExpenses = onSnapshot(qExpenses, (snap) => {
        setExpenses(snap.docs.map(d => ({ id: d.id, ...d.data() } as Expense)));
    });

    // 5. Fetch Tasks (Assigned to Rep OR Created by Rep)
    const qTasks = query(collection(db, 'tasks'), orderBy('createdAt', 'desc'));
    const unsubTasks = onSnapshot(qTasks, (snap) => {
        setTasks(snap.docs.map(d => ({ id: d.id, ...d.data() } as Task)));
    });

    return () => { unsubResidents(); unsubNeighborhoods(); unsubPayments(); unsubExpenses(); unsubTasks(); };
  }, []);

  // DERIVED DATA
  const filteredResidents = useMemo(() => {
      const term = searchTerm.toLowerCase();
      // Show only if searching, or limit initial list to avoid overload visually
      if (!term) return residents.slice(0, 50); 
      return residents.filter(r => 
          r.displayName?.toLowerCase().includes(term) ||
          r.firstName?.toLowerCase().includes(term) ||
          r.lastName?.toLowerCase().includes(term) ||
          r.email?.toLowerCase().includes(term)
      );
  }, [residents, searchTerm]);

  const cashBoxStats = useMemo(() => {
      // 1. Cash In: Payments collected by this user via CASH
      const cashIn = payments
        .filter(p => p.method === 'CASH' && p.status === 'PAID' && p.currency === 'EUR' && p.collectedBy === user.id)
        .reduce((sum, p) => sum + p.amount, 0);

      // 2. Cash Out: Expenses paid by this user (where paymentAccountCode is 1001 - Kasse EUR)
      const cashOut = expenses
        .filter(e => e.currency === 'EUR' && e.paymentAccountCode === '1001' && e.status === 'PAID')
        .reduce((sum, e) => sum + e.amount, 0);

      return { cashIn, cashOut, balance: cashIn - cashOut };
  }, [payments, expenses, user.id]);

  // ACTIONS
  const handleOpenPayModal = (resident: UserProfile) => {
      setSelectedResident(resident);
      setCustomAmount('12'); // Default Koretin Fee
      setShowPayModal(true);
  };

  const handleCollectPayment = async () => {
      if (!selectedResident) return;
      const amount = parseFloat(customAmount);
      if (!amount) return;

      try {
          await addDoc(collection(db, 'payments'), {
              userId: selectedResident.id,
              amount: amount,
              currency: 'EUR',
              method: 'CASH',
              status: 'PAID',
              type: 'FEE',
              invoiceType: 'MEMBERSHIP',
              billingYear: currentYear,
              timestamp: serverTimestamp(),
              paidAt: new Date().toISOString(),
              description: `Anëtarësia ${currentYear} (Cash)`,
              invoiceNumber: `CSH-${Date.now().toString().slice(-6)}`,
              collectedBy: user.id
          });

          // Update user status if pending
          if (selectedResident.membershipStatus !== 'ACTIVE') {
              await updateDoc(doc(db, 'users', selectedResident.id), { membershipStatus: 'ACTIVE' });
          }

          showAlert({ type: 'success', message: t('common.success') });
          setShowPayModal(false);
      } catch (e: any) {
          console.error(e);
          showAlert({ type: 'error', message: t('common.error') + ': ' + e.message });
      }
  };

  const handleRegisterMember = async () => {
      if (!newMember.firstName || !newMember.lastName) {
          showAlert({ type: 'error', message: 'Name required.' });
          return;
      }
      if (!newMember.neighborhoodId) {
          showAlert({ type: 'error', message: 'Neighborhood required.' });
          return;
      }

      try {
          await addDoc(collection(db, 'users'), {
              firstName: newMember.firstName,
              lastName: newMember.lastName,
              displayName: `${newMember.firstName} ${newMember.lastName}`,
              phone: newMember.phone,
              street: newMember.street,
              city: newMember.city,
              country: 'Kosovo',
              birthdate: newMember.birthdate,
              neighborhoodId: newMember.neighborhoodId,
              membershipStatus: 'PENDING',
              role: 'MEMBER',
              billingGroup: 'KOSOVO',
              joinedAt: new Date().toISOString(),
              email: '', // Placeholder
              profileComplete: false,
              tenantId: 'koretini'
          });
          showAlert({ type: 'success', message: t('common.success') });
          setShowMemberModal(false);
          setNewMember({ firstName: '', lastName: '', phone: '', street: '', city: 'Koretin', birthdate: '', neighborhoodId: '' });
      } catch (e: any) {
          console.error(e);
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  const handleExpenseImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setIsUploading(true);
      try {
          const storageRef = ref(storage, `receipts/${Date.now()}_${file.name}`);
          const snapshot = await uploadBytes(storageRef, file);
          const url = await getDownloadURL(snapshot.ref);
          setExpenseImage(url);
      } catch (err) { console.error(err); } 
      finally { setIsUploading(false); }
  };

  const handleSaveExpense = async () => {
      if (!newExpense.vendor || !newExpense.amount) return;
      try {
          await addDoc(collection(db, 'expenses'), {
              vendor: newExpense.vendor,
              amount: parseFloat(newExpense.amount),
              currency: 'EUR',
              date: newExpense.date,
              description: newExpense.description,
              categoryAccountCode: '4000', // Default Material
              paymentAccountCode: '1001', // CASH EUR (Kasse Euro) - Corrected for Reps
              status: 'PAID', // Immediately paid via cash
              receiptUrl: expenseImage,
              bookedInJournal: false,
              createdAt: serverTimestamp(),
              createdBy: user.id
          });
          showAlert({ type: 'success', message: t('common.success') });
          setShowExpenseModal(false);
          setNewExpense({ vendor: '', amount: '', description: '', date: new Date().toISOString().split('T')[0] });
          setExpenseImage('');
      } catch (e: any) {
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  const handleBankDeposit = async () => {
      const amountStr = await showPrompt({
          title: t('rep.deposit'),
          message: "Amount (EUR)?",
          placeholder: "0.00"
      });
      if (!amountStr) return;
      
      const amount = parseFloat(amountStr);
      if (amount > cashBoxStats.balance) {
          showAlert({ type: 'error', message: 'Insufficient funds.' });
          return;
      }

      await addDoc(collection(db, 'expenses'), {
          vendor: 'Banka (Depozitim)',
          amount: amount,
          currency: 'EUR',
          date: new Date().toISOString().split('T')[0],
          description: `Dorëzim i parave të inkasuara`,
          categoryAccountCode: '1020', // Transfer to Bank
          paymentAccountCode: '1001', // From Cash EUR
          status: 'PAID',
          bookedInJournal: false,
          createdAt: serverTimestamp(),
          createdBy: user.id
      });
      showAlert({ type: 'success', message: t('common.success') });
  };

  // Task Actions
  const handleCreateTask = async () => {
      if (!newTaskTitle.trim()) return;
      await addDoc(collection(db, 'tasks'), {
          title: newTaskTitle,
          status: 'TODO',
          priority: 'MEDIUM',
          createdBy: user.id,
          assignedToName: user.displayName, // Self assign or open
          createdAt: serverTimestamp()
      });
      setNewTaskTitle('');
      showAlert({ type: 'success', message: t('common.success') });
  };

  const handleUpdateTaskStatus = async (taskId: string, status: 'DONE' | 'IN_PROGRESS') => {
      await updateDoc(doc(db, 'tasks', taskId), { status });
  };

  // Helper to check if paid for current year
  const hasPaidCurrentYear = (userId: string) => {
      return payments.some(p => 
          p.userId === userId && 
          p.status === 'PAID' && 
          (p.billingYear === currentYear || p.timestamp?.toDate().getFullYear() === currentYear)
      );
  };

  return (
    <div className="bg-stone-100 min-h-screen pb-24">
        {/* TOP HEADER */}
        <div className="bg-stone-900 text-white pt-44 md:pt-48 pb-8 px-6 rounded-b-[2.5rem] shadow-xl relative z-10">
            {/* Language Switcher */}
            <div className="absolute top-6 right-6 flex gap-1 bg-white/10 p-1 rounded-lg backdrop-blur-sm">
                {['sq', 'de', 'en'].map(l => ( 
                    <button 
                        key={l} 
                        onClick={() => setLanguage(l as any)} 
                        className={`px-2 py-1 rounded-md text-[10px] font-bold uppercase transition-all ${language === l ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-300 hover:text-white'}`}
                    >
                        {l}
                    </button> 
                ))}
            </div>

            <div className="flex justify-between items-center mb-6 mt-4">
                <div>
                    <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-1">{t('rep.title')}</p>
                    <h1 className="text-3xl font-display font-bold italic">{user.displayName}</h1>
                </div>
                <div className="bg-white/10 p-2 rounded-xl">
                    <Briefcase size={24} className="text-primary"/>
                </div>
            </div>
            
            {/* CASH BOX SUMMARY CARD */}
            <div className="bg-white/10 border border-white/10 p-6 rounded-2xl backdrop-blur-sm flex justify-between items-center">
                <div>
                    <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-1">{t('rep.cash_balance')}</p>
                    <p className="text-4xl font-mono font-bold">{cashBoxStats.balance.toFixed(2)} <span className="text-lg text-stone-400">EUR</span></p>
                </div>
                <button onClick={handleBankDeposit} className="bg-white text-stone-900 px-4 py-2 rounded-xl text-xs font-bold hover:bg-stone-200 transition-colors">
                    {t('rep.deposit')}
                </button>
            </div>
        </div>

        {/* NAVIGATION TABS */}
        <div className="px-6 -mt-6 relative z-20">
            <div className="bg-white rounded-2xl shadow-lg p-2 flex gap-2">
                <button onClick={() => setActiveTab('INKASO')} className={`flex-1 py-3 rounded-xl font-bold text-sm flex flex-col items-center gap-1 transition-all ${activeTab === 'INKASO' ? 'bg-stone-900 text-white shadow-md' : 'text-stone-400 hover:bg-stone-50'}`}>
                    <Users size={18}/> {t('rep.collection')}
                </button>
                <button onClick={() => setActiveTab('KASA')} className={`flex-1 py-3 rounded-xl font-bold text-sm flex flex-col items-center gap-1 transition-all ${activeTab === 'KASA' ? 'bg-stone-900 text-white shadow-md' : 'text-stone-400 hover:bg-stone-50'}`}>
                    <Banknote size={18}/> {t('rep.expenses')}
                </button>
                <button onClick={() => setActiveTab('MIREMBAJTJA')} className={`flex-1 py-3 rounded-xl font-bold text-sm flex flex-col items-center gap-1 transition-all ${activeTab === 'MIREMBAJTJA' ? 'bg-stone-900 text-white shadow-md' : 'text-stone-400 hover:bg-stone-50'}`}>
                    <Hammer size={18}/> {t('rep.tasks')}
                </button>
            </div>
        </div>

        {/* CONTENT AREA */}
        <div className="p-6">
            
            {/* --- INKASO TAB --- */}
            {activeTab === 'INKASO' && (
                <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
                    <button onClick={() => setShowMemberModal(true)} className="w-full bg-primary text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-rose-200 mb-4">
                        <UserPlus size={20} /> {t('rep.register_member')}
                    </button>

                    <div className="relative">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" size={18}/>
                        <input 
                            placeholder={t('rep.search_member')}
                            value={searchTerm}
                            onChange={e => setSearchTerm(e.target.value)}
                            className="w-full pl-12 pr-4 py-4 bg-white rounded-2xl border-none shadow-sm text-stone-800 font-bold outline-none"
                        />
                    </div>

                    <div className="space-y-3">
                        {filteredResidents.map(r => {
                            const isPaid = hasPaidCurrentYear(r.id);
                            return (
                                <div key={r.id} className="bg-white p-4 rounded-2xl shadow-sm flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-white ${isPaid ? 'bg-green-500' : 'bg-stone-300'}`}>
                                            {r.displayName?.charAt(0)}
                                        </div>
                                        <div>
                                            <p className="font-bold text-stone-900 text-sm">{r.displayName}</p>
                                            <p className="text-xs text-stone-400 flex items-center gap-1"><MapPin size={10}/> {r.city || 'Koretin'}</p>
                                        </div>
                                    </div>
                                    {isPaid ? (
                                        <span className="bg-green-50 text-green-600 px-3 py-1 rounded-lg text-xs font-bold flex items-center gap-1">
                                            <CheckCircle2 size={12}/> {t('rep.paid')}
                                        </span>
                                    ) : (
                                        <button 
                                            onClick={() => handleOpenPayModal(r)}
                                            className="bg-stone-900 text-white px-4 py-2 rounded-xl text-xs font-bold shadow-lg hover:scale-105 transition-transform"
                                        >
                                            {t('rep.collect')}
                                        </button>
                                    )}
                                </div>
                            )
                        })}
                        {filteredResidents.length === 0 && <p className="text-center text-stone-400 italic mt-8">{t('common.search')}</p>}
                    </div>
                </motion.div>
            )}

            {/* --- KASA / SHPENZIME TAB --- */}
            {activeTab === 'KASA' && (
                <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
                    <button onClick={() => setShowExpenseModal(true)} className="w-full bg-white border-2 border-dashed border-stone-300 py-4 rounded-2xl text-stone-400 font-bold flex items-center justify-center gap-2 hover:border-primary hover:text-primary transition-all">
                        <Plus size={20}/> {t('rep.new_expense')}
                    </button>

                    <div className="space-y-3">
                        <h3 className="text-xs font-bold text-stone-400 uppercase tracking-widest ml-2">{t('rep.expense_history')}</h3>
                        {expenses.filter(e => e.createdBy === user.id).map(exp => (
                            <div key={exp.id} className="bg-white p-4 rounded-2xl shadow-sm flex items-center gap-4">
                                <div className="p-3 bg-rose-50 text-rose-600 rounded-xl">
                                    <ArrowUpRight size={20}/>
                                </div>
                                <div className="flex-1">
                                    <p className="font-bold text-stone-900 text-sm">{exp.vendor}</p>
                                    <p className="text-xs text-stone-400">{exp.description}</p>
                                </div>
                                <p className="font-mono font-bold text-rose-600">-{exp.amount} €</p>
                            </div>
                        ))}
                    </div>
                </motion.div>
            )}

            {/* --- MIREMBAJTJA / DETYRAT TAB --- */}
            {activeTab === 'MIREMBAJTJA' && (
                <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
                    {/* Create Task */}
                    <div className="flex gap-2">
                        <input 
                            value={newTaskTitle}
                            onChange={(e) => setNewTaskTitle(e.target.value)}
                            placeholder="Detyrë e re..."
                            className="flex-1 p-3 bg-white rounded-xl shadow-sm border-none outline-none"
                        />
                        <button onClick={handleCreateTask} className="bg-stone-900 text-white p-3 rounded-xl"><Plus/></button>
                    </div>

                    <div className="space-y-4">
                        {tasks.map(task => (
                            <div key={task.id} className="bg-white p-5 rounded-2xl shadow-sm border-l-4 border-l-primary">
                                <div className="flex justify-between items-start mb-2">
                                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${task.priority === 'HIGH' ? 'bg-red-100 text-red-600' : 'bg-stone-100 text-stone-500'}`}>{task.priority}</span>
                                    <span className="text-xs text-stone-400 flex items-center gap-1"><Clock size={10}/> {new Date(task.createdAt?.toDate()).toLocaleDateString()}</span>
                                </div>
                                <h4 className="font-bold text-stone-900 mb-1">{task.title}</h4>
                                {task.description && <p className="text-sm text-stone-500 mb-4">{task.description}</p>}
                                
                                {task.status !== 'DONE' ? (
                                    <button 
                                        onClick={() => handleUpdateTaskStatus(task.id, 'DONE')}
                                        className="w-full py-3 bg-stone-50 text-stone-600 font-bold rounded-xl text-xs hover:bg-stone-100 transition-colors flex items-center justify-center gap-2"
                                    >
                                        <CheckSquare size={14}/> Përfundo
                                    </button>
                                ) : (
                                    <div className="flex items-center gap-2 text-green-600 text-xs font-bold">
                                        <CheckCircle2 size={14}/> Përfunduar
                                    </div>
                                )}
                            </div>
                        ))}
                        {tasks.length === 0 && <p className="text-center text-stone-400 italic mt-8">{t('rep.no_tasks')}</p>}
                    </div>
                </motion.div>
            )}

        </div>

        {/* PAY MODAL */}
        <AnimatePresence>
            {showPayModal && selectedResident && (
                <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-stone-900/80 backdrop-blur-sm p-4">
                    <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} className="bg-white w-full max-w-sm rounded-[2rem] p-6 shadow-2xl relative">
                        <button onClick={() => setShowPayModal(false)} className="absolute top-4 right-4 p-2 bg-stone-100 rounded-full text-stone-500"><X size={18}/></button>
                        
                        <div className="text-center mb-6">
                            <div className="w-16 h-16 bg-stone-100 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl font-bold text-stone-400">
                                {selectedResident.displayName?.charAt(0)}
                            </div>
                            <h3 className="text-xl font-bold text-stone-900">{selectedResident.displayName}</h3>
                            <p className="text-sm text-stone-500">Inkasim për {currentYear}</p>
                        </div>

                        <div className="space-y-4 mb-6">
                            <div>
                                <label className="text-xs font-bold text-stone-400 uppercase">Shuma (EUR)</label>
                                <input 
                                    type="number" 
                                    value={customAmount} 
                                    onChange={e => setCustomAmount(e.target.value)} 
                                    className="w-full p-4 bg-stone-50 rounded-xl text-3xl font-bold text-center outline-none border-2 border-transparent focus:border-primary"
                                />
                            </div>
                        </div>

                        <button onClick={handleCollectPayment} className="w-full py-4 bg-green-500 text-white rounded-xl font-bold text-lg shadow-lg shadow-green-200 hover:scale-105 transition-transform flex items-center justify-center gap-2">
                            <CheckCircle2 size={24}/> {t('rep.collect')}
                        </button>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* MEMBER REGISTER MODAL */}
        <AnimatePresence>
            {showMemberModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-stone-900/80 backdrop-blur-sm p-4">
                    <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white w-full max-w-sm rounded-[2rem] p-6 shadow-2xl relative overflow-y-auto max-h-[90vh]">
                        <button onClick={() => setShowMemberModal(false)} className="absolute top-4 right-4 p-2 bg-stone-100 rounded-full text-stone-500"><X size={18}/></button>
                        
                        <h3 className="text-xl font-bold text-stone-900 mb-6">{t('rep.register_member')}</h3>
                        
                        <div className="space-y-4 mb-6">
                            <div className="grid grid-cols-2 gap-2">
                                <input placeholder={t('field.firstName')} value={newMember.firstName} onChange={e => setNewMember({...newMember, firstName: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                                <input placeholder={t('field.lastName')} value={newMember.lastName} onChange={e => setNewMember({...newMember, lastName: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                            </div>
                            <input placeholder={t('field.phone')} value={newMember.phone} onChange={e => setNewMember({...newMember, phone: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                            <input placeholder={t('field.street')} value={newMember.street} onChange={e => setNewMember({...newMember, street: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                            <input placeholder={t('field.city')} value={newMember.city} onChange={e => setNewMember({...newMember, city: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                            
                            <div>
                                <label className="text-xs font-bold text-stone-400 uppercase ml-1 block mb-1">{t('dash.neighborhood.title')}</label>
                                <select 
                                    value={newMember.neighborhoodId} 
                                    onChange={e => setNewMember({...newMember, neighborhoodId: e.target.value})}
                                    className="w-full p-3 bg-stone-50 rounded-xl outline-none"
                                >
                                    <option value="">{t('common.select')}</option>
                                    {neighborhoods.map(n => (
                                        <option key={n.id} value={n.id}>{n.name}</option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="text-xs font-bold text-stone-400 uppercase ml-1 block mb-1">{t('field.birthdate')}</label>
                                <input type="date" value={newMember.birthdate} onChange={e => setNewMember({...newMember, birthdate: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl outline-none" />
                            </div>
                        </div>

                        <button onClick={handleRegisterMember} className="w-full py-4 bg-primary text-white rounded-xl font-bold shadow-lg hover:scale-105 transition-transform flex items-center justify-center gap-2">
                            <Save size={18}/> {t('btn.save')}
                        </button>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* EXPENSE MODAL */}
        <AnimatePresence>
            {showExpenseModal && (
                <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-stone-900/80 backdrop-blur-sm p-4">
                    <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} className="bg-white w-full max-w-sm rounded-[2rem] p-6 shadow-2xl relative overflow-y-auto max-h-[90vh]">
                        <button onClick={() => setShowExpenseModal(false)} className="absolute top-4 right-4 p-2 bg-stone-100 rounded-full text-stone-500"><X size={18}/></button>
                        
                        <h3 className="text-xl font-bold text-stone-900 mb-6">{t('rep.new_expense')}</h3>

                        <div className="space-y-4 mb-6">
                            <div onClick={() => expenseFileRef.current?.click()} className="h-32 bg-stone-50 rounded-xl border-2 border-dashed border-stone-200 flex flex-col items-center justify-center cursor-pointer hover:border-primary transition-colors relative overflow-hidden">
                                {expenseImage ? <img src={expenseImage} className="w-full h-full object-cover" /> : <div className="flex flex-col items-center text-stone-400"><Camera size={24}/><span className="text-xs font-bold mt-1">Foto</span></div>}
                                {isUploading && <div className="absolute inset-0 bg-white/50 flex items-center justify-center"><Loader2 className="animate-spin text-primary"/></div>}
                                <input type="file" ref={expenseFileRef} hidden accept="image/*" onChange={handleExpenseImageUpload} />
                            </div>

                            <input placeholder={t('admin.expenses.vendor')} value={newExpense.vendor} onChange={e => setNewExpense({...newExpense, vendor: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl text-sm font-bold outline-none" />
                            <input type="number" placeholder={`${t('admin.finance.amount')} (EUR)`} value={newExpense.amount} onChange={e => setNewExpense({...newExpense, amount: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl text-lg font-bold outline-none" />
                            <textarea placeholder={t('admin.expenses.description')} value={newExpense.description} onChange={e => setNewExpense({...newExpense, description: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl text-sm outline-none h-20" />
                            <input type="date" value={newExpense.date} onChange={e => setNewExpense({...newExpense, date: e.target.value})} className="w-full p-3 bg-stone-50 rounded-xl text-sm outline-none" />
                        </div>

                        <button onClick={handleSaveExpense} className="w-full py-4 bg-stone-900 text-white rounded-xl font-bold shadow-lg hover:scale-105 transition-transform">
                            {t('btn.save')}
                        </button>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

    </div>
  );
};

export default RepresentativeDashboard;
