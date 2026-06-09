
import React, { createContext, useContext, useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, CheckCircle2, AlertCircle, Info, AlertTriangle } from 'lucide-react';

type AlertType = 'success' | 'error' | 'info' | 'warning';

interface AlertOptions {
  title?: string;
  message: string;
  type?: AlertType;
  buttonText?: string;
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
      setTimeout(() => {
        alertState.resolve();
        setAlertState(null);
      }, 200);
    }
  };

  const closeConfirm = (result: boolean) => {
    if (confirmState) {
      setConfirmState(prev => prev ? { ...prev, isOpen: false } : null);
      setTimeout(() => {
        confirmState.resolve(result);
        setConfirmState(null);
      }, 200);
    }
  };

  const closePrompt = (result: string | null) => {
    if (promptState) {
      setPromptState(prev => prev ? { ...prev, isOpen: false } : null);
      setTimeout(() => {
        promptState.resolve(result);
        setPromptState(null);
      }, 200);
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
    <FeedbackContext.Provider value={{ showAlert, showConfirm, showPrompt }}>
      {children}

      {/* ALERT MODAL */}
      <AnimatePresence>
        {alertState && alertState.isOpen && (
          <div className="fixed inset-0 z-[300] flex items-center justify-center p-6">
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
              <p className="text-stone-500 mb-8">{alertState.options.message}</p>
              <button 
                onClick={closeAlert}
                className="w-full bg-stone-900 text-white font-bold py-3 rounded-xl hover:bg-stone-800 transition-colors"
              >
                {alertState.options.buttonText || 'OK'}
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* CONFIRM MODAL */}
      <AnimatePresence>
        {confirmState && confirmState.isOpen && (
          <div className="fixed inset-0 z-[300] flex items-center justify-center p-6">
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
          <div className="fixed inset-0 z-[300] flex items-center justify-center p-6">
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
