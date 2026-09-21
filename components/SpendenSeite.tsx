import React, { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Heart, Loader2, AlertTriangle, ArrowLeft, Printer } from 'lucide-react';
import { Link } from 'react-router-dom';
import { supabase, doc, getDoc, db } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import SwissQRBill from './SwissQRBill';
import type { QrBillData } from '../services/qrBillService';
import CountrySelect from './ui/CountrySelect';

// Die oeffentliche Spendenseite.
//
// Der Ablauf endet nicht bei "danke", sondern bei einem Einzahlungsschein
// mit Referenznummer. Ueber sie ordnet die Bank die eingehende Zahlung von
// selbst zu -- ohne sie muesste der Vorstand jede Ueberweisung von Hand
// zuordnen, und genau diese Handarbeit soll das Modul abnehmen.
//
// Die Referenz entsteht auf dem Server. Eine im Browser erzeugte Nummer
// koennte doppelt vergeben oder gefaelscht werden.

const BETRAEGE = [20, 50, 100, 250];

const SpendenSeite: React.FC = () => {
  const { t } = useTranslation();
  const [betrag, setBetrag] = useState<number | ''>(50);
  const [eigener, setEigener] = useState('');
  const [form, setForm] = useState({
    name: '', email: '', strasse: '', plz: '', ort: '', land: 'Schweiz',
    nachricht: '', zweck: '',
  });
  const [anonym, setAnonym] = useState(false);
  const [laeuft, setLaeuft] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);
  const [ergebnis, setErgebnis] = useState<{ referenz: string; betrag: number; waehrung: string } | null>(null);
  const [zahlung, setZahlung] = useState<any>(null);

  useEffect(() => {
    getDoc(doc(db, 'public_settings', 'payment'))
      .then(s => { if (s.exists()) setZahlung(s.data()); })
      .catch(() => {});
  }, []);

  const endbetrag = eigener.trim() !== '' ? Number(eigener) : (betrag === '' ? 0 : betrag);

  const senden = async () => {
    setFehler(null);
    if (!endbetrag || endbetrag <= 0) { setFehler(t('spende.betrag_fehlt')); return; }
    if (!anonym && !form.name.trim()) { setFehler(t('spende.name_fehlt')); return; }
    setLaeuft(true);
    try {
      const { data, error } = await supabase.rpc('spende_anlegen', {
        p_betrag: endbetrag, p_waehrung: 'CHF',
        p_name: form.name, p_email: form.email, p_strasse: form.strasse,
        p_plz: form.plz, p_ort: form.ort, p_land: form.land,
        p_nachricht: form.nachricht, p_zweck: form.zweck, p_anonym: anonym,
      });
      if (error) throw error;
      const z = Array.isArray(data) ? data[0] : data;
      setErgebnis({ referenz: z.referenz, betrag: Number(z.betrag), waehrung: z.waehrung });
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setLaeuft(false);
    }
  };

  // Der Einzahlungsschein. Er entsteht erst nach dem Anlegen, weil er die
  // Referenznummer braucht.
  const beleg: QrBillData | null = useMemo(() => {
    if (!ergebnis || !zahlung?.qrIban) return null;
    return {
      amount: ergebnis.betrag,
      currency: (ergebnis.waehrung as 'CHF' | 'EUR') || 'CHF',
      iban: zahlung.qrIban || zahlung.iban,
      creditor: {
        name: zahlung.accountHolder || '', address: zahlung.street || '',
        zip: zahlung.zip || '', city: zahlung.city || '', country: zahlung.country || 'CH',
      },
      debtor: {
        name: anonym ? '' : form.name, address: form.strasse,
        zip: form.plz, city: form.ort, country: form.land,
      },
      reference: ergebnis.referenz,
      referenceType: 'QRR',
      additionalInfo: form.zweck || t('spende.zweck_allgemein'),
    };
  }, [ergebnis, zahlung, form, anonym, t]);

  const feld = 'w-full p-3.5 bg-white border border-stone-200 rounded-xl outline-none text-sm feld-primaer';
  const marke = 'block text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2';

  if (ergebnis) return (
    <div className="min-h-screen pt-32 pb-20 px-6" style={{ background: 'var(--accent)' }}>
      <div className="max-w-3xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}
                    className="bg-white rounded-[2.5rem] border border-stone-100 p-8 md:p-10 shadow-sm">
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center mb-6 tupfer-primaer">
            <Heart size={26} fill="currentColor" />
          </div>
          <h1 className="font-display font-bold italic text-3xl text-stone-900 mb-3">{t('spende.danke_titel')}</h1>
          <p className="text-stone-500 text-sm leading-relaxed mb-8 max-w-xl">{t('spende.danke_text')}</p>

          {beleg ? (
            <>
              <div className="border border-stone-100 rounded-2xl overflow-hidden mb-6">
                <SwissQRBill data={beleg} />
              </div>
              <button onClick={() => window.print()}
                      className="knopf-primaer px-6 py-3 text-white rounded-xl text-xs font-bold inline-flex items-center gap-2">
                <Printer size={14} /> {t('spende.drucken')}
              </button>
            </>
          ) : (
            <div className="p-5 bg-stone-50 rounded-2xl">
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('spende.referenz')}</p>
              <p className="font-mono text-lg text-stone-900 break-all">{ergebnis.referenz}</p>
              <p className="text-xs text-stone-400 mt-3">{t('spende.kein_beleg')}</p>
            </div>
          )}

          <Link to="/" className="inline-flex items-center gap-2 text-xs font-bold text-stone-400 hover:text-stone-900 mt-8">
            <ArrowLeft size={14} /> {t('nav.back_home')}
          </Link>
        </motion.div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen pt-32 pb-20 px-6" style={{ background: 'var(--accent)' }}>
      <div className="max-w-2xl mx-auto">
        <div className="mb-8">
          <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-[10px] font-bold uppercase tracking-widest tupfer-primaer mb-4">
            <Heart size={11} fill="currentColor" /> {t('spende.marke')}
          </span>
          <h1 className="font-display font-bold italic text-4xl text-stone-900 mb-3">{t('spende.titel')}</h1>
          <p className="text-stone-500 leading-relaxed max-w-xl">{t('spende.intro')}</p>
        </div>

        <div className="bg-white rounded-[2.5rem] border border-stone-100 p-7 md:p-9 shadow-sm space-y-6">
          <div>
            <label className={marke}>{t('spende.betrag')}</label>
            <div className="flex flex-wrap gap-2 mb-3">
              {BETRAEGE.map(b => (
                <button key={b} type="button"
                        onClick={() => { setBetrag(b); setEigener(''); }}
                        className={`px-5 py-3 rounded-xl text-sm font-bold transition-colors ${
                          eigener === '' && betrag === b
                            ? 'knopf-primaer text-white'
                            : 'bg-stone-50 text-stone-600 hover:bg-stone-100'}`}>
                  {b}.—
                </button>
              ))}
              <input value={eigener} onChange={e => setEigener(e.target.value)}
                     inputMode="decimal" placeholder={t('spende.eigener_betrag')}
                     className="w-36 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm feld-primaer" />
            </div>
          </div>

          <div>
            <label className={marke}>{t('spende.zweck')}</label>
            <input value={form.zweck} onChange={e => setForm({ ...form, zweck: e.target.value })}
                   placeholder={t('spende.zweck_platzhalter')} className={feld} />
          </div>

          <label className="flex items-center gap-3 text-sm text-stone-600 cursor-pointer">
            <input type="checkbox" checked={anonym} onChange={e => setAnonym(e.target.checked)}
                   className="w-4 h-4" style={{ accentColor: 'var(--primary)' }} />
            {t('spende.anonym')}
          </label>

          {!anonym && (
            <div className="space-y-4 pt-2 border-t border-stone-100">
              <p className="text-xs text-stone-400 leading-relaxed">{t('spende.warum_adresse')}</p>
              <div>
                <label className={marke}>{t('field.name')}</label>
                <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className={feld} />
              </div>
              <div>
                <label className={marke}>{t('field.email')}</label>
                <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className={feld} />
              </div>
              <div>
                <label className={marke}>{t('field.street')}</label>
                <input value={form.strasse} onChange={e => setForm({ ...form, strasse: e.target.value })} className={feld} />
              </div>
              <div className="flex gap-3">
                <div className="w-28">
                  <label className={marke}>{t('field.zip')}</label>
                  <input value={form.plz} onChange={e => setForm({ ...form, plz: e.target.value })} className={feld} />
                </div>
                <div className="flex-1">
                  <label className={marke}>{t('field.city')}</label>
                  <input value={form.ort} onChange={e => setForm({ ...form, ort: e.target.value })} className={feld} />
                </div>
              </div>
              <div>
                <label className={marke}>{t('field.country')}</label>
                <CountrySelect value={form.land} onChange={v => setForm({ ...form, land: v })} className={feld} />
              </div>
            </div>
          )}

          <div>
            <label className={marke}>{t('spende.nachricht')}</label>
            <textarea value={form.nachricht} onChange={e => setForm({ ...form, nachricht: e.target.value })}
                      rows={3} className={feld + ' resize-none'} />
          </div>

          {fehler && (
            <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl text-xs text-rose-700">
              <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
            </div>
          )}

          <button onClick={senden} disabled={laeuft}
                  className="knopf-primaer w-full py-4 text-white rounded-xl text-sm font-bold flex items-center justify-center gap-2 disabled:opacity-50">
            {laeuft ? <Loader2 className="animate-spin" size={16} /> : <Heart size={16} fill="currentColor" />}
            {t('spende.weiter')}
          </button>
          <p className="text-[11px] text-stone-400 text-center leading-relaxed">{t('spende.hinweis_qr')}</p>
        </div>
      </div>
    </div>
  );
};

export default SpendenSeite;
