import React, { useEffect, useState } from 'react';
import { Loader2, ShieldCheck, ShieldOff, AlertTriangle, Check } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Schreibrecht des Vorstands.
//
// Standardmaessig darf der Vorstand alles aendern, was die
// Vereinsadministration darf -- das ist bei den meisten Vereinen richtig,
// weil dort ohnehin dieselben zwei Personen arbeiten. Wer es anders
// haelt, schaltet es hier aus: der Vorstand SIEHT dann weiterhin alles
// und aendert nichts mehr.
//
// Bewusst kein Schalter fuer den Vorstand selbst: wer sich das Recht
// zurueckgeben kann, hat es nie verloren. Die Datenbank weist ihn ab,
// unabhaengig davon, was diese Maske anzeigt.

const AdminVorstandsrechte: React.FC = () => {
  const [an, setAn] = useState<boolean | null>(null);
  const [darfAendern, setDarfAendern] = useState(false);
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);
  const [gespeichert, setGespeichert] = useState(false);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const [{ data: stand }, { data: wer }] = await Promise.all([
        supabase.rpc('vorstand_schreibrecht'),
        supabase.rpc('wer_bin_ich'),
      ]);
      if (!lebt) return;
      setAn(stand === null || stand === undefined ? true : !!stand);
      const w = Array.isArray(wer) ? wer[0] : wer;
      // Nur Administration und Betreiber. Die eigentliche Pruefung macht
      // die Datenbank; hier geht es nur darum, niemandem einen Schalter
      // hinzustellen, der ihn ohnehin nicht umlegen darf.
      setDarfAendern(!!w && (w.ist_betreiber || ['SUPER_ADMIN', 'ADMIN'].includes(w.rolle)));
    })();
    return () => { lebt = false; };
  }, []);

  const umschalten = async (neu: boolean) => {
    setArbeitet(true); setFehler(null);
    const { data, error } = await supabase.rpc('vorstand_schreibrecht_setzen', { p_an: neu });
    setArbeitet(false);
    if (error) { setFehler(error.message); return; }
    setAn(!!data);
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
  };

  if (an === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div className="flex items-start justify-between gap-6 flex-wrap">
        <div className="max-w-xl">
          <p className="text-sm font-bold text-stone-800 flex items-center gap-2">
            {an ? <ShieldCheck size={15} className="text-emerald-600" />
                : <ShieldOff size={15} className="text-amber-600" />}
            Der Vorstand darf Daten ändern
          </p>
          <p className="text-[11px] text-stone-500 leading-relaxed mt-2">
            {an
              ? 'Vorstandsmitglieder können Mitglieder, Beiträge, Buchhaltung und Inhalte ändern — wie die Vereinsadministration.'
              : 'Vorstandsmitglieder sehen weiterhin alles, können aber nichts mehr ändern. Ändern darf nur die Vereinsadministration.'}
          </p>
          <p className="text-[11px] text-stone-400 leading-relaxed mt-2">
            Das Lesen bleibt in beiden Fällen unberührt — Sitzungen, Protokolle und
            Mitgliederliste bleiben für den Vorstand sichtbar.
          </p>
        </div>

        {darfAendern ? (
          <div className="flex gap-1 bg-white p-1 rounded-xl border border-stone-200 shrink-0">
            {([[true, 'Darf ändern'], [false, 'Nur lesen']] as const).map(([w, n]) => (
              <button key={String(w)} onClick={() => umschalten(w)} disabled={arbeitet}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-40 ${
                  an === w ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                {arbeitet && an !== w ? <Loader2 size={12} className="animate-spin" />
                  : gespeichert && an === w ? <span className="flex items-center gap-1"><Check size={12} /> {n}</span>
                  : n}
              </button>
            ))}
          </div>
        ) : (
          <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 shrink-0">
            nur die Vereinsadministration
          </span>
        )}
      </div>
    </div>
  );
};

export default AdminVorstandsrechte;
