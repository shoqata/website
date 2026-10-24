import React, { useState, useEffect, useMemo } from 'react';
import { VERTRETER_FELD_KEYS } from '../lib/vertreterfelder';
import { motion } from 'framer-motion';
import {
  Home, Users, Receipt, Search, Save, Loader2, CheckCircle2, Clock, Pencil,
  AlertTriangle, Phone, Mail, MapPin, Send, X, ShieldAlert, Download, Banknote, UserPlus,
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
import { rechnungsmailBauen } from '../lib/rechnungsmail';
import { zahlungsangabenPruefen } from '../lib/postversand';
import { versandsatz } from '../services/mailService';
import MeineZustaendigkeit from './MeineZustaendigkeit';
import { useVereinsjahre } from '../lib/useVereinsjahre';
import { KassierenDialog, MitgliedErfassenDialog, KasseTab, AufgabenTab } from './VertreterVorOrt';

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

  const [tab, setTab] = useState<'MEMBERS' | 'INVOICES' | 'KASSE' | 'AUFGABEN'>('MEMBERS');
  const [meine, setMeine] = useState<string[]>([]);
  const [nachbarschaften, setNachbarschaften] = useState<Neighborhood[]>([]);
  const [mitglieder, setMitglieder] = useState<UserProfile[]>([]);
  const [rechnungen, setRechnungen] = useState<Payment[]>([]);
  // Was die Administration dieser Person bei Rechnungen freigegeben hat.
  // Bis die Antwort da ist: nichts -- lieber einen Reiter eine Sekunde
  // spaeter zeigen als einen, der gleich wieder verschwindet.
  const [rechte, setRechte] = useState({
    sehen: false, senden: false, kassieren: false, ausgaben: false, erfassen: false, aufgaben: false,
  });
  // Vertreter vor Ort: wen er gerade kassiert, und ob die Neuerfassung offen ist.
  const [kassiert, setKassiert] = useState<UserProfile | null>(null);
  const [erfasst, setErfasst] = useState(false);
  const [rechnungLaeuft, setRechnungLaeuft] = useState<string | null>(null);
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
      const [{ data: t }, { data: r }] = await Promise.all([
        supabase.from('tenants').select('vertreter_felder').maybeSingle(),
        supabase.rpc('meine_vertreter_rechte'),
      ]);
      const rr: any = Array.isArray(r) ? r[0] : r;
      setRechte({
        sehen: !!rr?.sehen, senden: !!rr?.senden, kassieren: !!rr?.kassieren,
        ausgaben: !!rr?.ausgaben, erfassen: !!rr?.erfassen, aufgaben: !!rr?.aufgaben,
      });
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

  // Das Arbeitsjahr des Vereins: nach dem Jahreswechsel das neue.
  const { aktuell: jahr } = useVereinsjahre();

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

  // Die Rechnung so bauen, wie der Vorstand sie verschickt -- dieselbe
  // Mail, dasselbe PDF. Die Angaben dazu liefert die Datenbank fuer genau
  // diese eine Rechnung; die Einstellungen des Vereins selbst bleiben
  // dem Vorstand vorbehalten.
  const rechnungBauen = async (r: Payment) => {
    const { data, error } = await supabase.rpc('vertreter_rechnung_daten', { p_payment: r.id });
    if (error) throw error;
    const d: any = data;
    const z = zahlungsangabenPruefen({
      name: d.zahlung?.accountHolder, iban: d.zahlung?.iban, qrIban: d.zahlung?.qrIban,
      paypal: d.zahlung?.paypalEmail, twint: d.zahlung?.twintNumber,
    });
    if (!z.ok) throw new Error(`${z.grund || 'Es fehlt eine Zahlungsverbindung'} — bitte dem Vorstand melden.`);
    const gebaut = await rechnungsmailBauen({
      payment: { ...r, ...d.payment } as Payment,
      recipientName: d.mitglied?.name || nameVon(r.userId),
      anschrift: { adresse: d.mitglied?.adresse, plz: d.mitglied?.plz,
                   ort: d.mitglied?.ort, land: d.mitglied?.land },
      paymentSettings: d.zahlung, association: d.verein || '', t,
    });
    return gebaut;
  };

  const rechnungAlsPdf = async (r: Payment) => {
    setRechnungLaeuft(r.id!);
    try {
      const { anhaenge } = await rechnungBauen(r);
      const a = anhaenge[0];
      if (!a) throw new Error('Das PDF liess sich nicht erzeugen.');
      const bytes = Uint8Array.from(atob(a.content), c => c.charCodeAt(0));
      const url = URL.createObjectURL(new Blob([bytes], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url; link.download = a.filename; link.click();
      setTimeout(() => URL.revokeObjectURL(url), 2000);
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setRechnungLaeuft(null); }
  };

  // Der Empfaenger wird in der Datenbank bestimmt -- die hinterlegte
  // Adresse des Mitglieds, nie eine aus dem Browser.
  const rechnungSenden = async (r: Payment) => {
    setRechnungLaeuft(r.id!);
    try {
      const { subject, html, anhaenge } = await rechnungBauen(r);
      const { data: an, error } = await supabase.rpc('vertreter_rechnung_senden', {
        p_payment: r.id, p_betreff: subject, p_html: html, p_anhaenge: anhaenge,
      });
      if (error) throw error;
      showAlert({ type: 'success', message: await versandsatz(String(an)) });
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setRechnungLaeuft(null); }
  };

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
        <MeineZustaendigkeit />
        {/* Die Zahlen zaehlen Mitglieder, nicht Rechnungen. Vorher standen hier
            Rechnungszahlen -- wer wissen will, bei wem der Beitrag aussteht,
            ist damit nicht bedient. */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold">{zaehler.mitglieder}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.members')}</p>
          </div>
          {/* Ohne Freigabe sind die Rechnungen nicht sichtbar -- die Zahlen
              zeigten dann alle als nicht verrechnet. Lieber keine Zahl als
              eine falsche. */}
          {rechte.sehen && (<>
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-emerald-400">{zaehler.bezahlt}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.fee_paid', { year: jahr })}</p>
          </div>
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-amber-400">{zaehler.offen}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.fee_open')}</p>
          </div>
          </>)}
          <div className="bg-white/5 rounded-2xl p-4">
            <p className="text-2xl font-bold text-rose-300">{zaehler.luecken}</p>
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest mt-1">{t('steward.data_gaps')}</p>
          </div>
        </div>
        {rechte.sehen && zaehler.nichtVerrechnet > 0 && (
          <p className="text-stone-400 text-xs mt-4">
            {t('steward.not_billed', { count: zaehler.nichtVerrechnet, year: jahr })}
          </p>
        )}
      </div>

      <div className="flex gap-2 border-b border-stone-100 overflow-x-auto">
        {([
          ['MEMBERS', t('steward.tab_members'), true],
          ['INVOICES', t('steward.tab_invoices'), rechte.sehen],
          ['KASSE', t('steward.tab_cash'), rechte.kassieren || rechte.ausgaben],
          ['AUFGABEN', t('steward.tab_tasks'), rechte.aufgaben],
        ] as const).filter(([, , zeigen]) => zeigen).map(([k, label]) => (
          <button key={k} onClick={() => setTab(k)}
            className={`px-5 py-3 font-bold text-xs uppercase tracking-widest border-b-2 transition-colors whitespace-nowrap ${
              tab === k ? 'border-primary text-primary' : 'border-transparent text-stone-400 hover:text-stone-600'}`}>
            {label}
          </button>
        ))}
      </div>

      {tab === 'MEMBERS' && (
        <div className="space-y-4">
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
              <input value={suche} onChange={e => setSuche(e.target.value)} placeholder={t('common.search')}
                className="w-full pl-11 pr-4 py-3.5 bg-stone-50 border border-stone-200 rounded-2xl outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)] transition-colors" />
            </div>
            {rechte.erfassen && (
              <button onClick={() => setErfasst(true)}
                className="px-4 py-3 bg-stone-900 text-white rounded-2xl font-bold text-xs flex items-center gap-2 shrink-0">
                <UserPlus size={15} /> <span className="hidden sm:inline">{t('vorort.new_member')}</span>
              </button>
            )}
          </div>

          {/* Filter statt blosser Warnungen: bei 35 offenen Beitraegen unter 46
              Mitgliedern ist die vollstaendige Liste keine Arbeitsgrundlage. */}
          <div className="flex flex-wrap gap-2">
            {([
              ['ALLE', t('steward.filter_all'), bewertet.length],
              ['OFFEN', t('steward.filter_open'), zaehler.offen + zaehler.nichtVerrechnet],
              ['UNVOLLSTAENDIG', t('steward.filter_gaps'), zaehler.luecken],
            ] as const).filter(([k]) => rechte.sehen || k !== 'OFFEN').map(([k, label, n]) => (
              <button key={k} onClick={() => setFilter(k as any)}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors border ${
                  filter === k ? 'bg-stone-900 text-white border-stone-900'
                               : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                {label} <span className="opacity-60">{n}</span>
              </button>
            ))}
          </div>

          {gefiltert.length > 0 && (
            <p className="text-xs text-stone-500 mb-1">
              {t('steward.list_hint')}
            </p>
          )}
          {gefiltert.length === 0 && (
            <p className="text-sm text-stone-400 italic p-6 text-center">{t('steward.filter_empty')}</p>
          )}

          <div className="grid gap-3">
            {gefiltert.map(({ m, beitrag, fehlt, bearbeitbar }) => (
              <div key={m.id} role="button" tabIndex={bearbeitbar ? 0 : -1}
                onClick={() => bearbeitbar && setBearbeitet({ ...m })}
                onKeyDown={e => { if (bearbeitbar && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); setBearbeitet({ ...m }); } }}
                aria-disabled={!bearbeitbar}
                className={`text-left bg-white border rounded-2xl p-5 flex flex-wrap items-start justify-between gap-4 transition-colors ${
                  bearbeitbar
                    ? 'border-stone-200 hover:border-stone-400 hover:bg-stone-50 cursor-pointer'
                    : 'border-stone-100 opacity-70 cursor-not-allowed'}`}>
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
                  {/* Kassieren an der Tuer: wer noch nicht bezahlt hat. Die
                      Zeile selbst oeffnet die Bearbeitung, der Knopf darf
                      den Klick deshalb nicht weiterreichen. */}
                  {rechte.kassieren && beitrag !== 'PAID' && (
                    <span role="button" tabIndex={0}
                      onClick={e => { e.stopPropagation(); setKassiert(m); }}
                      onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); setKassiert(m); } }}
                      className="px-4 py-2 rounded-xl text-xs font-bold bg-stone-900 text-white flex items-center gap-1.5 hover:bg-stone-700 cursor-pointer">
                      <Banknote size={13} /> {t('vorort.collect')}
                    </span>
                  )}
                  {rechte.sehen && beitrag === 'PAID' && (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1.5">
                      <CheckCircle2 size={12} /> {t('steward.fee_paid', { year: jahr })}
                    </span>
                  )}
                  {rechte.sehen && beitrag === 'OPEN' && (
                    <span className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase bg-amber-50 text-amber-700 border border-amber-200 flex items-center gap-1.5">
                      <Clock size={12} /> {t('steward.fee_open')}
                    </span>
                  )}
                  {rechte.sehen && beitrag === 'NONE' && (
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
                
                  {/* Dass die Zeile anklickbar ist, muss dastehen. */}
                  {bearbeitbar ? (
                    <span className="mt-1 px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider bg-stone-900 text-white flex items-center gap-1.5">
                      <Pencil size={11} /> {t('steward.edit')}
                    </span>
                  ) : (
                    <span className="mt-1 text-[10px] font-bold uppercase tracking-wider text-stone-400">
                      {t('steward.not_editable_short')}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {tab === 'KASSE' && (rechte.kassieren || rechte.ausgaben) && (
        <KasseTab rechte={rechte} onGeaendert={laden} />
      )}
      {tab === 'AUFGABEN' && rechte.aufgaben && <AufgabenTab />}

      {kassiert && (
        <KassierenDialog mitglied={kassiert} onClose={() => setKassiert(null)}
          onDone={() => { setKassiert(null); laden(); }} />
      )}
      {erfasst && (
        <MitgliedErfassenDialog nachbarschaften={nachbarschaften} onClose={() => setErfasst(false)}
          onDone={() => { setErfasst(false); laden(); }} />
      )}

      {tab === 'INVOICES' && rechte.sehen && (
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
                    <button onClick={() => rechnungAlsPdf(r)} disabled={rechnungLaeuft === r.id}
                      title={t('steward.invoice_pdf_hint')}
                      className="px-3 py-2 border border-stone-200 text-stone-600 rounded-xl font-bold text-xs flex items-center gap-1.5 hover:border-stone-400 transition-colors disabled:opacity-50">
                      {rechnungLaeuft === r.id ? <Loader2 size={12} className="animate-spin" /> : <Download size={12} />} PDF
                    </button>
                    {/* Nur wer weiterleiten darf, und nur an jemanden mit Adresse.
                        Wer keine hat, bekommt das PDF auf anderem Weg. */}
                    {rechte.senden && (() => {
                      const mg = mitglieder.find(m => m.id === r.userId);
                      if (!mg || mg.id === user.id || !hasUsableEmail(mg)) return null;
                      return (
                        <button onClick={() => rechnungSenden(r)} disabled={rechnungLaeuft === r.id}
                          title={t('steward.invoice_send_hint', { email: mg.email || '' })}
                          className="px-3 py-2 border border-stone-200 text-stone-600 rounded-xl font-bold text-xs flex items-center gap-1.5 hover:border-stone-400 transition-colors disabled:opacity-50">
                          <Mail size={12} /> {t('steward.invoice_send')}
                        </button>
                      );
                    })()}
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
