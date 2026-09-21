import React, { useEffect, useState } from 'react';
import { Blocks, Loader2, AlertTriangle, Check, Building2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Der Katalog aus Sicht des Betreibers.
//
// Hier wird nicht je Verein geschaltet -- das geschieht im Verwalten-Dialog
// eines Vereins. Hier steht das Angebot selbst: was es gibt, was es kostet,
// und wie viele Vereine es nutzen.
//
// Der Schluessel laesst sich nicht aendern und ein Kernmodul nicht zum
// Zusatzmodul machen: beides haengt an den Zeilenregeln, und eine Maske,
// die das erlaubt, waere eine Falle.

type Zeile = {
  schluessel: string; name: string; status: string; ist_kern: boolean;
  preis_monat: number | null; vereine_an: number; vereine_gesperrt: number;
  vereine_gesamt: number; reihenfolge: number;
};

const SuperAdminModule: React.FC = () => {
  const { t } = useTranslation();
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [entwurf, setEntwurf] = useState<Record<string, string>>({});

  const laden = async () => {
    setFehler(null);
    try {
      const { data, error } = await supabase.rpc('modul_verbreitung');
      if (error) throw error;
      setZeilen(data ?? []);
    } catch (e: any) { setFehler(e?.message ?? String(e)); }
    finally { setLaedt(false); }
  };
  useEffect(() => { laden(); }, []);

  const speichern = async (m: Zeile, felder: Record<string, any>) => {
    setArbeitet(m.schluessel); setFehler(null);
    try {
      const { error } = await supabase.rpc('modul_katalog_speichern',
        { p_schluessel: m.schluessel, ...felder });
      if (error) throw error;
      await laden();
    } catch (e: any) { setFehler(e?.message ?? String(e)); }
    finally { setArbeitet(null); }
  };

  const preisSpeichern = (m: Zeile) => {
    const roh = (entwurf[m.schluessel] ?? '').trim();
    // Leer heisst "im Grundpreis enthalten". Die Datenbank unterscheidet
    // NULL (nicht aendern) von -1 (auf NULL setzen) -- anders liesse sich
    // ein gesetzter Preis nie wieder entfernen.
    const wert = roh === '' ? -1 : Number(roh);
    if (roh !== '' && (isNaN(wert) || wert < 0)) {
      setFehler(t('samod.preis_ungueltig')); return;
    }
    speichern(m, { p_preis_monat: wert });
    setEntwurf(e => { const n = { ...e }; delete n[m.schluessel]; return n; });
  };

  if (laedt) return (
    <div className="flex items-center gap-3 p-8 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('markt.laedt')}</span>
    </div>
  );

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-2">
        <Blocks size={18} className="text-stone-500" />
        <h3 className="text-xs font-bold uppercase tracking-widest text-stone-400">{t('samod.titel')}</h3>
      </div>

      {fehler && (
        <div className="flex gap-3 items-start p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-xs text-rose-400">
          <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
        </div>
      )}

      <div className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left" style={{ minWidth: 620 }}>
            <thead>
              <tr className="text-[10px] uppercase tracking-widest text-stone-500">
                <th className="px-5 py-3 font-normal">{t('samod.modul')}</th>
                <th className="px-3 py-3 font-normal">{t('samod.status')}</th>
                <th className="px-3 py-3 font-normal">{t('samod.preis')}</th>
                <th className="px-5 py-3 font-normal text-right">{t('samod.verbreitung')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {zeilen.map(m => (
                <tr key={m.schluessel} className="text-sm">
                  <td className="px-5 py-3">
                    <div className="font-bold text-white">{m.name}</div>
                    <div className="font-mono text-[10px] text-stone-500">{m.schluessel}</div>
                  </td>

                  <td className="px-3 py-3">
                    {m.ist_kern ? (
                      <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                        {t('markt.kern')}
                      </span>
                    ) : (
                      <select value={m.status} disabled={arbeitet === m.schluessel}
                              onChange={e => speichern(m, { p_status: e.target.value })}
                              className="bg-white/5 border border-white/10 rounded-lg px-2 py-1.5 text-xs text-white outline-none">
                        <option value="VERFUEGBAR">{t('samod.verfuegbar')}</option>
                        <option value="BETA">{t('markt.beta')}</option>
                        <option value="EINGESTELLT">{t('markt.geplant')}</option>
                      </select>
                    )}
                  </td>

                  <td className="px-3 py-3">
                    {m.ist_kern ? (
                      <span className="text-xs text-stone-500">{t('markt.im_grundpreis')}</span>
                    ) : (
                      <div className="flex items-center gap-2">
                        <input
                          value={entwurf[m.schluessel] ?? (m.preis_monat == null ? '' : String(m.preis_monat))}
                          onChange={e => setEntwurf({ ...entwurf, [m.schluessel]: e.target.value })}
                          onBlur={() => entwurf[m.schluessel] !== undefined && preisSpeichern(m)}
                          onKeyDown={e => { if (e.key === 'Enter') preisSpeichern(m); }}
                          placeholder={t('samod.im_preis')}
                          className="w-24 bg-white/5 border border-white/10 rounded-lg px-2 py-1.5 text-xs text-white outline-none tabular-nums" />
                        {arbeitet === m.schluessel && <Loader2 className="animate-spin text-stone-500" size={12} />}
                      </div>
                    )}
                  </td>

                  <td className="px-5 py-3 text-right">
                    <div className="inline-flex items-center gap-2 text-xs">
                      <Building2 size={12} className="text-stone-500" />
                      <span className="text-white tabular-nums">{m.vereine_an}</span>
                      <span className="text-stone-500">/ {m.vereine_gesamt}</span>
                      {m.vereine_gesperrt > 0 && (
                        <span className="text-rose-400 tabular-nums">· {m.vereine_gesperrt} {t('markt.gesperrt')}</span>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <p className="text-[11px] text-stone-500 leading-relaxed">{t('samod.hinweis')}</p>
    </div>
  );
};

export default SuperAdminModule;
