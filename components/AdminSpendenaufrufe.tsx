import React, { useEffect, useState } from 'react';
import { Megaphone, Plus, Pencil, Trash2, Eye, EyeOff, Loader2, Save, X, CheckCheck } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

type Aufruf = {
  id: string; titel: string; text: string | null;
  ziel_betrag: number | null; waehrung: string;
  beginnt_am: string | null; endet_am: string | null;
  status: 'ENTWURF' | 'OEFFENTLICH' | 'BEENDET';
  reihenfolge: number;
};
type Stand = { id: string; gesammelt: number; anzahl: number; offen: number };

const LEER = {
  titel: '', text: '', ziel_betrag: '' as string | number,
  waehrung: 'CHF', beginnt_am: '', endet_am: '',
};

// Spendenaufrufe.
//
// Bis zum 29.09.2026 gab es sie nicht: der Spender tippte einen freien Zweck
// ins Formular, und der Verein konnte weder einen Aufruf anlegen noch sehen,
// wieviel auf ein Anliegen zusammengekommen ist.
//
// Ein Aufruf ist ein Anliegen mit Titel, Text, Ziel und Frist. Entwurf heisst:
// nur hier sichtbar. Öffentlich heisst: er steht auf der Spendenseite und
// Spenden können ihm zugeordnet werden. Beendet heisst: er verschwindet von
// der Seite, die bereits zugeordneten Spenden bleiben daran hängen.
const AdminSpendenaufrufe: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();

  const [aufrufe, setAufrufe] = useState<Aufruf[]>([]);
  const [staende, setStaende] = useState<Record<string, Stand>>({});
  const [laedt, setLaedt] = useState(true);
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [form, setForm] = useState<typeof LEER>({ ...LEER });
  const [bearbeitet, setBearbeitet] = useState<string | null>(null);
  const [offenesFormular, setOffenesFormular] = useState(false);

  const laden = async () => {
    const [{ data: a }, { data: s }] = await Promise.all([
      supabase.from('spendenaufrufe').select('*').order('reihenfolge').order('erstellt_am', { ascending: false }),
      supabase.rpc('spendenaufrufe_stand'),
    ]);
    setAufrufe((a as Aufruf[]) || []);
    const karte: Record<string, Stand> = {};
    ((s as Stand[]) || []).forEach(x => { karte[x.id] = x; });
    setStaende(karte);
    setLaedt(false);
  };
  useEffect(() => { laden(); }, []);

  const sichern = async () => {
    if (!form.titel.trim()) { showAlert({ type: 'warning', message: t('aufruf.titel_fehlt') }); return; }
    setArbeitet(bearbeitet || 'neu');
    const inhalt = {
      titel: form.titel.trim(),
      text: form.text?.trim() || null,
      ziel_betrag: form.ziel_betrag === '' ? null : Number(form.ziel_betrag),
      waehrung: form.waehrung || 'CHF',
      beginnt_am: form.beginnt_am || null,
      endet_am: form.endet_am || null,
    };
    const { error } = bearbeitet
      ? await supabase.from('spendenaufrufe').update(inhalt).eq('id', bearbeitet)
      : await supabase.from('spendenaufrufe').insert([{ ...inhalt, status: 'ENTWURF' }]);
    setArbeitet(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    abbrechen();
    laden();
  };

  const bearbeiten = (a: Aufruf) => {
    setBearbeitet(a.id); setOffenesFormular(true);
    setForm({
      titel: a.titel, text: a.text || '',
      ziel_betrag: a.ziel_betrag ?? '', waehrung: a.waehrung || 'CHF',
      beginnt_am: a.beginnt_am || '', endet_am: a.endet_am || '',
    });
  };
  const abbrechen = () => { setBearbeitet(null); setForm({ ...LEER }); setOffenesFormular(false); };

  const status = async (a: Aufruf, neu: Aufruf['status']) => {
    setArbeitet(a.id);
    const { error } = await supabase.from('spendenaufrufe').update({ status: neu }).eq('id', a.id);
    setArbeitet(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  const entfernen = async (a: Aufruf) => {
    const stand = staende[a.id];
    const ja = await showConfirm({
      title: t('aufruf.entfernen'),
      message: stand && stand.anzahl > 0
        ? t('aufruf.entfernen_mit_spenden', { titel: a.titel, anzahl: stand.anzahl })
        : t('aufruf.entfernen_frage', { titel: a.titel }),
      confirmText: t('aufruf.entfernen'), type: 'danger',
    });
    if (!ja) return;
    const { error } = await supabase.from('spendenaufrufe').delete().eq('id', a.id);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    if (bearbeitet === a.id) abbrechen();
    laden();
  };

  const feld = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';
  const geld = (n: number, w = 'CHF') => `${Number(n || 0).toLocaleString('de-CH')} ${w}`;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div className="flex items-center gap-2">
          <Megaphone size={17} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('aufruf.titel_bereich')}</h3>
        </div>
        {!offenesFormular && (
          <button onClick={() => { setForm({ ...LEER }); setBearbeitet(null); setOffenesFormular(true); }}
            className="bg-stone-900 text-white px-5 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors">
            <Plus size={14} /> {t('aufruf.neu')}
          </button>
        )}
      </div>

      {offenesFormular && (
        <div className={`bg-white p-6 rounded-2xl border shadow-sm space-y-4 ${
          bearbeitet ? 'border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]' : 'border-stone-200'}`}>
          <div className="flex items-center justify-between">
            <p className="font-bold text-sm text-stone-900 flex items-center gap-2">
              {bearbeitet ? <Pencil size={14} className="text-primary" /> : <Plus size={14} className="text-stone-400" />}
              {bearbeitet ? t('aufruf.bearbeiten') : t('aufruf.neu')}
            </p>
            <button onClick={abbrechen} className="text-xs font-bold text-stone-400 hover:text-stone-600 flex items-center gap-1">
              <X size={13} /> {t('common.cancel')}
            </button>
          </div>

          <div>
            <label className={marke}>{t('aufruf.feld_titel')}</label>
            <input value={form.titel} onChange={e => setForm({ ...form, titel: e.target.value })}
              className={feld} placeholder={t('aufruf.titel_beispiel')} />
          </div>
          <div>
            <label className={marke}>{t('aufruf.feld_text')}</label>
            <textarea value={form.text} onChange={e => setForm({ ...form, text: e.target.value })}
              rows={3} className={feld} placeholder={t('aufruf.text_beispiel')} />
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div>
              <label className={marke}>{t('aufruf.ziel')}</label>
              <input type="number" min={0} step="10" value={form.ziel_betrag}
                onChange={e => setForm({ ...form, ziel_betrag: e.target.value })}
                className={feld} placeholder="8000" />
            </div>
            <div>
              <label className={marke}>{t('field.currency')}</label>
              <select value={form.waehrung} onChange={e => setForm({ ...form, waehrung: e.target.value })} className={feld}>
                <option value="CHF">CHF</option><option value="EUR">EUR</option>
              </select>
            </div>
            <div>
              <label className={marke}>{t('aufruf.beginn')}</label>
              <input type="date" value={form.beginnt_am} onChange={e => setForm({ ...form, beginnt_am: e.target.value })} className={feld} />
            </div>
            <div>
              <label className={marke}>{t('aufruf.ende')}</label>
              <input type="date" value={form.endet_am} onChange={e => setForm({ ...form, endet_am: e.target.value })} className={feld} />
            </div>
          </div>
          <p className="text-[11px] text-stone-400">{t('aufruf.entwurf_hinweis')}</p>
          <button onClick={sichern} disabled={!!arbeitet}
            className="bg-primary text-white px-6 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 hover:opacity-90 disabled:opacity-50">
            {arbeitet ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {bearbeitet ? t('common.save_changes') : t('aufruf.anlegen')}
          </button>
        </div>
      )}

      {laedt ? (
        <div className="flex items-center gap-2 p-5 text-stone-400 text-sm">
          <Loader2 className="animate-spin" size={15} /> {t('common.loading')}
        </div>
      ) : aufrufe.length === 0 ? (
        <div className="text-center py-10 bg-stone-50/60 rounded-2xl border border-dashed border-stone-200">
          <Megaphone size={30} className="mx-auto text-stone-200 mb-3" />
          <p className="text-stone-400 text-sm">{t('aufruf.leer')}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {aufrufe.map(a => {
            const st = staende[a.id];
            const ziel = Number(a.ziel_betrag || 0);
            const teil = ziel > 0 ? Math.min(100, Math.round((Number(st?.gesammelt || 0) / ziel) * 100)) : null;
            return (
              <div key={a.id} className="bg-white p-5 rounded-2xl border border-stone-100 shadow-sm">
                <div className="flex items-start justify-between gap-4 flex-wrap">
                  <div className="flex-1 min-w-[220px]">
                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                      <p className="font-bold text-stone-900 text-sm">{a.titel}</p>
                      <span className={`text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded ${
                        a.status === 'OEFFENTLICH' ? 'bg-emerald-50 text-emerald-600'
                        : a.status === 'BEENDET' ? 'bg-stone-800 text-stone-200'
                        : 'bg-stone-100 text-stone-500'}`}>
                        {a.status === 'OEFFENTLICH' ? t('aufruf.oeffentlich')
                          : a.status === 'BEENDET' ? t('aufruf.beendet') : t('aufruf.entwurf')}
                      </span>
                      {a.endet_am && (
                        <span className="text-[10px] text-stone-400">
                          {t('aufruf.bis')} {new Date(a.endet_am).toLocaleDateString('de-CH')}
                        </span>
                      )}
                    </div>
                    {a.text && <p className="text-xs text-stone-500 leading-relaxed mb-2 line-clamp-2">{a.text}</p>}

                    <div className="flex items-center gap-3 flex-wrap">
                      <p className="text-sm font-bold text-stone-900 tabular-nums">
                        {geld(st?.gesammelt ?? 0, a.waehrung)}
                        {ziel > 0 && <span className="text-stone-300 font-normal"> / {geld(ziel, a.waehrung)}</span>}
                      </p>
                      {st && st.anzahl > 0 && (
                        <span className="text-[11px] text-stone-400">{t('aufruf.spenden_anzahl', { anzahl: st.anzahl })}</span>
                      )}
                      {st && Number(st.offen) > 0 && (
                        <span className="text-[11px] text-amber-600">{t('aufruf.noch_offen', { betrag: geld(st.offen, a.waehrung) })}</span>
                      )}
                    </div>

                    {teil !== null && (
                      <div className="mt-2 h-1.5 bg-stone-100 rounded-full overflow-hidden max-w-md">
                        <div className="h-full bg-primary rounded-full transition-all" style={{ width: `${teil}%` }} />
                      </div>
                    )}
                  </div>

                  <div className="flex gap-1.5 shrink-0">
                    <button onClick={() => bearbeiten(a)} title={t('aufruf.bearbeiten')}
                      className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 transition-colors">
                      <Pencil size={15} />
                    </button>
                    {a.status !== 'OEFFENTLICH' ? (
                      <button onClick={() => status(a, 'OEFFENTLICH')} disabled={arbeitet === a.id}
                        title={t('aufruf.veroeffentlichen')}
                        className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 disabled:opacity-40">
                        {arbeitet === a.id ? <Loader2 size={15} className="animate-spin" /> : <Eye size={15} />}
                      </button>
                    ) : (
                      <>
                        <button onClick={() => status(a, 'ENTWURF')} disabled={arbeitet === a.id}
                          title={t('aufruf.verbergen')}
                          className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 disabled:opacity-40">
                          {arbeitet === a.id ? <Loader2 size={15} className="animate-spin" /> : <EyeOff size={15} />}
                        </button>
                        <button onClick={() => status(a, 'BEENDET')} disabled={arbeitet === a.id}
                          title={t('aufruf.abschliessen')}
                          className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 disabled:opacity-40">
                          <CheckCheck size={15} />
                        </button>
                      </>
                    )}
                    <button onClick={() => entfernen(a)}
                      className="p-2.5 rounded-xl border border-stone-200 text-stone-400 hover:border-rose-200 hover:text-rose-500 transition-colors">
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default AdminSpendenaufrufe;
