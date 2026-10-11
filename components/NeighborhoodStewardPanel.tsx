import React, { useState, useEffect, useMemo } from 'react';
import { VERTRETER_FELD_KEYS } from '../lib/vertreterfelder';
import { motion } from 'framer-motion';
import {
  Home, Users, Receipt, Search, Save, Loader2, CheckCircle2, Clock,
  AlertTriangle, Phone, Mail, MapPin, Send, X, ShieldAlert,
} from 'lucide-react';
import { db } from '../services/datenzugriff';
import {
  doc, updateDoc, collection, getDocs, query, where,
  myNeighborhoods, reportPaymentPaid, supabase,
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
  const [familien, setFamilien] = useState<{ id: string; name: string }[]>([]);
  // Was dieser Verein seinen Verantwortlichen erlaubt. Ein Feld
  // anzuzeigen, das die Datenbank hinterher zurueckweist, waere eine
  // Falle -- also wird nur gezeigt, was auch durchgeht.
  const [erlaubt, setErlaubt] = useState<Set<string>>(new Set());
  const [meldeGrund, setMeldeGrund] = useState('');
  const [meldetInaktiv, setMeldetInaktiv] = useState(false);
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
  // Was der Verantwortliche wirklich bekommen hat. Als Text gehalten und
  // nicht als Zahl: ein leeres Zahlenfeld ist in React entweder NaN oder
  // 0, und 0 waere hier eine Aussage ("nichts bekommen") statt einer
  // fehlenden Angabe.
  const [meldeBetrag, setMeldeBetrag] = useState('');
  const [meldet, setMeldet] = useState(false);

  const laden = async () => {
    setLaedt(true);
    try {
      const ids = await myNeighborhoods();
      setMeine(ids);
      if (!ids.length) { setLaedt(false); return; }

      // Die Zugriffsregeln begrenzen ohnehin auf die eigenen Nachbarschaften.
      // Die Abfragen holen deshalb schlicht, was sichtbar ist.
      const [nb, mg, zg, fa] = await Promise.all([
        getDocs(query(collection(db, 'neighborhoods'))),
        getDocs(query(collection(db, 'users'))),
        getDocs(query(collection(db, 'payments'))),
        getDocs(query(collection(db, 'families'))),
      ]);
      setFamilien(fa.docs.map(d => ({ id: d.id, name: (d.data() as any).name ?? d.id })));
      const { data: t } = await supabase.from('tenants').select('vertreter_felder').maybeSingle();
      setErlaubt(new Set(((t as any)?.vertreter_felder as string[]) ?? []));
      setNachbarschaften(nb.docs.map(d => ({ id: d.id, ...d.data() } as Neighborhood)).filter(n => ids.includes(n.id)));
      // Entfernte Mitglieder erscheinen gar nicht erst. Der Datensatz bleibt
      // in der Datenbank, weil Rechnungen und Zahlungen daran haengen -- in
      // der Nachbarschaft hat er nichts mehr zu suchen. Vorher standen dadurch
      // zwei Zeilen desselben Menschen nebeneinander.
      setMitglieder(
        mg.docs
          .map(d => ({ id: d.id, ...d.data() } as UserProfile))
          .filter(u => ids.includes(u.neighborhoodId || '') && u.membershipStatus !== 'INACTIVE')
      );
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
  // Wer im Adminbereich "entfernt" wird, bekommt den Status INACTIVE -- die
  // Zeile bleibt bestehen, weil Rechnungen und Zahlungen daran haengen. Sie
  // hier unmarkiert weiterzufuehren liess doppelte Eintraege wie zwei Zeilen
  // desselben Menschen unveraendert aussehen.
  //
  // Bearbeiten darf die Betreuung nur gewoehnliche Mitglieder: die
  // Zugriffsregel verlangt ausdruecklich role = MEMBER, damit niemand einen
  // Vorstand oder Vertreter umschreibt. Das gehoert vorher sichtbar zu sein
  // und nicht erst beim Speichern als technische Meldung.
  const bewertet = useMemo(() => mitglieder.map(m => ({
    m,
    beitrag: feeStateFor(m.id!, rechnungen, jahr),
    fehlt: missingFieldKeys(m, { selfServiceOnly: true }),
    bearbeitbar: (m.role || 'MEMBER') === 'MEMBER',
  })), [mitglieder, rechnungen, jahr]);

  // Entfernte Mitglieder kommen gar nicht erst in die Liste, es braucht hier
  // also keine Sonderbehandlung mehr.
  const zaehler = useMemo(() => ({
    mitglieder:      bewertet.length,
    bezahlt:         bewertet.filter(b => b.beitrag === 'PAID').length,
    offen:           bewertet.filter(b => b.beitrag === 'OPEN').length,
    nichtVerrechnet: bewertet.filter(b => b.beitrag === 'NONE').length,
    vollstaendig:    bewertet.filter(b => b.fehlt.length === 0).length,
    luecken:         bewertet.filter(b => b.fehlt.length > 0).length,
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

  // Der angezeigte Name folgt Vor- und Nachnamen -- aber nur, solange er
  // noch dem alten Paar entspricht. Wer ihn eigens gesetzt hat (etwa
  // "Familie Dervishi"), soll ihn nicht beim Berichtigen des Vornamens
  // verlieren.
  const namenFolgen = (m: any, feldName: 'firstName' | 'lastName', wert: string) => {
    const neu = { ...m, [feldName]: wert };
    const altPaar = [m.firstName, m.lastName].filter(Boolean).join(' ').trim();
    const eigens = (m.displayName || '').trim() && (m.displayName || '').trim() !== altPaar;
    if (!eigens) {
      neu.displayName = [neu.firstName, neu.lastName].filter(Boolean).join(' ').trim()
        || m.displayName;
    }
    return neu;
  };

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
      // Nur schicken, was erlaubt ist. Schickt die Maske mehr, weist es
      // der Ausloeser zurueck -- und der ganze Vorgang scheitert, auch
      // die erlaubten Felder.
      const nurErlaubt = (o: Record<string, any>) =>
        Object.fromEntries(Object.entries(o).filter(([k]) => erlaubt.has(k)));

      const zuSchicken = nurErlaubt({
        // Leer wird zu NULL: in der Spalte steht heute keine einzige leere
        // Zeichenkette, und dabei soll es bleiben.
        birthdate: bearbeitet.birthdate?.trim() || null,
        street: bearbeitet.street || '',
        zip: bearbeitet.zip || '',
        city: bearbeitet.city || '',
        country: bearbeitet.country || '',
        address: bearbeitet.street || '',
        phone: bearbeitet.phone || '',
        email: bearbeitet.email || '',
        // Die wenigsten Mitglieder koennen sich anmelden -- 6 von 340. Wer
        // anruft und nicht oeffentlich erscheinen will, muss den Widerspruch
        // hier eintragen lassen koennen, sonst hat er keinen.
        nicht_oeffentlich: !!bearbeitet.nicht_oeffentlich,
        // Was der Verantwortliche vor Ort weiss: wer aktiv dabei ist und
        // wer zu welcher Familie gehoert. Beides bewegt kein Geld -- der
        // Beitrag haengt an der Beitragsgruppe, und die bleibt beim
        // Vorstand. Ein Ausloeser in der Datenbank setzt diese Grenze;
        // dass die Maske sie einhaelt, genuegt nicht.
        membershipCategory: (bearbeitet as any).membershipCategory || null,
        familyId: (bearbeitet as any).familyId || null,
        invoiceDeliveryMethod: (bearbeitet as any).invoiceDeliveryMethod || null,
        // Die Person selbst. Diese sechs Felder fehlten, obwohl die
        // Administration sie freigegeben hatte -- darunter der Name. Ein
        // Verantwortlicher, der einen Schreibfehler berichtigen wollte,
        // fand kein Feld dafuer und hielt es fuer ein fehlendes Recht.
        salutation: (bearbeitet as any).salutation || null,
        firstName: (bearbeitet as any).firstName || null,
        lastName: (bearbeitet as any).lastName || null,
        displayName: bearbeitet.displayName || null,
        sprache: (bearbeitet as any).sprache || null,
        phoneSecondary: (bearbeitet as any).phoneSecondary || null,
        billingGroup: (bearbeitet as any).billingGroup || null,
        customAnnualFee: (bearbeitet as any).customAnnualFee === '' ||
                         (bearbeitet as any).customAnnualFee === undefined
          ? null : Number((bearbeitet as any).customAnnualFee),
      });

      // Bleibt nichts uebrig, wird nichts geschickt -- und vor allem kein
      // Erfolg gemeldet. Vorher ergab eine leere Freigabeliste ein
      // updateDoc({}), das ohne Fehler durchlief: die Maske sagte
      // "gespeichert", und geaendert war nichts. Genau diese Art stiller
      // Erfolgsmeldung hat in diesem Projekt schon mehrfach Zeit gekostet.
      if (Object.keys(zuSchicken).length === 0) {
        showAlert({ type: 'error', message: t('steward.nothing_allowed') });
        return;
      }

      await updateDoc(doc(db, 'users', bearbeitet.id), zuSchicken as any);
      setMitglieder(l => l.map(m => (m.id === bearbeitet.id ? bearbeitet : m)));
      showAlert({ type: 'success', message: t('steward.saved') });
      setBearbeitet(null);
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    } finally {
      setSpeichert(false);
    }
  };

  // Eine Meldung oeffnen und mit dem Rechnungsbetrag vorbelegen.
  const oeffneMeldung = (z: Payment) => {
    setMeldung(z);
    setMeldeBetrag(String(z.amount ?? ''));
    setMeldeNotiz('');
  };

  const melden = async () => {
    if (!meldung?.id) return;
    setMeldet(true);
    try {
      // Der gemeldete Betrag darf abweichen -- genau das ist der Zweck.
      // Unsinn soll er nicht sein: null oder negativ waere keine
      // Zahlung, und die Datenbank weist es ohnehin zurueck. Es hier zu
      // sagen erspart dem Verantwortlichen die technische Meldung.
      const betrag = Number(String(meldeBetrag).replace(',', '.'));
      if (!Number.isFinite(betrag) || betrag <= 0) {
        showAlert({ type: 'error', message: t('steward.amount_invalid') });
        setMeldet(false);
        return;
      }
      await reportPaymentPaid(
        meldung.id, meldeArt, new Date().toISOString().slice(0, 10),
        meldeNotiz || null, betrag);
      showAlert({ type: 'success', message: t('steward.reported') });
      setMeldung(null); setMeldeNotiz('');
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setMeldet(false);
    }
  };

  // Welche Kategorien gibt es? Die, die der Verein benutzt -- nicht die,
  // die ich mir ausdenke. Gemessen bei Koretini: 340 von 340 Mitgliedern
  // stehen auf INDIVIDUAL; im Demo-Verein auf FAMILJE. Eine feste Liste
  // haette den vorhandenen Wert als "—" angezeigt und beim Speichern
  // geloescht -- ein Feld, das einen Wert still verwirft, ist schlimmer
  // als keines.
  const kategorien = React.useMemo(() => {
    const vorhanden = mitglieder
      .map(m => String((m as any).membershipCategory ?? '').trim())
      .filter(Boolean);
    const dazu = (bearbeitet as any)?.membershipCategory;
    return [...new Set([...vorhanden, ...(dazu ? [String(dazu)] : []),
                        'AKTIV', 'PASSIV', 'INDIVIDUAL'])].sort();
  }, [mitglieder, bearbeitet]);

  // Beitragsgruppen ebenso aus den Daten. Gemessen bei Koretini:
  // STANDARD 329, KOSOVO 3, ohne Angabe 8. Eine feste Liste haette den
  // vorhandenen Wert still verworfen -- und hier haengt Geld daran.
  const beitragsgruppen = React.useMemo(() => {
    const vorhanden = mitglieder
      .map(m => String((m as any).billingGroup ?? '').trim())
      .filter(Boolean);
    const dazu = (bearbeitet as any)?.billingGroup;
    return [...new Set([...vorhanden, ...(dazu ? [String(dazu)] : [])])].sort();
  }, [mitglieder, bearbeitet]);

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)] transition-colors';
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
            <p className="text-2xl font-bold">{zaehler.mitglieder}</p>
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
              className="w-full pl-11 pr-4 py-3.5 bg-stone-50 border border-stone-200 rounded-2xl outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)] transition-colors" />
          </div>

          {/* Filter statt blosser Warnungen: bei 35 offenen Beitraegen unter 46
              Mitgliedern ist die vollstaendige Liste keine Arbeitsgrundlage. */}
          <div className="flex flex-wrap gap-2">
            {([
              ['ALLE', t('steward.filter_all'), bewertet.length],
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
            {gefiltert.map(({ m, beitrag, fehlt, bearbeitbar }) => (
              <button key={m.id} onClick={() => setBearbeitet({ ...m })}
                className="text-left bg-white border border-stone-100 rounded-2xl p-5 hover:border-stone-300 transition-colors flex flex-wrap items-start justify-between gap-4">
                <div className="min-w-0 flex-1 space-y-1.5">
                  <p className="font-bold text-stone-900 truncate flex items-center gap-2">
                    <span>{m.displayName || '-'}</span>
                    {!bearbeitbar && (
                      <span className="px-2 py-0.5 rounded text-[9px] font-bold uppercase bg-stone-100 text-stone-500 border border-stone-200 shrink-0">
                        {m.role}
                      </span>
                    )}
                  </p>
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
                    <button onClick={() => oeffneMeldung(r)}
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
              {/* Vorher sagen, was nicht geht. Die Zugriffsregel verlangt
                  role = MEMBER; ohne diesen Hinweis endete der Versuch in einer
                  technischen Meldung ueber eine nicht geaenderte Zeile. */}
              {(bearbeitet.role || 'MEMBER') !== 'MEMBER' && (
                <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex gap-2.5 text-amber-800">
                  <ShieldAlert size={16} className="mt-0.5 shrink-0" />
                  <p className="text-xs leading-relaxed">{t('steward.not_editable', { role: bearbeitet.role || '' })}</p>
                </div>
              )}
              {/* Das Geburtsdatum wurde in der Liste als fehlend bemaengelt, war
                  hier aber nicht einzutragen -- die Ansicht verlangte etwas, das
                  sie nicht anbot. Es ist zugleich die Grundlage der
                  Geburtstagsgruesse: bisher haben 17 von 350 Mitgliedern eines. */}
              {/* Hat der Verein nichts freigegeben, ist die Maske leer --
                  das muss dastehen und nicht als stummes Formular enden. */}
              {erlaubt.size === 0 && (
                <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex gap-2.5 text-amber-800">
                  <ShieldAlert size={16} className="mt-0.5 shrink-0" />
                  <p className="text-xs leading-relaxed">{t('steward.nothing_allowed')}</p>
                </div>
              )}

              {/* Die Person. Jedes Feld haengt an der Freigabe -- eines
                  anzuzeigen, das die Datenbank zurueckweist, waere eine
                  Falle; eines zu verbergen, das freigegeben ist, war der
                  Fehler, den dieser Abschnitt behebt. */}
              {erlaubt.has('salutation') && (
                <div>
                  <label className={marke}>Anrede</label>
                  <select value={(bearbeitet as any).salutation || ''}
                    onChange={e => setBearbeitet({ ...bearbeitet, salutation: e.target.value } as any)}
                    className={feld}>
                    <option value="">—</option>
                    <option value="HERR">Herr</option>
                    <option value="FRAU">Frau</option>
                    <option value="FAMILIE">Familie</option>
                  </select>
                </div>
              )}
              {(erlaubt.has('firstName') || erlaubt.has('lastName')) && (
                <div className="grid grid-cols-2 gap-3">
                  {erlaubt.has('firstName') && (
                    <div>
                      <label className={marke}>{t('field.firstName')}</label>
                      <input value={(bearbeitet as any).firstName || ''}
                        onChange={e => setBearbeitet(namenFolgen(bearbeitet, 'firstName', e.target.value))}
                        className={feld} />
                    </div>
                  )}
                  {erlaubt.has('lastName') && (
                    <div>
                      <label className={marke}>{t('field.lastName')}</label>
                      <input value={(bearbeitet as any).lastName || ''}
                        onChange={e => setBearbeitet(namenFolgen(bearbeitet, 'lastName', e.target.value))}
                        className={feld} />
                    </div>
                  )}
                </div>
              )}
              {erlaubt.has('displayName') && (
                <div>
                  <label className={marke}>Angezeigter Name</label>
                  <input value={bearbeitet.displayName || ''}
                    onChange={e => setBearbeitet({ ...bearbeitet, displayName: e.target.value })}
                    className={feld} />
                  <p className="text-[10px] text-stone-400 mt-1">
                    Folgt Vor- und Nachnamen, solange er nicht eigens geändert wird.
                  </p>
                </div>
              )}
              {erlaubt.has('birthdate') && (
              <div>
                <label className={marke}>{t('field.birthdate')}</label>
                <input type="date" value={bearbeitet.birthdate || ''}
                  onChange={e => setBearbeitet({ ...bearbeitet, birthdate: e.target.value })}
                  className={feld} />
              </div>
              )}
              {erlaubt.has('sprache') && (
                <div>
                  <label className={marke}>Sprache</label>
                  <div className="flex gap-1 bg-stone-100 p-1 rounded-xl">
                    {([['', 'beide'], ['sq', 'Shqip'], ['de', 'Deutsch']] as const).map(([w, n]) => (
                      <button key={w || 'beide'} type="button"
                        onClick={() => setBearbeitet({ ...bearbeitet, sprache: w || null } as any)}
                        className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${
                          ((bearbeitet as any).sprache || '') === w
                            ? 'bg-stone-900 text-white' : 'text-stone-500 hover:text-stone-800'}`}>
                        {n}
                      </button>
                    ))}
                  </div>
                  <p className="text-[10px] text-stone-400 mt-1">
                    Ohne Angabe gehen Briefe zweisprachig hinaus, Albanisch zuerst.
                  </p>
                </div>
              )}
              {erlaubt.has('street') && (
              <div>
                <label className={marke}>{t('admin.members.street_no')}</label>
                <input value={bearbeitet.street || ''} onChange={e => setBearbeitet({ ...bearbeitet, street: e.target.value })} className={feld} />
              </div>
              )}
              {(erlaubt.has('zip') || erlaubt.has('city')) && (
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
              )}
              {erlaubt.has('country') && (
              <div>
                <label className={marke}>{t('field.country')}</label>
                <CountrySelect value={bearbeitet.country} onChange={v => setBearbeitet({ ...bearbeitet, country: v })} className={feld} />
              </div>
              )}
              {erlaubt.has('phone') && (
              <div>
                <label className={marke}>{t('field.phone')}</label>
                <input value={bearbeitet.phone || ''} onChange={e => setBearbeitet({ ...bearbeitet, phone: e.target.value })} className={feld} />
              </div>
              )}
              {erlaubt.has('phoneSecondary') && (
                <div>
                  <label className={marke}>Telefon (zweit)</label>
                  <input value={(bearbeitet as any).phoneSecondary || ''}
                    onChange={e => setBearbeitet({ ...bearbeitet, phoneSecondary: e.target.value } as any)}
                    className={feld} />
                </div>
              )}
              {erlaubt.has('email') && (
              <div>
                <label className={marke}>{t('field.email')}</label>
                <input value={bearbeitet.email || ''} onChange={e => setBearbeitet({ ...bearbeitet, email: e.target.value })} className={feld} />
              </div>
              )}
              <div className="grid grid-cols-2 gap-3">
                {erlaubt.has('membershipCategory') && (
                <div>
                  <label className={marke}>Kategorie</label>
                  <select value={(bearbeitet as any).membershipCategory || ''}
                    onChange={e => setBearbeitet({ ...bearbeitet, membershipCategory: e.target.value } as any)}
                    className={feld}>
                    <option value="">—</option>
                    {kategorien.map(k => <option key={k} value={k}>{k}</option>)}
                  </select>
                </div>
                )}
                {erlaubt.has('familyId') && (
                <div>
                  <label className={marke}>Familie</label>
                  <select value={(bearbeitet as any).familyId || ''}
                    onChange={e => setBearbeitet({ ...bearbeitet, familyId: e.target.value } as any)}
                    className={feld}>
                    <option value="">keiner zugeordnet</option>
                    {familien.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                  </select>
                </div>
                )}
              </div>
              {/* Geld. Diese beiden standen im Katalog der Adminmaske, hatten
                  aber nirgends ein Eingabefeld -- die Freigabe war damit
                  wirkungslos. Sie bleiben bewusst unten und mit Hinweis:
                  sie bestimmen, was jemand zahlt. */}
              {(erlaubt.has('billingGroup') || erlaubt.has('customAnnualFee')) && (
                <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-3">
                  <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                    Beitrag — bestimmt, was dieses Mitglied zahlt
                  </p>
                  {erlaubt.has('billingGroup') && (
                    <div>
                      <label className={marke}>Beitragsgruppe</label>
                      <select value={(bearbeitet as any).billingGroup || ''}
                        onChange={e => setBearbeitet({ ...bearbeitet, billingGroup: e.target.value } as any)}
                        className={feld}>
                        <option value="">—</option>
                        {beitragsgruppen.map(g => <option key={g} value={g}>{g}</option>)}
                      </select>
                    </div>
                  )}
                  {erlaubt.has('customAnnualFee') && (
                    <div>
                      <label className={marke}>Eigener Jahresbeitrag</label>
                      <input type="number" step="0.05" min="0"
                        value={(bearbeitet as any).customAnnualFee ?? ''}
                        onChange={e => setBearbeitet({ ...bearbeitet, customAnnualFee: e.target.value } as any)}
                        className={feld} placeholder="leer = nach Beitragsgruppe" />
                      <p className="text-[10px] text-stone-400 mt-1">
                        Überschreibt die Beitragsgruppe. Leer lassen heisst: normaler Beitrag.
                      </p>
                    </div>
                  )}
                </div>
              )}
              {erlaubt.has('invoiceDeliveryMethod') && (
                <div>
                  <label className={marke}>Rechnungsweg</label>
                  <div className="flex gap-1 bg-stone-100 p-1 rounded-xl">
                    {([['EMAIL', 'E-Mail'], ['POST', 'Post']] as const).map(([w, n]) => (
                      <button key={w} type="button"
                        onClick={() => setBearbeitet({ ...bearbeitet, invoiceDeliveryMethod: w } as any)}
                        className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${
                          (bearbeitet as any).invoiceDeliveryMethod === w
                            ? 'bg-stone-900 text-white' : 'text-stone-500 hover:text-stone-800'}`}>
                        {n}
                      </button>
                    ))}
                  </div>
                  <p className="text-[10px] text-stone-400 mt-1.5">
                    Wer keine brauchbare Adresse hat, bekommt die Rechnung per Post.
                  </p>
                </div>
              )}

              {/* Jemanden auf inaktiv zu setzen beendet eine Mitgliedschaft.
                  Das entscheidet der Vorstand -- der Verantwortliche meldet
                  es, so wie er eine Barzahlung meldet. */}
              <div className="p-4 rounded-2xl border border-amber-100 bg-amber-50/60 space-y-3">
                <p className="text-[10px] font-bold uppercase tracking-widest text-amber-700">
                  Dem Vorstand melden
                </p>
                <p className="text-[11px] text-stone-600 leading-relaxed">
                  Weggezogen, verstorben oder nicht mehr erreichbar? Melden Sie es —
                  der Vorstand entscheidet, ob die Mitgliedschaft endet.
                </p>
                <input value={meldeGrund} onChange={e => setMeldeGrund(e.target.value)}
                  placeholder="Was ist passiert?" className={feld} />
                <button type="button" disabled={meldetInaktiv || !meldeGrund.trim()}
                  onClick={async () => {
                    setMeldetInaktiv(true);
                    const { error } = await supabase.rpc('mitglied_melden', {
                      p_member: bearbeitet.id, p_art: 'INAKTIV', p_bemerkung: meldeGrund.trim(),
                    });
                    setMeldetInaktiv(false);
                    if (error) { showAlert({ type: 'error', message: error.message }); return; }
                    setMeldeGrund('');
                    showAlert({ type: 'success',
                      message: 'Gemeldet. Der Vorstand sieht es unter Finanzen.' });
                  }}
                  className="w-full py-2.5 rounded-xl bg-amber-600 text-white text-[10px]
                             font-bold uppercase tracking-widest disabled:opacity-40">
                  {meldetInaktiv ? 'Meldet …' : 'Als inaktiv melden'}
                </button>
              </div>

              {/* Was der Vorstand entscheidet, steht hier nur zum Nachsehen.
                  Ein Feld, das man aendern kann und das die Datenbank dann
                  zurueckweist, ist schlimmer als keines. */}
              <div className="p-4 rounded-2xl bg-stone-50 border border-stone-200 flex flex-wrap gap-x-8 gap-y-2">
                <div>
                  <p className={marke}>Beitragsgruppe</p>
                  <p className="text-sm font-bold text-stone-500">
                    {(bearbeitet as any).billingGroup || '—'}
                  </p>
                </div>
                <div>
                  <p className={marke}>Status</p>
                  <p className="text-sm font-bold text-stone-500">
                    {bearbeitet.membershipStatus || '—'}
                  </p>
                </div>
                <p className="text-[11px] text-stone-400 basis-full leading-relaxed">
                  Beitrag und Status entscheidet der Vorstand — melden Sie ihm, was sich geändert hat.
                </p>
              </div>

              {erlaubt.has('nicht_oeffentlich') && (
              <label className="flex items-start gap-3 p-4 rounded-2xl border border-stone-200 bg-stone-50 cursor-pointer">
                <input type="checkbox" checked={!!bearbeitet.nicht_oeffentlich}
                  onChange={e => setBearbeitet({ ...bearbeitet, nicht_oeffentlich: e.target.checked })}
                  className="mt-0.5 w-4 h-4 accent-[color:var(--primary)] shrink-0" />
                <span>
                  <span className="block text-sm font-bold text-stone-800">{t('oeff.mitglied')}</span>
                  <span className="block text-xs text-stone-500 leading-relaxed mt-0.5">{t('oeff.mitglied_text')}</span>
                </span>
              </label>
              )}
            </div>
            <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
              <button onClick={() => setBearbeitet(null)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button>
              <button onClick={speichern} disabled={speichert || (bearbeitet.role || 'MEMBER') !== 'MEMBER'}
                className="flex-[2] py-3 bg-primary text-white rounded-xl font-bold shadow-lg flex items-center justify-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed">
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
              {/* Der Betrag. Vorher ging immer der Rechnungsbetrag hinaus,
                  egal was an der Tuer uebergeben wurde -- wer 30 statt 40
                  bekam, konnte das nicht melden, und der Vorstand
                  bestaetigte anschliessend eine Zahlung, die es so nicht
                  gab. */}
              <div>
                <label className={marke}>{t('steward.amount_received')}</label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">
                    {meldung.currency || 'CHF'}
                  </span>
                  <input type="text" inputMode="decimal" value={meldeBetrag}
                    onChange={e => setMeldeBetrag(e.target.value)}
                    className={feld + ' pl-14 font-mono font-bold'} />
                </div>
                {(() => {
                  const b = Number(String(meldeBetrag).replace(',', '.'));
                  const soll = Number(meldung.amount ?? 0);
                  if (!Number.isFinite(b) || b === soll) return null;
                  const d = b - soll;
                  return (
                    <p className={`text-[11px] mt-1.5 font-bold ${d > 0 ? 'text-sky-700' : 'text-amber-700'}`}>
                      {d > 0
                        ? t('steward.amount_more', { betrag: d.toFixed(2) })
                        : t('steward.amount_less', { betrag: Math.abs(d).toFixed(2) })}
                    </p>
                  );
                })()}
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
