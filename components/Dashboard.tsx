
import React, { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile, Payment, GlobalPaymentSettings, Neighborhood, Inquiry } from '../types';
import { db } from '../services/firebase';
import { collection, query, where, orderBy, onSnapshot, doc, getDoc, updateDoc, addDoc, serverTimestamp, myNeighborhoodContacts, myNeighborhoods, getDocs } from '@/services/supabase-bridge';
import { 
  History, 
  FileText, 
  CreditCard, 
  MapPin,
  CheckCircle2,
  Clock,
  Printer,
  X,
  ArrowRight,
  Users,
  Shield,
  MessageSquare,
  Sparkles,
  TrendingUp,
  Download,
  Mail,
  Phone,
  QrCode,
  CalendarClock,
  Info,
  UserCog,
  Save,
  User,
  HelpCircle,
  Landmark,
  Plus,
  AlertTriangle,
  Edit3,
  Send
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { QrBillData } from '../services/qrBillService';
import SwissQRBill from './SwissQRBill';
import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from 'recharts';
import { useFeedback } from '../context/FeedbackContext';
import { sendEmail } from '../services/mailService';

import { neighborhoodCity } from '../lib/neighborhood';
import CountrySelect from './ui/CountrySelect';
import { emailMissingForDelivery } from '../lib/memberEmail';
import { missingFieldKeys, feeStateFor } from '../lib/memberQuality';
import { onImageError } from '../lib/imageFallback';
// Kuerzel aus dem Vereinsnamen, z. B. "Shoqata Koretini" -> "SK".
const initialsOf = (name: string) =>
  name.trim().split(/\s+/).slice(0, 2).map(w => w[0] || '').join('').toUpperCase() || 'V';

interface DashboardProps {
  user: UserProfile;
}

const Dashboard: React.FC<DashboardProps> = ({ user }) => {
  const { t, loc } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings | null>(null);
  const [viewInvoice, setViewInvoice] = useState<Payment | null>(null);
  const [neighborhood, setNeighborhood] = useState<Neighborhood | null>(null);
  const [neighbors, setNeighbors] = useState<UserProfile[]>([]);
  // Der Puls kommt vom Server, nicht aus den geladenen Nachbarn.
  //
  // Gemessen: die Zeilenregel auf users gibt einem Mitglied ohne
  // Verantwortung nur die eigene Zeile heraus. Die Quote wurde aus genau
  // diesen Zeilen gerechnet und stand deshalb auf 1 von 1, obwohl die
  // Nachbarschaft 41 Mitglieder hat. Die Regel ist richtig -- falsch war,
  // eine Gemeinschaftskennzahl aus Datensaetzen zu rechnen, die es gar
  // nicht zu sehen gibt. nachbarschaft_puls() gibt nur Zahlen heraus, nie
  // wer bezahlt hat.
  // Steht hier und nicht weiter unten: der Effekt, der den Puls laedt,
  // braucht das Jahr. Eine Konstante unterhalb ihrer Verwendung laeuft nur
  // deshalb, weil Effekte nach dem Rendern ausgefuehrt werden -- eine Falle
  // fuer den Naechsten, der etwas verschiebt.
  const beitragsjahr = new Date().getFullYear();

  const [puls, setPuls] = useState<{
    mitglieder: number; aktiv: number; bezahlt: number; offen: number; ohne_rechnung: number;
  } | null>(null);
  const [manager, setManager] = useState<UserProfile | null>(null);
  // Weitere Verantwortliche derselben Nachbarschaft -- es koennen mehrere
  // hinterlegt sein, die Karte zeigte bisher nur eine Person.
  const [weitereKontakte, setWeitereKontakte] = useState<any[]>([]);
  // Nachbarschaften, fuer die dieses Mitglied selbst verantwortlich ist.
  const [betreutNachbarschaften, setBetreutNachbarschaften] = useState<string[]>([]);
  const [nachbarschaftsZahlungen, setNachbarschaftsZahlungen] = useState<Payment[]>([]);
  // Freigegebene Sitzungsprotokolle. Welche das sind, entscheidet die
  // Zugriffsregel -- ein nicht freigegebenes wird gar nicht erst geliefert.
  const [protokolle, setProtokolle] = useState<any[]>([]);
  const [offenesProtokoll, setOffenesProtokoll] = useState<any>(null);
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  // Vereinsname und Kuerzel auf dem Rechnungsbeleg kamen fest verdrahtet aus
  // Koretini; in einer zweiten Installation stand dort der falsche Verein.
  const [branding, setBranding] = useState<any>({});
  
  // Neighborhood Manager Specific State
  
  // Manage Neighbor State (For Managers)
  const [managedNeighbor, setManagedNeighbor] = useState<UserProfile | null>(null);
  const [managedData, setManagedData] = useState<Partial<UserProfile>>({});

  // Profile Edit State
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [profileData, setProfileData] = useState<Partial<UserProfile>>({});

  // Request Modal State
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [newRequest, setNewRequest] = useState({ type: 'GENERAL', subject: '', message: '' });

  // Missing Fields State
  const [missingFields, setMissingFields] = useState<string[]>([]);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'public_settings', 'branding'), (snap) => {
      if (snap.exists()) setBranding(snap.data());
    });
    return () => unsub();
  }, []);

  useEffect(() => {
      // Dieselben Regeln wie im Adminbereich -- sonst sagt die Verwaltung
      // "Angaben fehlen" und das Mitglied sieht keinen Hinweis. Beschraenkt
      // auf das, was es im eigenen Profil auch aendern kann.
      setMissingFields(missingFieldKeys(user, { selfServiceOnly: true }).map(k => t(k)));
  }, [user, t]);

  // Data Fetching
  useEffect(() => {
    if (!user?.id) return;

    // 1. Payments (My own)
    const qPayments = query(
      collection(db, 'payments'),
      where('userId', '==', user.id)
    );
    const unsubPayments = onSnapshot(qPayments, (snap) => {
      const loadedPayments = snap.docs.map(doc => ({ id: doc.id, ...doc.data() } as Payment));
      // Client-side Sort: Newest first
      loadedPayments.sort((a, b) => {
          const tA = a.timestamp?.toMillis ? a.timestamp.toMillis() : 0;
          const tB = b.timestamp?.toMillis ? b.timestamp.toMillis() : 0;
          return tB - tA;
      });
      setPayments(loadedPayments);
    });

    // 2. Settings
    getDoc(doc(db, 'public_settings', 'payment')).then(snap => {
        if (snap.exists()) setPaymentSettings(snap.data() as GlobalPaymentSettings);
    });

    // 3. Requests (Inquiries)
    const qInquiries = query(collection(db, 'inquiries'), where('userId', '==', user.id));
    const unsubInquiries = onSnapshot(qInquiries, (snap) => {
        const loaded = snap.docs.map(d => ({ id: d.id, ...d.data() } as Inquiry));
        // Client-side sort (Newest first)
        loaded.sort((a, b) => {
             const tA = a.createdAt?.toDate ? a.createdAt.toDate().getTime() : 0;
             const tB = b.createdAt?.toDate ? b.createdAt.toDate().getTime() : 0;
             return tB - tA;
        });
        setInquiries(loaded);
    });

    // 4. Neighborhood & Neighbors
    if (user.neighborhoodId) {
        (async () => {
          const { supabase } = await import('../services/supabase-bridge');
          const { data, error } = await supabase.rpc('nachbarschaft_puls', { p_jahr: beitragsjahr });
          const zeile = Array.isArray(data) ? data[0] : data;
          if (!error && zeile) setPuls(zeile);
        })();

        // Fetch Neighborhood Details
        const unsubNeighborhood = onSnapshot(doc(db, 'neighborhoods', user.neighborhoodId), (snap) => {
            if (snap.exists()) setNeighborhood({ id: snap.id, ...snap.data() } as Neighborhood);
        });

        // Fetch Neighbors (for anonymous stats and list)
        const qNeighbors = query(collection(db, 'users'), where('neighborhoodId', '==', user.neighborhoodId));
        const unsubNeighbors = onSnapshot(qNeighbors, (snap) => {
            // Wer aus dem Verein entfernt wurde, gehoert nicht mehr in die
            // Nachbarschaft -- weder in die Uebersicht noch in die Zahlquote.
            // Der Datensatz bleibt bestehen, weil Rechnungen daran haengen.
            const data = snap.docs
                .map(d => ({ id: d.id, ...d.data() } as UserProfile))
                .filter(u => u.membershipStatus !== 'INACTIVE');
            setNeighbors(data);
            // Die verantwortliche Person wurde frueher an der Rolle
            // NEIGHBORHOOD_MANAGER erkannt. Hinterlegt wird sie aber in der
            // Nachbarschaft selbst, und sie traegt dort meist gar keine
            // besondere Rolle -- die Karte blieb deshalb leer. Massgeblich ist
            // jetzt die Zuordnung, die der Server herausgibt.
        });

        // Die frueher hier laufende Rechnungsabfrage ist entfallen: sie filterte
        // auf payments.neighborhoodId, das nur bei 3 von 324 Zahlungen gesetzt
        // ist, und die zugehoerige Ansicht wurde durch /nachbarschaft ersetzt.
        return () => { unsubPayments(); unsubNeighborhood(); unsubNeighbors(); unsubInquiries(); };
    }

    return () => { unsubPayments(); unsubInquiries(); };
  }, [user.id, user.neighborhoodId, user.role, beitragsjahr]);

  // Verantwortliche der eigenen Nachbarschaft und eigene Zustaendigkeit.
  //
  // Beides kommt aus der Datenbank, nicht aus einer Vermutung im Client: die
  // Leseregel auf users gibt einem gewoehnlichen Mitglied keine fremden
  // Datensaetze heraus, my_neighborhood_contacts() genau die Kontaktangaben
  // seiner Verantwortlichen.
  useEffect(() => {
    let lebt = true;
    (async () => {
      const [kontakte, meine] = await Promise.all([myNeighborhoodContacts(), myNeighborhoods()]);
      if (!lebt) return;
      setManager((kontakte[0] as any) || null);
      setWeitereKontakte(kontakte.slice(1));
      setBetreutNachbarschaften(meine);

      // Die Rechnungen der betreuten Nachbarschaften. Ohne Filter auf
      // neighborhoodId -- das Feld ist nur bei 3 von 324 Zahlungen gesetzt.
      // Was sichtbar sein darf, entscheidet ohnehin die Leseregel.
      if (meine.length) {
        const snap = await getDocs(query(collection(db, 'payments')));
        if (!lebt) return;
        setNachbarschaftsZahlungen(snap.docs.map(d => ({ id: d.id, ...d.data() } as Payment)));
      }

      try {
        const p = await getDocs(query(collection(db, 'board_meetings')));
        if (!lebt) return;
        setProtokolle(
          p.docs.map(d => ({ id: d.id, ...d.data() } as any))
            .filter(m => m.publishedToMembers)
            .sort((a, b) => String(b.date || '').localeCompare(String(a.date || '')))
        );
      } catch { /* ohne Freigabe kommt hier nichts an, das ist kein Fehler */ }
    })();
    return () => { lebt = false; };
  }, [user.id, user.neighborhoodId]);

  // Handle Profile Modal Open
  const handleOpenProfile = () => {
      setProfileData({ ...user });
      setShowProfileModal(true);
  };

  // Handle Profile Update (Self)
  const handleUpdateProfile = async () => {
      if (!user.id) return;
      // Rechnung per E-Mail ohne E-Mail-Adresse geht nicht auf.
      if (emailMissingForDelivery({ ...user, ...profileData })) {
          showAlert({ type: 'error', message: t('email.required_for_delivery') });
          return;
      }
      try {
          // Construct displayName from components if edited
          const displayName = `${profileData.firstName || ''} ${profileData.lastName || ''}`.trim() || profileData.displayName;
          const address = `${profileData.street || ''}, ${profileData.zip || ''} ${profileData.city || ''}, ${profileData.country || ''}`;

          await updateDoc(doc(db, 'users', user.id), {
              ...profileData,
              displayName,
              address,
              dataUpdateRequested: false // Reset flag on save
          });
          
          showAlert({ type: 'success', message: t('common.success') });
          setShowProfileModal(false);
      } catch (err) {
          console.error(err);
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  // MANAGER: Open Manage Modal
  const handleOpenManageNeighbor = (neighbor: UserProfile) => {
      // An der Zuordnung festgemacht, nicht an der Rollenbezeichnung: die
      // verantwortlichen Personen tragen fast alle die Rolle MEMBER, und die
      // Kacheln waren fuer sie deshalb nicht anklickbar. Ob die Aenderung
      // durchgeht, entscheidet ohnehin die Zugriffsregel.
      if (!istBetreuer) return;
      setManagedNeighbor(neighbor);
      setManagedData({ ...neighbor });
  };

  // MANAGER: Save Neighbor Data Directly
  const handleSaveManagedNeighbor = async () => {
      if (!managedNeighbor) return;
      try {
          const displayName = `${managedData.firstName || ''} ${managedData.lastName || ''}`.trim() || managedData.displayName;
          const address = `${managedData.street || ''}, ${managedData.zip || ''} ${managedData.city || ''}, ${managedData.country || 'Switzerland'}`;
          
          await updateDoc(doc(db, 'users', managedNeighbor.id), {
              ...managedData,
              displayName,
              address,
              dataUpdateRequested: false // Reset flag as data is now provided
          });
          showAlert({ type: 'success', message: t('dash.saved') });
          setManagedNeighbor(null);
      } catch (e) {
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  // MANAGER: Send Update Request Email
  const handleSendUpdateRequest = async () => {
      if (!managedNeighbor || !managedNeighbor.email) {
          showAlert({ type: 'error', message: t('dash.no_email') });
          return;
      }
      try {
          await sendEmail({
              to: managedNeighbor.email,
              subject: "Bitte Profil aktualisieren - Shoqata Koretini",
              html: `<p>Hallo ${managedNeighbor.displayName},</p><p>Dein Nachbarschafts-Manager (${user.displayName}) bittet dich, deine Profildaten (Adresse, Telefon) zu aktualisieren, um die Erreichbarkeit sicherzustellen.</p><p><a href="${window.location.origin}/#/login">{t('dash.login_here')}</a></p>`
          });
          
          await updateDoc(doc(db, 'users', managedNeighbor.id), { dataUpdateRequested: true });
          
          showAlert({ type: 'success', message: t('dash.request_sent') });
          setManagedNeighbor(null);
      } catch (e) {
          showAlert({ type: 'error', message: t('common.error') });
      }
  };

  // ... (Other handlers like handleSubmitRequest, stats, groupedNeighbors, getQrData... unchanged)
  // Re-inserting required helpers for the component to function
  const handleSubmitRequest = async () => {
      if (!newRequest.subject || !newRequest.message) {
          showAlert({ type: 'error', message: t('dash.fill_all') });
          return;
      }
      try {
          await addDoc(collection(db, 'inquiries'), {
              userId: user.id,
              userName: user.displayName,
              type: newRequest.type,
              subject: newRequest.subject,
              message: newRequest.message,
              status: 'OPEN',
              createdAt: serverTimestamp()
          });
          showAlert({ type: 'success', message: t('common.success') });
          setShowRequestModal(false);
          setNewRequest({ type: 'GENERAL', subject: '', message: '' });
      } catch (e) {
          showAlert({ type: 'error', message: t('common.error') });
      }
  };


  // Der Puls rechnete ACTIVE / alle. Gemessen: in jeder der 27 Nachbarschaften
  // sind hundert Prozent ACTIVE -- die Kennzahl war eine Konstante und zeigte
  // dauerhaft 100. Die Zahlquote schwankt dagegen zwischen 15 und 38 Prozent;
  // dort liegt das, was sich beobachten laesst.
  //
  // "Nicht verrechnet" bleibt als eigener Anteil sichtbar, statt in "offen"
  // aufzugehen: das eine liegt beim Mitglied, das andere beim Verein.
  const stats = useMemo(() => {
      // Vorrang hat der Server. Antwortet er nicht, wird wie bisher aus den
      // geladenen Nachbarn gerechnet -- fuer Vorstand und verantwortliche
      // Personen ergibt das dasselbe, weil sie ohnehin alle Zeilen sehen.
      const total = puls ? Number(puls.mitglieder) : neighbors.length;
      const active = puls ? Number(puls.aktiv)
                          : neighbors.filter(n => n.membershipStatus === 'ACTIVE').length;
      const bezahlt = puls ? Number(puls.bezahlt)
                           : neighbors.filter(n => feeStateFor(n.id!, nachbarschaftsZahlungen, beitragsjahr) === 'PAID').length;
      const offen = puls ? Number(puls.offen)
                         : neighbors.filter(n => feeStateFor(n.id!, nachbarschaftsZahlungen, beitragsjahr) === 'OPEN').length;
      const nichtVerrechnet = puls ? Number(puls.ohne_rechnung)
                                   : Math.max(0, total - bezahlt - offen);
      const rate = total > 0 ? Math.round((bezahlt / total) * 100) : 0;
      return {
        total, active, bezahlt, offen, nichtVerrechnet, rate,
        chartData: [
          { name: 'Bezahlt', value: bezahlt, color: '#10b981' },
          { name: 'Offen', value: offen, color: '#f59e0b' },
          { name: 'Nicht verrechnet', value: nichtVerrechnet, color: '#e7e5e4' },
        ].filter(d => d.value > 0),
      };
  }, [puls, neighbors, nachbarschaftsZahlungen, beitragsjahr]);

  const groupedNeighbors = useMemo(() => {
      const families: Record<string, UserProfile[]> = {};
      const individuals: UserProfile[] = [];
      neighbors.forEach(n => { if (n.familyId) { if (!families[n.familyId]) families[n.familyId] = []; families[n.familyId].push(n); } else { individuals.push(n); } });
      return { families, individuals };
  }, [neighbors]);

  const getQrData = (payment: Payment): QrBillData | null => {
      if (!paymentSettings) return null;
      return {
        amount: payment.amount,
        currency: payment.currency as 'CHF' | 'EUR',
        iban: paymentSettings.qrIban || paymentSettings.iban,
        creditor: { name: paymentSettings.accountHolder, address: (paymentSettings.street || '') + ' ' + ((paymentSettings.street || '').match(/\d+/) ? '' : '1'), zip: paymentSettings.zip, city: paymentSettings.city, country: paymentSettings.country },
        debtor: { name: user.displayName || 'Member', address: user.street || 'Address', zip: user.zip || '0000', city: user.city || 'City', country: user.country || 'CH' },
        reference: payment.reference || '',
        additionalInfo: payment.description
      };
  };

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
      } catch (e) { console.error(e); }
  };

  const activeInvoice = payments.find(p => p.status === 'PENDING' || p.status === 'OVERDUE');
  const currentYear = new Date().getFullYear();
  const hasCurrentYearInvoice = payments.some(p => {
      const date = p.timestamp?.toDate();
      return date && date.getFullYear() === currentYear && p.status !== 'CANCELLED';
  });

  // Check if a neighbor profile is incomplete (Helper for UI)
  // Die beiden Auskuenfte, die eine verantwortliche Person auf einen Blick
  // braucht. istBetreuer entscheidet, ob sie ueberhaupt gezeigt werden: ein
  // gewoehnliches Mitglied bekommt die Zahlungen seiner Nachbarn gar nicht
  // erst zu sehen, und soll es auch nicht.
  const istBetreuer = betreutNachbarschaften.length > 0;
  const beitragVon = (u: UserProfile) => feeStateFor(u.id!, nachbarschaftsZahlungen, beitragsjahr);
  // Dieselbe Regel wie in der Nachbarschaftsansicht. selfServiceOnly nimmt nur
  // die Nachbarschaft heraus -- die ordnet der Vorstand zu, und ein Hinweis auf
  // etwas, das man nicht aendern kann, hilft niemandem. Das Geburtsdatum bleibt
  // drin und ist im Bearbeiten-Dialog einzutragen.
  const luckenVon = (u: UserProfile) => missingFieldKeys(u, { selfServiceOnly: true });

  const isProfileIncomplete = (u: UserProfile) => {
      return !u.phone || !u.street || !u.city || !u.zip || !u.birthdate;
  };

  // Helper to get list of missing fields for a specific user object (Dynamic)
  const getMissingFieldsList = (u: Partial<UserProfile>) => {
      const missing: string[] = [];
      if (!u.phone) missing.push('Telefon');
      if (!u.street || !u.zip || !u.city) missing.push('Adresse');
      if (!u.birthdate) missing.push('Geburtsdatum');
      // Email is usually present from auth, but checking it ensures data quality
      if (!u.email) missing.push('Email'); 
      return missing;
  };

  return (
    <div className="pt-44 md:pt-48 pb-20 px-6 max-w-7xl mx-auto bg-[#faf9f6]">
      
      {/* DATA QUALITY ALERT */}
      {(missingFields.length > 0 || user.dataUpdateRequested) && (
          <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="mb-8 p-4 bg-amber-50 border border-amber-200 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4 shadow-sm relative z-10">
              <div className="flex items-center gap-4">
                  <div className="p-3 bg-amber-100 text-amber-600 rounded-xl"><AlertTriangle size={24} /></div>
                  <div>
                      <h4 className="font-bold text-amber-900 text-lg">{t('dash.update.title')}</h4>
                      <p className="text-amber-700 text-sm">
                          {user.dataUpdateRequested ? t('dash.update.requested') : t('dash.update.missing', { fields: missingFields.join(', ') })}
                      </p>
                  </div>
              </div>
              <button onClick={handleOpenProfile} className="px-6 py-2 bg-amber-600 text-white font-bold rounded-xl hover:bg-amber-700 transition-colors shadow-lg">
                  {t('dash.update.now')}
              </button>
          </motion.div>
      )}

      {/* Welcome Header */}
      <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="mb-12 flex flex-col md:flex-row justify-between items-end gap-6">
        <div>
            <div className="inline-flex items-center gap-2 bg-white border border-stone-200 px-3 py-1 rounded-full text-xs font-bold text-stone-500 mb-4 shadow-sm">
                <Shield size={12} className="text-primary"/> {t('dash.badge')}
            </div>
            <div className="flex items-center gap-4 mb-2">
                <h1 className="text-4xl md:text-5xl font-display font-bold italic text-stone-900">
                    {t('dash.welcome')}, {user.firstName || user.displayName?.split(' ')[0]}
                </h1>
                <button 
                    onClick={handleOpenProfile} 
                    className="p-2 bg-stone-100 rounded-full hover:bg-primary hover:text-white transition-colors" 
                    title={t('profile.edit')}
                >
                    <UserCog size={20} />
                </button>
            </div>
            <p className="text-stone-500 text-lg max-w-lg">
                {t('dash.intro')} {neighborhood?.name || 'Koretini'}.
            </p>
        </div>
        <div className="flex items-center gap-3 bg-white p-2 rounded-2xl shadow-sm border border-stone-100">
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold text-white shadow-lg ${user.membershipStatus === 'ACTIVE' ? 'bg-emerald-500 shadow-emerald-200' : 'bg-amber-500 shadow-amber-200'}`}>
                {user.membershipStatus === 'ACTIVE' ? <CheckCircle2 size={24}/> : <Clock size={24}/>}
            </div>
            <div className="pr-4">
                <p className="text-[10px] uppercase tracking-widest font-bold text-stone-400">{t('dash.status.title')}</p>
                <p className={`font-bold ${user.membershipStatus === 'ACTIVE' ? 'text-emerald-600' : 'text-amber-600'}`}>
                    {user.membershipStatus === 'ACTIVE' ? t('dash.status.active_paid') : t('dash.status.pending')}
                </p>
            </div>
        </div>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* ... (LEFT COLUMN and Charts code remains largely the same) ... */}
        <div className="lg:col-span-4 space-y-8">
            {/* INVOICE STATUS CARD */}
            {activeInvoice ? (
                <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="bg-stone-900 text-white p-8 rounded-[2.5rem] shadow-xl shadow-stone-300 relative overflow-hidden group">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-primary/20 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 group-hover:bg-primary/30 transition-colors" />
                    <div className="relative z-10">
                        <div className="flex justify-between items-start mb-8">
                            <div>
                                <p className="text-primary font-bold text-xs uppercase tracking-widest mb-1">{t('dash.invoice.open')}</p>
                                <h3 className="text-3xl font-display font-bold italic">{t('dash.payment.title')}</h3>
                            </div>
                            <div className="bg-white/10 p-3 rounded-xl backdrop-blur-sm">
                                <CreditCard size={24} className="text-white"/>
                            </div>
                        </div>
                        
                        <div className="mb-8">
                            <p className="text-sm text-stone-400 mb-1">{t('dash.invoice.amount')}</p>
                            <p className="text-4xl font-mono font-bold">{activeInvoice.amount.toFixed(2)} <span className="text-lg">{activeInvoice.currency}</span></p>
                            <p className="text-xs text-stone-500 mt-2 flex items-center gap-1"><Clock size={10}/> {t('dash.invoice.due')}: {activeInvoice.dueDate}</p>
                        </div>

                        <button 
                            onClick={() => setViewInvoice(activeInvoice)}
                            className="w-full py-4 bg-white text-stone-900 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-stone-100 transition-all shadow-lg"
                        >
                            <QrCode size={18}/> {t('dash.payment.qr')}
                        </button>
                    </div>
                </motion.div>
            ) : hasCurrentYearInvoice ? (
                <div className="bg-emerald-50 text-emerald-800 p-8 rounded-[2.5rem] border border-emerald-100 text-center relative overflow-hidden h-[300px] flex flex-col items-center justify-center">
                    <div className="absolute top-0 left-0 w-full h-1 bg-emerald-200" />
                    <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center text-emerald-500 mx-auto mb-6 shadow-sm border border-emerald-100">
                        <CheckCircle2 size={40}/>
                    </div>
                    <h3 className="text-2xl font-bold mb-2">{t('dash.invoice.all_paid_title')}</h3>
                    <p className="text-sm text-emerald-600/80 mb-4 max-w-[200px] mx-auto">{t('dash.invoice.all_paid_desc')} {currentYear}.</p>
                    <div className="bg-emerald-100/50 px-4 py-1 rounded-full text-xs font-bold text-emerald-700">
                        {t('dash.invoice.membership')} {currentYear} ✅
                    </div>
                </div>
            ) : (
                <div className="bg-white text-stone-800 p-8 rounded-[2.5rem] border border-stone-200 text-center relative overflow-hidden h-[300px] flex flex-col items-center justify-center">
                    <div className="absolute top-0 left-0 w-full h-1 bg-stone-200" />
                    <div className="w-20 h-20 bg-stone-50 rounded-full flex items-center justify-center text-stone-400 mx-auto mb-6 shadow-inner">
                        <CalendarClock size={40}/>
                    </div>
                    <h3 className="text-xl font-bold mb-2">{t('dash.invoice.waiting_title')} {currentYear}</h3>
                    <p className="text-sm text-stone-500 mb-6 max-w-[240px] mx-auto">
                        {t('dash.invoice.waiting_desc', { year: currentYear })}
                    </p>
                    <div className="inline-flex items-center gap-2 bg-stone-50 px-4 py-2 rounded-xl text-xs font-bold text-stone-400">
                        <Info size={14} /> {t('dash.invoice.waiting_badge')}
                    </div>
                </div>
            )}

            {/* Payment History List */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                <div className="flex items-center justify-between mb-6">
                    <h4 className="font-bold text-stone-900 flex items-center gap-2"><History size={18} /> {t('dash.history')}</h4>
                </div>
                <div className="space-y-4">
                    {payments.length === 0 ? (
                        <div className="text-center py-8 border-2 border-dashed border-stone-100 rounded-2xl">
                            <p className="text-stone-400 text-sm italic">{t('dash.no_payments')}</p>
                        </div>
                    ) : (
                        payments.map(p => (
                            <div key={p.id} className="flex justify-between items-center p-3 hover:bg-stone-50 rounded-2xl transition-colors group cursor-pointer" onClick={() => setViewInvoice(p)}>
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${p.status === 'PAID' ? 'bg-emerald-100 text-emerald-600' : 'bg-stone-100 text-stone-400'}`}>
                                        <FileText size={18}/>
                                    </div>
                                    <div>
                                        <p className="font-bold text-stone-800 text-sm">{p.description || t('dash.invoice.membership')}</p>
                                        <p className="text-[10px] text-stone-400 font-mono">{p.timestamp?.toDate().toLocaleDateString()}</p>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="font-bold text-sm text-stone-900">{p.amount} {p.currency}</p>
                                    <span className="text-[10px] font-bold text-stone-400 group-hover:text-primary transition-colors">{t('dash.download_pdf')}</span>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>

        {/* RIGHT COLUMN: COMMUNITY & NEIGHBORHOOD (8 cols) */}
        <div className="lg:col-span-8 space-y-8">
            
            {offenesProtokoll && (
                <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
                    <div className="bg-white w-full max-w-2xl rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[88vh]">
                        <div className="p-6 border-b border-stone-100 bg-stone-50 flex justify-between items-start gap-4">
                            <div>
                                <h3 className="font-bold text-lg text-stone-900">{offenesProtokoll.title}</h3>
                                <p className="text-xs text-stone-500">
                                    {new Date(offenesProtokoll.date).toLocaleDateString()}
                                    {offenesProtokoll.location ? ` · ${offenesProtokoll.location}` : ''}
                                </p>
                            </div>
                            <button onClick={() => setOffenesProtokoll(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 shrink-0">
                                <X size={18}/>
                            </button>
                        </div>
                        <div className="p-8 space-y-6 overflow-y-auto custom-scrollbar text-sm">
                            <div>
                                <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('minutes.attendance')}</p>
                                <p className="text-stone-700">
                                    {(offenesProtokoll.attendees || []).filter((a: any) => a.present).map((a: any) => a.name).join(', ') || '—'}
                                </p>
                            </div>
                            {(['agendaItems', 'decisions'] as const).map(feld => (
                                <div key={feld}>
                                    <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">
                                        {feld === 'agendaItems' ? t('minutes.agenda') : t('minutes.decisions')}
                                    </p>
                                    {(offenesProtokoll[feld] || []).length === 0
                                        ? <p className="text-stone-400 italic">—</p>
                                        : <ol className="list-decimal ml-5 space-y-2">
                                            {(offenesProtokoll[feld] || []).map((e: any, i: number) => (
                                                <li key={i}>
                                                    <span className="font-bold text-stone-900">{e.title}</span>
                                                    {e.content && <p className="text-stone-600 mt-0.5">{e.content}</p>}
                                                </li>
                                            ))}
                                          </ol>}
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            )}

            {/* Vom Vorstand freigegebene Protokolle. Erscheint nur, wenn es
                welche gibt -- ein leerer Kasten mit der Ueberschrift
                "Protokolle" laesst sonst vermuten, es wuerde etwas
                zurueckgehalten. */}
            {protokolle.length > 0 && (
                <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                    <h4 className="font-bold text-xl text-stone-900 flex items-center gap-2 mb-2">
                        <FileText className="text-primary"/> {t('minutes.for_members')}
                    </h4>
                    <p className="text-xs text-stone-500 mb-5">{t('minutes.for_members_hint')}</p>
                    <div className="space-y-2">
                        {protokolle.map(m => (
                            <button key={m.id} onClick={() => setOffenesProtokoll(m)}
                                className="w-full text-left p-4 bg-stone-50 rounded-2xl border border-stone-100 hover:border-primary/30 transition-colors flex justify-between items-center gap-3">
                                <div className="min-w-0">
                                    <p className="font-bold text-sm text-stone-900 truncate">{m.title}</p>
                                    <p className="text-xs text-stone-500">
                                        {new Date(m.date).toLocaleDateString()}
                                        {m.location ? ` · ${m.location}` : ''}
                                    </p>
                                </div>
                                <ArrowRight size={16} className="text-stone-400 shrink-0"/>
                            </button>
                        ))}
                    </div>
                </div>
            )}

            {/* Zugang zur Betreuung, wenn dieses Mitglied eine Nachbarschaft fuehrt */}
            {betreutNachbarschaften.length > 0 && (
                <Link to="/nachbarschaft" className="block bg-stone-900 text-white p-8 rounded-[2.5rem] hover:bg-stone-800 transition-colors">
                    <div className="flex items-center justify-between gap-4">
                        <div>
                            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mb-1">{t('steward.title')}</p>
                            <h4 className="font-display font-bold italic text-2xl">{t('steward.open_panel')}</h4>
                            <p className="text-stone-400 text-xs mt-2">{t('steward.open_panel_hint')}</p>
                        </div>
                        <ArrowRight size={24} className="shrink-0" />
                    </div>
                </Link>
            )}

            {/* Alte Rechnungsansicht: lief ueber payments.neighborhoodId, das
                nur bei 3 von 324 Zahlungen gesetzt ist, und zeigte daher fast
                nichts. Ersetzt durch die Betreuungsansicht oben. */}
            {/* Die frueher hier stehende Rechnungsansicht des Managers ist
                entfallen. Sie las payments.neighborhoodId, das nur bei 3 von
                324 Zahlungen gesetzt ist, und zeigte deshalb fast nichts;
                ersetzt durch /nachbarschaft, verlinkt weiter oben. */}

            {/* 1. Neighborhood Stats & Manager Spotlight */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                
                {/* Community Pulse Chart */}
                <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.1 }} className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm relative overflow-hidden">
                    <div className="flex justify-between items-start mb-6">
                        <div>
                            <h4 className="font-bold text-lg text-stone-900">{t('dash.community.title')}</h4>
                            <p className="text-xs text-stone-500">{neighborhood?.name || 'Lagja'} · {t('dash.community.basis', { year: beitragsjahr })}</p>
                        </div>
                        <div className="bg-stone-50 p-2 rounded-xl">
                            <TrendingUp size={20} className="text-stone-400"/>
                        </div>
                    </div>
                    
                    <div className="flex items-center gap-8">
                        <div className="w-32 h-32 relative">
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie data={stats.chartData} innerRadius={40} outerRadius={55} paddingAngle={5} dataKey="value" startAngle={90} endAngle={-270}>
                                        {stats.chartData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={entry.color} stroke="none" />
                                        ))}
                                    </Pie>
                                </PieChart>
                            </ResponsiveContainer>
                            <div className="absolute inset-0 flex flex-col items-center justify-center">
                                <span className="text-2xl font-bold text-stone-900">{stats.rate}%</span>
                                <span className="text-[8px] uppercase font-bold text-stone-400 tracking-widest">{t('dash.community.paid_short')}</span>
                            </div>
                        </div>
                        <div className="flex-1 space-y-2.5">
                            <div>
                                <p className="text-2xl font-bold text-stone-900">{stats.bezahlt} <span className="text-sm font-normal text-stone-400">/ {stats.total}</span></p>
                                {/* Der Rueckfall auf eine einzelne Person greift nur,
                                    wenn der Server nicht antwortet -- dann waere eine
                                    Quote ueber eine Person irrefuehrend. */}
                                <p className="text-xs text-stone-500 font-medium">
                                    {stats.total > 1 ? t('dash.community.paid_of', { year: beitragsjahr })
                                                     : t('dash.community.own_fee', { year: beitragsjahr })}
                                </p>
                            </div>
                            {/* Die Bestandteile beim Namen nennen -- ein Ring ohne
                                Aufschluesselung laesst offen, woraus die Zahl entsteht. */}
                            <div className="space-y-1 text-[11px]">
                                <p className="flex items-center gap-2 text-stone-600">
                                    <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
                                    {stats.bezahlt} {t('steward.fee_paid', { year: beitragsjahr })}
                                </p>
                                <p className="flex items-center gap-2 text-stone-600">
                                    <span className="w-2 h-2 rounded-full bg-amber-500 shrink-0" />
                                    {stats.offen} {t('steward.fee_open')}
                                </p>
                                {stats.nichtVerrechnet > 0 && (
                                    <p className="flex items-center gap-2 text-stone-500">
                                        <span className="w-2 h-2 rounded-full bg-stone-300 shrink-0" />
                                        {stats.nichtVerrechnet} {t('steward.fee_none')}
                                    </p>
                                )}
                            </div>
                            <p className="text-[10px] text-stone-400 border-t border-stone-100 pt-2">
                                {t('dash.community.active_short')}: {stats.active} / {stats.total}
                            </p>
                        </div>
                    </div>
                </motion.div>

                {/* Manager Spotlight Card */}
                <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.2 }} className="bg-gradient-to-br from-stone-100 to-white p-8 rounded-[2.5rem] border border-stone-200 shadow-sm relative">
                    <div className="absolute top-4 right-4 bg-white px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest shadow-sm text-stone-500">
                        {t('dash.manager.title')}
                    </div>
                    
                    <div className="flex flex-col items-center text-center mt-4">
                        <div className="w-20 h-20 rounded-full border-4 border-white shadow-lg overflow-hidden mb-4 bg-stone-200">
                            {manager?.photoFileName ? (
                                <img src={manager.photoFileName} className="w-full h-full object-cover"  onError={onImageError}/>
                            ) : (
                                <div className="w-full h-full flex items-center justify-center text-2xl font-bold text-stone-400">{manager?.displayName?.charAt(0) || '?'}</div>
                            )}
                        </div>
                        <h4 className="text-xl font-bold text-stone-900 mb-1">{manager?.displayName || t('dash.manager.none')}</h4>
                        <p className="text-xs text-stone-500 mb-6 flex items-center gap-1">
                            <MapPin size={10}/> {manager?.city || neighborhoodCity(neighborhood)}
                        </p>

                        <div className="flex gap-2 w-full">
                            {manager?.email && (
                                <a href={`mailto:${manager.email}`} className="flex-1 py-2 bg-white border border-stone-200 rounded-xl text-stone-600 text-xs font-bold flex items-center justify-center gap-2 hover:border-primary hover:text-primary transition-all">
                                    <Mail size={14}/> {t('dash.manager.email')}
                                </a>
                            )}
                            {manager?.phone && (
                                <a href={`tel:${manager.phone}`} className="flex-1 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-black transition-all">
                                    <Phone size={14}/> {t('dash.manager.call')}
                                </a>
                            )}
                        </div>
                    </div>
                </motion.div>
            </div>

            {/* REQUEST CENTER (INQUIRIES) */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                <div className="flex justify-between items-center mb-6">
                    <h4 className="font-bold text-xl text-stone-900 flex items-center gap-2"><HelpCircle className="text-primary"/> {t('dash.requests.title')}</h4>
                    <button onClick={() => setShowRequestModal(true)} className="bg-stone-900 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-black transition-all shadow-lg">
                        <Plus size={14} /> {t('dash.requests.new')}
                    </button>
                </div>

                <div className="space-y-3">
                    {inquiries.length === 0 ? (
                        <div className="text-center py-8 bg-stone-50 rounded-2xl border border-dashed border-stone-200">
                            <p className="text-stone-400 italic text-sm">{t('dash.no_inquiries')}</p>
                        </div>
                    ) : (
                        inquiries.map(req => (
                            <div key={req.id} className="p-4 bg-stone-50 rounded-2xl border border-stone-100 flex justify-between items-center group hover:bg-white hover:shadow-md transition-all">
                                <div>
                                    <div className="flex items-center gap-2 mb-1">
                                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wide ${req.type === 'DONATION' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'}`}>
                                            {t(`req.type.${req.type}`)}
                                        </span>
                                        <span className="text-xs text-stone-400 flex items-center gap-1"><Clock size={10}/> {req.createdAt?.toDate().toLocaleDateString()}</span>
                                    </div>
                                    <h5 className="font-bold text-stone-800 text-sm">{req.subject}</h5>
                                    {req.adminNote && (
                                        <p className="text-xs text-stone-500 mt-1 italic border-l-2 border-primary pl-2">Admin: {req.adminNote}</p>
                                    )}
                                </div>
                                <span className={`text-xs font-bold px-3 py-1 rounded-full ${req.status === 'DONE' ? 'bg-green-50 text-white' : req.status === 'IN_PROGRESS' ? 'bg-blue-50 text-white' : req.status === 'REJECTED' ? 'bg-red-50 text-white' : 'bg-stone-200 text-stone-500'}`}>
                                    {t(`req.status.${req.status}`)}
                                </span>
                            </div>
                        ))
                    )}
                </div>
            </div>

            {/* 2. Visual Neighbors Grid */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                <div className="flex justify-between items-end mb-8">
                    <div>
                        <h4 className="font-bold text-xl text-stone-900 mb-1">{t('dash.neighbors.title')}</h4>
                        <p className="text-stone-500 text-sm">{t('dash.neighbors.subtitle')} {neighborhood?.name}</p>
                        {/* Ohne Legende sind farbige Punkte nur Dekoration. */}
                        {istBetreuer && (
                            <div className="flex flex-wrap items-center gap-4 mt-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">
                                <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> {t('steward.fee_paid', { year: beitragsjahr })}</span>
                                <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-amber-500" /> {t('steward.fee_open')}</span>
                                <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-stone-300" /> {t('steward.fee_none')}</span>
                                <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-rose-500" /> {t('steward.data_gaps')}</span>
                            </div>
                        )}
                    </div>
                    <div className="text-xs font-bold bg-stone-50 px-3 py-1 rounded-lg text-stone-400">
                        {Object.keys(groupedNeighbors.families).length + groupedNeighbors.individuals.length} {t('dash.neighbors.families')}
                    </div>
                </div>

                <div className="space-y-8">
                    {/* Render Families */}
                    {Object.entries(groupedNeighbors.families).length > 0 && (
                        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
                            {Object.entries(groupedNeighbors.families).map(([famId, members]: [string, UserProfile[]]) => (
                                <motion.div 
                                    key={famId}
                                    initial={{ opacity: 0, scale: 0.95 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    className="bg-stone-50 rounded-3xl p-5 border border-stone-100 relative overflow-hidden"
                                >
                                    <div className="absolute top-0 right-0 w-16 h-16 bg-white/50 rounded-full blur-2xl -translate-y-1/2 translate-x-1/2" />
                                    <div className="flex items-center gap-2 mb-4">
                                        <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center text-primary border border-stone-100 shadow-sm font-bold text-xs">
                                            {members.length}
                                        </div>
                                        <span className="font-bold text-sm text-stone-800">{t('dash.neighbors.family_prefix')} {members[0].lastName || members[0].displayName?.split(' ').pop()}</span>
                                    </div>
                                    <div className="flex flex-wrap gap-2">
                                        {members.map(m => (
                                            <div 
                                                key={m.id} 
                                                onClick={() => handleOpenManageNeighbor(m)}
                                                className={`bg-white px-3 py-1.5 rounded-lg border border-stone-100 shadow-sm flex items-center gap-2 relative ${istBetreuer ? 'cursor-pointer hover:border-primary/50 hover:shadow-md transition-all' : ''}`}
                                            >
                                                {istBetreuer && luckenVon(m).length > 0 && (
                                                    <div className="absolute -top-1 -right-1 w-3 h-3 bg-rose-500 rounded-full flex items-center justify-center z-10 border border-white"
                                                         title={`${t('steward.data_missing')}: ${luckenVon(m).map(k => t(k)).join(', ')}`}>
                                                        <AlertTriangle size={8} className="text-white"/>
                                                    </div>
                                                )}
                                                
                                                {m.photoFileName ? (
                                                    <img src={m.photoFileName} className="w-5 h-5 rounded-full object-cover"  onError={onImageError}/>
                                                ) : (
                                                    <div className="w-5 h-5 rounded-full bg-stone-100 flex items-center justify-center text-[8px] font-bold text-stone-400">
                                                        {m.firstName?.charAt(0) || m.displayName?.charAt(0)}
                                                    </div>
                                                )}
                                                <span className="text-xs font-medium text-stone-600">{m.firstName || m.displayName?.split(' ')[0]}</span>
                                                {istBetreuer ? (
                                                    <div className={`w-1.5 h-1.5 rounded-full ${
                                                        beitragVon(m) === 'PAID' ? 'bg-emerald-500'
                                                        : beitragVon(m) === 'OPEN' ? 'bg-amber-500' : 'bg-stone-300'}`}
                                                        title={beitragVon(m) === 'PAID' ? t('steward.fee_paid', { year: beitragsjahr })
                                                             : beitragVon(m) === 'OPEN' ? t('steward.fee_open') : t('steward.fee_none')} />
                                                ) : m.membershipStatus === 'ACTIVE' && <div className="w-1.5 h-1.5 bg-green-500 rounded-full" />}
                                            </div>
                                        ))}
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    )}

                    {/* Render Individuals */}
                    {groupedNeighbors.individuals.length > 0 && (
                        <div>
                            {Object.keys(groupedNeighbors.families).length > 0 && (
                                <h5 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 mt-2">{t('dash.neighbors.individuals')}</h5>
                            )}
                            <div className="flex flex-wrap gap-4 justify-center md:justify-start">
                                {groupedNeighbors.individuals.map((n, i) => (
                                    <motion.div 
                                        key={n.id} 
                                        initial={{ opacity: 0, scale: 0 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        transition={{ delay: i * 0.05 }}
                                        onClick={() => handleOpenManageNeighbor(n)}
                                        className={`flex flex-col items-center gap-2 w-20 group relative ${istBetreuer ? 'cursor-pointer' : 'cursor-default'}`}
                                    >
                                        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-xl font-bold border-2 transition-all shadow-sm overflow-hidden relative ${n.membershipStatus === 'ACTIVE' ? 'border-emerald-100 bg-emerald-50 text-emerald-600' : 'border-stone-100 bg-stone-50 text-stone-400 grayscale'}`}>
                                            {n.photoFileName ? (
                                                <img src={n.photoFileName} className="w-full h-full object-cover"  onError={onImageError}/>
                                            ) : (
                                                n.displayName?.charAt(0)
                                            )}
                                            {/* Fuer die verantwortliche Person zeigt die Ecke den
                                                Beitrag des laufenden Jahres. Vorher stand hier der
                                                Mitgliedsstatus -- bei fast allen ACTIVE, weshalb die
                                                Uebersicht durchgehend gruen aussah und nichts aussagte. */}
                                            {istBetreuer ? (
                                                <div className={`absolute bottom-0 right-0 w-4 h-4 rounded-tl-lg flex items-center justify-center ${
                                                    beitragVon(n) === 'PAID' ? 'bg-emerald-500'
                                                    : beitragVon(n) === 'OPEN' ? 'bg-amber-500' : 'bg-stone-300'}`}
                                                    title={beitragVon(n) === 'PAID' ? t('steward.fee_paid', { year: beitragsjahr })
                                                         : beitragVon(n) === 'OPEN' ? t('steward.fee_open') : t('steward.fee_none')}>
                                                    {beitragVon(n) === 'PAID'
                                                        ? <CheckCircle2 size={10} className="text-white"/>
                                                        : <Clock size={10} className="text-white"/>}
                                                </div>
                                            ) : n.membershipStatus === 'ACTIVE' && (
                                                <div className="absolute bottom-0 right-0 w-4 h-4 bg-emerald-500 rounded-tl-lg flex items-center justify-center">
                                                    <CheckCircle2 size={10} className="text-white"/>
                                                </div>
                                            )}
                                        </div>

                                        {/* Fehlende Angaben, mit Nennung der Felder im Tooltip --
                                            ein blosses Ausrufezeichen sagt nicht, was zu tun ist. */}
                                        {istBetreuer && luckenVon(n).length > 0 && (
                                            <div className="absolute top-0 right-2 w-5 h-5 bg-rose-500 rounded-full flex items-center justify-center z-10 border-2 border-white shadow-sm"
                                                 title={`${t('steward.data_missing')}: ${luckenVon(n).map(k => t(k)).join(', ')}`}>
                                                <AlertTriangle size={10} className="text-white"/>
                                            </div>
                                        )}

                                        <p className="text-[10px] text-stone-600 font-bold text-center line-clamp-2 w-full px-1 group-hover:text-primary transition-colors leading-tight">
                                            {n.displayName}
                                        </p>
                                    </motion.div>
                                ))}
                            </div>
                        </div>
                    )}

                    {neighbors.length === 0 && (
                        <p className="text-stone-400 italic text-sm w-full text-center py-8">{t('dash.neighbors.first')}</p>
                    )}
                </div>
            </div>

        </div>
      </div>

      {/* MANAGER: MANAGE MEMBER MODAL */}
      <AnimatePresence>
        {managedNeighbor && (
            <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div 
                    initial={{ scale: 0.95, opacity: 0 }} 
                    animate={{ scale: 1, opacity: 1 }} 
                    exit={{ scale: 0.95, opacity: 0 }}
                    className="bg-white w-full max-w-lg rounded-[2.5rem] shadow-2xl relative overflow-hidden"
                >
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center text-primary font-bold shadow-sm">
                                {managedNeighbor.displayName?.charAt(0)}
                            </div>
                            <div>
                                <h3 className="font-bold text-lg text-stone-900">{managedNeighbor.displayName}</h3>
                                <p className="text-xs text-stone-500">{t('dash.manage_profile')}</p>
                            </div>
                        </div>
                        <button onClick={() => setManagedNeighbor(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors">
                            <X size={20}/>
                        </button>
                    </div>
                    
                    <div className="p-8 space-y-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                        {(() => {
                            const missing = [];
                            if (!managedData.phone) missing.push(t('field.phone'));
                            if (!managedData.street || !managedData.zip || !managedData.city) missing.push(t('profile.address'));
                            if (!managedData.birthdate) missing.push(t('field.birthdate'));
                            if (!managedData.email) missing.push('Email');
                            
                            if (missing.length > 0) {
                                return (
                                    <div className="bg-amber-50 p-4 rounded-xl border border-amber-100 flex gap-3 text-amber-800 text-sm">
                                        <AlertTriangle className="shrink-0" size={20}/>
                                        <p>Daten fehlen: {missing.join(', ')}.</p>
                                    </div>
                                );
                            }
                            return null;
                        })()}

                        <div className="space-y-4">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.email')}</label>
                                <input 
                                    value={managedData.email || ''}
                                    onChange={e => setManagedData({...managedData, email: e.target.value})}
                                    placeholder={t('ph.email_example')}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.phone')}</label>
                                <input 
                                    value={managedData.phone || ''}
                                    onChange={e => setManagedData({...managedData, phone: e.target.value})}
                                    placeholder={t('ph.phone_short')}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.address')}</label>
                                <input 
                                    value={managedData.street || ''}
                                    onChange={e => setManagedData({...managedData, street: e.target.value})}
                                    placeholder={t('ph.street_short')}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none mb-2"
                                />
                                <div className="flex gap-2 mb-2">
                                    <input 
                                        value={managedData.zip || ''}
                                        onChange={e => setManagedData({...managedData, zip: e.target.value})}
                                        placeholder={t('ph.zip_short')}
                                        className="w-24 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                    />
                                    <input 
                                        value={managedData.city || ''}
                                        onChange={e => setManagedData({...managedData, city: e.target.value})}
                                        placeholder={t('ph.city_short')}
                                        className="flex-1 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                    />
                                </div>
                                {/* Auswahl statt freiem Text -- sonst stehen "DE",
                                    "Holland", "FR" und "Schweiz" nebeneinander. Das
                                    eigene Profil weiter unten macht es schon so; hier,
                                    beim Verwalten fremder Profile, war es vergessen. */}
                                <CountrySelect
                                    value={managedData.country}
                                    onChange={(v) => setManagedData({...managedData, country: v})}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.birthdate')}</label>
                                <input 
                                    type="date"
                                    value={managedData.birthdate || ''}
                                    onChange={e => setManagedData({...managedData, birthdate: e.target.value})}
                                    className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none"
                                />
                            </div>
                        </div>

                        <div className="pt-4 border-t border-stone-100 flex flex-col gap-3">
                            <button onClick={handleSaveManagedNeighbor} className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-black transition-all">
                                <Save size={16}/> {t('dash.save_data')}
                            </button>
                            <div className="relative py-2 flex items-center">
                                <div className="flex-grow border-t border-stone-200"></div>
                                <span className="flex-shrink-0 mx-4 text-stone-400 text-xs font-bold uppercase">{t('common.or')}</span>
                                <div className="flex-grow border-t border-stone-200"></div>
                            </div>
                            <button onClick={handleSendUpdateRequest} className="w-full py-3 bg-white border border-stone-200 text-stone-600 rounded-xl font-bold flex items-center justify-center gap-2 hover:border-primary hover:text-primary transition-all">
                                <Send size={16}/> {t('dash.invite_update')}
                            </button>
                        </div>
                    </div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* REQUEST MODAL */}
      <AnimatePresence>
        {showRequestModal && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div 
                    initial={{ scale: 0.95, opacity: 0 }} 
                    animate={{ scale: 1, opacity: 1 }} 
                    exit={{ scale: 0.95, opacity: 0 }}
                    className="bg-white w-full max-w-lg rounded-[2.5rem] shadow-2xl overflow-hidden relative"
                >
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
                            <MessageSquare className="text-primary"/> {t('dash.requests.new')}
                        </h3>
                        <button onClick={() => setShowRequestModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors">
                            <X size={20}/>
                        </button>
                    </div>
                    
                    <div className="p-8 space-y-6">
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-2">{t('dash.requests.type')}</label>
                            <div className="grid grid-cols-3 gap-2">
                                {(['GENERAL', 'DONATION', 'PROJECT'] as const).map(type => (
                                    <button 
                                        key={type} 
                                        onClick={() => setNewRequest({...newRequest, type})}
                                        className={`py-3 rounded-xl text-xs font-bold border-2 transition-all ${newRequest.type === type ? 'border-primary bg-primary/5 text-primary' : 'border-stone-100 text-stone-400 hover:border-stone-200'}`}
                                    >
                                        {t(`req.type.${type}`)}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {newRequest.type === 'DONATION' && (
                            <div className="p-4 bg-green-50 border border-green-100 rounded-xl text-green-800 text-sm italic">
                                Thank you! The admin will contact you to arrange the details or issue a donation receipt.
                            </div>
                        )}

                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('dash.requests.subject')}</label>
                            <input 
                                value={newRequest.subject}
                                onChange={e => setNewRequest({...newRequest, subject: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl font-bold text-stone-900 outline-none focus:border-primary/50"
                                placeholder="..."
                            />
                        </div>

                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('dash.requests.message')}</label>
                            <textarea 
                                value={newRequest.message}
                                onChange={e => setNewRequest({...newRequest, message: e.target.value})}
                                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/50 h-32"
                                placeholder="..."
                            />
                        </div>

                        <button onClick={handleSubmitRequest} className="w-full py-4 bg-stone-900 text-white rounded-xl font-bold shadow-lg hover:bg-black transition-all">
                            {t('dash.requests.submit')}
                        </button>
                    </div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* EDIT PROFILE MODAL */}
      <AnimatePresence>
        {showProfileModal && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                <motion.div 
                    initial={{ scale: 0.95, opacity: 0 }} 
                    animate={{ scale: 1, opacity: 1 }} 
                    exit={{ scale: 0.95, opacity: 0 }}
                    className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl relative overflow-hidden flex flex-col max-h-[90vh]"
                >
                    <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
                            <UserCog className="text-primary"/> {t('profile.edit')}
                        </h3>
                        <button onClick={() => setShowProfileModal(false)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors">
                            <X size={20}/>
                        </button>
                    </div>
                    
                    <div className="flex-1 overflow-y-auto p-8 space-y-8 custom-scrollbar">
                        {/* Identity */}
                        <div>
                            <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">{t('profile.identity')}</h4>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.salutation')}</label>
                                    <select 
                                        value={profileData.salutation || ''} 
                                        onChange={e => setProfileData({...profileData, salutation: e.target.value})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium"
                                    >
                                        <option value="">...</option>
                                        <option value="Z.">Z.</option>
                                        <option value="Znj.">{t('salutation.ms')}</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.birthdate')}</label>
                                    <input 
                                        type="date"
                                        value={profileData.birthdate || ''} 
                                        onChange={e => setProfileData({...profileData, birthdate: e.target.value})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.firstName')}</label>
                                    <input 
                                        value={profileData.firstName || ''} 
                                        onChange={e => setProfileData({...profileData, firstName: e.target.value})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.lastName')}</label>
                                    <input 
                                        value={profileData.lastName || ''} 
                                        onChange={e => setProfileData({...profileData, lastName: e.target.value})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Contact */}
                        <div>
                            <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">{t('profile.contact')}</h4>
                            <div className="space-y-4">
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.phone')}</label>
                                        <input 
                                            value={profileData.phone || ''} 
                                            onChange={e => setProfileData({...profileData, phone: e.target.value})}
                                            className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                        />
                                    </div>
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.email')}</label>
                                        <input 
                                            value={profileData.email || ''} 
                                            disabled
                                            className="w-full p-3 bg-stone-100 border border-stone-200 rounded-xl outline-none text-sm font-medium text-stone-400 cursor-not-allowed" 
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-2">{t('profile.invoice_method')}</label>
                                    <div className="flex gap-2">
                                        {(['EMAIL', 'POST', 'BOTH'] as const).map(method => (
                                            <button
                                                key={method}
                                                onClick={() => setProfileData({...profileData, invoiceDeliveryMethod: method})}
                                                className={`flex-1 py-2 rounded-lg text-xs font-bold border transition-all ${profileData.invoiceDeliveryMethod === method ? 'bg-primary text-white border-primary' : 'bg-white text-stone-500 border-stone-200 hover:bg-stone-50'}`}
                                            >
                                                {method}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Address */}
                        <div>
                            <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">{t('profile.address')}</h4>
                            <div className="space-y-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.street')}</label>
                                    <input 
                                        value={profileData.street || ''} 
                                        onChange={e => setProfileData({...profileData, street: e.target.value})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                    />
                                </div>
                                <div className="grid grid-cols-3 gap-4">
                                    <div>
                                        <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.zip')}</label>
                                        <input 
                                            value={profileData.zip || ''} 
                                            onChange={e => setProfileData({...profileData, zip: e.target.value})}
                                            className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                        />
                                    </div>
                                    <div className="col-span-2">
                                        <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.city')}</label>
                                        <input 
                                            value={profileData.city || ''} 
                                            onChange={e => setProfileData({...profileData, city: e.target.value})}
                                            className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium" 
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 block mb-1">{t('field.country')}</label>
                                    <CountrySelect
                                        value={profileData.country}
                                        onChange={(v) => setProfileData({...profileData, country: v})}
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-medium"
                                    />
                                </div>
                            </div>

                            {/* Der Widerspruch gegen das oeffentliche
                                Erscheinen. Er gewinnt gegen die Einstellung
                                des Vereins -- auch wenn dieser Namen
                                veroeffentlicht, steht dieses Mitglied nicht
                                dabei, und im Mitgliederband der Startseite
                                ebenfalls nicht. */}
                            <label className="flex items-start gap-3 p-4 rounded-2xl border border-stone-200 bg-stone-50 cursor-pointer mt-6">
                                <input type="checkbox" checked={!!profileData.nicht_oeffentlich}
                                    onChange={e => setProfileData({ ...profileData, nicht_oeffentlich: e.target.checked })}
                                    className="mt-0.5 w-4 h-4 accent-[color:var(--primary)] shrink-0" />
                                <span>
                                    <span className="block text-sm font-bold text-stone-800">{t('oeff.mitglied')}</span>
                                    <span className="block text-xs text-stone-500 leading-relaxed mt-0.5">{t('oeff.mitglied_text')}</span>
                                </span>
                            </label>
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

      {/* Invoice Modal (Preview + PDF) */}
      <AnimatePresence>
        {viewInvoice && paymentSettings && (
            <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/80 backdrop-blur-md">
                <motion.div 
                    initial={{ scale: 0.95, opacity: 0 }} 
                    animate={{ scale: 1, opacity: 1 }} 
                    exit={{ scale: 0.95, opacity: 0 }}
                    className="bg-stone-100 w-full max-w-4xl rounded-[2rem] overflow-hidden shadow-2xl flex flex-col max-h-[90vh]"
                >
                    <div className="p-4 border-b border-stone-200 flex justify-between items-center bg-white">
                        <h3 className="font-bold text-stone-800">Fatura #{viewInvoice.invoiceNumber}</h3>
                        <div className="flex gap-2">
                            <button onClick={handleDownloadPdf} className="px-4 py-2 bg-stone-900 text-white rounded-lg text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors">
                                <Download size={14} /> {t('dash.download_pdf')}
                            </button>
                            <button onClick={() => setViewInvoice(null)} className="p-2 hover:bg-stone-100 rounded-lg text-stone-500"><X size={20}/></button>
                        </div>
                    </div>
                    
                    <div className="flex-1 overflow-y-auto p-8 flex justify-center custom-scrollbar">
                        <div id="invoice-preview-content" className="bg-white shadow-xl w-[210mm] min-h-[297mm] p-[20mm] text-stone-900 relative flex flex-col">
                             {/* Header */}
                             <div className="flex justify-between mb-12">
                                <div>
                                   <div className="flex items-center gap-2 mb-4">
                                       <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-white font-bold text-xs">{initialsOf(loc(branding.associationName) || 'Shoqata Koretini')}</div>
                                       <span className="font-display font-bold italic text-xl">{loc(branding.associationName) || 'Shoqata Koretini'}</span>
                                   </div>
                                   <h1 className="text-4xl font-bold text-stone-900 mb-2">{t('invoice.heading')}</h1>
                                   <p className="text-sm text-stone-500 font-mono">#{viewInvoice.invoiceNumber}</p>
                                   <p className="text-sm text-stone-500 mt-1">{t('field.date')}: {new Date(viewInvoice.timestamp?.toDate()).toLocaleDateString()}</p>
                                </div>
                                <div className="text-right text-sm leading-relaxed">
                                   <p className="font-bold text-lg mb-1">{paymentSettings.accountHolder}</p>
                                   <p>{paymentSettings.street}</p>
                                   <p>{paymentSettings.zip} {paymentSettings.city}</p>
                                   <p>{paymentSettings.country}</p>
                                   <p className="mt-2 text-stone-500">{paymentSettings.contactEmail || 'info@koretini.org'}</p>
                                </div>
                             </div>

                             {/* Recipient */}
                             <div className="mb-16 bg-stone-50 p-6 rounded-xl border border-stone-100">
                                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-3">{t('invoice.billed_to')}</p>
                                <p className="font-bold text-xl">{user.displayName}</p>
                                <p className="text-stone-600 text-lg whitespace-pre-line">{user.address}</p>
                             </div>

                             {/* Details Table */}
                             <table className="w-full mb-12">
                                <thead>
                                   <tr className="border-b-2 border-stone-900 text-left text-xs font-bold uppercase tracking-widest">
                                      <th className="py-3">{t('invoice.description')}</th>
                                      <th className="py-3 text-right">{t('invoice.amount')}</th>
                                   </tr>
                                </thead>
                                <tbody>
                                   <tr className="border-b border-stone-100">
                                      <td className="py-6 text-lg font-medium">{viewInvoice.description}</td>
                                      <td className="py-6 text-right font-mono text-lg">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</td>
                                   </tr>
                                </tbody>
                                <tfoot>
                                   <tr>
                                      <td className="py-6 font-bold text-right text-lg">{t('invoice.total')}</td>
                                      <td className="py-6 text-right font-bold text-3xl">{viewInvoice.amount.toFixed(2)} {viewInvoice.currency}</td>
                                   </tr>
                                </tfoot>
                             </table>

                             <div className="mt-auto">
                                <p className="text-sm text-stone-500 mb-8 italic text-center">{t('invoice.thanks')}</p>
                                {/* Swiss QR Bill (Bottom) */}
                                <div className="border-t-2 border-dashed border-stone-300 pt-8">
                                   <SwissQRBill data={getQrData(viewInvoice)!} />
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

export default Dashboard;
