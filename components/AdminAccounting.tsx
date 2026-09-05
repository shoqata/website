
import React, { useState, useEffect, useMemo } from 'react';
import { 
  BookOpen, 
  Plus, 
  TrendingUp, 
  Scale, 
  Filter,
  RefreshCw,
  Lock,
  ArrowRight,
  CheckCircle2,
  AlertCircle,
  // Added AlertTriangle to fix "Cannot find name 'AlertTriangle'" errors
  AlertTriangle,
  ArrowDownRight,
  ArrowUpRight,
  Landmark,
  Wallet,
  Printer,
  Download,
  X,
  ArrowLeftRight
} from 'lucide-react';
import { db } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, getDocs, where, writeBatch, doc, Timestamp, getDoc, setDoc } from '@/services/supabase-bridge';
import { Account, JournalEntry, Payment } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { motion, AnimatePresence } from 'framer-motion';
import { useTranslation } from '../context/LanguageContext';

// Expanded Swiss KMU Chart of Accounts
const DEFAULT_ACCOUNTS: Account[] = [
    // 1. AKTIVEN (Assets)
    { id: '1000', code: '1000', name: 'Kasse CHF', class: 'ASSET', category: 'Flüssige Mittel' },
    { id: '1001', code: '1001', name: 'Kasse EUR', class: 'ASSET', category: 'Flüssige Mittel' }, // Added EUR Cash
    { id: '1020', code: '1020', name: 'Bank (ZKB)', class: 'ASSET', category: 'Flüssige Mittel', systemAccount: true },
    { id: '1021', code: '1021', name: 'PayPal', class: 'ASSET', category: 'Flüssige Mittel' },
    { id: '1100', code: '1100', name: 'Forderungen (Mitglieder)', class: 'ASSET', category: 'Forderungen' },
    { id: '1500', code: '1500', name: 'Mobile Sachanlagen', class: 'ASSET', category: 'Anlagevermögen' },
    
    // 2. PASSIVEN (Liabilities)
    { id: '2000', code: '2000', name: 'Kreditoren (VLL)', class: 'LIABILITY', category: 'Kurzfr. Fremdkapital' },
    { id: '2200', code: '2200', name: 'Übrige kurzfr. Verbindlichkeiten', class: 'LIABILITY', category: 'Kurzfr. Fremdkapital' },
    { id: '2900', code: '2900', name: 'Vereinsvermögen (Eigenkapital)', class: 'LIABILITY', category: 'Eigenkapital' },

    // 3. ERTRAG (Revenue)
    { id: '3000', code: '3000', name: 'Mitgliederbeiträge', class: 'REVENUE', category: 'Betrieblicher Ertrag' },
    { id: '3200', code: '3200', name: 'Dienstleistungserlöse', class: 'REVENUE', category: 'Betrieblicher Ertrag' },
    { id: '3400', code: '3400', name: 'Spenden / Zuwendungen', class: 'REVENUE', category: 'Betrieblicher Ertrag' },
    { id: '3600', code: '3600', name: 'Erträge aus Veranstaltungen', class: 'REVENUE', category: 'Betrieblicher Ertrag' },
    { id: '3805', code: '3805', name: 'Verluste aus Forderungen', class: 'EXPENSE', category: 'Erlösminderungen' }, // Write-off account

    // 4-6. AUFWAND (Expense)
    { id: '4000', code: '4000', name: 'Materialaufwand', class: 'EXPENSE', category: 'Materialaufwand' },
    { id: '6000', code: '6000', name: 'Raumaufwand', class: 'EXPENSE', category: 'Betriebsaufwand' },
    { id: '6200', code: '6200', name: 'Fahrzeuge / Transport', class: 'EXPENSE', category: 'Betriebsaufwand' },
    { id: '6500', code: '6500', name: 'Informatik & Admin', class: 'EXPENSE', category: 'Verwaltungsaufwand' },
    { id: '6570', code: '6570', name: 'Porti & Gebühren', class: 'EXPENSE', category: 'Verwaltungsaufwand' },
    { id: '6700', code: '6700', name: 'Werbung & PR', class: 'EXPENSE', category: 'Werbeaufwand' },
    { id: '6900', code: '6900', name: 'Bankspesen', class: 'EXPENSE', category: 'Finanzaufwand' },
    { id: '6950', code: '6950', name: 'Abschreibungen', class: 'EXPENSE', category: 'Abschreibungen' },
];

/**
 * Local interface for Accounts including calculated financial values
 */
interface AccountWithBalance extends Account {
    debit: number;
    credit: number;
    balance: number;
}

interface AdminAccountingProps {
    selectedYear: number;
    isYearClosed?: boolean;
}

// Helper to reliably extract a Year from any date format
const getYearFromEntry = (dateInput: any): number => {
    if (!dateInput) return new Date().getFullYear();
    if (dateInput instanceof Timestamp) return dateInput.toDate().getFullYear();
    if (typeof dateInput === 'string') return new Date(dateInput).getFullYear();
    if (dateInput instanceof Date) return dateInput.getFullYear();
    return new Date().getFullYear();
};

const getDateString = (dateInput: any): string => {
    if (!dateInput) return '';
    if (dateInput instanceof Timestamp) return dateInput.toDate().toISOString().split('T')[0];
    if (dateInput instanceof Date) return dateInput.toISOString().split('T')[0];
    if (typeof dateInput === 'string') return dateInput.split('T')[0];
    return String(dateInput);
};

const AdminAccounting: React.FC<AdminAccountingProps> = ({ selectedYear, isYearClosed }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [activeTab, setActiveTab] = useState<'JOURNAL' | 'ACCOUNTS' | 'BILANZ' | 'ERFOLG'>('BILANZ');
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [journal, setJournal] = useState<JournalEntry[]>([]);
  const [unbookedPayments, setUnbookedPayments] = useState<Payment[]>([]);
  
  // New Booking State
  const [isBookingModalOpen, setIsBookingModalOpen] = useState(false);
  const [newBooking, setNewBooking] = useState({
      date: new Date().toISOString().split('T')[0],
      description: '',
      debitCode: '',
      creditCode: '',
      amount: ''
  });

  // Transfer State
  const [isTransferModalOpen, setIsTransferModalOpen] = useState(false);
  const [transferData, setTransferData] = useState({
      date: new Date().toISOString().split('T')[0],
      sourceCode: '1020',
      targetCode: '1001',
      amountOut: '',
      amountIn: '',
      rate: ''
  });

  // Account Detail Modal State (Typed to include balance)
  const [viewAccount, setViewAccount] = useState<AccountWithBalance | null>(null);

  // Closing Ceremony State
  const [showClosingWizard, setShowClosingWizard] = useState(false);
  const [closingStep, setClosingStep] = useState(0);

  useEffect(() => {
    // 1. Sync Accounts (Seed if empty, or add missing specific accounts like 1001)
    const syncAccounts = async () => {
        const q = query(collection(db, 'accounting_accounts'), orderBy('code'));
        const snap = await getDocs(q);
        
        if (snap.empty) {
            // First time seed
            const batch = writeBatch(db);
            DEFAULT_ACCOUNTS.forEach(acc => {
                const ref = doc(db, 'accounting_accounts', acc.id);
                batch.set(ref, acc);
            });
            await batch.commit();
            setAccounts(DEFAULT_ACCOUNTS);
        } else {
            const loadedAccounts = snap.docs.map(d => d.data() as Account);
            
            // Check for missing key accounts (specifically 1001 for Reps and 1021 for PayPal)
            const missing1001 = !loadedAccounts.find(a => a.code === '1001');
            if (missing1001) {
                const acc1001 = DEFAULT_ACCOUNTS.find(a => a.code === '1001');
                if (acc1001) {
                    await setDoc(doc(db, 'accounting_accounts', acc1001.id), acc1001);
                    loadedAccounts.push(acc1001);
                }
            }

            const missing1021 = !loadedAccounts.find(a => a.code === '1021');
            if (missing1021) {
                const acc1021 = DEFAULT_ACCOUNTS.find(a => a.code === '1021');
                if (acc1021) {
                    await setDoc(doc(db, 'accounting_accounts', acc1021.id), acc1021);
                    loadedAccounts.push(acc1021);
                }
            }

            // Re-sort
            loadedAccounts.sort((a, b) => a.code.localeCompare(b.code));
            
            setAccounts(loadedAccounts);
        }
    };
    syncAccounts();

    // 2. Listen to Journal (ROBUST FETCHING)
    const journalQuery = query(collection(db, 'accounting_journal'), orderBy('date', 'desc'));
    
    const unsubJournal = onSnapshot(journalQuery, (snap) => {
        const allEntries = snap.docs.map(d => {
            const data = d.data();
            
            // Normalize Amount (handle strings like "100.50")
            const rawAmount = data.amount;
            let numericAmount = 0;
            if (typeof rawAmount === 'number') numericAmount = rawAmount;
            else if (typeof rawAmount === 'string') numericAmount = parseFloat(rawAmount);

            return { 
                id: d.id, 
                ...data, 
                date: getDateString(data.date), // Normalize to YYYY-MM-DD string for display/logic
                amount: numericAmount || 0 
            } as JournalEntry;
        });

        // Strict Year Filter
        const filtered = allEntries.filter(j => getYearFromEntry(j.date) === selectedYear);
        setJournal(filtered);
    });

    // 3. Listen to Unbooked Paid Payments (Only if year matches)
    const qPayments = query(collection(db, 'payments'), where('status', '==', 'PAID'));
    const unsubPayments = onSnapshot(qPayments, (snap) => {
        const allPaid = snap.docs.map(d => {
            const data = d.data();
            return { id: d.id, ...data } as Payment;
        });
        
        // Filter based on normalized date logic
        setUnbookedPayments(allPaid.filter(p => 
            !p.bookedInJournal && 
            (p.paidAt ? getYearFromEntry(p.paidAt) : getYearFromEntry(p.timestamp)) === selectedYear
        ));
    });

    return () => { unsubJournal(); unsubPayments(); };
  }, [selectedYear]);

  const getAccountName = (code: string) => accounts.find(a => a.code === code)?.name || code;

  // --- CORE BOOKING LOGIC ---
  const handleBooking = async () => {
      if (!newBooking.debitCode || !newBooking.creditCode || !newBooking.amount || !newBooking.description) {
          showAlert({ type: 'error', message: 'Bitte alle Felder ausfüllen.' });
          return;
      }
      if (isYearClosed) {
          showAlert({ type: 'error', message: 'Das Geschäftsjahr ist bereits abgeschlossen.' });
          return;
      }
      
      try {
          await addDoc(collection(db, 'accounting_journal'), {
              ...newBooking,
              amount: parseFloat(newBooking.amount),
              createdAt: serverTimestamp()
          });
          setIsBookingModalOpen(false);
          setNewBooking({ date: new Date().toISOString().split('T')[0], description: '', debitCode: '', creditCode: '', amount: '' });
          showAlert({ type: 'success', message: 'Buchung erfolgreich.' });
      } catch (e) {
          console.error(e);
          showAlert({ type: 'error', message: "Fehler beim Buchen." });
      }
  };

  const handleTransfer = async () => {
      if (!transferData.sourceCode || !transferData.targetCode || !transferData.amountOut) {
          showAlert({ type: 'error', message: 'Bitte Konten und Ausgangsbetrag wählen.' });
          return;
      }

      // If amounts differ (Currency Exchange), mention it in description
      let desc = `Kontoübertrag ${transferData.sourceCode} -> ${transferData.targetCode}`;
      if (transferData.amountIn && transferData.amountIn !== transferData.amountOut) {
          desc += ` (Wechsel: ${transferData.amountOut} -> ${transferData.amountIn})`;
      }

      try {
          await addDoc(collection(db, 'accounting_journal'), {
              date: transferData.date,
              description: desc,
              debitCode: transferData.targetCode, // Target receives (Debit)
              creditCode: transferData.sourceCode, // Source gives (Credit)
              amount: parseFloat(transferData.amountOut), // Book value is based on source outflow (usually CHF)
              createdAt: serverTimestamp()
          });
          setIsTransferModalOpen(false);
          showAlert({ type: 'success', message: 'Übertrag erfolgreich verbucht.' });
      } catch (e) {
          showAlert({ type: 'error', message: 'Fehler beim Übertrag.' });
      }
  };

  const handleSyncPayments = async () => {
      if (unbookedPayments.length === 0) return;
      if (isYearClosed) return;

      const confirmed = await showConfirm({
          title: "Zahlungen verbuchen",
          message: `${unbookedPayments.length} neue Zahlungen für ${selectedYear} gefunden. \n\nAutomatische Buchung:\nSOLL: 1020 Bank (ZKB)\nHABEN: 3000 Mitgliederbeiträge`,
          confirmText: "Alle Verbuchen",
          type: 'primary'
      });
      if (!confirmed) return;

      const batch = writeBatch(db);
      
      unbookedPayments.forEach(p => {
          // 1. Create Journal Entry
          const journalRef = doc(collection(db, 'accounting_journal'));
          
          // Determine Debit Account (Bank or Cash?)
          // If method was CASH, use 1001 (EUR) or 1000 (CHF). Defaulting to 1020 for Bank Transfers.
          let debitCode = '1020'; 
          if (p.method === 'CASH') {
              debitCode = p.currency === 'EUR' ? '1001' : '1000';
          }

          batch.set(journalRef, {
              date: p.paidAt || getDateString(p.timestamp),
              description: `Zahlungseingang: ${p.description || 'Mitgliederbeitrag'} (${p.invoiceNumber})`,
              debitCode: debitCode, 
              creditCode: '3000', // Member Fees (Revenue)
              amount: p.amount,
              referenceId: p.id,
              createdAt: serverTimestamp()
          });

          // 2. Mark payment as booked so it doesn't appear again
          const paymentRef = doc(db, 'payments', p.id);
          batch.update(paymentRef, { bookedInJournal: true });
      });

      await batch.commit();
      showAlert({ type: 'success', message: `${unbookedPayments.length} Zahlungen erfolgreich ins Journal übertragen.` });
  };

  const accountBalances = useMemo((): AccountWithBalance[] => {
      return accounts.map(acc => {
          const debitEntries = journal.filter(j => String(j.debitCode) === String(acc.code));
          const creditEntries = journal.filter(j => String(j.creditCode) === String(acc.code));

          const sumDebit = debitEntries.reduce((sum, j) => sum + (j.amount || 0), 0);
          const sumCredit = creditEntries.reduce((sum, j) => sum + (j.amount || 0), 0);

          let balance = 0;
          if (acc.class === 'ASSET' || acc.class === 'EXPENSE') {
              balance = sumDebit - sumCredit;
          } else {
              balance = sumCredit - sumDebit;
          }

          return { ...acc, debit: sumDebit, credit: sumCredit, balance };
      });
  }, [accounts, journal]);

  const totalAssets = accountBalances.filter(b => b.class === 'ASSET').reduce((sum, b) => sum + b.balance, 0);
  const totalLiabilities = accountBalances.filter(b => b.class === 'LIABILITY').reduce((sum, b) => sum + b.balance, 0);
  const totalRevenue = accountBalances.filter(b => b.class === 'REVENUE').reduce((sum, b) => sum + b.balance, 0);
  const totalExpense = accountBalances.filter(b => b.class === 'EXPENSE').reduce((sum, b) => sum + b.balance, 0);
  
  const currentProfit = totalRevenue - totalExpense;
  const balanceSheetCheck = totalAssets - (totalLiabilities + currentProfit); 

  const handleExportStatement = (account: Account) => {
      const transactions = journal.filter(j => String(j.debitCode) === String(account.code) || String(j.creditCode) === String(account.code))
                                  .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
      
      const csvHeader = "Datum,Beschreibung,Soll,Haben,Betrag\n";
      const csvRows = transactions.map(t => {
          const isDebit = String(t.debitCode) === String(account.code);
          return `${t.date},"${t.description.replace(/"/g, '""')}",${isDebit ? account.code : ''},${!isDebit ? account.code : ''},${t.amount.toFixed(2)}`;
      }).join("\n");

      const blob = new Blob([csvHeader + csvRows], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Kontoauszug_${account.code}_${selectedYear}.csv`;
      a.click();
  };

  const performYearClosing = async () => {
      setClosingStep(1); 
      const batch = writeBatch(db);
      batch.update(doc(db, 'fiscal_years', selectedYear.toString()), { status: 'CLOSED', closedAt: new Date().toISOString(), netProfit: currentProfit });
      const nextYear = selectedYear + 1;
      batch.set(doc(db, 'fiscal_years', nextYear.toString()), { id: nextYear.toString(), year: nextYear, status: 'OPEN' }, { merge: true });
      const balanceSheetAccounts = accountBalances.filter(b => b.class === 'ASSET' || b.class === 'LIABILITY');
      balanceSheetAccounts.forEach(acc => {
          let openingAmount = acc.balance;
          if (acc.code === '2900') openingAmount += currentProfit;
          if (Math.abs(openingAmount) > 0.01) {
              const jRef = doc(collection(db, 'accounting_journal'));
              const isAsset = acc.class === 'ASSET';
              batch.set(jRef, {
                  date: `${nextYear}-01-01`,
                  description: `Eröffnungsbilanz (Vortrag aus ${selectedYear})`,
                  debitCode: isAsset ? acc.code : '9100', 
                  creditCode: isAsset ? '9100' : acc.code,
                  amount: openingAmount,
                  createdAt: serverTimestamp(),
                  isSystemEntry: true
              });
          }
      });
      setClosingStep(2);
      await batch.commit();
      setClosingStep(3);
      setTimeout(() => { setShowClosingWizard(false); setClosingStep(0); showAlert({ type: 'success', message: `Geschäftsjahr ${selectedYear} erfolgreich abgeschlossen.` }); }, 2000);
  };

  return (
    <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden min-h-[600px] flex flex-col">
        <div className="flex justify-between items-center pr-8 border-b border-stone-100 bg-white sticky top-0 z-20">
            <div className="flex overflow-x-auto no-scrollbar">
                <button onClick={() => setActiveTab('BILANZ')} className={`px-8 py-6 font-bold text-sm transition-all flex items-center gap-2 border-b-2 ${activeTab === 'BILANZ' ? 'text-primary border-primary bg-primary/5' : 'text-stone-400 border-transparent hover:text-stone-900 hover:bg-stone-50'}`}><Scale size={18}/> {t('admin.accounting.balanceSheet')}</button>
                <button onClick={() => setActiveTab('ERFOLG')} className={`px-8 py-6 font-bold text-sm transition-all flex items-center gap-2 border-b-2 ${activeTab === 'ERFOLG' ? 'text-primary border-primary bg-primary/5' : 'text-stone-400 border-transparent hover:text-stone-900 hover:bg-stone-50'}`}><TrendingUp size={18}/> {t('admin.accounting.incomeStatement')}</button>
                <button onClick={() => setActiveTab('JOURNAL')} className={`px-8 py-6 font-bold text-sm transition-all flex items-center gap-2 border-b-2 ${activeTab === 'JOURNAL' ? 'text-primary border-primary bg-primary/5' : 'text-stone-400 border-transparent hover:text-stone-900 hover:bg-stone-50'}`}><BookOpen size={18}/> {t('admin.accounting.journal')}</button>
                <button onClick={() => setActiveTab('ACCOUNTS')} className={`px-8 py-6 font-bold text-sm transition-all flex items-center gap-2 border-b-2 ${activeTab === 'ACCOUNTS' ? 'text-primary border-primary bg-primary/5' : 'text-stone-400 border-transparent hover:text-stone-900 hover:bg-stone-50'}`}><Filter size={18}/> {t('admin.accounting.accounts')}</button>
            </div>
            {isYearClosed ? ( <div className="flex items-center gap-2 text-stone-400 font-bold text-xs uppercase tracking-widest bg-stone-100 px-4 py-2 rounded-xl"><Lock size={14} /> {selectedYear} Closed</div> ) : ( <button onClick={() => setShowClosingWizard(true)} className="flex items-center gap-2 text-primary hover:bg-primary/5 px-4 py-2 rounded-xl font-bold text-xs uppercase tracking-widest transition-colors border border-primary/20"><CheckCircle2 size={14} /> {t('admin.accounting.closeYear')} {selectedYear}</button> )}
        </div>

        <div className="p-8 bg-[#faf9f6] flex-1 overflow-y-auto">
            {activeTab === 'BILANZ' && (
                <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-8">
                    <div className="text-center mb-8"><h3 className="text-3xl font-display font-bold italic text-stone-900">{t('admin.accounting.balanceSheet')} {selectedYear}</h3><p className="text-stone-400 text-sm font-medium">Stichtag 31.12.{selectedYear}</p></div>
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-200 shadow-sm flex flex-col h-full">
                            <div className="flex items-center gap-3 mb-6 pb-4 border-b border-stone-100"><div className="bg-emerald-100 text-emerald-700 p-3 rounded-xl"><Wallet size={24}/></div><div><h4 className="text-lg font-bold text-stone-900">{t('admin.accounting.assets')}</h4><p className="text-xs text-stone-400 uppercase tracking-widest">Mittelverwendung</p></div></div>
                            <div className="space-y-1 flex-1">
                                {accountBalances.filter(b => b.class === 'ASSET').map(acc => (
                                    <div key={acc.id} className="flex justify-between text-sm py-3 border-b border-stone-50 last:border-0 hover:bg-stone-50 px-2 rounded-lg transition-colors"><div className="flex items-center gap-3"><span className="font-mono text-xs text-stone-400 bg-stone-100 px-1.5 py-0.5 rounded">{acc.code}</span><span className="text-stone-700 font-medium">{acc.name}</span></div><span className="font-mono font-bold text-stone-900">{acc.balance.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                                ))}
                            </div>
                            <div className="mt-8 pt-6 border-t-2 border-stone-100 flex justify-between items-end"><span className="text-xs font-bold text-stone-400 uppercase tracking-widest">Total {t('admin.accounting.assets')}</span><span className="text-2xl font-mono font-bold text-emerald-600">{totalAssets.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                        </div>
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-200 shadow-sm flex flex-col h-full">
                            <div className="flex items-center gap-3 mb-6 pb-4 border-b border-stone-100"><div className="bg-rose-100 text-rose-700 p-3 rounded-xl"><Landmark size={24}/></div><div><h4 className="text-lg font-bold text-stone-900">{t('admin.accounting.liabilities')}</h4><p className="text-xs text-stone-400 uppercase tracking-widest">Mittelherkunft</p></div></div>
                            <div className="space-y-1 flex-1">
                                {accountBalances.filter(b => b.class === 'LIABILITY').map(acc => (
                                    <div key={acc.id} className="flex justify-between text-sm py-3 border-b border-stone-50 last:border-0 hover:bg-stone-50 px-2 rounded-lg transition-colors"><div className="flex items-center gap-3"><span className="font-mono text-xs text-stone-400 bg-stone-100 px-1.5 py-0.5 rounded">{acc.code}</span><span className="text-stone-700 font-medium">{acc.name}</span></div><span className="font-mono font-bold text-stone-900">{acc.balance.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                                ))}
                                <div className={`flex justify-between text-sm py-4 mt-4 px-4 rounded-xl border ${currentProfit >= 0 ? 'bg-green-50 border-green-100 text-green-800' : 'bg-red-50 border-red-100 text-red-800'}`}><span className="font-bold flex items-center gap-2">{currentProfit >= 0 ? <ArrowUpRight size={16}/> : <ArrowDownRight size={16}/>}{t('admin.accounting.profit')} {selectedYear}</span><span className="font-mono font-bold">{currentProfit.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                            </div>
                            <div className="mt-8 pt-6 border-t-2 border-stone-100 flex justify-between items-end"><span className="text-xs font-bold text-stone-400 uppercase tracking-widest">Total {t('admin.accounting.liabilities')}</span><span className="text-2xl font-mono font-bold text-stone-900">{(totalLiabilities + currentProfit).toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                        </div>
                    </div>
                    {Math.abs(balanceSheetCheck) > 0.05 && ( <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-xl text-center font-bold flex items-center justify-center gap-2"><AlertTriangle size={20}/>Bilanzdifferenz: {balanceSheetCheck.toFixed(2)} CHF - Bitte Buchungen prüfen!</div> )}
                </motion.div>
            )}

            {activeTab === 'ERFOLG' && (
                <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="max-w-3xl mx-auto space-y-8">
                    <div className="text-center mb-8"><h3 className="text-3xl font-display font-bold italic text-stone-900">{t('admin.accounting.incomeStatement')} {selectedYear}</h3><p className="text-stone-400 text-sm font-medium">01.01.{selectedYear} - 31.12.{selectedYear}</p></div>
                    <div className="bg-white border border-stone-200 rounded-[2.5rem] overflow-hidden shadow-lg">
                        <div className="p-8 border-b border-stone-100 bg-emerald-50/30">
                            <div className="flex justify-between items-center mb-6"><h4 className="text-emerald-700 font-bold uppercase tracking-widest text-sm flex items-center gap-2"><Plus size={16}/> {t('admin.accounting.revenue')}</h4></div>
                            <div className="space-y-2">
                                {accountBalances.filter(b => b.class === 'REVENUE').map(acc => ( <div key={acc.id} className="flex justify-between text-sm py-2 border-b border-stone-100 last:border-0"><span className="text-stone-600">{acc.name}</span><span className="font-mono font-bold text-stone-900">{acc.balance.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div> ))}
                            </div>
                            <div className="flex justify-between font-bold mt-6 pt-4 border-t border-emerald-200 text-emerald-900 text-lg"><span>Total {t('admin.accounting.revenue')}</span><span>{totalRevenue.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                        </div>
                        <div className="p-8 border-b border-stone-100 bg-rose-50/30">
                            <div className="flex justify-between items-center mb-6"><h4 className="text-rose-700 font-bold uppercase tracking-widest text-sm flex items-center gap-2"><ArrowDownRight size={16}/> {t('admin.accounting.expense')}</h4></div>
                            <div className="space-y-2">
                                {accountBalances.filter(b => b.class === 'EXPENSE').map(acc => ( <div key={acc.id} className="flex justify-between text-sm py-2 border-b border-stone-100 last:border-0"><span className="text-stone-600">{acc.name}</span><span className="font-mono font-bold text-stone-900">{acc.balance.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div> ))}
                            </div>
                            <div className="flex justify-between font-bold mt-6 pt-4 border-t border-rose-200 text-rose-900 text-lg"><span>Total {t('admin.accounting.expense')}</span><span>{totalExpense.toLocaleString('de-CH', { minimumFractionDigits: 2 })}</span></div>
                        </div>
                        <div className="p-8 bg-stone-900 text-white flex justify-between items-center"><div className="flex flex-col"><span className="font-display italic text-2xl">Unternehmenserfolg</span><span className="text-stone-400 text-xs uppercase tracking-widest">{t('admin.accounting.profit')}</span></div><span className={`font-mono text-3xl font-bold ${currentProfit >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>{currentProfit >= 0 ? '+' : ''}{currentProfit.toLocaleString('de-CH', { minimumFractionDigits: 2 })} CHF</span></div>
                    </div>
                </motion.div>
            )}

            {activeTab === 'JOURNAL' && (
                <div className="space-y-6">
                    <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-[2rem] border border-stone-100 shadow-sm">
                        <div><h3 className="text-xl font-bold text-stone-900">Buchungsjournal</h3><p className="text-stone-500 text-sm">Chronologische Liste aller Transaktionen.</p></div>
                        <div className="flex gap-3">
                            {unbookedPayments.length > 0 && !isYearClosed && ( <button onClick={handleSyncPayments} className="bg-amber-100 text-amber-800 px-5 py-3 rounded-xl font-bold text-xs flex items-center gap-2 hover:bg-amber-200 transition-colors shadow-sm animate-pulse border border-amber-200"><RefreshCw size={16}/> {t('admin.accounting.importPayments')} ({unbookedPayments.length})</button> )}
                            <button onClick={() => setIsTransferModalOpen(true)} disabled={isYearClosed} className="bg-white border border-stone-200 text-stone-700 px-6 py-3 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-stone-50 transition-all disabled:opacity-50"><ArrowLeftRight size={18} /> Kontoübertrag</button>
                            <button onClick={() => setIsBookingModalOpen(true)} disabled={isYearClosed} className="bg-stone-900 text-white px-6 py-3 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-stone-800 transition-all disabled:opacity-50 shadow-lg"><Plus size={18} /> {t('admin.accounting.newBooking')}</button>
                        </div>
                    </div>
                    <div className="bg-white rounded-[2rem] border border-stone-200 overflow-hidden shadow-sm">
                        <table className="w-full text-left text-sm">
                            <thead className="bg-stone-50 text-stone-500 font-bold uppercase text-[10px] tracking-widest border-b border-stone-200"><tr><th className="px-6 py-4">{t('admin.finance.date')}</th><th className="px-6 py-4">{t('admin.expenses.description')}</th><th className="px-6 py-4">{t('admin.accounting.debit')}</th><th className="px-6 py-4">{t('admin.accounting.credit')}</th><th className="px-6 py-4 text-right">{t('admin.finance.amount')}</th></tr></thead>
                            <tbody className="divide-y divide-stone-100">
                                {journal.map(entry => (
                                    <tr key={entry.id} className={`hover:bg-stone-50 transition-colors ${entry.isSystemEntry ? 'bg-blue-50/30' : ''}`}><td className="px-6 py-4 font-mono text-xs text-stone-500">{entry.date}</td><td className="px-6 py-4 font-medium text-stone-800">{entry.description}{entry.isSystemEntry && <span className="ml-2 inline-block bg-blue-100 text-blue-600 text-[9px] px-1.5 py-0.5 rounded font-bold uppercase">System</span>}</td><td className="px-6 py-4 text-stone-600"><span className="bg-stone-100 border border-stone-200 px-2 py-1 rounded text-[10px] font-mono font-bold mr-2 text-stone-500">{entry.debitCode}</span>{getAccountName(entry.debitCode)}</td><td className="px-6 py-4 text-stone-600"><span className="bg-stone-100 border border-stone-200 px-2 py-1 rounded text-[10px] font-mono font-bold mr-2 text-stone-500">{entry.creditCode}</span>{getAccountName(entry.creditCode)}</td><td className="px-6 py-4 text-right font-mono font-bold text-stone-900">{entry.amount.toFixed(2)}</td></tr>
                                ))}
                                {journal.length === 0 && ( <tr><td colSpan={5} className="px-6 py-12 text-center text-stone-400 italic">Keine Buchungen für {selectedYear} vorhanden.</td></tr> )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {activeTab === 'ACCOUNTS' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {accountBalances.map(acc => (
                        <div key={acc.id} onClick={() => setViewAccount(acc)} className="bg-white border border-stone-200 p-6 rounded-[2rem] flex justify-between items-center shadow-sm hover:shadow-md hover:border-primary/50 transition-all cursor-pointer group">
                            <div className="flex items-center gap-4"><div className={`w-12 h-12 rounded-2xl flex items-center justify-center font-mono font-bold text-sm ${acc.class === 'ASSET' ? 'bg-emerald-100 text-emerald-700' : acc.class === 'LIABILITY' ? 'bg-orange-100 text-orange-700' : acc.class === 'REVENUE' ? 'bg-blue-100 text-blue-700' : 'bg-rose-100 text-rose-700'}`}>{acc.code}</div><div><p className="font-bold text-stone-900 group-hover:text-primary transition-colors">{acc.name}</p><p className="text-[10px] text-stone-400 uppercase tracking-widest">{acc.category}</p></div></div>
                            <div className="text-right"><p className="font-mono font-bold text-stone-800 text-lg">{acc.balance.toFixed(2)}</p><p className="text-[10px] text-stone-400 uppercase tracking-widest">Saldo</p></div>
                        </div>
                    ))}
                </div>
            )}
        </div>

        <AnimatePresence>
            {viewAccount && (
                <div className="fixed inset-0 z-[300] bg-stone-900/80 backdrop-blur-md flex items-center justify-center p-4">
                    <motion.div initial={{opacity:0, scale:0.95}} animate={{opacity:1, scale:1}} exit={{opacity:0, scale:0.95}} className="bg-white h-[90vh] w-full max-w-4xl rounded-2xl flex flex-col overflow-hidden relative">
                        <div className="bg-stone-50 border-b border-stone-200 p-4 flex justify-between items-center shrink-0 no-print">
                            <h3 className="font-bold text-stone-800">Kontoauszug: {viewAccount.code} {viewAccount.name}</h3>
                            <div className="flex gap-2"><button onClick={() => handleExportStatement(viewAccount)} className="flex items-center gap-2 px-4 py-2 bg-white border border-stone-200 rounded-lg text-sm font-bold text-stone-600 hover:text-primary transition-colors"><Download size={16}/> CSV Export</button><button onClick={() => window.print()} className="flex items-center gap-2 px-4 py-2 bg-stone-900 text-white rounded-lg text-sm font-bold hover:bg-black transition-colors"><Printer size={16}/> Drucken</button><button onClick={() => setViewAccount(null)} className="p-2 hover:bg-stone-200 rounded-lg text-stone-500"><X size={20}/></button></div>
                        </div>
                        <div className="flex-1 overflow-y-auto bg-stone-100 p-8 flex justify-center printable-scroll-area">
                            <div className="bg-white shadow-xl w-[210mm] min-h-[297mm] p-[20mm] text-stone-900 printable-account-sheet">
                                <style>{` @media print { body * { visibility: hidden; } .printable-account-sheet, .printable-account-sheet * { visibility: visible; } .printable-account-sheet { position: absolute; left: 0; top: 0; width: 100%; margin: 0; padding: 10mm; box-shadow: none; } @page { size: A4; margin: 0; } .no-print { display: none !important; } } `}</style>
                                <div className="border-b-2 border-stone-900 pb-4 mb-8 flex justify-between items-end"><div><h1 className="text-2xl font-display font-bold italic mb-1">Kontoauszug {selectedYear}</h1><h2 className="text-lg font-bold">{viewAccount.code} {viewAccount.name}</h2></div><div className="text-right text-sm"><p className="font-bold">Klasse: {viewAccount.class}</p><p className="text-stone-500">Kategorie: {viewAccount.category}</p></div></div>
                                <table className="w-full text-left text-xs">
                                    <thead className="border-b-2 border-stone-200 font-bold uppercase"><tr><th className="py-2">Datum</th><th className="py-2">Buchungstext</th><th className="py-2">Gegenkonto</th><th className="py-2 text-right">Soll</th><th className="py-2 text-right">Haben</th></tr></thead>
                                    <tbody className="divide-y divide-stone-100">{journal.filter(j => String(j.debitCode) === String(viewAccount.code) || String(j.creditCode) === String(viewAccount.code)).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()).map(t => { const isDebit = String(t.debitCode) === String(viewAccount.code); return ( <tr key={t.id}><td className="py-2 font-mono text-stone-500">{t.date}</td><td className="py-2 max-w-[200px] truncate">{t.description}</td><td className="py-2 font-mono text-stone-500">{isDebit ? t.creditCode : t.debitCode}</td><td className="py-2 text-right font-mono">{isDebit ? t.amount.toFixed(2) : '-'}</td><td className="py-2 text-right font-mono">{!isDebit ? t.amount.toFixed(2) : '-'}</td></tr> )})}</tbody>
                                    <tfoot className="border-t-2 border-stone-900 font-bold"><tr><td colSpan={3} className="py-4 text-right">Saldo</td><td className="py-4 text-right font-mono text-base">{viewAccount.class === 'ASSET' || viewAccount.class === 'EXPENSE' ? viewAccount.balance.toFixed(2) : ''}</td><td className="py-4 text-right font-mono text-base">{viewAccount.class === 'LIABILITY' || viewAccount.class === 'REVENUE' ? viewAccount.balance.toFixed(2) : ''}</td></tr></tfoot>
                                </table>
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        <AnimatePresence>
            {isBookingModalOpen && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-lg rounded-[2.5rem] p-8 shadow-2xl">
                        <h3 className="text-2xl font-bold mb-6 text-stone-900">{t('admin.accounting.newBooking')}</h3>
                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.date')}</label><input type="date" min={`${selectedYear}-01-01`} max={`${selectedYear}-12-31`} value={newBooking.date} onChange={e => setNewBooking({...newBooking, date: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50" /></div>
                                <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.amount')}</label><input type="number" placeholder="0.00" value={newBooking.amount} onChange={e => setNewBooking({...newBooking, amount: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50 font-mono font-bold" /></div>
                            </div>
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.expenses.description')}</label><input type="text" placeholder="Zweck der Buchung..." value={newBooking.description} onChange={e => setNewBooking({...newBooking, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none focus:border-primary/50" /></div>
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.accounting.debit')}</label><select value={newBooking.debitCode} onChange={e => setNewBooking({...newBooking, debitCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none font-medium"><option value="">{t('common.select')}</option>{accounts.map(a => <option key={a.id} value={a.code}>{a.code} {a.name}</option>)}</select></div>
                                <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.accounting.credit')}</label><select value={newBooking.creditCode} onChange={e => setNewBooking({...newBooking, creditCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none font-medium"><option value="">{t('common.select')}</option>{accounts.map(a => <option key={a.id} value={a.code}>{a.code} {a.name}</option>)}</select></div>
                            </div>
                            <div className="flex gap-4 mt-8 pt-4 border-t border-stone-100"><button onClick={() => setIsBookingModalOpen(false)} className="flex-1 py-3 bg-stone-100 font-bold rounded-xl text-stone-500 hover:bg-stone-200 transition-colors">{t('common.cancel')}</button><button onClick={handleBooking} className="flex-1 py-3 bg-stone-900 text-white font-bold rounded-xl hover:bg-black transition-colors shadow-lg">{t('admin.expenses.book')}</button></div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* TRANSFER MODAL */}
        <AnimatePresence>
            {isTransferModalOpen && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-lg rounded-[2.5rem] p-8 shadow-2xl">
                        <h3 className="text-2xl font-bold mb-2 text-stone-900">Kontoübertrag / Wechsel</h3>
                        <p className="text-stone-500 text-sm mb-6">Transfer von liquiden Mitteln (z.B. Bank zu Kasse oder Währungswechsel).</p>
                        
                        <div className="space-y-4">
                            <div><label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Datum</label><input type="date" value={transferData.date} onChange={e => setTransferData({...transferData, date: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                            
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Von (Haben)</label>
                                    <select value={transferData.sourceCode} onChange={e => setTransferData({...transferData, sourceCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-bold outline-none">
                                        {accounts.filter(a => a.category === 'Flüssige Mittel').map(a => <option key={a.id} value={a.code}>{a.name}</option>)}
                                    </select>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Nach (Soll)</label>
                                    <select value={transferData.targetCode} onChange={e => setTransferData({...transferData, targetCode: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-bold outline-none">
                                        {accounts.filter(a => a.category === 'Flüssige Mittel').map(a => <option key={a.id} value={a.code}>{a.name}</option>)}
                                    </select>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Betrag Ausgang</label>
                                    <input type="number" placeholder="0.00" value={transferData.amountOut} onChange={e => setTransferData({...transferData, amountOut: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold" />
                                    <p className="text-[10px] text-stone-400 mt-1">Betrag in Quellwährung</p>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Betrag Eingang</label>
                                    <input type="number" placeholder="0.00" value={transferData.amountIn} onChange={e => setTransferData({...transferData, amountIn: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono font-bold" />
                                    <p className="text-[10px] text-stone-400 mt-1">Betrag in Zielwährung</p>
                                </div>
                            </div>

                            <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 text-xs text-blue-800">
                                <p>Hinweis: Bei Währungswechsel wird der "Betrag Ausgang" (in Basiswährung) verbucht. Der "Betrag Eingang" dient der Information für den Kassenbestand.</p>
                            </div>

                            <div className="flex gap-4 mt-8 pt-4 border-t border-stone-100"><button onClick={() => setIsTransferModalOpen(false)} className="flex-1 py-3 bg-stone-100 font-bold rounded-xl text-stone-500 hover:bg-stone-200 transition-colors">{t('common.cancel')}</button><button onClick={handleTransfer} className="flex-1 py-3 bg-stone-900 text-white font-bold rounded-xl hover:bg-black transition-colors shadow-lg">Umbuchen</button></div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* CLOSING CEREMONY WIZARD */}
        <AnimatePresence>
            {showClosingWizard && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/80 backdrop-blur-sm">
                    <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }} className="bg-white w-full max-w-lg rounded-[2.5rem] p-10 text-center relative overflow-hidden shadow-2xl">
                        <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-rose-500 via-purple-500 to-amber-500" />
                        <div className="w-24 h-24 bg-stone-100 rounded-full flex items-center justify-center mx-auto mb-8 relative">
                            {closingStep === 3 ? ( <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} className="text-green-500"><CheckCircle2 size={48} /></motion.div> ) : ( <Lock size={32} className="text-stone-400" /> )}
                            {closingStep > 0 && closingStep < 3 && ( <div className="absolute inset-0 border-4 border-stone-200 border-t-primary rounded-full animate-spin" /> )}
                        </div>
                        <h3 className="text-3xl font-display font-bold mb-4 text-stone-900">{t('admin.accounting.closeYear')} {selectedYear}</h3>
                        {closingStep === 0 && (
                            <>
                                <p className="text-stone-500 mb-8 leading-relaxed text-sm">Sie sind dabei, das Geschäftsjahr {selectedYear} unwiderruflich abzuschließen. Der Gewinn/Verlust von <strong className={currentProfit >= 0 ? 'text-green-600' : 'text-red-600'}>{currentProfit.toFixed(2)} CHF</strong> wird dem Eigenkapital zugewiesen und die Eröffnungsbilanz für {selectedYear + 1} wird automatisch generiert.</p>
                                <div className="bg-amber-50 p-4 rounded-2xl border border-amber-100 mb-8 text-left flex items-start gap-3"><AlertTriangle className="text-amber-600 shrink-0 mt-0.5" size={18} /><p className="text-amber-800 text-xs font-medium">Achtung: Stellen Sie sicher, dass alle Buchungen korrekt erfasst sind. Dieser Vorgang sperrt das Journal für {selectedYear}.</p></div>
                                <div className="flex gap-4"><button onClick={() => setShowClosingWizard(false)} className="flex-1 py-4 bg-stone-100 rounded-xl font-bold text-stone-500 hover:bg-stone-200 transition-colors">{t('common.cancel')}</button><button onClick={performYearClosing} className="flex-1 py-4 bg-stone-900 text-white rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-black transition-colors shadow-lg">{t('admin.accounting.closeYear')} <ArrowRight size={16} /></button></div>
                            </>
                        )}
                        {closingStep > 0 && closingStep < 3 && ( <div className="py-8"><p className="font-bold text-stone-900 text-lg">Verarbeite Daten...</p><p className="text-xs text-stone-400 mt-2">Erstelle Eröffnungsbilanz {selectedYear + 1}...</p></div> )}
                        {closingStep === 3 && ( <div className="py-4"><p className="text-green-600 font-bold text-lg mb-2">{t('common.success')}</p><p className="text-stone-400 text-sm">Das Jahr {selectedYear} ist nun gesperrt.</p></div> )}
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    </div>
  );
};

export default AdminAccounting;
