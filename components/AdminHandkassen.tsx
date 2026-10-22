import React, { useEffect, useState } from 'react';
import { Wallet, Landmark, ArrowDownLeft, ArrowUpRight, CheckCircle2, ChevronDown } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';

// Die Handkassen der Vertreter vor Ort -- die Pruefung durch den Vorstand.
//
// Bar kassiert gilt sofort als bezahlt (Entscheid des Vereins). Damit das
// nicht ungeprueft bleibt, steht hier je Vertreter, wie viel Bargeld er
// haelt, und jede Bankeinzahlung wartet, bis jemand vom Vorstand sie auf dem
// Konto gesehen hat. Erst die Bestaetigung bucht sie (Bank an Kasse). Die
// eigene Einzahlung bestaetigt die Datenbank nicht.
//
// Die Ausgaben der Vertreter stehen darunter in der gewohnten Ausgabenliste
// und werden dort genehmigt und gebucht.

const geld = (n: number, w: string) => `${w} ${Number(n || 0).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const AdminHandkassen: React.FC = () => {
  const { showAlert, showConfirm } = useFeedback();
  const [kassen, setKassen] = useState<any[] | null>(null);
  const [offen, setOffen] = useState<string | null>(null);

  const laden = async () => {
    const { data, error } = await supabase.rpc('vertreter_kassen_uebersicht');
    if (error) { setKassen([]); return; }
    setKassen((data as any[]) || []);
  };
  useEffect(() => { laden(); }, []);

  const bestaetigen = async (k: any, e: any) => {
    const ok = await showConfirm({
      title: 'Einzahlung bestätigen?',
      message: `${geld(e.betrag, e.waehrung)} von ${k.name} sind auf dem Vereinskonto eingegangen. Die Einzahlung wird gebucht (Bank an Kasse).`,
      confirmText: 'Eingang bestätigen', type: 'primary',
    });
    if (!ok) return;
    const { error } = await supabase.rpc('vertreter_einzahlung_bestaetigen', { p_kasse: e.id });
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  if (kassen === null) return null;
  if (kassen.length === 0) return null;

  return (
    <div className="bg-white rounded-[2rem] border border-stone-100 p-6 md:p-8 mb-8 space-y-4">
      <div>
        <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2"><Wallet size={18} /> Handkassen der Vertreter</h3>
        <p className="text-xs text-stone-500 mt-1 leading-relaxed max-w-2xl">
          Bargeld, das die Vertreter vor Ort kassiert und noch nicht abgeliefert haben. Bankeinzahlungen
          bestätigen Sie, sobald sie auf dem Konto stehen. Ihre Ausgaben genehmigen Sie unten in der Ausgabenliste.
        </p>
      </div>
      <div className="divide-y divide-stone-100 border border-stone-100 rounded-2xl">
        {kassen.map(k => {
          const pruefen = (k.eintraege as any[]).filter(e => e.art === 'BANKEINZAHLUNG' && !e.bestaetigt_am);
          return (
            <div key={k.person}>
              <button onClick={() => setOffen(offen === k.person ? null : k.person)}
                      className="w-full p-4 flex flex-wrap items-center justify-between gap-3 text-left hover:bg-stone-50">
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-900">{k.name || k.person}</p>
                  {pruefen.length > 0 && (
                    <p className="text-[11px] text-amber-700 font-bold mt-0.5">{pruefen.length} Einzahlung(en) zu bestätigen</p>
                  )}
                </div>
                <div className="flex items-center gap-4">
                  {(k.bestand as any[]).map(b => (
                    <span key={b.waehrung} className={`font-mono font-bold text-sm ${Number(b.bestand) < 0 ? 'text-rose-600' : 'text-stone-900'}`}>
                      {geld(b.bestand, b.waehrung)}
                    </span>
                  ))}
                  <ChevronDown size={16} className={`text-stone-400 transition-transform ${offen === k.person ? 'rotate-180' : ''}`} />
                </div>
              </button>
              {offen === k.person && (
                <div className="px-4 pb-4 space-y-2">
                  {(k.eintraege as any[]).map(e => (
                    <div key={e.id} className="flex items-center gap-3 text-sm bg-stone-50 rounded-xl p-3">
                      {e.art === 'EINNAHME' ? <ArrowDownLeft size={15} className="text-emerald-600 shrink-0" />
                        : e.art === 'AUSGABE' ? <ArrowUpRight size={15} className="text-rose-600 shrink-0" />
                        : <Landmark size={15} className="text-sky-600 shrink-0" />}
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-stone-800">
                          {e.art === 'EINNAHME' ? `Beitrag ${e.mitglied_name || ''}` : e.art === 'AUSGABE' ? (e.notiz || 'Ausgabe') : 'Bankeinzahlung'}
                          {e.art === 'BANKEINZAHLUNG' && e.notiz ? ` · ${e.notiz}` : ''}
                        </p>
                        <p className="text-[11px] text-stone-500">
                          {new Date(e.erfasst_am).toLocaleString('de-CH', { dateStyle: 'short', timeStyle: 'short' })}
                          {e.beleg && <> · <a href={e.beleg} target="_blank" rel="noreferrer" className="underline">Beleg</a></>}
                        </p>
                      </div>
                      <span className="font-mono text-stone-700 shrink-0">{e.art === 'EINNAHME' ? '+' : '−'}{geld(e.betrag, e.waehrung)}</span>
                      {e.art === 'BANKEINZAHLUNG' && (e.bestaetigt_am ? (
                        <span className="text-[10px] font-bold uppercase text-emerald-700 flex items-center gap-1 shrink-0"><CheckCircle2 size={12} /> bestätigt</span>
                      ) : (
                        <button onClick={() => bestaetigen(k, e)}
                                className="px-3 py-1.5 bg-stone-900 text-white rounded-lg text-[11px] font-bold shrink-0">
                          Eingang bestätigen
                        </button>
                      ))}
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default AdminHandkassen;
