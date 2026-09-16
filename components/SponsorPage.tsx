import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Handshake, Check, ArrowRight, ArrowLeft, Loader2, ShieldCheck } from 'lucide-react';
import { submitSponsor } from '../services/firebase';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { SPONSOR_PACKAGES, packageByKey, SponsorPackageKey } from '../lib/sponsorPackages';

type Step = 1 | 2 | 3;

const SponsorPage: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();

  const [step, setStep] = useState<Step>(1);
  const [selected, setSelected] = useState<SponsorPackageKey | null>(null);
  const [customAmount, setCustomAmount] = useState('');
  const [sending, setSending] = useState(false);
  const [form, setForm] = useState({
    company: '', contactName: '', email: '', phone: '',
    street: '', zip: '', city: '', country: 'Schweiz',
    website: '', message: '',
  });

  const pkg = useMemo(() => packageByKey(selected || undefined), [selected]);
  const amount = pkg?.amount ?? (customAmount ? Number(customAmount) : null);

  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));

  const goToDetails = () => {
    if (!selected) { showAlert({ type: 'error', message: t('sponsor.pick_package') }); return; }
    if (selected === 'CUSTOM' && !(Number(customAmount) > 0)) {
      showAlert({ type: 'error', message: t('sponsor.need_amount') }); return;
    }
    setStep(2);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (sending || !selected) return;
    setSending(true);
    try {
      await submitSponsor({
        packageKey: selected,
        amount: amount ?? null,
        company: form.company,
        contactName: form.contactName,
        email: form.email,
        phone: form.phone,
        street: form.street,
        zip: form.zip,
        city: form.city,
        country: form.country,
        website: form.website,
        message: form.message,
      });
      setStep(3);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err: any) {
      showAlert({ type: 'error', message: t('sponsor.error', { reason: err?.message || '?' }) });
    } finally {
      setSending(false);
    }
  };

  const steps: { n: Step; label: string }[] = [
    { n: 1, label: t('sponsor.step1') },
    { n: 2, label: t('sponsor.step2') },
    { n: 3, label: t('sponsor.step3') },
  ];

  const field =
    'w-full p-3.5 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors';
  const label = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-20">
      <div className="max-w-4xl mx-auto px-6">

        <div className="flex items-start gap-4 mb-10">
          <div className="w-12 h-12 rounded-2xl bg-rose-50 text-primary flex items-center justify-center shrink-0">
            <Handshake size={22} />
          </div>
          <div>
            <h1 className="font-display text-3xl md:text-4xl font-bold italic text-stone-900 mb-1">{t('sponsor.title')}</h1>
            <p className="text-stone-500 italic">{t('sponsor.subtitle')}</p>
          </div>
        </div>

        {/* Schrittanzeige */}
        <div className="flex items-center gap-3 mb-12">
          {steps.map((s, i) => (
            <React.Fragment key={s.n}>
              <div className="flex items-center gap-2.5">
                <div className={`w-7 h-7 rounded-full grid place-items-center text-xs font-bold transition-colors ${
                  step >= s.n ? 'bg-stone-900 text-white' : 'bg-stone-200 text-stone-500'
                }`}>
                  {step > s.n ? <Check size={13} /> : s.n}
                </div>
                <span className={`text-sm font-medium hidden sm:block ${step >= s.n ? 'text-stone-900' : 'text-stone-400'}`}>
                  {s.label}
                </span>
              </div>
              {i < steps.length - 1 && <div className="flex-1 h-px bg-stone-200" />}
            </React.Fragment>
          ))}
        </div>

        {/* Schritt 1 — Paket */}
        {step === 1 && (
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}>
            <h2 className="font-bold text-xl text-stone-900 mb-6">{t('sponsor.choose')}</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {SPONSOR_PACKAGES.map((p) => {
                const active = selected === p.key;
                return (
                  <button
                    type="button"
                    key={p.key}
                    onClick={() => setSelected(p.key)}
                    aria-pressed={active}
                    className={`text-left bg-white rounded-3xl border-2 p-7 transition-all ${
                      active ? 'border-primary shadow-lg shadow-rose-100' : 'border-stone-100 hover:border-stone-300'
                    }`}
                  >
                    <div className="flex justify-between items-start gap-4 mb-4">
                      <h3 className="font-bold text-lg text-stone-900">{t(p.titleKey)}</h3>
                      {p.amount !== null && (
                        <span className="font-bold text-stone-900 whitespace-nowrap">CHF {p.amount}</span>
                      )}
                    </div>
                    <ul className="space-y-2">
                      {p.benefitKeys.map((b) => (
                        <li key={b} className="flex gap-2.5 text-sm text-stone-500 leading-relaxed">
                          <span className={`mt-1.5 w-1.5 h-1.5 rounded-full shrink-0 ${active ? 'bg-primary' : 'bg-stone-300'}`} />
                          {t(b)}
                        </li>
                      ))}
                    </ul>

                    {p.key === 'CUSTOM' && active && (
                      <div className="mt-5" onClick={(e) => e.stopPropagation()}>
                        <label className={label}>{t('sponsor.custom_amount')}</label>
                        <input
                          type="number" min={1} step={1} inputMode="numeric"
                          value={customAmount}
                          onChange={(e) => setCustomAmount(e.target.value)}
                          className={field}
                          placeholder="750"
                        />
                      </div>
                    )}

                    {active && p.key !== 'CUSTOM' && (
                      <p className="mt-5 text-[10px] font-bold uppercase tracking-widest text-primary flex items-center gap-1.5">
                        <Check size={12} /> {t('sponsor.selected')}
                      </p>
                    )}
                  </button>
                );
              })}
            </div>

            <div className="flex justify-end mt-10">
              <button
                onClick={goToDetails}
                className="bg-primary text-white px-8 py-4 rounded-2xl font-bold text-sm flex items-center gap-2 shadow-lg shadow-rose-200 hover:bg-rose-600 transition-colors"
              >
                {t('common.next')} <ArrowRight size={16} />
              </button>
            </div>
          </motion.div>
        )}

        {/* Schritt 2 — Kontakt */}
        {step === 2 && (
          <motion.form initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} onSubmit={handleSubmit}>
            <div className="bg-white rounded-3xl border border-stone-100 p-8 mb-6">
              <div className="flex justify-between items-center pb-5 mb-6 border-b border-stone-100">
                <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                  {t('sponsor.package_label')}
                </span>
                <span className="font-bold text-stone-900">
                  {pkg ? t(pkg.titleKey) : ''}{amount ? ` · CHF ${amount}` : ''}
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className={label}>{t('sponsor.company')} *</label>
                  <input required value={form.company} onChange={set('company')} className={field} />
                </div>
                <div>
                  <label className={label}>{t('sponsor.contact')} *</label>
                  <input required value={form.contactName} onChange={set('contactName')} className={field} />
                </div>
                <div>
                  <label className={label}>{t('field.email')} *</label>
                  <input required type="email" value={form.email} onChange={set('email')} className={field}
                         placeholder={t('ph.email_example')} />
                </div>
                <div>
                  <label className={label}>{t('field.phone')}</label>
                  <input value={form.phone} onChange={set('phone')} className={field} placeholder={t('ph.phone')} />
                </div>
                <div className="md:col-span-2">
                  <label className={label}>{t('field.street')}</label>
                  <input value={form.street} onChange={set('street')} className={field} placeholder={t('ph.street')} />
                </div>
                <div className="grid grid-cols-3 gap-3 md:col-span-2">
                  <div>
                    <label className={label}>{t('field.zip')}</label>
                    <input value={form.zip} onChange={set('zip')} className={field} placeholder={t('ph.zip')} />
                  </div>
                  <div>
                    <label className={label}>{t('field.city')}</label>
                    <input value={form.city} onChange={set('city')} className={field} placeholder={t('ph.city')} />
                  </div>
                  <div>
                    <label className={label}>{t('field.country')}</label>
                    <input value={form.country} onChange={set('country')} className={field} />
                  </div>
                </div>
                <div className="md:col-span-2">
                  <label className={label}>{t('sponsor.website')}</label>
                  <input value={form.website} onChange={set('website')} className={field} placeholder="https://..." />
                </div>
                <div className="md:col-span-2">
                  <label className={label}>{t('sponsor.message')}</label>
                  <textarea value={form.message} onChange={set('message')} rows={4}
                            className={field + ' resize-none'} placeholder={t('sponsor.message_ph')} />
                </div>
              </div>

              <p className="flex items-start gap-2 text-xs text-stone-400 mt-6 leading-relaxed">
                <ShieldCheck size={14} className="text-stone-300 shrink-0 mt-0.5" />
                {t('sponsor.privacy_hint')}
              </p>
            </div>

            <div className="flex justify-between items-center">
              <button type="button" onClick={() => setStep(1)}
                      className="px-6 py-4 text-stone-500 font-bold text-sm flex items-center gap-2 hover:text-stone-900 transition-colors">
                <ArrowLeft size={16} /> {t('common.back')}
              </button>
              <button type="submit" disabled={sending}
                      className="bg-primary text-white px-8 py-4 rounded-2xl font-bold text-sm flex items-center gap-2 shadow-lg shadow-rose-200 hover:bg-rose-600 transition-colors disabled:opacity-60">
                {sending ? <><Loader2 size={16} className="animate-spin" /> {t('sponsor.sending')}</>
                         : <>{t('sponsor.submit')} <ArrowRight size={16} /></>}
              </button>
            </div>
          </motion.form>
        )}

        {/* Schritt 3 — Bestaetigung */}
        {step === 3 && (
          <motion.div initial={{ opacity: 0, scale: 0.97 }} animate={{ opacity: 1, scale: 1 }}
                      className="bg-white rounded-3xl border border-stone-100 p-12 text-center">
            <div className="w-16 h-16 rounded-full bg-emerald-50 text-emerald-600 grid place-items-center mx-auto mb-7">
              <Check size={30} />
            </div>
            <h2 className="font-display text-3xl font-bold italic text-stone-900 mb-3">{t('sponsor.done_title')}</h2>
            <p className="text-stone-500 leading-relaxed max-w-lg mx-auto mb-9 italic">{t('sponsor.done_text')}</p>
            <Link to="/fussball"
                  className="inline-flex items-center gap-2 bg-stone-900 text-white px-8 py-4 rounded-2xl font-bold text-sm hover:bg-black transition-colors">
              <ArrowLeft size={16} /> {t('sponsor.done_back')}
            </Link>
          </motion.div>
        )}

      </div>
    </div>
  );
};

export default SponsorPage;
