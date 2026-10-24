import React, { useEffect, useState } from 'react';
import { Loader2 } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Im Mitgliederprofil: welcher Vertreter der Nachbarschaft fuer dieses
// Mitglied zustaendig ist. Speichert sofort -- die Zuteilung haengt nicht
// am Speichern-Knopf des Profils, weil sie ueber betreuer_setzen laeuft
// und der Vertreter-Feldschutz sie sonst nicht durchliesse.
// Erscheint nur, wenn die Nachbarschaft mehr als einen Vertreter hat.
// onGeaendert: das Profil speichert spaeter den ganzen Datensatz; ohne den
// neuen Wert schriebe es die alte Zuteilung zurueck.
const BetreuerAuswahl: React.FC<{ mitglied: string; nachbarschaft?: string | null;
                                  onGeaendert?: (betreuer: string | null) => void }> = ({ mitglied, nachbarschaft, onGeaendert }) => {
  const [vertreter, setVertreter] = useState<{ id: string; name: string }[]>([]);
  const [wert, setWert] = useState<string>('');
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState('');

  useEffect(() => {
    if (!nachbarschaft) { setVertreter([]); return; }
    (async () => {
      const [s, m] = await Promise.all([
        supabase.rpc('zustaendigkeit_stand'),
        supabase.rpc('zustaendigkeit_mitglieder', { p_nb: nachbarschaft }),
      ]);
      setVertreter(((s.data as any[]) ?? []).filter(z => z.r_nachbarschaft === nachbarschaft)
        .map(z => ({ id: z.r_person, name: z.r_person_name })));
      setWert(((m.data as any[]) ?? []).find(x => x.r_id === mitglied)?.r_betreuer || '');
    })();
  }, [mitglied, nachbarschaft]);

  if (vertreter.length < 2) return null;

  const setzen = async (neu: string) => {
    setArbeitet(true); setFehler('');
    const { error } = await supabase.rpc('betreuer_setzen', { p_mitglieder: [mitglied], p_betreuer: neu || null });
    setArbeitet(false);
    if (error) setFehler(error.message); else { setWert(neu); onGeaendert?.(neu || null); }
  };

  return (
    <div>
      <label className="text-[10px] font-bold text-stone-400 uppercase block mb-1 flex items-center gap-2">
        Zuständiger Vertreter {arbeitet && <Loader2 size={11} className="animate-spin" />}
      </label>
      <select value={wert} disabled={arbeitet} onChange={e => setzen(e.target.value)}
        className="w-full p-4 bg-white border border-stone-200 rounded-xl outline-none font-bold">
        <option value="">Alle Vertreter der Nachbarschaft</option>
        {vertreter.map(v => <option key={v.id} value={v.id}>{v.name}</option>)}
      </select>
      {fehler && <p className="text-xs text-red-600 mt-1">{fehler}</p>}
    </div>
  );
};

export default BetreuerAuswahl;
