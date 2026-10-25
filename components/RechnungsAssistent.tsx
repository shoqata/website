import React, { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  X, Users, ClipboardCheck, Loader2, CheckCircle2, Mail, Printer, AlertTriangle,
  ArrowRight, ArrowLeft, Search, SkipForward, Send,
} from 'lucide-react';
import { db } from '../services/datenzugriff';
import { collection, doc, writeBatch, serverTimestamp, supabase } from '@/services/supabase-bridge';
import { zustellweg } from '../lib/erfassen';
import { hasUsableEmail } from '../lib/memberEmail';
import PostGuthabenDialog from './PostGuthabenDialog';
import type { Payment, UserProfile } from '../types';

// Rechnungsassistent: Beitragsrechnungen fuer viele Mitglieder auf einmal.
//
//   1. Wer       Aktive ohne Rechnung fuer das Jahr, oder eine Auswahl.
//   2. Pruefen   Betrag und Zustellweg je Person: E-Mail, Post, beides --
//                und was nicht geht (keine Adresse), BEVOR etwas entsteht.
//   3. Laeuft    erstellen, E-Mails versenden, Briefe einreihen.
//   4. Uebersicht was erledigt ist, was uebersprungen wurde, was scheiterte.
//
// Der Zustellweg kommt aus derselben Regel wie ueberall (lib/erfassen):
// ohne brauchbare E-Mail geht die Rechnung per Post, "beides" heisst
// E-Mail UND Brief. Wer fuer das Jahr schon eine Beitragsrechnung hat,
// wird uebersprungen -- ein zweiter Lauf erzeugt keine zweite Rechnung.

type Weg = 'EMAIL' | 'POST' | 'BOTH';
type Zeile = {
  u: UserProfile; amount: number; currency: string; weg: Weg;
  ohneMail: boolean;     // wollte E-Mail, hat keine brauchbare -> Post
  ohneAdresse: boolean;  // Brief noetig, aber keine vollstaendige Anschrift
};
type Ergebnis = {
  erstellt: { name: string; weg: Weg; betrag: string }[];
  uebersprungen: string[];
  mailGut: string[]; mailFehler: { name: string; grund: string }[];
  postGut: string[]; postFehler: { name: string; grund: string }[];
  mailAus: number; postAus: number;   // nicht versendet, weil abgewaehlt
};

const name = (u: any) => u?.displayName || `${u?.firstName || ''} ${u?.lastName || ''}`.trim() || u?.id;
const geld = (n: number, w: string) => `${w} ${Number(n || 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const hatAnschrift = (u: any) => !!((u?.address || u?.street) && u?.zip && u?.city);
const in30Tagen = () => new Date(Date.now() + 30 * 864e5).toISOString().slice(0, 10);

const WegMarke: React.FC<{ weg: Weg }> = ({ weg }) => (
  <span className="flex gap-1">
    {(weg === 'EMAIL' || weg === 'BOTH') && <span className="flex items-center gap-1 text-[10px] font-bold text-sky-700 bg-sky-50 px-2 py-0.5 rounded"><Mail size={10} /> E-Mail</span>}
    {(weg === 'POST' || weg === 'BOTH') && <span className="flex items-center gap-1 text-[10px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded"><Printer size={10} /> Post</span>}
  </span>
);

const RechnungsAssistent: React.FC<{
  users: UserProfile[]; payments: Payment[]; jahr: number;
  beitragVon: (u: UserProfile) => { amount: number; currency: string };
  zahlart: (land?: string) => string;
  mailen: (p: Payment, melde: (g: string) => void) => Promise<boolean>;
  aufgeben: (p: Payment, melde: (g: string) => void) => Promise<boolean>;
  holen: (ids: string[]) => Promise<Payment[]>;
  onClose: () => void;
}> = ({ users, payments, jahr, beitragVon, zahlart, mailen, aufgeben, holen, onClose }) => {
  const [schritt, setSchritt] = useState<'WER' | 'PRUEFEN' | 'LAEUFT' | 'FERTIG'>('WER');
  const [modus, setModus] = useState<'OHNE_RECHNUNG' | 'AUSWAHL'>('OHNE_RECHNUNG');
  const [auswahl, setAuswahl] = useState<Set<string>>(new Set());
  const [suche, setSuche] = useState('');
  const [beschreibung, setBeschreibung] = useState(`Mitgliederbeitrag ${jahr}`);
  const [faellig, setFaellig] = useState(in30Tagen());
  const [mailJetzt, setMailJetzt] = useState(true);
  const [postJetzt, setPostJetzt] = useState(true);
  const [postModul, setPostModul] = useState<boolean | null>(null);
  const [guthabenDialog, setGuthabenDialog] = useState(false);
  const [stand, setStand] = useState('');
  const [fortschritt, setFortschritt] = useState({ fertig: 0, gesamt: 0 });
  const [ergebnis, setErgebnis] = useState<Ergebnis | null>(null);

  const schonBerechnet = useMemo(() => new Set(
    payments.filter(p => p.type === 'FEE' && p.billingYear === jahr && p.userId).map(p => p.userId as string)
  ), [payments, jahr]);

  const aktive = useMemo(() => users.filter(u => u.membershipStatus === 'ACTIVE'), [users]);
  const kandidaten = useMemo(() => modus === 'OHNE_RECHNUNG'
    ? aktive.filter(u => !schonBerechnet.has(u.id))
    : users.filter(u => auswahl.has(u.id)), [modus, aktive, users, auswahl, schonBerechnet]);
  const uebersprungen = useMemo(() => kandidaten.filter(u => schonBerechnet.has(u.id)), [kandidaten, schonBerechnet]);

  const zeilen: Zeile[] = useMemo(() => kandidaten.filter(u => !schonBerechnet.has(u.id)).map(u => {
    const { amount, currency } = beitragVon(u);
    const weg = zustellweg(u as any) as Weg;
    return {
      u, amount, currency, weg,
      ohneMail: !hasUsableEmail(u as any) && (u as any).invoiceDeliveryMethod !== 'POST',
      ohneAdresse: weg !== 'EMAIL' && !hatAnschrift(u),
    };
  }), [kandidaten, schonBerechnet, beitragVon]);

  const zahl = (w: Weg) => zeilen.filter(z => z.weg === w).length;
  const mitPost = zeilen.filter(z => z.weg !== 'EMAIL' && !z.ohneAdresse).length;
  const mitMail = zeilen.filter(z => z.weg !== 'POST').length;
  const summen = useMemo(() => {
    const m = new Map<string, number>();
    zeilen.forEach(z => m.set(z.currency, (m.get(z.currency) || 0) + Number(z.amount || 0)));
    return [...m.entries()];
  }, [zeilen]);

  // Ist der Briefversand ueberhaupt aktiv? Sonst gar nicht erst anbieten.
  useEffect(() => {
    if (schritt !== 'PRUEFEN' || postModul !== null) return;
    supabase.rpc('post_guthaben_vor_versand').then(({ data, error }) => {
      const an = !error && !!(data as any)?.modul_aktiv;
      setPostModul(an);
      if (!an) setPostJetzt(false);
    });
  }, [schritt]);

  const auswaehlbar = useMemo(() => {
    const s = suche.trim().toLowerCase();
    return users.filter(u => u.membershipStatus !== 'INACTIVE')
      .filter(u => !s || [u.displayName, u.email, (u as any).city].some(v => String(v ?? '').toLowerCase().includes(s)));
  }, [users, suche]);

  const starten = () => {
    if (postJetzt && postModul && mitPost > 0) setGuthabenDialog(true);
    else laufen();
  };

  const laufen = async () => {
    setGuthabenDialog(false);
    setSchritt('LAEUFT');
    const e: Ergebnis = { erstellt: [], uebersprungen: uebersprungen.map(name), mailGut: [], mailFehler: [],
                          postGut: [], postFehler: [], mailAus: 0, postAus: 0 };
    try {
      // 1. Erstellen -- in Paketen, ein Batch hat eine Obergrenze.
      setStand('Rechnungen werden erstellt …');
      setFortschritt({ fertig: 0, gesamt: zeilen.length });
      const ids: string[] = [];
      for (let i = 0; i < zeilen.length; i += 200) {
        const batch = writeBatch(db);
        zeilen.slice(i, i + 200).forEach((z, k) => {
          const ref = doc(collection(db, 'payments'));
          ids.push(ref.id);
          batch.set(ref, {
            description: beschreibung || `Mitgliederbeitrag ${jahr}`, dueDate: faellig, status: 'PENDING',
            type: 'FEE', billingYear: jahr, method: zahlart(z.u.country), userId: z.u.id,
            amount: z.amount, currency: z.currency, deliveryMethod: z.weg, timestamp: serverTimestamp(),
            invoiceNumber: `INV-${Date.now().toString().slice(-6)}-${String(i + k).padStart(3, '0')}${Math.floor(Math.random() * 100).toString().padStart(2, '0')}`,
          });
          e.erstellt.push({ name: name(z.u), weg: z.weg, betrag: geld(z.amount, z.currency) });
        });
        await batch.commit();
        setFortschritt({ fertig: Math.min(i + 200, zeilen.length), gesamt: zeilen.length });
      }

      // Die Rechnungen so holen, wie die Datenbank sie gespeichert hat --
      // mit Referenz und Zeitstempel, die der Versand braucht.
      const neu = (await holen(ids)).filter(Boolean);
      const nach = new Map(neu.map(p => [p.id, p]));
      const paare = zeilen.map((z, i) => ({ z, p: nach.get(ids[i]) }));

      // 2. E-Mails
      const mails = paare.filter(x => x.z.weg !== 'POST');
      if (mailJetzt) {
        setStand('E-Mails werden versendet …');
        setFortschritt({ fertig: 0, gesamt: mails.length });
        let n = 0;
        for (const { z, p } of mails) {
          let grund = '';
          const ok = p ? await mailen(p, g => { grund = g; }) : (grund = 'Rechnung nicht gefunden', false);
          ok ? e.mailGut.push(name(z.u)) : e.mailFehler.push({ name: name(z.u), grund });
          setFortschritt({ fertig: ++n, gesamt: mails.length });
        }
      } else e.mailAus = mails.length;

      // 3. Briefe
      const briefe = paare.filter(x => x.z.weg !== 'EMAIL');
      if (postJetzt && postModul) {
        setStand('Briefe werden eingereiht …');
        setFortschritt({ fertig: 0, gesamt: briefe.length });
        let n = 0;
        for (const { z, p } of briefe) {
          let grund = '';
          const ok = p ? await aufgeben(p, g => { grund = g; }) : (grund = 'Rechnung nicht gefunden', false);
          ok ? e.postGut.push(name(z.u)) : e.postFehler.push({ name: name(z.u), grund });
          setFortschritt({ fertig: ++n, gesamt: briefe.length });
        }
      } else e.postAus = briefe.length;
    } catch (err: any) {
      e.mailFehler.push({ name: 'Lauf abgebrochen', grund: err?.message || String(err) });
    }
    setErgebnis(e);
    setSchritt('FERTIG');
  };

  const SCHRITTE = [['WER', 'Wer'], ['PRUEFEN', 'Prüfen'], ['LAEUFT', 'Erstellen'], ['FERTIG', 'Übersicht']] as const;
  const idx = SCHRITTE.findIndex(s => s[0] === schritt);

  return (
    <div className="fixed inset-0 z-[200] flex items-end sm:items-center justify-center sm:p-6 bg-stone-900/80 backdrop-blur-md">
      <motion.div initial={{ scale: 0.97, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full sm:max-w-3xl rounded-t-[2rem] sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[92dvh] overflow-hidden">
        {/* Kopf mit Schritten */}
        <div className="p-6 border-b border-stone-100">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h3 className="text-xl font-bold text-stone-900">Beitragsrechnungen {jahr}</h3>
              <p className="text-xs text-stone-500 mt-0.5">Assistent: auswählen, prüfen, erstellen und versenden</p>
            </div>
            {schritt !== 'LAEUFT' && <button onClick={onClose} className="p-2 hover:bg-stone-100 rounded-full"><X size={20} /></button>}
          </div>
          <div className="flex gap-2 mt-4">
            {SCHRITTE.map(([k, l], i) => (
              <div key={k} className="flex-1">
                <div className={`h-1.5 rounded-full ${i <= idx ? 'bg-primary' : 'bg-stone-100'}`} />
                <p className={`text-[10px] font-bold uppercase tracking-widest mt-1.5 ${i === idx ? 'text-stone-900' : 'text-stone-400'}`}>{i + 1}. {l}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-5">
          {schritt === 'WER' && (
            <>
              <div className="grid sm:grid-cols-2 gap-3">
                {([
                  ['OHNE_RECHNUNG', 'Alle Aktiven ohne Rechnung', `${aktive.filter(u => !schonBerechnet.has(u.id)).length} von ${aktive.length} aktiven Mitgliedern haben für ${jahr} noch keine Beitragsrechnung.`],
                  ['AUSWAHL', 'Eigene Auswahl', 'Einzelne Mitglieder auswählen.'],
                ] as const).map(([k, t, z]) => (
                  <button key={k} onClick={() => setModus(k)}
                    className={`text-left p-4 rounded-2xl border-2 transition ${modus === k ? 'border-primary bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]' : 'border-stone-100 hover:border-stone-200'}`}>
                    <p className="font-bold text-sm text-stone-900 flex items-center gap-2"><Users size={15} /> {t}</p>
                    <p className="text-xs text-stone-500 mt-1 leading-relaxed">{z}</p>
                  </button>
                ))}
              </div>

              {modus === 'AUSWAHL' && (
                <div>
                  <div className="flex gap-2 mb-2">
                    <div className="relative flex-1">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={14} />
                      <input value={suche} onChange={e => setSuche(e.target.value)} placeholder="Suchen"
                        className="w-full pl-9 pr-3 py-2 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none" />
                    </div>
                    <button onClick={() => setAuswahl(auswahl.size === auswaehlbar.length ? new Set() : new Set(auswaehlbar.map(u => u.id)))}
                      className="text-xs font-bold text-primary px-2">{auswahl.size === auswaehlbar.length ? 'Keine' : `Alle (${auswaehlbar.length})`}</button>
                  </div>
                  <div className="max-h-60 overflow-y-auto border border-stone-200 rounded-xl divide-y divide-stone-50">
                    {auswaehlbar.map(u => (
                      <label key={u.id} className="flex items-center gap-3 px-4 py-2 hover:bg-stone-50 cursor-pointer">
                        <input type="checkbox" checked={auswahl.has(u.id)} className="accent-primary"
                          onChange={() => { const n = new Set(auswahl); n.has(u.id) ? n.delete(u.id) : n.add(u.id); setAuswahl(n); }} />
                        <span className="text-sm flex-1 truncate">{name(u)}</span>
                        {schonBerechnet.has(u.id) && <span className="text-[10px] font-bold text-stone-400">hat schon Rechnung</span>}
                        <WegMarke weg={zustellweg(u as any) as Weg} />
                      </label>
                    ))}
                  </div>
                </div>
              )}

              <div className="grid sm:grid-cols-3 gap-3">
                <div className="sm:col-span-2">
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Beschreibung</label>
                  <input value={beschreibung} onChange={e => setBeschreibung(e.target.value)} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Fällig am</label>
                  <input type="date" value={faellig} onChange={e => setFaellig(e.target.value)} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm" />
                </div>
              </div>
            </>
          )}

          {schritt === 'PRUEFEN' && (
            <>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-center">
                {[
                  ['Rechnungen', zeilen.length, 'text-stone-900'],
                  ['nur E-Mail', zahl('EMAIL'), 'text-sky-700'],
                  ['nur Post', zahl('POST'), 'text-amber-700'],
                  ['E-Mail + Post', zahl('BOTH'), 'text-violet-700'],
                ].map(([l, n, f]) => (
                  <div key={l as string} className="bg-stone-50 rounded-2xl p-3">
                    <p className={`text-2xl font-bold ${f}`}>{n as number}</p>
                    <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{l as string}</p>
                  </div>
                ))}
              </div>
              <p className="text-xs text-stone-500">Summe: {summen.map(([w, b]) => geld(b, w)).join(' · ') || '—'}
                {uebersprungen.length > 0 && <> · <span className="font-bold">{uebersprungen.length} übersprungen</span> (haben schon eine Rechnung {jahr})</>}</p>

              {zeilen.some(z => z.ohneAdresse) && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-100 text-xs text-rose-800 flex gap-2">
                  <AlertTriangle size={14} className="shrink-0 mt-0.5" />
                  {zeilen.filter(z => z.ohneAdresse).length} Rechnung(en) müssten per Post gehen, aber die Anschrift ist unvollständig. Sie werden erstellt, der Brief wird aber nicht aufgegeben. Ergänze die Adresse und gib ihn später auf.
                </div>
              )}

              <div className="border border-stone-100 rounded-2xl divide-y divide-stone-50 max-h-72 overflow-y-auto">
                {zeilen.map(z => (
                  <div key={z.u.id} className="px-4 py-2.5 flex items-center gap-3 text-sm">
                    <span className="flex-1 min-w-0">
                      <span className="font-bold text-stone-800 truncate block">{name(z.u)}</span>
                      {(z.ohneMail || z.ohneAdresse) && (
                        <span className={`text-[11px] ${z.ohneAdresse ? 'text-rose-600' : 'text-amber-700'}`}>
                          {z.ohneAdresse ? 'Anschrift unvollständig — kein Brief möglich' : 'keine brauchbare E-Mail — geht per Post'}
                        </span>
                      )}
                    </span>
                    <WegMarke weg={z.weg} />
                    <span className="font-mono text-xs text-stone-600 w-24 text-right">{geld(z.amount, z.currency)}</span>
                  </div>
                ))}
                {zeilen.length === 0 && <p className="p-6 text-center text-sm text-stone-400">Niemand zu berechnen.</p>}
              </div>

              <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={mailJetzt} onChange={e => setMailJetzt(e.target.checked)} className="accent-primary" />
                  <Send size={14} className="text-sky-600" /> {mitMail} E-Mail(s) gleich versenden
                </label>
                <label className={`flex items-center gap-2 text-sm ${postModul === false ? 'opacity-50' : 'cursor-pointer'}`}>
                  <input type="checkbox" checked={postJetzt} disabled={postModul === false} onChange={e => setPostJetzt(e.target.checked)} className="accent-primary" />
                  <Printer size={14} className="text-amber-600" /> {mitPost} Brief(e) gleich aufgeben
                  {postModul === false && <span className="text-xs text-stone-500">— Briefversand ist nicht aktiv (Paket Voll)</span>}
                </label>
                <p className="text-[11px] text-stone-400">Abgewählt bleibt die Rechnung offen und lässt sich später in der Liste versenden.</p>
              </div>
            </>
          )}

          {schritt === 'LAEUFT' && (
            <div className="py-10 text-center space-y-4">
              <Loader2 className="animate-spin text-primary mx-auto" size={32} />
              <p className="font-bold text-stone-800">{stand}</p>
              <div className="max-w-sm mx-auto h-2 bg-stone-100 rounded-full overflow-hidden">
                <div className="h-full bg-primary transition-[width] duration-300 ease-out-strong" style={{ width: `${fortschritt.gesamt ? (fortschritt.fertig / fortschritt.gesamt) * 100 : 0}%` }} />
              </div>
              <p className="text-xs text-stone-500">{fortschritt.fertig} von {fortschritt.gesamt} · Bitte das Fenster offen lassen.</p>
            </div>
          )}

          {schritt === 'FERTIG' && ergebnis && (
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <CheckCircle2 className="text-emerald-600" size={28} />
                <div>
                  <p className="font-bold text-lg text-stone-900">{ergebnis.erstellt.length} Rechnung(en) erstellt</p>
                  <p className="text-xs text-stone-500">
                    {ergebnis.erstellt.filter(x => x.weg === 'EMAIL').length} E-Mail · {ergebnis.erstellt.filter(x => x.weg === 'POST').length} Post · {ergebnis.erstellt.filter(x => x.weg === 'BOTH').length} beides
                  </p>
                </div>
              </div>
              <div className="grid sm:grid-cols-2 gap-3">
                <Kachel I={Mail} farbe="sky" titel="E-Mails" gut={ergebnis.mailGut.length} fehler={ergebnis.mailFehler} aus={ergebnis.mailAus}
                  gutText="in den Versand gegeben" ausText="nicht versendet (abgewählt)" />
                <Kachel I={Printer} farbe="amber" titel="Briefe" gut={ergebnis.postGut.length} fehler={ergebnis.postFehler} aus={ergebnis.postAus}
                  gutText="eingereiht — Pingen übernimmt sie innert 10 Min." ausText="nicht aufgegeben (abgewählt oder Briefversand aus)" />
              </div>
              {ergebnis.uebersprungen.length > 0 && (
                <details className="p-4 rounded-2xl bg-stone-50 text-sm">
                  <summary className="font-bold cursor-pointer flex items-center gap-2"><SkipForward size={14} /> {ergebnis.uebersprungen.length} übersprungen — haben schon eine Rechnung {jahr}</summary>
                  <p className="text-xs text-stone-500 mt-2 leading-relaxed">{ergebnis.uebersprungen.join(', ')}</p>
                </details>
              )}
              <details className="p-4 rounded-2xl border border-stone-100 text-sm">
                <summary className="font-bold cursor-pointer flex items-center gap-2"><ClipboardCheck size={14} /> Alle erstellten Rechnungen</summary>
                <div className="mt-2 divide-y divide-stone-50">
                  {ergebnis.erstellt.map((x, i) => (
                    <div key={i} className="py-1.5 flex items-center gap-3 text-xs"><span className="flex-1">{x.name}</span><WegMarke weg={x.weg} /><span className="font-mono w-24 text-right">{x.betrag}</span></div>
                  ))}
                </div>
              </details>
            </div>
          )}
        </div>

        <div className="p-5 border-t border-stone-100 bg-stone-50 flex justify-between gap-3">
          {schritt === 'PRUEFEN' ? (
            <button onClick={() => setSchritt('WER')} className="px-5 py-3 rounded-xl font-bold text-stone-500 hover:bg-stone-200 flex items-center gap-2"><ArrowLeft size={16} /> Zurück</button>
          ) : <span />}
          {schritt === 'WER' && (
            <button onClick={() => setSchritt('PRUEFEN')} disabled={kandidaten.length === 0}
              className="px-6 py-3 rounded-xl font-bold bg-stone-900 text-white disabled:opacity-40 flex items-center gap-2">
              Weiter: prüfen ({kandidaten.length}) <ArrowRight size={16} />
            </button>
          )}
          {schritt === 'PRUEFEN' && (
            <button onClick={starten} disabled={zeilen.length === 0}
              className="px-6 py-3 rounded-xl font-bold bg-primary text-white disabled:opacity-40 flex items-center gap-2">
              {zeilen.length} erstellen{(mailJetzt && mitMail) || (postJetzt && postModul && mitPost) ? ' und versenden' : ''} <ArrowRight size={16} />
            </button>
          )}
          {schritt === 'FERTIG' && (
            <button onClick={onClose} className="px-6 py-3 rounded-xl font-bold bg-stone-900 text-white">Fertig</button>
          )}
        </div>
      </motion.div>

      {guthabenDialog && (
        <PostGuthabenDialog anzahl={mitPost} onAbbrechen={() => setGuthabenDialog(false)} onAufgeben={laufen} />
      )}
    </div>
  );
};

const Kachel: React.FC<{
  I: any; farbe: 'sky' | 'amber'; titel: string; gut: number; fehler: { name: string; grund: string }[];
  aus: number; gutText: string; ausText: string;
}> = ({ I, farbe, titel, gut, fehler, aus, gutText, ausText }) => (
  <div className={`p-4 rounded-2xl border ${farbe === 'sky' ? 'border-sky-100 bg-sky-50/40' : 'border-amber-100 bg-amber-50/40'}`}>
    <p className="font-bold text-sm text-stone-900 flex items-center gap-2 mb-2"><I size={15} /> {titel}</p>
    <p className="text-sm"><span className="font-bold text-emerald-700">{gut}</span> {gutText}</p>
    {aus > 0 && <p className="text-xs text-stone-500 mt-1">{aus} {ausText}</p>}
    {fehler.length > 0 && (
      <div className="mt-2 space-y-1">
        <p className="text-xs font-bold text-rose-700">{fehler.length} nicht erledigt:</p>
        {fehler.map((f, i) => <p key={i} className="text-[11px] text-rose-700">{f.name}: {f.grund}</p>)}
      </div>
    )}
  </div>
);

export default RechnungsAssistent;
