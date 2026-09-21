import React, { useEffect, useState } from 'react';
import { Blocks, Check, Loader2, AlertTriangle, Lock, Sparkles, Wrench } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Der Modulmarktplatz.
//
// Dieselbe Komponente dient beiden Seiten: dem Verein, der sieht was er hat,
// und dem Betreiber, der umschaltet. Der Unterschied ist eine Eigenschaft --
// eine zweite, fast gleiche Maske wuerde frueher oder spaeter auseinander
// laufen.
//
// Was hier angezeigt wird, rechnet die Datenbank mit derselben Regel, die
// auch die Zeilenregeln anwenden (modul_aktiv). Die Maske hat keine eigene
// Vorstellung davon, ob ein Modul laeuft -- sonst koennte sie "an" zeigen,
// waehrend die Daten gesperrt sind.

export type Modulzeile = {
  schluessel: string; name: string; beschreibung: string | null;
  ist_kern: boolean; status: string; braucht_einrichtung: boolean;
  preis_monat: number | null; preis_einmalig: number | null;
  zustand: string; testet_bis: string | null; seit: string | null;
  aktiv: boolean; frei_fuer_verein: boolean; reihenfolge: number;
};

const Marktplatz: React.FC<{
  // Ohne Vereinskennung: der eigene Verein. Mit: die Sicht des Betreibers.
  verein?: string;
  // Nur der Betreiber darf umschalten; ohne diesen Rueckruf ist die Liste
  // reine Anzeige.
  umschalten?: (modul: string, zustand: string) => Promise<void>;
  dunkel?: boolean;
}> = ({ verein, umschalten, dunkel = false }) => {
  const { t } = useTranslation();
  const [zeilen, setZeilen] = useState<Modulzeile[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const laden = async () => {
    setFehler(null);
    try {
      const { data, error } = await supabase.rpc('marktplatz_uebersicht',
        verein ? { p_verein: verein } : {});
      if (error) throw error;
      setZeilen(data ?? []);
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { setLaedt(true); laden(); }, [verein]);

  const schalten = async (m: Modulzeile, zustand: string) => {
    if (!umschalten) return;
    setArbeitet(m.schluessel); setFehler(null);
    try { await umschalten(m.schluessel, zustand); await laden(); }
    catch (e: any) { setFehler(e?.message ?? String(e)); }
    finally { setArbeitet(null); }
  };

  const F = dunkel
    ? { karte: 'bg-white/5 border-white/10', titel: 'text-white', text: 'text-stone-400',
        marke: 'text-stone-500', rahmen: 'border-white/10' }
    : { karte: 'bg-white border-stone-100', titel: 'text-stone-900', text: 'text-stone-500',
        marke: 'text-stone-400', rahmen: 'border-stone-100' };

  if (laedt) return (
    <div className={`flex items-center gap-3 p-8 ${F.text}`}>
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('markt.laedt')}</span>
    </div>
  );

  const frei = zeilen[0]?.frei_fuer_verein;

  return (
    <div className="space-y-4">
      {fehler && (
        <div className="flex gap-3 items-start p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-xs text-rose-400">
          <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
        </div>
      )}

      {frei && (
        <div className={`flex gap-3 items-start p-4 rounded-2xl border ${F.rahmen} ${F.karte}`}>
          <Sparkles size={16} className="shrink-0 mt-0.5 text-emerald-500" />
          <p className={`text-xs leading-relaxed ${F.text}`}>{t('markt.frei_hinweis')}</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {zeilen.map(m => {
          const gesperrt = m.zustand === 'GESPERRT';
          const eingestellt = m.status === 'EINGESTELLT';
          return (
            <div key={m.schluessel}
                 className={`p-5 rounded-2xl border ${F.karte} ${F.rahmen} ${m.aktiv ? '' : 'opacity-75'}`}>
              <div className="flex items-start justify-between gap-3 mb-2">
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap mb-1">
                    <h4 className={`font-bold text-sm ${F.titel}`}>{m.name}</h4>
                    {m.ist_kern && (
                      <span className="inline-flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded bg-stone-500/15 text-stone-400">
                        <Lock size={9} /> {t('markt.kern')}
                      </span>
                    )}
                    {m.status === 'BETA' && (
                      <span className="text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded bg-amber-500/15 text-amber-500">
                        {t('markt.beta')}
                      </span>
                    )}
                    {eingestellt && (
                      <span className="text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded bg-stone-500/15 text-stone-400">
                        {t('markt.geplant')}
                      </span>
                    )}
                  </div>
                  <p className={`text-xs leading-relaxed ${F.text}`}>{m.beschreibung}</p>
                </div>

                {/* Der Stand. Er kommt aus derselben Rechnung wie die
                    Zeilenregeln -- nicht aus einer eigenen Vermutung. */}
                <span className={`shrink-0 text-[9px] font-bold uppercase tracking-widest px-2.5 py-1 rounded ${
                  gesperrt ? 'bg-rose-500/15 text-rose-400'
                  : m.aktiv ? 'bg-emerald-500/15 text-emerald-500'
                  : 'bg-stone-500/15 text-stone-400'}`}>
                  {gesperrt ? t('markt.gesperrt') : m.aktiv ? t('markt.an') : t('markt.aus')}
                </span>
              </div>

              <div className="flex items-center justify-between gap-3 mt-3 pt-3 border-t ${F.rahmen}"
                   style={{ borderColor: dunkel ? 'rgba(255,255,255,.1)' : '#f5f5f4' }}>
                <div className={`text-[10px] ${F.marke} flex items-center gap-3 flex-wrap`}>
                  <span>
                    {m.preis_monat == null
                      ? t('markt.im_grundpreis')
                      : `${Number(m.preis_monat).toFixed(2)} ${t('markt.pro_monat')}`}
                  </span>
                  {m.braucht_einrichtung && (
                    <span className="inline-flex items-center gap-1">
                      <Wrench size={10} /> {t('markt.einrichtung')}
                    </span>
                  )}
                </div>

                {umschalten && !m.ist_kern && !eingestellt && (
                  <div className="flex gap-1.5 shrink-0">
                    {(['AN','AUS','GESPERRT'] as const).map(z => (
                      <button key={z} onClick={() => schalten(m, z)}
                              disabled={arbeitet === m.schluessel || m.zustand === z}
                              className={`px-2.5 py-1 rounded text-[9px] font-bold uppercase tracking-widest transition-colors disabled:opacity-100 ${
                                m.zustand === z
                                  ? (z === 'GESPERRT' ? 'bg-rose-500 text-white'
                                     : z === 'AN' ? 'bg-emerald-500 text-white' : 'bg-stone-500 text-white')
                                  : 'bg-stone-500/15 text-stone-400 hover:bg-stone-500/25'}`}>
                        {arbeitet === m.schluessel && m.zustand !== z
                          ? <Loader2 className="animate-spin" size={9} />
                          : t(`markt.${z.toLowerCase()}`)}
                      </button>
                    ))}
                  </div>
                )}

                {!umschalten && m.aktiv && !m.ist_kern && (
                  <Check size={14} className="text-emerald-500 shrink-0" />
                )}
              </div>
            </div>
          );
        })}
      </div>

      {!umschalten && (
        <p className={`text-[11px] ${F.marke} pt-2`}>{t('markt.nur_betreiber')}</p>
      )}
    </div>
  );
};

export default Marktplatz;
