import React, { useEffect, useMemo, useState } from 'react';
import {
  Loader2, AlertTriangle, Check, Mail, TrendingUp, Clock, RefreshCw, Lock,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../../context/LanguageContext';

// Brieftarife: was unityhub einkauft, was der Verein zahlt.
//
// Der Verkaufspreis wird hier nicht eingetippt. Er steht in der
// Datenbank als gerechnete Spalte -- Einkauf plus Aufpreis -- und kann
// darum nicht von seiner Regel abweichen. Eingestellt werden zwei Dinge:
//
//   der Aufpreis in Prozent   die Regel; Vorgabe 10
//   ein Festpreis             die Ausnahme; schlaegt die Regel
//
// Der Einkaufspreis kommt von Pingen selbst, ueber den Preisrechner. Wo
// er fehlt, ist noch keine Abfrage gelaufen; dann braucht es einen
// Festpreis, sonst kann der Verein nichts kaufen.
//
// Die Marge daneben ist nicht geschaetzt: sie steht so im
// Kontingentbuch, Erloes minus Einkauf, Brief fuer Brief.

type Tarif = {
  r_verein: string; r_name: string;
  r_einkauf: number | null; r_aufpreis: number | null; r_fest: number | null;
  r_verkauf: number | null; r_waehrung: string;
  r_abgefragt: string | null; r_grundlage: string | null; r_modul: string;
};

type Marge = {
  r_verein: string; r_name: string; r_gekauft: number; r_verbraucht: number;
  r_stand: number; r_erloes: number; r_einkauf: number; r_marge: number;
  r_preis: number | null;
};

const MODUL_FARBE: Record<string, string> = {
  AN:        'bg-emerald-500/15 text-emerald-400',
  TESTPHASE: 'bg-sky-500/15 text-sky-400',
  AUS:       'bg-stone-700 text-stone-400',
};

const fr = (n: number | null | undefined, w = 'CHF') =>
  n === null || n === undefined ? '—' : `${w} ${Number(n).toFixed(2)}`;

// numeric kommt je nach Einstellung als Zahl ODER als Zeichenkette
// zurueck. Ein Vergleich mit !== waere dann immer wahr, der Knopf immer
// aktiv und die Vorschau immer gelb -- "geaendert" ohne Aenderung.
// Darum beide Seiten durch dieselbe Form.
const zahl = (v: any): number | null => {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};

const Brieftarife: React.FC = () => {
  const { t } = useTranslation();
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  const [tarife, setTarife] = useState<Tarif[]>([]);
  const [margen, setMargen] = useState<Marge[]>([]);
  // Was gerade im Formular steht, je Verein. Getrennt von den Daten,
  // damit ein halb getippter Wert nicht als Preis gilt.
  const [eingabe, setEingabe] = useState<Record<string, { aufpreis: string; fest: string }>>({});
  const [speichert, setSpeichert] = useState('');
  const [gesichert, setGesichert] = useState('');

  const modulName = (m: string) => {
    const n = t(`tarif.modul.${m}`);
    return n === `tarif.modul.${m}` ? m : n;
  };

  const laden = async () => {
    setLaedt(true); setFehler('');
    const [ta, m] = await Promise.all([
      supabase.rpc('post_tarife'),
      supabase.rpc('post_marge'),
    ]);
    const err = [ta, m].find(x => (x as any).error);
    if (err) setFehler((err as any).error.message);
    const reihen = (ta.data as Tarif[]) ?? [];
    setTarife(reihen);
    setMargen((m.data as Marge[]) ?? []);
    setEingabe(Object.fromEntries(reihen.map(r => [r.r_verein, {
      aufpreis: r.r_aufpreis === null ? '10' : String(r.r_aufpreis),
      fest: r.r_fest === null ? '' : String(r.r_fest),
    }])));
    setLaedt(false);
  };

  useEffect(() => { laden(); }, []);

  const margeJeVerein = useMemo(
    () => Object.fromEntries(margen.map(m => [m.r_verein, m])), [margen]);

  const summe = useMemo(() => margen.reduce((a, m) => ({
    erloes: a.erloes + Number(m.r_erloes || 0),
    einkauf: a.einkauf + Number(m.r_einkauf || 0),
    marge: a.marge + Number(m.r_marge || 0),
    briefe: a.briefe + Number(m.r_verbraucht || 0),
  }), { erloes: 0, einkauf: 0, marge: 0, briefe: 0 }), [margen]);

  const wartend = tarife.filter(x => x.r_verkauf === null && x.r_modul !== 'AUS');

  const setzen = async (verein: string) => {
    const e = eingabe[verein];
    if (!e) return;
    setSpeichert(verein); setFehler(''); setGesichert('');
    // Beide Werte gehen immer mit. p_fest = NULL loescht einen
    // Festpreis -- genau dafuer ist es da; wer nur den Aufpreis
    // schickte, liesse einen alten Festpreis fuer immer stehen.
    const { error } = await supabase.rpc('post_preis_setzen', {
      p_verein: verein,
      p_aufpreis: zahl(e.aufpreis),
      p_fest: zahl(e.fest),
    });
    setSpeichert('');
    if (error) { setFehler(error.message); return; }
    setGesichert(verein);
    laden();
  };

  if (laedt) return (
    <div className="flex items-center justify-center py-20 text-stone-500">
      <Loader2 className="animate-spin" size={22} />
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start gap-4 flex-wrap">
        <div>
          <h2 className="text-2xl font-bold">{t('tarif.titel')}</h2>
          <p className="text-stone-400 text-sm mt-1">{t('tarif.untertitel')}</p>
        </div>
        <button onClick={laden}
          className="px-4 py-2 bg-white/5 text-stone-300 rounded-xl text-xs font-bold hover:bg-white/10 flex items-center gap-2">
          <RefreshCw size={14} /> {t('post.neu_laden')}
        </button>
      </div>

      {fehler && (
        <div className="p-4 bg-rose-500/15 border border-rose-500/30 rounded-xl text-sm text-rose-200 flex gap-3">
          <AlertTriangle size={18} className="shrink-0 mt-0.5" />
          <span>{fehler}</span>
        </div>
      )}

      {/* Wer wartet. Das steht oben, weil es der Verein nicht selbst
          loesen kann: ohne Preis ist bei ihm der Kaufknopf fort, und
          dort steht "der Betreiber legt ihn fest". */}
      {wartend.length > 0 && (
        <div className="p-5 bg-amber-500/15 border border-amber-500/30 rounded-2xl">
          <div className="flex items-start gap-3">
            <Clock size={18} className="text-amber-400 shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-amber-200">
                {wartend.length === 1 ? t('tarif.wartet_einer')
                                      : t('tarif.wartet_mehrere', { anzahl: wartend.length })}
              </p>
              <p className="text-xs text-amber-200/70 mt-1 leading-relaxed">
                {t('tarif.wartet_text', { namen: wartend.map(w => w.r_name).join(', ') })}
              </p>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {[
          { titel: t('tarif.briefe_verbraucht'), wert: String(summe.briefe), hinweis: t('tarif.ueber_alle') },
          { titel: t('tarif.erloes'), wert: fr(summe.erloes), hinweis: t('tarif.erloes_hinweis') },
          { titel: t('tarif.einkauf'), wert: fr(summe.einkauf), hinweis: t('tarif.einkauf_hinweis') },
          { titel: t('tarif.marge'), wert: fr(summe.marge), hinweis: t('tarif.marge_hinweis') },
        ].map(k => (
          <div key={k.titel} className="p-5 bg-white/5 border border-white/10 rounded-2xl">
            <p className="text-[10px] font-bold text-stone-500 uppercase tracking-widest mb-2">{k.titel}</p>
            <p className="text-2xl font-bold text-white font-mono"
               style={{ fontVariantNumeric: 'tabular-nums' }}>{k.wert}</p>
            <p className="text-[11px] text-stone-500 mt-1">{k.hinweis}</p>
          </div>
        ))}
      </div>

      <div className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-white/5 text-[10px] font-bold text-stone-500 uppercase tracking-widest">
              <tr>
                <th className="text-left px-6 py-3">{t('tarif.sp.verein')}</th>
                <th className="text-right px-4 py-3">{t('tarif.einkauf')}</th>
                <th className="text-right px-4 py-3">{t('tarif.sp.aufpreis')}</th>
                <th className="text-right px-4 py-3">{t('tarif.sp.festpreis')}</th>
                <th className="text-right px-4 py-3">{t('tarif.sp.verkauf')}</th>
                <th className="text-right px-4 py-3">{t('tarif.sp.marge')}</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {tarife.length === 0 && (
                <tr><td colSpan={7} className="px-6 py-8 text-center text-stone-500 text-sm">
                  {t('tarif.keiner')}
                </td></tr>
              )}
              {tarife.map(x => {
                const e = eingabe[x.r_verein] ?? { aufpreis: '', fest: '' };
                const m = margeJeVerein[x.r_verein];
                const fest = zahl(e.fest);
                const auf = zahl(e.aufpreis);
                const ein = zahl(x.r_einkauf);
                // Dieselbe Rechnung wie die gerechnete Spalte in der
                // Datenbank: round(einkauf * (1 + aufpreis/100), 2).
                const vorschau = fest !== null ? fest
                  : ein !== null && auf !== null
                    ? Math.round(ein * (1 + auf / 100) * 100) / 100
                    : null;
                const geaendert = auf !== zahl(x.r_aufpreis) || fest !== zahl(x.r_fest);
                return (
                  <tr key={x.r_verein} className="hover:bg-white/5">
                    <td className="px-6 py-3">
                      <p className="font-bold text-white">{x.r_name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${MODUL_FARBE[x.r_modul] ?? MODUL_FARBE.AUS}`}>
                          {modulName(x.r_modul)}
                        </span>
                        {x.r_abgefragt && (
                          <span className="text-[10px] text-stone-500">
                            {t('tarif.tarif_vom', { datum: new Date(x.r_abgefragt).toLocaleDateString('de-CH') })}
                            {x.r_grundlage ? ` · ${x.r_grundlage}` : ''}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-stone-300"
                        style={{ fontVariantNumeric: 'tabular-nums' }}>
                      {ein === null
                        ? <span className="text-stone-600">{t('tarif.nicht_abgefragt')}</span>
                        : fr(ein, x.r_waehrung)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <input type="number" step="0.5" min="0" max="200" value={e.aufpreis}
                        onChange={ev => setEingabe({ ...eingabe, [x.r_verein]: { ...e, aufpreis: ev.target.value } })}
                        className="w-20 p-2 bg-white/5 border border-white/10 rounded-lg outline-none text-sm font-mono text-right text-white focus:border-white/30"/>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <input type="number" step="0.05" min="0" value={e.fest} placeholder="—"
                        onChange={ev => setEingabe({ ...eingabe, [x.r_verein]: { ...e, fest: ev.target.value } })}
                        className="w-24 p-2 bg-white/5 border border-white/10 rounded-lg outline-none text-sm font-mono text-right text-white placeholder:text-stone-600 focus:border-white/30"/>
                    </td>
                    <td className="px-4 py-3 text-right font-mono font-bold"
                        style={{ fontVariantNumeric: 'tabular-nums' }}>
                      <span className={geaendert ? 'text-amber-300' : 'text-white'}>
                        {vorschau === null ? '—' : fr(vorschau, x.r_waehrung)}
                      </span>
                      {fest !== null && (
                        <span className="block text-[10px] text-stone-500 font-sans font-normal mt-0.5">
                          {t('tarif.festpreis_gilt')}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-stone-300"
                        style={{ fontVariantNumeric: 'tabular-nums' }}>
                      {m ? fr(m.r_marge, x.r_waehrung) : '—'}
                      {m && m.r_verbraucht > 0 && (
                        <span className="block text-[10px] text-stone-500 font-sans font-normal mt-0.5">
                          {t('tarif.briefe_stand', { verbraucht: m.r_verbraucht, stand: m.r_stand })}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button onClick={() => setzen(x.r_verein)} disabled={speichert === x.r_verein || !geaendert}
                        className="px-4 py-2 bg-rose-600 text-white rounded-lg text-xs font-bold hover:bg-rose-700 disabled:opacity-30 disabled:hover:bg-rose-600 inline-flex items-center gap-1.5">
                        {speichert === x.r_verein ? <Loader2 size={13} className="animate-spin" />
                          : gesichert === x.r_verein && !geaendert ? <Check size={13} /> : null}
                        {gesichert === x.r_verein && !geaendert ? t('tarif.gesetzt') : t('tarif.setzen')}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      <div className="p-5 bg-white/5 border border-white/10 rounded-2xl text-xs text-stone-400 leading-relaxed space-y-2">
        {[
          { symbol: <TrendingUp size={14} className="shrink-0 mt-0.5 text-stone-500" />, text: t('tarif.hinweis_vorgabe') },
          { symbol: <Mail size={14} className="shrink-0 mt-0.5 text-stone-500" />, text: t('tarif.hinweis_festpreis') },
          { symbol: <Lock size={14} className="shrink-0 mt-0.5 text-stone-500" />, text: t('tarif.hinweis_betreiber') },
        ].map((h, i) => (
          <p key={i} className="flex items-start gap-2">{h.symbol}<span>{h.text}</span></p>
        ))}
      </div>
    </div>
  );
};

export default Brieftarife;
