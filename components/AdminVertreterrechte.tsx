import React, { useEffect, useState } from 'react';
import { Loader2, Save, Check, AlertTriangle, MapPin, Lock } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Was ein Nachbarschafts-Verantwortlicher pflegen darf.
//
// Bis hierher stand die Liste im Quelltext. Das war besser als vorher --
// da stand sie nur in der Maske und war damit gar keine Schranke --, aber
// immer noch falsch: welche Felder ein Vertreter pflegen soll, weiss der
// Verein. Einer mit drei Nachbarschaften und einem Kassier, der alles
// selbst macht, will etwas anderes als einer mit neun Lagje in drei
// Kantonen.
//
// Drei Felder stehen bewusst NICHT zur Wahl, und das soll man sehen statt
// es zu suchen: Rolle, Nachbarschaft und Mitgliedsstatus. Wer sich selbst
// befoerdern oder Mitglieder in die eigene Lagje ziehen kann, pflegt
// keine Daten mehr, sondern erweitert seine Zustaendigkeit.

// Der Katalog steht in lib/vertreterfelder.ts, nicht hier.
//
// Er stand hier -- und die Betreuungsmaske hatte ihre eigene, kuerzere
// Fassung als Satz von Eingabefeldern. Die beiden sind auseinander
// gelaufen: 18 Felder freigegeben, 11 angeboten. Der Admin konnte
// "Vorname" ankreuzen, und in der Maske erschien nichts. Eine
// Einstellung, die nichts bewirkt, ist schlechter als keine.
import { VERTRETER_GRUPPEN as GRUPPEN } from '../lib/vertreterfelder';

const GESPERRT = [
  { name: 'Rolle', warum: 'Wer sich selbst befördern kann, ist nicht gebunden.' },
  { name: 'Nachbarschaft', warum: 'Wer Mitglieder in die eigene Lagje ziehen kann, erweitert seinen Zuständigkeitsbereich.' },
  { name: 'Mitgliedsstatus', warum: 'Eine Mitgliedschaft zu beenden ist keine Datenpflege — dafür gibt es die Meldung an den Vorstand.' },
];

const AdminVertreterrechte: React.FC = () => {
  const [gewaehlt, setGewaehlt] = useState<Set<string> | null>(null);
  const [darf, setDarf] = useState(false);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const [{ data: t }, { data: wer }] = await Promise.all([
        supabase.from('tenants').select('vertreter_felder').maybeSingle(),
        supabase.rpc('wer_bin_ich'),
      ]);
      if (!lebt) return;
      setGewaehlt(new Set(((t as any)?.vertreter_felder as string[]) ?? []));
      const w = Array.isArray(wer) ? wer[0] : wer;
      setDarf(!!w && (w.ist_betreiber || ['SUPER_ADMIN', 'ADMIN'].includes(w.rolle)));
    })();
    return () => { lebt = false; };
  }, []);

  const sichern = async () => {
    if (!gewaehlt) return;
    setSpeichert(true); setFehler(null);
    const { data, error } = await supabase.rpc('vertreter_felder_setzen',
      { p_felder: [...gewaehlt] });
    setSpeichert(false);
    if (error) { setFehler(error.message); return; }
    // Die Datenbank verwirft, was nicht erlaubt ist. Weicht das Ergebnis
    // ab, soll das hier stehen statt stillschweigend unterzugehen.
    const zurueck = new Set((data as string[]) ?? []);
    if (zurueck.size !== gewaehlt.size) {
      setFehler(`${zurueck.size} von ${gewaehlt.size} übernommen — die übrigen sind gesperrt.`);
    }
    setGewaehlt(zurueck);
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
  };

  if (gewaehlt === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
      {fehler && (
        <p className="text-xs text-amber-700 bg-amber-50 border border-amber-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div>
        <p className={`${marke} flex items-center gap-2`}>
          <MapPin size={13} /> Was ein Verantwortlicher einer Nachbarschaft pflegen darf
        </p>
        <p className="text-[11px] text-stone-500 leading-relaxed mt-2 max-w-2xl">
          Er sieht nur Mitglieder seiner eigenen Lagje. Was er dort ändern darf,
          bestimmen Sie hier — und zwar wirksam: die Datenbank weist alles andere
          ab, nicht nur die Maske.
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        {GRUPPEN.map(g => (
          <div key={g.titel} className="bg-white rounded-2xl border border-stone-100 p-4">
            <p className={`${marke} mb-3`}>{g.titel}</p>
            <div className="space-y-1">
              {g.felder.map(f => (
                <label key={f.key}
                  className={`flex items-start gap-2.5 py-1.5 px-2 rounded-lg ${
                    darf ? 'hover:bg-stone-50 cursor-pointer' : 'opacity-60'}`}>
                  <input type="checkbox" disabled={!darf} checked={gewaehlt.has(f.key)}
                    onChange={e => {
                      const n = new Set(gewaehlt);
                      e.target.checked ? n.add(f.key) : n.delete(f.key);
                      setGewaehlt(n);
                    }}
                    className="w-4 h-4 accent-stone-900 mt-0.5 shrink-0" />
                  <span>
                    <span className="text-xs text-stone-800">{f.name}</span>
                    {f.hinweis && (
                      <span className="block text-[10px] text-amber-700">{f.hinweis}</span>
                    )}
                  </span>
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-stone-100 p-4">
        <p className={`${marke} flex items-center gap-2 mb-3`}>
          <Lock size={13} /> Nie wählbar
        </p>
        <div className="space-y-2">
          {GESPERRT.map(g => (
            <p key={g.name} className="text-[11px] text-stone-500 leading-relaxed">
              <span className="font-bold text-stone-700">{g.name}</span> — {g.warum}
            </p>
          ))}
        </div>
      </div>

      {darf ? (
        <div className="flex items-center gap-3">
          <button onClick={sichern} disabled={speichert}
            className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2 rounded-xl
                       text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
            {speichert ? <Loader2 size={12} className="animate-spin" />
              : gespeichert ? <Check size={12} /> : <Save size={12} />}
            {gespeichert ? 'Gespeichert' : 'Speichern'}
          </button>
          <span className="text-[11px] text-stone-400">
            {gewaehlt.size === 0 ? 'nichts — er kann dann nur lesen'
              : `${gewaehlt.size} Felder freigegeben`}
          </span>
        </div>
      ) : (
        <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
          nur die Vereinsadministration
        </span>
      )}
    </div>
  );
};

export default AdminVertreterrechte;
