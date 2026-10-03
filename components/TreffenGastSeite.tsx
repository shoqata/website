import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Loader2, AlertTriangle, Users } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import TreffenAntwort, { type Person } from './TreffenAntwort';

// Die Seite für einen Gastverein: kein Konto, kein Passwort.
//
// Der Verweis trägt ein Token, und daraus leitet die Datenbank ab, wer
// hier antwortet und für welches Treffen. Lesen und die eigene Delegation
// pflegen — mehr geht nicht, und zwar nicht weil die Oberfläche nichts
// anderes anbietet, sondern weil es keine Funktion gibt, die mit diesem
// Token etwas anderes täte.
//
// Die Namensliste anderer Vereine sieht er nicht. Das entscheidet
// treffen_sicht() in der Datenbank, nicht diese Seite.

const TreffenGastSeite: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const [daten, setDaten] = useState<any>(null);
  const [fehler, setFehler] = useState('');
  const [laedt, setLaedt] = useState(true);

  const laden = async () => {
    const { data, error } = await supabase.rpc('treffen_gast_lesen', { p_token: token });
    if (error) { setFehler(error.message || 'Zugang nicht gültig.'); setDaten(null); }
    else { setDaten(data); setFehler(''); }
    setLaedt(false);
  };
  useEffect(() => { laden(); /* eslint-disable-next-line */ }, [token]);

  const speichern = async (zugesagt: boolean, bemerkung: string, leute: Person[]) => {
    const { error } = await supabase.rpc('treffen_gast_antworten', {
      p_token: token, p_zugesagt: zugesagt, p_bemerkung: bemerkung,
      p_delegation: leute,
    });
    if (error) throw error;
    await laden();
  };

  return (
    <div className="min-h-screen bg-stone-100">
      <header className="bg-white border-b border-stone-200">
        <div className="max-w-3xl mx-auto px-5 py-4 flex items-center gap-3">
          <Users size={18} className="text-stone-400 shrink-0" />
          <div className="min-w-0">
            <p className="font-bold text-sm text-stone-900 truncate">
              {daten?.wer || 'Einladung'}
            </p>
            {daten?.gueltig_bis && (
              <p className="text-[11px] text-stone-400">
                Zugang gültig bis {new Date(daten.gueltig_bis).toLocaleDateString('de-CH')}
              </p>
            )}
          </div>
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-5 py-8">
        {laedt && (
          <div className="flex items-center gap-2 text-stone-400 py-20 justify-center">
            <Loader2 className="animate-spin" size={18} /> Einladung wird geladen …
          </div>
        )}

        {fehler && (
          <div className="bg-white border border-amber-200 rounded-2xl p-8 text-center mt-10">
            <AlertTriangle size={28} className="text-amber-500 mx-auto mb-4" />
            <p className="font-bold text-stone-900 mb-2">Dieser Zugang ist nicht verfügbar</p>
            <p className="text-sm text-stone-500 leading-relaxed max-w-md mx-auto">{fehler}</p>
            <p className="text-xs text-stone-400 mt-5 leading-relaxed max-w-md mx-auto">
              Zugänge sind befristet und können vom Gastgeber zurückgezogen werden.
              Melden Sie sich beim Gastgeber, wenn Sie einen neuen brauchen.
            </p>
          </div>
        )}

        {daten && !fehler && <TreffenAntwort daten={daten} speichern={speichern} />}
      </main>
    </div>
  );
};

export default TreffenGastSeite;
