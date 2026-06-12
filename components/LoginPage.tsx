
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Mail, ArrowRight, ShieldCheck, Heart, ArrowLeft, AlertCircle, Chrome, Lock, Eye, EyeOff, RefreshCcw, Key, LogIn } from 'lucide-react';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';

// Firebase
import { auth } from '../services/firebase';
import { 
  sendSignInLinkToEmail, 
  isSignInWithEmailLink, 
  signInWithEmailLink,
  GoogleAuthProvider,
  signInWithPopup,
  signInWithEmailAndPassword,
  sendPasswordResetEmail
} from 'firebase/auth';

const LoginPage: React.FC = () => {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [step, setStep] = useState<'INPUT' | 'SENT' | 'VERIFYING' | 'FORGOT' | 'RESET_SENT'>('INPUT');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [loginMethod, setLoginMethod] = useState<'PASSWORD' | 'MAGIC'>('PASSWORD');
  const navigate = useNavigate();

  useEffect(() => {
    // Check for auto-logout session expired flag
    if (localStorage.getItem('koretini_session_expired')) {
        setError(t('auth.session_expired'));
        localStorage.removeItem('koretini_session_expired');
    }

    const completeSignIn = async () => {
      if (isSignInWithEmailLink(auth, window.location.href)) {
        setStep('VERIFYING');
        let emailForSignIn = window.localStorage.getItem('emailForSignIn');
        
        if (!emailForSignIn) {
          emailForSignIn = window.prompt(t('login.email.label'));
        }
        
        try {
          await signInWithEmailLink(auth, emailForSignIn || '', window.location.href);
          window.localStorage.removeItem('emailForSignIn');
          navigate('/dashboard');
        } catch (err: any) {
          console.error("Link verification error:", err);
          handleAuthError(err);
          setStep('INPUT');
        }
      }
    };
    completeSignIn();
  }, [navigate, t]);

  const handleAuthError = (err: any) => {
    if (err.code === 'auth/unauthorized-domain') {
      setError(`Domain "${window.location.hostname}" not authorized.`);
    } else if (err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
      setError(t('common.error') + ": Email/Password wrong.");
    } else {
      setError(err.message || t('common.error'));
    }
    setIsLoading(false);
  };

  const handlePasswordLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;
    setError(null);
    setIsLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      if (!userCredential.user.emailVerified) {
        setError(t('wizard.success.title')); // Generic message to check email
        setIsLoading(false);
        return;
      }
      navigate('/dashboard');
    } catch (err: any) {
      handleAuthError(err);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setError(t('login.email.label'));
      return;
    }
    setError(null);
    setIsLoading(true);
    try {
      await sendPasswordResetEmail(auth, email);
      setStep('RESET_SENT');
    } catch (err: any) {
      handleAuthError(err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleMagicLinkSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setError(null);
    setIsLoading(true);

    const actionCodeSettings = {
      url: window.location.origin + '/#/login',
      handleCodeInApp: true,
    };

    try {
      await sendSignInLinkToEmail(auth, email, actionCodeSettings);
      window.localStorage.setItem('emailForSignIn', email);
      setStep('SENT');
    } catch (err: any) {
      handleAuthError(err);
    }
  };

  const handleGoogleLogin = async () => {
    setError(null);
    setIsLoading(true);
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
      navigate('/dashboard');
    } catch (err: any) {
      handleAuthError(err);
    }
  };

  return (
    <div className="min-h-screen grid grid-cols-1 lg:grid-cols-2 bg-[#faf9f6]">
      {/* Left Hero Side */}
      <div className="hidden lg:flex relative bg-rose-500 overflow-hidden items-center justify-center p-12">
        <div className="absolute inset-0">
          <img 
            src="https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&q=80&w=2070" 
            alt="Humanitarian mission" 
            className="w-full h-full object-cover opacity-40 mix-blend-overlay" 
          />
          <div className="absolute inset-0 bg-gradient-to-br from-rose-600/40 to-stone-900/60" />
        </div>
        <div className="relative z-10 max-w-md text-white text-center lg:text-left">
          <Heart fill="white" size={64} className="mb-12 mx-auto lg:mx-0 shadow-2xl" />
          <h1 className="font-display text-5xl font-bold mb-6 leading-tight italic">
            {t('login.hero.title')}
          </h1>
          <p className="text-xl text-rose-50/80 leading-relaxed mb-12 italic">
            {t('login.hero.desc')}
          </p>
        </div>
      </div>

      {/* Right Login Side */}
      <div className="flex flex-col p-8 lg:p-24 justify-center relative overflow-hidden">
        <div className="absolute top-8 left-8 lg:top-12 lg:left-12">
          <button 
            onClick={() => step === 'INPUT' ? navigate('/') : setStep('INPUT')}
            className="flex items-center gap-2 text-stone-500 hover:text-rose-500 transition-colors font-bold text-sm tracking-tight"
          >
            <ArrowLeft size={18} /> {step === 'INPUT' ? t('login.back') : t('common.back')}
          </button>
        </div>

        <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="max-w-md w-full mx-auto">
          <AnimatePresence mode="wait">
            {step === 'VERIFYING' ? (
              <motion.div key="verifying" className="text-center py-12">
                <div className="w-16 h-16 border-4 border-rose-100 border-t-rose-500 rounded-full animate-spin mx-auto mb-8"></div>
                <h3 className="text-2xl font-bold">{t('login.verifying')}</h3>
              </motion.div>
            ) : step === 'INPUT' ? (
              <motion.div key="input" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <div className="mb-12 text-center lg:text-left">
                  <h2 className="text-4xl font-display font-bold mb-4 italic text-stone-900 tracking-tight">{t('login.title')}</h2>
                  <p className="text-stone-500 text-lg leading-relaxed">{t('login.subtitle')} (v2-firebase-restored)</p>
                </div>

                {error && (
                  <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-2xl flex items-start gap-3 text-red-600 text-sm leading-relaxed">
                    <AlertCircle size={18} className="shrink-0 mt-0.5" /> 
                    <span>{error}</span>
                  </div>
                )}

                <div className="space-y-4 mb-8">
                  <div className="flex bg-stone-100 p-1 rounded-2xl mb-6">
                    <button 
                      onClick={() => setLoginMethod('PASSWORD')}
                      className={`flex-1 py-3 rounded-xl text-xs font-bold transition-all ${loginMethod === 'PASSWORD' ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-400'}`}
                    >
                      {t('login.method.password')}
                    </button>
                    <button 
                      onClick={() => setLoginMethod('MAGIC')}
                      className={`flex-1 py-3 rounded-xl text-xs font-bold transition-all ${loginMethod === 'MAGIC' ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-400'}`}
                    >
                      {t('login.method.magic')}
                    </button>
                  </div>

                  {loginMethod === 'PASSWORD' ? (
                    <form onSubmit={handlePasswordLogin} className="space-y-6">
                      <div>
                        <label className="block text-[10px] font-bold text-stone-400 mb-3 uppercase tracking-widest">{t('login.email.label')}</label>
                        <div className="relative">
                          <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                          <input 
                            type="email" 
                            required 
                            placeholder={t('login.email.placeholder')}
                            value={email} 
                            onChange={(e) => setEmail(e.target.value)} 
                            className="w-full pl-16 pr-6 py-5 bg-white border-2 border-stone-100 rounded-2xl outline-none focus:border-rose-500/30 transition-all text-lg shadow-sm font-medium" 
                          />
                        </div>
                      </div>
                      <div>
                        <div className="flex justify-between items-center mb-3">
                          <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('login.password.label')}</label>
                          <button 
                            type="button" 
                            onClick={() => setStep('FORGOT')}
                            className="text-[10px] font-bold text-primary hover:underline uppercase tracking-widest"
                          >
                            {t('login.password.forgot')}
                          </button>
                        </div>
                        <div className="relative">
                          <Lock className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                          <input 
                            type={showPassword ? "text" : "password"} 
                            required 
                            placeholder="••••••••"
                            value={password} 
                            onChange={(e) => setPassword(e.target.value)} 
                            className="w-full pl-16 pr-14 py-5 bg-white border-2 border-stone-100 rounded-2xl outline-none focus:border-rose-500/30 transition-all text-lg shadow-sm font-medium" 
                          />
                          <button 
                            type="button"
                            onClick={() => setShowPassword(!showPassword)}
                            className="absolute right-6 top-1/2 -translate-y-1/2 text-stone-300 hover:text-stone-500 transition-colors"
                          >
                            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                          </button>
                        </div>
                      </div>
                      <button 
                        type="submit" 
                        disabled={isLoading} 
                        className="w-full bg-rose-500 text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-rose-600 transition-all shadow-2xl shadow-rose-200 disabled:opacity-50 text-lg"
                      >
                        {isLoading ? (
                          <div className="w-6 h-6 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                        ) : (
                          <>{t('login.submit')} <ArrowRight size={22} /></>
                        )}
                      </button>
                    </form>
                  ) : (
                    <form onSubmit={handleMagicLinkSubmit} className="space-y-6">
                      <div>
                        <label className="block text-[10px] font-bold text-stone-400 mb-3 uppercase tracking-widest">{t('login.email.label')}</label>
                        <div className="relative">
                          <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                          <input 
                            type="email" 
                            required 
                            placeholder={t('login.email.placeholder')}
                            value={email} 
                            onChange={(e) => setEmail(e.target.value)} 
                            className="w-full pl-16 pr-6 py-5 bg-white border-2 border-stone-100 rounded-2xl outline-none focus:border-rose-500/30 transition-all text-lg shadow-sm font-medium" 
                          />
                        </div>
                      </div>
                      <button 
                        type="submit" 
                        disabled={isLoading} 
                        className="w-full bg-rose-500 text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-rose-600 transition-all shadow-2xl shadow-rose-200 disabled:opacity-50 text-lg"
                      >
                        {isLoading ? (
                          <div className="w-6 h-6 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                        ) : (
                          <>{t('login.email.send')} <ArrowRight size={22} /></>
                        )}
                      </button>
                    </form>
                  )}

                  <div className="relative py-6">
                    <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-stone-100"></div></div>
                    <div className="relative flex justify-center text-[10px] uppercase tracking-[0.4em] font-bold text-stone-300 bg-[#faf9f6] px-6">{t('common.or')}</div>
                  </div>

                  <button 
                    onClick={handleGoogleLogin}
                    disabled={isLoading}
                    className="w-full flex items-center justify-center gap-4 py-5 bg-white border-2 border-stone-100 rounded-2xl font-bold text-stone-700 hover:bg-stone-50 transition-all shadow-sm hover:shadow-md disabled:opacity-50"
                  >
                    <Chrome size={22} className="text-blue-500" /> {t('login.google')}
                  </button>
                </div>
              </motion.div>
            ) : step === 'FORGOT' ? (
              <motion.div key="forgot" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <div className="mb-12 text-center lg:text-left">
                  <h2 className="text-4xl font-display font-bold mb-4 italic text-stone-900 tracking-tight">{t('login.password.forgot')}</h2>
                  <p className="text-stone-500 text-lg leading-relaxed">{t('login.subtitle')}</p>
                </div>

                {error && (
                  <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-2xl flex items-start gap-3 text-red-600 text-sm leading-relaxed">
                    <AlertCircle size={18} className="shrink-0 mt-0.5" /> 
                    <span>{error}</span>
                  </div>
                )}

                <form onSubmit={handleForgotPassword} className="space-y-6">
                  <div>
                    <label className="block text-[10px] font-bold text-stone-400 mb-3 uppercase tracking-widest">{t('login.email.label')}</label>
                    <div className="relative">
                      <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-stone-300" size={20} />
                      <input 
                        type="email" 
                        required 
                        placeholder={t('login.email.placeholder')}
                        value={email} 
                        onChange={(e) => setEmail(e.target.value)} 
                        className="w-full pl-16 pr-6 py-5 bg-white border-2 border-stone-100 rounded-2xl outline-none focus:border-rose-500/30 transition-all text-lg shadow-sm font-medium" 
                      />
                    </div>
                  </div>
                  <button 
                    type="submit" 
                    disabled={isLoading} 
                    className="w-full bg-rose-500 text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-rose-600 transition-all shadow-2xl shadow-rose-200 disabled:opacity-50 text-lg"
                  >
                    {isLoading ? (
                      <div className="w-6 h-6 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                    ) : (
                      <>{t('login.email.send')} <Key size={22} /></>
                    )}
                  </button>
                  <button 
                    type="button"
                    onClick={() => setStep('INPUT')}
                    className="w-full text-stone-400 hover:text-stone-900 text-xs font-bold transition-colors uppercase tracking-widest"
                  >
                    {t('common.back')}
                  </button>
                </form>
              </motion.div>
            ) : step === 'RESET_SENT' ? (
              <motion.div key="reset-sent" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-center py-12">
                <div className="w-24 h-24 bg-rose-50 text-rose-500 rounded-3xl flex items-center justify-center mx-auto mb-8 shadow-inner">
                  <RefreshCcw size={48} className="animate-spin-slow" />
                </div>
                <h3 className="text-3xl font-display font-bold mb-4 italic">{t('login.sent.title')}</h3>
                <p className="text-stone-500 text-lg mb-8 leading-relaxed">
                  {t('login.sent.desc')} <br /> 
                  <span className="font-bold text-stone-900 border-b-2 border-rose-100">{email}</span>
                </p>
                <button 
                  onClick={() => setStep('INPUT')} 
                  className="w-full bg-stone-900 text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-stone-800 transition-all shadow-xl text-lg"
                >
                  <LogIn size={22} /> {t('login.submit')}
                </button>
              </motion.div>
            ) : (
              <motion.div key="sent" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-center py-12">
                <div className="w-24 h-24 bg-green-50 text-green-500 rounded-3xl flex items-center justify-center mx-auto mb-8 shadow-inner">
                  <ShieldCheck size={48} />
                </div>
                <h3 className="text-3xl font-display font-bold mb-4 italic">{t('login.sent.title')}</h3>
                <p className="text-stone-500 text-lg mb-8 leading-relaxed">
                  {t('login.sent.desc')} <br /> 
                  <span className="font-bold text-stone-900 border-b-2 border-rose-100">{email}</span>
                </p>
                <button 
                  onClick={() => setStep('INPUT')} 
                  className="text-stone-400 hover:text-stone-900 text-sm font-bold transition-colors underline uppercase tracking-widest"
                >
                  {t('login.sent.retry')}
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
      </div>
    </div>
  );
};

export default LoginPage;
