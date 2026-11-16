
// Die Rueckmeldungsebene liegt bewusst ueber allem anderen.
//
// Sie lag auf z-300 und damit unter mehreren Dialogen -- unter anderem unter
// dem Verein-Dialog auf z-400. Eine Meldung, die dahinter erscheint, ist so
// gut wie keine: fuer den Benutzer "passiert nichts", obwohl das Programm
// sehr wohl geantwortet hat. Wer ueber alles berichtet, muss ueber allem
// liegen. Hoeher bleiben nur die Sperrbildschirme (z-9999 aufwaerts).

import React, { createContext, useContext, useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, CheckCircle2, AlertCircle, Info, AlertTriangle } from 'lucide-react';

type AlertType = 'success' | 'error' | 'info' | 'warning';

interface AlertOptions {
  title?: string;
  message: string;
  type?: AlertType;
  buttonText?: string;
  // Was genau geschah: Betrag, Empfaenger, Nummer. "Erfolg!" allein sagt
  // nicht, ob die richtige Rechnung an den richtigen Menschen ging.
  details?: { label: string; value: string }[];
  // Ein naechster Schritt neben dem Schliessen -- hoechstens einer, sonst
  // ist es keine Empfehlung mehr, sondern ein Menue.
  action?: { label: string; onClick: () => void };
}

// Fuer Umkehrbares: verschwindet von selbst und bietet "Rueckgaengig".
// Eine Einstellung zu speichern verlangt keinen Klick auf "OK".
interface ToastOptions {
  message: string;
  type?: 'success' | 'error';
  undo?: () => void | Promise<void>;
  undoLabel?: string;
}

interface ConfirmOptions {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: 'danger' | 'neutral' | 'primary';
}

interface PromptOptions {
  title?: string;
  message: string;
  placeholder?: string;
  confirmText?: string;
  cancelText?: string;
}

interface FeedbackContextType {
  showAlert: (options: AlertOptions) => Promise<void>;
  showConfirm: (options: ConfirmOptions) => Promise<boolean>;
  showPrompt: (options: PromptOptions) => Promise<string | null>;
  showToast: (options: ToastOptions) => void;
}

const FeedbackContext = createContext<FeedbackContextType | undefined>(undefined);

export const useFeedback = () => {
  const context = useContext(FeedbackContext);
  if (!context) throw new Error('useFeedback must be used within a FeedbackProvider');
  return context;
};

export const FeedbackProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Alert State
  const [alertState, setAlertState] = useState<{ isOpen: boolean; options: AlertOptions; resolve: () => void } | null>(null);
  
  // Confirm State
  const [confirmState, setConfirmState] = useState<{ isOpen: boolean; options: ConfirmOptions; resolve: (val: boolean) => void } | null>(null);

  // Prompt State
  const [promptState, setPromptState] = useState<{ isOpen: boolean; options: PromptOptions; value: string; resolve: (val: string | null) => void } | null>(null);

  // Toast: eine Meldung zur Zeit. Eine neue ersetzt die alte, statt sich
  // darueberzustapeln -- wer zehnmal "bezahlt" klickt, braucht nur die
  // letzte Rueckgaengig-Moeglichkeit vor Augen.
  const [toast, setToast] = useState<(ToastOptions & { id: number }) | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const showToast = useCallback((options: ToastOptions) => {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    const id = Date.now();
    setToast({ ...options, id });
    // Mit Rueckgaengig etwas laenger: man muss lesen UND entscheiden.
    toastTimer.current = setTimeout(() => setToast(null), options.undo ? 7000 : 3500);
  }, []);

  const showAlert = useCallback((options: AlertOptions) => {
    return new Promise<void>((resolve) => {
      setAlertState({ isOpen: true, options, resolve });
    });
  }, []);

  const showConfirm = useCallback((options: ConfirmOptions) => {
    return new Promise<boolean>((resolve) => {
      setConfirmState({ isOpen: true, options, resolve });
    });
  }, []);

  const showPrompt = useCallback((options: PromptOptions) => {
    return new Promise<string | null>((resolve) => {
      setPromptState({ isOpen: true, options, value: '', resolve });
    });
  }, []);

  const closeAlert = () => {
    if (alertState) {
      setAlertState(prev => prev ? { ...prev, isOpen: false } : null);
      // Sofort antworten: wer "Loeschen?" bestaetigt, wartete sonst 200 ms
      // auf das Ende der Ausblendung. Abgeraeumt wird erst danach.
      alertState.resolve();
      setTimeout(() => setAlertState(null), 200);
    }
  };

  const closeConfirm = (result: boolean) => {
    if (confirmState) {
      setConfirmState(prev => prev ? { ...prev, isOpen: false } : null);
      // Sofort antworten: wer "Loeschen?" bestaetigt, wartete sonst 200 ms
      // auf das Ende der Ausblendung. Abgeraeumt wird erst danach.
      confirmState.resolve(result);
      setTimeout(() => setConfirmState(null), 200);
    }
  };

  const closePrompt = (result: string | null) => {
    if (promptState) {
      setPromptState(prev => prev ? { ...prev, isOpen: false } : null);
      // Sofort antworten: wer "Loeschen?" bestaetigt, wartete sonst 200 ms
      // auf das Ende der Ausblendung. Abgeraeumt wird erst danach.
      promptState.resolve(result);
      setTimeout(() => setPromptState(null), 200);
    }
  };

  // Helper to get Icon based on type
  const getIcon = (type?: AlertType | 'danger' | 'neutral' | 'primary') => {
    switch (type) {
      case 'success': return <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600 mb-4"><CheckCircle2 size={24} /></div>;
      case 'error': 
      case 'danger': return <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center text-red-600 mb-4"><AlertCircle size={24} /></div>;
      case 'warning': return <div className="w-12 h-12 rounded-full bg-amber-100 flex items-center justify-center text-amber-600 mb-4"><AlertTriangle size={24} /></div>;
      default: return <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 mb-4"><Info size={24} /></div>;
    }
  };

  return (
    <FeedbackContext.Provider value={{ showAlert, showConfirm, showPrompt, showToast }}>
      {children}

      {/* ALERT MODAL */}
      <AnimatePresence>
        {alertState && alertState.isOpen && (
          <div className="fixed inset-0 z-[9000] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} 
              className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" 
              onClick={closeAlert} 
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.95, y: 10 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="bg-white rounded-[2rem] p-8 max-w-sm w-full shadow-2xl relative z-10 text-center"
            >
              {getIcon(alertState.options.type)}
              {alertState.options.title && <h3 className="text-xl font-bold text-stone-900 mb-2">{alertState.options.title}</h3>}
              <p className={`text-stone-500 ${alertState.options.details?.length ? 'mb-4' : 'mb-8'}`}>{alertState.options.message}</p>
              {!!alertState.options.details?.length && (
                <dl className="mb-6 text-left text-sm rounded-xl border border-stone-100 divide-y divide-stone-100">
                  {alertState.options.details.map(d => (
                    <div key={d.label} className="flex justify-between gap-4 px-4 py-2">
                      <dt className="text-stone-400 shrink-0">{d.label}</dt>
                      <dd className="font-semibold text-stone-800 text-right break-all">{d.value}</dd>
                    </div>
                  ))}
                </dl>
              )}
              {alertState.options.action && (
                <button
                  onClick={() => { const a = alertState.options.action!; closeAlert(); a.onClick(); }}
                  className="w-full mb-2 bg-[color:var(--primary,#1c1917)] text-white font-bold py-3 rounded-xl hover:opacity-90 transition"
                >
                  {alertState.options.action.label}
                </button>
              )}
              <button 
                onClick={closeAlert}
                className={alertState.options.action
                  ? 'w-full text-stone-600 font-bold py-3 rounded-xl hover:bg-stone-100 transition-colors'
                  : 'w-full bg-stone-900 text-white font-bold py-3 rounded-xl hover:bg-stone-800 transition-colors'}
              >
                {alertState.options.buttonText || 'OK'}
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* TOAST */}
      <AnimatePresence>
        {toast && (
          <motion.div key={toast.id} role="status" aria-live="polite"
            initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 16 }}
            className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[9000] w-[calc(100%-2rem)] max-w-md bg-stone-900 text-white rounded-2xl shadow-2xl px-4 py-3 flex items-center gap-3">
            {toast.type === 'error'
              ? <AlertCircle size={18} className="text-red-400 shrink-0" />
              : <CheckCircle2 size={18} className="text-emerald-400 shrink-0" />}
            <p className="text-sm flex-1">{toast.message}</p>
            {toast.undo && (
              <button onClick={async () => { const u = toast.undo!; setToast(null); await u(); }}
                className="text-sm font-bold text-emerald-300 hover:text-emerald-200 px-2 py-1 rounded-lg shrink-0">
                {toast.undoLabel || 'Undo'}
              </button>
            )}
            <button onClick={() => setToast(null)} aria-label="Schliessen" className="text-stone-400 hover:text-white shrink-0"><X size={16} /></button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* CONFIRM MODAL */}
      <AnimatePresence>
        {confirmState && confirmState.isOpen && (
          <div className="fixed inset-0 z-[9000] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} 
              className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" 
              onClick={() => closeConfirm(false)} 
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.95, y: 10 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="bg-white rounded-[2rem] p-8 max-w-md w-full shadow-2xl relative z-10"
            >
              <div className="flex items-start gap-4">
                 {getIcon(confirmState.options.type || 'neutral')}
                 <div className="flex-1 text-left">
                    <h3 className="text-xl font-bold text-stone-900 mb-2">{confirmState.options.title || 'Confirm'}</h3>
                    <p className="text-stone-500 text-sm leading-relaxed mb-6">{confirmState.options.message}</p>
                 </div>
              </div>
              <div className="flex gap-3 justify-end">
                <button 
                  onClick={() => closeConfirm(false)}
                  className="px-6 py-3 bg-stone-100 text-stone-600 font-bold rounded-xl hover:bg-stone-200 transition-colors"
                >
                  {confirmState.options.cancelText || 'Cancel'}
                </button>
                <button 
                  onClick={() => closeConfirm(true)}
                  className={`px-6 py-3 text-white font-bold rounded-xl transition-colors shadow-lg ${confirmState.options.type === 'danger' ? 'bg-red-500 hover:bg-red-600 shadow-red-200' : 'bg-blue-600 hover:bg-blue-700 shadow-blue-200'}`}
                >
                  {confirmState.options.confirmText || 'Confirm'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* PROMPT MODAL */}
      <AnimatePresence>
        {promptState && promptState.isOpen && (
          <div className="fixed inset-0 z-[9000] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} 
              className="absolute inset-0 bg-stone-900/60 backdrop-blur-sm" 
              onClick={() => closePrompt(null)} 
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.95, y: 10 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="bg-white rounded-[2rem] p-8 max-w-md w-full shadow-2xl relative z-10"
            >
              <h3 className="text-xl font-bold text-stone-900 mb-2">{promptState.options.title || 'Input Required'}</h3>
              <p className="text-stone-500 text-sm mb-6">{promptState.options.message}</p>
              
              <input 
                autoFocus
                type="text"
                value={promptState.value}
                onChange={(e) => setPromptState(prev => prev ? { ...prev, value: e.target.value } : null)}
                placeholder={promptState.options.placeholder}
                className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl mb-6 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium"
                onKeyDown={(e) => {
                    if (e.key === 'Enter') closePrompt(promptState.value);
                    if (e.key === 'Escape') closePrompt(null);
                }}
              />

              <div className="flex gap-3 justify-end">
                <button 
                  onClick={() => closePrompt(null)}
                  className="px-6 py-3 bg-stone-100 text-stone-600 font-bold rounded-xl hover:bg-stone-200 transition-colors"
                >
                  {promptState.options.cancelText || 'Cancel'}
                </button>
                <button 
                  onClick={() => closePrompt(promptState.value)}
                  className="px-6 py-3 bg-stone-900 text-white font-bold rounded-xl hover:bg-stone-800 transition-colors shadow-lg"
                >
                  {promptState.options.confirmText || 'Submit'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </FeedbackContext.Provider>
  );
};
