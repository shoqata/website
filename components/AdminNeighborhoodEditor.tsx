import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { MapPin, X, Save, Loader2, Trash2 } from 'lucide-react';
import { db } from '../services/firebase';
import { addDoc, collection, doc, updateDoc, deleteDoc } from '@/services/supabase-bridge';
import { Neighborhood, UserProfile } from '../types';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

interface Props {
  neighborhood: Partial<Neighborhood> | null;   // null = Dialog geschlossen
  users: UserProfile[];
  memberCount: number;
  onClose: () => void;
}

// Bearbeiten einer Nachbarschaft.
//
// Das Zahnrad in der Uebersicht hat bisher einen Zustand gesetzt, den nichts
// gelesen hat -- der Dialog fehlte schlicht. Hier ist er.
const AdminNeighborhoodEditor: React.FC<Props> = ({ neighborhood, users, memberCount, onClose }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [form, setForm] = useState<Partial<Neighborhood>>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (neighborhood) setForm({ status: 'ACTIVE', ...neighborhood });
  }, [neighborhood]);

  if (!neighborhood) return null;

  const isNew = !form.id;
  const set = (k: keyof Neighborhood) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
      setForm((f) => ({ ...f, [k]: e.target.value }));

  // Als Verantwortliche kommen alle aktiven Personen infrage, nicht nur die
  // Mitglieder dieser Nachbarschaft -- oft betreut jemand von aussen mit.
  const candidates = users
    .filter((u) => u.membershipStatus !== 'INACTIVE')
    .sort((a, b) => (a.displayName || '').localeCompare(b.displayName || ''));

  const handleSave = async () => {
    if (!form.name?.trim()) {
      showAlert({ type: 'error', message: t('admin.nb.name_required') });
      return;
    }
    setSaving(true);
    try {
      const payload: any = {
        name: form.name.trim(),
        city: form.city?.trim() || '',
        description: form.description?.trim() || '',
        managerId: form.managerId || '',
        contactEmail: form.contactEmail?.trim() || '',
        contactPhone: form.contactPhone?.trim() || '',
        website: form.website?.trim() || '',
        image: form.image?.trim() || '',
        status: form.status || 'ACTIVE',
        lastActivity: new Date().toISOString(),
      };

      if (isNew) {
        await addDoc(collection(db, 'neighborhoods'), {
          ...payload,
          memberCount: 0,
          createdAt: new Date().toISOString(),
        });
        showAlert({ type: 'success', message: t('admin.nb.created') });
      } else {
        await updateDoc(doc(db, 'neighborhoods', form.id!), payload);
        showAlert({ type: 'success', message: t('admin.nb.saved') });
      }
      onClose();
    } catch (e: any) {
      console.error('[AdminNeighborhoodEditor] Speichern fehlgeschlagen:', e);
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!form.id) return;
    // Loeschen nur, wenn niemand mehr daran haengt -- sonst verlieren die
    // Mitglieder ihre Zuordnung und die Datenbank weist es ohnehin zurueck.
    if (memberCount > 0) {
      showAlert({ type: 'error', message: t('admin.nb.delete_blocked', { count: memberCount }) });
      return;
    }
    const ok = await showConfirm({
      title: t('admin.nb.delete_title'),
      message: t('admin.delete_permanent'),
      confirmText: t('common.delete'),
      type: 'danger',
    });
    if (!ok) return;
    try {
      await deleteDoc(doc(db, 'neighborhoods', form.id));
      showAlert({ type: 'success', message: t('admin.deleted') });
      onClose();
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const field = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors';
  const label = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  return (
    <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
      <motion.div
        initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]"
      >
        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
          <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
            <MapPin className="text-primary" size={20} />
            {isNew ? t('admin.nb.new') : t('admin.nb.edit')}
          </h3>
          <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 transition-colors">
            <X size={20} />
          </button>
        </div>

        <div className="p-8 space-y-5 overflow-y-auto custom-scrollbar">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className={label}>{t('admin.nb.name')} *</label>
              <input value={form.name || ''} onChange={set('name')} className={field} />
            </div>
            <div>
              <label className={label}>{t('field.city')}</label>
              <input value={form.city || ''} onChange={set('city')} className={field} placeholder={t('ph.city_short')} />
            </div>
          </div>

          <div>
            <label className={label}>{t('field.description')}</label>
            <textarea value={form.description || ''} onChange={set('description')} rows={3}
                      className={field + ' resize-none'} />
          </div>

          <div>
            <label className={label}>{t('admin.nb.manager')}</label>
            <select value={form.managerId || ''} onChange={set('managerId')} className={field}>
              <option value="">{t('admin.nb.no_manager')}</option>
              {candidates.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.displayName || u.email}{u.role !== 'MEMBER' ? ` · ${t('role.' + u.role.toLowerCase())}` : ''}
                </option>
              ))}
            </select>
            <p className="text-[10px] text-stone-400 mt-1.5 italic">{t('admin.nb.manager_hint')}</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className={label}>{t('field.email')}</label>
              <input value={form.contactEmail || ''} onChange={set('contactEmail')} className={field}
                     placeholder={t('ph.email_example')} />
            </div>
            <div>
              <label className={label}>{t('field.phone')}</label>
              <input value={form.contactPhone || ''} onChange={set('contactPhone')} className={field}
                     placeholder={t('ph.phone')} />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className={label}>{t('sponsor.website')}</label>
              <input value={form.website || ''} onChange={set('website')} className={field} placeholder="https://..." />
            </div>
            <div>
              <label className={label}>{t('field.image_url')}</label>
              <input value={form.image || ''} onChange={set('image')} className={field} placeholder="https://..." />
            </div>
          </div>

          <div>
            <label className={label}>{t('field.status')}</label>
            <select value={form.status || 'ACTIVE'} onChange={set('status')} className={field}>
              <option value="ACTIVE">{t('status.active')}</option>
              <option value="INACTIVE">{t('status.inactive')}</option>
            </select>
          </div>

          {!isNew && (
            <div className="pt-2 flex items-center justify-between text-xs text-stone-400">
              <span>{t('admin.members.count')}: <b className="text-stone-700">{memberCount}</b></span>
              <button onClick={handleDelete}
                      className="flex items-center gap-1.5 text-red-500 hover:text-red-700 font-bold transition-colors">
                <Trash2 size={13} /> {t('common.delete')}
              </button>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
          <button onClick={onClose} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">
            {t('common.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving}
                  className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
            {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
            {t('common.save_changes')}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

export default AdminNeighborhoodEditor;
