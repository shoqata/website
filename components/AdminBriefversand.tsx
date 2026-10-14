import React, { useEffect, useMemo, useState } from 'react';
import {
  Loader2, Mail, AlertTriangle, CheckCircle2, Clock, Send, XCircle,
  PackageX, ShoppingCart, Receipt, Ban, RefreshCw,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { postArbeiterAnstossen, pingenZugangPruefen } from '../lib/postversand';

// Briefversand: Kontingent und Briefe.
//
// Das Modul ist im Marktplatz zu finden. Der Verein schaltet es frei und
// kauft ein Kontingent an Briefen; unityhub kauft bei Pingen ein und
// schlaegt pro Brief etwas auf. Darum sind hier drei Dinge
// auseinanderzuhalten, die leicht zu einem verschwimmen:
//
//   ist das Modul ueberhaupt frei      -> sonst geht nichts
//   hat der Betreiber einen Preis      -> sonst kann nichts gekauft werden
//   ist noch Kontingent da             -> sonst bleibt ein Lauf stehen
//
// Jeder dieser drei Faelle bekommt einen eigenen Satz. Ein einziger
// ausgegrauter Knopf mit Fragezeichen waere kuerzer und wertlos: wer
// nicht versenden kann, muss wissen, wen er fragt.

type Stand = {
  verein: string; modul_aktiv: boolean; stand: number;
  gekauft: number; verbraucht: number;
  preis_je_brief: number | null; waehrung: string; kaufbar: boolean;
};

type Brief = {
  r_id: string; r_rechnung: string | null; r_empfaenger: string | null;
  r_zustand: string; r_produkt: string | null; r_pingen_id: string | null;
  r_status: string | null; r_meldung: string | null; r_versuche: number;
  r_fehler: string | null; r_erstellt: string;
  r_uebergeben: string | null; r_erledigt: string | null;
};

type Buchung = {
  r_art: string; r_menge: number; r_preis: number | null;
  r_waehrung: string | null; r_grund: string | null;
  r_rechnung: string | null; r_am: string;
};

// Farbe und Symbol je Zustand. Die Namen stehen im Katalog unter
// post.zustand.<WERT> -- ein Zustand, den die Uebersetzung nicht kennt,
// zeigt den Rohwert statt zu verschwinden.
const ZUSTAND: Record<string, { farbe: string; symbol: React.ReactNode }> = {
  WARTEND:      { farbe: 'bg-stone-100 text-stone-600',    symbol: <Clock size={13} /> },
  UEBERGEBEN:   { farbe: 'bg-sky-50 text-sky-700',         symbol: <Send size={13} /> },
  VERSENDET:    { farbe: 'bg-indigo-50 text-indigo-700',   symbol: <Mail size={13} /> },
  ZUGESTELLT:   { farbe: 'bg-emerald-50 text-emerald-700', symbol: <CheckCircle2 size={13} /> },
  UNZUSTELLBAR: { farbe: 'bg-amber-50 text-amber-700',     symbol: <PackageX size={13} /> },
  PROBLEM:      { farbe: 'bg-red-50 text-red-700',         symbol: <AlertTriangle size={13} /> },
  ABGEBROCHEN:  { farbe: 'bg-stone-100 text-stone-400',    symbol: <Ban size={13} /> },
};

const AdminBriefversand: React.FC = () => {
  const { t } = useTranslation();
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  const [stand, setStand] = useState<Stand | null>(null);
  const [briefe, setBriefe] = useState<Brief[]>([]);
  const [buch, setBuch] = useState<Buchung[]>([]);
  const [menge, setMenge] = useState('50');
  const [kauft, setKauft] = useState(false);
  const [quittung, setQuittung] = useState('');
  const [arbeitet, setArbeitet] = useState(false);
  const [zugang, setZugang] = useState('');

  // Ein unbekannter Zustand soll als Rohwert dastehen und nicht als
  // leere Zelle: eine Luecke verschweigt, dass es den Zustand gibt.
  const zustandName = (z: string) => {
    const name = t(`post.zustand.${z}`);
    return name === `post.zustand.${z}` ? z : name;
  };
  const artName = (a: string) => {
    const name = t(`post.art.${a}`);
    return name === `post.art.${a}` ? a : name;
  };

  const datum = (s: string | null) =>
    s ? new Date(s).toLocaleString('de-CH', { dateStyle: 'short', timeStyle: 'short' }) : '—';

  const laden = async () => {
    setLaedt(true); setFehler('');
    const [s, b, k] = await Promise.all([
      supabase.rpc('post_kontingent_stand'),
      supabase.rpc('post_uebersicht', { p_grenze: 200 }),
      supabase.rpc('post_kontingent_buch', { p_grenze: 100 }),
    ]);
    const err = [s, b, k].find(x => (x as any).error);
    if (err) setFehler((err as any).error.message);
    setStand((s.data as Stand) ?? null);
    setBriefe((b.data as Brief[]) ?? []);
    setBuch((k.data as Buchung[]) ?? []);
    setLaedt(false);
  };

  useEffect(() => { laden(); }, []);

  const anzahl = Math.max(0, Math.floor(Number(menge) || 0));
  const summe = stand?.preis_je_brief ? anzahl * Number(stand.preis_je_brief) : null;

  const kaufen = async () => {
    // Kaufen heisst Geld ausgeben. Darum steht die Summe vorher da und
    // die Rechnungsnummer nachher -- nicht nur ein "erledigt".
    setKauft(true); setFehler(''); setQuittung('');
    const { data, error } = await supabase.rpc('post_kontingent_kaufen', { p_menge: anzahl });
    setKauft(false);
    if (error) { setFehler(error.message); return; }
    const d = data as any;
    setQuittung(t('post.gekauft_meldung', {
      gekauft: d.gekauft, nummer: d.rechnungsnummer, stand: d.stand,
      betrag: `${d.waehrung} ${Number(d.betrag).toFixed(2)}`,
    }));
    laden();
  };

  const abbrechen = async (id: string) => {
    const { data, error } = await supabase.rpc('post_abbrechen', { p_id: id });
    if (error) { setFehler(error.message); return; }
    // false heisst: der Brief war nicht mehr WARTEND. Das ist kein
    // Fehler, aber es muss dastehen -- sonst klickt man noch einmal.
    if (data === false) setFehler(t('post.abbrechen_zu_spaet'));
    laden();
  };

  // Die wartenden Briefe jetzt uebergeben, statt auf den naechsten Lauf
  // zu warten. Was zurueckkommt, steht da -- auch eine Null: "0
  // uebergeben, 3 offen" ist eine Antwort, ein stilles Nichts nicht.
  const uebergeben = async () => {
    setArbeitet(true); setFehler(''); setQuittung('');
    try {
      const d: any = await postArbeiterAnstossen(25);
      if (d?.error) setFehler(String(d.error));
      else setQuittung(
        t('post.uebergeben_meldung', { anzahl: d?.aufgegeben ?? 0 })
        + (d?.offen ? t('post.noch_offen', { anzahl: d.offen }) : '')
        + (d?.ohne_kontingent ? t('post.ohne_kontingent', { anzahl: d.ohne_kontingent }) : '')
        + (d?.umgebung === 'staging' ? t('post.staging') : '.'));
    } catch (e: any) {
      setFehler(e?.message || t('post.uebergabe_fehler'));
    }
    setArbeitet(false);
    laden();
  };

  // Nur nachsehen. Gibt nichts auf -- der Knopf muss gedrueckt werden
  // koennen, ohne dass Porto entsteht.
  const pruefen = async () => {
    setZugang(''); setFehler('');
    try {
      const d: any = await pingenZugangPruefen();
      setZugang(d?.ergebnis || JSON.stringify(d));
    } catch (e: any) {
      setZugang(e?.message || t('post.zugang_fehler'));
    }
  };

  const nachZustand = useMemo(() => {
    const z: Record<string, number> = {};
    briefe.forEach(b => { z[b.r_zustand] = (z[b.r_zustand] || 0) + 1; });
    return z;
  }, [briefe]);

  const offen = briefe.filter(b => b.r_zustand === 'WARTEND').length;

  if (laedt) return (
    <div className="flex items-center justify-center py-20 text-stone-400">
      <Loader2 className="animate-spin" size={22} />
    </div>
  );

  return (
    <div className="space-y-6">
      {fehler && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-sm text-red-800 flex gap-3">
          <AlertTriangle size={18} className="shrink-0 mt-0.5" />
          <span>{fehler}</span>
        </div>
      )}
      {zugang && (
        <div className="p-4 bg-stone-900 rounded-xl text-sm text-stone-200 flex gap-3">
          <Send size={18} className="shrink-0 mt-0.5 text-stone-500" />
          <span>{zugang}</span>
        </div>
      )}
      {quittung && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-sm text-emerald-900 flex gap-3">
          <Receipt size={18} className="shrink-0 mt-0.5" />
          <span>{quittung}</span>
        </div>
      )}

      {/* Modul nicht frei: dann hilft kein Kaufknopf, sondern der Weg
          zum Marktplatz. */}
      {stand && !stand.modul_aktiv && (
        <div className="p-6 bg-stone-900 rounded-2xl text-stone-300 space-y-2">
          <p className="font-display text-xl font-bold text-white">{t('post.nicht_frei_titel')}</p>
          <p className="text-sm leading-relaxed">{t('post.nicht_frei_text')}</p>
        </div>
      )}

      {stand?.modul_aktiv && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className={`p-6 rounded-2xl border ${stand.stand <= 10 ? 'bg-amber-50 border-amber-200' : 'bg-white border-stone-200'}`}>
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('post.kontingent')}</p>
              <p className="font-display text-5xl font-bold text-stone-900"
                 style={{ fontVariantNumeric: 'tabular-nums' }}>{stand.stand}</p>
              <p className="text-xs text-stone-500 mt-2">
                {t('post.gekauft_verbraucht', { gekauft: stand.gekauft, verbraucht: stand.verbraucht })}
              </p>
              {/* Ein Lauf ueber mehr Briefe als Kontingent bleibt in der
                  Mitte stehen. Besser hier warnen als dort. */}
              {stand.stand <= 10 && (
                <p className="text-xs text-amber-800 mt-3 leading-relaxed">{t('post.wenig_uebrig')}</p>
              )}
            </div>

            <div className="p-6 bg-white border border-stone-200 rounded-2xl">
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('post.preis_je_brief')}</p>
              <p className="font-display text-5xl font-bold text-stone-900"
                 style={{ fontVariantNumeric: 'tabular-nums' }}>
                {stand.preis_je_brief ? Number(stand.preis_je_brief).toFixed(2) : '—'}
              </p>
              <p className="text-xs text-stone-500 mt-2">{t('post.preis_hinweis', { waehrung: stand.waehrung })}</p>
            </div>

            <div className="p-6 bg-white border border-stone-200 rounded-2xl">
              <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('post.in_arbeit')}</p>
              <p className="font-display text-5xl font-bold text-stone-900"
                 style={{ fontVariantNumeric: 'tabular-nums' }}>{offen}</p>
              <p className="text-xs text-stone-500 mt-2">{t('post.in_arbeit_hinweis')}</p>
            </div>
          </div>

          {/* Kaufen. Ohne Preis kein Knopf, sondern der Grund. */}
          <div className="p-6 bg-white border border-stone-200 rounded-2xl">
            <div className="flex items-center gap-2 mb-4">
              <ShoppingCart size={16} className="text-stone-400" />
              <h3 className="font-display text-lg font-bold text-stone-900">{t('post.kaufen_titel')}</h3>
            </div>
            {!stand.kaufbar ? (
              <p className="text-sm text-stone-600 leading-relaxed">{t('post.kein_preis')}</p>
            ) : (
              <div className="flex flex-wrap items-end gap-4">
                <div>
                  <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">
                    {t('post.anzahl')}
                  </label>
                  <input type="number" min="1" max="10000" value={menge}
                    onChange={e => setMenge(e.target.value)}
                    className="w-32 p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm font-mono font-bold text-stone-900 focus:border-stone-400"/>
                </div>
                <div className="flex-1 min-w-[12rem]">
                  <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-1">{t('post.kostet')}</p>
                  <p className="text-2xl font-bold text-stone-900 font-mono"
                     style={{ fontVariantNumeric: 'tabular-nums' }}>
                    {summe !== null ? `${stand.waehrung} ${summe.toFixed(2)}` : '—'}
                  </p>
                  <p className="text-[11px] text-stone-400 mt-1">{t('post.kostet_hinweis')}</p>
                </div>
                <button onClick={kaufen} disabled={kauft || anzahl < 1 || anzahl > 10000}
                  className="px-6 py-3 bg-stone-900 text-white rounded-xl text-sm font-bold hover:bg-stone-800 disabled:opacity-40 flex items-center gap-2">
                  {kauft ? <Loader2 size={16} className="animate-spin" /> : <ShoppingCart size={16} />}
                  {t('post.kaufen_knopf', { anzahl })}
                </button>
              </div>
            )}
          </div>
        </>
      )}

      {/* Die Briefe. Zustand zuerst: danach wird gesucht. */}
      <div className="bg-white border border-stone-200 rounded-2xl overflow-hidden">
        <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
          <div>
            <h3 className="font-display text-lg font-bold text-stone-900">{t('post.briefe')}</h3>
            <p className="text-xs text-stone-500 mt-1">
              {briefe.length === 0 ? t('post.keine_briefe') :
                Object.entries(nachZustand)
                  .map(([z, n]) => `${n} ${zustandName(z).toLowerCase()}`)
                  .join(' · ')}
            </p>
          </div>
          <div className="flex gap-2 flex-wrap">
            <button onClick={pruefen}
              className="px-4 py-2 bg-stone-100 text-stone-700 rounded-xl text-xs font-bold hover:bg-stone-200 flex items-center gap-2">
              {t('post.zugang_pruefen')}
            </button>
            {offen > 0 && (
              <button onClick={uebergeben} disabled={arbeitet}
                className="px-4 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold hover:bg-stone-800 disabled:opacity-40 flex items-center gap-2">
                {arbeitet ? <Loader2 size={14} className="animate-spin" /> : <Send size={14} />}
                {t('post.jetzt_uebergeben', { anzahl: offen })}
              </button>
            )}
            <button onClick={laden}
              className="px-4 py-2 bg-stone-100 text-stone-700 rounded-xl text-xs font-bold hover:bg-stone-200 flex items-center gap-2">
              <RefreshCw size={14} /> {t('post.neu_laden')}
            </button>
          </div>
        </div>
        {briefe.length > 0 && (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                <tr>
                  <th className="text-left px-6 py-3">{t('post.sp.rechnung')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.empfaenger')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.zustand')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.meldung')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.erstellt')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.erledigt')}</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-50">
                {briefe.map(b => {
                  const z = ZUSTAND[b.r_zustand];
                  return (
                    <tr key={b.r_id} className="hover:bg-stone-50/50">
                      <td className="px-6 py-3 font-mono text-xs text-stone-900">{b.r_rechnung ?? '—'}</td>
                      <td className="px-4 py-3 text-stone-700 truncate max-w-[14rem]">{b.r_empfaenger ?? '—'}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold ${z?.farbe ?? 'bg-stone-100 text-stone-600'}`}>
                          {z?.symbol}{zustandName(b.r_zustand)}
                        </span>
                        {/* Versuche nur dann, wenn es mehr als einer war --
                            sonst steht ueberall eine 1 und sagt nichts. */}
                        {b.r_versuche > 1 && (
                          <span className="text-[10px] text-stone-400 ml-2">{t('post.versuche', { anzahl: b.r_versuche })}</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-xs text-stone-500 max-w-[18rem]">
                        {b.r_fehler
                          ? <span className="text-red-700">{b.r_fehler}</span>
                          : (b.r_meldung ?? b.r_status ?? '—')}
                      </td>
                      <td className="px-4 py-3 text-xs text-stone-400 whitespace-nowrap">{datum(b.r_erstellt)}</td>
                      <td className="px-4 py-3 text-xs text-stone-400 whitespace-nowrap">{datum(b.r_erledigt)}</td>
                      <td className="px-4 py-3 text-right">
                        {/* Abbrechen geht nur, solange der Brief noch nicht
                            uebergeben ist. Danach ist er gedruckt. */}
                        {b.r_zustand === 'WARTEND' && (
                          <button onClick={() => abbrechen(b.r_id)}
                            className="px-3 py-1.5 bg-stone-100 text-stone-600 rounded-lg text-xs font-bold hover:bg-red-50 hover:text-red-700 flex items-center gap-1.5 ml-auto">
                            <XCircle size={13} /> {t('post.abbrechen')}
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Das Kontingentbuch. Jede Bewegung mit Grund: wer sich fragt,
          wohin die Briefe gegangen sind, findet es hier und nicht in
          einer Differenz zweier Zahlen. */}
      {buch.length > 0 && (
        <div className="bg-white border border-stone-200 rounded-2xl overflow-hidden">
          <div className="p-6">
            <h3 className="font-display text-lg font-bold text-stone-900">{t('post.buch_titel')}</h3>
            <p className="text-xs text-stone-500 mt-1">{t('post.buch_hinweis')}</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                <tr>
                  <th className="text-left px-6 py-3">{t('post.sp.art')}</th>
                  <th className="text-right px-4 py-3">{t('post.sp.menge')}</th>
                  <th className="text-right px-4 py-3">{t('post.sp.betrag')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.grund')}</th>
                  <th className="text-left px-4 py-3">{t('post.sp.wann')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-50">
                {buch.map((e, i) => (
                  <tr key={i} className="hover:bg-stone-50/50">
                    <td className="px-6 py-3 font-bold text-xs text-stone-700">{artName(e.r_art)}</td>
                    <td className="px-4 py-3 text-right font-mono text-stone-900"
                        style={{ fontVariantNumeric: 'tabular-nums' }}>
                      {e.r_menge > 0 ? `+${e.r_menge}` : e.r_menge}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-xs text-stone-500"
                        style={{ fontVariantNumeric: 'tabular-nums' }}>
                      {e.r_preis ? `${e.r_waehrung ?? 'CHF'} ${Number(e.r_preis).toFixed(2)}` : '—'}
                    </td>
                    <td className="px-4 py-3 text-xs text-stone-500">
                      {e.r_grund ?? '—'}
                      {e.r_rechnung && <span className="font-mono text-stone-400 ml-2">{e.r_rechnung}</span>}
                    </td>
                    <td className="px-4 py-3 text-xs text-stone-400 whitespace-nowrap">{datum(e.r_am)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminBriefversand;
