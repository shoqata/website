import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import {
  Home, Users, Receipt, Search, Save, Loader2, CheckCircle2, Clock,
  AlertTriangle, Phone, Mail, MapPin, Send, X,
} from 'lucide-react';
import { db } from '../services/firebase';
import {
  doc, updateDoc, collection, getDocs, query, where,
  myNeighborhoods, reportPaymentPaid,
} from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { UserProfile, Payment, Neighborhood } from '../types';
import CountrySelect from './ui/CountrySelect';
import { missingFieldKeys, feeStateFor } from '../lib/memberQuality';
import { hasUsableEmail } from '../lib/memberEmail';

interface Props { user: UserProfile; }

// Die Ansicht der verantwortlichen Person einer Nachbarschaft.
//
// Sie zeigt genau das, was diese Person auch darf: die Mitglieder ihrer
// Nachbarschaften, deren Anschriften zum Berichtigen, und den Stand der
// Rechnungen. Den Stand aendern kann sie nicht -- sie meldet, und Vorstand
// oder Administration entscheiden. Diese Grenze steht in den Zugriffsregeln
// der Datenbank; die Oberflaeche bildet sie nur ab, statt sie zu behaupten.
const NeighborhoodStewardPanel: React.FC<Props> = ({ user }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();

  const [tab, setTab] = useState<'MEMBERS' | 'INVOICES'>('MEMBERS');
  const [meine, setMeine] = useState<string[]>([]);
  const [nachbarschaften, setNachbarschaften] = useState<Neighborhood[]>([]);
  const [mitglieder, setMitglieder] = useState<UserProfile[]>([]);
  const [rechnungen, setRechnungen] = useState<Payment[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [suche, setSuche] = useState('');
  // Bei 35 offenen Beitraegen und 39 unvollstaendigen Datensaetzen unter 46
  // Mitgliedern ist eine Warnung an fast jeder Zeile wertlos. Erst der
  // Filter macht daraus eine Arbeitsliste.
  const [filter, setFilter] = useState<'ALLE' | 'OFFEN' | 'UNVOLLSTAENDIG'>('ALLE');

  const [bearbeitet, setBearbeitet] = useState<UserProfile | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [meldung, setMeldung] = useState<Payment | null>(null);
  const [meldeArt, setMeldeArt] = useState('CASH');
  const [meldeNotiz, setMeldeNotiz] = useState('');
  const [meldet, setMeldet] = useState(false);

  const laden = async () => {
    setLaedt(true);
    try {
      const ids = await myNeighborhoods();
      setMeine(ids);
      if (!ids.length) { setLaedt(false); return; }

      // Die Zugriffsregeln begrenzen ohnehin auf die eigenen Nachbarschaften.
      // Die Abfragen holen deshalb schlicht, was sichtbar ist.
      const [nb, mg, zg] = await Promise.all([
        getDocs(query(collection(db, 'neighborhoods'))),
        getDocs(query(collection(db, 'users'))),
        getDocs(query(collection(db, 'payments'))),
      ]);
      setNachbarschaften(nb.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)).filter(n => ids.includes(n.id)));
      setMitglieder(mg.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile)).filter(u => ids.includes(u.neighborhoodId || '')));
      setRechnungen(zg.docs.map(d => ({ id: d.id, ...d.data() } as Payment)));
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { laden(); }, [user.id]);

  const jahr = new Date().getFullYear();

  // Beitragsstand und fehlende Angaben einmal je Mitglied, nicht in jeder
  // Zeile neu -- die Liste kann mehrere Dutzend Eintraege lang sein.
  const bewertet = useMemo(() => mitglieder.map(m => ({
    m,
    beitrag: feeStateFor(m.id!, rechnungen, jahr),
    fehlt: missingFieldKeys(m, { selfServiceOnly: true }),
  })), [mitglieder, rechnungen, jahr]);

  const zaehler = useMemo(() => ({
    bezahlt:       bewertet.filter(b => b.beitrag === 'PAID').length,
    offen:         bewertet.filter(b => b.beitrag === 'OPEN').length,
    nichtVerrechnet: bewertet.filter(b => b.beitrag === 'NONE').length,
    vollstaendig:  bewertet.filter(b => b.fehlt.length === 0).length,
    luecken:       bewertet.filter(b => b.fehlt.length > 0).length,
  }), [bewertet]);

  const gefiltert = useMemo(() => {
    const s = suche.toLowerCase().trim();
    return bewertet.filter(({ m, beitrag, fehlt }) => {
      if (filter === 'OFFEN' && beitrag === 'PAID') return false;
      if (filter === 'UNVOLLSTAENDIG' && fehlt.length === 0) return false;
      if (!s) return true;
      return (m.displayName || '').toLowerCase().includes(s) ||
             (m.email || '').toLowerCase().includes(s) ||
             (m.city || '').toLowerCase().includes(s) ||
             (m.phone || '').toLowerCase().includes(s);
    });
  }, [bewertet, suche, filter]);

  const nameVon = (id?: string) => mitglieder.find(m => m.id === id)?.displayName || '-';
  const offen = rechnungen.filter(r => r.status !== 'PAID');
  const bezahlt = rechnungen.filter(r => r.status === 'PAID');

  const speichern = async () => {
    if (!bearbeitet?.id) return;
    setSpeichert(true);
    try {
      // Bewusst nur die Anschrift und die Erreichbarkeit. Rolle, Nachbarschaft
      // und Beitragsgruppe bleiben aussen vor -- die Zugriffsregel wuerde sie
      // ohnehin zurueckweisen, und was nicht mitgeschickt wird, kann sich
      // nicht versehentlich aendern.
      await updateDoc(doc(db, 'users', bearbeitet.id), {
        street: bearbeitet.street || '',
        zip: bearbeitet.zip || '',
        city: bearbeitet.city || '',
        country: bearbeitet.country || '',
        address: bearbeitet.street || '',
        phone: bearbeitet.phone || '',
        email: bearbeitet.email || '',
      } as any);
      setMitglieder(l => l.map(m => (m.id === bearbeitet.id ? bearbeitet : m)));
      showAlert({ type: 'success', message: t('steward.saved') });
      setBearbeitet(null);
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSpeichert(false);
    }
  };

  const melden = async () => {
    if (!meldung?.id) return;
    setMeldet(true);
    try {
      await reportPaymentPaid(meldung.id, meldeArt, new Date().toISOString().slice(0, 10), meldeNotiz || null);
      showAlert({ type: 'success', message: t('steward.reported') });
      setMeldung(null); setMeldeNotiz('');
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setMeldet(false);
    }
  };

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  if (laedt) {
    return <div className="min-h-[60vh] flex items-center justify-center"><Loader2 className="animate-spin text-primary" size={32} /></div>;
  }

  if (!meine.length) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center p-6">
        <div className="max-w-md text-center space-y-3">
          <Home className="mx-auto text-stone-300" size={40} />
          <p className="text-stone-500 text-sm leading-relaxed">{t('steward.none')}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 md:p-10 space-y-8">
      <div className="bg-stone-900 text-white rounded-[2.5rem] p-8 md:p-10">
        <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">{t('steward.title')}</p>
        <h1 className="text-3xl md:text-4xl font-display font-bold italic mb-4">
          {nachbarschaften.map(n => n.name).join(' · ') || '-'}
        </h1>
        {/* Die Zahlen zaehlen Mitglieder, nicht Rechnungen. Vorher standen hier
            Rechnungszahlen -- wer wissen will, bei wem der Beitrag aussteht,
            ist damit nicht bedient. */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold">{mitglieder.length}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.members')}</p>
          </div>
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-emerald-400">{zaehler.bezahlt}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.fee_paid', { year: jahr })}</p>
          </div>
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-amber-400">{zaehler.offen}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.fee_open')}</p>
          </div>
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-rose-300">{zaehler.luecken}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.data_gaps')}</p>
          </div>
        </div>
        {zaehler.nichtVerrechnet > 0 && (
          <p className="text-stone-400 text-xs mt-4">
            {t('steward.not_billed', { count: zaehler.nichtVerrechnet, year: jahr })}
          </p>
        )}
      </div>

      <div className="flex gap-2 border-b border-stone-100">
        {(['MEMBERS', 'INVOICES'] as const).map(k => (
          <button key={k} onClick={() => setTab(k)}
            className={`px-5 py-3 font-bold text-xs uppercase tracking-widest border-b-2 transition-colors ${
              tab === k ? 'border-primary text-primary' : 'border-transparent text-stone-400 hover:text-stone-600'}`}>
            {k === 'MEMBERS' ? t('steward.tab_members') : t('steward.tab_invoices')}
          </button>
        ))}
      </div>

      {tab === 'MEMBERS' && (
        <div className="space-y-4">
          <div className="relative">
            <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
            <input value={suche} onChange={e => setSuche(e.target.value)} placeholder={t('common.search')}
              className="w-full pl-11 pr-4 py-3.5 bg-stone-50 border border-stone-200 rounded-2xl outline-none focus:border-primary/40 transition-colors" />
          </div>

          {/* Filter statt blosser Warnungen: bei 35 offenen Beitraegen unter 46
              Mitgliedern ist die vollstaendige Liste keine Arbeitsgrundlage. */}
          <div className="flex flex-wrap gap-2">
            {([
              ['ALLE', t('steward.filter_all'), mitglieder.length],
              ['OFFEN', t('steward.filter_open'), zaehler.offen + zaehler.nichtVerrechnet],
              ['UNVOLLSTAENDIG', t('steward.filter_gaps'), zaehler.luecken],
            ] as const).map(([k, label, n]) => (
              <button key={k} onClick={() => setFilter(k as any)}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors border ${
                  filter === k ? 'bg-stone-900 text-white border-stone-900'
                               : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                {label} <span className="opacity-60">{n}</span>
              </button>
            ))}
          </div>

          {gefiltert.length === 0 && (
            <p className="text-sm text-stone-400 italic p-6 text-center">{t('steward.filter_empty')}</p>
          )}

          <div className="grid gap-3">
            {gefiltert.map(({ m, beitrag, fehlt }) => (
              <button key={m.id} onClick={() => setBearbeitet({ ...m })}
                className="text-left bg-white border border-stone-100 rounded-2xl p-5 hover:border-stone-300 transition-colors flex flex-wrap items-start justify-between gap-4">
                <div className="min-w-0 flex-1 space-y-1.5">
                  <p className="font-bold text-stone-900 truncate">{m.displayName || '-'}</p>
                  <p className="text-xs text-stone-500 truncate">
                    {[m.street, [m.zip, m.city].filter(Boolean).join(' ')].filter(Boolean).join(', ') || t('steward.no_address')}
                  </p>
                  <div className="flex flex-wrap gap-3 text-xs text-stone-500">
                    {m.phone && <span className="flex items-center gap-1.5"><Phone size={12} /> {m.phone}</span>}
                    {hasUsableEmail(m) && <span className="flex items-center gap-1.5 truncate"><Mail size={12} /> {m.email}</span>}
                  </div>
                </div>

                {/* Die beiden Auskuenfte, um die es geht: Beitrag des laufenden
                    Jahres und Vollstaendigkeit der Angaben. "Nicht verrechnet"
                    bleibt von "offen" getrennt -- das eine liegt beim Mitglied,
                    das andere beim Verein. */}
                <div className="flex flex-col items-end gap-2 shrink-0">
                  {beitrag === 'PAID' && (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1.5">
                      <CheckCircle2 size={12} /> {t('steward.fee_paid', { year: jahr })}
                    </span>
                  )}
                  {beitrag === 'OPEN' && (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-amber-50 text-amber-700 border border-amber-200 flex items-center gap-1.5">
                      <Clock size={12} /> {t('steward.fee_open')}
                    </span>
                  )}
                  {beitrag === 'NONE' && (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-stone-100 text-stone-500 border border-stone-200 flex items-center gap-1.5">
                      <Receipt size={12} /> {t('steward.fee_none')}
                    </span>
                  )}

                  {fehlt.length === 0 ? (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1.5">
                      <CheckCircle2 size={12} /> {t('steward.data_ok')}
                    </span>
                  ) : (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold bg-rose-50 text-rose-700 border border-rose-200 flex items-center gap-1.5 text-right">
                      <AlertTriangle size={12} className="shrink-0" />
                      {t('steward.data_missing')}: {fehlt.map(k => t(k)).join(', ')}
                    </span>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {tab === 'INVOICES' && (
        <div className="space-y-3">
          <div className="p-4 bg-stone-50 border border-stone-200 rounded-2xl text-xs text-stone-600 leading-relaxed">
            {t('steward.invoice_hint')}
          </div>
          {rechnungen.length === 0 && <p className="text-sm text-stone-400 italic p-4">{t('steward.no_invoices')}</p>}
          {rechnungen.map(r => (
            <div key={r.id} className="bg-white border border-stone-100 rounded-2xl p-5 flex flex-wrap items-center justify-between gap-4">
              <div className="min-w-0">
                <p className="font-bold text-stone-900 truncate">{nameVon(r.userId)}</p>
                <p className="text-xs text-stone-500">
                  {r.invoiceNumber || r.id?.slice(0, 8)} · {r.billingYear || '-'} · {r.currency || 'CHF'} {r.amount}
                </p>
              </div>
              <div className="flex items-center gap-3">
                {r.status === 'PAID' ? (
                  <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-emerald-50 text-emerald-700 flex items-center gap-1.5">
                    <CheckCircle2 size={12} /> {t('steward.paid')}
                  </span>
                ) : (
                  <>
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-amber-50 text-amber-700 flex items-center gap-1.5">
                      <Clock size={12} /> {t('steward.open')}
                    </span>
                    <button onClick={() => setMeldung(r)}
                      className="px-4 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs flex items-center gap-1.5 hover:bg-stone-700 transition-colors">
                      <Send size={12} /> {t('steward.report')}
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Anschrift berichtigen */}
      {bearbeitet && (
        <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
          <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
            className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
              <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2">
                <MapPin size={18} className="text-primary" /> {bearbeitet.displayName}
              </h3>
              <button onClick={() => setBearbeitet(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={18} /></button>
            </div>
            <div className="p-8 space-y-4 overflow-y-auto custom-scrollbar">
              <div>
                <label className={marke}>{t('admin.members.street_no')}</label>
                <input value={bearbeitet.street || ''} onChange={e => setBearbeitet({ ...bearbeitet, street: e.target.value })} className={feld} />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className={marke}>{t('field.zip')}</label>
                  <input value={bearbeitet.zip || ''} onChange={e => setBearbeitet({ ...bearbeitet, zip: e.target.value })} className={feld} />
                </div>
                <div className="col-span-2">
                  <label className={marke}>{t('field.city')}</label>
                  <input value={bearbeitet.city || ''} onChange={e => setBearbeitet({ ...bearbeitet, city: e.target.value })} className={feld} />
                </div>
              </div>
              <div>
                <label className={marke}>{t('field.country')}</label>
                <CountrySelect value={bearbeitet.country} onChange={v => setBearbeitet({ ...bearbeitet, country: v })} className={feld} />
              </div>
              <div>
                <label className={marke}>{t('field.phone')}</label>
                <input value={bearbeitet.phone || ''} onChange={e => setBearbeitet({ ...bearbeitet, phone: e.target.value })} className={feld} />
              </div>
              <div>
                <label className={marke}>{t('field.email')}</label>
                <input value={bearbeitet.email || ''} onChange={e => setBearbeitet({ ...bearbeitet, email: e.target.value })} className={feld} />
              </div>
            </div>
            <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
              <button onClick={() => setBearbeitet(null)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button>
              <button onClick={speichern} disabled={speichert}
                className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
                {speichert ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />} {t('common.save_changes')}
              </button>
            </div>
          </motion.div>
        </div>
      )}

      {/* Zahlung melden */}
      {meldung && (
        <div className="fixed inset-0 z-[400] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
          <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
            className="bg-white w-full max-w-md rounded-[2rem] shadow-2xl overflow-hidden">
            <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
              <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2">
                <Receipt size={18} className="text-primary" /> {t('steward.report')}
              </h3>
              <button onClick={() => setMeldung(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={18} /></button>
            </div>
            <div className="p-8 space-y-5">
              <div>
                <p className="font-bold text-stone-900">{nameVon(meldung.userId)}</p>
                <p className="text-xs text-stone-500">{meldung.currency || 'CHF'} {meldung.amount} · {meldung.billingYear || '-'}</p>
              </div>
              <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-800 leading-relaxed">
                {t('steward.report_explain')}
              </div>
              <div>
                <label className={marke}>{t('steward.method')}</label>
                <select value={meldeArt} onChange={e => setMeldeArt(e.target.value)} className={feld}>
                  <option value="CASH">{t('steward.method_cash')}</option>
                  <option value="BANK_TRANSFER">{t('steward.method_bank')}</option>
                  <option value="QR_BILL">QR</option>
                  <option value="PAYPAL">PayPal</option>
                </select>
              </div>
              <div>
                <label className={marke}>{t('steward.note')}</label>
                <textarea value={meldeNotiz} onChange={e => setMeldeNotiz(e.target.value)} rows={3}
                  className={feld + ' resize-none'} placeholder={t('steward.note_ph')} />
              </div>
            </div>
            <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
              <button onClick={() => setMeldung(null)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button>
              <button onClick={melden} disabled={meldet}
                className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-60">
                {meldet ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />} {t('steward.send_report')}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
};

export default NeighborhoodStewardPanel;
