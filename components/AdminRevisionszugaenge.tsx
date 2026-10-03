import React, { useEffect, useState } from 'react';
import { Loader2, ShieldCheck, Copy, Check, Ban, Plus, Clock } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Zugänge für die Revisionsstelle: ausstellen, sehen, widerrufen.
//
// Das Token wird GENAU EINMAL angezeigt -- beim Ausstellen. In der
// Datenbank liegt nur sein Hash; es ist danach nicht mehr herstellbar,
// nur noch ersetzbar. Das ist Absicht: läge es dort im Klartext, wäre ein
// Leseblick in die Datenbank gleichbedeutend mit offenem Zugriff auf die
// Finanzen aller Vereine.
//
// Deshalb die auffällige Stelle nach dem Erstellen -- wer den Verweis
// jetzt nicht kopiert, muss einen neuen ausstellen.

type Zugang = {
  id: string; bezeichnung: string; jahr: number | null;
  gueltig_bis: string; erstellt_am: string; erstellt_von: string | null;
  widerrufen_am: string | null; zuletzt_gesehen: string | null; zugriffe: number;
};

const datum = (s?: string | null) =>
  s ? new Date(s).toLocaleDateString('de-CH') : '';

const AdminRevisionszugaenge: React.FC = () => {
  const { t } = useTranslation();
  const jetzt = new Date().getFullYear();
  const [liste, setListe] = useState<Zugang[] | null>(null);
  const [offen, setOffen] = useState(false);
  const [name, setName] = useState('');
  // Vorgabe und Obergrenze: ein Monat. Dieselbe Grenze prueft die
  // Datenbank noch einmal -- die Oberflaeche kann man umgehen, die
  // Funktion nicht.
  const inEinemMonat = (() => {
    const d = new Date(); d.setMonth(d.getMonth() + 1);
    return d.toISOString().slice(0, 10);
  })();
  const morgen = (() => {
    const d = new Date(); d.setDate(d.getDate() + 1);
    return d.toISOString().slice(0, 10);
  })();
  const [bis, setBis] = useState(inEinemMonat);
  const [jahr, setJahr] = useState<number | ''>(jetzt);
  const [arbeitet, setArbeitet] = useState(false);
  const [frisch, setFrisch] = useState<{ token: string } | null>(null);
  const [kopiert, setKopiert] = useState(false);
  const [fehler, setFehler] = useState('');

  const laden = async () => {
    const { data, error } = await supabase
      .from('revisionszugaenge').select('*').order('erstellt_am', { ascending: false });
    setListe(error ? [] : (data as Zugang[]) || []);
  };
  useEffect(() => { laden(); }, []);

  const verweis = (token: string) => `${window.location.origin}/#/revision/${token}`;

  const erstellen = async () => {
    setArbeitet(true); setFehler('');
    try {
      const { data, error } = await supabase.rpc('revisionszugang_erstellen', {
        p_bezeichnung: name, p_gueltig_bis: bis, p_jahr: jahr === '' ? null : jahr,
      });
      if (error) throw error;
      setFrisch({ token: (data as any).token });
      setName(''); setOffen(false);
      await laden();
    } catch (e: any) {
      setFehler(e?.message || 'Konnte nicht ausgestellt werden.');
    } finally { setArbeitet(false); }
  };

  const widerrufen = async (z: Zugang) => {
    setArbeitet(true); setFehler('');
    try {
      const { error } = await supabase.rpc('revisionszugang_widerrufen', { p_id: z.id });
      if (error) throw error;
      await laden();
    } catch (e: any) {
      setFehler(e?.message || 'Konnte nicht widerrufen werden.');
    } finally { setArbeitet(false); }
  };

  const stand = (z: Zugang) =>
    z.widerrufen_am ? { wort: t('revz.widerrufen'), farbe: 'text-stone-400' }
    : new Date(z.gueltig_bis) < new Date() ? { wort: t('revz.abgelaufen'), farbe: 'text-amber-600' }
    : { wort: t('revz.gueltig'), farbe: 'text-emerald-600' };

  return (
    <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-7 space-y-5">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-3">
          <ShieldCheck size={18} className="text-stone-400" />
          <div>
            <h3 className="font-bold text-stone-900">{t('revz.titel')}</h3>
            <p className="text-[11px] text-stone-400 max-w-md leading-relaxed">{t('revz.untertitel')}</p>
          </div>
        </div>
        <button onClick={() => setOffen(o => !o)}
          className="flex items-center gap-2 px-4 py-2 rounded-xl text-[11px] font-bold uppercase
                     tracking-widest border border-stone-200 text-stone-600 hover:border-stone-400">
          <Plus size={13} /> {t('revz.ausstellen')}
        </button>
      </div>

      {fehler && <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">{fehler}</p>}

      {/* Das Token, genau einmal */}
      {frisch && (
        <div className="bg-stone-900 text-white rounded-2xl p-5">
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">
            {t('revz.einmalig')}
          </p>
          <p className="font-mono text-[11px] break-all bg-black/40 rounded-lg p-3 mb-3">
            {verweis(frisch.token)}
          </p>
          <div className="flex items-center gap-3 flex-wrap">
            <button onClick={() => {
                navigator.clipboard?.writeText(verweis(frisch.token));
                setKopiert(true); setTimeout(() => setKopiert(false), 2500);
              }}
              className="flex items-center gap-2 bg-white text-stone-900 px-4 py-2 rounded-lg
                         text-[11px] font-bold uppercase tracking-widest">
              {kopiert ? <Check size={13} /> : <Copy size={13} />}
              {kopiert ? t('revz.kopiert') : t('revz.kopieren')}
            </button>
            <button onClick={() => setFrisch(null)}
              className="text-[11px] font-bold uppercase tracking-widest text-stone-400 hover:text-white">
              {t('revz.schliessen')}
            </button>
          </div>
          <p className="text-[11px] text-stone-400 mt-3 leading-relaxed">{t('revz.einmalig_hinweis')}</p>
        </div>
      )}

      {offen && (
        <div className="bg-stone-50 border border-stone-200 rounded-2xl p-5 grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
          <label className="md:col-span-2 block">
            <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-1">{t('revz.fuer_wen')}</span>
            <input value={name} onChange={e => setName(e.target.value)}
              placeholder={t('revz.fuer_wen_beispiel')}
              className="w-full p-2.5 bg-white border border-stone-200 rounded-xl text-sm outline-none" />
          </label>
          <label className="block">
            <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-1">{t('revz.gueltig_bis')}</span>
            <input type="date" value={bis} min={morgen} max={inEinemMonat}
              onChange={e => setBis(e.target.value)}
              className="w-full p-2.5 bg-white border border-stone-200 rounded-xl text-sm outline-none" />
            <span className="text-[10px] text-stone-400 block mt-1">{t('revz.hoechstens')}</span>
          </label>
          <label className="block">
            <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-1">{t('revz.jahr')}</span>
            <select value={jahr} onChange={e => setJahr(e.target.value === '' ? '' : Number(e.target.value))}
              className="w-full p-2.5 bg-white border border-stone-200 rounded-xl text-sm outline-none">
              <option value="">{t('revz.alle_jahre')}</option>
              {Array.from({ length: 6 }, (_, i) => jetzt - i).map(j => <option key={j} value={j}>{j}</option>)}
            </select>
          </label>
          <div className="md:col-span-4 flex justify-end">
            <button onClick={erstellen} disabled={arbeitet || !name.trim()}
              className="knopf-primaer text-white px-5 py-2.5 rounded-xl text-[11px] font-bold
                         uppercase tracking-widest inline-flex items-center gap-2 disabled:opacity-40">
              {arbeitet ? <Loader2 size={13} className="animate-spin" /> : <ShieldCheck size={13} />}
              {t('revz.ausstellen')}
            </button>
          </div>
        </div>
      )}

      {liste === null ? (
        <div className="flex items-center gap-2 text-stone-400 text-sm py-6">
          <Loader2 className="animate-spin" size={15} /> …
        </div>
      ) : liste.length === 0 ? (
        <p className="text-[11px] text-stone-400 py-4">{t('revz.keine')}</p>
      ) : (
        <div className="divide-y divide-stone-100">
          {liste.map(z => {
            const s = stand(z);
            return (
              <div key={z.id} className="py-3 flex items-center justify-between gap-4 flex-wrap">
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-900 truncate">{z.bezeichnung}</p>
                  <p className="text-[11px] text-stone-400">
                    {z.jahr ? `${t('revz.jahr')} ${z.jahr}` : t('revz.alle_jahre')} ·
                    {' '}{t('revz.bis')} {datum(z.gueltig_bis)}
                    {z.zuletzt_gesehen
                      ? ` · ${t('revz.zuletzt')} ${datum(z.zuletzt_gesehen)} (${z.zugriffe}×)`
                      : ` · ${t('revz.nie_benutzt')}`}
                  </p>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <span className={`text-[10px] font-bold uppercase tracking-widest ${s.farbe}`}>
                    {s.wort}
                  </span>
                  {!z.widerrufen_am && (
                    <button onClick={() => widerrufen(z)} disabled={arbeitet}
                      className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest
                                 text-stone-400 hover:text-red-600 transition-colors disabled:opacity-40">
                      <Ban size={12} /> {t('revz.widerrufen_knopf')}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      <p className="text-[11px] text-stone-400 leading-relaxed flex items-start gap-2">
        <Clock size={13} className="shrink-0 mt-0.5" /> {t('revz.hinweis')}
      </p>
    </div>
  );
};

export default AdminRevisionszugaenge;
