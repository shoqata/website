import React, { useEffect, useRef, useState } from 'react';
import {
  Plus, Loader2, Save, Check, AlertTriangle, Trash2, Star, Home, Users, Upload, X, EyeOff, History,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';
import { useTranslation } from '../context/LanguageContext';
import { chronikLaden, chronikDatum, type ChronikEintrag } from '../lib/useChronik';
import { bildHochladen } from '../lib/bildHochladen';

// Die Chronik pflegen: Eintraege anlegen, aendern, loeschen.
//
// Jeder Eintrag wird fuer sich gespeichert (chronik_speichern), nicht mit
// dem grossen Knopf "Veroeffentlichen" unten -- der gilt dem Branding.
// Ein Eintrag ist eine Zeile in der Datenbank, kein Feld im Branding: so
// kann die Chronik wachsen, ohne dass jede Aenderung das ganze Branding
// neu schreibt.

type Entwurf = Omit<ChronikEintrag, 'id' | 'geaendert_am' | 'geaendert_von'> & { id: string | null };

const LEER = (): Entwurf => ({
  id: null, jahr: new Date().getFullYear(), monat: null, tag: null,
  titel: {}, text: {}, bild: null, bereich: 'VEREIN', meilenstein: false, status: 'OEFFENTLICH',
});

const MONATE = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli',
                'August', 'September', 'Oktober', 'November', 'Dezember'];

const AdminChronik: React.FC<{ sprache: 'de' | 'sq' | 'en'; onGespeichert?: () => void }> = ({ sprache, onGespeichert }) => {
  const { showConfirm } = useFeedback();
  const { language, loc } = useTranslation();
  const [eintraege, setEintraege] = useState<ChronikEintrag[] | null>(null);
  const [offen, setOffen] = useState<Entwurf | null>(null);
  const [arbeitet, setArbeitet] = useState(false);
  const [laedtBild, setLaedtBild] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [fehler, setFehler] = useState('');
  const bildEingabe = useRef<HTMLInputElement>(null);

  const laden = async () => {
    try { setEintraege(await chronikLaden(false)); }
    catch (e: any) { setFehler(e?.message || 'Konnte nicht geladen werden.'); setEintraege([]); }
  };
  useEffect(() => { laden(); }, []);

  const sichern = async () => {
    if (!offen) return;
    setArbeitet(true); setFehler('');
    const { data, error } = await supabase.rpc('chronik_speichern', {
      p_id: offen.id, p_jahr: offen.jahr, p_monat: offen.monat, p_tag: offen.monat ? offen.tag : null,
      p_titel: offen.titel, p_text: offen.text, p_bild: offen.bild,
      p_bereich: offen.bereich, p_meilenstein: offen.meilenstein, p_status: offen.status,
    });
    setArbeitet(false);
    if (error) { setFehler(error.message); return; }
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
    setOffen(o => o ? { ...o, id: (data as string) ?? o.id } : o);
    await laden();
    onGespeichert?.();
  };

  const loeschen = async () => {
    if (!offen?.id) { setOffen(null); return; }
    const ja = await showConfirm({
      title: 'Eintrag löschen?', type: 'danger', confirmText: 'Löschen',
      message: `„${loc(offen.titel) || offen.jahr}" wird aus der Chronik entfernt. Das lässt sich nicht rückgängig machen.`,
    });
    if (!ja) return;
    const { error } = await supabase.rpc('chronik_loeschen', { p_id: offen.id });
    if (error) { setFehler(error.message); return; }
    setOffen(null); await laden(); onGespeichert?.();
  };

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none focus:border-stone-300';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  if (eintraege === null) return (
    <div className="p-6 flex items-center gap-2 text-stone-400 text-sm"><Loader2 size={16} className="animate-spin" /> Lädt …</div>
  );

  // ------------------------------------------------------------ Editor
  if (offen) {
    const tage = offen.monat ? new Date(offen.jahr, offen.monat, 0).getDate() : 31;
    return (
      <div className="space-y-5">
        <button onClick={() => { setOffen(null); setFehler(''); }}
          className="text-[10px] font-bold uppercase tracking-widest text-stone-400 hover:text-stone-900">
          ← Alle Einträge
        </button>
        {fehler && (
          <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
            <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
          </p>
        )}

        <div className="bg-stone-50 rounded-3xl border border-stone-100 p-5 space-y-4">
          <div>
            <p className={`${marke} mb-2`}>Wann</p>
            <div className="grid grid-cols-3 gap-2">
              <input type="number" className={feld} value={offen.jahr} min={1000} max={2200}
                onChange={e => setOffen({ ...offen, jahr: Number(e.target.value) || offen.jahr })} />
              <select className={feld} value={offen.monat ?? ''}
                onChange={e => setOffen({ ...offen, monat: e.target.value ? Number(e.target.value) : null, tag: e.target.value ? offen.tag : null })}>
                <option value="">Monat unbekannt</option>
                {MONATE.map((m, i) => <option key={m} value={i + 1}>{m}</option>)}
              </select>
              <select className={feld} value={offen.tag ?? ''} disabled={!offen.monat}
                onChange={e => setOffen({ ...offen, tag: e.target.value ? Number(e.target.value) : null })}>
                <option value="">Tag unbekannt</option>
                {Array.from({ length: tage }, (_, i) => <option key={i} value={i + 1}>{i + 1}.</option>)}
              </select>
            </div>
            <p className="text-[10px] text-stone-400 mt-2">
              So genau wie bekannt — aus der Gründungszeit reicht oft das Jahr.
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
            {([['VEREIN', 'Verein', <Users size={13} />], ['DORF', 'Dorf', <Home size={13} />]] as const).map(([w, n, i]) => (
              <button key={w} type="button" onClick={() => setOffen({ ...offen, bereich: w })}
                className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 border ${
                  offen.bereich === w ? 'bg-stone-900 text-white border-stone-900' : 'bg-white text-stone-500 border-stone-200'}`}>
                {i} {n}
              </button>
            ))}
            <button type="button" onClick={() => setOffen({ ...offen, meilenstein: !offen.meilenstein })}
              className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 border ${
                offen.meilenstein ? 'bg-primary text-white border-primary' : 'bg-white text-stone-500 border-stone-200'}`}>
              <Star size={13} fill={offen.meilenstein ? 'currentColor' : 'none'} /> Meilenstein
            </button>
            <button type="button" onClick={() => setOffen({ ...offen, status: offen.status === 'ENTWURF' ? 'OEFFENTLICH' : 'ENTWURF' })}
              className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 border ${
                offen.status === 'ENTWURF' ? 'bg-amber-50 text-amber-800 border-amber-200' : 'bg-white text-stone-500 border-stone-200'}`}>
              <EyeOff size={13} /> {offen.status === 'ENTWURF' ? 'Entwurf (unsichtbar)' : 'Als Entwurf'}
            </button>
          </div>
          <p className="text-[10px] text-stone-400 -mt-2">
            Meilensteine erscheinen zusätzlich auf „Über uns“ und sind in der Chronik hervorgehoben.
          </p>
        </div>

        <div className="bg-stone-50 rounded-3xl border border-stone-100 p-5 space-y-3">
          <p className={marke}>Inhalt ({sprache})</p>
          <input className={`${feld} font-bold`} value={offen.titel[sprache] ?? ''}
            onChange={e => setOffen({ ...offen, titel: { ...offen.titel, [sprache]: e.target.value } })}
            placeholder="Neue Wasserleitung im Dorf" />
          <textarea className={`${feld} leading-relaxed`} rows={5} value={offen.text[sprache] ?? ''}
            onChange={e => setOffen({ ...offen, text: { ...offen.text, [sprache]: e.target.value } })}
            placeholder="Was ist passiert, wer war beteiligt, was hat es bewirkt?" />
          <p className="text-[10px] text-stone-400">
            Die Sprache wählen Sie oben. Fehlt eine Übersetzung, erscheint die vorhandene.
          </p>
        </div>

        <div className="bg-stone-50 rounded-3xl border border-stone-100 p-5 space-y-3">
          <p className={marke}>Bild (freiwillig)</p>
          {offen.bild ? (
            <div className="relative">
              <img src={offen.bild} alt="" className="w-full aspect-[16/9] object-cover rounded-2xl border border-stone-100" />
              <button type="button" onClick={() => setOffen({ ...offen, bild: null })}
                className="absolute top-2 right-2 w-8 h-8 bg-white/90 rounded-full flex items-center justify-center text-stone-600 hover:text-red-600">
                <X size={15} />
              </button>
            </div>
          ) : (
            <div className="flex gap-2">
              <input className={feld} placeholder="https://…"
                onBlur={e => e.target.value.trim() && setOffen({ ...offen, bild: e.target.value.trim() })} />
              <button type="button" onClick={() => bildEingabe.current?.click()} disabled={laedtBild}
                className="shrink-0 px-4 bg-white border border-stone-200 rounded-xl text-xs font-bold text-stone-600 flex items-center gap-1.5">
                {laedtBild ? <Loader2 size={13} className="animate-spin" /> : <Upload size={13} />} Hochladen
              </button>
            </div>
          )}
          <input ref={bildEingabe} type="file" accept="image/*" hidden onChange={async e => {
            const d = e.target.files?.[0]; e.target.value = '';
            if (!d) return;
            setLaedtBild(true); setFehler('');
            try { const url = await bildHochladen(d, 'chronik'); setOffen(o => o ? { ...o, bild: url } : o); }
            catch (err: any) { setFehler(err?.message || 'Hochladen fehlgeschlagen.'); }
            finally { setLaedtBild(false); }
          }} />
        </div>

        <div className="flex items-center gap-3 flex-wrap">
          <button onClick={sichern} disabled={arbeitet || laedtBild}
            className="flex items-center gap-2 bg-stone-900 text-white px-5 py-3 rounded-xl text-[11px] font-bold uppercase tracking-widest disabled:opacity-40">
            {arbeitet ? <Loader2 size={13} className="animate-spin" /> : gespeichert ? <Check size={13} /> : <Save size={13} />}
            {gespeichert ? 'Gespeichert' : 'Eintrag speichern'}
          </button>
          {offen.id && (
            <button onClick={loeschen}
              className="text-[11px] font-bold uppercase tracking-widest text-stone-400 hover:text-red-600 flex items-center gap-1.5">
              <Trash2 size={13} /> Löschen
            </button>
          )}
        </div>
      </div>
    );
  }

  // ------------------------------------------------------------- Liste
  const neuesteZuerst = [...eintraege].reverse();
  return (
    <div className="space-y-5">
      {fehler && <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">{fehler}</p>}
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <p className="text-[11px] text-stone-500 leading-relaxed max-w-md">
          Die Entwicklung von Verein und Dorf als Zeitleiste — von der Gründung bis heute.
          Jeder Eintrag wird einzeln gespeichert und erscheint sofort auf der Seite Chronik.
        </p>
        <button onClick={() => { setOffen(LEER()); setFehler(''); }}
          className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2.5 rounded-xl text-[10px] font-bold uppercase tracking-widest shrink-0">
          <Plus size={13} /> Neuer Eintrag
        </button>
      </div>

      {eintraege.length === 0 ? (
        <div className="bg-stone-50 rounded-3xl border border-dashed border-stone-200 p-10 text-center">
          <History size={32} className="mx-auto text-stone-200 mb-3" />
          <p className="text-sm text-stone-500">Noch keine Einträge.</p>
          <p className="text-[11px] text-stone-400 mt-1">
            Solange die Chronik leer ist, erscheint sie weder im Menü noch auf „Über uns“.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-stone-100 divide-y divide-stone-50">
          {neuesteZuerst.map(e => (
            <button key={e.id} onClick={() => { setOffen({ ...e }); setFehler(''); }}
              className="w-full text-left px-5 py-3.5 hover:bg-stone-50 flex items-center gap-4">
              <span className="w-12 shrink-0 font-display font-bold text-stone-900 tabular-nums">{e.jahr}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-stone-800 truncate flex items-center gap-1.5">
                  {e.meilenstein && <Star size={12} className="text-primary shrink-0" fill="currentColor" />}
                  {e.titel?.[sprache] || loc(e.titel) || '(ohne Titel)'}
                </p>
                <p className="text-[11px] text-stone-400 mt-0.5">
                  {chronikDatum(e, language)} · {e.bereich === 'DORF' ? 'Dorf' : 'Verein'}
                  {!e.titel?.[sprache] && <span className="text-amber-600"> · ohne {sprache.toUpperCase()}</span>}
                </p>
              </div>
              {e.status === 'ENTWURF' && (
                <span className="text-[9px] font-bold uppercase tracking-widest text-stone-400 bg-stone-50 border border-stone-200 rounded px-1.5 py-0.5 shrink-0">
                  Entwurf
                </span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminChronik;
