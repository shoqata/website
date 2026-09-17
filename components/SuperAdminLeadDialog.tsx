import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Briefcase, X, Save, Loader2, Trash2, Mail, Phone, ArrowRight } from 'lucide-react';
import { db } from '../services/firebase';
import { doc, updateDoc, deleteDoc } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

const STAGES = ['LEAD', 'TALKS', 'ONBOARDING', 'WON', 'LOST'] as const;

interface Props {
  lead: any | null;
  onClose: () => void;
}

// Ein Interessent im Einzelnen.
//
// Vorher liess sich nur die Notiz ueber eine Eingabeaufforderung aendern --
// zu wenig, um ein Gespraech ueber Wochen zu begleiten.
const SuperAdminLeadDialog: React.FC<Props> = ({ lead, onClose }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [form, setForm] = useState<any>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => { if (lead) setForm({ ...lead }); }, [lead]);
  if (!lead) return null;

  const set = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setForm((f: any) => ({ ...f, [k]: e.target.value }));

  const handleSave = async () => {
    if (!form.name?.trim()) { showAlert({ type: 'error', message: t('sa.lead_name') }); return; }
    setSaving(true);
    try {
      await updateDoc(doc(db, 'platform_leads', lead.id), {
        name: form.name.trim(),
        contactName: form.contactName?.trim() || null,
        email: form.email?.trim() || null,
        phone: form.phone?.trim() || null,
        city: form.city?.trim() || null,
        stage: form.stage || 'LEAD',
        expectedMembers: form.expectedMembers === '' || form.expectedMembers === undefined || form.expectedMembers === null
          ? null : Number(form.expectedMembers),
        note: form.note?.trim() || null,
        updatedAt: new Date().toISOString(),
      } as any);
      showAlert({ type: 'success', message: t('sa.lead_saved') });
      onClose();
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    const ok = await showConfirm({
      title: form.name || t('sa.lead_new'),
      message: t('admin.delete_permanent'),
      confirmText: t('common.delete'),
      type: 'danger',
    });
    if (!ok) return;
    try {
      await deleteDoc(doc(db, 'platform_leads', lead.id));
      showAlert({ type: 'success', message: t('sa.lead_deleted') });
      onClose();
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const field = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors';
  const label = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  return (
    <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
      <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">

        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
          <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
            <Briefcase className="text-primary" size={20} /> {form.name || t('sa.lead_new')}
          </h3>
          <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={20} /></button>
        </div>

        <div className="p-8 space-y-5 overflow-y-auto custom-scrollbar">
          {/* Stand des Gespraechs, direkt umschaltbar */}
          <div>
            <label className={label}>{t('sa.move_to')}</label>
            <div className="flex flex-wrap gap-2">
              {STAGES.map((st) => (
                <button key={st} type="button" onClick={() => setForm((f: any) => ({ ...f, stage: st }))}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-colors border ${
                    (form.stage || 'LEAD') === st
                      ? 'bg-stone-900 text-white border-stone-900'
                      : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                  {t('sa.stage.' + st)}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="md:col-span-2">
              <label className={label}>{t('sa.lead_name')} *</label>
              <input value={form.name || ''} onChange={set('name')} className={field} />
            </div>
            <div>
              <label className={label}>{t('sa.contact_person')}</label>
              <input value={form.contactName || ''} onChange={set('contactName')} className={field} />
            </div>
            <div>
              <label className={label}>{t('field.city')}</label>
              <input value={form.city || ''} onChange={set('city')} className={field} placeholder={t('ph.city_short')} />
            </div>
            <div>
              <label className={label}>{t('field.email')}</label>
              <input value={form.email || ''} onChange={set('email')} className={field} placeholder={t('ph.email_example')} />
            </div>
            <div>
              <label className={label}>{t('field.phone')}</label>
              <input value={form.phone || ''} onChange={set('phone')} className={field} placeholder={t('ph.phone')} />
            </div>
            <div>
              <label className={label}>{t('sa.expected_members')}</label>
              <input type="number" min={0} value={form.expectedMembers ?? ''} onChange={set('expectedMembers')}
                     className={field} placeholder="150" />
              <p className="text-[10px] text-stone-400 mt-1.5 italic">{t('sa.expected_hint')}</p>
            </div>
          </div>

          <div>
            <label className={label}>{t('sa.lead_note')}</label>
            <textarea value={form.note || ''} onChange={set('note')} rows={6}
                      className={field + ' resize-none'} placeholder={t('sa.lead_note_ph')} />
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-stone-100">
            <div className="flex flex-wrap gap-3">
              {form.email && (
                <a href={`mailto:${form.email}`} className="text-xs font-bold text-stone-500 hover:text-primary flex items-center gap-1.5">
                  <Mail size={13} /> {form.email}
                </a>
              )}
              {form.phone && (
                <a href={`tel:${form.phone}`} className="text-xs font-bold text-stone-500 hover:text-primary flex items-center gap-1.5">
                  <Phone size={13} /> {form.phone}
                </a>
              )}
            </div>
            <button onClick={handleDelete}
                    className="flex items-center gap-1.5 text-red-500 hover:text-red-700 font-bold text-xs transition-colors">
              <Trash2 size={13} /> {t('common.delete')}
            </button>
          </div>
        </div>

        <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
          <button onClick={onClose} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button>
          <button onClick={handleSave} disabled={saving}
            className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
            {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />} {t('common.save_changes')}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

export default SuperAdminLeadDialog;
