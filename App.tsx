
import React, { useState, useEffect } from 'react';
import { needsProfileSetup } from './lib/memberQuality';
import { useIstPlattformDomain } from './lib/useIstPlattformDomain';
import { HashRouter as Router, Routes, Route, Link, useLocation, Navigate, useSearchParams } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  LayoutDashboard, Settings, LogOut, Heart, Menu, X, Globe, Sparkles, LogIn, Zap, ChevronDown, 
  Mail, MapPin, ShieldCheck, Calendar, Newspaper, Info, QrCode, ArrowRight, Smartphone, 
  Hammer, Maximize, UserPlus, Loader2, Building2
} from 'lucide-react';
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
} from './services/firebase';


// Context & Hooks
import { LanguageProvider, useTranslation } from './context/LanguageContext';
import { ErrorBoundary } from './components/ErrorBoundary';
import { FeedbackProvider } from './context/FeedbackContext';
import { TenantProvider, useTenant } from './context/TenantContext';
import { useSecurity } from './hooks/useSecurity';
import { useAutoLogout } from './hooks/useAutoLogout';

// Components
import Hero from './components/Hero';

// Nur die Startseite wird sofort geladen. Alles andere -- und damit die
// schweren Admin- und Dashboard-Ansichten samt Charts, 3D und PDF-Erzeugung --
// kommt erst, wenn die Route tatsaechlich aufgerufen wird.
const Dashboard = React.lazy(() => import('./components/Dashboard'));
const AdminPanel = React.lazy(() => import('./components/AdminPanel'));
const BoardDashboard = React.lazy(() => import('./components/BoardDashboard'));
// Die Kassen-Ansicht der Vertreter ist derzeit nicht verlinkt, siehe die
// Begruendung an der Dashboard-Weiche weiter unten. Die Datei bleibt liegen,
// damit sie sich mit passenden Rechten wieder anschliessen laesst.
// const RepresentativeDashboard = React.lazy(() => import('./components/RepresentativeDashboard'));
const NeighborhoodStewardPanel = React.lazy(() => import('./components/NeighborhoodStewardPanel'));
const SocialAI = React.lazy(() => import('./components/SocialAI'));
const LoginPage = React.lazy(() => import('./components/LoginPage'));
const RegistrationWizard = React.lazy(() => import('./components/RegistrationWizard'));
const VillageLive = React.lazy(() => import('./components/VillageLive'));
const ProfileSetup = React.lazy(() => import('./components/ProfileSetup'));
const EventsPage = React.lazy(() => import('./components/EventsPage'));
const NewsPage = React.lazy(() => import('./components/NewsPage'));
const AboutUsPage = React.lazy(() => import('./components/AboutUsPage'));
const FutsalPage = React.lazy(() => import('./components/FutsalPage'));
const SponsorPage = React.lazy(() => import('./components/SponsorPage'));
const LegalPage = React.lazy(() => import('./components/LegalPage'));
const SuperAdminDashboard = React.lazy(() => import('./components/SuperAdminDashboard'));
const PlatformHome = React.lazy(() => import('./components/PlatformHome'));



 








 
import CookieConsent from './components/CookieConsent'; 
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
  <div className="flex items-center justify-center py-32">
    <div className="w-8 h-8 border-2 border-stone-200 border-t-stone-900 rounded-full animate-spin" />
  </div>
);

// Der Betreiber der Plattform. Er ist in keinem Verein Mitglied -- der Zugriff
// auf einen Verein laeuft ueber eine Betreuungssitzung, die mit Anfang und Ende
// stehen bleibt. Massgeblich ist die Tabelle platform_admins in der Datenbank;
// diese Liste steuert nur, was die Anwendung anzeigt.
const ADMIN_EMAILS = ['burim@dervishi.ch'];

// Es gab hier zwei Listen fuer dieselbe Sache, und die zweite stand nach der
// Rollentrennung noch auf der alten Adresse -- der Betreiberbereich waere damit
// dem falschen Konto angeboten worden. Jetzt ist es eine.
const PLATFORM_EMAILS = ADMIN_EMAILS;

const AuthRedirectHandler: React.FC<{ user: UserProfile | null, children: React.ReactNode }> = ({ user, children }) => {
  const location = useLocation();
  if (user && (location.pathname === '/login' || location.pathname === '/register')) {
    // Der Betreiber der Plattform gehoert in seinen Bereich, nicht auf ein
    // Mitglieder-Dashboard: er ist in keinem Verein Mitglied, und die Ansicht
    // zeigte ihm folgerichtig einen Beitrag von 0 und "Kein Manager".
    if (ADMIN_EMAILS.includes(user.email)) {
      return <Navigate to="/super-admin" replace />;
    }
    const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN;
    // Nicht das Haekchen entscheidet, sondern die Daten selbst -- sonst
    // landen laengst vollstaendige Mitglieder immer wieder im Assistenten.
    const shouldGoToDashboard = isAdmin || !needsProfileSetup(user);
    return <Navigate to={shouldGoToDashboard ? "/dashboard" : "/setup-profile"} replace />;
  }
  return <>{children}</>;
};

const ProtectedRoute: React.FC<{ user: UserProfile | null, children: React.ReactNode, adminOnly?: boolean, superAdminOnly?: boolean }> = ({ user, children, adminOnly, superAdminOnly }) => {
  if (!user) return <Navigate to="/login" replace />;
  
  const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email);
  const isSuper = user.role === UserRole.SUPER_ADMIN || PLATFORM_EMAILS.includes(user.email);
  
  if (superAdminOnly && !isSuper) return <Navigate to="/" replace />;
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
          <div className="absolute inset-0 bg-primary/20 blur-[100px] rounded-full" />
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

const AppContent: React.FC = () => {
  const { t } = useTranslation();
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [branding, setBranding] = useState<Branding>({});
  const [systemSettings, setSystemSettings] = useState<SystemSettings | null>(null);
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
                // Weder eine Zeile unter der Auth-UID noch eine beanspruchbare:
                // es ist wirklich ein neues Konto.
                const newUser: any = {
                    id: uid,
                    authUserId: uid,
                    tenantId: 'koretini',
                    email,
                    role: UserRole.MEMBER,
                    membershipStatus: 'ACTIVE',
                    displayName: email.split('@')[0] || 'Member',
                    joinedAt: new Date().toISOString(),
                    profileComplete: false
                };
                try {
                    await setDoc(doc(db, 'users', uid), newUser);
                } catch (err) {
                    console.error("[App] Profil konnte nicht angelegt werden:", err);
                }
                setUser(newUser as UserProfile);
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

  if (loading) return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#faf9f6]">
      <Loader2 className="animate-spin text-primary" size={40} />
      <p className="mt-4 text-stone-400 animate-pulse">{t('app.connecting')}</p>
    </div>
  );

  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <MaintenanceGuard maintenanceMode={systemSettings?.maintenanceMode || false} user={user} branding={branding}>
        <div className="min-h-screen flex flex-col bg-[#faf9f6]">
            <ConditionalNavigation user={user} branding={branding} systemSettings={systemSettings} />
            <main className="flex-grow">
            <AnimatePresence mode="wait">
                <ErrorBoundary>
                <React.Suspense fallback={<PageLoader />}>
                <Routes>
                    {/* Auf der Betreiber-Domain steht keine Vereinsseite.
                        Solange die Zuordnung noch geprueft wird (null), bleibt
                        es bei der bisherigen Seite -- ein kurzes Aufblitzen der
                        falschen Startseite waere schlechter als eine
                        Verzoegerung von Sekundenbruchteilen. */}
                    <Route path="/" element={istPlattformDomain ? <PlatformHome user={user} /> : <Hero />} />
                    <Route path="/about" element={istPlattformDomain ? <Navigate to="/" replace /> : <AboutUsPage />} />
                    <Route path="/live" element={istPlattformDomain ? <Navigate to="/" replace /> : <VillageLive />} />
                    <Route path="/events" element={istPlattformDomain ? <Navigate to="/" replace /> : <EventsPage />} />
                    <Route path="/news" element={istPlattformDomain ? <Navigate to="/" replace /> : <NewsPage />} />
                    {/* Turnier und Sponsoring. Die Adressen werden so geteilt
                        (koretini.me/fussball/sponsoren); index.html schreibt
                        einen Pfad ohne Raute auf die Rauten-Form um und
                        entfernt dabei den Schraegstrich am Ende. Eine eigene
                        Route mit Schraegstrich darf es nicht geben -- React
                        Router weist solche Pfade zurueck und legt damit die
                        gesamte Routentabelle lahm. */}
                    <Route path="/fussball" element={istPlattformDomain ? <Navigate to="/" replace /> : <FutsalPage />} />
                    <Route path="/fussball/sponsoren" element={istPlattformDomain ? <Navigate to="/" replace /> : <SponsorPage />} />
                    <Route path="/futsal" element={<Navigate to="/fussball" replace />} />
                    <Route path="/gdpr" element={<LegalPage type="GDPR" />} />
                    <Route path="/privacy" element={<LegalPage type="PRIVACY" />} />
                    <Route path="/login" element={<AuthRedirectHandler user={user}><LoginPage /></AuthRedirectHandler>} />
                    <Route path="/register" element={<AuthRedirectHandler user={user}><RegistrationWizard /></AuthRedirectHandler>} />
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
                        istPlattformDomain ? <Navigate to="/super-admin" replace /> :
                        <ProtectedRoute user={user}>
                            {user?.role === UserRole.BOARD ? <BoardDashboard user={user} /> : <Dashboard user={user!} />}
                            {/* Die Kassen-Ansicht der Vertreter haengt an
                                is_member_manager(), das REPRESENTATIVE nicht
                                mehr einschliesst -- sie koennte nichts mehr
                                schreiben. Benutzt wurde sie nie: collectedBy
                                ist bei allen 324 Zahlungen leer. Die Betreuung
                                einer Nachbarschaft laeuft jetzt ueber
                                /nachbarschaft, verlinkt aus dem Dashboard. */}
                        </ProtectedRoute>
                    } />
                    
                    <Route path="/admin" element={<ProtectedRoute user={user} adminOnly><AdminPanel /></ProtectedRoute>} />
                    <Route path="/super-admin" element={<ProtectedRoute user={user} superAdminOnly><SuperAdminDashboard user={user} /></ProtectedRoute>} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
                </React.Suspense>
                </ErrorBoundary>
            </AnimatePresence>
            </main>
            <ConditionalFooter branding={branding} user={user} />
            <CookieConsent />
            <BackToTop />
        </div>
      </MaintenanceGuard>
    </Router>
  );
};

const Navigation: React.FC<any> = ({ user, branding, systemSettings }) => {
  const { t, loc, setLanguage, language } = useTranslation();
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const isActive = (path: string) => location.pathname === path;

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (e) {
      console.error("Sign out error:", e);
    }
  };

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 p-4 md:p-6 select-none">
      <div className="max-w-7xl mx-auto glass rounded-2xl flex items-center justify-between px-4 py-2 shadow-lg relative">
        <Link to="/" className="flex items-center gap-3 pr-4 group relative z-50">
          {branding.logoUrl ? (
            <img src={branding.logoUrl} style={{ height: branding.logoHeight || '2.5rem' }} className="w-auto object-contain" alt="Logo"  onError={onImageError}/>
          ) : (
            <div className="bg-primary p-2 rounded-xl text-white shadow-lg"><Heart size={24} fill="white" /></div>
          )}
          <span className="font-display font-bold text-xl italic hidden xl:block text-stone-800">{loc(branding.associationName) || 'Koretini'}</span>
        </Link>

        <div className="hidden md:flex items-center gap-1 lg:gap-2">
            <Link to="/about" className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive('/about') ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                <Info size={16} className="text-emerald-600"/><span className="font-bold text-sm">{t('nav.about')}</span>
            </Link>
            <Link to="/events" className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive('/events') ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                <Calendar size={16} className="text-primary"/><span className="font-bold text-sm">{t('nav.events.title')}</span>
            </Link>
            <Link to="/news" className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive('/news') ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                <Newspaper size={16} className="text-blue-600"/><span className="font-bold text-sm">{t('nav.news.title')}</span>
            </Link>
            <Link to="/live" className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive('/live') ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                <Zap size={16} className="text-amber-600"/><span className="font-bold text-sm">{t('nav.live')}</span>
            </Link>
        </div>

        <div className="flex items-center gap-2 md:gap-4 z-50">
          <div className="flex gap-1 bg-stone-100/50 p-1 rounded-lg">
            {['sq', 'de', 'en'].map(l => ( <button key={l} onClick={() => setLanguage(l as any)} className={`px-2 py-1 rounded-md text-[10px] font-bold uppercase ${language === l ? 'bg-white text-primary' : 'text-stone-400'}`}>{l}</button> ))}
          </div>
          <div className="hidden md:flex items-center gap-3 pl-2">
              {user ? (
                <>
                   <Link to="/dashboard" className="text-sm font-bold text-stone-500 hover:text-stone-900">{t('nav.dashboard')}</Link>
                   {(user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email)) && ( <Link to="/admin" className="w-9 h-9 bg-stone-900 text-white rounded-xl flex items-center justify-center shadow-lg"><ShieldCheck size={16} /></Link> )}
                   {(user.role === UserRole.SUPER_ADMIN || PLATFORM_EMAILS.includes(user.email)) && (
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
          <button onClick={() => setIsMenuOpen(!isMenuOpen)} className="md:hidden w-10 h-10 bg-white rounded-xl flex items-center justify-center text-stone-600 shadow-sm border border-stone-100">
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        <AnimatePresence>
            {isMenuOpen && (
                <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} className="absolute top-full left-0 right-0 mt-3 mx-2 p-4 bg-white/95 backdrop-blur-xl rounded-[2rem] shadow-2xl border border-white/20 md:hidden flex flex-col gap-2 z-40">
                    <Link to="/about" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Info size={20}/><span className="font-bold">{t('nav.about')}</span></Link>
                    <Link to="/events" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Calendar size={20}/><span className="font-bold">{t('nav.events.title')}</span></Link>
                    <Link to="/news" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Newspaper size={20}/><span className="font-bold">{t('nav.news.title')}</span></Link>
                    <Link to="/live" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Zap size={20}/><span className="font-bold">{t('nav.live')}</span></Link>
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
  );
};

const ConditionalNavigation = ({ user, branding, systemSettings }: any) => {
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
  return <Navigation user={user} branding={branding} systemSettings={systemSettings} />;
};

const ConditionalFooter = ({ branding, user }: any) => {
  const { t, loc } = useTranslation();
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
            {branding.logoUrl ? <img src={branding.logoUrl} style={{ height: branding.logoHeight || '3rem' }} className="w-auto mb-6 object-contain" alt="Logo"  onError={onImageError}/> : <h3 className="font-display text-3xl font-bold italic mb-6">Koretini</h3>}
            <p className="text-white/50 text-lg leading-relaxed max-w-md italic">{loc(branding.footerText) || t('footer.tagline')}</p>
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">{t('footer.contact')}</h4>
            <div className="space-y-3 text-white/60">
               <p className="flex items-center gap-3"><MapPin size={18} className="text-primary" /> {loc(branding.footerAddress) || t('footer.address.fallback')}</p>
               <p className="flex items-center gap-3"><Mail size={18} className="text-primary" /> {loc(branding.footerEmail) || t('footer.email.fallback')}</p>
            </div>
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">{t('footer.links')}</h4>
            <div className="flex flex-col gap-3 text-white/60">
              <Link to="/" className="hover:text-white transition-colors">{t('nav.home')}</Link>
              <Link to="/about" className="hover:text-white transition-colors">{t('nav.about')}</Link>
              <Link to="/live" className="hover:text-white transition-colors">{t('nav.live')}</Link>
              <Link to="/login" className="hover:text-white transition-colors">{t('nav.membership')}</Link>
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row justify-between items-center gap-6 text-white/30 text-xs font-medium uppercase tracking-widest">
          <p>© {new Date().getFullYear()} {loc(branding.associationName) || 'Shoqata Koretini'}. {t('footer.rights')}</p>
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
