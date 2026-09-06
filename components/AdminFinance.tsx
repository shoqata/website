import React, { useState, useEffect, useMemo } from 'react';
import { 
  CreditCard, 
  Plus, 
  Search, 
  CheckCircle2, 
  MoreHorizontal, 
  Filter, 
  Download, 
  FileText, 
  User, 
  Mail, 
  Calendar,
  X,
  Loader2, 
  Trash2, 
  Send,
  Users,
  CheckSquare,
  Square,
  LayoutDashboard,
  BellRing,
  Settings,
  AlertTriangle,
  ArrowRight,
  Save,
  Banknote,
  Eye,
  Printer,
  PieChart as PieChartIcon,
  Calculator,
  Info
} from 'lucide-react';
import { db } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, doc, updateDoc, deleteDoc, writeBatch, setDoc, getDoc } from '@/services/supabase-bridge';
import { Payment, UserProfile, GlobalPaymentSettings, Account } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { motion, AnimatePresence } from 'framer-motion';
import { useTranslation } from '../context/LanguageContext';
import SwissQRBill from './SwissQRBill';
import { QrBillData } from '../services/qrBillService';
import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import { sendEmail } from '../services/mailService';
import { QRCodeSVG } from 'qrcode.react';

interface AdminFinanceProps {
    viewMode: 'LIST' | 'GRID' | 'KANBAN';
    selectedYear: number;
}

const AdminFinance: React.FC<AdminFinanceProps> = ({ viewMode, selectedYear }) => {
    const { t } = useTranslation();
    const { showAlert, showConfirm } = useFeedback();
    
    // Tabs
    const [activeTab, setActiveTab] = useState<'OVERVIEW' | 'INVOICES' | 'DUNNING' | 'BUDGET' | 'SETTINGS'>('OVERVIEW');

    // Data
    const [payments, setPayments] = useState<Payment[]>([]);
    const [users, setUsers] = useState<UserProfile[]>([]);
    const [accounts, setAccounts] = useState<Account[]>([]); 
    const [budgetData, setBudgetData] = useState<Record<string, number>>({}); 
    const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings>({
        iban: '', bankName: '', bic: '', accountHolder: '', street: '', zip: '', city: '', country: 'Switzerland', paypalEmail: '', currency: 'CHF', annualFeeAmount: 100
    });
    
    // UI State
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState<string>('ALL');
    const [viewInvoice, setViewInvoice] = useState<Payment | null>(null);
    const [isSendingEmails, setIsSendingEmails] = useState(false);
    const [isSavingBudget, setIsSavingBudget] = useState(false);

    // Create Invoice State
    const [invoiceMode, setInvoiceMode] = useState<'SINGLE' | 'MULTI' | 'BULK'>('SINGLE');
    const [recipientMode, setRecipientMode] = useState<'MEMBER' | 'EXTERNAL'>('MEMBER');
    const [newInvoice, setNewInvoice] = useState<Partial<Payment>>({
        amount: 0,
        currency: 'CHF',
        description: 'Mitgliederbeitrag ' + selectedYear,
        dueDate: '',
        userId: ''
    });
    const [customRecipient, setCustomRecipient] = useState({
        name: '',
        email: '',
        street: '',
        zip: '',
        city: '',
        country: 'Switzerland'
    });
    
    // Member Search/Selection State
    const [memberSearchTerm, setMemberSearchTerm] = useState('');
    const [showMemberDropdown, setShowMemberDropdown] = useState(false);
    const [selectedInvoiceUserIds, setSelectedInvoiceUserIds] = useState<Set<string>>(new Set());
    const [multiSelectFilter, setMultiSelectFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE' | 'NO_FEE_PAID'>('ALL');

    useEffect(() => {
        const q = query(collection(db, 'payments'), orderBy('timestamp', 'desc'));
        const unsub = onSnapshot(q, (snap) => {
            setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() } as Payment)));
        });

        const qUsers = query(collection(db, 'users'), orderBy('displayName'));
        const unsubUsers = onSnapshot(qUsers, (snap) => {
            setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile)));
        });

        const qAccounts = query(collection(db, 'accounting_accounts'), orderBy('code'));
        const unsubAccounts = onSnapshot(qAccounts, (snap) => {
            setAccounts(snap.docs.map(d => d.data() as Account));
        });

        const unsubSettings = onSnapshot(doc(db, 'settings', 'payment'), (snap) => {
            if(snap.exists()) setPaymentSettings(snap.data() as GlobalPaymentSettings);
        });

        return () => { unsub(); unsubUsers(); unsubAccounts(); unsubSettings(); };
    }, []);

    useEffect(() => {
        const fetchBudget = async () => {
            const docRef = doc(db, 'fiscal_budgets', selectedYear.toString());
            const snap = await getDoc(docRef);
            if (snap.exists()) {
                setBudgetData(snap.data().entries || {});
            } else {
                setBudgetData({});
            }
        };
        fetchBudget();
    }, [selectedYear]);

    const yearPayments = useMemo(() => payments.filter(p => p.timestamp?.toDate().getFullYear() === selectedYear), [payments, selectedYear]);
    
    const filteredPayments = useMemo(() => {
        return yearPayments.filter(p => {
            const matchesSearch = p.invoiceNumber?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                                  p.description?.toLowerCase().includes(searchTerm.toLowerCase());
            
            let matchesFilter = true;
            if (filterStatus === 'TO_PRINT') {
                matchesFilter = p.deliveryMethod === 'POST' && p.status !== 'PAID';
            } else if (filterStatus !== 'ALL') {
                matchesFilter = p.status === filterStatus;
            }
            
            return matchesSearch && matchesFilter;
        });
    }, [yearPayments, searchTerm, filterStatus]);

    const overduePayments = useMemo(() => {
        return payments.filter(p => p.status === 'OVERDUE' || (p.status === 'PENDING' && p.dueDate && new Date(p.dueDate) < new Date()));
    }, [payments]);

    const budgetStats = useMemo(() => {
        let totalRevenue = 0;
        let totalExpense = 0;
        Object.entries(budgetData).forEach(([code, amount]) => {
            const acc = accounts.find(a => a.code === code);
            if (acc) {
                if (acc.class === 'REVENUE') totalRevenue += Number(amount);
                if (acc.class === 'EXPENSE') totalExpense += Number(amount);
            }
        });
        return { totalRevenue, totalExpense, result: totalRevenue - totalExpense };
    }, [budgetData, accounts]);

    const dropdownUsers = useMemo(() => {
        if (!memberSearchTerm) return [];
        return users.filter(u => 
            u.displayName?.toLowerCase().includes(memberSearchTerm.toLowerCase()) ||
            u.email?.toLowerCase().includes(memberSearchTerm.toLowerCase())
        ).slice(0, 5);
    }, [users, memberSearchTerm]);

    const multiSelectUsers = useMemo(() => {
        return users.filter(u => {
            const matchesSearch = u.displayName?.toLowerCase().includes(memberSearchTerm.toLowerCase()) || u.email?.toLowerCase().includes(memberSearchTerm.toLowerCase());
            if (!matchesSearch) return false;
            
            if (multiSelectFilter === 'ACTIVE') return u.membershipStatus === 'ACTIVE';
            if (multiSelectFilter === 'INACTIVE') return u.membershipStatus === 'INACTIVE';
            if (multiSelectFilter === 'NO_FEE_PAID') {
                // Check if user has paid any fee
                const hasPaidFee = payments.some(p => p.userId === u.id && p.type === 'FEE' && p.status === 'PAID');
                return !hasPaidFee;
            }
            return u.membershipStatus !== 'INACTIVE'; // Default 'ALL' excludes INACTIVE
        });
    }, [users, memberSearchTerm, multiSelectFilter, payments]);

    const pendingEmailPayments = useMemo(() => {
        return filteredPayments.filter(p => p.deliveryMethod === 'EMAIL' && p.status !== 'PAID');
    }, [filteredPayments]);

    const handleBudgetChange = (code: string, value: string) => {
        const num = parseFloat(value);
        setBudgetData(prev => ({
            ...prev,
            [code]: isNaN(num) ? 0 : num
        }));
    };

    const handleSaveBudget = async () => {
        setIsSavingBudget(true);
        try {
            await setDoc(doc(db, 'fiscal_budgets', selectedYear.toString()), {
                year: selectedYear,
                entries: budgetData,
                updatedAt: serverTimestamp()
            });
            showAlert({ type: 'success', message: `Budget für ${selectedYear} gespeichert.` });
        } catch (e) {
            showAlert({ type: 'error', message: 'Fehler beim Speichern.' });
        } finally {
            setIsSavingBudget(false);
        }
    };

    const handleSendInvoiceEmail = async (payment: Payment) => {
        let email = '';
        let recipientName = '';
        if (payment.userId === 'EXTERNAL' || !payment.userId) {
            email = payment.customRecipient?.email || '';
            recipientName = payment.customRecipient?.name || 'Guest';
        } else {
            const u = users.find(user => user.id === payment.userId);
            email = u?.email || '';
            recipientName = u?.displayName || 'Member';
        }
        if (!email || !email.includes('@') || email.includes('@koretini.legacy')) {
            showAlert({ type: 'error', message: 'No valid email address for this recipient.' });
            return;
        }
        try {
            const subject = `Rechnung / Invoice ${payment.invoiceNumber} - Shoqata Koretini`;
            
            let paymentInfoHtml = '';
            if (payment.method === 'QR_BILL') {
                paymentInfoHtml = `
                    <h3>Zahlungsinformationen (Banküberweisung / Swiss QR)</h3>
                    <p><strong>Bank:</strong> ${paymentSettings.bankName}<br/><strong>Kontoinhaber:</strong> ${paymentSettings.accountHolder}<br/><strong>IBAN:</strong> ${paymentSettings.qrIban || paymentSettings.iban}<br/>${payment.reference ? `<strong>Referenz:</strong> ${payment.reference}<br/>` : ''}</p>
                    ${paymentSettings.twintNumber ? `
                    <div style="margin-top: 20px; padding: 15px; background-color: #f0f0f0; border-radius: 8px;">
                        <h4 style="margin-top: 0;">Zahlung per TWINT</h4>
                        <p>Sie können den Betrag auch bequem per TWINT an folgende Nummer senden: <strong>${paymentSettings.twintNumber}</strong></p>
                        ${paymentSettings.twintUrl ? `<p><a href="${paymentSettings.twintUrl}" style="display: inline-block; padding: 10px 20px; background-color: #000; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold;">Jetzt mit TWINT bezahlen</a></p>` : ''}
                    </div>` : ''}
                `;
            } else if (payment.method === 'GIRO_CODE') {
                paymentInfoHtml = `
                    <h3>Zahlungsinformationen (SEPA Überweisung)</h3>
                    <p><strong>Bank:</strong> ${paymentSettings.bankName}<br/><strong>Kontoinhaber:</strong> ${paymentSettings.accountHolder}<br/><strong>IBAN:</strong> ${paymentSettings.iban}<br/><strong>BIC:</strong> ${paymentSettings.bic || 'Nicht angegeben'}<br/><strong>Verwendungszweck:</strong> ${payment.invoiceNumber}</p>
                `;
            } else if (payment.method === 'PAYPAL') {
                paymentInfoHtml = `
                    <h3>Zahlungsinformationen (PayPal)</h3>
                    <p>Bitte senden Sie den Betrag an unsere PayPal-Adresse: <strong>${paymentSettings.paypalEmail || 'Nicht konfiguriert'}</strong></p>
                    <p>Geben Sie als Verwendungszweck unbedingt Ihre Rechnungsnummer an: <strong>${payment.invoiceNumber}</strong></p>
                `;
            } else {
                paymentInfoHtml = `
                    <h3>Zahlungsinformationen</h3>
                    <p><strong>Bank:</strong> ${paymentSettings.bankName}<br/><strong>Kontoinhaber:</strong> ${paymentSettings.accountHolder}<br/><strong>IBAN:</strong> ${paymentSettings.iban}<br/>${payment.reference ? `<strong>Referenz:</strong> ${payment.reference}<br/>` : ''}</p>
                `;
            }

            const html = `
                <div style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
                    <h2>Rechnung / Invoice</h2>
                    <p>Përshëndetje / Hello <strong>${recipientName}</strong>,</p>
                    <p>Ju lutem gjeni më poshtë detajet për pagesën e anëtarësisë:</p>
                    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; border: 1px solid #eee; margin: 20px 0;">
                        <table style="width: 100%;">
                            <tr><td style="padding: 5px 0;"><strong>Invoice #:</strong></td><td style="text-align: right;">${payment.invoiceNumber}</td></tr>
                            <tr><td style="padding: 5px 0;"><strong>Description:</strong></td><td style="text-align: right;">${payment.description}</td></tr>
                            <tr><td style="padding: 5px 0;"><strong>Amount:</strong></td><td style="text-align: right; font-size: 1.2em; font-weight: bold;">${payment.amount.toFixed(2)} ${payment.currency}</td></tr>
                            <tr><td style="padding: 5px 0;"><strong>Due Date:</strong></td><td style="text-align: right;">${payment.dueDate || 'Immediate'}</td></tr>
                        </table>
                    </div>
                    ${paymentInfoHtml}
                    <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;"/>
                    <p style="font-size: 0.9em; color: #666;">Faleminderit që mbështesni komunitetin tonë.</p>
                </div>
            `;
            await sendEmail({ to: email, subject, html });
            showAlert({ type: 'success', message: `Invoice sent to ${email}` });
        } catch (error) { showAlert({ type: 'error', message: 'Failed to send email.' }); }
    };

    const handleSendBulkEmails = async () => {
        if (pendingEmailPayments.length === 0) return;
        const confirmed = await showConfirm({ title: "Send Bulk Emails", message: `Send invoices to ${pendingEmailPayments.length} recipients via email?`, confirmText: "Send All", type: 'primary' });
        if (!confirmed) return;
        setIsSendingEmails(true);
        for (const payment of pendingEmailPayments) { await handleSendInvoiceEmail(payment); }
        setIsSendingEmails(false);
        showAlert({ type: 'success', message: `Sent emails successfully.` });
    };

    const toggleUserSelection = (userId: string) => {
        const next = new Set(selectedInvoiceUserIds);
        if (next.has(userId)) next.delete(userId); else next.add(userId);
        setSelectedInvoiceUserIds(next);
    };

    const selectAllFiltered = () => {
        if (selectedInvoiceUserIds.size === multiSelectUsers.length) setSelectedInvoiceUserIds(new Set());
        else setSelectedInvoiceUserIds(new Set(multiSelectUsers.map(u => u.id)));
    };

    const determinePaymentMethod = (country?: string): 'QR_BILL' | 'GIRO_CODE' | 'PAYPAL' => {
        if (!country) return 'QR_BILL';
        const c = country.toLowerCase();
        if (['switzerland', 'schweiz', 'suisse', 'svizzera', 'ch'].includes(c)) return 'QR_BILL';
        if (['germany', 'deutschland', 'de', 'austria', 'österreich', 'at', 'france', 'frankreich', 'fr', 'italy', 'italien', 'it'].includes(c)) return 'GIRO_CODE';
        return 'PAYPAL';
    };

    const handleCreateInvoice = async () => {
        if (invoiceMode === 'SINGLE' && (!newInvoice.amount || !newInvoice.description)) { showAlert({ type: 'error', message: 'Please fill amount and description.' }); return; }
        if (invoiceMode === 'SINGLE') {
            if (recipientMode === 'MEMBER' && !newInvoice.userId) { showAlert({ type: 'error', message: 'Please select a member.' }); return; }
            if (recipientMode === 'EXTERNAL' && !customRecipient.name) { showAlert({ type: 'error', message: 'Please enter recipient name.' }); return; }
        } else if (invoiceMode === 'MULTI' && selectedInvoiceUserIds.size === 0) { showAlert({ type: 'error', message: 'Please select at least one member.' }); return; }

        try {
            const batch = writeBatch(db);
            const baseData = { description: newInvoice.description || 'Mitgliederbeitrag ' + selectedYear, dueDate: newInvoice.dueDate, status: 'PENDING', type: 'FEE', billingYear: selectedYear };
            
            if (invoiceMode === 'SINGLE') {
                const docRef = doc(collection(db, 'payments'));
                let country = 'Switzerland';
                if (recipientMode === 'EXTERNAL') {
                    country = customRecipient.country || 'Switzerland';
                } else {
                    const member = users.find(u => u.id === newInvoice.userId);
                    if (member) country = member.country || 'Switzerland';
                }
                const method = determinePaymentMethod(country);

                batch.set(docRef, { ...baseData, method, amount: newInvoice.amount, currency: newInvoice.currency, timestamp: serverTimestamp(), invoiceNumber: `INV-${Date.now().toString().slice(-6)}`, userId: recipientMode === 'MEMBER' ? newInvoice.userId : 'EXTERNAL', deliveryMethod: 'EMAIL', customRecipient: recipientMode === 'EXTERNAL' ? { ...customRecipient, address: `${customRecipient.street}, ${customRecipient.zip} ${customRecipient.city}` } : null });
            } else {
                const targetUserIds = invoiceMode === 'MULTI' ? Array.from(selectedInvoiceUserIds) : users.filter(u => u.membershipStatus === 'ACTIVE').map(u => u.id);
                const standardFee = paymentSettings.fees?.STANDARD?.amount || 120;
                const standardCurr = paymentSettings.fees?.STANDARD?.currency || 'CHF';
                targetUserIds.forEach((uid, index) => {
                    const u = users.find(user => user.id === uid);
                    if (!u) return;
                    let amount = u.customAnnualFee || (u.billingGroup === 'KOSOVO' ? paymentSettings.fees?.KOSOVO?.amount : u.billingGroup === 'REDUCED' ? paymentSettings.fees?.REDUCED?.amount : standardFee) || standardFee;
                    let currency = (u.customAnnualFee ? u.currency : u.billingGroup === 'KOSOVO' ? paymentSettings.fees?.KOSOVO?.currency : u.billingGroup === 'REDUCED' ? paymentSettings.fees?.REDUCED?.currency : standardCurr) || standardCurr;
                    const hasValidEmail = u.email && !u.email.includes('@koretini.legacy') && u.email.includes('@');
                    let deliveryMethod = (!hasValidEmail || u.invoiceDeliveryMethod === 'POST') ? 'POST' : (u.invoiceDeliveryMethod === 'BOTH' ? 'BOTH' : 'EMAIL');
                    const method = determinePaymentMethod(u.country);
                    
                    const docRef = doc(collection(db, 'payments'));
                    batch.set(docRef, { ...baseData, method, userId: uid, amount, currency, deliveryMethod, timestamp: serverTimestamp(), invoiceNumber: `INV-${Date.now().toString().slice(-5)}${index}` });
                });
            }
            await batch.commit();
            setShowCreateModal(false);
            setNewInvoice({ amount: 0, currency: 'CHF', description: '', userId: '' });
            setMemberSearchTerm('');
            setCustomRecipient({ name: '', email: '', street: '', zip: '', city: '', country: 'Switzerland' });
            setSelectedInvoiceUserIds(new Set());
            showAlert({ type: 'success', message: 'Invoices created.' });
        } catch (error) { showAlert({ type: 'error', message: 'Failed to create invoice.' }); }
    };

    const handleDelete = async (id: string) => { if (await showConfirm({ title: 'Delete Invoice', message: 'Are you sure?', type: 'danger' })) await deleteDoc(doc(db, 'payments', id)); };
    const handleMarkPaid = async (payment: Payment) => { await updateDoc(doc(db, 'payments', payment.id), { status: 'PAID', paidAt: new Date().toISOString() }); showAlert({ type: 'success', message: 'Marked as paid.' }); };
    const handleSaveSettings = async () => { try { await setDoc(doc(db, 'settings', 'payment'), paymentSettings); showAlert({ type: 'success', message: 'Settings saved.' }); } catch (e) { showAlert({ type: 'error', message: 'Failed to save settings.' }); } };
    const handleSendReminder = async (payment: Payment) => { try { const newLevel = (payment.dunningLevel || 0) + 1; await updateDoc(doc(db, 'payments', payment.id), { status: 'OVERDUE', dunningLevel: newLevel, lastDunningDate: new Date().toISOString() }); showAlert({ type: 'success', message: `Reminder Level ${newLevel} sent.` }); } catch (e) { showAlert({ type: 'error', message: 'Error sending reminder.' }); } };

    // Fix: Refactored getQrData to correctly resolve debtor and handle member lookup
    const getQrData = (payment: Payment): QrBillData | null => {
        if (!paymentSettings) return null;
        
        let debtorName = 'Unknown';
        let debtorAddress = '';
        let debtorZip = '';
        let debtorCity = '';
        let debtorCountry = 'CH';

        if (payment.userId === 'EXTERNAL' || !payment.userId) {
            if (payment.customRecipient) {
                debtorName = payment.customRecipient.name;
                debtorAddress = payment.customRecipient.street || payment.customRecipient.address;
                debtorZip = payment.customRecipient.zip || '';
                debtorCity = payment.customRecipient.city || '';
                debtorCountry = payment.customRecipient.country || 'CH';
            }
        } else {
            const member = users.find(u => u.id === payment.userId);
            if (member) {
                debtorName = member.displayName || 'Member';
                debtorAddress = member.address || (member.street ? `${member.street}` : '');
                debtorZip = member.zip || '';
                debtorCity = member.city || '';
                debtorCountry = member.country || 'CH';
            }
        }

        const debtor = {
            name: debtorName,
            address: debtorAddress,
            zip: debtorZip,
            city: debtorCity,
            country: debtorCountry
        };

        return { 
            amount: payment.amount, 
            currency: payment.currency as 'CHF' | 'EUR', 
            iban: paymentSettings.qrIban || paymentSettings.iban, 
            creditor: { 
                name: paymentSettings.accountHolder, 
                address: paymentSettings.street + ' ' + (paymentSettings.street.match(/\d+/) ? '' : '1'), 
                zip: paymentSettings.zip, 
                city: paymentSettings.city, 
                country: paymentSettings.country 
            }, 
            debtor, 
            reference: payment.reference || '', 
            additionalInfo: payment.description 
        };
    };

    // Fix: Formatted handleDownloadPdf for better readability
    const handleDownloadPdf = async () => { 
        const element = document.getElementById('invoice-preview-content'); 
        if (!element) return; 
        try { 
            const canvas = await html2canvas(element, { scale: 2, useCORS: true, logging: false }); 
            const imgData = canvas.toDataURL('image/jpeg', 0.95); 
            const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' }); 
            const imgWidth = 210; 
            const imgHeight = (canvas.height * imgWidth) / canvas.width; 
            pdf.addImage(imgData, 'JPEG', 0, 0, imgWidth, imgHeight); 
            pdf.save(`Rechnung_${viewInvoice?.invoiceNumber}.pdf`); 
        } catch (e) { 
            console.error(e); 
        } 
    };

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden min-h-[600px] flex flex-col">
            <div className="flex border-b border-stone-100 bg-stone-50/50 overflow-x-auto">
                <button onClick={() => setActiveTab('OVERVIEW')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'OVERVIEW' ? 'border-primary text-primary bg-primary/5' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><LayoutDashboard size={18}/> {t('admin.finance.overview')}</button>
                <button onClick={() => setActiveTab('INVOICES')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'INVOICES' ? 'border-primary text-primary bg-primary/5' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><FileText size={18}/> {t('admin.finance.invoices')}</button>
                <button onClick={() => setActiveTab('DUNNING')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'DUNNING' ? 'border-primary text-primary bg-primary/5' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><BellRing size={18}/> {t('admin.finance.dunning')}{overduePayments.length > 0 && <span className="bg-red-500 text-white text-[10px] px-1.5 py-0.5 rounded-full ml-1">{overduePayments.length}</span>}</button>
                <button onClick={() => setActiveTab('BUDGET')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'BUDGET' ? 'border-primary text-primary bg-primary/5' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><Calculator size={18}/> Budget</button>
                <button onClick={() => setActiveTab('SETTINGS')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'SETTINGS' ? 'border-primary text-primary bg-primary/5' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><Settings size={18}/> {t('admin.finance.settings')}</button>
            </div>

            <div className="p-8 flex-1 overflow-y-auto bg-[#faf9f6]">
                {activeTab === 'OVERVIEW' && (
                    <div className="space-y-8">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm"><p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.finance.collected')} {selectedYear}</p><p className="text-4xl font-display font-bold text-emerald-600">{yearPayments.filter(p => p.status === 'PAID').reduce((acc, p) => acc + p.amount, 0).toFixed(0)} <span className="text-lg text-stone-400">CHF</span></p></div>
                            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm"><p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.finance.open')} {selectedYear}</p><p className="text-4xl font-display font-bold text-amber-500">{yearPayments.filter(p => p.status === 'PENDING').reduce((acc, p) => acc + p.amount, 0).toFixed(0)} <span className="text-lg text-stone-400">CHF</span></p></div>
                            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm"><p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.finance.overdue')}</p><p className="text-4xl font-display font-bold text-rose-500">{overduePayments.reduce((acc, p) => acc + p.amount, 0).toFixed(0)} <span className="text-lg text-stone-400">CHF</span></p></div>
                        </div>
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                            <div className="bg-white p-8 rounded-3xl border border-stone-100 shadow-sm"><h3 className="text-xl font-bold mb-6">Recent Activity</h3><div className="space-y-4">{payments.slice(0, 5).map(p => { const u = users.find(u => u.id === p.userId); return (<div key={p.id} className="flex justify-between items-center text-sm border-b border-stone-50 pb-2"><div><p className="font-bold">{u?.displayName || 'External'}</p><p className="text-xs text-stone-400">{new Date(p.timestamp?.toDate()).toLocaleDateString()}</p></div><div className="text-right"><p className="font-mono font-bold">{p.amount.toFixed(2)} {p.currency}</p><span className={`text-[10px] font-bold ${p.status === 'PAID' ? 'text-green-500' : 'text-stone-400'}`}>{p.status}</span></div></div>)})}</div></div>
                        </div>
                    </div>
                )}

                {activeTab === 'INVOICES' && (
                    <div className="space-y-6">
                        <div className="flex flex-col md:flex-row justify-between items-center gap-4 bg-white p-4 rounded-3xl border border-stone-100 shadow-sm">
                            <div className="flex gap-2 w-full md:w-auto"><div className="relative flex-1 md:w-64"><Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={16} /><input value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} placeholder={t('common.search')} className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/30"/></div><div className="flex bg-stone-50 p-1 rounded-xl border border-stone-200">{(['ALL', 'TO_PRINT', 'PAID', 'PENDING', 'OVERDUE'] as const).map(s => (<button key={s} onClick={() => setFilterStatus(s)} className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1 ${filterStatus === s ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>{s === 'TO_PRINT' ? <><Printer size={12}/> Zu Drucken</> : s}</button>))}</div></div>
                            <div className="flex gap-2">{pendingEmailPayments.length > 0 && (<button onClick={handleSendBulkEmails} disabled={isSendingEmails} className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-blue-700 transition-all shadow-lg disabled:opacity-50">{isSendingEmails ? <Loader2 className="animate-spin" size={16} /> : <Send size={16} />} Send All Emails ({pendingEmailPayments.length})</button>)}<button onClick={() => setShowCreateModal(true)} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16} /> {t('admin.finance.create')}</button></div>
                        </div>
                        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden"><table className="w-full text-left text-sm"><thead className="bg-stone-50 text-stone-400 font-bold uppercase text-[10px] tracking-widest border-b border-stone-100"><tr><th className="px-6 py-4"># Invoice</th><th className="px-6 py-4">Recipient</th><th className="px-6 py-4">Description</th><th className="px-6 py-4">Date</th><th className="px-6 py-4">Amount</th><th className="px-6 py-4">Method / Via</th><th className="px-6 py-4">Status</th><th className="px-6 py-4 text-right">Actions</th></tr></thead><tbody className="divide-y divide-stone-50">{filteredPayments.map(p => { const recipientUser = users.find(u => u.id === p.userId); const recipientName = recipientUser?.displayName || p.customRecipient?.name || 'Unknown'; return (<tr key={p.id} className="hover:bg-stone-50 transition-colors group"><td className="px-6 py-4 font-mono text-xs text-stone-500">{p.invoiceNumber}</td><td className="px-6 py-4 font-bold text-stone-800">{recipientName}</td><td className="px-6 py-4 text-stone-600">{p.description}</td><td className="px-6 py-4 text-stone-500 text-xs">{p.timestamp?.toDate().toLocaleDateString()}</td><td className="px-6 py-4 font-mono font-bold">{p.amount.toFixed(2)} {p.currency}</td><td className="px-6 py-4"><div className="flex flex-col gap-1"><span className="text-[10px] font-bold text-stone-600 uppercase tracking-widest">{p.method === 'QR_BILL' ? 'Swiss QR' : p.method === 'GIRO_CODE' ? 'GiroCode' : p.method === 'PAYPAL' ? 'PayPal' : p.method}</span>{p.deliveryMethod === 'POST' ? (<span className="flex items-center gap-1 text-[10px] font-bold text-amber-600 bg-amber-50 px-2 py-1 rounded w-fit"><Printer size={10}/> Post</span>) : (<span className="flex items-center gap-1 text-[10px] font-bold text-stone-400 bg-stone-50 px-2 py-1 rounded w-fit"><Mail size={10}/> Email</span>)}</div></td><td className="px-6 py-4"><span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${p.status === 'PAID' ? 'bg-green-100 text-green-700' : p.status === 'OVERDUE' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{p.status}</span></td><td className="px-6 py-4 text-right"><div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">{p.deliveryMethod === 'EMAIL' && p.status !== 'PAID' && (<button onClick={() => handleSendInvoiceEmail(p)} className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100"><Send size={14} /></button>)}<button onClick={() => setViewInvoice(p)} className="p-2 bg-stone-100 text-stone-600 rounded-lg hover:bg-stone-200"><Eye size={14} /></button>{p.status !== 'PAID' && (<button onClick={() => handleMarkPaid(p)} className="p-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100"><CheckCircle2 size={14} /></button>)}<button onClick={() => handleDelete(p.id)} className="p-2 bg-red-50 text-red-500 rounded-lg hover:bg-red-100"><Trash2 size={14} /></button></div></td></tr>); })}</tbody></table></div>
                    </div>
                )}

                {activeTab === 'DUNNING' && (
                    <div className="space-y-6">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><BellRing size={20}/> {t('admin.finance.dunning')}</h3>
                            {overduePayments.length === 0 ? (
                                <div className="text-center py-12">
                                    <div className="w-16 h-16 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-4"><CheckCircle2 size={32} /></div>
                                    <h4 className="text-lg font-bold text-stone-900 mb-2">Keine überfälligen Zahlungen</h4>
                                    <p className="text-stone-500">Aktuell gibt es keine offenen Rechnungen, die angemahnt werden müssen.</p>
                                </div>
                            ) : (
                                <div className="space-y-4">
                                    {overduePayments.map(p => {
                                        const u = users.find(u => u.id === p.userId);
                                        return (
                                            <div key={p.id} className="flex justify-between items-center p-4 bg-red-50/50 border border-red-100 rounded-2xl">
                                                <div>
                                                    <p className="font-bold text-stone-900">{u?.displayName || p.customRecipient?.name || 'Unknown'}</p>
                                                    <p className="text-xs text-stone-500">Rechnung: {p.invoiceNumber} • Fällig seit: {new Date(p.dueDate).toLocaleDateString()}</p>
                                                </div>
                                                <div className="flex items-center gap-4">
                                                    <div className="text-right">
                                                        <p className="font-mono font-bold text-red-600">{p.amount.toFixed(2)} {p.currency}</p>
                                                    </div>
                                                    <button onClick={() => handleSendInvoiceEmail(p)} className="px-4 py-2 bg-red-600 text-white rounded-xl text-xs font-bold hover:bg-red-700 transition-colors flex items-center gap-2">
                                                        <Send size={14} /> Mahnung senden
                                                    </button>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {activeTab === 'BUDGET' && (
                    <div className="space-y-6">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <div className="flex justify-between items-center mb-8">
                                <h3 className="text-xl font-bold flex items-center gap-2"><Calculator size={20}/> Budget {selectedYear}</h3>
                                <button onClick={handleSaveBudget} disabled={isSavingBudget} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg disabled:opacity-50">
                                    {isSavingBudget ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />} Speichern
                                </button>
                            </div>

                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
                                <div>
                                    <h4 className="font-bold text-lg mb-4 text-emerald-600 border-b border-stone-100 pb-2">Einnahmen (Ertrag)</h4>
                                    <div className="space-y-3">
                                        {accounts.filter(a => a.class === 'REVENUE').map(acc => (
                                            <div key={acc.id} className="flex items-center justify-between gap-4">
                                                <div className="flex-1">
                                                    <p className="font-bold text-sm text-stone-800">{acc.code} {acc.name}</p>
                                                </div>
                                                <div className="w-32 relative">
                                                    <input type="number" value={budgetData[acc.code] || ''} onChange={e => handleBudgetChange(acc.code, e.target.value)} className="w-full p-2 pl-3 pr-8 bg-stone-50 border border-stone-200 rounded-lg outline-none font-mono text-right" placeholder="0" />
                                                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-stone-400 font-bold">CHF</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                    <div className="mt-6 pt-4 border-t border-stone-200 flex justify-between items-center">
                                        <span className="font-bold text-stone-500 uppercase tracking-widest text-xs">Total Einnahmen</span>
                                        <span className="font-display font-bold text-xl text-emerald-600">{budgetStats.totalRevenue.toFixed(0)} CHF</span>
                                    </div>
                                </div>

                                <div>
                                    <h4 className="font-bold text-lg mb-4 text-rose-500 border-b border-stone-100 pb-2">Ausgaben (Aufwand)</h4>
                                    <div className="space-y-3">
                                        {accounts.filter(a => a.class === 'EXPENSE').map(acc => (
                                            <div key={acc.id} className="flex items-center justify-between gap-4">
                                                <div className="flex-1">
                                                    <p className="font-bold text-sm text-stone-800">{acc.code} {acc.name}</p>
                                                </div>
                                                <div className="w-32 relative">
                                                    <input type="number" value={budgetData[acc.code] || ''} onChange={e => handleBudgetChange(acc.code, e.target.value)} className="w-full p-2 pl-3 pr-8 bg-stone-50 border border-stone-200 rounded-lg outline-none font-mono text-right" placeholder="0" />
                                                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-stone-400 font-bold">CHF</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                    <div className="mt-6 pt-4 border-t border-stone-200 flex justify-between items-center">
                                        <span className="font-bold text-stone-500 uppercase tracking-widest text-xs">Total Ausgaben</span>
                                        <span className="font-display font-bold text-xl text-rose-500">{budgetStats.totalExpense.toFixed(0)} CHF</span>
                                    </div>
                                </div>
                            </div>

                            <div className={`mt-12 p-6 rounded-2xl border flex justify-between items-center ${budgetStats.result >= 0 ? 'bg-emerald-50 border-emerald-100' : 'bg-rose-50 border-rose-100'}`}>
                                <div>
                                    <p className="text-sm font-bold uppercase tracking-widest mb-1 text-stone-500">Budgetiertes Ergebnis</p>
                                    <p className={`text-3xl font-display font-bold ${budgetStats.result >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>{budgetStats.result >= 0 ? 'Gewinn' : 'Verlust'}</p>
                                </div>
                                <div className="text-right">
                                    <p className={`text-4xl font-display font-bold ${budgetStats.result >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>{Math.abs(budgetStats.result).toFixed(0)} <span className="text-xl">CHF</span></p>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'SETTINGS' && (
                    <div className="max-w-3xl mx-auto space-y-8">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><Banknote size={20}/> Bank & QR Settings</h3>
                            <div className="space-y-6">
                                <div className="p-4 bg-blue-50 border border-blue-100 rounded-2xl flex gap-4 items-start">
                                    <Info className="text-blue-500 shrink-0 mt-1" size={20}/>
                                    <div className="text-xs text-blue-800 leading-relaxed">
                                        <p className="font-bold mb-1">Unterschied IBAN vs. QR-IBAN:</p>
                                        <ul className="list-disc ml-4 space-y-1">
                                            <li><strong>Standard IBAN:</strong> Wird für normale Überweisungen ohne 27-stellige Referenz genutzt.</li>
                                            <li><strong>QR-IBAN:</strong> Spezielle Nummer deiner Bank (IID 30000-31999). <strong>Zwingend erforderlich</strong>, wenn du die automatisierte 27-stellige Referenz für den Abgleich nutzen willst.</li>
                                        </ul>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Standard IBAN (für normale Zahlungen)</label>
                                        <input value={paymentSettings.iban} onChange={e => setPaymentSettings({...paymentSettings, iban: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono" placeholder="CH..." />
                                    </div>
                                    
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1 flex items-center gap-2">QR-IBAN (Zwingend für 27-stellige Referenz) <span className="bg-primary/10 text-primary text-[8px] px-1.5 py-0.5 rounded font-bold">EMPFOHLEN</span></label>
                                        <input value={paymentSettings.qrIban || ''} onChange={e => setPaymentSettings({...paymentSettings, qrIban: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono border-primary/20 focus:border-primary" placeholder="CH..." />
                                        <p className="text-[10px] text-stone-400 mt-1 italic">Falls leer, wird die Standard IBAN für den QR-Code verwendet (ohne 27-stellige Referenz).</p>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Bank Name</label>
                                            <input value={paymentSettings.bankName} onChange={e => setPaymentSettings({...paymentSettings, bankName: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Kontoinhaber</label>
                                            <input value={paymentSettings.accountHolder} onChange={e => setPaymentSettings({...paymentSettings, accountHolder: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                    </div>
                                    <div className="pt-4 border-t border-stone-50">
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Adresse der Bank / des Inhabers</label>
                                        <input value={paymentSettings.street} onChange={e => setPaymentSettings({...paymentSettings, street: e.target.value})} placeholder="Strasse" className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none mb-2" />
                                        <div className="flex gap-2">
                                            <input value={paymentSettings.zip} onChange={e => setPaymentSettings({...paymentSettings, zip: e.target.value})} placeholder="PLZ" className="w-24 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                            <input value={paymentSettings.city} onChange={e => setPaymentSettings({...paymentSettings, city: e.target.value})} placeholder="Ort" className="flex-1 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                    </div>

                                    {/* TWINT Settings */}
                                    <div className="pt-6 border-t border-stone-100">
                                        <h4 className="text-sm font-bold mb-4 flex items-center gap-2 text-stone-800">
                                            <div className="w-6 h-6 rounded-full bg-[#000000] text-white flex items-center justify-center text-[10px] font-bold">TW</div>
                                            TWINT Einstellungen (Schweiz)
                                        </h4>
                                        <div className="space-y-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">TWINT Nummer (Mobile)</label>
                                                <input value={paymentSettings.twintNumber || ''} onChange={e => setPaymentSettings({...paymentSettings, twintNumber: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder="+41 79 123 45 67" />
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">TWINT PayLink / URL (Optional)</label>
                                                <input value={paymentSettings.twintUrl || ''} onChange={e => setPaymentSettings({...paymentSettings, twintUrl: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder="https://pay.twint.ch/..." />
                                            </div>
                                        </div>
                                    </div>

                                    {/* PayPal Settings */}
                                    <div className="pt-6 border-t border-stone-100">
                                        <h4 className="text-sm font-bold mb-4 flex items-center gap-2 text-stone-800">
                                            <div className="w-6 h-6 rounded-full bg-[#003087] text-white flex items-center justify-center text-[10px] font-bold">PP</div>
                                            PayPal Einstellungen (International)
                                        </h4>
                                        <div className="space-y-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">PayPal E-Mail</label>
                                                <input value={paymentSettings.paypalEmail || ''} onChange={e => setPaymentSettings({...paymentSettings, paypalEmail: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder="zahlungen@verein.ch" />
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">PayPal Client ID (API)</label>
                                                <input value={paymentSettings.paypalClientId || ''} onChange={e => setPaymentSettings({...paymentSettings, paypalClientId: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono text-xs" placeholder="AdX..." />
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">PayPal Secret (API)</label>
                                                <input type="password" value={paymentSettings.paypalSecret || ''} onChange={e => setPaymentSettings({...paymentSettings, paypalSecret: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono text-xs" placeholder="E..." />
                                            </div>
                                        </div>
                                    </div>

                                    <div className="pt-6">
                                        <button onClick={handleSaveSettings} className="w-full bg-stone-900 text-white py-4 rounded-xl font-bold hover:bg-black transition-all shadow-lg flex items-center justify-center gap-2">
                                            <Save size={18}/> {t('admin.hub.title')} Speichern
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>

            {/* MODALS */}
            <AnimatePresence>
                {showCreateModal && (
                    <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/80 backdrop-blur-md">
                        <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-white w-full max-w-2xl rounded-[2rem] overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
                            <div className="p-6 border-b border-stone-100 flex justify-between items-center">
                                <h3 className="text-xl font-bold">Rechnung erstellen</h3>
                                <button onClick={() => setShowCreateModal(false)} className="p-2 hover:bg-stone-100 rounded-full"><X size={20}/></button>
                            </div>
                            <div className="p-6 overflow-y-auto">
                                <div className="flex gap-2 mb-6 bg-stone-50 p-1 rounded-xl w-fit">
                                    <button onClick={() => setInvoiceMode('SINGLE')} className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${invoiceMode === 'SINGLE' ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>Einzelrechnung</button>
                                    <button onClick={() => setInvoiceMode('MULTI')} className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${invoiceMode === 'MULTI' ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>Sammelrechnung</button>
                                </div>

                                {invoiceMode === 'SINGLE' && (
                                    <div className="space-y-4">
                                        <div className="flex gap-4 mb-4">
                                            <label className="flex items-center gap-2 text-sm font-bold cursor-pointer">
                                                <input type="radio" checked={recipientMode === 'MEMBER'} onChange={() => setRecipientMode('MEMBER')} className="accent-primary" /> Mitglied
                                            </label>
                                            <label className="flex items-center gap-2 text-sm font-bold cursor-pointer">
                                                <input type="radio" checked={recipientMode === 'EXTERNAL'} onChange={() => setRecipientMode('EXTERNAL')} className="accent-primary" /> Extern
                                            </label>
                                        </div>

                                        {recipientMode === 'MEMBER' ? (
                                            <div>
                                                <label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Mitglied auswählen</label>
                                                <select value={newInvoice.userId || ''} onChange={e => setNewInvoice({...newInvoice, userId: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none">
                                                    <option value="">Bitte wählen...</option>
                                                    {users.map(u => <option key={u.id} value={u.id}>{u.displayName} ({u.email})</option>)}
                                                </select>
                                            </div>
                                        ) : (
                                            <div className="grid grid-cols-2 gap-4">
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Name</label><input value={customRecipient.name} onChange={e => setCustomRecipient({...customRecipient, name: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">E-Mail</label><input value={customRecipient.email} onChange={e => setCustomRecipient({...customRecipient, email: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Strasse</label><input value={customRecipient.address} onChange={e => setCustomRecipient({...customRecipient, address: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">PLZ</label><input value={customRecipient.zip} onChange={e => setCustomRecipient({...customRecipient, zip: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Ort</label><input value={customRecipient.city} onChange={e => setCustomRecipient({...customRecipient, city: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Land</label><input value={customRecipient.country} onChange={e => setCustomRecipient({...customRecipient, country: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            </div>
                                        )}

                                        <div className="grid grid-cols-2 gap-4">
                                            <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Beschreibung</label><input value={newInvoice.description || ''} onChange={e => setNewInvoice({...newInvoice, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Betrag</label><input type="number" value={newInvoice.amount || ''} onChange={e => setNewInvoice({...newInvoice, amount: Number(e.target.value)})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Währung</label><select value={newInvoice.currency || 'CHF'} onChange={e => setNewInvoice({...newInvoice, currency: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"><option value="CHF">CHF</option><option value="EUR">EUR</option></select></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Fälligkeitsdatum</label><input type="date" value={newInvoice.dueDate || ''} onChange={e => setNewInvoice({...newInvoice, dueDate: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                        </div>
                                    </div>
                                )}

                                {invoiceMode === 'MULTI' && (
                                    <div className="space-y-4">
                                        <div className="flex justify-between items-center mb-4">
                                            <div className="flex gap-2 bg-stone-50 p-1 rounded-xl">
                                                {(['ALL', 'ACTIVE', 'INACTIVE', 'NO_FEE_PAID'] as const).map(f => (
                                                    <button key={f} onClick={() => setMultiSelectFilter(f)} className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${multiSelectFilter === f ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>{f}</button>
                                                ))}
                                            </div>
                                            <button onClick={selectAllFiltered} className="text-xs font-bold text-primary hover:underline">Alle auswählen ({multiSelectUsers.length})</button>
                                        </div>
                                        <div className="max-h-64 overflow-y-auto border border-stone-200 rounded-xl divide-y divide-stone-100">
                                            {multiSelectUsers.map(u => (
                                                <label key={u.id} className="flex items-center gap-3 p-3 hover:bg-stone-50 cursor-pointer">
                                                    <input type="checkbox" checked={selectedInvoiceUserIds.has(u.id)} onChange={() => toggleUserSelection(u.id)} className="accent-primary w-4 h-4 rounded" />
                                                    <div>
                                                        <p className="font-bold text-sm">{u.displayName}</p>
                                                        <p className="text-xs text-stone-500">{u.email}</p>
                                                    </div>
                                                </label>
                                            ))}
                                        </div>
                                        <div className="grid grid-cols-2 gap-4 mt-4">
                                            <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Beschreibung</label><input value={newInvoice.description || ''} onChange={e => setNewInvoice({...newInvoice, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">Fälligkeitsdatum</label><input type="date" value={newInvoice.dueDate || ''} onChange={e => setNewInvoice({...newInvoice, dueDate: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                        </div>
                                    </div>
                                )}
                            </div>
                            <div className="p-6 border-t border-stone-100 bg-stone-50 flex justify-end gap-4">
                                <button onClick={() => setShowCreateModal(false)} className="px-6 py-3 rounded-xl font-bold text-stone-500 hover:bg-stone-200 transition-colors">Abbrechen</button>
                                <button onClick={handleCreateInvoice} className="px-6 py-3 rounded-xl font-bold bg-stone-900 text-white hover:bg-black transition-colors shadow-lg">Rechnung(en) erstellen</button>
                            </div>
                        </motion.div>
                    </div>
                )}
                {viewInvoice && paymentSettings && (
                    <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/80 backdrop-blur-md">
                        <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-stone-100 w-full max-w-4xl rounded-[2rem] overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
                            <div className="p-4 border-b border-stone-200 flex justify-between items-center bg-white"><h3 className="font-bold text-stone-800">Preview Invoice #{viewInvoice.invoiceNumber}</h3><div className="flex gap-2"><button onClick={handleDownloadPdf} className="px-4 py-2 bg-stone-900 text-white rounded-lg text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors"><Download size={14} /> Download PDF</button><button onClick={() => setViewInvoice(null)} className="p-2 hover:bg-stone-100 rounded-lg text-stone-500"><X size={20}/></button></div></div>
                            <div className="flex-1 overflow-y-auto p-8 flex justify-center custom-scrollbar">
                                <div id="invoice-preview-content" className="bg-white shadow-xl w-[210mm] min-h-[297mm] p-[20mm] text-stone-900 relative flex flex-col">
                                     <div className="flex justify-between mb-12"><div><div className="flex items-center gap-2 mb-4"><div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-white font-bold text-xs">SK</div><span className="font-display font-bold italic text-xl">Shoqata Koretini</span></div><h1 className="text-4xl font-bold text-stone-900 mb-2">INVOICE</h1><p className="text-sm text-stone-500 font-mono">#{viewInvoice.invoiceNumber}</p><p className="text-sm text-stone-500 mt-1">Date: {new Date(viewInvoice.timestamp?.toDate()).toLocaleDateString()}</p></div><div className="text-right text-sm leading-relaxed"><p className="font-bold text-lg mb-1">{paymentSettings.accountHolder}</p><p>{paymentSettings.street}</p><p>{paymentSettings.zip} {paymentSettings.city}</p><p>{paymentSettings.country}</p><p className="mt-2 text-stone-500">{paymentSettings.contactEmail || 'info@koretini.org'}</p></div></div>
                                     <div className="mb-16 bg-stone-50 p-6 rounded-xl border border-stone-100"><p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-3">Bill To:</p><p className="font-bold text-xl">{getQrData(viewInvoice)?.debtor.name}</p><p className="text-stone-600 text-lg whitespace-pre-line">{getQrData(viewInvoice)?.debtor.address}<br/>{getQrData(viewInvoice)?.debtor.zip} {getQrData(viewInvoice)?.debtor.city}</p></div>
                                     <table className="w-full mb-12"><thead><tr className="border-b-2 border-stone-900 text-left text-xs font-bold uppercase tracking-widest"><th className="py-3">Description</th><th className="py-3 text-right">Amount</th></tr></thead><tbody><tr className="border-b border-stone-100"><td className="py-6 text-lg font-medium">{viewInvoice.description}</td><td className="py-6 text-right font-mono text-lg">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</td></tr></tbody><tfoot><tr><td className="py-6 font-bold text-right text-lg">Total Due</td><td className="py-6 text-right font-bold text-3xl">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</td></tr></tfoot></table>
                                     <div className="mt-auto">
                                        <p className="text-sm text-stone-500 mb-8 italic text-center">Thank you for your contribution.</p>
                                        <div className="border-t-2 border-dashed border-stone-300 pt-8">
                                            {viewInvoice.method === 'QR_BILL' && (
                                                <div className="space-y-8">
                                                    <SwissQRBill data={getQrData(viewInvoice)!} />
                                                    {paymentSettings.twintNumber && (
                                                        <div className="bg-stone-50 p-6 rounded-xl border border-stone-200 text-center">
                                                            <h4 className="font-bold text-stone-800 mb-2 flex items-center justify-center gap-2">
                                                                <div className="w-6 h-6 rounded-full bg-[#000000] text-white flex items-center justify-center text-[10px] font-bold">TW</div>
                                                                TWINT Zahlung
                                                            </h4>
                                                            <p className="text-sm text-stone-600 mb-4">Zahlen Sie bequem per TWINT an folgende Nummer:</p>
                                                            <p className="text-2xl font-mono font-bold tracking-widest">{paymentSettings.twintNumber}</p>
                                                            {paymentSettings.twintUrl && (
                                                                <div className="mt-4 flex justify-center">
                                                                    <div className="p-2 bg-white rounded-xl border border-stone-200">
                                                                        <QRCodeSVG value={paymentSettings.twintUrl} size={120} />
                                                                    </div>
                                                                </div>
                                                            )}
                                                        </div>
                                                    )}
                                                </div>
                                            )}
                                            {viewInvoice.method === 'GIRO_CODE' && (
                                                <div className="bg-stone-50 p-8 rounded-2xl border border-stone-200 flex items-center gap-8">
                                                    <div className="p-4 bg-white rounded-xl border border-stone-200 shadow-sm">
                                                        <QRCodeSVG 
                                                            value={`BCD\n002\n1\nSCT\n${paymentSettings.bic || ''}\n${paymentSettings.accountHolder}\n${paymentSettings.iban.replace(/\s/g, '')}\nEUR${viewInvoice.amount.toFixed(2)}\n\n\n${viewInvoice.invoiceNumber}\n`} 
                                                            size={150} 
                                                        />
                                                    </div>
                                                    <div>
                                                        <h4 className="font-bold text-xl text-stone-800 mb-2">GiroCode (SEPA)</h4>
                                                        <p className="text-sm text-stone-600 mb-4">Scannen Sie diesen Code mit Ihrer Banking-App, um die Überweisung automatisch auszufüllen.</p>
                                                        <div className="space-y-1 text-sm font-mono">
                                                            <p><span className="text-stone-400">IBAN:</span> {paymentSettings.iban}</p>
                                                            <p><span className="text-stone-400">BIC:</span> {paymentSettings.bic}</p>
                                                            <p><span className="text-stone-400">Empfänger:</span> {paymentSettings.accountHolder}</p>
                                                            <p><span className="text-stone-400">Betrag:</span> {viewInvoice.amount.toFixed(2)} EUR</p>
                                                            <p><span className="text-stone-400">Verwendungszweck:</span> {viewInvoice.invoiceNumber}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
                                            {viewInvoice.method === 'PAYPAL' && (
                                                <div className="bg-[#003087]/5 p-8 rounded-2xl border border-[#003087]/20 text-center">
                                                    <h4 className="font-bold text-xl text-[#003087] mb-2 flex items-center justify-center gap-2">
                                                        <div className="w-8 h-8 rounded-full bg-[#003087] text-white flex items-center justify-center text-xs font-bold">PP</div>
                                                        PayPal Zahlung
                                                    </h4>
                                                    <p className="text-sm text-stone-600 mb-6">Bitte senden Sie den Betrag an unsere PayPal-Adresse. Geben Sie als Verwendungszweck Ihre Rechnungsnummer an.</p>
                                                    <div className="inline-block bg-white px-6 py-4 rounded-xl border border-stone-200 shadow-sm">
                                                        <p className="text-xs text-stone-400 uppercase tracking-widest mb-1">PayPal E-Mail</p>
                                                        <p className="text-lg font-bold font-mono">{paymentSettings.paypalEmail || 'Nicht konfiguriert'}</p>
                                                    </div>
                                                    <div className="mt-6 text-sm">
                                                        <p><span className="text-stone-500">Betrag:</span> <span className="font-bold">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</span></p>
                                                        <p><span className="text-stone-500">Verwendungszweck:</span> <span className="font-bold">{viewInvoice.invoiceNumber}</span></p>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default AdminFinance;