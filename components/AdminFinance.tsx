import React, { useState, useEffect, useMemo } from 'react';
import CountrySelect from './ui/CountrySelect';
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
  Info,
  LayoutTemplate
} from 'lucide-react';
import { db } from '../services/datenzugriff';
import { supabase } from '@/services/supabase-bridge';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, doc, updateDoc, deleteDoc, writeBatch, setDoc, getDoc } from '@/services/supabase-bridge';
import { Payment, UserProfile, GlobalPaymentSettings, Account, JournalEntry } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { motion, AnimatePresence } from 'framer-motion';
import { billingYearOf, isOverdue } from '../lib/memberQuality';
import { useTranslation } from '../context/LanguageContext';
import MemberPicker from './ui/MemberPicker';
import { hasUsableEmail } from '../lib/memberEmail';
import { mahnungSenden } from '../lib/mahnung';
import { postausgangBereit } from '../services/mailService';
import SwissQRBill from './SwissQRBill';
import { QrBillData } from '../services/qrBillService';
import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import { sendEmail } from '../services/mailService';
import { erzeugeRechnungPdf } from '../lib/rechnungpdf';
import { rechnungsmailBauen } from '../lib/rechnungsmail';
import { briefEinreihen, zahlungsangabenPruefen, postArbeiterAnstossen } from '../lib/postversand';
import { zustellweg } from '../lib/erfassen';
import { istSchweiz } from '../services/qrBillService';
import { textwerkLaden, sprachenFuer, textFuer, alsHtml, type Textwerk } from '../lib/textbaustein';
import { QRCodeSVG } from 'qrcode.react';
import AdminRechnungsdesigner from './AdminRechnungsdesigner';
import PostGuthabenDialog from './PostGuthabenDialog';
import RechnungsAssistent from './RechnungsAssistent';
import Rechnungsblatt from './Rechnungsblatt';
import { layoutLesen, VORGABE, type Rechnungslayout } from '../lib/rechnungslayout';

interface AdminFinanceProps {
    viewMode: 'LIST' | 'GRID' | 'KANBAN';
    selectedYear: number;
}

// Eine Zeile im Budget: Konto, Planzahl, Ist -- und wie weit das eine das
// andere erreicht.
//
// Das Ist stand vorher nirgends. Ein Verein mit Eingaengen sah ueberall 0
// und hielt das Budget fuer kaputt; es zeigte nur nie, was wirklich
// gebucht wurde.
//
// Der Balken bleibt weg, solange kein Plan steht: ein Balken ohne
// Bezugsgroesse zeigt entweder nichts oder immer 100 Prozent, und beides
// ist eine Luege.
const BudgetZeile: React.FC<{
  konto: Account;
  plan?: number;
  ist: number;
  aendern: (wert: string) => void;
}> = ({ konto, plan, ist, aendern }) => {
  const ertrag = konto.class === 'REVENUE';
  const hatPlan = Number(plan) > 0;
  // Der Balken klemmt bei 100 Prozent -- er kann nicht laenger werden als
  // seine Spur. Die ZAHL darf das nicht uebernehmen: 1200 von 1000 sind
  // 120 Prozent, und genau diese Ueberschreitung ist das, was man sehen
  // will. Ein Balken, der bei 100 steht, waehrend 120 gemeint sind, ist
  // keine Vereinfachung, sondern eine falsche Angabe.
  const anteil = hatPlan ? Math.round((ist / Number(plan)) * 100) : 0;
  const balken = Math.max(0, Math.min(100, anteil));
  // Bei Ertraegen ist mehr als geplant gut, bei Aufwaenden schlecht.
  const guenstig = ertrag ? ist >= Number(plan) : ist <= Number(plan);

  return (
    <div className="py-2">
      <div className="flex items-center justify-between gap-3">
        <p className="font-bold text-sm text-stone-800 flex-1 min-w-0 truncate">
          {konto.code} {konto.name}
        </p>
        <div className="text-right tabular-nums shrink-0 w-24">
          <p className={`font-mono text-sm font-bold ${ist === 0 ? 'text-stone-300' : ertrag ? 'text-emerald-600' : 'text-rose-500'}`}>
            {ist.toLocaleString('de-CH', { minimumFractionDigits: 2 })}
          </p>
        </div>
        <div className="w-28 relative shrink-0">
          <input type="number" value={plan ?? ''} onChange={e => aendern(e.target.value)}
                 className="w-full p-2 pl-3 pr-8 bg-stone-50 border border-stone-200 rounded-lg outline-none font-mono text-right text-sm"
                 placeholder="0" />
          <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[10px] text-stone-400 font-bold">CHF</span>
        </div>
      </div>
      {hatPlan && (
        <div className="flex items-center gap-2 mt-1.5 pr-28">
          <div className="h-1 flex-1 bg-stone-100 rounded-full overflow-hidden">
            <div className={`h-full rounded-full ${guenstig ? 'bg-emerald-400' : 'bg-amber-400'}`}
                 style={{ width: `${balken}%` }} />
          </div>
          <span className={`text-[10px] tabular-nums w-12 text-right ${anteil > 100 && !ertrag ? 'text-rose-500 font-bold' : 'text-stone-400'}`}>
            {anteil}%
          </span>
        </div>
      )}
    </div>
  );
};

const AdminFinance: React.FC<AdminFinanceProps> = ({ viewMode, selectedYear }) => {
    const { t, loc } = useTranslation();
    const { showAlert, showConfirm } = useFeedback();
    
    // Tabs
    // Das Layout der Rechnung. Wird es im Designer geaendert, aendert sich
    // die gedruckte Rechnung mit -- sonst waere der Designer Zierde.
    const [rechnungslayout, setRechnungslayout] = useState<Rechnungslayout>(VORGABE);
    const [activeTab, setActiveTab] = useState<'OVERVIEW' | 'INVOICES' | 'DUNNING' | 'BUDGET' | 'DESIGN' | 'SETTINGS'>('OVERVIEW');

    // Data
    const [payments, setPayments] = useState<Payment[]>([]);
    const [users, setUsers] = useState<UserProfile[]>([]);
    const [accounts, setAccounts] = useState<Account[]>([]); 
    // Vereinsname fuer Betreff und Beleg; stand bisher fest als "Shoqata Koretini".
    const [branding, setBranding] = useState<any>({});
    // Zugangsdaten liegen nicht mehr in settings, sondern in einer
    // Tabelle, die kein angemeldetes Konto lesen kann. Was hier steht,
    // ist der STAND -- hinterlegt oder nicht, seit wann, letzte vier
    // Zeichen -- und nie der Wert. Fuenf Vorstandsmitglieder konnten das
    // Geheimnis vorher im Browser auslesen, und gebraucht hat es dort
    // niemand.
    const [ppStand, setPpStand] = useState<any>(null);
    const [ppClient, setPpClient] = useState('');
    const [ppSecret, setPpSecret] = useState('');
    const [ppLaeuft, setPpLaeuft] = useState(false);
    const [budgetData, setBudgetData] = useState<Record<string, number>>({}); 
    // Das Journal fuer die Ist-Spalte. Das Budget zeigte bis zum 29.09.2026
    // ausschliesslich Planzahlen -- ein Verein mit CHF 9'144 Eingang sah
    // ueberall 0 und hielt das fuer einen Fehler. Es war keiner: das Ist kam
    // dort schlicht nicht vor. Ein Budget ohne Ist beantwortet die einzige
    // Frage nicht, die man an ein Budget hat.
    const [journal, setJournal] = useState<JournalEntry[]>([]);
    const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings>({
        iban: '', bankName: '', bic: '', accountHolder: '', street: '', zip: '', city: '', country: 'Switzerland', paypalEmail: '', currency: 'CHF', annualFeeAmount: 100
    });
    
    const invoiceAssociation = loc(branding.associationName) || paymentSettings.accountHolder || '';

    // Kann ein Mitglied diese Rechnung ueberhaupt bezahlen?
    //
    // Gemessen bei Koretini am 09.10.: settings/payment ist leer, im ganzen
    // System steht keine IBAN. Die Rechnung entstand trotzdem -- ohne
    // QR-Code, mit leerer Zeile "Kontoinhaber:". Das Mitglied haette eine
    // Rechnung bekommen, die es nicht bezahlen kann, und der Verein haette
    // eine Erfolgsmeldung gesehen.
    // Dieselbe Regel wie beim Postversand, aus einer Quelle. Zwei
    // Fassungen hiessen: eine wird irgendwann milder, und dann geht eine
    // unbezahlbare Rechnung genau auf dem anderen Weg hinaus.
    const zahlwegFehlt = (): string | null => {
        const p: any = paymentSettings;
        const z = zahlungsangabenPruefen({
            name: p.accountHolder, iban: p.iban, qrIban: p.qrIban,
            paypal: p.paypalEmail, twint: p.twintNumber,
        });
        return z.ok ? null : (z.grund || 'Es fehlt eine Zahlungsverbindung');
    };
    const invoiceInitials = invoiceAssociation.trim().split(/\s+/).slice(0, 2).map(w => w[0] || '').join('').toUpperCase() || 'V';

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

        const unsubJournal = onSnapshot(collection(db, 'accounting_journal'), (snap) => {
            setJournal(snap.docs.map(d => ({ id: d.id, ...d.data() } as JournalEntry)));
        });

        const qAccounts = query(collection(db, 'accounting_accounts'), orderBy('code'));
        const unsubAccounts = onSnapshot(qAccounts, (snap) => {
            setAccounts(snap.docs.map(d => d.data() as Account));
        });

        const unsubSettings = onSnapshot(doc(db, 'settings', 'payment'), (snap) => {
            if(snap.exists()) setPaymentSettings(snap.data() as GlobalPaymentSettings);
        });

        const unsubBranding = onSnapshot(doc(db, 'public_settings', 'branding'), (snap) => {
            if(snap.exists()) setBranding(snap.data());
        });

        return () => { unsub(); unsubUsers(); unsubJournal(); unsubAccounts(); unsubSettings(); unsubBranding(); };
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

    // Nach dem Beitragsjahr filtern, nicht nach dem Entstehungszeitpunkt. Eine
    // im Januar gestellte Rechnung fuer das Vorjahr gehoert sonst ins falsche
    // Jahr; gemessen betraf das 324 gegen 321 Zahlungen fuer 2026. Dieselbe
    // Regel wie in der Vorstandsansicht und bei den Beitragskennzeichen.
    const yearPayments = useMemo(
        () => payments.filter(p => billingYearOf(p) === selectedYear),
        [payments, selectedYear]
    );
    
    // Wer eine Rechnung sucht, sucht in aller Regel nach der Person -- nicht
    // nach einer Rechnungsnummer, die er nicht auswendig kennt. Verglichen
    // wurden bisher nur Nummer und Beschreibung, weshalb die Eingabe eines
    // Namens nie etwas fand.
    const nameNachId = useMemo(() => {
        const karte = new Map<string, string>();
        users.forEach((u: any) => {
            karte.set(u.id, [u.displayName, u.firstName, u.lastName, u.email]
                .filter(Boolean).join(' ').toLowerCase());
        });
        return karte;
    }, [users]);

    const filteredPayments = useMemo(() => {
        const suche = searchTerm.toLowerCase().trim();
        return yearPayments.filter(p => {
            const matchesSearch = !suche
                || p.invoiceNumber?.toLowerCase().includes(suche)
                || p.description?.toLowerCase().includes(suche)
                || (p.userId ? nameNachId.get(p.userId)?.includes(suche) : false)
                // Rechnungen an einen frei erfassten Empfaenger haben kein
                // Mitglied dahinter -- deren Name steht an der Zahlung selbst.
                || (p as any).customRecipient?.name?.toLowerCase().includes(suche);
            
            let matchesFilter = true;
            if (filterStatus === 'TO_PRINT') {
                matchesFilter = perPost(p) && p.status !== 'PAID';
            } else if (filterStatus !== 'ALL') {
                matchesFilter = p.status === filterStatus;
            }
            
            return matchesSearch && matchesFilter;
        });
    }, [yearPayments, searchTerm, filterStatus, nameNachId]);

    const overduePayments = useMemo(() => {
        // Dieselbe Regel wie im Armaturenbrett und in der Statistik --
        // vorher stand sie hier als eigene Fassung und die beiden Ansichten
        // zeigten Verschiedenes.
        return payments.filter(p => isOverdue(p));
    }, [payments]);

    // Was im gewaehlten Jahr tatsaechlich gebucht wurde, je Konto.
    //
    // Doppelte Buchfuehrung: ein Ertrag steht im Haben, ein Aufwand im Soll.
    // Darum fuer Ertragskonten Haben minus Soll und fuer Aufwandskonten Soll
    // minus Haben -- sonst kaeme der Aufwand negativ heraus und eine
    // Stornobuchung wuerde falsch herum zaehlen.
    //
    // Gerechnet wird aus dem Journal, nicht aus den Zahlungen: der Ertrag
    // entsteht beim Rechnungstellen (1100/3000), nicht beim Zahlungseingang.
    // Fuer Koretini sind das 2026 CHF 38'044 gestellt gegenueber CHF 9'144
    // eingegangen -- beides richtig, aber nur das Erste gehoert ins Budget.
    const istWerte = useMemo(() => {
        const nachKonto: Record<string, number> = {};
        const klasse = (code?: string) => accounts.find(a => a.code === code)?.class;
        journal.forEach(b => {
            const betrag = Number(b.amount) || 0;
            if (String(b.date || '').slice(0, 4) !== String(selectedYear)) return;
            if (b.creditCode) {
                const k = klasse(b.creditCode);
                if (k === 'REVENUE') nachKonto[b.creditCode] = (nachKonto[b.creditCode] || 0) + betrag;
                if (k === 'EXPENSE') nachKonto[b.creditCode] = (nachKonto[b.creditCode] || 0) - betrag;
            }
            if (b.debitCode) {
                const k = klasse(b.debitCode);
                if (k === 'EXPENSE') nachKonto[b.debitCode] = (nachKonto[b.debitCode] || 0) + betrag;
                if (k === 'REVENUE') nachKonto[b.debitCode] = (nachKonto[b.debitCode] || 0) - betrag;
            }
        });
        return nachKonto;
    }, [journal, accounts, selectedYear]);

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
        let istRevenue = 0, istExpense = 0;
        accounts.forEach(a => {
            const w = istWerte[a.code] || 0;
            if (a.class === 'REVENUE') istRevenue += w;
            if (a.class === 'EXPENSE') istExpense += w;
        });
        return {
            totalRevenue, totalExpense, result: totalRevenue - totalExpense,
            istRevenue, istExpense, istResult: istRevenue - istExpense,
        };
    }, [budgetData, accounts, istWerte]);

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
        return filteredPayments.filter(p => perMail(p) && p.status !== 'PAID');
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
            showAlert({ type: 'success', message: t('admin.finance.budget_saved', { year: selectedYear }) });
        } catch (e) {
            showAlert({ type: 'error', message: t('admin.finance.save_failed') });
        } finally {
            setIsSavingBudget(false);
        }
    };

    // Gibt zurueck, ob die Nachricht wirklich eingereiht wurde. Vorher gab
    // sie nichts zurueck, und der Sammelversand meldete deshalb Erfolg fuer
    // alles -- auch fuer das, was er gerade abgewiesen hatte.
    // Zustellweg einer Rechnung. "BOTH" heisst beides -- E-Mail UND Brief.
    // Vorher wurde nur auf 'POST' bzw. 'EMAIL' geprueft: eine Rechnung mit
    // BOTH bekam weder den Mail- noch den Postknopf und stand in der Liste
    // als "E-Mail".
    const perPost = (p: Payment) => p.deliveryMethod === 'POST' || (p.deliveryMethod as string) === 'BOTH';
    const perMail = (p: Payment) => p.deliveryMethod === 'EMAIL' || (p.deliveryMethod as string) === 'BOTH';

    // melde: im Assistenten werden Fehler gesammelt statt einzeln gemeldet.
    const handleSendInvoiceEmail = async (payment: Payment, melde?: (grund: string) => void): Promise<boolean> => {
        const fehlerMelden = (m: string) => melde ? melde(m) : showAlert({ type: 'error', message: m });
        let email = '';
        let recipientName = '';
        let anschrift: { adresse?: string; plz?: string; ort?: string; land?: string } = {};
        if (payment.userId === 'EXTERNAL' || !payment.userId) {
            email = payment.customRecipient?.email || '';
            recipientName = payment.customRecipient?.name || 'Guest';
            const c: any = payment.customRecipient || {};
            anschrift = { adresse: c.address, plz: c.zip, ort: c.city, land: c.country };
        } else {
            const u = users.find(user => user.id === payment.userId);
            email = u?.email || '';
            recipientName = u?.displayName || 'Member';
            // address vor street wie beim Brief -- vorher nur address: wer
            // nur eine Strasse hatte, bekam eine Rechnung ohne Strasse.
            anschrift = { adresse: (u as any)?.address || (u as any)?.street, plz: (u as any)?.zip,
                          ort: (u as any)?.city, land: (u as any)?.country };
        }
        if (!hasUsableEmail({ email } as any)) {
            fehlerMelden(t('mail.no_address'));
            return false;
        }
        const fehlt = zahlwegFehlt();
        if (fehlt) {
            fehlerMelden(`${fehlt}. Eine Rechnung ohne Zahlungsverbindung kann niemand bezahlen — `
                + 'bitte zuerst unter Finanzen → Einstellungen eintragen.');
            return false;
        }
        try {
            const association = loc(branding?.associationName) || paymentSettings.accountHolder || '';
            const { subject, html, anhaenge } = await rechnungsmailBauen({
                payment, recipientName, anschrift, paymentSettings, association, t });
            await sendEmail({ to: email, subject, html, attachments: anhaenge });
            if (!melde) showAlert({ type: 'success', message: t('mail.sent_to', { email }) });
            return true;
        } catch (error) {
            fehlerMelden(t('mail.send_failed'));
            return false;
        }
    };

    // Eine Rechnung per Post aufgeben.
    //
    // Eingereiht wird hier, aufgegeben wird vom Arbeiter pingen-versand.
    // Darum zwei getrennte Schritte und zwei getrennte Meldungen: ein
    // eingereihter Brief ist sicher, auch wenn die Uebergabe gerade
    // nicht geht -- er liegt dann in der Warteschlange und geht beim
    // naechsten Lauf. Waere beides ein Schritt, saehe ein fehlender
    // Zugang wie ein verlorener Brief aus.
    const [postLaeuft, setPostLaeuft] = useState<string>('');
    // Vor dem Aufgeben: Guthaben zeigen und gleich kaufen koennen.
    const [postDialog, setPostDialog] = useState<Payment[] | null>(null);
    const [assistent, setAssistent] = useState(false);
    // Der Assistent braucht die neuen Rechnungen so, wie die Datenbank sie
    // gespeichert hat. Sie kommen ueber den laufenden Abgleich herein;
    // gewartet wird, bis alle da sind (hoechstens 20 Sekunden).
    const paymentsRef = React.useRef<Payment[]>([]);
    React.useEffect(() => { paymentsRef.current = payments; }, [payments]);
    const rechnungenHolen = async (ids: string[]): Promise<Payment[]> => {
        const ende = Date.now() + 20000;
        while (Date.now() < ende) {
            const da = ids.map(id => paymentsRef.current.find(p => p.id === id));
            if (da.every(Boolean)) return da as Payment[];
            await new Promise(r => setTimeout(r, 400));
        }
        return ids.map(id => paymentsRef.current.find(p => p.id === id)).filter(Boolean) as Payment[];
    };

    const postDatenBauen = (payment: Payment) => {
        let empfaengerName = '';
        let anschrift: { adresse?: string; plz?: string; ort?: string; land?: string } = {};
        if (payment.userId === 'EXTERNAL' || !payment.userId) {
            const c: any = payment.customRecipient || {};
            empfaengerName = c.name || '';
            anschrift = { adresse: c.address || c.street, plz: c.zip, ort: c.city, land: c.country };
        } else {
            const u: any = users.find(user => user.id === payment.userId);
            empfaengerName = u?.displayName || '';
            // address vor street, wie die QR-Rechnung: sonst steht auf
            // dem Brief die alte Strasse.
            anschrift = { adresse: u?.address || u?.street, plz: u?.zip,
                          ort: u?.city, land: u?.country };
        }
        return {
            empfaengerName, anschrift,
            daten: {
                nummer: payment.invoiceNumber || '',
                datum: (payment as any).issuedAt || new Date().toISOString(),
                faellig: payment.dueDate || null,
                betrag: Number(payment.amount || 0),
                waehrung: (payment.currency as 'CHF' | 'EUR') || 'CHF',
                zweck: payment.description || '',
                referenz: payment.reference || payment.invoiceNumber || undefined,
                verein: {
                    name: paymentSettings.accountHolder || invoiceAssociation,
                    adresse: paymentSettings.street, plz: paymentSettings.zip,
                    ort: paymentSettings.city, land: paymentSettings.country,
                    iban: paymentSettings.iban, qrIban: paymentSettings.qrIban,
                    bic: paymentSettings.bic, bank: paymentSettings.bankName,
                    paypal: paymentSettings.paypalEmail, twint: paymentSettings.twintNumber,
                },
                empfaenger: {
                    name: empfaengerName, adresse: anschrift.adresse,
                    plz: anschrift.plz, ort: anschrift.ort, land: anschrift.land,
                },
            },
        };
    };

    const handlePostAufgeben = async (payment: Payment, still = false, melde?: (grund: string) => void): Promise<boolean> => {
        const { empfaengerName, anschrift, daten } = postDatenBauen(payment);
        // Ohne Anschrift kein Brief. Pingen liest den Empfaenger aus dem
        // PDF; eine leere Adresse gaebe ein gedrucktes Blatt ohne
        // Zustellziel -- bezahlt und weggeworfen.
        if (!empfaengerName || !anschrift.adresse || !anschrift.ort) {
            const m = t('post.keine_adresse', { name: empfaengerName || t('field.recipient') });
            melde ? melde(m) : showAlert({ type: 'error', message: m });
            return false;
        }
        if (!still) setPostLaeuft(payment.id);
        try {
            const e = await briefEinreihen(payment.id, daten as any);
            // Im Sammellauf schweigen: fuenfzig Meldungen sind keine
            // Rueckmeldung, sondern eine Wand. Am Ende steht eine Zahl.
            if (!still) showAlert({ type: 'success', message:
                t('post.eingereiht', { name: empfaengerName, kb: Math.round(e.bytes / 1024), hinweis: e.hinweis }) });
            // Den Arbeiter anstossen, aber sein Scheitern nicht als
            // Scheitern des Briefes melden: der Brief liegt sicher.
            postArbeiterAnstossen(5).catch(() => { /* geht beim naechsten Lauf */ });
            return true;
        } catch (err: any) {
            // Fehler werden auch im Sammellauf gemeldet: eine Zahl am
            // Ende sagt nicht, WARUM zwölf Briefe liegengeblieben sind.
            const m = (still ? `${empfaengerName}: ` : '') + (err?.message || t('post.nicht_eingereiht'));
            melde ? melde(err?.message || t('post.nicht_eingereiht')) : showAlert({ type: 'error', message: m });
            return false;
        } finally {
            if (!still) setPostLaeuft('');
        }
    };

    const handlePostAlleAufgeben = async (liste?: Payment[]) => {
        const offen = liste ?? filteredPayments.filter(p => perPost(p) && p.status !== 'PAID');
        if (!offen.length) return;
        setPostLaeuft('ALLE');
        let gut = 0, schlecht = 0;
        for (const p of offen) {
            // Einer nach dem anderen: post_einreihen hat einen
            // Eindeutigkeitsindex je Rechnung, und ein doppelt
            // abgeschickter Lauf soll am Index scheitern und nicht am
            // Zufall, welcher Aufruf zuerst ankommt.
            const ok = await handlePostAufgeben(p, true);
            ok ? gut++ : schlecht++;
        }
        setPostLaeuft('');
        showAlert({ type: schlecht ? 'error' : 'success', message:
            t('post.sammel_ergebnis', { gut })
            + (schlecht ? t('post.sammel_fehler', { schlecht }) : '.') });
    };

    const handleSendBulkEmails = async () => {
        if (pendingEmailPayments.length === 0) return;

        // Einmal vorher pruefen statt hundertmal dieselbe Fehlermeldung.
        const fehlt = zahlwegFehlt();
        if (fehlt) {
            showAlert({ type: 'error', message:
                `${fehlt}. Es wurde nichts verschickt — bitte zuerst unter `
                + 'Finanzen → Einstellungen eintragen.' });
            return;
        }

        const confirmed = await showConfirm({ title: t('mail.bulk.title'), message: t('mail.bulk.text', { count: pendingEmailPayments.length }), confirmText: t('mail.bulk.confirm'), type: 'primary' });
        if (!confirmed) return;
        setIsSendingEmails(true);
        // Gezaehlt wird, was wirklich durchging. "Sent emails successfully"
        // stand hier fest, auch wenn keine einzige hinausging.
        let gut = 0, schlecht = 0;
        for (const payment of pendingEmailPayments) {
            (await handleSendInvoiceEmail(payment)) ? gut++ : schlecht++;
        }
        setIsSendingEmails(false);
        const bereit = await postausgangBereit();
        showAlert({ type: schlecht ? 'error' : 'success',
            message: schlecht
                ? `${gut} von ${gut + schlecht} eingereiht, ${schlecht} nicht — `
                  + 'meist fehlt eine brauchbare E-Mail-Adresse.'
                : bereit
                  ? `${gut} Rechnungen in den Versand gegeben.`
                  : `${gut} Rechnungen liegen in der Warteschlange — es ist kein `
                    + 'Postausgang eingerichtet.' });
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

    // Der Jahresbeitrag eines Mitglieds -- fuer den Sammellauf und den
    // Rechnungsassistenten, damit beide dieselbe Zahl rechnen.
    //
    // Der hinterlegte Eigenbeitrag wird mit ?? geprueft, nicht mit ||.
    // Ein Betrag von 0 -- Ehrenmitglied, Beitragsbefreiung -- ist eine
    // Aussage und kein fehlender Wert; mit || waere daraus still der
    // volle Standardbeitrag geworden.
    const beitragVon = (u: UserProfile): { amount: number; currency: string } => {
        const standardFee = paymentSettings.fees?.STANDARD?.amount ?? 120;
        const standardCurr = paymentSettings.fees?.STANDARD?.currency ?? 'CHF';
        const groupFee = u.billingGroup === 'KOSOVO' ? paymentSettings.fees?.KOSOVO?.amount
            : u.billingGroup === 'REDUCED' ? paymentSettings.fees?.REDUCED?.amount
            : standardFee;
        const groupCurr = u.billingGroup === 'KOSOVO' ? paymentSettings.fees?.KOSOVO?.currency
            : u.billingGroup === 'REDUCED' ? paymentSettings.fees?.REDUCED?.currency
            : standardCurr;
        const hasOwnFee = u.customAnnualFee !== undefined && u.customAnnualFee !== null;
        const amount = hasOwnFee ? (u.customAnnualFee as number) : (groupFee ?? standardFee);
        const currency = (hasOwnFee ? u.currency : groupCurr) || standardCurr;
        return { amount, currency };
    };

    const handleCreateInvoice = async () => {
        if (invoiceMode === 'SINGLE' && (!newInvoice.amount || !newInvoice.description)) { showAlert({ type: 'error', message: t('admin.finance.fill_amount_desc') }); return; }
        if (invoiceMode === 'SINGLE') {
            if (recipientMode === 'MEMBER' && !newInvoice.userId) { showAlert({ type: 'error', message: t('admin.finance.select_member') }); return; }
            if (recipientMode === 'EXTERNAL' && !customRecipient.name) { showAlert({ type: 'error', message: t('admin.finance.enter_recipient') }); return; }
        } else if (invoiceMode === 'MULTI' && selectedInvoiceUserIds.size === 0) { showAlert({ type: 'error', message: t('admin.finance.select_one_member') }); return; }

        try {
            const batch = writeBatch(db);
            let createdSummary = 'Rechnung erstellt.';
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
                // Der Zustellweg wurde hier fest auf EMAIL gesetzt. Damit
                // konnte eine einzeln erfasste Rechnung NIE per Post gehen
                // -- auch nicht fuer ein Mitglied ohne Mailadresse oder mit
                // ausdruecklichem Wunsch nach Post. Sie landete im
                // Mailversand, der sie wegen fehlender Adresse abwies, und
                // niemand erfuhr davon. Jetzt gilt dieselbe Regel wie im
                // Sammellauf, aus lib/erfassen.
                const empfaenger: any = recipientMode === 'MEMBER'
                  ? users.find(u => u.id === newInvoice.userId)
                  : { email: customRecipient.email, invoiceDeliveryMethod: customRecipient.email ? 'EMAIL' : 'POST' };
                const zustellung = zustellweg(empfaenger || {});

                batch.set(docRef, { ...baseData, method, amount: newInvoice.amount, currency: newInvoice.currency, timestamp: serverTimestamp(), invoiceNumber: `INV-${Date.now().toString().slice(-6)}-${Math.floor(Math.random()*1000).toString().padStart(3, '0')}`, userId: recipientMode === 'MEMBER' ? newInvoice.userId : 'EXTERNAL', deliveryMethod: zustellung, customRecipient: recipientMode === 'EXTERNAL' ? { ...customRecipient, address: `${customRecipient.street}, ${customRecipient.zip} ${customRecipient.city}` } : null });
            } else {
                // Wer fuer dieses Jahr schon eine Beitragsrechnung hat, wird
                // uebersprungen. Ohne diese Pruefung erzeugt ein zweiter Lauf des
                // Sammellaufs fuer jedes aktive Mitglied eine zweite Rechnung --
                // bei ueber 300 Mitgliedern still und schwer rueckgaengig zu machen.
                const alreadyInvoiced = new Set(
                    payments
                        .filter(p => p.type === 'FEE' && p.billingYear === selectedYear && p.userId)
                        .map(p => p.userId as string)
                );
                const candidateIds = invoiceMode === 'MULTI'
                    ? Array.from(selectedInvoiceUserIds)
                    : users.filter(u => u.membershipStatus === 'ACTIVE').map(u => u.id);
                const targetUserIds = candidateIds.filter(id => !alreadyInvoiced.has(id));
                const skippedCount = candidateIds.length - targetUserIds.length;
                let downgradedCount = 0;

                if (targetUserIds.length === 0) {
                    showAlert({ type: 'error', message: t('admin.finance.all_invoiced', { count: candidateIds.length, year: selectedYear }) });
                    return;
                }
                targetUserIds.forEach((uid, index) => {
                    const u = users.find(user => user.id === uid);
                    if (!u) return;
                    const { amount, currency } = beitragVon(u);
                    const hasValidEmail = hasUsableEmail(u);
                    // Wer E-Mail-Versand gewaehlt hat, aber keine brauchbare
                    // Adresse hat, bekommt die Rechnung per Post. Das ist
                    // richtig, darf aber nicht stillschweigend geschehen --
                    // sonst wartet der Vorstand auf einen Versand, der nie
                    // stattfindet. Deshalb wird es unten gemeldet.
                    if (!hasValidEmail && u.invoiceDeliveryMethod !== 'POST') downgradedCount++;
                    let deliveryMethod = zustellweg(u as any);
                    const method = determinePaymentMethod(u.country);
                    
                    const docRef = doc(collection(db, 'payments'));
                    batch.set(docRef, { ...baseData, method, userId: uid, amount, currency, deliveryMethod, timestamp: serverTimestamp(), invoiceNumber: `INV-${Date.now().toString().slice(-6)}-${String(index).padStart(3, '0')}${Math.floor(Math.random()*100).toString().padStart(2, '0')}` });
                });
                createdSummary = skippedCount > 0
                    ? t('admin.finance.bulk_created_skipped', { count: targetUserIds.length, skipped: skippedCount, year: selectedYear })
                    : t('admin.finance.bulk_created', { count: targetUserIds.length });
                if (downgradedCount > 0) {
                    createdSummary += ' ' + t('admin.finance.downgraded', { count: downgradedCount });
                }
            }
            await batch.commit();
            setShowCreateModal(false);
            setNewInvoice({ amount: 0, currency: 'CHF', description: '', userId: '' });
            setMemberSearchTerm('');
            setCustomRecipient({ name: '', email: '', street: '', zip: '', city: '', country: 'Switzerland' });
            setSelectedInvoiceUserIds(new Set());
            showAlert({ type: 'success', message: createdSummary });
        } catch (error) { showAlert({ type: 'error', message: t('admin.finance.invoice_failed') }); }
    };

    const handleDelete = async (id: string) => { if (await showConfirm({ title: t('admin.finance.delete_invoice'), message: t('admin.confirm_delete'), type: 'danger' })) await deleteDoc(doc(db, 'payments', id)); };
    const handleMarkPaid = async (payment: Payment) => { await updateDoc(doc(db, 'payments', payment.id), { status: 'PAID', paidAt: new Date().toISOString() }); showAlert({ type: 'success', message: t('admin.finance.marked_paid') }); };
    const ppStandLaden = async () => {
        const { data, error } = await supabase.rpc('zahlungsgeheimnis_stand');
        if (!error) setPpStand(data);
    };
    React.useEffect(() => { void ppStandLaden(); }, []);

    const ppSpeichern = async () => {
        if (!ppSecret.trim() && !ppClient.trim()) {
            showAlert({ type: 'error', message: 'Bitte Client-ID oder Geheimnis eintragen.' });
            return;
        }
        setPpLaeuft(true);
        try {
            const { data, error } = await supabase.rpc('zahlungsgeheimnis_setzen', {
                p_client_id: ppClient.trim() || null,
                p_secret: ppSecret.trim() || null,
            });
            if (error) throw error;
            setPpStand(data);
            // Die Felder leeren. Sie stehen leer da, weil der Wert nicht
            // zurueckgelesen werden kann -- das ist kein Mangel, sondern
            // der Zweck.
            setPpClient(''); setPpSecret('');
            showAlert({ type: 'success', message: 'Zugangsdaten gespeichert.' });
        } catch (e: any) {
            showAlert({ type: 'error', message: e?.message || '?' });
        } finally { setPpLaeuft(false); }
    };

    const handleSaveSettings = async () => { try {
        // Geheimnisse ausdruecklich herausnehmen. Ohne das schreibt der
        // naechste Klick auf "Speichern" sie wieder in settings/payment --
        // der Umzug waere nach einer Minute rueckgaengig, und niemand
        // haette es gemerkt.
        const { paypalSecret: _s, paypalClientId: _c, ...ohneGeheimnis } =
            paymentSettings as any;
        await setDoc(doc(db, 'settings', 'payment'), ohneGeheimnis); showAlert({ type: 'success', message: t('admin.finance.settings_saved') }); } catch (e) { showAlert({ type: 'error', message: t('admin.finance.settings_failed') }); } };
    // Die Mahnung verschickte bisher NICHTS. Sie setzte die Mahnstufe und
    // meldete "Reminder Level X sent." -- eine Erfolgsmeldung fuer etwas,
    // das nie passiert ist. Jetzt geht ein Brief hinaus, aus dem
    // Textbaustein des Vereins, in der Sprache des Mitglieds.
    // Der Vorgang selbst liegt in lib/mahnung.ts -- dieselbe Stelle, die
    // auch die Floky-Karte ruft. Zwei Fassungen desselben Briefes liefen
    // frueher oder spaeter auseinander.
    const handleSendReminder = async (payment: Payment) => {
        try {
            const u = users.find(x => x.id === payment.userId);
            const r = await mahnungSenden(payment, u, invoiceAssociation);
            showAlert({ type: r.unterwegs ? 'success' : 'error',
                message: r.unterwegs
                  ? `Mahnung ${r.stufe} an ${r.empfaenger} in den Versand gegeben (${r.sprachen.join('/')}).`
                  : `Mahnung ${r.stufe} liegt in der Warteschlange für ${r.empfaenger} — es ist kein `
                    + 'Postausgang eingerichtet, sie geht vorerst nicht hinaus.' });
        } catch (e: any) {
            showAlert({ type: 'error', message: e?.message || t('admin.finance.reminder_failed') });
        }
    };

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
                address: (paymentSettings.street || '') + ' ' + ((paymentSettings.street || '').match(/\d+/) ? '' : '1'), 
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
    useEffect(() => {
        const abL = onSnapshot(doc(db, 'settings', 'rechnungslayout'),
            (d: any) => { if (d.exists()) setRechnungslayout(layoutLesen(d.data())); });
        // branding wird weiter oben schon geladen -- kein zweiter Abruf.
        return () => { abL(); };
    }, []);

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
            {assistent && (
                <RechnungsAssistent users={users} payments={payments} jahr={selectedYear}
                    beitragVon={beitragVon} zahlart={determinePaymentMethod}
                    mailen={(p, melde) => handleSendInvoiceEmail(p, melde)}
                    aufgeben={(p, melde) => handlePostAufgeben(p, true, melde)}
                    holen={rechnungenHolen}
                    onClose={() => setAssistent(false)} />
            )}
            {postDialog && (
                <PostGuthabenDialog anzahl={postDialog.length}
                    onAbbrechen={() => setPostDialog(null)}
                    onAufgeben={() => {
                        const liste = postDialog;
                        setPostDialog(null);
                        if (liste.length === 1) handlePostAufgeben(liste[0]);
                        else handlePostAlleAufgeben(liste);
                    }} />
            )}
            <div className="flex border-b border-stone-100 bg-stone-50/50 overflow-x-auto">
                <button onClick={() => setActiveTab('OVERVIEW')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'OVERVIEW' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><LayoutDashboard size={18}/> {t('admin.finance.overview')}</button>
                <button onClick={() => setActiveTab('INVOICES')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'INVOICES' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><FileText size={18}/> {t('admin.finance.invoices')}</button>
                <button onClick={() => setActiveTab('DUNNING')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'DUNNING' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><BellRing size={18}/> {t('admin.finance.dunning')}{overduePayments.length > 0 && <span className="bg-red-500 text-white text-[10px] px-1.5 py-0.5 rounded-full ml-1">{overduePayments.length}</span>}</button>
                <button onClick={() => setActiveTab('BUDGET')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'BUDGET' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><Calculator size={18}/> {t('admin.finance.budget')}</button>
                <button onClick={() => setActiveTab('DESIGN')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'DESIGN' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><LayoutTemplate size={18}/> {t('admin.finance.design')}</button>
                <button onClick={() => setActiveTab('SETTINGS')} className={`px-8 py-5 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors ${activeTab === 'SETTINGS' ? 'border-primary text-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-transparent text-stone-400 hover:text-stone-900 hover:bg-stone-50'}`}><Settings size={18}/> {t('admin.finance.settings')}</button>
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
                            <div className="bg-white p-8 rounded-3xl border border-stone-100 shadow-sm"><h3 className="text-xl font-bold mb-6">{t('admin.finance.recent_activity')}</h3><div className="space-y-4">{payments.slice(0, 5).map(p => { const u = users.find(u => u.id === p.userId); return (<div key={p.id} className="flex justify-between items-center text-sm border-b border-stone-50 pb-2"><div><p className="font-bold">{u?.displayName || 'External'}</p><p className="text-xs text-stone-400">{new Date(p.timestamp?.toDate()).toLocaleDateString()}</p></div><div className="text-right"><p className="font-mono font-bold tabular-nums">{p.amount.toFixed(2)} {p.currency}</p><span className={`text-[10px] font-bold ${p.status === 'PAID' ? 'text-green-600' : p.status === 'OVERDUE' ? 'text-red-600' : 'text-amber-600'}`}>{p.status}</span></div></div>)})}</div></div>
                        </div>
                    </div>
                )}

                {activeTab === 'INVOICES' && (
                    <div className="space-y-6">
                        <div className="flex flex-col md:flex-row justify-between items-center gap-4 bg-white p-4 rounded-3xl border border-stone-100 shadow-sm">
                            <div className="flex gap-2 w-full md:w-auto"><div className="relative flex-1 md:w-64"><Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={16} /><input value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} placeholder={t('common.search')} className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]"/></div><div className="flex bg-stone-50 p-1 rounded-xl border border-stone-200">{(['ALL', 'TO_PRINT', 'PAID', 'PENDING', 'OVERDUE'] as const).map(s => (<button key={s} onClick={() => setFilterStatus(s)} className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1 ${filterStatus === s ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>{s === 'TO_PRINT' ? <><Printer size={12}/> {t('admin.finance.to_print')}</> : s === 'ALL' ? t('status.all') : s === 'PAID' ? t('board.paid') : s === 'PENDING' ? t('status.pending') : t('admin.finance.overdue')}</button>))}</div>{filterStatus === 'TO_PRINT' && filteredPayments.some(p => perPost(p) && p.status !== 'PAID') && (<button onClick={() => setPostDialog(filteredPayments.filter(p => perPost(p) && p.status !== 'PAID'))} disabled={postLaeuft !== ''} className="px-4 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold hover:bg-stone-800 disabled:opacity-40 flex items-center gap-2 whitespace-nowrap">{postLaeuft === 'ALLE' ? <Loader2 size={14} className="animate-spin" /> : <Printer size={14} />}{t('post.alle_als_brief')}</button>)}</div>
                            <div className="flex gap-2">{pendingEmailPayments.length > 0 && (<button onClick={handleSendBulkEmails} disabled={isSendingEmails} className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-blue-700 transition-all shadow-lg disabled:opacity-50">{isSendingEmails ? <Loader2 className="animate-spin" size={16} /> : <Send size={16} />} Send All Emails ({pendingEmailPayments.length})</button>)}<button onClick={() => setShowCreateModal(true)} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg"><Plus size={16} /> {t('admin.finance.create')}</button></div>
                        </div>
                        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-x-auto"><table className="w-full text-left text-sm"><thead className="bg-stone-50 text-stone-400 font-bold uppercase text-[10px] tracking-widest border-b border-stone-100 sticky top-0 z-10"><tr><th className="px-6 py-4">{t('admin.finance.invoiceNum')}</th><th className="px-6 py-4">{t('field.recipient')}</th><th className="px-6 py-4">{t('field.description')}</th><th className="px-6 py-4">{t('field.date')}</th><th className="px-6 py-4">{t('field.amount')}</th><th className="px-6 py-4">{t('admin.finance.method_via')}</th><th className="px-6 py-4">{t('field.status')}</th><th className="px-6 py-4 text-right">{t('common.actions')}</th></tr></thead><tbody className="divide-y divide-stone-50">{filteredPayments.map(p => { const recipientUser = users.find(u => u.id === p.userId); const recipientName = recipientUser?.displayName || p.customRecipient?.name || 'Unknown'; return (<tr key={p.id} className="hover:bg-stone-50 transition-colors group"><td className="px-6 py-4 font-mono text-xs text-stone-500">{p.invoiceNumber}</td><td className="px-6 py-4 font-bold text-stone-800">{recipientName}</td><td className="px-6 py-4 text-stone-600">{p.description}</td><td className="px-6 py-4 text-stone-500 text-xs">{p.timestamp?.toDate().toLocaleDateString()}</td><td className="px-6 py-4 font-mono font-bold">{p.amount.toFixed(2)} {p.currency}</td><td className="px-6 py-4"><div className="flex flex-col gap-1"><span className="text-[10px] font-bold text-stone-600 uppercase tracking-widest">{p.method === 'QR_BILL' ? 'Swiss QR' : p.method === 'GIRO_CODE' ? 'GiroCode' : p.method === 'PAYPAL' ? 'PayPal' : p.method}</span>{perPost(p) && (<span className="flex items-center gap-1 text-[10px] font-bold text-amber-600 bg-amber-50 px-2 py-1 rounded w-fit"><Printer size={10}/> {t('admin.finance.post')}</span>)}{perMail(p) && (<span className="flex items-center gap-1 text-[10px] font-bold text-sky-700 bg-sky-50 px-2 py-1 rounded w-fit"><Mail size={10}/> {t('field.email')}</span>)}</div></td><td className="px-6 py-4"><span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${p.status === 'PAID' ? 'bg-green-100 text-green-700' : p.status === 'OVERDUE' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{p.status}</span></td><td className="px-6 py-4 text-right"><div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">{perMail(p) && p.status !== 'PAID' && (<button onClick={() => handleSendInvoiceEmail(p)} className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100"><Send size={14} /></button>)}{perPost(p) && p.status !== 'PAID' && (<button onClick={() => setPostDialog([p])} disabled={postLaeuft === p.id} title={t('post.als_brief')} className="p-2 bg-amber-50 text-amber-700 rounded-lg hover:bg-amber-100 disabled:opacity-40">{postLaeuft === p.id ? <Loader2 size={14} className="animate-spin" /> : <Printer size={14} />}</button>)}<button onClick={() => setViewInvoice(p)} className="p-2 bg-stone-100 text-stone-600 rounded-lg hover:bg-stone-200"><Eye size={14} /></button>{p.status !== 'PAID' && (<button onClick={() => handleMarkPaid(p)} className="p-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100"><CheckCircle2 size={14} /></button>)}<button onClick={() => handleDelete(p.id)} className="p-2 bg-red-50 text-red-500 rounded-lg hover:bg-red-100"><Trash2 size={14} /></button></div></td></tr>); })}</tbody></table></div>
                    </div>
                )}

                {activeTab === 'DUNNING' && (
                    <div className="space-y-6">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><BellRing size={20}/> {t('admin.finance.dunning')}</h3>
                            {overduePayments.length === 0 ? (
                                <div className="text-center py-12">
                                    <div className="w-16 h-16 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-4"><CheckCircle2 size={32} /></div>
                                    <h4 className="text-lg font-bold text-stone-900 mb-2">{t('admin.finance.no_overdue')}</h4>
                                    <p className="text-stone-500">{t('admin.finance.no_overdue_text')}</p>
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
                                                        <Send size={14} /> {t('admin.finance.send_reminder')}
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

                {activeTab === 'DESIGN' && (
                    <div className="p-8">
                        <div className="mb-6">
                            <h3 className="text-xl font-bold text-stone-900">{t('rdes.titel')}</h3>
                            <p className="text-xs text-stone-400 mt-1">{t('rdes.untertitel')}</p>
                        </div>
                        <AdminRechnungsdesigner />
                    </div>
                )}

                {activeTab === 'BUDGET' && (
                    <div className="space-y-6">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <div className="flex justify-between items-center mb-8">
                                <div>
                                    <h3 className="text-xl font-bold flex items-center gap-2"><Calculator size={20}/> Budget {selectedYear}</h3>
                                    <p className="text-[11px] text-stone-400 mt-1 max-w-xl leading-relaxed">{t('budget.hinweis')}</p>
                                </div>
                                <button onClick={handleSaveBudget} disabled={isSavingBudget} className="bg-stone-900 text-white px-6 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black transition-all shadow-lg disabled:opacity-50">
                                    {isSavingBudget ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />} Speichern
                                </button>
                            </div>

                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
                                <div>
                                    <h4 className="font-bold text-lg mb-1 text-emerald-600 border-b border-stone-100 pb-2">{t('admin.finance.income')}</h4>
                                    {/* Ohne Spaltenkoepfe weiss niemand, welche Zahl gebucht und
                                        welche geplant ist. */}
                                    <div className="flex items-center justify-between gap-3 pb-2 mb-1 border-b border-stone-50">
                                      <span className="flex-1" />
                                      <span className="w-24 text-right text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('budget.ist')} {selectedYear}</span>
                                      <span className="w-28 text-right text-[10px] font-bold uppercase tracking-widest text-stone-400 pr-2">{t('budget.plan')}</span>
                                    </div>
                                    <div className="space-y-1">
                                        {accounts.filter(a => a.class === 'REVENUE').map(acc => (
                                            <BudgetZeile key={acc.id} konto={acc}
                                                plan={budgetData[acc.code]}
                                                ist={istWerte[acc.code] || 0}
                                                aendern={(w) => handleBudgetChange(acc.code, w)} />
                                        ))}
                                    </div>
                                    <div className="mt-6 pt-4 border-t border-stone-200 flex justify-between items-center">
                                        <span className="font-bold text-stone-500 uppercase tracking-widest text-xs">{t('admin.finance.total_income')}</span>
                                        <span className="flex items-baseline gap-4 tabular-nums">
                                          <span className="font-display font-bold text-xl text-emerald-600">{budgetStats.istRevenue.toLocaleString('de-CH', {maximumFractionDigits:0})}</span>
                                          <span className="font-mono text-sm text-stone-400">/ {budgetStats.totalRevenue.toLocaleString('de-CH', {maximumFractionDigits:0})} CHF</span>
                                        </span>
                                    </div>
                                </div>

                                <div>
                                    <h4 className="font-bold text-lg mb-1 text-rose-500 border-b border-stone-100 pb-2">{t('admin.finance.expenses')}</h4>
                                    {/* Ohne Spaltenkoepfe weiss niemand, welche Zahl gebucht und
                                        welche geplant ist. */}
                                    <div className="flex items-center justify-between gap-3 pb-2 mb-1 border-b border-stone-50">
                                      <span className="flex-1" />
                                      <span className="w-24 text-right text-[10px] font-bold uppercase tracking-widest text-stone-400">{t('budget.ist')} {selectedYear}</span>
                                      <span className="w-28 text-right text-[10px] font-bold uppercase tracking-widest text-stone-400 pr-2">{t('budget.plan')}</span>
                                    </div>
                                    <div className="space-y-1">
                                        {accounts.filter(a => a.class === 'EXPENSE').map(acc => (
                                            <BudgetZeile key={acc.id} konto={acc}
                                                plan={budgetData[acc.code]}
                                                ist={istWerte[acc.code] || 0}
                                                aendern={(w) => handleBudgetChange(acc.code, w)} />
                                        ))}
                                    </div>
                                    <div className="mt-6 pt-4 border-t border-stone-200 flex justify-between items-center">
                                        <span className="font-bold text-stone-500 uppercase tracking-widest text-xs">{t('admin.finance.total_expenses')}</span>
                                        <span className="flex items-baseline gap-4 tabular-nums">
                                          <span className="font-display font-bold text-xl text-rose-500">{budgetStats.istExpense.toLocaleString('de-CH', {maximumFractionDigits:0})}</span>
                                          <span className="font-mono text-sm text-stone-400">/ {budgetStats.totalExpense.toLocaleString('de-CH', {maximumFractionDigits:0})} CHF</span>
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className={`mt-12 p-6 rounded-2xl border flex justify-between items-center ${budgetStats.istResult >= 0 ? 'bg-emerald-50 border-emerald-100' : 'bg-rose-50 border-rose-100'}`}>
                                <div>
                                    <p className="text-sm font-bold uppercase tracking-widest mb-1 text-stone-500">{t('admin.finance.budget_result')} {selectedYear}</p>
                                    {/* Das Ist zuerst: danach wird gefragt. Der Plan daneben,
                                        damit man sieht, wie weit man ist. */}
                                    <p className={`text-3xl font-display font-bold ${budgetStats.istResult >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                                        {budgetStats.istResult >= 0 ? t('admin.finance.profit') : t('admin.finance.loss')}
                                    </p>
                                </div>
                                <div className="text-right">
                                    <p className={`text-4xl font-display font-bold tabular-nums ${budgetStats.istResult >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                                        {Math.abs(budgetStats.istResult).toLocaleString('de-CH', {maximumFractionDigits:0})} <span className="text-xl">CHF</span>
                                    </p>
                                    <p className="text-xs text-stone-400 mt-1 tabular-nums">
                                        {t('budget.geplant')} {budgetStats.result.toLocaleString('de-CH', {maximumFractionDigits:0})} CHF
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'SETTINGS' && (
                    <div className="max-w-3xl mx-auto space-y-8">
                        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                            <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><Banknote size={20}/> {t('admin.finance.bank_qr_settings')}</h3>
                            <div className="space-y-6">
                                <div className="p-4 bg-blue-50 border border-blue-100 rounded-2xl flex gap-4 items-start">
                                    <Info className="text-blue-500 shrink-0 mt-1" size={20}/>
                                    <div className="text-xs text-blue-800 leading-relaxed">
                                        <p className="font-bold mb-1">{t('admin.finance.iban_diff_title')}</p>
                                        <ul className="list-disc ml-4 space-y-1">
                                            <li><strong>{t('admin.finance.iban_standard')}</strong> {t('admin.finance.iban_standard_desc')}</li>
                                            <li><strong>{t('admin.finance.qr_iban')}</strong> {t('admin.finance.qr_iban_desc')} <strong>{t('admin.finance.mandatory')}</strong> — {t('admin.finance.qr_iban_hint')}</li>
                                        </ul>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.iban_standard_label')}</label>
                                        <input value={paymentSettings.iban} onChange={e => setPaymentSettings({...paymentSettings, iban: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono" placeholder="CH..." />
                                    </div>
                                    
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1 flex items-center gap-2">{t('admin.finance.qr_iban_label')} <span className="bg-[color:color-mix(in_srgb,var(--primary)_10%,transparent)] text-primary text-[8px] px-1.5 py-0.5 rounded font-bold">{t('admin.finance.recommended')}</span></label>
                                        <input value={paymentSettings.qrIban || ''} onChange={e => setPaymentSettings({...paymentSettings, qrIban: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none font-mono border-[color:color-mix(in_srgb,var(--primary)_20%,transparent)] focus:border-primary" placeholder="CH..." />
                                        <p className="text-[10px] text-stone-400 mt-1 italic">{t('admin.finance.qr_iban_empty')}</p>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.bank_name')}</label>
                                            <input value={paymentSettings.bankName} onChange={e => setPaymentSettings({...paymentSettings, bankName: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                        <div>
                                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.account_holder')}</label>
                                            <input value={paymentSettings.accountHolder} onChange={e => setPaymentSettings({...paymentSettings, accountHolder: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                    </div>
                                    <div className="pt-4 border-t border-stone-50">
                                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.bank_address')}</label>
                                        <input value={paymentSettings.street} onChange={e => setPaymentSettings({...paymentSettings, street: e.target.value})} placeholder={t('ph.street_short')} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none mb-2" />
                                        <div className="flex gap-2">
                                            <input value={paymentSettings.zip} onChange={e => setPaymentSettings({...paymentSettings, zip: e.target.value})} placeholder={t('ph.zip_short')} className="w-24 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                            <input value={paymentSettings.city} onChange={e => setPaymentSettings({...paymentSettings, city: e.target.value})} placeholder={t('ph.city_short')} className="flex-1 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" />
                                        </div>
                                    </div>

                                    {/* TWINT Settings */}
                                    <div className="pt-6 border-t border-stone-100">
                                        <h4 className="text-sm font-bold mb-4 flex items-center gap-2 text-stone-800">
                                            <div className="w-6 h-6 rounded-full bg-[#000000] text-white flex items-center justify-center text-[10px] font-bold">TW</div>
                                            {t('admin.finance.twint_settings')}
                                        </h4>
                                        <div className="space-y-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.twint_number')}</label>
                                                <input value={paymentSettings.twintNumber || ''} onChange={e => setPaymentSettings({...paymentSettings, twintNumber: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder={t('ph.phone')} />
                                            </div>
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.twint_url')}</label>
                                                <input value={paymentSettings.twintUrl || ''} onChange={e => setPaymentSettings({...paymentSettings, twintUrl: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder="https://pay.twint.ch/..." />
                                            </div>
                                        </div>
                                    </div>

                                    {/* PayPal Settings */}
                                    <div className="pt-6 border-t border-stone-100">
                                        <h4 className="text-sm font-bold mb-4 flex items-center gap-2 text-stone-800">
                                            <div className="w-6 h-6 rounded-full bg-[#003087] text-white flex items-center justify-center text-[10px] font-bold">PP</div>
                                            {t('admin.finance.paypal_settings')}
                                        </h4>
                                        <div className="space-y-4">
                                            <div>
                                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.finance.paypal_email')}</label>
                                                <input value={paymentSettings.paypalEmail || ''} onChange={e => setPaymentSettings({...paymentSettings, paypalEmail: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" placeholder="zahlungen@verein.ch" />
                                            </div>
                                            {/* Client-ID und Geheimnis liegen getrennt,
                                                in einer Tabelle, die kein angemeldetes
                                                Konto lesen kann. Eintragen ja, nachlesen
                                                nein -- dieselbe Regel wie beim
                                                SMTP-Kennwort. */}
                                            <div className="p-4 bg-stone-900 rounded-xl space-y-3">
                                                <div className="flex items-start justify-between gap-3">
                                                    <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                                                        {t('admin.finance.paypal_client')} &amp; {t('admin.finance.paypal_secret')}
                                                    </p>
                                                    {ppStand?.hinterlegt ? (
                                                        <span className="px-2 py-0.5 bg-emerald-500/20 text-emerald-300 rounded text-[10px] font-bold uppercase shrink-0">
                                                            hinterlegt
                                                        </span>
                                                    ) : (
                                                        <span className="px-2 py-0.5 bg-white/10 text-stone-400 rounded text-[10px] font-bold uppercase shrink-0">
                                                            nicht hinterlegt
                                                        </span>
                                                    )}
                                                </div>

                                                {ppStand?.hinterlegt && (
                                                    <p className="text-[11px] text-stone-400 leading-relaxed">
                                                        Geheimnis endet auf <span className="font-mono text-stone-200">…{ppStand.endet_auf ?? '????'}</span>
                                                        {ppStand.geaendert_am && <> · gesetzt am {new Date(ppStand.geaendert_am).toLocaleDateString('de-CH')}</>}
                                                        {ppStand.geaendert_von && <> von {ppStand.geaendert_von}</>}
                                                    </p>
                                                )}

                                                <input value={ppClient} onChange={e => setPpClient(e.target.value)}
                                                    className="w-full p-3 bg-white/5 border border-white/10 rounded-xl outline-none font-mono text-xs text-white placeholder:text-stone-600"
                                                    placeholder={ppStand?.client_id_hinterlegt ? 'Client-ID — neue eintragen, um sie zu ersetzen' : 'Client-ID (AdX…)'} />
                                                <input type="password" value={ppSecret} onChange={e => setPpSecret(e.target.value)}
                                                    className="w-full p-3 bg-white/5 border border-white/10 rounded-xl outline-none font-mono text-xs text-white placeholder:text-stone-600"
                                                    placeholder={ppStand?.hinterlegt ? 'Geheimnis — neues eintragen, um es zu ersetzen' : 'Geheimnis (E…)'} />

                                                <button onClick={ppSpeichern} disabled={ppLaeuft}
                                                    className="w-full py-2.5 bg-white text-stone-900 rounded-xl font-bold text-xs disabled:opacity-50">
                                                    {ppLaeuft ? 'Speichert …' : 'Zugangsdaten speichern'}
                                                </button>
                                                <p className="text-[10px] text-stone-500 leading-relaxed">
                                                    Wird getrennt gespeichert und nicht zurückgelesen — auch nicht von
                                                    der Administration. Die Felder bleiben darum nach dem Speichern leer.
                                                </p>
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
                                <h3 className="text-xl font-bold">{t('admin.finance.create')}</h3>
                                <button onClick={() => setShowCreateModal(false)} className="p-2 hover:bg-stone-100 rounded-full"><X size={20}/></button>
                            </div>
                            <div className="p-6 overflow-y-auto">
                                <div className="flex gap-2 mb-6 bg-stone-50 p-1 rounded-xl w-fit">
                                    <button onClick={() => setInvoiceMode('SINGLE')} className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${invoiceMode === 'SINGLE' ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400 hover:text-stone-600'}`}>{t('admin.finance.single_invoice')}</button>
                                    <button onClick={() => { setShowCreateModal(false); setAssistent(true); }} className="px-4 py-2 rounded-lg text-sm font-bold transition-all text-stone-400 hover:text-stone-600">{t('admin.finance.bulk_invoice')}</button>
                                </div>

                                {invoiceMode === 'SINGLE' && (
                                    <div className="space-y-4">
                                        <div className="flex gap-4 mb-4">
                                            <label className="flex items-center gap-2 text-sm font-bold cursor-pointer">
                                                <input type="radio" checked={recipientMode === 'MEMBER'} onChange={() => setRecipientMode('MEMBER')} className="accent-primary" /> {t('field.member')}
                                            </label>
                                            <label className="flex items-center gap-2 text-sm font-bold cursor-pointer">
                                                <input type="radio" checked={recipientMode === 'EXTERNAL'} onChange={() => setRecipientMode('EXTERNAL')} className="accent-primary" /> {t('admin.finance.external')}
                                            </label>
                                        </div>

                                        {recipientMode === 'MEMBER' ? (
                                            <div>
                                                <label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('admin.finance.choose_member')}</label>
                                                                                                <MemberPicker
                                                    single
                                                    users={users}
                                                    value={newInvoice.userId ? [newInvoice.userId] : []}
                                                    onChange={(ids) => setNewInvoice({ ...newInvoice, userId: ids[0] || '' })}
                                                />
                                            </div>
                                        ) : (
                                            <div className="grid grid-cols-2 gap-4">
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.name')}</label><input value={customRecipient.name} onChange={e => setCustomRecipient({...customRecipient, name: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.email')}</label><input value={customRecipient.email} onChange={e => setCustomRecipient({...customRecipient, email: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.street')}</label><input value={customRecipient.street} onChange={e => setCustomRecipient({...customRecipient, street: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.zip')}</label><input value={customRecipient.zip} onChange={e => setCustomRecipient({...customRecipient, zip: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.city')}</label><input value={customRecipient.city} onChange={e => setCustomRecipient({...customRecipient, city: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                                <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.country')}</label><CountrySelect value={customRecipient.country} onChange={(v) => setCustomRecipient({...customRecipient, country: v})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            </div>
                                        )}

                                        <div className="grid grid-cols-2 gap-4">
                                            <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.description')}</label><input value={newInvoice.description || ''} onChange={e => setNewInvoice({...newInvoice, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.amount')}</label><input type="number" value={newInvoice.amount || ''} onChange={e => setNewInvoice({...newInvoice, amount: Number(e.target.value)})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.currency')}</label><select value={newInvoice.currency || 'CHF'} onChange={e => setNewInvoice({...newInvoice, currency: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"><option value="CHF">CHF</option><option value="EUR">EUR</option></select></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.due_date')}</label><input type="date" value={newInvoice.dueDate || ''} onChange={e => setNewInvoice({...newInvoice, dueDate: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
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
                                            <div className="col-span-2"><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.description')}</label><input value={newInvoice.description || ''} onChange={e => setNewInvoice({...newInvoice, description: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                            <div><label className="text-xs font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('field.due_date')}</label><input type="date" value={newInvoice.dueDate || ''} onChange={e => setNewInvoice({...newInvoice, dueDate: e.target.value})} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none" /></div>
                                        </div>
                                    </div>
                                )}
                            </div>
                            <div className="p-6 border-t border-stone-100 bg-stone-50 flex justify-end gap-4">
                                <button onClick={() => setShowCreateModal(false)} className="px-6 py-3 rounded-xl font-bold text-stone-500 hover:bg-stone-200 transition-colors">{t('common.cancel')}</button>
                                <button onClick={handleCreateInvoice} className="px-6 py-3 rounded-xl font-bold bg-stone-900 text-white hover:bg-black transition-colors shadow-lg">{t('admin.finance.create_invoices')}</button>
                            </div>
                        </motion.div>
                    </div>
                )}
                {viewInvoice && paymentSettings && (
                    <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/80 backdrop-blur-md">
                        <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.95, opacity: 0 }} className="bg-stone-100 w-full max-w-4xl rounded-[2rem] overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
                            <div className="p-4 border-b border-stone-200 flex justify-between items-center bg-white"><h3 className="font-bold text-stone-800">{t('admin.finance.preview_invoice', { number: viewInvoice.invoiceNumber || '' })}</h3><div className="flex gap-2"><button onClick={handleDownloadPdf} className="px-4 py-2 bg-stone-900 text-white rounded-lg text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors"><Download size={14} /> {t('admin.finance.download_pdf')}</button><button onClick={() => setViewInvoice(null)} className="p-2 hover:bg-stone-100 rounded-lg text-stone-500"><X size={20}/></button></div></div>
                            <div className="flex-1 overflow-y-auto p-8 flex justify-center custom-scrollbar">
                                <div id="invoice-preview-content" className="bg-white shadow-xl w-[210mm] min-h-[297mm] p-[20mm] text-stone-900 relative flex flex-col">
                                     <Rechnungsblatt nurKopf layout={rechnungslayout} daten={{
                                         nummer: viewInvoice.invoiceNumber || '',
                                         datum: new Date(viewInvoice.timestamp?.toDate?.() || Date.now()).toLocaleDateString('de-CH'),
                                         beschreibung: viewInvoice.description || '',
                                         betrag: viewInvoice.amount, waehrung: viewInvoice.currency,
                                         verein: { name: paymentSettings.accountHolder, strasse: paymentSettings.street,
                                                   plz: paymentSettings.zip,
                                                   ort: paymentSettings.city, land: paymentSettings.country,
                                                   email: paymentSettings.contactEmail },
                                         logoUrl: branding?.logoUrl || '',
                                         qr: getQrData(viewInvoice),
                                         ueberschrift: t('invoice.heading'),
                                         schlusswort: t('admin.finance.thanks'),
                                         beschriftung: { nummer: '#', datum: t('field.date') + ':',
                                                         an: t('admin.finance.bill_to'),
                                                         was: t('field.description'), betrag: t('field.amount') },
                                     }} />
                                     <div className="mt-auto">
                                        <div className="border-t-2 border-dashed border-stone-300 pt-8">
                                            {viewInvoice.method === 'QR_BILL' && (
                                                <div className="space-y-8">
                                                    <SwissQRBill data={getQrData(viewInvoice)!} />
                                                    {paymentSettings.twintNumber && (
                                                        <div className="bg-stone-50 p-6 rounded-xl border border-stone-200 text-center">
                                                            <h4 className="font-bold text-stone-800 mb-2 flex items-center justify-center gap-2">
                                                                <div className="w-6 h-6 rounded-full bg-[#000000] text-white flex items-center justify-center text-[10px] font-bold">TW</div>
                                                                {t('admin.finance.twint_payment')}
                                                            </h4>
                                                            <p className="text-sm text-stone-600 mb-4">{t('admin.finance.twint_pay_intro')}</p>
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
                                                        <h4 className="font-bold text-xl text-stone-800 mb-2">{t('admin.finance.girocode')}</h4>
                                                        <p className="text-sm text-stone-600 mb-4">Scannen Sie diesen Code mit Ihrer Banking-App, um die Überweisung automatisch auszufüllen.</p>
                                                        <div className="space-y-1 text-sm font-mono">
                                                            <p><span className="text-stone-400">{t('field.iban')}:</span> {paymentSettings.iban}</p>
                                                            <p><span className="text-stone-400">{t('field.bic')}:</span> {paymentSettings.bic}</p>
                                                            <p><span className="text-stone-400">{t('field.recipient')}:</span> {paymentSettings.accountHolder}</p>
                                                            <p><span className="text-stone-400">{t('field.amount')}:</span> {viewInvoice.amount.toFixed(2)} EUR</p>
                                                            <p><span className="text-stone-400">{t('field.purpose')}:</span> {viewInvoice.invoiceNumber}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
                                            {viewInvoice.method === 'PAYPAL' && (
                                                <div className="bg-[#003087]/5 p-8 rounded-2xl border border-[#003087]/20 text-center">
                                                    <h4 className="font-bold text-xl text-[#003087] mb-2 flex items-center justify-center gap-2">
                                                        <div className="w-8 h-8 rounded-full bg-[#003087] text-white flex items-center justify-center text-xs font-bold">PP</div>
                                                        {t('admin.finance.paypal_payment')}
                                                    </h4>
                                                    <p className="text-sm text-stone-600 mb-6">{t('admin.finance.paypal_pay_intro')}</p>
                                                    <div className="inline-block bg-white px-6 py-4 rounded-xl border border-stone-200 shadow-sm">
                                                        <p className="text-xs text-stone-400 uppercase tracking-widest mb-1">{t('admin.finance.paypal_email')}</p>
                                                        <p className="text-lg font-bold font-mono">{paymentSettings.paypalEmail || 'Nicht konfiguriert'}</p>
                                                    </div>
                                                    <div className="mt-6 text-sm">
                                                        <p><span className="text-stone-500">{t('field.amount')}:</span> <span className="font-bold">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</span></p>
                                                        <p><span className="text-stone-500">{t('field.purpose')}:</span> <span className="font-bold">{viewInvoice.invoiceNumber}</span></p>
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