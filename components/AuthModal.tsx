
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Mail, ArrowRight, ShieldCheck, Heart } from 'lucide-react';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLogin: (email: string) => void;
}

const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose, onLogin }) => {
  const [email, setEmail] = useState('');
  const [step, setStep] = useState<'INPUT' | 'SENT'>('INPUT');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setStep('SENT');
    // Simulate sending magic link
    setTimeout(() => {
      onLogin(email);
      setStep('INPUT');
      setEmail('');
    }, 2500);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-6">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm"
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className="relative w-full max-w-md bg-white rounded-[2.5rem] p-8 shadow-2xl overflow-hidden"
          >
            <button onClick={onClose} className="absolute top-6 right-6 p-2 text-stone-400 hover:text-stone-900 transition-colors">
              <X size={20} />
            </button>

            <div className="mb-8">
              <div className="w-12 h-12 bg-rose-50 text-rose-500 rounded-2xl flex items-center justify-center mb-6">
                <Heart fill="currentColor" />
              </div>
              <h2 className="text-3xl font-display font-bold mb-2">Join Humanitas</h2>
              <p className="text-stone-500">Secure passwordless login with Magic Link.</p>
            </div>

            {step === 'INPUT' ? (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label className="block text-sm font-bold text-stone-700 mb-2">Email Address</label>
                  <div className="relative">
                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" size={18} />
                    <input 
                      type="email" 
                      required
                      placeholder="name@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full pl-12 pr-4 py-4 bg-stone-50 border border-stone-200 rounded-2xl outline-none focus:ring-2 focus:ring-rose-500 transition-all"
                    />
                  </div>
                </div>
                <button 
                  type="submit"
                  className="w-full bg-rose-500 text-white font-bold py-4 rounded-2xl flex items-center justify-center gap-2 hover:bg-rose-600 transition-all shadow-xl shadow-rose-200"
                >
                  Send Magic Link <ArrowRight size={18} />
                </button>
              </form>
            ) : (
              <div className="py-12 text-center space-y-4">
                <div className="w-16 h-16 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
                  <ShieldCheck size={32} />
                </div>
                <h3 className="text-xl font-bold">Link sent!</h3>
                <p className="text-stone-500">Check your inbox for a secure login link. It expires in 15 minutes.</p>
                <div className="pt-4 flex justify-center">
                   <div className="w-8 h-8 border-4 border-stone-200 border-t-rose-500 rounded-full animate-spin"></div>
                </div>
              </div>
            )}

            <p className="mt-8 text-center text-xs text-stone-400 leading-relaxed">
              By continuing, you agree to our Terms of Service and Privacy Policy. 
              We use Magic Links for your security and privacy.
            </p>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default AuthModal;
