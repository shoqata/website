
import React, { useState, useEffect } from 'react';
import { HashRouter as Router, Routes, Route, Link, useLocation, Navigate, useSearchParams } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  LayoutDashboard, Settings, LogOut, Heart, Menu, X, Globe, Sparkles, LogIn, Zap, ChevronDown, 
  Mail, MapPin, ShieldCheck, Calendar, Newspaper, Info, QrCode, ArrowRight, Smartphone, 
  Hammer, Maximize, UserPlus, Loader2
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
const RepresentativeDashboard = React.lazy(() => import('./components/RepresentativeDashboard'));
const SocialAI = React.lazy(() => import('./components/SocialAI'));
const LoginPage = React.lazy(() => import('./components/LoginPage'));
const RegistrationWizard = React.lazy(() => import('./components/RegistrationWizard'));
const VillageLive = React.lazy(() => import('./components/VillageLive'));
const ProfileSetup = React.lazy(() => import('./components/ProfileSetup'));
const EventsPage = React.lazy(() => import('./components/EventsPage'));
const NewsPage = React.lazy(() => import('./components/NewsPage'));
const AboutUsPage = React.lazy(() => import('./components/AboutUsPage'));
const LegalPage = React.lazy(() => import('./components/LegalPage'));
const SuperAdminDashboard = React.lazy(() => import('./components/SuperAdminDashboard'));



 








 
import CookieConsent from './components/CookieConsent'; 
import BackToTop from './components/BackToTop';

import { AntiScrapeProtection } from './components/AntiScrapeProtection';

import { UserRole, UserProfile, GlobalPaymentSettings, SystemSettings } from './types';

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

const ADMIN_EMAILS = ['email@dervishi.ch'];

const AuthRedirectHandler: React.FC<{ user: UserProfile | null, children: React.ReactNode }> = ({ user, children }) => {
  const location = useLocation();
  if (user && (location.pathname === '/login' || location.pathname === '/register')) {
    const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email);
    const shouldGoToDashboard = user.profileComplete || isAdmin;
    return <Navigate to={shouldGoToDashboard ? "/dashboard" : "/setup-profile"} replace />;
  }
  return <>{children}</>;
};

const ProtectedRoute: React.FC<{ user: UserProfile | null, children: React.ReactNode, adminOnly?: boolean, superAdminOnly?: boolean }> = ({ user, children, adminOnly, superAdminOnly }) => {
  if (!user) return <Navigate to="/login" replace />;
  
  const isAdmin = user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || ADMIN_EMAILS.includes(user.email);
  const isSuper = user.role === UserRole.SUPER_ADMIN || user.email === 'info@unityhub.li';
  
  if (superAdminOnly && !isSuper) return <Navigate to="/" replace />;
  if (isAdmin) return <>{children}</>;
  
  if (!user.profileComplete && adminOnly === undefined) return <Navigate to="/setup-profile" replace />;
  if (adminOnly && !isAdmin) return <Navigate to="/dashboard" replace />;
  
  return <>{children}</>;
};

const MaintenanceScreen = ({ branding }: { branding: Branding }) => (
  <div className="fixed inset-0 z-[9999] bg-stone-900 flex flex-col items-center justify-center text-white p-6">
      <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ duration: 0.8 }} className="relative mb-12">
          <div className="absolute inset-0 bg-primary/20 blur-[100px] rounded-full" />
          {branding.logoUrl ? (
              <img src={branding.logoUrl} className="h-40 w-auto object-contain relative z-10 drop-shadow-2xl animate-pulse" alt="Logo" />
          ) : (
              <Heart size={120} className="text-primary relative z-10 animate-pulse" fill="currentColor" />
          )}
      </motion.div>
      <h1 className="text-5xl md:text-7xl font-display font-bold italic mb-6 text-center">Under Maintenance</h1>
      <p className="text-stone-400 text-lg md:text-xl max-w-xl text-center leading-relaxed mb-12">Përmirësim i sistemit në rrjedhë e sipër. Ju lutem kthehuni më vonë.</p>
      <Link to="/login" className="px-8 py-3 rounded-full border border-white/10 hover:bg-white/10 hover:border-white/30 transition-all font-bold text-sm uppercase tracking-widest flex items-center gap-2">
          <ShieldCheck size={16} /> Staff Login
      </Link>
  </div>
);

const MaintenanceGuard = ({ children, maintenanceMode, user, branding }: { children?: React.ReactNode, maintenanceMode: boolean, user: UserProfile | null, branding: Branding }) => {
    const location = useLocation();
    const canBypass = user && (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN || user.role === UserRole.BOARD || ADMIN_EMAILS.includes(user.email));
    if (maintenanceMode && !canBypass && location.pathname !== '/login') return <MaintenanceScreen branding={branding} />;
    return <>{children}</>;
};

const AppContent: React.FC = () => {
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
    const brandingUnsubscribe = onSnapshot(doc(db, 'settings', 'branding'), (doc) => {
      if (doc.exists()) {
        const data = doc.data();
        setBranding(data);
        if(!tenant) {
            document.documentElement.style.setProperty('--primary', data.primary || '#f43f5e');
            document.documentElement.style.setProperty('--secondary', data.secondary || '#1c1917');
        }
      }
    });

    const settingsUnsubscribe = onSnapshot(doc(db, 'settings', 'system'), (doc) => {
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
                if (isAdminEmail && data.role !== UserRole.SUPER_ADMIN) {
                    await updateDoc(userDocRef, { role: UserRole.SUPER_ADMIN, profileComplete: true });
                }
                setUser({ ...data, id: profileId });
            } else {
                // Weder eine Zeile unter der Auth-UID noch eine beanspruchbare:
                // es ist wirklich ein neues Konto.
                const newUser: any = {
                    id: uid,
                    authUserId: uid,
                    tenantId: 'koretini',
                    email,
                    role: isAdminEmail ? UserRole.SUPER_ADMIN : UserRole.MEMBER,
                    membershipStatus: 'ACTIVE',
                    displayName: isAdminEmail ? 'Administrator' : (email.split('@')[0] || 'Anëtar'),
                    joinedAt: new Date().toISOString(),
                    profileComplete: isAdminEmail
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

  if (loading) return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#faf9f6]">
      <Loader2 className="animate-spin text-primary" size={40} />
      <p className="mt-4 text-stone-400 animate-pulse">Duke u lidhur...</p>
    </div>
  );

  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <MaintenanceGuard maintenanceMode={systemSettings?.maintenanceMode || false} user={user} branding={branding}>
        <div className="min-h-screen flex flex-col bg-[#faf9f6]">
            <ConditionalNavigation user={user} branding={branding} systemSettings={systemSettings} />
            <main className="flex-grow">
            <AnimatePresence mode="wait">
                <React.Suspense fallback={<PageLoader />}>
                <Routes>
                    <Route path="/" element={<Hero />} />
                    <Route path="/about" element={<AboutUsPage />} />
                    <Route path="/live" element={<VillageLive />} />
                    <Route path="/events" element={<EventsPage />} />
                    <Route path="/news" element={<NewsPage />} />
                    <Route path="/gdpr" element={<LegalPage type="GDPR" />} />
                    <Route path="/privacy" element={<LegalPage type="PRIVACY" />} />
                    <Route path="/login" element={<AuthRedirectHandler user={user}><LoginPage /></AuthRedirectHandler>} />
                    <Route path="/register" element={<AuthRedirectHandler user={user}><RegistrationWizard /></AuthRedirectHandler>} />
                    <Route path="/setup-profile" element={user ? <ProfileSetup user={user} onComplete={setUser} /> : <Navigate to="/login" />} />
                    
                    <Route path="/dashboard" element={
                        <ProtectedRoute user={user}>
                            {user?.role === UserRole.BOARD ? <BoardDashboard user={user} /> : user?.role === UserRole.REPRESENTATIVE ? <RepresentativeDashboard user={user} /> : <Dashboard user={user!} />}
                        </ProtectedRoute>
                    } />
                    
                    <Route path="/admin" element={<ProtectedRoute user={user} adminOnly><AdminPanel /></ProtectedRoute>} />
                    <Route path="/super-admin" element={<ProtectedRoute user={user} superAdminOnly><SuperAdminDashboard /></ProtectedRoute>} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
                </React.Suspense>
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
  const { t, setLanguage, language } = useTranslation();
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
            <img src={branding.logoUrl} style={{ height: branding.logoHeight || '2.5rem' }} className="w-auto object-contain" alt="Logo" />
          ) : (
            <div className="bg-primary p-2 rounded-xl text-white shadow-lg"><Heart size={24} fill="white" /></div>
          )}
          <span className="font-display font-bold text-xl italic hidden xl:block text-stone-800">Koretini</span>
        </Link>

        <div className="hidden md:flex items-center gap-1 lg:gap-2">
            <Link to="/about" className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${isActive('/about') ? 'bg-white shadow-sm' : 'hover:bg-white/50'}`}>
                <Info size={16} className="text-emerald-600"/><span className="font-bold text-sm">Rreth Nesh</span>
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
                    <Link to="/about" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Info size={20}/><span className="font-bold">Rreth Nesh</span></Link>
                    <Link to="/events" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Calendar size={20}/><span className="font-bold">{t('nav.events.title')}</span></Link>
                    <Link to="/news" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Newspaper size={20}/><span className="font-bold">{t('nav.news.title')}</span></Link>
                    <Link to="/live" className="flex items-center gap-4 p-4 bg-stone-50 rounded-2xl"><Zap size={20}/><span className="font-bold">{t('nav.live')}</span></Link>
                    <div className="h-px bg-stone-100 my-2" />
                    {user ? (
                        <>
                            <Link to="/dashboard" className="flex items-center gap-4 p-4 bg-stone-900 text-white rounded-2xl shadow-lg"><LayoutDashboard size={20} /><span className="font-bold">{t('nav.dashboard')}</span></Link>
                            <button onClick={handleSignOut} className="flex items-center gap-4 p-4 text-stone-400 justify-center font-bold text-sm"><LogOut size={16} /> Sign Out</button>
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
  const loc = useLocation();
  const hidePaths = ['/setup-profile', '/super-admin', '/admin'];
  if (hidePaths.some(path => loc.pathname.startsWith(path))) return null;
  return <Navigation user={user} branding={branding} systemSettings={systemSettings} />;
};

const ConditionalFooter = ({ branding, user }: any) => {
  const loc = useLocation();
  const hidePaths = ['/setup-profile', '/super-admin', '/admin'];
  if (hidePaths.some(path => loc.pathname.startsWith(path))) return null;
  
  return (
    <footer className="bg-secondary text-white py-16 px-6 relative">
      <div className="max-w-7xl mx-auto relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12 border-b border-white/10 pb-12">
          <div className="lg:col-span-2 space-y-8">
            {branding.logoUrl ? <img src={branding.logoUrl} style={{ height: branding.logoHeight || '3rem' }} className="w-auto mb-6 object-contain" alt="Logo" /> : <h3 className="font-display text-3xl font-bold italic mb-6">Koretini</h3>}
            <p className="text-white/50 text-lg leading-relaxed max-w-md italic">{branding.footerText || "Bashkë për vendlindjen tonë. Diaspora dhe Koretini në një hap drejt të ardhmes."}</p>
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">Kontakt</h4>
            <div className="space-y-3 text-white/60">
               <p className="flex items-center gap-3"><MapPin size={18} className="text-primary" /> {branding.footerAddress || "Koretin, Kosovë"}</p>
               <p className="flex items-center gap-3"><Mail size={18} className="text-primary" /> {branding.footerEmail || "info@koretini.org"}</p>
            </div>
          </div>
          <div className="space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-[0.2em] text-primary">Linke</h4>
            <div className="flex flex-col gap-3 text-white/60">
              <Link to="/" className="hover:text-white transition-colors">Ballina</Link>
              <Link to="/about" className="hover:text-white transition-colors">Rreth Nesh</Link>
              <Link to="/live" className="hover:text-white transition-colors">Koretini Live</Link>
              <Link to="/login" className="hover:text-white transition-colors">Anëtarësimi</Link>
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row justify-between items-center gap-6 text-white/30 text-xs font-medium uppercase tracking-widest">
          <p>© {new Date().getFullYear()} Shoqata Koretini. Të gjitha të drejtat e rezervuara.</p>
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
