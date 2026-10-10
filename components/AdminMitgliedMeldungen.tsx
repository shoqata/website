import React, { useEffect, useState } from 'react';
import { Loader2, Check, X, AlertTriangle, UserMinus } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Meldungen aus den Nachbarschaften ueber Mitglieder.
//
// Dieselbe Form wie bei der Barzahlung: der Verantwortliche vor Ort
// meldet, der Vorstand entscheidet. Wer jemanden auf inaktiv setzt,
// beendet eine Mitgliedschaft -- das ist keine Datenpflege, und deshalb
// darf es der Vertreter nicht selbst.
//
// Sind keine offen, erscheint hier nichts. Ein leerer Kasten mit
// "Keine Meldungen" nimmt Platz und sagt nichts.

type Meldung = {
  id: string; memberId: string; art: string; bemerkung: string | null;
  reportedBy: string | null; createdAt: string;
};

const ARTEN: Record<string, string> = {
  INAKTIV: 'Mitgliedschaft beenden',
  VERSTORBEN: 'Verstorben',
  WEGGEZOGEN: 'Weggezogen',
  SONSTIGES: 'Sonstiges',
};

const AdminMitgliedMeldungen: React.FC = () => {
  const [offen, setOffen] = useState<Meldung[] | null>(null);
  const [namen, setNamen] = useState<Record<string, string>>({});
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  const laden = async () => {
    const { data, error } = await supabase.from('mitglied_meldungen')
      .select('id,memberId,art,bemerkung,reportedBy,createdAt')
      .eq('status', 'OFFEN').order('createdAt', { ascending: false });
    if (error) { setFehler(error.message); setOffen([]); return; }
    const liste = (data as Meldung[]) ?? [];
    setOffen(liste);
    const ids = [...new Set(liste.flatMap(m => [m.memberId, m.reportedBy].filter(Boolean)))] as string[];
    if (ids.length) {
      const { data: u } = await supabase.from('users').select('id,displayName').in('id', ids);
      setNamen(Object.fromEntries(((u as any[]) ?? []).map(x => [x.id, x.displayName])));
    }
  };
  useEffect(() => { laden(); }, []);

  const entscheiden = async (m: Meldung, uebernehmen: boolean) => {
    setArbeitet(m.id); setFehler(null);
    const { error } = await supabase.rpc('mitglied_meldung_entscheiden', {
      p_id: m.id, p_uebernehmen: uebernehmen, p_notiz: null,
    });
    setArbeitet(null);
    if (error) { setFehler(error.message); return; }
    await laden();
  };

  if (offen === null || (offen.length === 0 && !fehler)) return null;

  return (
    <div className="bg-amber-50/60 border border-amber-100 rounded-3xl p-6 space-y-4">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}
      <p className="text-[10px] font-bold uppercase tracking-widest text-amber-700 flex items-center gap-2">
        <UserMinus size={13} /> Meldungen aus den Nachbarschaften ({offen.length})
      </p>

      <div className="space-y-2">
        {offen.map(m => (
          <div key={m.id} className="bg-white rounded-2xl border border-stone-100 p-4
                                     flex items-start justify-between gap-4 flex-wrap">
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-stone-800">
                {namen[m.memberId] ?? m.memberId}
                <span className="ml-2 text-[10px] font-bold uppercase tracking-widest
                                 text-amber-700 bg-amber-50 border border-amber-100
                                 rounded px-1.5 py-0.5">
                  {ARTEN[m.art] ?? m.art}
                </span>
              </p>
              {m.bemerkung && (
                <p className="text-xs text-stone-600 mt-1.5 leading-relaxed">„{m.bemerkung}"</p>
              )}
              <p className="text-[10px] text-stone-400 mt-1.5">
                gemeldet von {namen[m.reportedBy ?? ''] ?? '—'}
                {m.createdAt && `, ${new Date(m.createdAt).toLocaleDateString('de-CH')}`}
              </p>
            </div>
            <div className="flex gap-2 shrink-0">
              <button onClick={() => entscheiden(m, true)} disabled={arbeitet === m.id}
                className="flex items-center gap-1.5 bg-stone-900 text-white px-3 py-2 rounded-xl
                           text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
                {arbeitet === m.id ? <Loader2 size={12} className="animate-spin" /> : <Check size={12} />}
                Übernehmen
              </button>
              <button onClick={() => entscheiden(m, false)} disabled={arbeitet === m.id}
                className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-[10px]
                           font-bold uppercase tracking-widest text-stone-400 hover:text-stone-700">
                <X size={12} /> Ablehnen
              </button>
            </div>
          </div>
        ))}
      </div>
      <p className="text-[11px] text-stone-500 leading-relaxed">
        „Übernehmen" setzt das Mitglied auf inaktiv. Rechnungen und Zahlungen bleiben
        erhalten — der Datensatz verschwindet nicht.
      </p>
    </div>
  );
};

export default AdminMitgliedMeldungen;
