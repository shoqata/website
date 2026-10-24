import React, { useEffect, useState } from 'react';
import { Globe2 } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { landName } from '../lib/laender';

// Fuer den Vertreter: wofuer er zustaendig ist, wenn er sich eine
// Nachbarschaft mit anderen teilt. Ohne Kollegen bleibt die Zeile weg --
// dann sieht er ohnehin alle.
type Zeile = { r_nachbarschaft: string; r_name: string; r_laender: string[];
               r_eigene: number; r_offen: number; r_kollegen: number };

const MeineZustaendigkeit: React.FC = () => {
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  useEffect(() => {
    supabase.rpc('meine_zustaendigkeit').then(({ data }) =>
      setZeilen(((data as Zeile[]) ?? []).filter(z => z.r_kollegen > 0)));
  }, []);
  if (!zeilen.length) return null;
  return (
    <div className="mb-5 space-y-1.5">
      {zeilen.map(z => (
        <p key={z.r_nachbarschaft} className="text-xs text-stone-300 flex items-start gap-2 leading-relaxed">
          <Globe2 size={13} className="shrink-0 mt-0.5 text-stone-400" />
          <span>
            {zeilen.length > 1 && <strong className="text-white">{z.r_name}: </strong>}
            Sie teilen sich diese Nachbarschaft mit {z.r_kollegen} {z.r_kollegen === 1 ? 'weiteren Vertreter' : 'weiteren Vertretern'}.
            {' '}Sie sehen Ihre {z.r_eigene} zugeteilten Mitglieder
            {z.r_laender.length > 0 && <> ({z.r_laender.map(landName).join(', ')})</>}
            {z.r_offen > 0 && <> und {z.r_offen}, die noch niemandem zugeteilt sind</>}.
          </span>
        </p>
      ))}
    </div>
  );
};

export default MeineZustaendigkeit;
