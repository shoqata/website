
import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Receipt, 
  Upload, 
  ScanLine, 
  CheckCircle2, 
  Loader2, 
  Trash2, 
  FileText,
  BookOpen,
  Keyboard,
  Tag,
  CreditCard
} from 'lucide-react';
import { db, storage } from '../services/firebase';
import { collection, addDoc, serverTimestamp, query, orderBy, onSnapshot, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { Expense, Account } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { analyzeReceiptImage } from '../services/geminiService';
import { useTranslation } from '../context/LanguageContext';

const AdminExpenses: React.FC = () => {
    const { t } = useTranslation();
    const { showAlert, showConfirm, showPrompt } = useFeedback();
    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [accounts, setAccounts] = useState<Account[]>([]);
    
    // UI State
    const [isScanning, setIsScanning] = useState(false);
    const [isFormOpen, setIsFormOpen] = useState(false);
    const [filter, setFilter] = useState<'ALL' | 'PENDING' | 'PAID'>('ALL');
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Form State
    const [formData, setFormData] = useState<Partial<Expense>>({
        vendor: '',
        amount: 0,
        currency: 'CHF',
        date: new Date().toISOString().split('T')[0],
        description: '',
        categoryAccountCode: '4000', // Default Materialaufwand
        paymentAccountCode: '1020', // Default Bank ZKB
        status: 'PENDING'
    });
    const [receiptPreview, setReceiptPreview] = useState<string | null>(null);

    useEffect(() => {
        const q = query(collection(db, 'expenses'), orderBy('date', 'desc'));
        const unsub = onSnapshot(q, (snap) => {
            setExpenses(snap.docs.map(d => ({ id: d.id, ...d.data() } as Expense)));
        });
        
        const qAcc = query(collection(db, 'accounting_accounts'), orderBy('code'));
        const unsubAcc = onSnapshot(qAcc, (snap) => {
            setAccounts(snap.docs.map(d => d.data() as Account));
        });

        return () => { unsub(); unsubAcc(); };
    }, []);

    const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Preview
        const reader = new FileReader();
        reader.onload = (re) => {
            setReceiptPreview(re.target?.result as string);
            setIsFormOpen(true);
            scanReceipt(re.target?.result as string);
        };
        reader.readAsDataURL(file);
    };

    const handleManualEntry = () => {
        resetForm();
        setIsFormOpen(true);
    };

    const scanReceipt = async (base64: string) => {
        setIsScanning(true);
        try {
            const resultJson = await analyzeReceiptImage(base64);
            if (resultJson) {
                const data = JSON.parse(resultJson);
                setFormData(prev => ({
                    ...prev,
                    vendor: data.vendor || '',
                    amount: data.amount || 0,
                    currency: data.currency || 'CHF',
                    date: data.date || new Date().toISOString().split('T')[0],
                    description: data.description || '',
                    categoryAccountCode: data.suggestedAccountCode || '4000'
                }));
                showAlert({ type: 'success', message: 'Beleg erfolgreich analysiert!' });
            }
        } catch (err) {
            console.error(err);
            showAlert({ type: 'error', message: 'KI-Analyse fehlgeschlagen. Bitte manuell eingeben.' });
        } finally {
            setIsScanning(false);
        }
    };

    const handleSaveExpense = async () => {
        if (!formData.vendor || !formData.amount) {
            showAlert({ type: 'error', message: 'Bitte Lieferant und Betrag angeben.' });
            return;
        }

        try {
            let receiptUrl = '';
            if (receiptPreview && fileInputRef.current?.files?.[0]) {
                const file = fileInputRef.current.files[0];
                const storageRef = ref(storage, `receipts/${Date.now()}_${file.name}`);
                const snap = await uploadBytes(storageRef, file);
                receiptUrl = await getDownloadURL(snap.ref);
            }

            await addDoc(collection(db, 'expenses'), {
                ...formData,
                receiptUrl,
                bookedInJournal: false,
                createdAt: serverTimestamp()
            });

            setIsFormOpen(false);
            resetForm();
            showAlert({ type: 'success', message: 'Ausgabe gespeichert.' });
        } catch (e) {
            console.error(e);
            showAlert({ type: 'error', message: 'Fehler beim Speichern.' });
        }
    };

    const resetForm = () => {
        setFormData({
            vendor: '',
            amount: 0,
            currency: 'CHF',
            date: new Date().toISOString().split('T')[0],
            description: '',
            categoryAccountCode: '4000',
            paymentAccountCode: '1020',
            status: 'PENDING'
        });
        setReceiptPreview(null);
        if(fileInputRef.current) fileInputRef.current.value = '';
    };

    const handleBookExpense = async (expense: Expense) => {
        if (expense.bookedInJournal) return;

        let finalAmountCHF = expense.amount;
        let bookingDescription = `Ausgabe: ${expense.vendor} - ${expense.description}`;

        if (expense.currency !== 'CHF') {
            const conversionInput = await showPrompt({
                title: "Währungsumrechnung erforderlich",
                message: `Die Ausgabe ist in ${expense.currency} (${expense.amount}).\nBitte geben Sie den effektiven CHF-Betrag für die Buchhaltung ein:`,
                placeholder: "z.B. 105.50",
                confirmText: "Buchen"
            });

            if (!conversionInput) return; // User cancelled
            
            const converted = parseFloat(conversionInput);
            if (isNaN(converted)) {
                showAlert({ type: 'error', message: "Ungültiger Betrag." });
                return;
            }
            
            finalAmountCHF = converted;
            bookingDescription += ` (${expense.amount} ${expense.currency} @ ${converted} CHF)`;
        } else {
            const confirm = await showConfirm({
                title: "Ausgabe verbuchen",
                message: `Soll die Zahlung von ${expense.amount} ${expense.currency} an ${expense.vendor} im Journal verbucht werden?\n\nSOLL: ${expense.categoryAccountCode} (Aufwand)\nHABEN: ${expense.paymentAccountCode} (Bank/Kasse)`,
                confirmText: "Verbuchen",
                type: 'primary'
            });
            if (!confirm) return;
        }

        try {
            await addDoc(collection(db, 'accounting_journal'), {
                date: expense.date,
                description: bookingDescription,
                debitCode: expense.categoryAccountCode,
                creditCode: expense.paymentAccountCode,
                amount: finalAmountCHF,
                referenceId: expense.id,
                createdAt: serverTimestamp()
            });

            await updateDoc(doc(db, 'expenses', expense.id), {
                status: 'PAID',
                bookedInJournal: true
            });

            showAlert({ type: 'success', message: 'Erfolgreich verbucht.' });
        } catch (e) {
            showAlert({ type: 'error', message: 'Fehler bei der Buchung.' });
        }
    };

    const handleDelete = async (id: string) => {
        if (await showConfirm({ title: t('common.delete'), message: t('admin.confirm_delete'), type: 'danger' })) {
            await deleteDoc(doc(db, 'expenses', id));
        }
    };

    const filteredExpenses = expenses.filter(e => filter === 'ALL' || (filter === 'PENDING' ? e.status !== 'PAID' : e.status === 'PAID'));

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden min-h-[600px] flex flex-col">
            <div className="flex border-b border-stone-100">
                <button onClick={() => setFilter('ALL')} className={`px-8 py-5 font-bold text-sm transition-colors ${filter === 'ALL' ? 'text-primary border-b-2 border-primary' : 'text-stone-400'}`}>{t('admin.expenses.all')}</button>
                <button onClick={() => setFilter('PENDING')} className={`px-8 py-5 font-bold text-sm transition-colors ${filter === 'PENDING' ? 'text-amber-500 border-b-2 border-amber-500' : 'text-stone-400'}`}>{t('admin.expenses.pending')}</button>
                <button onClick={() => setFilter('PAID')} className={`px-8 py-5 font-bold text-sm transition-colors ${filter === 'PAID' ? 'text-green-500 border-b-2 border-green-500' : 'text-stone-400'}`}>{t('admin.expenses.paid')}</button>
            </div>

            <div className="flex-1 p-8 grid grid-cols-1 lg:grid-cols-12 gap-8 bg-[#faf9f6]">
                
                {/* Left: List */}
                <div className="lg:col-span-7 space-y-4">
                    {filteredExpenses.map(expense => (
                        <motion.div 
                            layoutId={expense.id} 
                            key={expense.id}
                            className={`p-5 rounded-2xl border transition-all flex items-center gap-4 bg-white hover:shadow-md ${expense.bookedInJournal ? 'border-green-100' : 'border-stone-200'}`}
                        >
                            <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${expense.bookedInJournal ? 'bg-green-100 text-green-600' : 'bg-stone-100 text-stone-500'}`}>
                                {expense.bookedInJournal ? <CheckCircle2 size={20}/> : <FileText size={20}/>}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="flex justify-between items-start mb-1">
                                    <h4 className="font-bold text-stone-900 truncate">{expense.vendor}</h4>
                                    <span className="font-mono font-bold text-stone-900">{expense.amount.toFixed(2)} <span className={`text-xs ${expense.currency !== 'CHF' ? 'text-rose-500 font-bold' : 'text-stone-400'}`}>{expense.currency}</span></span>
                                </div>
                                <p className="text-xs text-stone-500 truncate mb-1">{expense.description}</p>
                                <div className="flex items-center gap-2">
                                    <span className="text-[10px] font-mono bg-stone-50 border border-stone-200 px-1.5 py-0.5 rounded text-stone-500">{expense.categoryAccountCode}</span>
                                    <span className="text-[10px] text-stone-400">{expense.date}</span>
                                    {expense.currency !== 'CHF' && (
                                        <span className="text-[9px] bg-rose-50 text-rose-600 px-1.5 py-0.5 rounded border border-rose-100 font-bold uppercase tracking-wide">Ausland</span>
                                    )}
                                </div>
                            </div>
                            <div className="flex flex-col gap-2">
                                {!expense.bookedInJournal ? (
                                    <button 
                                        onClick={() => handleBookExpense(expense)}
                                        className="p-2 bg-stone-900 text-white rounded-lg hover:bg-primary transition-colors text-xs font-bold flex items-center gap-1"
                                        title="Verbuchen"
                                    >
                                        <BookOpen size={14} /> {t('admin.expenses.book')}
                                    </button>
                                ) : (
                                    <span className="text-[10px] font-bold text-green-600 uppercase tracking-widest text-center border border-green-100 px-2 py-1 rounded-lg bg-green-50">{t('admin.expenses.paid')}</span>
                                )}
                                <button onClick={() => handleDelete(expense.id)} className="p-2 text-stone-300 hover:text-red-500 transition-colors self-end"><Trash2 size={14}/></button>
                            </div>
                        </motion.div>
                    ))}
                    {filteredExpenses.length === 0 && (
                        <div className="text-center py-20 text-stone-400 italic">Keine Ausgaben gefunden.</div>
                    )}
                </div>

                {/* Right: Upload / Form */}
                <div className="lg:col-span-5">
                    <div className={`bg-white rounded-[2rem] border border-stone-200 shadow-xl overflow-hidden sticky top-8 transition-all ${isFormOpen ? 'ring-4 ring-primary/10' : ''}`}>
                        
                        {/* Action Header */}
                        <div className="bg-stone-900 text-white p-6">
                            <div className="flex gap-4">
                                <div 
                                    onClick={() => fileInputRef.current?.click()}
                                    className="flex-1 bg-white/10 hover:bg-white/20 rounded-2xl p-6 cursor-pointer flex flex-col items-center gap-3 transition-colors group relative overflow-hidden"
                                >
                                    <input type="file" ref={fileInputRef} hidden accept="image/*,.pdf" onChange={handleFileSelect} />
                                    {isScanning ? (
                                        <Loader2 size={32} className="animate-spin text-primary" />
                                    ) : (
                                        <ScanLine size={32} className="group-hover:scale-110 transition-transform" />
                                    )}
                                    <span className="text-sm font-bold">{isScanning ? "Scanne..." : t('admin.expenses.scan')}</span>
                                    <div className="absolute inset-0 bg-gradient-to-tr from-primary/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                                </div>

                                <div 
                                    onClick={handleManualEntry}
                                    className="flex-1 bg-white/10 hover:bg-white/20 rounded-2xl p-6 cursor-pointer flex flex-col items-center gap-3 transition-colors group"
                                >
                                    <Keyboard size={32} className="group-hover:scale-110 transition-transform text-emerald-400" />
                                    <span className="text-sm font-bold">{t('admin.expenses.manual')}</span>
                                </div>
                            </div>
                            <p className="text-center text-stone-500 text-xs mt-4">Wählen Sie Scan für automatische Erkennung oder Manuell für Bareinkäufe (z.B. Kosovo).</p>
                        </div>

                        {/* Edit Form */}
                        <AnimatePresence>
                            {isFormOpen && (
                                <motion.div 
                                    initial={{ height: 0, opacity: 0 }} 
                                    animate={{ height: 'auto', opacity: 1 }} 
                                    exit={{ height: 0, opacity: 0 }}
                                    className="p-6 bg-white"
                                >
                                    {receiptPreview && (
                                        <div className="mb-6 h-32 w-full bg-stone-50 rounded-xl border border-stone-100 overflow-hidden relative group">
                                            <img src={receiptPreview} className="w-full h-full object-contain" />
                                            <div className="absolute bottom-2 right-2 bg-black/60 text-white text-[10px] px-2 py-1 rounded backdrop-blur-sm">Beleg Vorschau</div>
                                        </div>
                                    )}

                                    <div className="space-y-4">
                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.expenses.vendor')}</label>
                                            <input value={formData.vendor} onChange={e => setFormData({...formData, vendor: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50 font-bold" placeholder="z.B. Market Prishtina" />
                                        </div>
                                        
                                        <div className="grid grid-cols-2 gap-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.amount')}</label>
                                                <div className="relative">
                                                    <input type="number" value={formData.amount} onChange={e => setFormData({...formData, amount: parseFloat(e.target.value)})} className="w-full pl-3 pr-16 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50 font-mono font-bold" />
                                                    <div className="absolute right-1 top-1 bottom-1 flex bg-white rounded-lg border border-stone-100 p-1">
                                                        <button 
                                                            onClick={() => setFormData({...formData, currency: 'CHF', paymentAccountCode: '1020'})} // Reset to bank default
                                                            className={`px-2 rounded-md text-xs font-bold transition-colors ${formData.currency === 'CHF' ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-900'}`}
                                                        >CHF</button>
                                                        <button 
                                                            onClick={() => setFormData({...formData, currency: 'EUR', paymentAccountCode: '1001'})} // Switch to EUR Cash default
                                                            className={`px-2 rounded-md text-xs font-bold transition-colors ${formData.currency === 'EUR' ? 'bg-blue-600 text-white' : 'text-stone-400 hover:text-blue-600'}`}
                                                        >EUR</button>
                                                    </div>
                                                </div>
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.date')}</label>
                                                <input type="date" value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50" />
                                            </div>
                                        </div>

                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.expenses.description')}</label>
                                            <input value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50 text-sm" placeholder="Zweck der Ausgabe" />
                                        </div>

                                        <div className="grid grid-cols-2 gap-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1 flex items-center gap-1"><Tag size={10}/> {t('admin.expenses.category')}</label>
                                                <select value={formData.categoryAccountCode} onChange={e => setFormData({...formData, categoryAccountCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold">
                                                    {accounts.filter(a => a.class === 'EXPENSE' || a.class === 'ASSET').map(a => (
                                                        <option key={a.id} value={a.code}>{a.code} {a.name}</option>
                                                    ))}
                                                </select>
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1 flex items-center gap-1"><CreditCard size={10}/> {t('admin.expenses.paymentAcc')}</label>
                                                <select value={formData.paymentAccountCode} onChange={e => setFormData({...formData, paymentAccountCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-xs font-bold">
                                                    {accounts.filter(a => a.class === 'ASSET' && (a.category.includes('Flüssige') || a.code === '1020' || a.code === '1000' || a.code === '1001')).map(a => (
                                                        <option key={a.id} value={a.code}>{a.code} {a.name}</option>
                                                    ))}
                                                </select>
                                            </div>
                                        </div>

                                        <div className="flex gap-3 pt-4 border-t border-stone-100">
                                            <button onClick={() => setIsFormOpen(false)} className="flex-1 py-3 bg-stone-100 text-stone-500 rounded-xl font-bold hover:bg-stone-200">{t('common.cancel')}</button>
                                            <button onClick={handleSaveExpense} className="flex-1 py-3 bg-primary text-white rounded-xl font-bold hover:bg-rose-600 shadow-lg flex items-center justify-center gap-2">
                                                <Upload size={16} /> {t('admin.expenses.save')}
                                            </button>
                                        </div>
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminExpenses;
