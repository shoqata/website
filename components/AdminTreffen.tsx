import React, { useEffect, useState } from 'react';
import { Loader2, CalendarDays, Check, X, HelpCircle } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import TreffenAntwort, { type Person } from './TreffenAntwort';

// Einladungen zu Vereinstreffen -- aus der Sicht des eingeladenen Vereins.
//
// Dasselbe Formular wie beim Gastverein, nur der Weg hinein ist ein
// anderer: hier die Sitzung, dort ein Token. Zwei Nachbildungen desselben
// Formulars liefen frueher oder spaeter auseinander.
//
// Was hier ankommt, entscheidet treffen_meine() in der Datenbank:
// Entwuerfe nicht, Vergangenes nicht, und immer nur die EIGENE Delegation.

const AdminTreffen: React.FC = () => {
  const [liste, setListe] = useState<any[] | null>(null);
  const [offen, setOffen] = useState<string | null>(null);

  const laden = async () => {
    const { data, error } = await supabase.rpc('treffen_meine');
    setListe(error ? [] : (data as any[]) || []);
  };
  useEffect(() => { laden(); }, []);

  const speichern = (teilnehmerId: string) =>
    async (zugesagt: boolean, bemerkung: string, leute: Person[]) => {
      const { error } = await supabase.rpc('treffen_mein_antworten', {
        p_teilnehmer: teilnehmerId, p_zugesagt: zugesagt,
        p_bemerkung: bemerkung, p_delegation: leute,
      });
      if (error) throw error;
      await laden();
    };

  if (liste === null) return (
    <div className="flex items-center gap-2 text-stone-400 text-sm p-10">
      <Loader2 className="animate-spin" size={16} /> …
    </div>
  );

  if (liste.length === 0) return (
    <div className="max-w-3xl mx-auto p-10 text-center">
      <CalendarDays size={28} className="text-stone-300 mx-auto mb-4" />
      <p className="font-bold text-stone-900 mb-2">Keine Einladung offen</p>
      <p className="text-sm text-stone-500 leading-relaxed max-w-md mx-auto">
        Hier erscheinen Vereinstreffen, zu denen Ihr Verein eingeladen wurde — mit der
        Möglichkeit zuzusagen und einzutragen, wer mitkommt.
      </p>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto space-y-4 p-2">
      <div className="mb-6">
        <h2 className="text-xl font-bold text-stone-900">Vereinstreffen</h2>
        <p className="text-xs text-stone-400 mt-0.5">
          Einladungen, Zusagen und wer von Ihrem Verein mitkommt.
        </p>
      </div>

      {liste.map((t: any) => {
        const auf = offen === t.teilnehmer_id;
        const stand = t.zugesagt === true ? { w: 'zugesagt', f: 'text-emerald-600', S: Check }
          : t.zugesagt === false ? { w: 'abgesagt', f: 'text-stone-400', S: X }
          : { w: 'noch offen', f: 'text-amber-600', S: HelpCircle };
        const S = stand.S;
        return (
          <div key={t.teilnehmer_id} className="bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden">
            <button onClick={() => setOffen(auf ? null : t.teilnehmer_id)}
              className="w-full text-left px-7 py-5 flex items-center justify-between gap-4 hover:bg-stone-50/60">
              <div className="min-w-0">
                <p className="font-bold text-stone-900 truncate">{t.treffen.titel}</p>
                <p className="text-[11px] text-stone-400 mt-0.5">
                  {new Date(t.treffen.datum).toLocaleDateString('de-CH')}
                  {t.treffen.ort ? ` · ${t.treffen.ort}` : ''}
                  {t.zugesagt ? ` · ${t.personen} Personen` : ''}
                </p>
              </div>
              <span className={`flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest shrink-0 ${stand.f}`}>
                <S size={13} /> {stand.w}
              </span>
            </button>
            {auf && (
              <div className="px-7 pb-7 pt-1 border-t border-stone-100">
                <TreffenAntwort daten={t} speichern={speichern(t.teilnehmer_id)} />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default AdminTreffen;
