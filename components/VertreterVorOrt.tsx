import React, { useEffect, useState } from 'react';
import {
  Banknote, Loader2, X, Camera, ArrowDownLeft, ArrowUpRight, Landmark, Undo2, Trash2,
  Plus, CheckCircle2, Hammer, Clock, UserPlus,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { UserProfile, Neighborhood } from '../types';

// Die Werkzeuge des Vertreters vor Ort: kassieren, Handkasse, Ausgaben,
// Neuerfassung, Aufgaben.
//
// Alles laeuft ueber Datenbankfunktionen (vertreter_*). Sie pruefen Recht und
// Nachbarschaft und schreiben genau das, was der Vorgang verlangt; diese
// Masken zeigen nur, was durchgeht, und reichen die Meldung der Datenbank
// sonst unveraendert weiter -- sie ist dort in ganzen Saetzen formuliert.

export type VorOrtRechte = {
  kassieren: boolean; ausgaben: boolean; erfassen: boolean; aufgaben: boolean;
};

const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)] transition-colors';
const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';
const geld = (n: number, w: string) => `${w} ${Number(n || 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const zahl = (s: string) => Number(String(s).replace(',', '.'));

// Ein Handyfoto hat gern 8 MB; der Speicher nimmt hoechstens 5. Fuer einen
// Kassenbon reichen 1600 Pixel Kantenlaenge.
async function belegHochladen(datei: File): Promise<string> {
  let blob: Blob = datei;
  if (datei.type.startsWith('image/')) {
    // HEIC vom iPhone kann nicht jeder Browser lesen -- dann das Original.
    try {
      const bild = await createImageBitmap(datei);
      const f = Math.min(1, 1600 / Math.max(bild.width, bild.height));
      const c = document.createElement('canvas');
      c.width = Math.round(bild.width * f); c.height = Math.round(bild.height * f);
      c.getContext('2d')!.drawImage(bild, 0, 0, c.width, c.height);
      blob = await new Promise<Blob>((ok, nein) => c.toBlob(b => (b ? ok(b) : nein(new Error('Bild nicht lesbar'))), 'image/jpeg', 0.8));
    } catch {
      blob = datei;
    }
  }
  if (blob.size > 5 * 1024 * 1024) throw new Error('Der Beleg ist größer als 5 MB.');
  const pfad = `belege/${crypto.randomUUID()}.${blob.type === 'image/jpeg' ? 'jpg' : (datei.name.split('.').pop() || 'bin')}`;
  const { error } = await supabase.storage.from('uploads').upload(pfad, blob, { contentType: blob.type || datei.type });
  if (error) throw error;
  return supabase.storage.from('uploads').getPublicUrl(pfad).data.publicUrl;
}

const Fenster: React.FC<{ titel: string; onClose: () => void; children: React.ReactNode }> = ({ titel, onClose, children }) => (
  <div className="fixed inset-0 z-[200] bg-black/40 flex items-end md:items-center justify-center p-0 md:p-6" onClick={onClose}>
    <div className="bg-white w-full md:max-w-lg rounded-t-[2rem] md:rounded-[2rem] p-6 md:p-8 space-y-5 max-h-[92dvh] overflow-y-auto"
         onClick={e => e.stopPropagation()}>
      <div className="flex items-center justify-between gap-4">
        <h3 className="text-xl font-bold text-stone-900">{titel}</h3>
        <button onClick={onClose} className="p-2 text-stone-400 hover:text-stone-700" aria-label="Schliessen"><X size={18} /></button>
      </div>
      {children}
    </div>
  </div>
);

// ------------------------------------------------------------ Kassieren
export const KassierenDialog: React.FC<{
  mitglied: UserProfile; onClose: () => void; onDone: () => void;
}> = ({ mitglied, onClose, onDone }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [vorschlag, setVorschlag] = useState<any>(null);
  const [betrag, setBetrag] = useState('');
  const [notiz, setNotiz] = useState('');
  const [laeuft, setLaeuft] = useState(false);

  useEffect(() => {
    supabase.rpc('vertreter_kassier_vorschlag', { p_mitglied: mitglied.id }).then(({ data, error }) => {
      if (error) { showAlert({ type: 'error', message: error.message }); onClose(); return; }
      setVorschlag(data);
      if (data?.betrag != null) setBetrag(String(data.betrag));
    });
  }, [mitglied.id]);

  const kassieren = async () => {
    const b = zahl(betrag);
    if (!Number.isFinite(b) || b <= 0) { showAlert({ type: 'error', message: t('steward.amount_invalid') }); return; }
    setLaeuft(true);
    const { data, error } = await supabase.rpc('vertreter_kassieren', {
      p_mitglied: mitglied.id, p_betrag: b, p_waehrung: vorschlag?.waehrung ?? null, p_notiz: notiz || null,
    });
    setLaeuft(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    showAlert({
      type: 'success',
      message: (data as any)?.status === 'PAID'
        ? t('vorort.collected_paid', { name: mitglied.displayName || '', amount: geld(b, (data as any).waehrung) })
        : t('vorort.collected_partial', { amount: geld(b, (data as any).waehrung), rest: geld(Number((data as any).soll) - Number((data as any).bezahlt), (data as any).waehrung) }),
    });
    onDone();
  };

  return (
    <Fenster titel={t('vorort.collect_title', { name: mitglied.displayName || '' })} onClose={onClose}>
      {!vorschlag ? <Loader2 className="animate-spin text-primary mx-auto" /> : vorschlag.bereits_bezahlt ? (
        <p className="text-sm text-stone-600">{t('vorort.already_paid', { year: vorschlag.jahr })}</p>
      ) : (
        <>
          <p className="text-sm text-stone-500 leading-relaxed">
            {vorschlag.rechnung ? t('vorort.collect_invoice', { what: vorschlag.beschreibung || '' }) : t('vorort.collect_new', { year: vorschlag.jahr })}
          </p>
          <div>
            <label className={marke}>{t('vorort.amount')} ({vorschlag.waehrung})</label>
            <input inputMode="decimal" value={betrag} onChange={e => setBetrag(e.target.value)}
                   className={`${feld} text-2xl font-bold`} autoFocus />
          </div>
          <div>
            <label className={marke}>{t('vorort.note')}</label>
            <input value={notiz} onChange={e => setNotiz(e.target.value)} className={feld} placeholder={t('vorort.note_ph')} />
          </div>
          <p className="text-[11px] text-stone-400 leading-relaxed">{t('vorort.collect_hint')}</p>
          <button onClick={kassieren} disabled={laeuft}
                  className="w-full py-4 bg-stone-900 text-white rounded-2xl font-bold flex items-center justify-center gap-2 disabled:opacity-50">
            {laeuft ? <Loader2 size={16} className="animate-spin" /> : <Banknote size={16} />} {t('vorort.collect_confirm')}
          </button>
        </>
      )}
    </Fenster>
  );
};

// ------------------------------------------------------------ Neuerfassung
export const MitgliedErfassenDialog: React.FC<{
  nachbarschaften: Neighborhood[]; onClose: () => void; onDone: (id: string) => void;
}> = ({ nachbarschaften, onClose, onDone }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [f, setF] = useState({ vorname: '', nachname: '', telefon: '', strasse: '', plz: '', ort: '',
                               nachbarschaft: nachbarschaften[0]?.id || '', gruppe: '' });
  const [laeuft, setLaeuft] = useState(false);
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setF({ ...f, [k]: e.target.value });

  const speichern = async () => {
    setLaeuft(true);
    const { data, error } = await supabase.rpc('vertreter_mitglied_anlegen', {
      p_vorname: f.vorname, p_nachname: f.nachname, p_telefon: f.telefon || null, p_strasse: f.strasse,
      p_plz: f.plz || null, p_ort: f.ort, p_nachbarschaft: f.nachbarschaft, p_gruppe: f.gruppe || null,
    });
    setLaeuft(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    showAlert({ type: 'success', message: t('vorort.member_created', { name: `${f.vorname} ${f.nachname}` }) });
    onDone(data as string);
  };

  return (
    <Fenster titel={t('vorort.new_member')} onClose={onClose}>
      <div className="grid grid-cols-2 gap-3">
        <div><label className={marke}>{t('field.firstName')}</label><input value={f.vorname} onChange={set('vorname')} className={feld} autoFocus /></div>
        <div><label className={marke}>{t('field.lastName')}</label><input value={f.nachname} onChange={set('nachname')} className={feld} /></div>
        <div className="col-span-2"><label className={marke}>{t('field.phone')}</label><input type="tel" value={f.telefon} onChange={set('telefon')} className={feld} /></div>
        <div className="col-span-2"><label className={marke}>{t('field.street')}</label><input value={f.strasse} onChange={set('strasse')} className={feld} /></div>
        <div><label className={marke}>{t('field.zip')}</label><input value={f.plz} onChange={set('plz')} className={feld} /></div>
        <div><label className={marke}>{t('field.city')}</label><input value={f.ort} onChange={set('ort')} className={feld} /></div>
        <div className="col-span-2">
          <label className={marke}>{t('admin.members.neighborhood')}</label>
          <select value={f.nachbarschaft} onChange={set('nachbarschaft')} className={feld}>
            {nachbarschaften.map(n => <option key={n.id} value={n.id}>{n.name}</option>)}
          </select>
        </div>
        <div className="col-span-2">
          <label className={marke}>{t('admin.members.billing_group')}</label>
          <select value={f.gruppe} onChange={set('gruppe')} className={feld}>
            <option value="">{t('vorort.group_auto')}</option>
            <option value="STANDARD">{t('admin.members.billing.standard')}</option>
            <option value="KOSOVO">{t('admin.members.billing.kosovo')}</option>
            <option value="REDUCED">{t('admin.members.billing.reduced')}</option>
          </select>
        </div>
      </div>
      <p className="text-[11px] text-stone-400 leading-relaxed">{t('vorort.new_member_hint')}</p>
      <button onClick={speichern} disabled={laeuft}
              className="w-full py-4 bg-stone-900 text-white rounded-2xl font-bold flex items-center justify-center gap-2 disabled:opacity-50">
        {laeuft ? <Loader2 size={16} className="animate-spin" /> : <UserPlus size={16} />} {t('vorort.new_member_save')}
      </button>
    </Fenster>
  );
};

// ------------------------------------------------------------ Handkasse
type Eintrag = {
  id: string; art: 'EINNAHME' | 'AUSGABE' | 'BANKEINZAHLUNG'; betrag: number; waehrung: string;
  notiz: string | null; beleg: string | null; erfasst_am: string; bestaetigt_am: string | null;
  mitglied_name: string | null; expenseId: string | null; ausgabe_status: string | null;
};

export const KasseTab: React.FC<{ rechte: VorOrtRechte; onGeaendert: () => void }> = ({ rechte, onGeaendert }) => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [stand, setStand] = useState<{ bestand: { waehrung: string; bestand: number; offen_einzahlung: number }[]; eintraege: Eintrag[] } | null>(null);
  const [form, setForm] = useState<null | 'AUSGABE' | 'EINZAHLUNG'>(null);
  const [f, setF] = useState({ empfaenger: '', betrag: '', waehrung: 'EUR', beschreibung: '', datum: new Date().toISOString().slice(0, 10) });
  const [datei, setDatei] = useState<File | null>(null);
  const [laeuft, setLaeuft] = useState(false);

  const laden = async () => {
    const { data, error } = await supabase.rpc('vertreter_kasse_lesen');
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setStand(data as any);
  };
  useEffect(() => { laden(); }, []);

  const heute = new Date().toISOString().slice(0, 10);
  const oeffnen = (art: 'AUSGABE' | 'EINZAHLUNG') => {
    const eur = stand?.bestand.find(b => b.waehrung === 'EUR');
    setF({ empfaenger: '', betrag: art === 'EINZAHLUNG' && eur ? String(eur.bestand) : '', waehrung: eur || !stand?.bestand.length ? 'EUR' : stand.bestand[0].waehrung,
           beschreibung: '', datum: heute });
    setDatei(null);
    setForm(art);
  };

  const speichern = async () => {
    const b = zahl(f.betrag);
    if (!Number.isFinite(b) || b <= 0) { showAlert({ type: 'error', message: t('steward.amount_invalid') }); return; }
    setLaeuft(true);
    try {
      const beleg = datei ? await belegHochladen(datei) : null;
      const { error } = form === 'AUSGABE'
        ? await supabase.rpc('vertreter_ausgabe', { p_empfaenger: f.empfaenger, p_betrag: b, p_waehrung: f.waehrung,
            p_beschreibung: f.beschreibung || null, p_datum: f.datum || null, p_beleg: beleg })
        : await supabase.rpc('vertreter_bankeinzahlung', { p_betrag: b, p_waehrung: f.waehrung,
            p_notiz: f.beschreibung || null, p_beleg: beleg });
      if (error) throw error;
      showAlert({ type: 'success', message: form === 'AUSGABE' ? t('vorort.expense_saved') : t('vorort.deposit_saved') });
      setForm(null);
      await laden();
      onGeaendert();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally {
      setLaeuft(false);
    }
  };

  const rueckgaengig = async (e: Eintrag) => {
    const ok = await showConfirm({
      title: t('vorort.undo_title'),
      message: e.art === 'EINNAHME' ? t('vorort.undo_income', { name: e.mitglied_name || '' }) : t('vorort.undo_expense'),
      confirmText: t('vorort.undo'), type: 'danger',
    });
    if (!ok) return;
    const { error } = e.art === 'EINNAHME'
      ? await supabase.rpc('vertreter_kassieren_rueckgaengig', { p_kasse: e.id })
      : await supabase.rpc('vertreter_ausgabe_loeschen', { p_ausgabe: e.expenseId });
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    await laden();
    onGeaendert();
  };

  if (!stand) return <Loader2 className="animate-spin text-primary mx-auto" />;
  const bestaende = stand.bestand.length ? stand.bestand : [{ waehrung: 'EUR', bestand: 0, offen_einzahlung: 0 }];

  return (
    <div className="space-y-5">
      <div className="grid gap-3 md:grid-cols-2">
        {bestaende.map(b => (
          <div key={b.waehrung} className="bg-stone-900 text-white rounded-[2rem] p-6">
            <p className="text-stone-400 text-[10px] font-bold uppercase tracking-widest">{t('vorort.cash_balance')}</p>
            <p className={`text-4xl font-bold mt-2 ${b.bestand < 0 ? 'text-rose-300' : ''}`}>{geld(b.bestand, b.waehrung)}</p>
            {b.offen_einzahlung > 0 && (
              <p className="text-xs text-amber-300 mt-2">{t('vorort.deposit_pending', { amount: geld(b.offen_einzahlung, b.waehrung) })}</p>
            )}
            {b.bestand < 0 && <p className="text-xs text-rose-300 mt-2">{t('vorort.negative_hint')}</p>}
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-2">
        <button onClick={() => oeffnen('EINZAHLUNG')} disabled={!bestaende.some(b => b.bestand > 0)}
                className="px-5 py-3 bg-stone-900 text-white rounded-xl font-bold text-sm flex items-center gap-2 disabled:opacity-40">
          <Landmark size={15} /> {t('vorort.deposit')}
        </button>
        {rechte.ausgaben && (
          <button onClick={() => oeffnen('AUSGABE')}
                  className="px-5 py-3 border border-stone-300 text-stone-800 rounded-xl font-bold text-sm flex items-center gap-2 hover:border-stone-500">
            <Plus size={15} /> {t('vorort.new_expense')}
          </button>
        )}
      </div>

      <div className="space-y-2">
        <p className={marke}>{t('vorort.history')}</p>
        {stand.eintraege.length === 0 && <p className="text-sm text-stone-400 italic">{t('vorort.history_empty')}</p>}
        {stand.eintraege.map(e => {
          const ein = e.art === 'EINNAHME';
          const darfZurueck = (ein && rechte.kassieren && e.erfasst_am.slice(0, 10) === heute)
            || (e.art === 'AUSGABE' && rechte.ausgaben && e.ausgabe_status === 'PENDING');
          return (
            <div key={e.id} className="bg-white border border-stone-100 rounded-2xl p-4 flex items-center gap-4">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                ein ? 'bg-emerald-50 text-emerald-600' : e.art === 'AUSGABE' ? 'bg-rose-50 text-rose-600' : 'bg-sky-50 text-sky-600'}`}>
                {ein ? <ArrowDownLeft size={18} /> : e.art === 'AUSGABE' ? <ArrowUpRight size={18} /> : <Landmark size={18} />}
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-bold text-sm text-stone-900 truncate">
                  {ein ? (e.mitglied_name || t('vorort.income')) : e.art === 'AUSGABE' ? (e.notiz || t('vorort.expense')) : t('vorort.deposit')}
                </p>
                <p className="text-xs text-stone-500">
                  {new Date(e.erfasst_am).toLocaleString('de-CH', { dateStyle: 'short', timeStyle: 'short' })}
                  {e.art === 'BANKEINZAHLUNG' && (e.bestaetigt_am ? ` · ${t('vorort.confirmed')}` : ` · ${t('vorort.unconfirmed')}`)}
                  {e.art === 'AUSGABE' && e.ausgabe_status && ` · ${e.ausgabe_status === 'PENDING' ? t('vorort.expense_pending') : t('vorort.expense_done')}`}
                  {ein && e.notiz ? ` · ${e.notiz}` : ''}
                  {e.beleg && <> · <a href={e.beleg} target="_blank" rel="noreferrer" className="underline">{t('vorort.receipt')}</a></>}
                </p>
              </div>
              <p className={`font-bold text-sm shrink-0 ${ein ? 'text-emerald-700' : 'text-stone-700'}`}>
                {ein ? '+' : '−'}{geld(e.betrag, e.waehrung)}
              </p>
              {darfZurueck && (
                <button onClick={() => rueckgaengig(e)} title={t('vorort.undo')}
                        className="p-2 text-stone-400 hover:text-rose-600 shrink-0">
                  {ein ? <Undo2 size={15} /> : <Trash2 size={15} />}
                </button>
              )}
            </div>
          );
        })}
      </div>

      {form && (
        <Fenster titel={form === 'AUSGABE' ? t('vorort.new_expense') : t('vorort.deposit')} onClose={() => setForm(null)}>
          {form === 'AUSGABE' && (
            <div><label className={marke}>{t('vorort.vendor')}</label>
              <input value={f.empfaenger} onChange={e => setF({ ...f, empfaenger: e.target.value })} className={feld} autoFocus /></div>
          )}
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2"><label className={marke}>{t('vorort.amount')}</label>
              <input inputMode="decimal" value={f.betrag} onChange={e => setF({ ...f, betrag: e.target.value })} className={`${feld} text-xl font-bold`} /></div>
            <div><label className={marke}>{t('vorort.currency')}</label>
              <select value={f.waehrung} onChange={e => setF({ ...f, waehrung: e.target.value })} className={feld}>
                <option>EUR</option><option>CHF</option>
              </select></div>
          </div>
          <div><label className={marke}>{form === 'AUSGABE' ? t('vorort.description') : t('vorort.note')}</label>
            <input value={f.beschreibung} onChange={e => setF({ ...f, beschreibung: e.target.value })} className={feld}
                   placeholder={form === 'AUSGABE' ? t('vorort.description_ph') : t('vorort.deposit_note_ph')} /></div>
          {form === 'AUSGABE' && (
            <div><label className={marke}>{t('vorort.date')}</label>
              <input type="date" value={f.datum} onChange={e => setF({ ...f, datum: e.target.value })} className={feld} /></div>
          )}
          <label className="flex items-center gap-3 p-4 border-2 border-dashed border-stone-200 rounded-2xl cursor-pointer hover:border-stone-400">
            <Camera size={20} className="text-stone-500" />
            <span className="text-sm text-stone-600 truncate">{datei ? datei.name : t('vorort.receipt_photo')}</span>
            <input type="file" accept="image/*,application/pdf" capture="environment" className="hidden"
                   onChange={e => setDatei(e.target.files?.[0] || null)} />
          </label>
          <p className="text-[11px] text-stone-400 leading-relaxed">
            {form === 'AUSGABE' ? t('vorort.expense_hint') : t('vorort.deposit_hint')}
          </p>
          <button onClick={speichern} disabled={laeuft || (form === 'AUSGABE' && !f.empfaenger.trim())}
                  className="w-full py-4 bg-stone-900 text-white rounded-2xl font-bold flex items-center justify-center gap-2 disabled:opacity-50">
            {laeuft && <Loader2 size={16} className="animate-spin" />} {t('common.save')}
          </button>
        </Fenster>
      )}
    </div>
  );
};

// ------------------------------------------------------------ Aufgaben
export const AufgabenTab: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [liste, setListe] = useState<any[] | null>(null);
  const [neu, setNeu] = useState(false);
  const [f, setF] = useState({ titel: '', beschreibung: '', prioritaet: 'MEDIUM', faellig: '' });
  const [laeuft, setLaeuft] = useState(false);

  const laden = async () => {
    const { data, error } = await supabase.rpc('vertreter_aufgaben');
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setListe((data as any[]) || []);
  };
  useEffect(() => { laden(); }, []);

  const anlegen = async () => {
    setLaeuft(true);
    const { error } = await supabase.rpc('vertreter_aufgabe_anlegen', {
      p_titel: f.titel, p_beschreibung: f.beschreibung || null, p_prioritaet: f.prioritaet, p_faellig: f.faellig || null,
    });
    setLaeuft(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setNeu(false); setF({ titel: '', beschreibung: '', prioritaet: 'MEDIUM', faellig: '' });
    laden();
  };

  const status = async (id: string, s: string) => {
    const { error } = await supabase.rpc('vertreter_aufgabe_status', { p_aufgabe: id, p_status: s });
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  const farbe: Record<string, string> = {
    HIGH: 'bg-rose-50 text-rose-700 border-rose-200', MEDIUM: 'bg-amber-50 text-amber-700 border-amber-200',
    LOW: 'bg-stone-100 text-stone-600 border-stone-200',
  };

  if (!liste) return <Loader2 className="animate-spin text-primary mx-auto" />;
  return (
    <div className="space-y-4">
      <button onClick={() => setNeu(true)}
              className="px-5 py-3 bg-stone-900 text-white rounded-xl font-bold text-sm flex items-center gap-2">
        <Plus size={15} /> {t('vorort.new_task')}
      </button>
      {liste.length === 0 && <p className="text-sm text-stone-400 italic">{t('vorort.tasks_empty')}</p>}
      {liste.map(a => (
        <div key={a.id} className={`bg-white border border-stone-100 rounded-2xl p-4 flex items-center gap-4 ${a.status === 'DONE' ? 'opacity-60' : ''}`}>
          <Hammer size={18} className="text-stone-400 shrink-0" />
          <div className="min-w-0 flex-1">
            <p className={`font-bold text-sm text-stone-900 ${a.status === 'DONE' ? 'line-through' : ''}`}>{a.title}</p>
            <p className="text-xs text-stone-500 flex flex-wrap gap-2 items-center mt-1">
              <span className={`px-2 py-0.5 rounded border text-[9px] font-bold uppercase ${farbe[a.priority] || farbe.LOW}`}>{t(`vorort.prio_${a.priority}`)}</span>
              {a.dueDate && <span className="flex items-center gap-1"><Clock size={11} /> {a.dueDate}</span>}
              {a.description && <span className="truncate">{a.description}</span>}
            </p>
          </div>
          {a.status !== 'DONE' ? (
            <div className="flex gap-2 shrink-0">
              {a.status === 'TODO' && (
                <button onClick={() => status(a.id, 'IN_PROGRESS')}
                        className="px-3 py-2 border border-stone-200 rounded-xl text-xs font-bold text-stone-600 hover:border-stone-400">
                  {t('vorort.task_start')}
                </button>
              )}
              <button onClick={() => status(a.id, 'DONE')}
                      className="px-3 py-2 bg-emerald-600 text-white rounded-xl text-xs font-bold flex items-center gap-1.5">
                <CheckCircle2 size={13} /> {t('vorort.task_done')}
              </button>
            </div>
          ) : (
            <button onClick={() => status(a.id, 'TODO')} className="text-[10px] font-bold uppercase text-stone-400 hover:text-stone-700 shrink-0">
              {t('vorort.task_reopen')}
            </button>
          )}
        </div>
      ))}

      {neu && (
        <Fenster titel={t('vorort.new_task')} onClose={() => setNeu(false)}>
          <div><label className={marke}>{t('vorort.task_title')}</label>
            <input value={f.titel} onChange={e => setF({ ...f, titel: e.target.value })} className={feld} autoFocus
                   placeholder={t('vorort.task_title_ph')} /></div>
          <div><label className={marke}>{t('vorort.description')}</label>
            <input value={f.beschreibung} onChange={e => setF({ ...f, beschreibung: e.target.value })} className={feld} /></div>
          <div className="grid grid-cols-2 gap-3">
            <div><label className={marke}>{t('vorort.priority')}</label>
              <select value={f.prioritaet} onChange={e => setF({ ...f, prioritaet: e.target.value })} className={feld}>
                <option value="LOW">{t('vorort.prio_LOW')}</option>
                <option value="MEDIUM">{t('vorort.prio_MEDIUM')}</option>
                <option value="HIGH">{t('vorort.prio_HIGH')}</option>
              </select></div>
            <div><label className={marke}>{t('vorort.due')}</label>
              <input type="date" value={f.faellig} onChange={e => setF({ ...f, faellig: e.target.value })} className={feld} /></div>
          </div>
          <button onClick={anlegen} disabled={laeuft || !f.titel.trim()}
                  className="w-full py-4 bg-stone-900 text-white rounded-2xl font-bold flex items-center justify-center gap-2 disabled:opacity-50">
            {laeuft && <Loader2 size={16} className="animate-spin" />} {t('common.save')}
          </button>
        </Fenster>
      )}
    </div>
  );
};
