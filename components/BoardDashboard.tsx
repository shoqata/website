
import { useJahresauswahl } from '../lib/useVereinsjahre';
import NachrichtenVerwaltung from './NachrichtenVerwaltung';
import NbWebsiteLeiste from './NbWebsiteLeiste';
import AdminNeighborhoodEditor from './AdminNeighborhoodEditor';
import { useModule } from '../lib/useModule';
import React, { useState, useEffect, useMemo } from 'react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile, Payment, Neighborhood, BoardMeeting } from '../types';
import BoardMinutesEditor from './BoardMinutesEditor';
import VorstandWizard from './VorstandWizard';
import VorstandPostausgang from './VorstandPostausgang';
import AnfragenBearbeiten from './AnfragenBearbeiten';
import ProtokollTeilen from './ProtokollTeilen';
import CountrySelect from './ui/CountrySelect';
import { missingFieldKeys } from '../lib/memberQuality';
import { markPaymentPaid, zahlungDifferenzSetzen } from '@/services/supabase-bridge';
import { beitragFuer } from '../lib/beitrag';
import { einstellungLaden } from '../lib/einstellungen';
import { db } from '../services/datenzugriff';
import { collection, query, orderBy, onSnapshot, doc, updateDoc } from '@/services/supabase-bridge';
import { 
  Briefcase, 
  CalendarDays, 
  Search, 
  UserCog, 
  CheckCircle2, 
  AlertCircle, 
  FileText, 
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
  CreditCard,
  Plus,
  FileEdit,
  Loader2
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useFeedback } from '../context/FeedbackContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, CartesianGrid } from 'recharts';

import { neighborhoodCity } from '../lib/neighborhood';
import { billingYearOf, isOverdue } from '../lib/memberQuality';
import { onImageError } from '../lib/imageFallback';
import AenderungenVerwaltung from './AenderungenVerwaltung';
interface BoardDashboardProps {
  user: UserProfile;
}

const BoardDashboard: React.FC<BoardDashboardProps> = ({ user }) => {
  const { aktiv: modulAktiv } = useModule();
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  
  // Data State
  const [selectedYear, setSelectedYear, vereinsjahre] = useJahresauswahl();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [nbBearbeiten, setNbBearbeiten] = useState<Partial<Neighborhood> | null>(null);
  const [meetings, setMeetings] = useState<BoardMeeting[]>([]);
  
  // UI State
  const [searchTerm, setSearchTerm] = useState('');
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [profileData, setProfileData] = useState<Partial<UserProfile>>({});
  const [selectedMeeting, setSelectedMeeting] = useState<BoardMeeting | null>(null);
  // Protokoll bearbeiten: null bedeutet ein neues, ein Objekt eine Ueberarbeitung.
  const [editMeeting, setEditMeeting] = useState<BoardMeeting | null>(null);
  const [editorOffen, setEditorOffen] = useState(false);
  // Mitgliedsangaben berichtigen
  const [memberForm, setMemberForm] = useState<any>(null);
  // Die Beitragssaetze. Gebraucht, um zu zeigen, WOVON ein individueller
  // Betrag abweicht -- eine Zahl ohne diesen Bezug laedt dazu ein, sie
  // fuer den Gruppensatz zu halten.
  const [saetze, setSaetze] = useState<any>(null);
  const [memberSaving, setMemberSaving] = useState(false);
  
  // New UI States
  const [selectedMember, setSelectedMember] = useState<UserProfile | null>(null); // For Search Result Modal
  const [showInvoiceListModal, setShowInvoiceListModal] = useState<'PAID' | 'OPEN' | null>(null); // For KPI Drilldown
  // Eigene Suche im Rechnungsfenster -- die Liste umfasst mehrere hundert
  // Eintraege, und wer eine bestimmte Person sucht, scrollt sonst.
  const [rechnungsSuche, setRechnungsSuche] = useState('');
  const [zeigeNachbarschaften, setZeigeNachbarschaften] = useState(false);
  const [nbSuche, setNbSuche] = useState('');

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

    // 5. Board Meetings (Protocols)
    const qMeetings = query(collection(db, 'board_meetings'), orderBy('date', 'desc'));
    const unsubMeetings = onSnapshot(qMeetings, (snap) => {
        setMeetings(snap.docs.map(d => ({ id: d.id, ...d.data() } as BoardMeeting)));
    });

    return () => { unsubPayments(); unsubUsers(); unsubNeighborhoods(); unsubMeetings(); };
  }, []);

  // DERIVED STATS & ANALYTICS
  // Frueher wurde nach dem Zeitstempel gefiltert, also danach, wann der
  // Datensatz entstand. Massgeblich ist aber billingYear -- das Jahr, fuer das
  // der Beitrag erhoben wird. Gemessen: fuer 2026 zaehlte die Ansicht dadurch
  // 324 Zahlungen statt 321 und 80 bezahlte statt 79. Eine Rechnung gehoert
  // ins Jahr 2025 und wurde hier mitgezaehlt.
  const yearPayments = useMemo(
    () => payments.filter(p => billingYearOf(p) === selectedYear),
    [payments, selectedYear]
  );
  
  const stats = useMemo(() => {
      const paid = yearPayments.filter(p => p.status === 'PAID');
      // Offen heisst hier: noch nicht bezahlt. Ueberfaellig ist eine
      // Teilmenge davon und wird gesondert ausgewiesen.
      const open = yearPayments.filter(p => p.status !== 'PAID' && p.status !== 'CANCELLED');
      const ueberfaellig = open.filter(p => isOverdue(p));
      
      const totalRevenue = paid.reduce((acc, p) => acc + p.amount, 0);
      const openRevenue = open.reduce((acc, p) => acc + p.amount, 0);

      // Payment Percentage Calculation
      const totalVolume = totalRevenue + openRevenue;
      const paidPercentage = totalVolume > 0 ? Math.round((totalRevenue / totalVolume) * 100) : 0;

      return {
          paidCount: paid.length,
          openCount: open.length,
          overdueCount: ueberfaellig.length,
          overdueAmount: ueberfaellig.reduce((acc, p) => acc + (p.amount || 0), 0),
          totalRevenue,
          openRevenue,
          paidPercentage,
          paidInvoices: paid, // Store for modal list
          openInvoices: open  // Store for modal list
      };
  }, [yearPayments]);

  // Eine Nachbarschaft braucht eine Mindestgroesse, um in der Rangliste nach
  // Quote zu erscheinen. Gemessen: 9 der 27 haben weniger als fuenf
  // Mitglieder, und dort springt die Quote zwischen 0 und 100 Prozent, ohne
  // etwas auszusagen -- eine Nachbarschaft mit einem einzigen zahlenden
  // Mitglied stuende sonst dauerhaft an der Spitze.
  const MINDESTGROESSE = 5;

  const neighborhoodAnalytics = useMemo(() => {
      // Entfernte Mitglieder zaehlen nicht mit: sie stuenden im Nenner, ohne
      // je zahlen zu koennen.
      const aktive = users.filter(u => u.membershipStatus !== 'INACTIVE');

      const data = neighborhoods.map(n => {
          const nUsers = aktive.filter(u => u.neighborhoodId === n.id);
          const uIds = new Set(nUsers.map(u => u.id));
          const bezahlt = yearPayments.filter(p => uIds.has(p.userId!) && p.status === 'PAID');
          const zahlende = new Set(bezahlt.map(p => p.userId)).size;
          const chf = bezahlt.reduce((sum, p) => sum + (p.amount || 0), 0);

          return {
              name: n.name,
              city: neighborhoodCity(n),
              mitglieder: nUsers.length,
              zahlende,
              chf,
              // Der Balken zeigt die Quote; CHF und Mitgliederzahl stehen im
              // Hinweisfenster daneben.
              quote: nUsers.length > 0 ? Math.round((zahlende / nUsers.length) * 100) : 0,
          };
      });

      const wertbar = data.filter(d => d.mitglieder >= MINDESTGROESSE);
      const sortiert = [...wertbar].sort((a, b) => b.quote - a.quote || b.chf - a.chf);

      return {
          top5: sortiert.slice(0, 5),
          // Die schwaechste zuerst, damit oben steht, wo am meisten zu tun ist.
          bottom5: sortiert.slice(-5).reverse(),
          zuKlein: data.length - wertbar.length,
          mindest: MINDESTGROESSE,
          // Alle, auch die kleinen -- in der Uebersicht gehoert nichts
          // unterschlagen; dort steht die Mitgliederzahl daneben.
          alle: [...data].sort((a, b) => b.mitglieder - a.mitglieder),
      };
  }, [neighborhoods, users, yearPayments]);

  // Statt "value : 2052" die drei Zahlen, um die es geht.
  const NachbarschaftsHinweis = ({ active, payload }: any) => {
      if (!active || !payload?.length) return null;
      const d = payload[0].payload;
      return (
          <div className="bg-white rounded-xl shadow-lg border border-stone-100 px-4 py-3 text-xs">
              <p className="font-bold text-stone-900 mb-1.5">{d.name}</p>
              <p className="text-stone-600">
                  {t('board.rate')}: <b className="text-stone-900">{d.quote}%</b>
              </p>
              <p className="text-stone-600">
                  {t('board.paid_members', { paid: d.zahlende, total: d.mitglieder })}
              </p>
              <p className="text-stone-600">
                  {t('board.collected')}: <b className="text-stone-900">{d.chf.toLocaleString('de-CH')} CHF</b>
              </p>
          </div>
      );
  };

  React.useEffect(() => {
    // Ueber einstellungLaden: die Saetze stehen in der Spalte payment,
    // nicht in data. Genau diese Verwechslung hat heute dazu gefuehrt,
    // dass Mahnungen ohne IBAN scheiterten.
    einstellungLaden('payment').then(setSaetze).catch(() => setSaetze(null));
  }, []);

  // Angaben eines Mitglieds berichtigen.
  //
  // Geschrieben werden nur die Felder dieser Maske. Rolle, Nachbarschaft und
  // Beitragsgruppe bleiben aussen vor -- was nicht mitgeschickt wird, kann sich
  // nicht versehentlich aendern.
  const handleSaveMember = async () => {
      if (!memberForm?.id) return;
      setMemberSaving(true);
      try {
          await updateDoc(doc(db, 'users', memberForm.id), {
              email: memberForm.email?.trim() || null,
              phone: memberForm.phone?.trim() || null,
              birthdate: memberForm.birthdate?.trim() || null,
              street: memberForm.street?.trim() || '',
              zip: memberForm.zip?.trim() || '',
              city: memberForm.city?.trim() || '',
              country: memberForm.country || '',
              // Die QR-Rechnung liest address vor street; beide muessen
              // uebereinstimmen, sonst steht auf der Rechnung die alte Strasse.
              address: memberForm.street?.trim() || '',
              // Beitragsgruppe und eigener Beitrag. Der Server erlaubt dem
              // Vorstand beides seit immer -- is_member_manager() schliesst
              // BOARD ein --, es fehlte nur das Feld.
              billingGroup: memberForm.billingGroup || null,
              // Leer heisst KEIN eigener Beitrag, nicht null Franken. Mit
              // einer 0 wuerde aus dem Leeren eine Beitragsbefreiung, und
              // das Mitglied bekaeme nie wieder eine Rechnung.
              customAnnualFee:
                memberForm.customAnnualFee === '' || memberForm.customAnnualFee === undefined
                  || memberForm.customAnnualFee === null
                  ? null : Number(memberForm.customAnnualFee),
          } as any);
          setSelectedMember({ ...(selectedMember as any), ...memberForm });
          showAlert({ type: 'success', message: t('steward.saved') });
      } catch (e: any) {
          showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
      } finally {
          setMemberSaving(false);
      }
  };

  // Welche Rechnung gerade gebucht wird, und mit welchem Betrag.
  //
  // Vorher war das ein einziger Klick, der immer den Rechnungsbetrag
  // buchte. Das ist der haeufige Fall, aber nicht der einzige: es kommt
  // vor, dass jemand mehr oder weniger gibt, und dann stand im Journal
  // trotzdem der verrechnete Betrag -- die Kasse stimmte nicht.
  // Erfassen von Mitglied und Rechnung. Gemessen: der Server erlaubt dem
  // Vorstand beides, nur /admin wies ihn ab (isAdmin kennt nur ADMIN und
  // SUPER_ADMIN). Statt den ganzen Adminbereich zu oeffnen -- dort stehen
  // Domain, Module und die Rollenvergabe -- zwei Formulare an der Stelle,
  // an der er ohnehin arbeitet.
  const [wizard, setWizard] = React.useState(false);
  const [postausgang, setPostausgang] = useState(false);

  const [buchung, setBuchung] = React.useState<Payment | null>(null);
  const [buchBetrag, setBuchBetrag] = React.useState('');
  const [buchArt, setBuchArt] = React.useState('BANK_TRANSFER');
  const [buchLaeuft, setBuchLaeuft] = React.useState(false);
  // Entstandener Mehrbetrag, ueber den noch zu entscheiden ist. Solange
  // er gesetzt ist, bleibt das Fenster offen -- die Entscheidung in eine
  // andere Maske zu verschieben hiesse, dass sie niemand trifft.
  const [mehrbetrag, setMehrbetrag] = React.useState<{ id: string; betrag: number } | null>(null);

  const offenerRest = (z: Payment) =>
    Math.max(0, Number(z.amount ?? 0) - Number((z as any).bezahlt ?? 0));

  // Eine Zahlung buchen. Der Stand wird serverseitig gesetzt -- dort haengt
  // auch die Erledigung einer offenen Meldung daran.
  // Das Fenster oeffnen, mit dem offenen Rest vorbelegt. Bei einer
  // Rechnung ohne Eingaenge ist das genau der Rechnungsbetrag -- der
  // haeufige Fall bleibt also ein Bestaetigen.
  const handleMarkPaid = (zahlung: Payment) => {
      setBuchung(zahlung);
      setBuchBetrag(String(offenerRest(zahlung) || zahlung.amount || ''));
      setBuchArt(zahlung.method || 'BANK_TRANSFER');
  };

  const buchen = async () => {
      if (!buchung) return;
      const betrag = Number(String(buchBetrag).replace(',', '.'));
      if (!Number.isFinite(betrag) || betrag <= 0) {
          showAlert({ type: 'error', message: t('board.amount_invalid') });
          return;
      }
      setBuchLaeuft(true);
      try {
          await markPaymentPaid(buchung.id, buchArt,
              new Date().toISOString().slice(0, 10), betrag);
          const d = betrag - Number(buchung.amount ?? 0) + Number((buchung as any).bezahlt ?? 0);
          showAlert({
              type: 'success',
              // Die Meldung sagt, was daraus folgt. "Gebucht" allein
              // liesse offen, ob die Rechnung damit erledigt ist -- und
              // bei einer Teilzahlung ist sie es nicht.
              message: d === 0 ? t('board.marked_paid')
                : d > 0 ? t('board.booked_more', { betrag: d.toFixed(2) })
                : t('board.booked_less', { betrag: Math.abs(d).toFixed(2) }),
          });
          if (d > 0) setMehrbetrag({ id: buchung.id, betrag: d });
          else setBuchung(null);
      } catch (e: any) {
          showAlert({ type: 'error', message: e?.message || '?' });
      } finally {
          setBuchLaeuft(false);
      }
  };

  // Was mit dem Mehrbetrag geschieht. Die Software entscheidet das
  // nicht: ob ein Mitglied 5 Franken gespendet oder eine Anzahlung
  // fuers naechste Jahr geleistet hat, weiss nur der Verein. Zu raten
  // hiesse, ihm eine Buchung unterzuschieben.
  const mehrbetragDeuten = async (art: 'SPENDE' | 'GUTHABEN' | 'OFFEN') => {
      if (!mehrbetrag) return;
      setBuchLaeuft(true);
      try {
          if (art !== 'OFFEN') await zahlungDifferenzSetzen(mehrbetrag.id, art);
          showAlert({
              type: 'success',
              message: art === 'SPENDE' ? t('board.surplus_donation')
                : art === 'GUTHABEN' ? t('board.surplus_credit')
                : t('board.surplus_later'),
          });
          setMehrbetrag(null); setBuchung(null);
      } catch (e: any) {
          showAlert({ type: 'error', message: e?.message || '?' });
      } finally {
          setBuchLaeuft(false);
      }
  };

  // Die Liste im Rechnungsfenster, nach Name, Rechnungsnummer oder Beschreibung.
  const rechnungenImFenster = useMemo(() => {
      const liste = showInvoiceListModal === 'PAID' ? stats.paidInvoices : stats.openInvoices;
      const suche = rechnungsSuche.toLowerCase().trim();
      if (!suche) return liste;
      return liste.filter((inv: Payment) => {
          const u = users.find(user => user.id === inv.userId);
          return (u?.displayName || '').toLowerCase().includes(suche)
              || (u?.email || '').toLowerCase().includes(suche)
              || (inv.invoiceNumber || '').toLowerCase().includes(suche)
              || (inv.description || '').toLowerCase().includes(suche);
      });
  }, [showInvoiceListModal, stats, rechnungsSuche, users]);

  const nachbarschaftenGefiltert = useMemo(() => {
      const suche = nbSuche.toLowerCase().trim();
      if (!suche) return neighborhoodAnalytics.alle;
      return neighborhoodAnalytics.alle.filter((n: any) =>
          n.name.toLowerCase().includes(suche) || (n.city || '').toLowerCase().includes(suche));
  }, [neighborhoodAnalytics, nbSuche]);

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
                    <Briefcase size={12} /> {t('board.title')}
                </div>
                <h1 className="text-4xl font-display font-bold italic text-stone-900 mb-2">
                    {t('dash.welcome')}, {user.displayName}
                </h1>
                <p className="text-stone-500">{t('board.subtitle')}</p>
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
                        {vereinsjahre.jahre.map(y => (
                            <option key={y} value={y}>{y}</option>
                        ))}
                    </select>
                </div>

                {/* Erfassen. Steht neben dem Profilknopf, weil der Vorstand
                    hier arbeitet -- der Adminbereich ist fuer ihn gesperrt,
                    und das ist richtig: dort stehen Domain, Module und die
                    Rollenvergabe. */}
                <button
                    onClick={() => setWizard(true)}
                    className="px-4 py-3 bg-stone-900 text-white rounded-2xl shadow-sm hover:bg-stone-800 transition-colors flex items-center gap-2 font-bold text-xs"
                >
                    <Plus size={16}/> <span className="hidden sm:inline">Erfassen</span>
                </button>

                {/* Schreiben. Steht neben dem Erfassen, weil es dieselbe
                    Arbeit ist: der Vorstand kuemmert sich um Mitglieder.
                    Bisher nahm dafuer jeder sein privates Postfach -- und
                    damit stand seine private Adresse in der Nachricht und
                    die Antwort ging dorthin. */}
                <button
                    onClick={() => setPostausgang(true)}
                    className="px-4 py-3 bg-white border border-stone-100 text-stone-700 rounded-2xl shadow-sm hover:border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)] hover:text-primary transition-colors flex items-center gap-2 font-bold text-xs"
                >
                    <Mail size={16}/> <span className="hidden sm:inline">{t('vpost.knopf')}</span>
                </button>

                <button 
                    onClick={handleOpenProfile}
                    className="p-3 bg-white rounded-2xl shadow-sm border border-stone-100 hover:border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)] transition-colors group"
                    title={t('profile.edit')}
                >
                    <UserCog size={20} className="text-stone-400 group-hover:text-primary"/>
                </button>
            </div>
        </div>


        {/* Anfragen & Feedback zuerst: das ist, was nach der Anmeldung zu
            tun ist. Kennzahlen und Auswertungen folgen darunter. */}
        <div className="mb-10">
            <AnfragenBearbeiten breit />
        </div>
        <div className="mb-10">
            <AenderungenVerwaltung kompakt />
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
                    <span className="text-sm font-bold text-emerald-600/60 mb-1">{t('board.invoices')}</span>
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
                    <span className="text-sm font-bold text-amber-600/60 mb-1">{t('board.invoices')}</span>
                </div>
                <p className="text-amber-700/60 text-sm mt-1 font-mono">{stats.openRevenue.toLocaleString()} CHF</p>
            </motion.div>

            {/* 3. Nachbarschaften (anklickbar) */}
            <motion.div
                whileHover={{ y: -5 }}
                onClick={() => setZeigeNachbarschaften(true)}
                className="bg-stone-900 text-white p-6 rounded-3xl cursor-pointer shadow-sm hover:shadow-md transition-all group"
            >
                <div className="flex justify-between items-start mb-2">
                    <p className="text-stone-400 font-bold text-xs uppercase tracking-widest">{t('admin.tab.neighborhoods')}</p>
                    <div className="bg-white/10 p-2 rounded-full opacity-50 group-hover:opacity-100 transition-opacity">
                        <MapPin size={16} className="text-white"/>
                    </div>
                </div>
                <div className="flex items-end gap-2">
                    <h3 className="text-3xl font-display font-bold">{neighborhoodAnalytics.alle.length}</h3>
                    <span className="text-sm font-bold text-stone-400 mb-1">{t('board.with_rate')}</span>
                </div>
                <p className="text-stone-400 text-sm mt-1">
                    {t('board.avg_rate')}: {
                        Math.round(
                            neighborhoodAnalytics.alle.reduce((a: number, n: any) => a + n.mitglieder, 0) > 0
                            ? neighborhoodAnalytics.alle.reduce((a: number, n: any) => a + n.zahlende, 0) * 100
                              / neighborhoodAnalytics.alle.reduce((a: number, n: any) => a + n.mitglieder, 0)
                            : 0
                        )
                    }%
                </p>
            </motion.div>

            {/* 4. Search Bar */}
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm flex flex-col">
                <div className="flex items-center gap-2 mb-4">
                    <Search size={18} className="text-stone-400"/>
                    <input 
                        type="text" 
                        placeholder={t('board.search_member')} 
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
                                onClick={() => { setSelectedMember(u); setMemberForm({ ...u }); }}
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
                            <p className="text-stone-400 text-xs italic">{t('board.no_results')}</p>
                        )}
                    </div>
                ) : (
                    <div className="flex-1 flex items-center justify-center text-stone-300 text-sm italic">
                        <p>{t('board.search_hint')}</p>
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
                        <span className="text-[10px] text-stone-400 font-bold uppercase">{t('board.paid')}</span>
                    </div>
                </div>
            </div>

            {/* Top 5 Neighborhoods */}
            <div className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="flex items-center gap-2 mb-6">
                    <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg"><TrendingUp size={16}/></div>
                    <h4 className="font-bold text-stone-900 text-sm">{t('board.top_neighborhoods')}</h4>
                </div>
                <div className="h-48 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={neighborhoodAnalytics.top5} layout="vertical" margin={{ left: 0, right: 30 }}>
                            <CartesianGrid horizontal={false} stroke="#f5f5f4" />
                            <XAxis type="number" domain={[0, 100]} unit="%" tick={{ fontSize: 9 }} />
                            <YAxis dataKey="name" type="category" width={80} tick={{fontSize: 10}} interval={0} />
                            <Tooltip cursor={{fill: '#f5f5f4'}} content={<NachbarschaftsHinweis />} />
                            <Bar dataKey="quote" fill="#10b981" radius={[0, 4, 4, 0]} barSize={16}
                                 label={{ position: 'right', fontSize: 9, fill: '#78716c',
                                          formatter: (v: any) => `${v}%` }} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
                {/* Ohne diesen Hinweis wirkt eine fehlende Nachbarschaft wie ein Fehler. */}
                {neighborhoodAnalytics.zuKlein > 0 && (
                    <p className="text-[10px] text-stone-400 mt-3 leading-relaxed">
                        {t('board.min_size_hint', {
                            count: neighborhoodAnalytics.zuKlein,
                            min: neighborhoodAnalytics.mindest,
                        })}
                    </p>
                )}
            </div>

            {/* Bottom 5 Neighborhoods */}
            <div className="bg-white p-6 rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="flex items-center gap-2 mb-6">
                    <div className="p-2 bg-rose-50 text-rose-600 rounded-lg"><TrendingDown size={16}/></div>
                    <h4 className="font-bold text-stone-900 text-sm">{t('board.lowest_contributions')}</h4>
                </div>
                <div className="h-48 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={neighborhoodAnalytics.bottom5} layout="vertical" margin={{ left: 0, right: 30 }}>
                            <CartesianGrid horizontal={false} stroke="#f5f5f4" />
                            <XAxis type="number" domain={[0, 100]} unit="%" tick={{ fontSize: 9 }} />
                            <YAxis dataKey="name" type="category" width={80} tick={{fontSize: 10}} interval={0} />
                            <Tooltip cursor={{fill: '#f5f5f4'}} content={<NachbarschaftsHinweis />} />
                            <Bar dataKey="quote" fill="#fb7185" radius={[0, 4, 4, 0]} barSize={16}
                                 label={{ position: 'right', fontSize: 9, fill: '#78716c',
                                          formatter: (v: any) => `${v}%` }} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
                {/* Ohne diesen Hinweis wirkt eine fehlende Nachbarschaft wie ein Fehler. */}
                {neighborhoodAnalytics.zuKlein > 0 && (
                    <p className="text-[10px] text-stone-400 mt-3 leading-relaxed">
                        {t('board.min_size_hint', {
                            count: neighborhoodAnalytics.zuKlein,
                            min: neighborhoodAnalytics.mindest,
                        })}
                    </p>
                )}
            </div>

        </div>

        {/* Protokolle */}
        <div className="grid grid-cols-1 gap-8">

            {/* Protocols */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm h-[600px] flex flex-col">
                <div className="flex items-center justify-between mb-6">
                    <h3 className="text-xl font-bold flex items-center gap-2"><FileText size={20} className="text-primary"/> {t('board.minutes')}</h3>
                    <button onClick={() => { setEditMeeting(null); setEditorOffen(true); }}
                        className="px-4 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-stone-700 transition-colors">
                        <Plus size={13}/> {t('minutes.new')}
                    </button>
                </div>
                
                <div className="overflow-y-auto custom-scrollbar flex-1 space-y-3">
                    {meetings.map(m => (
                        <div key={m.id} className="p-4 rounded-2xl border border-stone-100 hover:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)] hover:shadow-md transition-all group">
                            <div className="flex justify-between items-start mb-2 gap-2">
                                <h4 onClick={() => setSelectedMeeting(m)} className="font-bold text-stone-800 group-hover:text-primary transition-colors cursor-pointer flex-1">{m.title}</h4>
                                <div className="flex items-center gap-1.5 shrink-0">
                                    {((m as any).version ?? 1) > 1 && (
                                        <span className="text-[9px] font-bold bg-amber-100 text-amber-700 px-1.5 py-1 rounded" title={t('minutes.revised')}>
                                            v{(m as any).version}
                                        </span>
                                    )}
                                    <span className="text-[10px] font-bold bg-stone-100 px-2 py-1 rounded text-stone-500">{new Date(m.date).toLocaleDateString()}</span>
                                    <button onClick={(e) => { e.stopPropagation(); setEditMeeting(m); setEditorOffen(true); }}
                                        title={t('minutes.edit')}
                                        className="p-1.5 text-stone-400 hover:text-primary bg-white border border-stone-200 rounded-lg">
                                        <FileEdit size={13}/>
                                    </button>
                                </div>
                            </div>
                            <div className="text-xs text-stone-500 line-clamp-2">
                                {m.agendaItems?.map((item, i) => `${i+1}. ${item.title}`).join(', ')}
                            </div>
                        </div>
                    ))}
                    {meetings.length === 0 && <p className="text-stone-400 italic text-center py-10">{t('board.no_minutes')}</p>}
                </div>
            </div>

        </div>

        {/* Nachbarschaften verwalten. Der Vorstand gehoert laut Datenbank zur
            Verwaltung (is_member_manager) -- die Masken dafuer lagen aber nur
            unter /admin, wohin er nicht kommt. Dieselben Masken hier. */}
        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
            <div className="flex items-center justify-between gap-4 flex-wrap mb-6">
                <h3 className="text-xl font-bold flex items-center gap-2"><MapPin size={20} className="text-primary"/> {t('board.nb_verwalten')}</h3>
                <button onClick={() => setNbBearbeiten({ name: '', status: 'ACTIVE' } as any)}
                    className="px-4 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-stone-700">
                    <Plus size={13}/> {t('admin.nb.new')}
                </button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {neighborhoods.map(n => (
                    <div key={n.id} className="p-5 rounded-2xl border border-stone-100">
                        <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0">
                                <p className="font-bold text-stone-900 truncate">{n.name}</p>
                                <p className="text-[11px] text-stone-400 mt-0.5">
                                    {users.filter(u => u.neighborhoodId === n.id).length} {t('nb.mitglieder')}
                                </p>
                            </div>
                            <button onClick={() => setNbBearbeiten(n)} title={t('common.edit')}
                                className="p-2 text-stone-400 hover:text-stone-900 bg-white border border-stone-200 rounded-lg shrink-0">
                                <FileEdit size={14}/>
                            </button>
                        </div>
                        <NbWebsiteLeiste nb={{ id: n.id, name: n.name }} darfBilder />
                    </div>
                ))}
                {neighborhoods.length === 0 && <p className="text-stone-400 italic">{t('board.no_entries')}</p>}
            </div>
        </div>
        {nbBearbeiten && (
            <AdminNeighborhoodEditor
                neighborhood={nbBearbeiten}
                users={users}
                memberCount={users.filter(u => u.neighborhoodId === nbBearbeiten.id).length}
                onClose={() => setNbBearbeiten(null)}
            />
        )}

        {/* Neuigkeiten. Der Vorstand durfte sie laut Datenbank schon immer
            schreiben, hatte aber keine Maske: die liegt unter /admin, und
            von dort leitet die App den Vorstand hierher. */}
        {modulAktiv('NEUIGKEITEN') && <NachrichtenVerwaltung karte />}

        {/* MODALS */}

        {/* 1. MEMBER DETAIL MODAL */}
        <AnimatePresence>
            {selectedMember && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-lg rounded-[2.5rem] p-8 shadow-2xl relative">
                        <button onClick={() => { setSelectedMember(null); setMemberForm(null); }} className="absolute top-6 right-6 p-2 bg-stone-50 rounded-full hover:bg-stone-100 text-stone-500"><X size={20}/></button>
                        
                        <div className="flex flex-col items-center mb-6">
                            <div className="w-24 h-24 bg-stone-100 rounded-full flex items-center justify-center text-3xl font-bold text-stone-400 mb-4 overflow-hidden border-4 border-white shadow-md">
                                {selectedMember.photoFileName ? <img src={selectedMember.photoFileName} className="w-full h-full object-cover" onError={onImageError}/> : selectedMember.displayName?.charAt(0)}
                            </div>
                            <h3 className="text-2xl font-bold text-stone-900">{selectedMember.displayName}</h3>
                            <span className={`text-xs font-bold px-3 py-1 rounded-full mt-2 ${selectedMember.membershipStatus === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-stone-100 text-stone-500'}`}>
                                {selectedMember.membershipStatus}
                            </span>
                        </div>

                        {/* Fehlendes benennen, statt es nur wegzulassen: sonst faellt
                            eine Luecke erst auf, wenn eine Rechnung nicht ankommt. */}
                        {missingFieldKeys(selectedMember, { selfServiceOnly: true }).length > 0 && (
                            <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-700">
                                <b>{t('steward.data_missing')}:</b>{' '}
                                {missingFieldKeys(selectedMember, { selfServiceOnly: true }).map(k => t(k)).join(', ')}
                            </div>
                        )}

                        <div className="space-y-3 bg-stone-50 p-6 rounded-2xl border border-stone-100 max-h-[42vh] overflow-y-auto custom-scrollbar">
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.email')}</label>
                                <input value={memberForm?.email ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), email: e.target.value })}
                                    className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.phone')}</label>
                                    <input value={memberForm?.phone ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), phone: e.target.value })}
                                        className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.birthdate')}</label>
                                    <input type="date" value={memberForm?.birthdate ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), birthdate: e.target.value })}
                                        className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('admin.members.street_no')}</label>
                                <input value={memberForm?.street ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), street: e.target.value })}
                                    className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                            </div>
                            <div className="grid grid-cols-3 gap-3">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.zip')}</label>
                                    <input value={memberForm?.zip ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), zip: e.target.value })}
                                        className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                                </div>
                                <div className="col-span-2">
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.city')}</label>
                                    <input value={memberForm?.city ?? ''} onChange={e => setMemberForm({ ...(memberForm || {}), city: e.target.value })}
                                        className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">{t('field.country')}</label>
                                <CountrySelect value={memberForm?.country} onChange={v => setMemberForm({ ...(memberForm || {}), country: v })}
                                    className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]"/>
                            </div>

                            {/* Beitrag. Steht unten und abgesetzt, weil es die
                                einzige Angabe hier ist, die Geld bewegt. */}
                            <div className="p-4 bg-stone-900 rounded-xl space-y-3">
                                <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                                    {t('board.fee_title')}
                                </p>

                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 uppercase tracking-widest block mb-1">
                                        {t('board.fee_group')}
                                    </label>
                                    <select value={memberForm?.billingGroup ?? ''}
                                        onChange={e => setMemberForm({ ...(memberForm || {}), billingGroup: e.target.value })}
                                        className="w-full p-3 bg-white/5 border border-white/10 rounded-xl outline-none text-sm text-white">
                                        <option value="" className="text-stone-900">{t('board.fee_group_none')}</option>
                                        {Object.entries((saetze?.fees ?? {}) as Record<string, any>)
                                          .map(([k, v]) => (
                                            <option key={k} value={k} className="text-stone-900">
                                                {k} — {v?.amount} {v?.currency || ''}
                                            </option>
                                          ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="text-[10px] font-bold text-stone-500 uppercase tracking-widest block mb-1">
                                        {t('board.fee_own')}
                                    </label>
                                    <div className="relative">
                                        <input type="number" step="0.05" min="0"
                                            value={memberForm?.customAnnualFee ?? ''}
                                            onChange={e => setMemberForm({ ...(memberForm || {}), customAnnualFee: e.target.value })}
                                            placeholder={t('board.fee_own_ph')}
                                            className="w-full p-3 pr-14 bg-white/5 border border-white/10 rounded-xl outline-none text-sm font-mono font-bold text-white placeholder:text-stone-600"/>
                                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-[10px] font-bold text-stone-500">
                                            {beitragFuer(memberForm, saetze).waehrung}
                                        </span>
                                    </div>
                                </div>

                                {/* Was gilt, und wovon es abweicht. Ohne diesen
                                    Satz ist eine Zahl im Feld nicht einzuordnen. */}
                                {(() => {
                                  const b = beitragFuer(memberForm, saetze);
                                  return (
                                    <p className="text-[11px] text-stone-400 leading-relaxed">
                                      {b.quelle === 'EIGEN'
                                        ? t('board.fee_own_hint', {
                                            betrag: `${b.waehrung} ${b.betrag.toFixed(2)}`,
                                            sonst: `${b.waehrung} ${b.ohne_eigenen.toFixed(2)}` })
                                        : t('board.fee_group_hint', {
                                            betrag: `${b.waehrung} ${b.betrag.toFixed(2)}` })}
                                      {b.quelle === 'RUECKFALL' && ' ' + t('board.fee_no_rates')}
                                    </p>
                                  );
                                })()}
                            </div>
                        </div>

                        <button onClick={handleSaveMember} disabled={memberSaving}
                            className="w-full mt-4 py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
                            {memberSaving ? <Loader2 size={16} className="animate-spin"/> : <Save size={16}/>} {t('common.save_changes')}
                        </button>
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
                                {showInvoiceListModal === 'PAID' ? t('board.paid_invoices') : t('board.open_invoices')} ({selectedYear})
                            </h3>
                            <button onClick={() => { setShowInvoiceListModal(null); setRechnungsSuche(''); }} className="p-2 bg-white/50 rounded-full hover:bg-white transition-colors"><X size={20}/></button>
                        </div>

                        <div className="px-6 pt-5">
                            <div className="relative">
                                <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-stone-400"/>
                                <input autoFocus value={rechnungsSuche} onChange={e => setRechnungsSuche(e.target.value)}
                                    placeholder={t('board.search_invoice')}
                                    className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]"/>
                            </div>
                            {rechnungsSuche && (
                                <p className="text-[11px] text-stone-400 mt-2">
                                    {t('board.search_result', { found: rechnungenImFenster.length,
                                        total: (showInvoiceListModal === 'PAID' ? stats.paidInvoices : stats.openInvoices).length })}
                                </p>
                            )}
                        </div>

                        <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
                            <table className="w-full text-left text-sm">
                                <thead className="text-xs font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                    <tr>
                                        <th className="pb-3">{t('field.member')}</th>
                                        <th className="pb-3">{t('field.date')}</th>
                                        <th className="pb-3 text-right">{t('field.amount')}</th>
                                        {showInvoiceListModal === 'OPEN' && <th className="pb-3 text-right">{t('board.action')}</th>}
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-stone-50">
                                    {rechnungenImFenster.map(inv => {
                                        const u = users.find(user => user.id === inv.userId);
                                        return (
                                            <tr key={inv.id} className="hover:bg-stone-50">
                                                <td className="py-3">
                                                    <p className="font-bold text-stone-800">{u?.displayName || 'Unknown'}</p>
                                                    <p className="text-[10px] text-stone-400 font-mono">{inv.invoiceNumber}</p>
                                                </td>
                                                <td className="py-3 text-stone-500 font-mono text-xs">{new Date(inv.timestamp?.toDate()).toLocaleDateString()}</td>
                                                <td className="py-3 text-right font-mono font-bold">
                                                    {inv.amount} {inv.currency}
                                                    {/* Angezahlt: vorher sah eine halb bezahlte
                                                        Rechnung wie eine unbezahlte aus. */}
                                                    {Number((inv as any).bezahlt ?? 0) > 0 &&
                                                     Number((inv as any).bezahlt) !== Number(inv.amount) && (
                                                        <span className={`block text-[10px] font-bold ${
                                                            Number((inv as any).bezahlt) > Number(inv.amount)
                                                                ? 'text-sky-700' : 'text-amber-700'}`}>
                                                            {Number((inv as any).bezahlt).toFixed(2)} erhalten
                                                        </span>
                                                    )}
                                                </td>
                                                {showInvoiceListModal === 'OPEN' && (
                                                    <td className="py-3 text-right">
                                                        <button onClick={() => handleMarkPaid(inv)}
                                                            className="px-3 py-1.5 bg-emerald-600 text-white rounded-lg font-bold text-[11px] hover:bg-emerald-700 transition-colors">
                                                            {t('board.mark_paid')}
                                                        </button>
                                                    </td>
                                                )}
                                            </tr>
                                        )
                                    })}
                                    {rechnungenImFenster.length === 0 && (
                                        <tr><td colSpan={showInvoiceListModal === 'OPEN' ? 4 : 3} className="text-center py-8 text-stone-400 italic">{t('board.no_entries')}</td></tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        {/* Uebersicht aller Nachbarschaften */}
        <AnimatePresence>
            {zeigeNachbarschaften && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}}
                        className="bg-white w-full max-w-3xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
                        <div className="p-6 flex justify-between items-center bg-stone-900 text-white">
                            <h3 className="font-bold text-lg flex items-center gap-2">
                                <MapPin size={20}/> {t('admin.tab.neighborhoods')} ({selectedYear})
                            </h3>
                            <button onClick={() => { setZeigeNachbarschaften(false); setNbSuche(''); }}
                                className="p-2 bg-white/10 rounded-full hover:bg-white/20 transition-colors"><X size={20}/></button>
                        </div>

                        <div className="px-6 pt-5">
                            <div className="relative">
                                <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-stone-400"/>
                                <input autoFocus value={nbSuche} onChange={e => setNbSuche(e.target.value)}
                                    placeholder={t('board.search_neighborhood')}
                                    className="w-full pl-10 pr-4 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]"/>
                            </div>
                        </div>

                        <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
                            <table className="w-full text-left text-sm">
                                <thead className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                                    <tr>
                                        <th className="pb-3">{t('admin.tab.neighborhoods')}</th>
                                        <th className="pb-3 text-right">{t('steward.members')}</th>
                                        <th className="pb-3 text-right">{t('board.paid')}</th>
                                        <th className="pb-3 text-right">{t('status.pending')}</th>
                                        <th className="pb-3 text-right">{t('board.rate')}</th>
                                        <th className="pb-3 text-right">CHF</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-stone-50">
                                    {nachbarschaftenGefiltert.map((n: any) => (
                                        <tr key={n.name} className="hover:bg-stone-50">
                                            <td className="py-3">
                                                <p className="font-bold text-stone-800">{n.name}</p>
                                                {n.city && <p className="text-[10px] text-stone-400">{n.city}</p>}
                                            </td>
                                            <td className="py-3 text-right text-stone-600 tabular-nums">{n.mitglieder}</td>
                                            <td className="py-3 text-right text-emerald-700 font-bold tabular-nums">{n.zahlende}</td>
                                            <td className="py-3 text-right text-amber-700 font-bold tabular-nums">
                                                {n.mitglieder - n.zahlende}
                                            </td>
                                            <td className="py-3 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    <span className="text-xs font-bold tabular-nums w-9 text-right">{n.quote}%</span>
                                                    {/* Der Balken macht den Vergleich auf einen Blick moeglich;
                                                        die Zahl daneben bleibt ablesbar. */}
                                                    <div className="w-14 h-1.5 bg-stone-100 rounded-full overflow-hidden shrink-0">
                                                        <div className={`h-full rounded-full ${
                                                            n.quote >= 50 ? 'bg-emerald-500' : n.quote >= 25 ? 'bg-amber-500' : 'bg-rose-400'}`}
                                                            style={{ width: `${Math.min(100, n.quote)}%` }}/>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="py-3 text-right font-mono text-xs tabular-nums">
                                                {n.chf.toLocaleString('de-CH')}
                                            </td>
                                        </tr>
                                    ))}
                                    {nachbarschaftenGefiltert.length === 0 && (
                                        <tr><td colSpan={6} className="text-center py-8 text-stone-400 italic">{t('board.no_entries')}</td></tr>
                                    )}
                                </tbody>
                                <tfoot className="border-t-2 border-stone-200">
                                    <tr className="font-bold text-stone-900">
                                        <td className="pt-3">{t('status.all')}</td>
                                        <td className="pt-3 text-right tabular-nums">
                                            {nachbarschaftenGefiltert.reduce((a: number, n: any) => a + n.mitglieder, 0)}
                                        </td>
                                        <td className="pt-3 text-right tabular-nums text-emerald-700">
                                            {nachbarschaftenGefiltert.reduce((a: number, n: any) => a + n.zahlende, 0)}
                                        </td>
                                        <td className="pt-3 text-right tabular-nums text-amber-700">
                                            {nachbarschaftenGefiltert.reduce((a: number, n: any) => a + (n.mitglieder - n.zahlende), 0)}
                                        </td>
                                        <td className="pt-3 text-right tabular-nums">
                                            {(() => {
                                                const m = nachbarschaftenGefiltert.reduce((a: number, n: any) => a + n.mitglieder, 0);
                                                const z = nachbarschaftenGefiltert.reduce((a: number, n: any) => a + n.zahlende, 0);
                                                return m > 0 ? `${Math.round(z * 100 / m)}%` : '-';
                                            })()}
                                        </td>
                                        <td className="pt-3 text-right font-mono text-xs tabular-nums">
                                            {nachbarschaftenGefiltert.reduce((a: number, n: any) => a + n.chf, 0).toLocaleString('de-CH')}
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>

        <BoardMinutesEditor
            meeting={editMeeting}
            open={editorOffen}
            boardUsers={users.filter(u => ['BOARD','ADMIN','SUPER_ADMIN'].includes(u.role || ''))}
            onClose={() => { setEditorOffen(false); setEditMeeting(null); }}
        />

        {/* 3. PROTOCOL MODAL (READ ONLY) */}
        <AnimatePresence>
            {selectedMeeting && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                    <motion.div initial={{scale:0.95, opacity:0}} animate={{scale:1, opacity:1}} exit={{scale:0.95, opacity:0}} className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
                        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                            <div>
                                <h3 className="font-bold text-lg text-stone-900">{selectedMeeting.title}</h3>
                                <p className="text-xs text-stone-500">
                                    {new Date(selectedMeeting.date).toLocaleDateString()}
                                    {(selectedMeeting as any).location ? ` · ${(selectedMeeting as any).location}` : ''}
                                    {(selectedMeeting as any).protokollfuehrer?.name ? ` · ${t('minutes.minute_taker')}: ${(selectedMeeting as any).protokollfuehrer.name}` : ''}
                                </p>
                            </div>
                            <button onClick={() => setSelectedMeeting(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors"><X size={20}/></button>
                        </div>
                        {/* Weitergeben: PDF, WhatsApp, E-Mail */}
                        <div className="px-6 py-3 border-b border-stone-100">
                            <ProtokollTeilen meeting={selectedMeeting}
                                boardUsers={users.filter(u => ['BOARD','ADMIN','SUPER_ADMIN'].includes(u.role || ''))} />
                        </div>
                        <div className="p-8 overflow-y-auto custom-scrollbar flex-1 space-y-8">
                            <div>
                                <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-3 border-b border-stone-100 pb-2">{t('board.attendees')}</h4>
                                <div className="flex flex-wrap gap-2">
                                    {selectedMeeting.attendees?.map((att, i) => (
                                        <div key={i} className={`text-xs px-3 py-1.5 rounded-lg border ${(att as any).guest ? 'bg-violet-50 border-violet-100 text-violet-800' : att.present ? 'bg-white border-stone-200 text-stone-800' : 'bg-stone-50 border-stone-100 text-stone-400 line-through'}`}>
                                            {att.name}{(att as any).guest ? ` · ${t('minutes.guest')}` : ''}
                                        </div>
                                    ))}
                                </div>
                            </div>
                            <div>
                                <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">{t('board.agenda')}</h4>
                                <div className="space-y-6">
                                    {selectedMeeting.agendaItems?.map((item, i) => (
                                        <div key={i}>
                                            <h5 className="font-bold text-stone-900 text-sm flex items-center gap-2 mb-2">
                                                <span className="bg-stone-100 w-5 h-5 flex items-center justify-center rounded-full text-[10px]">{i+1}</span> 
                                                {item.title}
                                            </h5>
                                            {/* Als Text, nicht als HTML: der Editor speichert Klartext,
                                                und eingeschleustes HTML gehoert nicht in die Ansicht. */}
                                            <p className="pl-7 text-sm text-stone-600 leading-relaxed whitespace-pre-wrap">{String(item.content || '').replace(/<[^>]*>/g, '')}</p>
                                        </div>
                                    ))}
                                </div>
                            </div>
                            {((selectedMeeting as any).decisions || []).length > 0 && (
                                <div>
                                    <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 border-b border-stone-100 pb-2">{t('minutes.decisions')}</h4>
                                    <div className="space-y-4">
                                        {((selectedMeeting as any).decisions || []).map((d: any, i: number) => (
                                            <div key={i}>
                                                <h5 className="font-bold text-stone-900 text-sm">{i + 1}. {d.title}</h5>
                                                {d.content && <p className="text-sm text-stone-600 whitespace-pre-wrap mt-1">{d.content}</p>}
                                                {(d.responsible || d.dueDate) && (
                                                    <p className="text-[11px] text-stone-400 mt-1">{[d.responsible && `${t('minutes.responsible')}: ${d.responsible}`, d.dueDate && new Date(d.dueDate).toLocaleDateString()].filter(Boolean).join(' · ')}</p>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
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

        {wizard && (
          <VorstandWizard
            mitglieder={users}
            nachbarschaften={neighborhoods}
            onClose={() => setWizard(false)}
          />
        )}

        {postausgang && (
          <VorstandPostausgang
            mitglieder={users}
            nachbarschaften={neighborhoods}
            onClose={() => setPostausgang(false)}
          />
        )}

        {/* Eine Zahlung buchen.
            Mit Betrag, weil er abweichen kann. Steht hier als eigenes
            Fenster und nicht als Bestaetigungsdialog: in eine
            Bestaetigung laesst sich nichts eintippen, und genau das war
            der Grund, dass bisher immer der Rechnungsbetrag gebucht
            wurde. */}
        <AnimatePresence>
        {buchung && (
          <div className="fixed inset-0 z-[500] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
            <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.96, opacity: 0 }}
              className="bg-white w-full max-w-md rounded-[2rem] shadow-2xl overflow-hidden">
              <div className="p-6 border-b border-stone-100 bg-stone-50 flex justify-between items-center">
                <div>
                  <h3 className="font-bold text-lg text-stone-900">{t('board.mark_paid')}</h3>
                  <p className="text-xs text-stone-500 mt-0.5">
                    {users.find(u => u.id === buchung.userId)?.displayName || '-'}
                    {buchung.invoiceNumber ? ` · ${buchung.invoiceNumber}` : ''}
                  </p>
                </div>
                <button onClick={() => setBuchung(null)}
                  className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={18} /></button>
              </div>

              {mehrbetrag ? (
                <>
                  <div className="p-8 space-y-4">
                    <div className="p-4 bg-sky-50 border border-sky-200 rounded-xl">
                      <p className="text-xs text-sky-900 leading-relaxed">
                        Gebucht. Es wurden <strong>{mehrbetrag.betrag.toFixed(2)} {buchung.currency || 'CHF'}</strong>{' '}
                        mehr bezahlt als verrechnet. Was soll damit geschehen?
                      </p>
                    </div>
                    <button onClick={() => mehrbetragDeuten('SPENDE')} disabled={buchLaeuft}
                      className="w-full p-4 text-left bg-white border border-stone-200 rounded-xl hover:border-stone-400 transition-colors disabled:opacity-50">
                      <p className="font-bold text-sm text-stone-900">Als Spende verbuchen</p>
                      <p className="text-[11px] text-stone-500 mt-0.5">
                        Geht auf das Spendenkonto und erscheint im Jahresergebnis.
                      </p>
                    </button>
                    <button onClick={() => mehrbetragDeuten('GUTHABEN')} disabled={buchLaeuft}
                      className="w-full p-4 text-left bg-white border border-stone-200 rounded-xl hover:border-stone-400 transition-colors disabled:opacity-50">
                      <p className="font-bold text-sm text-stone-900">Als Guthaben behalten</p>
                      <p className="text-[11px] text-stone-500 mt-0.5">
                        Bleibt eine Verbindlichkeit gegenüber dem Mitglied und kann nächstes Jahr angerechnet werden.
                      </p>
                    </button>
                    <button onClick={() => mehrbetragDeuten('OFFEN')} disabled={buchLaeuft}
                      className="w-full p-3 text-center text-xs font-bold text-stone-400 hover:text-stone-700 transition-colors disabled:opacity-50">
                      Später entscheiden
                    </button>
                  </div>
                </>
              ) : (
              <>
              <div className="p-8 space-y-5">
                <div className="grid grid-cols-2 gap-3 text-center">
                  <div className="p-3 bg-stone-50 rounded-xl">
                    <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">verrechnet</p>
                    <p className="font-mono font-bold text-stone-800 mt-1">
                      {buchung.currency || 'CHF'} {Number(buchung.amount ?? 0).toFixed(2)}
                    </p>
                  </div>
                  <div className="p-3 bg-stone-50 rounded-xl">
                    <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">bisher erhalten</p>
                    <p className="font-mono font-bold text-stone-800 mt-1">
                      {Number((buchung as any).bezahlt ?? 0).toFixed(2)}
                    </p>
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5">
                    {t('board.amount_received')}
                  </label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">
                      {buchung.currency || 'CHF'}
                    </span>
                    <input type="text" inputMode="decimal" value={buchBetrag}
                      onChange={e => setBuchBetrag(e.target.value)}
                      className="w-full p-3 pl-14 bg-white border border-stone-200 rounded-xl outline-none text-sm font-mono font-bold focus:border-stone-400" />
                  </div>
                  {(() => {
                    const b = Number(String(buchBetrag).replace(',', '.'));
                    if (!Number.isFinite(b)) return null;
                    const neu = Number((buchung as any).bezahlt ?? 0) + b;
                    const d = neu - Number(buchung.amount ?? 0);
                    if (d === 0) return (
                      <p className="text-[11px] mt-1.5 font-bold text-emerald-700">
                        Damit ist die Rechnung gedeckt.
                      </p>
                    );
                    return (
                      <p className={`text-[11px] mt-1.5 font-bold ${d > 0 ? 'text-sky-700' : 'text-amber-700'}`}>
                        {d > 0
                          ? `${d.toFixed(2)} mehr als verrechnet — Sie entscheiden anschliessend, was damit geschieht.`
                          : `${Math.abs(d).toFixed(2)} bleiben offen — die Rechnung bleibt mahnbar.`}
                      </p>
                    );
                  })()}
                </div>

                <div>
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5">
                    {t('steward.method')}
                  </label>
                  <select value={buchArt} onChange={e => setBuchArt(e.target.value)}
                    className="w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm">
                    <option value="CASH">{t('steward.method_cash')}</option>
                    <option value="BANK_TRANSFER">{t('steward.method_bank')}</option>
                    <option value="QR_BILL">QR</option>
                    <option value="TWINT">TWINT</option>
                    <option value="PAYPAL">PayPal</option>
                  </select>
                </div>
              </div>

              <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
                <button onClick={() => setBuchung(null)}
                  className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">
                  {t('common.cancel')}
                </button>
                <button onClick={buchen} disabled={buchLaeuft}
                  className="flex-[2] py-3 bg-emerald-600 text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
                  {buchLaeuft ? <Loader2 size={16} className="animate-spin" /> : <CheckCircle2 size={16} />}
                  {t('board.mark_paid')}
                </button>
              </div>
              </>
              )}
            </motion.div>
          </div>
        )}
        </AnimatePresence>

    </div>
  );
};

export default BoardDashboard;
