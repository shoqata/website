
import React, { useState, useEffect } from 'react';
import './lib/design.css';
import { useWerBinIch, type WerBinIch } from './lib/useWerBinIch';
import { useDemoRolle } from './lib/useDemoRolle';
import { usePaket } from './lib/usePaket';
const DemoRollenschalter = React.lazy(() => import('./components/DemoRollenschalter'));
const SpendenSeite = React.lazy(() => import('./components/SpendenSeite'));
// Die sechs Startseiten-Vorlagen. Alle nachgeladen: ein Verein zeigt genau
// eine, und die fuenf anderen gehoeren nicht in sein Bundle. Besonders die
// erzaehlenden -- sie ziehen den scroll-craft-Kern nach sich.
const StartseitePremium = React.lazy(() => import('./components/StartseitePremium'));
const Magazin = React.lazy(() => import('./components/vorlagen/Magazin'));
const Kompakt = React.lazy(() => import('./components/vorlagen/Kompakt'));
const Buehne  = React.lazy(() => import('./components/vorlagen/Buehne'));
const Journal = React.lazy(() => import('./components/vorlagen/Journal'));
const VideoSeite = React.lazy(() => import('./components/VideoSeite'));
const RevisionsSeite = React.lazy(() => import('./components/RevisionsSeite'));
const TreffenGastSeite = React.lazy(() => import('./components/TreffenGastSeite'));
const VorstellungWizard = React.lazy(() => import('./components/VorstellungWizard'));
const HeftSeite = React.lazy(() => import('./components/HeftSeite'));
const TreffenDrucksachen = React.lazy(() => import('./components/TreffenDrucksachen'));
import { needsProfileSetup } from './lib/memberQuality';
import { useIstPlattformDomain } from './lib/useIstPlattformDomain';
import { useStartseitenVorlage } from './lib/useStartseitenVorlage';
import { useOeffentlicheModule } from './lib/useOeffentlicheModule';
import { seitenZustand } from './lib/modulgate';
import { useWerbemessung } from './lib/useWerbemessung';
import { useSpendenseiteSichtbar } from './lib/useSpendenseiteSichtbar';
import { useKopfzeile, navLayout, zeigtOben, zeigtFuss, navGruppen, navBaum } from './components/kopfzeile';
import { KopfGruppe, GruppenTitel } from './components/NavGruppen';
import { useReiterKennzeichen } from './lib/useReiterKennzeichen';
import { HashRouter as Router, Routes, Route, Link, useLocation, Navigate, useSearchParams } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowRight, Building2, Calendar, ChevronDown, Film, Globe, Hammer, Heart, Home, Info, LayoutDashboard, Loader2, LogIn, LogOut, Mail, MapPin, Maximize, Menu, Newspaper, QrCode, Settings, ShieldCheck, Smartphone, Sparkles, Trophy, UserPlus, X, Zap } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

// Supabase Auth (replaces Firebase Auth)
import { 
  auth, 
  db, 
  onAuthStateChanged, 
  signOut,
  claimMyProfile,
  doc, 
  getDoc, 
  onSnapshot, 
  setDoc, 
  updateDoc, 
  collection, 
  query, 
  orderBy, 
  where, 
  getDocs, 
  deleteDoc
} from './services/datenzugriff';


// Context & Hooks
import { LanguageProvider, useTranslation } from './context/LanguageContext';
import { ErrorBoundary } from './components/ErrorBoundary';
import { FeedbackProvider } from './context/FeedbackContext';
import { TenantProvider, useTenant } from './context/TenantContext';
import { aufrufZaehlen, zaehlerStarten } from './lib/zaehler';
import { useSecurity } from './hooks/useSecurity';
import { useAutoLogout } from './hooks/useAutoLogout';

// Components
import Hero from './components/Hero';

// Nur die Startseite wird sofort geladen. Alles andere -- und damit die
// schweren Admin- und Dashboard-Ansichten samt Charts, 3D und PDF-Erzeugung --
// kommt erst, wenn die Route tatsaechlich aufgerufen wird.
const Dashboard = React.lazy(() => import('./components/Dashboard'));
const AdminPanel = React.lazy(() => import('./components/AdminPanel'));
const Floky = React.lazy(() => import('./components/Floky'));
const EigeneSeite = React.lazy(() => import('./components/EigeneSeite'));
const OhneWebsite = React.lazy(() => import('./components/OhneWebsite'));
const BoardDashboard = React.lazy(() => import('./components/BoardDashboard'));
// Die Kassen-Ansicht der Vertreter ist derzeit nicht verlinkt, siehe die
// Begruendung an der Dashboard-Weiche weiter unten. Die Datei bleibt liegen,
// damit sie sich mit passenden Rechten wieder anschliessen laesst.
// const RepresentativeDashboard = React.lazy(() => import('./components/RepresentativeDashboard'));
const NeighborhoodStewardPanel = React.lazy(() => import('./components/NeighborhoodStewardPanel'));
const SocialAI = React.lazy(() => import('./components/SocialAI'));
const LoginPage = React.lazy(() => import('./components/LoginPage'));
const RegistrationWizard = React.lazy(() => import('./components/RegistrationWizard'));
const ZahlerSeite = React.lazy(() => import('./components/ZahlerSeite'));
const VillageLive = React.lazy(() => import('./components/VillageLive'));
const ProfileSetup = React.lazy(() => import('./components/ProfileSetup'));
const EventsPage = React.lazy(() => import('./components/EventsPage'));
const NewsPage = React.lazy(() => import('./components/NewsPage'));
const NachrichtSeite = React.lazy(() => import('./components/NachrichtSeite'));
const AboutUsPage = React.lazy(() => import('./components/AboutUsPage'));
const ChronikSeite = React.lazy(() => import('./components/ChronikSeite'));
const KontaktSeite = React.lazy(() => import('./components/KontaktSeite'));
const FutsalPage = React.lazy(() => import('./components/FutsalPage'));
const SponsorPage = React.lazy(() => import('./components/SponsorPage'));
const LegalPage = React.lazy(() => import('./components/LegalPage'));
const SuperAdminDashboard = React.lazy(() => import('./components/SuperAdminDashboard'));
const PlatformHome = React.lazy(() => import('./components/PlatformHome'));



 








 
import CookieConsent from './components/CookieConsent'; 
import BetreuungHinweis from './components/BetreuungHinweis';
import BackToTop from './components/BackToTop';

import { AntiScrapeProtection } from './components/AntiScrapeProtection';

import { UserRole, UserProfile, GlobalPaymentSettings, SystemSettings } from './types';

import { onImageError } from './lib/imageFallback';
interface Branding {
  primary?: string;
  secondary?: string;
  logoUrl?: string;
  logoHeight?: string; 
  footerText?: string;
  footerAddress?: string;
  footerEmail?: string;
}

// WHITELISTED ADMIN EMAILS
const PageLoader: React.FC = () => (
  // Die Farbe folgt dem Untergrund: auf der dunklen Betreiberdarstellung
  // waere ein fast schwarzer Kreisel unsichtbar.
  <div className="flex items-center justify-center py-32">
    <div className="w-8 h-8 border-2 rounded-full animate-spin"
         style={{ borderColor: 'color-mix(in srgb, var(--kontrast) 20%, transparent)',
                  borderTopColor: 'var(--kontrast)' }} />
  </div>
);

// Der Betreiber der Plattform. Er ist in keinem Verein Mitglied -- der Zugriff
// auf einen Verein laeuft ueber eine Betreuungssitzung, die mit Anfang und Ende
// stehen bleibt. Massgeblich ist die Tabelle platform_admins in der Datenbank;
// diese Liste steuert nur, was die Anwendung anzeigt.
const ADMIN_EMAILS = ['burim@dervishi.ch'];

// Wer Plattformbetreiber ist, entscheidet inzwischen die Datenbank
// (wer_bin_ich / platform_admins). Die frueher hier gefuehrte zweite Liste
// ist entfallen: sie stand nach der Rollentrennung noch auf der alten
// Adresse, und ausserdem galt jede Vereinsrolle SUPER_ADMIN als Betreiber
// -- damit landete ein Vereinsadministrator im Betreiberbereich.
//
// ADMIN_EMAILS bleibt: sie oeffnet dem Betreiber die Vereinsverwaltung fuer
// die Betreuung. Das ist eine andere Frage als der Betreiberbereich.

const AuthRedirectHandler: React.FC<{ user: UserProfile | null, children: React.ReactNode }> = ({ user, children }) => {
  const location = useLocation();
  if (user && (location.pathname === '/login' || location.pathname === '/register')) {
    // Der Betreiber der Plattform gehoert in seinen Bereich, nicht auf ein
    // Mitglieder-Dashboard: er ist in keinem Verein Mitglied, und die Ansicht
    // zeigte ihm folgerichtig einen Beitrag von 0 und "Kein Manager".
    // Wohin nach der Anmeldung? Die Liste im Quelltext entscheidet das
    // nicht mehr -- /super-admin prueft selbst und weist ab, wer nicht
    // hingehoert. Der Betreiber kommt ueber den Verweis in der Kopfzeile
    // hin; ihn hier anhand einer Adresse vorzusortieren war die zweite
    // Stelle, an der dieselbe Frage anders beantwortet wurde.
    if (ADMIN_EMAILS.includes(user.email)) {
      return <Navigate to="/super-admin" replace />;
    }
    const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN;
    // Nicht das Haekchen entscheidet, sondern die Daten selbst -- sonst
    // landen laengst vollstaendige Mitglieder immer wieder im Assistenten.
    const shouldGoToDashboard = isAdmin || !needsProfileSetup(user);
    if (!shouldGoToDashboard) return <Navigate to="/setup-profile" replace />;
    // Verwaltung und Vorstand haben ihre eigene Startseite.
    if (isAdmin || user.role === UserRole.BOARD) return <Navigate to="/dashboard" replace />;
    return <AnmeldeZiel />;
  }
  return <>{children}</>;
};

// Wer eine Nachbarschaft betreut, landet nach der Anmeldung in deren
// Ansicht und nicht auf dem Mitglieder-Dashboard. Ob jemand betreut, steht
// nicht an seiner Rolle -- die Vertreter bei Koretini sind gewoehnliche
// Mitglieder --, sondern in der Nachbarschaft selbst. Darum fragt diese
// Weiche die Datenbank (my_neighborhoods) und nicht user.role. Schlaegt die
// Frage fehl, geht es aufs Dashboard: von dort fuehrt ein Verweis weiter.
const AnmeldeZiel: React.FC = () => {
  const [ziel, setZiel] = useState<string | null>(null);
  useEffect(() => {
    let vorbei = false;
    (async () => {
      try {
        const { supabase } = await import('./services/supabase-bridge');
        const { data, error } = await supabase.rpc('my_neighborhoods');
        if (!vorbei) setZiel(!error && Array.isArray(data) && data.length > 0 ? '/nachbarschaft' : '/dashboard');
      } catch {
        if (!vorbei) setZiel('/dashboard');
      }
    })();
    return () => { vorbei = true; };
  }, []);
  return ziel ? <Navigate to={ziel} replace /> : <PageLoader />;
};

// Wer sich auf der Betreiber-Domain anmeldet, aber zu einem Verein
// gehoert, steht vor der falschen Tuer. Frueher bekam er den
// Betreiberbereich zu sehen -- die Datenbank gab ihm dort nichts heraus,
// die Ansicht war also leer und wirkte kaputt. Jetzt steht dort, wohin er
// gehoert.
const FalscheTuer: React.FC<{ wer: WerBinIch; abmelden?: boolean }> = ({ wer, abmelden }) => {
  const { t } = useTranslation();
  const ziel = wer.vereinsdomain ? `https://${wer.vereinsdomain}` : null;

  // Auf der Betreiber-Domain bleibt niemand angemeldet, der nicht der
  // Betreiber ist. Vorher bekam er eine Sitzung und danach diese Seite --
  // angemeldet war er trotzdem. Die Anmeldung dort ist dem Betreiber
  // vorbehalten, also wird sie auch beendet.
  useEffect(() => {
    if (!abmelden) return;
    signOut(auth).catch(() => { /* dann bleibt wenigstens diese Seite stehen */ });
  }, [abmelden]);
  return (
    <div className="min-h-screen flex items-center justify-center px-6"
         style={{ background: 'var(--accent)' }}>
      <div className="max-w-md text-center">
        <p className="uppercase mb-4"
           style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 11,
                    letterSpacing: '.14em', color: 'var(--kontrast)', opacity: .5 }}>
          {t('tuer.marke')}
        </p>
        <h1 className="text-3xl font-light mb-4"
            style={{ color: 'var(--kontrast)', letterSpacing: '-.02em' }}>
          {t('tuer.titel')}
        </h1>
        <p className="text-sm leading-relaxed mb-4" style={{ color: 'var(--kontrast)', opacity: .6 }}>
          {wer.vereinsname
            ? t('tuer.text').replace('{verein}', wer.vereinsname)
            : t('tuer.text_ohne')}
        </p>
        {abmelden && (
          <p className="text-xs leading-relaxed mb-8"
             style={{ color: 'var(--kontrast)', opacity: .45 }}>
            {t('tuer.abgemeldet')}
          </p>
        )}
        {ziel && (
          <a href={ziel}
             className="knopf-primaer inline-flex items-center gap-2 px-6 py-3 text-white rounded-lg text-xs font-bold">
            {t('tuer.hin').replace('{domain}', wer.vereinsdomain!)}
          </a>
        )}
      </div>
    </div>
  );
};

const ProtectedRoute: React.FC<{ user: UserProfile | null, children: React.ReactNode, adminOnly?: boolean, superAdminOnly?: boolean }> = ({ user, children, adminOnly, superAdminOnly }) => {
  const wer = useWerBinIch(!!user);
  if (!user) return <Navigate to="/login" replace />;

  const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email);

  // Den Betreiberbereich betritt nur, wen die Datenbank als Betreiber
  // fuehrt. Frueher genuegte die Vereinsrolle SUPER_ADMIN -- zwei ganz
  // verschiedene Dinge, die hier verwechselt wurden.
  if (superAdminOnly) {
    if (wer === null) return <PageLoader />;
    if (!wer.ist_betreiber) return <FalscheTuer wer={wer} />;
  }
  if (isAdmin) return <>{children}</>;
  
  if (needsProfileSetup(user) && adminOnly === undefined) return <Navigate to="/setup-profile" replace />;
  if (adminOnly && !isAdmin) return <Navigate to="/dashboard" replace />;
  
  return <>{children}</>;
};

const MaintenanceScreen = ({ branding }: { branding: Branding }) => {
  const { t } = useTranslation();
  return (
  <div className="fixed inset-0 z-[9999] bg-stone-900 flex flex-col items-center justify-center text-white p-6">
      <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ duration: 0.8 }} className="relative mb-12">
          <div className="absolute inset-0 bg-[color:color-mix(in_srgb,var(--primary)_20%,transparent)] blur-[100px] rounded-full" />
          {branding.logoUrl ? (
              <img src={branding.logoUrl} className="h-40 w-auto object-contain relative z-10 drop-shadow-2xl animate-pulse" alt="Logo"  onError={onImageError}/>
          ) : (
              <Heart size={120} className="text-primary relative z-10 animate-pulse" fill="currentColor" />
          )}
      </motion.div>
      <h1 className="text-5xl md:text-7xl font-display font-bold italic mb-6 text-center">{t('app.maintenance.title')}</h1>
      <p className="text-stone-400 text-lg md:text-xl max-w-xl text-center leading-relaxed mb-12">{t('app.maintenance.desc')}</p>
      <Link to="/login" className="px-8 py-3 rounded-full border border-white/10 hover:bg-white/10 hover:border-white/30 transition-all font-bold text-sm uppercase tracking-widest flex items-center gap-2">
          <ShieldCheck size={16} /> {t('nav.staff_login')}
      </Link>
  </div>
);
};

const MaintenanceGuard = ({ children, maintenanceMode, user, branding }: { children?: React.ReactNode, maintenanceMode: boolean, user: UserProfile | null, branding: Branding }) => {
    const location = useLocation();
    const canBypass = user && (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || user.role === UserRole.BOARD || ADMIN_EMAILS.includes(user.email));
    if (maintenanceMode && !canBypass && location.pathname !== '/login') return <MaintenanceScreen branding={branding} />;
    return <>{children}</>;
};

// Zaehlt jeden Wechsel der oeffentlichen Seite.
//
// Eigene Komponente, weil sie INNERHALB des Routers stehen muss --
// AppContent rendert den Router selbst und hat darum kein useLocation.
// Sie gibt nichts aus; sie hoert nur zu.
const Zaehlwache: React.FC = () => {
  const ort = useLocation();
  React.useEffect(() => { zaehlerStarten(); }, []);
  React.useEffect(() => {
    // Der Titel wird einen Augenblick spaeter gesetzt, wenn die Seite
    // ihn selbst traegt. Ohne die kurze Verzoegerung stuende in der
    // Auswertung der Titel der VORIGEN Seite.
    const t = setTimeout(() => { void aufrufZaehlen(ort.pathname); }, 120);
    return () => clearTimeout(t);
  }, [ort.pathname]);
  return null;
};

const AppContent: React.FC = () => {
  const { t, loc } = useTranslation();
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [branding, setBranding] = useState<Branding>({});
  // Konto vorhanden, Mitgliedseintrag nicht verknuepfbar. Eigener Zustand,
  // weil es weder "angemeldet" noch "abgemeldet" ist -- und weil die
  // Person etwas Lesbares braucht.
  const [profilFehler, setProfilFehler] = useState<string | null>(null);
  const [systemSettings, setSystemSettings] = useState<SystemSettings | null>(null);
  // Ob die Antwort da ist -- auch wenn der Verein keine Zeile hat. Sonst
  // bliebe die Kopfzeile eines neuen Vereins leer.
  const [systemGeladen, setSystemGeladen] = useState(false);
  const { tenant } = useTenant();

  useSecurity();
  useAutoLogout(user);

  useEffect(() => {
    if (loading) {
      const timer = setTimeout(() => setLoading(false), 10000);
      return () => clearTimeout(timer);
    }
  }, [loading]);

  useEffect(() => {
    const brandingUnsubscribe = onSnapshot(doc(db, 'public_settings', 'branding'), (doc) => {
      if (doc.exists()) {
        const data = doc.data();
        setBranding(data);
        if(!tenant) {
            document.documentElement.style.setProperty('--primary', data.primary || '#f43f5e');
            document.documentElement.style.setProperty('--secondary', data.secondary || '#1c1917');
        }
      }
    });

    const settingsUnsubscribe = onSnapshot(doc(db, 'public_settings', 'system'), (doc) => {
        if (doc.exists()) setSystemSettings(doc.data() as SystemSettings);
        setSystemGeladen(true);
    });

    let userUnsubscribe: (() => void) | null = null;

    // Use Supabase onAuthStateChanged (same signature as Firebase's)
    const authUnsubscribe = onAuthStateChanged(auth, async (supabaseUser: any) => {
      if (userUnsubscribe) userUnsubscribe();
      if (supabaseUser) {
        const uid = supabaseUser.uid;
        const email = supabaseUser.email || '';
        const isAdminEmail = ADMIN_EMAILS.includes(email);
        console.log("[App] Supabase user detected:", uid, email);

        // Fruehere Fassung legte fuer bestehende Mitglieder eine zweite Zeile mit
        // der Auth-UID an und kopierte die Daten hinueber. users.email ist aber
        // eindeutig, der Insert scheiterte deshalb immer mit 23505 und keine
        // Anmeldung hinterliess je ein Profil. Jetzt wird die vorhandene Zeile
        // beansprucht -- sie behaelt ihre id, an der Zahlungen und Mandate
        // haengen, und bekommt die Auth-UID als Merkmal.
        let profileId = uid;
        const claimedId = await claimMyProfile();
        if (claimedId) {
            profileId = claimedId;
            console.log("[App] Bestehendes Profil beansprucht:", profileId);
        }

        const userDocRef = doc(db, 'users', profileId);

        userUnsubscribe = onSnapshot(userDocRef, async (docSnap) => {
            if (docSnap.exists()) {
                const data = docSnap.data() as UserProfile;
                // Frueher wurde hier die Rolle einer gefundenen Zeile auf
                // SUPER_ADMIN heraufgestuft, sobald die Adresse in der Liste
                // stand. Der Betreiber hat jetzt keine Mitgliedszeile mehr --
                // und eine fremde Zeile deswegen heraufzustufen waere falsch.
                setUser({ ...data, id: profileId });
            } else if (isAdminEmail) {
                // Der Betreiber der Plattform bekommt keine Mitgliedszeile.
                //
                // Vorher legte dieser Zweig eine an, mit tenantId 'koretini' --
                // genau die Kopplung, die gerade aufgeloest wurde, waere bei
                // der naechsten Anmeldung wieder entstanden. Sein Profil lebt
                // nur im Speicher; die Rechte haengen ohnehin an der Tabelle
                // platform_admins und nicht an dieser Zeile.
                setUser({
                    id: uid,
                    authUserId: uid,
                    email,
                    role: UserRole.SUPER_ADMIN,
                    membershipStatus: 'ACTIVE',
                    displayName: 'Administrator',
                    joinedAt: new Date().toISOString(),
                    profileComplete: true,
                } as any);
            } else {
                // Weder eine Zeile unter der Auth-UID noch eine beanspruchbare.
                //
                // Das heisst NICHT zwangsläufig "neues Konto". Gemessen an
                // einem echten Fall: Alban Rexha war als Mitglied erfasst,
                // bekam die Rolle REPRESENTATIVE und registrierte sich
                // danach selbst. claim_my_profile() verknuepft bewusst nur
                // gewoehnliche Zeilen (MEMBER, GUEST) -- sonst koennte sich
                // jemand mit der Adresse eines Vorstands anmelden und dessen
                // Rechte uebernehmen. Der Anspruch wurde also zu Recht
                // abgewiesen.
                //
                // Danach lief dieser Zweig und versuchte eine ZWEITE Zeile
                // anzulegen. users.email ist eindeutig, der Insert scheiterte
                // mit 23505, der Fehler wurde geloggt und verworfen -- und
                // setUser erfand trotzdem ein Profil im Speicher. Die Person
                // landete im Einrichtungsassistenten und bekam dort beim
                // Speichern "updateDoc hat keine Zeile geaendert": eine
                // technische Meldung ueber eine Zeile, die es nie gab.
                const newUser: any = {
                    id: uid,
                    authUserId: uid,
                    // Kein fest eingetragenes 'koretini' mehr. Die
                    // Schreibschicht loest den Verein aus der Domain auf; ein
                    // neues Konto auf der Domain eines anderen Vereins waere
                    // sonst bei Koretini gelandet.
                    email,
                    role: UserRole.MEMBER,
                    membershipStatus: 'ACTIVE',
                    displayName: email.split('@')[0] || 'Member',
                    joinedAt: new Date().toISOString(),
                    profileComplete: false
                };
                try {
                    await setDoc(doc(db, 'users', uid), newUser);
                    setUser(newUser as UserProfile);
                } catch (err: any) {
                    // Kein erfundenes Profil. Wer hier scheitert, braucht
                    // die Administration -- und soll das lesen koennen,
                    // statt zwei Masken weiter eine Fehlermeldung ueber
                    // updateDoc zu bekommen.
                    console.error("[App] Profil konnte nicht angelegt werden:", err);
                    setProfilFehler(String(err?.message ?? err));
                    setUser(null);
                }
            }
            setLoading(false);
        });
      } else {
        console.log("[App] No user (logged out)");
        setUser(null);
        setLoading(false);
      }
    });

    return () => { authUnsubscribe(); brandingUnsubscribe(); settingsUnsubscribe(); if (userUnsubscribe) userUnsubscribe(); };
  }, [tenant]);

  const istPlattformDomain = useIstPlattformDomain();
  // Welche Module hat der Verein dieser Adresse? Gebraucht fuer die
  // Routen von Dorfleben und Turnier.
  //
  // Bisher war beides fuer JEDEN Verein offen -- und das Turnier war
  // zusaetzlich fest auf das von Koretini verdrahtet. Ein anderer Verein
  // haette unter seiner eigenen Adresse ein fremdes Turnier gezeigt.
  const oeffentlicheModule = useOeffentlicheModule();
  // Fuer Website, Anlaesse und Neuigkeiten: scheitert die Abfrage, kommt eine
  // leere Liste -- dann gilt die Website als vorhanden. Eine echte Antwort
  // enthaelt immer die drei Kernmodule; ohne diesen Fallback stuende ein
  // Verein bei einer Stoerung ohne Startseite da.
  const websiteModule = React.useMemo(
    () => oeffentlicheModule && oeffentlicheModule.size === 0
      ? new Set(['WEBSITE', 'ANLAESSE', 'NEUIGKEITEN']) : oeffentlicheModule,
    [oeffentlicheModule]);
  // Werbemessung. Laedt nur auf der Betreiberseite, nur mit Zustimmung
  // und nur mit eingetragener ID -- die Entscheidung steckt in
  // darfMessen(), nicht hier.
  useWerbemessung(istPlattformDomain);
  const vorlage = useStartseitenVorlage();
  const spendenSeiteSichtbar = useSpendenseiteSichtbar();
  // Wer auf unityhub.li angemeldet ist, muss der Betreiber sein. Die Frage
  // wird hier gestellt und nicht erst an der Tuer zu /super-admin: vorher
  // konnte sich jeder anmelden, bekam eine Sitzung und danach nur die Seite
  // "Hier sind Sie falsch" -- angemeldet blieb er trotzdem.
  const werAufPlattform = useWerBinIch(!!user && istPlattformDomain === true);

  // Der Rollenschalter der Vorfuehrung. Greift nur, wenn der Betreiber
  // im Demo-Verein ist -- die Pruefung steht in useDemoRolle, nicht hier.
  // Eigene Abfrage: das vorhandene `wer` lebt in ProtectedRoute, nicht hier.
  // Der Reitertitel stand fest in index.html als "Koretini" -- jeder
  // Verein trug ihn damit, nicht nur Koretini. Jetzt aus der Marke, mit
  // dem bisherigen Wert als Rueckfall: wer kein associationName hinterlegt
  // hat (Koretini selbst), behaelt genau das, was vorher dort stand.
  useEffect(() => {
    if (istPlattformDomain !== false) return;   // Betreiberseite setzt ihn selbst
    const name = loc((branding as any).associationName);
    if (name && document.title !== name) document.title = name;
  }, [branding, istPlattformDomain]);

  const werHier = useWerBinIch(!!user);
  const demo = useDemoRolle(!!werHier?.ist_betreiber, werHier?.verein ?? null);
  // Paket Light: keine Rollen-Zugaenge -- weder Anmeldung (gesperrt im
  // Anmeldesystem) noch Rollenschalter noch Registrierung.
  const paket = usePaket();
  // Die App entscheidet ueberall anhand von user.role, welche Oberflaeche
  // jemand bekommt. Genau dort setzt der Schalter an: eine ueberschriebene
  // Rolle, sonst der echte Nutzer unveraendert.
  const sichtUser = (demo.rolleFuerApp && user)
    ? ({ ...user, role: demo.rolleFuerApp } as typeof user)
    : user;
  // Reitertitel und Symbol -- fuer jede Seite der Betreiber-Domain,
  // nicht nur fuer deren Startseite.
  useReiterKennzeichen(istPlattformDomain);

  // Solange die Antwort aussteht, wird gewartet statt geraten -- dieselbe
  // Lehre wie bei der Domain selbst: wer sich zu frueh festlegt, zeigt die
  // falsche Welt und springt dann weg.
  if (istPlattformDomain === true && user && werAufPlattform === null && !loading) {
    return <PageLoader />;
  }
  if (istPlattformDomain === true && user && werAufPlattform && !werAufPlattform.ist_betreiber) {
    return <FalscheTuer wer={werAufPlattform} abmelden />;
  }

  if (loading) return (
    <div className="min-h-screen flex flex-col items-center justify-center"
         style={{ background: 'var(--accent)' }}>
      <Loader2 className="animate-spin text-primary" size={40} />
      <p className="mt-4 text-stone-400 animate-pulse">{t('app.connecting')}</p>
    </div>
  );

  // Konto vorhanden, Mitgliedseintrag nicht verknuepfbar.
  //
  // Der Fall ist echt und hat einen Namen: ein Mitglied bekommt eine
  // bevorrechtigte Rolle und registriert sich DANACH selbst.
  // claim_my_profile() verknuepft bewusst nur gewoehnliche Zeilen, sonst
  // koennte sich jemand mit der Adresse eines Vorstands anmelden und
  // dessen Rechte uebernehmen. Der Anspruch wird also zu Recht
  // abgewiesen -- aber bisher landete die Person danach im
  // Einrichtungsassistenten und bekam beim Speichern eine Meldung ueber
  // updateDoc und null geaenderte Zeilen. Das ist richtig und nutzlos.
  if (profilFehler) return (
    <div className="min-h-screen flex items-center justify-center p-6"
         style={{ background: 'var(--accent)' }}>
      <div className="max-w-md bg-white rounded-[2rem] shadow-xl border border-stone-100 p-8 space-y-4">
        <h1 className="font-display font-bold italic text-2xl text-stone-900">
          {t('profil.nicht_verbunden.titel')}
        </h1>
        <p className="text-sm text-stone-600 leading-relaxed">
          {t('profil.nicht_verbunden.text')}
        </p>
        <p className="text-[11px] text-stone-400 font-mono bg-stone-50 border border-stone-100 rounded-xl p-3 break-words">
          {profilFehler}
        </p>
        <button onClick={async () => { await signOut(auth).catch(() => {}); setProfilFehler(null); }}
          className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold text-sm">
          {t('nav.logout')}
        </button>
      </div>
    </div>
  );

  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <Zaehlwache />
      <DesignMarke vorlage={vorlage} />
      <MaintenanceGuard maintenanceMode={systemSettings?.maintenanceMode || false} user={user} branding={branding}>
        {/* Grund aus der Variablen: sie steht in index.html je Domain und
            ist schon vor dem ersten Rendern gesetzt. */}
        <div className="min-h-screen flex flex-col" style={{ background: 'var(--accent)' }}>
            <ConditionalNavigation user={user} branding={branding} systemSettings={systemSettings} systemGeladen={systemGeladen} />
            <main className="flex-grow">
            <AnimatePresence mode="wait">
                <ErrorBoundary>
                <React.Suspense fallback={<PageLoader />}>
                <Routes>
                    {/* Auf der Betreiber-Domain steht keine Vereinsseite.
                        Solange die Zuordnung noch geprueft wird (null), wird
                        KEINE von beiden gezeigt: hier stand frueher die
                        Vereinsseite, und genau deshalb erschien auf
                        unityhub.li zuerst Koretini. Nach dem ersten Besuch
                        kennt der Speicher die Antwort und dieser Zustand
                        tritt gar nicht mehr ein. */}
                    {/* Solange eine der beiden Antworten fehlt, wird gewartet.
                        Frueher fiel hier eine unbekannte Domain auf die
                        Vereinsseite durch -- auf der Betreiber-Domain erschien
                        dadurch zuerst Koretini. Dieselbe Falle gilt fuer die
                        Startseiten-Vorlage: wer sich zu frueh festlegt, zeigt
                        die Standardseite und springt dann weg. */}
                    {/* Ohne Website-Modul (Paket Light) gibt es keine
                        oeffentliche Startseite: Besucher sehen den Weg zur
                        Anmeldung, Angemeldete kommen in ihren Bereich. */}
                    <Route path="/" element={
                      istPlattformDomain === null ? <PageLoader />
                        : istPlattformDomain ? <PlatformHome user={user} />
                        : websiteModule === null ? <PageLoader />
                        : !websiteModule.has('WEBSITE') ? (user ? <Navigate to="/dashboard" replace /> : <OhneWebsite />)
                        : vorlage === null ? <PageLoader />
                        : vorlage === 'MAGAZIN' ? <Magazin />
                        : vorlage === 'KOMPAKT' ? <Kompakt />
                        : vorlage === 'ERZAEHLUNG' ? <StartseitePremium />
                        : vorlage === 'BUEHNE' ? <Buehne />
                        : vorlage === 'JOURNAL' ? <Journal />
                        : <Hero />} />
                    {/* Die Revisionsstelle: kein Konto, kein Passwort. Was
                        sie sehen darf, entscheidet das Token in der Adresse --
                        in der Datenbank, nicht hier. */}
                    <Route path="/revision/:token" element={<RevisionsSeite />} />
                    {/* Der Gastverein: kein Konto, kein Passwort. Was er sehen
                        und aendern darf, entscheidet das Token in der Adresse --
                        in der Datenbank, nicht hier. */}
                    <Route path="/treffen/:token" element={<TreffenGastSeite />} />
                    {/* Die Selbstvorstellung. Jede Person bekommt ihren eigenen
                        Link; was sie damit darf, entscheidet die Datenbank. */}
                    <Route path="/vorstellen/:token" element={<VorstellungWizard />} />
                    {/* Das Heft nach dem Treffen -- derselbe Link wie bei der
                        Vorstellung, ab dem Tag des Treffens. */}
                    <Route path="/heft/:token" element={<HeftSeite />} />
                    {/* Flyer und Poster zum Treffen. Eigene Seite, damit der
                        Druckdialog nur das Blatt sieht und nicht die halbe
                        Verwaltung drumherum. Wer das Treffen lesen darf,
                        entscheidet die Datenbank. */}
                    <Route path="/drucksachen/:id" element={<TreffenDrucksachen />} />
                    <Route path="/about" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <AboutUsPage />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'WEBSITE', istPlattformDomain))} />
                    <Route path="/chronik" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <ChronikSeite />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'WEBSITE', istPlattformDomain))} />
                    <Route path="/kontakt" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <KontaktSeite />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'WEBSITE', istPlattformDomain))} />
                    {/* Dorfleben nur mit gebuchtem Modul. Ausgeblendet
                        heisst auch nicht erreichbar: nur den Verweis
                        wegzunehmen hiesse "schwerer zu finden", nicht "aus".
                        Solange die Antwort aussteht, laedt die Seite --
                        sofort umzuleiten wuerde einen Besucher
                        hinauswerfen, dessen Verein das Modul hat. */}
                    <Route path="/live" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <VillageLive />
                            : <Navigate to="/" replace />)
                      (seitenZustand(oeffentlicheModule, 'DORFLEBEN', istPlattformDomain))} />
                    <Route path="/events" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <EventsPage />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'ANLAESSE', istPlattformDomain))} />
                    <Route path="/news" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <NewsPage />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'NEUIGKEITEN', istPlattformDomain))} />
                    <Route path="/news/:id" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <NachrichtSeite />
                            : <Navigate to="/" replace />)
                      (seitenZustand(websiteModule, 'NEUIGKEITEN', istPlattformDomain))} />
                    {/* Turnier und Sponsoring. Die Adressen werden so geteilt
                        (koretini.me/fussball/sponsoren); index.html schreibt
                        einen Pfad ohne Raute auf die Rauten-Form um und
                        entfernt dabei den Schraegstrich am Ende. Eine eigene
                        Route mit Schraegstrich darf es nicht geben -- React
                        Router weist solche Pfade zurueck und legt damit die
                        gesamte Routentabelle lahm. */}
                    <Route path="/fussball" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <FutsalPage />
                            : <Navigate to="/" replace />)
                      (seitenZustand(oeffentlicheModule, 'TURNIER', istPlattformDomain))} />
                    <Route path="/fussball/sponsoren" element={
                      ((z) => z === 'LAEDT' ? <PageLoader />
                            : z === 'ZEIGEN' ? <SponsorPage />
                            : <Navigate to="/" replace />)
                      (seitenZustand(oeffentlicheModule, 'TURNIER', istPlattformDomain))} />
                    <Route path="/futsal" element={<Navigate to="/fussball" replace />} />
                    <Route path="/gdpr" element={<LegalPage type="GDPR" />} />
                    {/* Spenden. Die Zeilenregel sperrt die Daten ohnehin; die Route
                        faellt zusaetzlich weg, damit kein Verweis auf eine
                        Seite fuehrt, die nichts annehmen kann. */}
                    {/* Ausgeblendet heisst auch nicht erreichbar. Nur den
                        Verweis wegzunehmen hiesse "schwerer zu finden", nicht
                        "aus" -- ueber die eingetippte Adresse stuende die
                        Seite weiter offen. */}
                    <Route path="/spenden" element={
                      spendenSeiteSichtbar === null ? <PageLoader />
                        : spendenSeiteSichtbar ? <SpendenSeite />
                        : <Navigate to="/" replace />} />
                    {/* Was die Seite zeigt, entscheidet die Zeilenregel:
                        freigegeben UND Modul aktiv. Ohne gebuchtes Modul
                        bleibt sie leer statt zu fehlen -- eine Adresse, die
                        ins Leere laeuft, verwirrt mehr als eine leere Seite. */}
                    <Route path="/videos" element={istPlattformDomain ? <Navigate to="/" replace /> : <VideoSeite />} />
                    {/* Zahlerliste: ob oeffentlich, nur fuer Mitglieder oder aus,
                        entscheidet zahlerliste() -- die Seite sagt es dann. */}
                    <Route path="/beitraege" element={istPlattformDomain ? <Navigate to="/" replace /> : <ZahlerSeite />} />
                    <Route path="/privacy" element={<LegalPage type="PRIVACY" />} />
                    <Route path="/login" element={<AuthRedirectHandler user={user}><LoginPage /></AuthRedirectHandler>} />
                    <Route path="/register" element={paket === 'LIGHT' ? <Navigate to="/login" replace /> : <AuthRedirectHandler user={user}><RegistrationWizard /></AuthRedirectHandler>} />
                    {/* Betreuung einer Nachbarschaft. Wer dafuer nicht
                        zustaendig ist, bekommt in der Ansicht selbst den
                        Hinweis -- die Zugriffsregeln geben ihm ohnehin
                        keine fremden Daten heraus. */}
                    <Route path="/nachbarschaft" element={user ? <NeighborhoodStewardPanel user={user} /> : <Navigate to="/login" />} />
                    <Route path="/setup-profile" element={user ? <ProfileSetup user={user} onComplete={setUser} /> : <Navigate to="/login" />} />
                    
                    {/* Auf der Betreiber-Domain gibt es kein Mitglieder-Dashboard.
                        Der Betreiber ist in keinem Verein Mitglied, und die
                        Ansicht zeigte ihm folgerichtig einen Beitrag von 0 und
                        "Kein Manager" -- richtig gerechnet, aber sinnlos. */}
                    <Route path="/dashboard" element={
                        // Auf der Betreiber-Domain gibt es kein Mitglieder-
                        // Dashboard. /super-admin prueft selbst, wer dort
                        // hingehoert, und weist Vereinsleute an ihre eigene
                        // Adresse weiter.
                        istPlattformDomain ? <Navigate to="/super-admin" replace /> :
                        <ProtectedRoute user={sichtUser}>
                            {sichtUser?.role === UserRole.BOARD ? <BoardDashboard user={sichtUser} /> : <Dashboard user={sichtUser!} />}
                            {/* Die Kassen-Ansicht der Vertreter haengt an
                                is_member_manager(), das REPRESENTATIVE nicht
                                mehr einschliesst -- sie koennte nichts mehr
                                schreiben. Benutzt wurde sie nie: collectedBy
                                ist bei allen 324 Zahlungen leer. Die Betreuung
                                einer Nachbarschaft laeuft jetzt ueber
                                /nachbarschaft, verlinkt aus dem Dashboard. */}
                        </ProtectedRoute>
                    } />
                    
                    <Route path="/admin" element={<ProtectedRoute user={sichtUser} adminOnly><AdminPanel /></ProtectedRoute>} />
                    <Route path="/super-admin" element={<ProtectedRoute user={user} superAdminOnly><SuperAdminDashboard user={user} /></ProtectedRoute>} />
                    {/* Selbst gebaute Seiten. Steht ganz unten, aber das
                        entscheidet nicht die Reihenfolge: Router 6 bewertet
                        statische Pfade hoeher als dynamische, /about gewinnt
                        also weiterhin gegen /:pfad. Auf der Betreiberdomain
                        gibt es keine Vereinsseiten. */}
                    {!istPlattformDomain && (
                      <Route path="/:pfad" element={
                        ((z) => z === 'LAEDT' ? <PageLoader />
                              : z === 'ZEIGEN' ? <EigeneSeite />
                              : <Navigate to="/" replace />)
                        (seitenZustand(websiteModule, 'WEBSITE', istPlattformDomain))} />
                    )}
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
                </React.Suspense>
                </ErrorBoundary>
            </AnimatePresence>
            </main>
            <ConditionalFooter branding={branding} user={user} systemSettings={systemSettings} systemGeladen={systemGeladen} />
            <CookieConsent />
            {/* Zeigt sich nur dem Betreiber auf der Domain eines Vereins --
                und nur, wenn er selbst zu keinem Verein gehoert. Sonst sieht
                er vollstaendige Menues und ueberall 0 Zeilen. */}
            <BetreuungHinweis user={user} />
            {/* Der Rollenschalter der Vorfuehrung. useDemoRolle gibt
                erlaubt nur im Demo-Verein und nur dem Betreiber zurueck --
                in einer echten Vereinsoberflaeche kann die Leiste damit
                nicht auftauchen. */}
            {demo.erlaubt && paket !== 'LIGHT' && (
              <React.Suspense fallback={null}>
                <DemoRollenschalter rolle={demo.rolle} setRolle={demo.setRolle} />
              </React.Suspense>
            )}
            {/* Floky. Die Maske prueft selbst ueber floky_darf(), ob das
                Modul gebucht ist und die Rolle einen Assistenten bekommt --
                und gibt sonst null zurueck. Deshalb steht sie hier und
                nicht hinter einer zweiten Pruefung: zwei Pruefungen laufen
                frueher oder spaeter auseinander. */}
            {user && (
              <React.Suspense fallback={null}>
                <Floky />
              </React.Suspense>
            )}
            <BackToTop />
        </div>
      </MaintenanceGuard>
    </Router>
  );
};

// Die gewaehlte Vorlage gilt fuer die ganze oeffentliche Website, nicht nur
// fuer die Startseite: lib/design.css uebersetzt Navigation, Fusszeile und
// die Bausteine der uebrigen Seiten in ihr Aussehen. Hier stehen nur die
// Marken am Wurzelelement. Wo gearbeitet wird -- Verwaltung, Mitglieder-
// und Vertreterbereich, die Seiten hinter einem Zugangslink -- bleibt es
// beim gewohnten Aussehen; die Navigation darueber traegt die Vorlage
// trotzdem, sie gehoert zur Website.
const ARBEITSBEREICHE = ['/dashboard', '/nachbarschaft', '/setup-profile', '/admin', '/super-admin',
                         '/drucksachen', '/revision', '/treffen', '/vorstellen', '/heft'];
const DesignMarke: React.FC<{ vorlage: string | null }> = ({ vorlage }) => {
  const { pathname } = useLocation();
  const istPlattform = useIstPlattformDomain();
  useEffect(() => {
    const h = document.documentElement;
    const aktiv = istPlattform === false && !!vorlage && vorlage !== 'KLASSISCH';
    const arbeit = ARBEITSBEREICHE.some(p => pathname.startsWith(p));
    if (aktiv) h.dataset.design = vorlage!; else delete h.dataset.design;
    if (aktiv && !arbeit && pathname !== '/') h.dataset.designSeite = vorlage!; else delete h.dataset.designSeite;
  }, [vorlage, pathname, istPlattform]);
  return null;
};

const Navigation: React.FC<any> = ({ user, branding, systemSettings, systemGeladen }) => {
  // Derselbe Massstab wie bei der Route: nur wer laut Datenbank Betreiber
  // ist, bekommt den Verweis. Ihn jedem Vereins-SUPER_ADMIN anzubieten
  // fuehrte auf eine Seite, die ihm nichts zeigt.
  const werIch = useWerBinIch(!!user);
  // Ohne gebuchtes Modul gehoert kein Verweis in die Leiste, mit gebuchtem
  // gehoert er hinein. Bisher fehlte er in beiden Faellen -- die
  // Spendenseite war nur ueber die eingetippte Adresse erreichbar.
  const { t, loc, setLanguage, language } = useTranslation();
  // Solange die Einstellungen fehlen, keine Eintraege: sonst stuenden sie
  // eine Sekunde in der Grundreihenfolge und sprangen dann um.
  const kopfAlle = useKopfzeile({
    einstellung: (systemSettings as any)?.navigation,
    zahlerliste: (systemSettings as any)?.zahlerliste,
    angemeldet: !!user, loc,
  });
  const kopf = systemGeladen ? (kopfAlle || []).filter(zeigtOben) : null;
  // Untermenues: die Gruppen aus Website -> Navigation. Ohne Gruppen ist
  // der Baum dieselbe flache Liste wie bisher.
  const baum = navBaum(kopf || [], navGruppen((systemSettings as any)?.navigationGruppen));
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const isActive = (path: string) => location.pathname === path;
  // Wo die Navigation steht, waehlt der Verein (Website -> Navigation).
  // Solange die Einstellungen fehlen, die Kopfzeile -- wie bisher.
  const layout = navLayout(systemGeladen ? (systemSettings as any)?.navigationLayout : null);
  const seitenleiste = layout.computer === 'SEITENLEISTE';
  const leisteUnten = layout.handy === 'LEISTE';
  // Platz fuer Seitenleiste und untere Leiste schafft index.html ueber
  // diese Marken. Verschwindet die Navigation (Verwaltung), gehen sie mit.
  useEffect(() => {
    const h = document.documentElement;
    if (seitenleiste) h.setAttribute('data-nav-seite', ''); else h.removeAttribute('data-nav-seite');
    if (leisteUnten) h.setAttribute('data-nav-unten', ''); else h.removeAttribute('data-nav-unten');
    return () => { h.removeAttribute('data-nav-seite'); h.removeAttribute('data-nav-unten'); };
  }, [seitenleiste, leisteUnten]);
  useEffect(() => { setIsMenuOpen(false); }, [location.pathname]);
  const label = (e: any) => e.uebersetzen ? t(e.label) : e.label;
  const istAdmin = !!user && (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email));

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (e) {
      console.error("Sign out error:", e);
    }
  };

  const logo = (gross: boolean) => branding.logoUrl ? (
    <img src={branding.logoUrl} style={{ height: branding.logoHeight || '2.5rem' }} className="w-auto object-contain" alt="Logo"  onError={onImageError}/>
  ) : (
    <div className={`bg-primary ${gross ? 'p-2.5' : 'p-2'} rounded-xl text-white shadow-lg`}><Heart size={24} fill="white" /></div>
  );
  const sprachen = (
    <div className="flex gap-1 bg-stone-100/50 p-1 rounded-lg">
      {['sq', 'de', 'en'].map(l => ( <button key={l} onClick={() => setLanguage(l as any)} className={`px-2 py-1 rounded-md text-[10px] font-bold uppercase ${language === l ? 'bg-white text-primary' : 'text-stone-400'}`}>{l}</button> ))}
    </div>
  );

  return (
    <>
    {/* Seitenleiste links, nur am Computer. Auf dem Handy bleibt es bei
        der Kopfzeile mit Menue oder der Leiste unten. */}
    {seitenleiste && (
      <aside className="hidden md:flex fixed top-0 left-0 bottom-0 w-72 z-50 p-4 select-none">
        <div className="glass rounded-2xl shadow-lg flex flex-col w-full p-4 gap-1 overflow-y-auto">
          <Link to="/" className="flex items-center gap-3 p-2 mb-4">
            {logo(true)}
            <span className="font-display font-bold text-lg italic text-stone-800 leading-tight">{loc((branding as any).associationName) || ''}</span>
          </Link>
          {baum.map(k => {
            const zeile = (e: any) => (
              <Link key={e.schluessel} to={e.pfad} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all ${isActive(e.pfad) ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                {e.icon}<span className="font-bold text-sm">{label(e)}</span>
              </Link>
            );
            return k.art === 'eintrag' ? zeile(k.eintrag) : (
              <React.Fragment key={`g-${k.gruppe.id}`}>
                <GruppenTitel gruppe={k.gruppe} />
                {k.eintraege.map(zeile)}
              </React.Fragment>
            );
          })}
          <div className="flex-1" />
          <div className="pt-4 border-t border-stone-200/60 space-y-3">
            {sprachen}
            {user ? (
              <div className="flex items-center gap-2">
                <Link to="/dashboard" className="flex-1 flex items-center gap-2 px-3 py-2.5 bg-stone-900 text-white rounded-xl text-sm font-bold"><LayoutDashboard size={15} /> {t('nav.dashboard')}</Link>
                {istAdmin && <Link to="/admin" className="w-10 h-10 bg-stone-900 text-white rounded-xl flex items-center justify-center"><ShieldCheck size={16} /></Link>}
                {werIch?.ist_betreiber && (
                  <Link to="/super-admin" title={t('nav.platform')} className="w-10 h-10 bg-primary text-white rounded-xl flex items-center justify-center"><Building2 size={16} /></Link>
                )}
                <button onClick={handleSignOut} className="w-10 h-10 text-stone-400 hover:text-primary flex items-center justify-center"><LogOut size={18} /></button>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                <Link to="/register" className="bg-primary text-white px-4 py-2.5 rounded-xl text-sm font-bold text-center shadow-lg">{t('nav.join')}</Link>
                <Link to="/login" className="text-sm font-bold text-stone-500 hover:text-primary text-center py-1">{t('nav.login')}</Link>
              </div>
            )}
          </div>
        </div>
      </aside>
    )}

    {/* Leiste unten, nur auf dem Handy: Start, die ersten Eintraege, Mehr. */}
    {leisteUnten && (
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 px-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-2 select-none">
        <div className="glass rounded-2xl shadow-lg flex items-stretch justify-around px-1 py-1.5">
          <Link to="/" className={`flex-1 flex flex-col items-center gap-1 py-1.5 rounded-xl ${isActive('/') ? 'bg-white shadow-sm text-stone-900' : 'text-stone-500'}`}>
            <Home size={20} /><span className="text-[10px] font-bold truncate max-w-full px-1">{t('nav.home')}</span>
          </Link>
          {(kopf || []).slice(0, 3).map(e => (
            <Link key={e.schluessel} to={e.pfad} className={`flex-1 min-w-0 flex flex-col items-center gap-1 py-1.5 rounded-xl ${isActive(e.pfad) ? 'bg-white shadow-sm text-stone-900' : 'text-stone-500'}`}>
              {e.iconKlein}<span className="text-[10px] font-bold truncate max-w-full px-1">{label(e)}</span>
            </Link>
          ))}
          <button onClick={() => setIsMenuOpen(!isMenuOpen)} className={`flex-1 flex flex-col items-center gap-1 py-1.5 rounded-xl ${isMenuOpen ? 'bg-white shadow-sm text-stone-900' : 'text-stone-500'}`}>
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}<span className="text-[10px] font-bold">{t('nav.mehr')}</span>
          </button>
        </div>
      </nav>
    )}

    <nav className={`fixed top-0 left-0 right-0 z-50 p-4 md:p-6 select-none ${seitenleiste ? 'md:hidden' : ''}`}>
      <div className="max-w-7xl mx-auto glass rounded-2xl flex items-center justify-between px-4 py-2 shadow-lg relative">
        <Link to="/" className="flex items-center gap-3 pr-4 group relative z-50">
          {logo(false)}
          <span className="font-display font-bold text-xl italic hidden xl:block text-stone-800">{loc((branding as any).associationName) || ''}</span>
        </Link>

        {/* Die Eintraege kommen aus kopfzeile.tsx: Reihenfolge und An/Aus
            bestimmt der Verein, ob ein Eintrag erscheinen kann, das
            gebuchte Modul. Leiste und Handymenue lesen dieselbe Liste --
            vorher waren es zwei Abschriften, und im Handymenue fehlten
            Videos und Spenden. */}
        <div className="hidden md:flex items-center gap-1 lg:gap-2">
            {baum.map(k => k.art === 'eintrag' ? (
              <Link key={k.eintrag.schluessel} to={k.eintrag.pfad} className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive(k.eintrag.pfad) ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                  {k.eintrag.icon}<span className="font-bold text-sm">{label(k.eintrag)}</span>
              </Link>
            ) : (
              <KopfGruppe key={`g-${k.gruppe.id}`} gruppe={k.gruppe} eintraege={k.eintraege}
                mega={layout.computer === 'MEGAMENU'} angemeldet={!!user} />
            ))}
        </div>

        <div className="flex items-center gap-2 md:gap-4 z-50">
          {sprachen}
          <div className="hidden md:flex items-center gap-3 pl-2">
              {user ? (
                <>
                   <Link to="/dashboard" className="text-sm font-bold text-stone-500 hover:text-stone-900">{t('nav.dashboard')}</Link>
                   {istAdmin && ( <Link to="/admin" className="w-9 h-9 bg-stone-900 text-white rounded-xl flex items-center justify-center shadow-lg"><ShieldCheck size={16} /></Link> )}
                   {werIch?.ist_betreiber && (
                     <Link to="/super-admin" title={t('nav.platform')} className="w-9 h-9 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg hover:bg-rose-600 transition-colors">
                       <Building2 size={16} />
                     </Link>
                   )}
                   <button onClick={handleSignOut} className="text-stone-400 hover:text-primary"><LogOut size={18} /></button>
                </>
              ) : (
                <>
                  <Link to="/login" className="text-sm font-bold text-stone-500 hover:text-primary">{t('nav.login')}</Link>
                  <Link to="/register" className="bg-primary text-white px-5 py-2.5 rounded-xl text-sm font-bold shadow-lg">{t('nav.join')}</Link>
                </>
              )}
          </div>
          <button onClick={() => setIsMenuOpen(!isMenuOpen)} className={`${leisteUnten ? 'hidden' : 'md:hidden'} w-10 h-10 bg-white rounded-xl flex items-center justify-center text-stone-600 shadow-sm border border-stone-100`}>
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        <AnimatePresence>
            {isMenuOpen && (
                <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} className="absolute top-full left-0 right-0 mt-3 mx-2 p-4 bg-white/95 backdrop-blur-xl rounded-[2rem] shadow-2xl border border-white/20 md:hidden flex flex-col gap-2 z-40">
                    {/* Mit der Leiste unten stehen die ersten drei schon dort. */}
                    {(() => {
                      const schonUnten = new Set(leisteUnten ? (kopf || []).slice(0, 3).map(e => e.schluessel) : []);
                      const zeile = (e: any) => (
                        <Link key={e.schluessel} to={e.pfad} onClick={() => setIsMenuOpen(false)} className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl">{e.iconKlein}<span className="font-bold">{label(e)}</span></Link>
                      );
                      return baum.map(k => {
                        if (k.art === 'eintrag') return schonUnten.has(k.eintrag.schluessel) ? null : zeile(k.eintrag);
                        const rest = k.eintraege.filter(e => !schonUnten.has(e.schluessel));
                        return rest.length ? (
                          <React.Fragment key={`g-${k.gruppe.id}`}>
                            <GruppenTitel gruppe={k.gruppe} />
                            {rest.map(zeile)}
                          </React.Fragment>
                        ) : null;
                      });
                    })()}
                    <div className="h-px bg-stone-100 my-2" />
                    {user ? (
                        <>
                            <Link to="/dashboard" className="flex items-center gap-4 p-4 bg-stone-900 text-white rounded-2xl shadow-lg"><LayoutDashboard size={20} /><span className="font-bold">{t('nav.dashboard')}</span></Link>
                            <button onClick={handleSignOut} className="flex items-center gap-4 p-4 text-stone-400 justify-center font-bold text-sm"><LogOut size={16} /> {t('nav.signout')}</button>
                        </>
                    ) : (
                        <div className="flex flex-col gap-3">
                            <Link to="/login" className="w-full py-4 text-center font-bold text-stone-600 bg-stone-50 rounded-2xl">{t('nav.login')}</Link>
                            <Link to="/register" className="w-full py-4 text-center font-bold text-white bg-primary rounded-2xl shadow-lg">{t('nav.join')}</Link>
                        </div>
                    )}
                </motion.div>
            )}
        </AnimatePresence>
      </div>
    </nav>
    </>
  );
};

const ConditionalNavigation = ({ user, branding, systemSettings, systemGeladen }: any) => {
  const routeLoc = useLocation();
  // Auf der Betreiber-Domain gibt es ueberhaupt keine Vereinsnavigation.
  //
  // Vorher war das auf die Startseite beschraenkt -- auf /login und
  // /dashboard erschien dadurch weiterhin die Leiste von Koretini, samt
  // Herzsymbol, "Ueber uns" und "Koretini Live". Diese Verweise gehoeren
  // einem Verein, und den gibt es auf dieser Adresse nicht.
  const istPlattform = useIstPlattformDomain();
  const hidePaths = ['/setup-profile', '/super-admin', '/admin'];
  if (istPlattform) return null;
  if (hidePaths.some(path => routeLoc.pathname.startsWith(path))) return null;
  return <Navigation user={user} branding={branding} systemSettings={systemSettings} systemGeladen={systemGeladen} />;
};

const ConditionalFooter = ({ branding, user, systemSettings, systemGeladen }: any) => {
  const { t, loc } = useTranslation();
  // Dieselbe Liste wie die Navigation (kopfzeile.tsx). Was in die
  // Fusszeile kommt, bestimmt der Verein je Eintrag (Navigation,
  // Fusszeile, beides); ob ein Eintrag erscheinen KANN, das Modul. Vorher
  // standen die Verweise hier von Hand -- "Ueber uns" auch ohne Modul
  // Website, und eigene Seiten ueber eine zweite Abfrage.
  const fussAlle = useKopfzeile({
    einstellung: (systemSettings as any)?.navigation,
    zahlerliste: (systemSettings as any)?.zahlerliste,
    angemeldet: !!user, loc,
  });
  const fuss = systemGeladen ? (fussAlle || []).filter(zeigtFuss) : [];
  const routeLoc = useLocation();
  // Dieselbe Ueberlegung wie bei der Navigation: die Fusszeile eines Vereins
  // gehoert nicht auf die Adresse der Plattform.
  const istPlattform = useIstPlattformDomain();
  const hidePaths = ['/setup-profile', '/super-admin', '/admin'];
  if (istPlattform) return null;
  if (hidePaths.some(path => routeLoc.pathname.startsWith(path))) return null;
  
  return (
    <footer className="bg-secondary text-white py-16 px-6 relative">
      <div className="max-w-7xl mx-auto relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12 border-b border-white/10 pb-12">
          <div className="lg:col-span-2 space-y-8">
            {branding.logoUrl ? <img src={branding.logoUrl} style={{ height: branding.logoHeight || '3rem' }} className="w-auto mb-6 object-contain" alt="Logo"  onError={onImageError}/> : <h3 className="font-display text-3xl font-bold italic mb-6">{loc((branding as any).associationName) || ''}</h3>}
            {/* Nur was der Verein selbst hinterlegt hat.
                Hier stand ein Rueckfall auf koretinis Satz ueber die
                Diaspora -- ein zweiter Verein mit leerer Fusszeile haette
                ihn als seinen eigenen angezeigt. */}
            {loc(branding.footerText) && (
              <p className="text-white/50 text-lg leading-relaxed max-w-md italic">{loc(branding.footerText)}</p>
            )}
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">{t('footer.contact')}</h4>
            <div className="space-y-3 text-white/60">
               {/* Gemessen: koretinis footerEmail war eine leere
                   Zeichenkette, darum griff der Rueckfall -- und der
                   lautete info@koretini.org, die ALTE Domain. Jeder
                   andere Verein mit leerer Fusszeile hat dieselbe
                   fremde Adresse angezeigt. Eine erfundene Angabe ist
                   schlechter als keine. */}
               {loc(branding.footerAddress) && (
                 <p className="flex items-center gap-3"><MapPin size={18} className="text-primary" /> {loc(branding.footerAddress)}</p>
               )}
               {loc(branding.footerEmail) && (
                 <p className="flex items-center gap-3"><Mail size={18} className="text-primary" /> {loc(branding.footerEmail)}</p>
               )}
               {!loc(branding.footerAddress) && !loc(branding.footerEmail) && (
                 <p className="text-white/30 text-sm italic">{t('footer.contact.none')}</p>
               )}
            </div>
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">{t('footer.links')}</h4>
            <div className="flex flex-col gap-3 text-white/60">
              <Link to="/" className="hover:text-white transition-colors">{t('nav.home')}</Link>
              {fuss.map(e => (
                <Link key={e.schluessel} to={e.pfad} className="hover:text-white transition-colors">
                  {e.uebersetzen ? t(e.label) : e.label}
                </Link>
              ))}
              <Link to="/login" className="hover:text-white transition-colors">{t('nav.membership')}</Link>
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row justify-between items-center gap-6 text-white/30 text-xs font-medium uppercase tracking-widest">
          {/* Ohne Namen kein Name -- und kein fremder. Der Punkt entfaellt
              mit, sonst stuende "© 2026 . Alle Rechte vorbehalten." */}
          <p>© {new Date().getFullYear()}
            {loc((branding as any).associationName)
              ? ` ${loc((branding as any).associationName)}. `
              : ' · '}
            {t('footer.rights')}</p>
        </div>
      </div>
    </footer>
  );
};

const App = () => (
  <FeedbackProvider>
    <TenantProvider>
        <LanguageProvider>
          <AntiScrapeProtection>
            <AppContent />
          </AntiScrapeProtection>
        </LanguageProvider>
    </TenantProvider>
  </FeedbackProvider>
);

export default App;
