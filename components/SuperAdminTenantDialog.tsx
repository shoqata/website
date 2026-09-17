import React, { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Building2, X, Save, Loader2, Receipt, Globe, Users } from 'lucide-react';
import { db } from '../services/firebase';
import { doc, updateDoc, addDoc, collection } from '@/services/supabase-bridge';
import { Tenant } from '../types';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

interface Props {
  tenant: any | null;
  domains: string[];
  memberCount: number;
  invoices: any[];
  onClose: () => void;
}

// Betreuung eines Vereins durch den Plattformbetreiber.
//
// Der Knopf "Verwalten" in der Uebersicht hatte bis hierher keine Funktion.
// Hier lassen sich Stammdaten, Plan, Status und vor allem die Gebuehren
// hinterlegen -- und daraus eine Rechnung an den Verein erzeugen.
const SuperAdminTenantDialog: React.FC<Props> = ({ tenant, domains, memberCount, invoices, onClose }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [form, setForm] = useState<any>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => { if (tenant) setForm({ currency: 'CHF', ...tenant }); }, [tenant]);

  // Alle Hooks stehen vor dem vorzeitigen Ausstieg. Stand useMemo darunter,
  // rendert React beim Oeffnen des Dialogs mehr Hooks als beim Schliessen --
  // und wirft. Genau das ist hier passiert.
  const ownInvoices = useMemo(
    () => (tenant ? invoices.filter((i) => i.tenantId === tenant.id) : []),
    [invoices, tenant]
  );

  if (!tenant) return null;

  const year = new Date().getFullYear();
  const set = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setForm((f: any) => ({ ...f, [k]: e.target.value }));
  const annualDone = ownInvoices.some((i) => i.kind === 'ANNUAL' && Number(i.year) === year && i.status !== 'CANCELLED');
  const setupDone = ownInvoices.some((i) => i.kind === 'SETUP' && i.status !== 'CANCELLED');

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, 'tenants', tenant.id), {
        name: form.name?.trim() || tenant.name,
        contactName: form.contactName?.trim() || '',
        contactEmail: form.contactEmail?.trim() || '',
        phone: form.phone?.trim() || '',
        subscriptionPlan: form.subscriptionPlan || 'FREE',
        subscriptionStatus: form.subscriptionStatus || 'ACTIVE',
        annualFee: form.annualFee === '' || form.annualFee === undefined ? null : Number(form.annualFee),
        setupFee: form.setupFee === '' || form.setupFee === undefined ? null : Number(form.setupFee),
        currency: form.currency || 'CHF',
        contractStart: form.contractStart || null,
        billingNote: form.billingNote?.trim() || '',
      } as any);
      showAlert({ type: 'success', message: t('sa.tenant_saved') });
      onClose();
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSaving(false);
    }
  };

  const createInvoice = async (kind: 'SETUP' | 'ANNUAL') => {
    const amount = kind === 'SETUP' ? Number(form.setupFee) : Number(form.annualFee);
    if (!(amount > 0)) { showAlert({ type: 'error', message: t('sa.fee_missing') }); return; }
    if (kind === 'ANNUAL' && annualDone) { showAlert({ type: 'error', message: t('sa.already_invoiced', { year }) }); return; }
    try {
      const due = new Date(); due.setDate(due.getDate() + 30);
      await addDoc(collection(db, 'platform_invoices'), {
        tenantId: tenant.id,
        kind,
        amount,
        currency: form.currency || 'CHF',
        year: kind === 'ANNUAL' ? year : null,
        status: 'DRAFT',
        invoiceNumber: `PF-${year}-${String(Date.now()).slice(-5)}`,
        issuedAt: new Date().toISOString().slice(0, 10),
        dueDate: due.toISOString().slice(0, 10),
      });
      showAlert({ type: 'success', message: t('sa.invoice_created') });
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const field = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors';
  const label = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  return (
    <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
      <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-3xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">

        <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
          <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2">
            <Building2 className="text-primary" size={20} /> {t('sa.manage_tenant')}
          </h3>
          <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={20} /></button>
        </div>

        <div className="p-8 space-y-6 overflow-y-auto custom-scrollbar">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div className="bg-stone-50 rounded-2xl p-4">
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-1 flex items-center gap-1"><Users size={11} /> {t('sa.members_count')}</p>
              <p className="font-bold text-xl text-stone-900">{memberCount}</p>
            </div>
            <div className="bg-stone-50 rounded-2xl p-4 col-span-2 md:col-span-3">
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-1 flex items-center gap-1"><Globe size={11} /> {t('sa.domains')}</p>
              <p className="text-xs text-stone-600 font-mono break-all">{domains.length ? domains.join(', ') : '—'}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div><label className={label}>{t('field.name')}</label>
              <input value={form.name || ''} onChange={set('name')} className={field} /></div>
            <div><label className={label}>{t('sa.contact_person')}</label>
              <input value={form.contactName || ''} onChange={set('contactName')} className={field} /></div>
            <div><label className={label}>{t('field.email')}</label>
              <input value={form.contactEmail || ''} onChange={set('contactEmail')} className={field} /></div>
            <div><label className={label}>{t('field.phone')}</label>
              <input value={form.phone || ''} onChange={set('phone')} className={field} /></div>
            <div><label className={label}>{t('sa.plan')}</label>
              <select value={form.subscriptionPlan || 'FREE'} onChange={set('subscriptionPlan')} className={field}>
                <option value="FREE">FREE</option><option value="PRO">PRO</option><option value="ENTERPRISE">ENTERPRISE</option>
              </select></div>
            <div><label className={label}>{t('field.status')}</label>
              <select value={form.subscriptionStatus || 'ACTIVE'} onChange={set('subscriptionStatus')} className={field}>
                <option value="ACTIVE">{t('status.active')}</option>
                <option value="PAST_DUE">{t('admin.finance.overdue')}</option>
                <option value="CANCELLED">{t('sa.istatus.CANCELLED')}</option>
              </select></div>
          </div>

          <div className="border-t border-stone-100 pt-6">
            <h4 className="font-bold text-stone-900 mb-4 flex items-center gap-2"><Receipt size={16} className="text-primary" /> {t('sa.fees')}</h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
              <div><label className={label}>{t('sa.annual_fee')}</label>
                <input type="number" min={0} step="0.05" value={form.annualFee ?? ''} onChange={set('annualFee')} className={field} placeholder="480" /></div>
              <div><label className={label}>{t('sa.setup_fee')}</label>
                <input type="number" min={0} step="0.05" value={form.setupFee ?? ''} onChange={set('setupFee')} className={field} placeholder="900" /></div>
              <div><label className={label}>{t('field.currency')}</label>
                <select value={form.currency || 'CHF'} onChange={set('currency')} className={field}>
                  <option value="CHF">CHF</option><option value="EUR">EUR</option>
                </select></div>
              <div><label className={label}>{t('sa.contract_start')}</label>
                <input type="date" value={form.contractStart || ''} onChange={set('contractStart')} className={field} /></div>
              <div className="md:col-span-2"><label className={label}>{t('sa.billing_note')}</label>
                <input value={form.billingNote || ''} onChange={set('billingNote')} className={field} /></div>
            </div>

            <div className="flex flex-wrap gap-3 mt-5">
              <button onClick={() => createInvoice('SETUP')} disabled={setupDone}
                className="px-5 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold hover:bg-black transition-colors disabled:opacity-40">
                {t('sa.create_setup_invoice')}
              </button>
              <button onClick={() => createInvoice('ANNUAL')} disabled={annualDone}
                className="px-5 py-2.5 bg-primary text-white rounded-xl text-xs font-bold hover:bg-rose-600 transition-colors disabled:opacity-40">
                {t('sa.create_annual_invoice', { year })}
              </button>
            </div>

            {ownInvoices.length > 0 && (
              <div className="mt-5 border border-stone-100 rounded-2xl overflow-hidden">
                <table className="w-full text-left text-xs">
                  <tbody className="divide-y divide-stone-50">
                    {ownInvoices.map((i) => (
                      <tr key={i.id}>
                        <td className="px-4 py-2.5 font-mono text-stone-400">{i.invoiceNumber}</td>
                        <td className="px-4 py-2.5">{t('sa.kind.' + i.kind)}{i.year ? ` ${i.year}` : ''}</td>
                        <td className="px-4 py-2.5 font-bold text-right">{Number(i.amount).toLocaleString()} {i.currency}</td>
                        <td className="px-4 py-2.5 text-right">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                            i.status === 'PAID' ? 'bg-emerald-100 text-emerald-700'
                            : i.status === 'SENT' ? 'bg-amber-100 text-amber-700' : 'bg-stone-100 text-stone-500'}`}>
                            {t('sa.istatus.' + i.status)}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
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

export default SuperAdminTenantDialog;
