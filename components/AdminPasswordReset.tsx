import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { KeyRound, X, Loader2, Copy, Check, ShieldAlert } from 'lucide-react';
import { resetMemberPassword } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { hasUsableEmail } from '../lib/memberEmail';

interface Props {
  member: any | null;
  onClose: () => void;
}

// Voruebergehendes Passwort fuer ein Mitglied.
//
// Der Ablauf ist bewusst zweistufig: erst die Frage, dann das Passwort. Es
// wird genau einmal gezeigt und nirgends gespeichert -- weder hier noch im
// Mitgliederdatensatz. Wer es verpasst, setzt eben noch einmal zurueck. Das
// ist unbequemer als ein Passwort, das man spaeter nachlesen kann, und genau
// deshalb richtig.
const AdminPasswordReset: React.FC<Props> = ({ member, onClose }) => {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);

  if (!member) return null;

  const usable = hasUsableEmail(member);

  const run = async () => {
    setBusy(true); setError('');
    try {
      setResult(await resetMemberPassword(member.id));
    } catch (e: any) {
      setError(e?.message || '?');
    } finally {
      setBusy(false);
    }
  };

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(result.password);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch { /* Zwischenablage gesperrt -- das Passwort steht ja lesbar da. */ }
  };

  return (
    <div className="fixed inset-0 z-[500] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
      <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden">

        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
          <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2">
            <KeyRound size={18} className="text-primary" /> {t('pw.title')}
          </h3>
          <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={18} /></button>
        </div>

        <div className="p-8 space-y-5">
          <div>
            <p className="font-bold text-stone-900">{member.displayName || member.email}</p>
            <p className="text-xs text-stone-500">{member.email}</p>
          </div>

          {!usable && !result && (
            <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex gap-2.5 text-amber-800">
              <ShieldAlert size={16} className="mt-0.5 shrink-0" />
              <p className="text-xs leading-relaxed">{t('pw.no_email')}</p>
            </div>
          )}

          {!result && usable && (
            <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl">
              <p className="text-xs text-stone-600 leading-relaxed">{t('pw.explain')}</p>
            </div>
          )}

          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 leading-relaxed">{error}</div>
          )}

          {result && (
            <div className="space-y-4">
              <div className="p-5 bg-emerald-50 border-2 border-emerald-200 rounded-2xl">
                <p className="text-[10px] font-bold text-emerald-700 uppercase tracking-widest mb-2">
                  {result.created ? t('pw.created') : t('pw.new_password')}
                </p>
                <div className="flex items-center gap-3">
                  <code className="flex-1 text-xl font-mono font-bold text-stone-900 tracking-wider select-all break-all">
                    {result.password}
                  </code>
                  <button onClick={copy} title={t('common.copy')}
                    className="p-2.5 bg-white border border-emerald-300 rounded-xl text-emerald-700 hover:bg-emerald-100 transition-colors shrink-0">
                    {copied ? <Check size={16} /> : <Copy size={16} />}
                  </button>
                </div>
              </div>
              <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex gap-2.5 text-amber-800">
                <ShieldAlert size={16} className="mt-0.5 shrink-0" />
                <p className="text-xs leading-relaxed">{t('pw.once_warning')}</p>
              </div>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
          <button onClick={onClose} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">
            {result ? t('common.close') : t('common.cancel')}
          </button>
          {!result && (
            <button onClick={run} disabled={busy || !usable}
              className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed">
              {busy ? <Loader2 size={16} className="animate-spin" /> : <KeyRound size={16} />} {t('pw.action')}
            </button>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default AdminPasswordReset;
