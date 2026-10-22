import React, { useEffect, useState } from 'react';
import { Loader2, Receipt, AlertTriangle, KeyRound } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Rechnungen fuer die Verantwortlichen einer Nachbarschaft -- je Person.
//
// Die Feldrechte daneben gelten fuer alle Verantwortlichen gemeinsam, weil
// es dort um Datenpflege geht. Rechnungen sind Geld und Vertrauen: dem
// einen gibt man sie, dem anderen nicht. Darum hier eine Zeile je Person.
//
// Die Schalter wirken in der Datenbank (payments_read und
// vertreter_rechnung_senden), nicht nur in der Maske. Weitergeleitet wird
// immer an die beim Mitglied hinterlegte Adresse -- der Vertreter kann
// keine andere angeben.

type Zeile = {
  person: string; name: string; email: string | null; zugang: boolean;
  nachbarschaften: string[]; sehen: boolean; senden: boolean;
};

const AdminVertreterRechnungen: React.FC<{ darf: boolean }> = ({ darf }) => {
  const [zeilen, setZeilen] = useState<Zeile[] | null>(null);
  const [laeuft, setLaeuft] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const [{ data: stand, error: e1 }, { data: rechte, error: e2 }] = await Promise.all([
        supabase.rpc('verantwortliche_stand'),
        supabase.rpc('vertreter_rechte_stand'),
      ]);
      if (!lebt) return;
      if (e1 || e2) { setFehler((e1 || e2)!.message); setZeilen([]); return; }
      const r = new Map(((rechte as any[]) || []).map(x => [x.person, x]));
      const je = new Map<string, Zeile>();
      for (const s of (stand as any[]) || []) {
        // Platzhalter aus der Erstbefuellung treffen auf keine Person.
        if (!s.r_email && s.r_person_name === s.r_person) continue;
        const z = je.get(s.r_person) ?? {
          person: s.r_person, name: s.r_person_name, email: s.r_email,
          zugang: !!s.r_hat_zugang, nachbarschaften: [],
          sehen: !!r.get(s.r_person)?.sehen, senden: !!r.get(s.r_person)?.senden,
        };
        z.nachbarschaften.push(s.r_name);
        je.set(s.r_person, z);
      }
      setZeilen([...je.values()].sort((a, b) => a.name.localeCompare(b.name)));
    })();
    return () => { lebt = false; };
  }, []);

  const setzen = async (z: Zeile, sehen: boolean, senden: boolean) => {
    setLaeuft(z.person); setFehler(null);
    const { data, error } = await supabase.rpc('vertreter_rechte_setzen',
      { p_person: z.person, p_sehen: sehen, p_senden: senden });
    setLaeuft(null);
    if (error) { setFehler(error.message); return; }
    // Die Datenbank entscheidet, was gilt (Weiterleiten schliesst Sehen ein).
    const d: any = Array.isArray(data) ? data[0] : data;
    setZeilen(zs => zs!.map(x => x.person === z.person
      ? { ...x, sehen: !!d?.sehen, senden: !!d?.senden } : x));
  };

  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
      <div>
        <p className={`${marke} flex items-center gap-2`}>
          <Receipt size={13} /> Rechnungen — je Verantwortlichem
        </p>
        <p className="text-[11px] text-stone-500 leading-relaxed mt-2 max-w-2xl">
          <span className="font-bold text-stone-700">Sehen</span>: die Rechnungen der Mitglieder
          seiner Nachbarschaft, mit Stand und PDF. <span className="font-bold text-stone-700">Weiterleiten</span>:
          zusätzlich per E-Mail an das Mitglied senden — immer an die hinterlegte Adresse,
          eine andere kann er nicht angeben. Die Mail nennt ihn als Absender.
        </p>
      </div>

      {fehler && (
        <p className="text-xs text-amber-700 bg-amber-50 border border-amber-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {zeilen === null ? (
        <div className="flex items-center gap-3 text-stone-400 text-sm">
          <Loader2 className="animate-spin" size={16} /> Lädt …
        </div>
      ) : zeilen.length === 0 ? (
        <p className="text-xs text-stone-400 italic">
          Noch niemand ist als verantwortlich für eine Nachbarschaft eingetragen.
        </p>
      ) : (
        <div className="bg-white rounded-2xl border border-stone-100 divide-y divide-stone-100">
          {zeilen.map(z => (
            <div key={z.person} className="p-4 flex flex-wrap items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="text-sm font-bold text-stone-900 truncate">{z.name}</p>
                <p className="text-[11px] text-stone-500 truncate">{z.nachbarschaften.join(' · ')}</p>
                {!z.zugang && (
                  <p className="text-[10px] text-amber-700 flex items-center gap-1 mt-0.5">
                    <KeyRound size={10} /> kann sich noch nicht anmelden — die Freigabe wirkt erst danach
                  </p>
                )}
              </div>
              <div className="flex items-center gap-4">
                {laeuft === z.person && <Loader2 size={14} className="animate-spin text-stone-400" />}
                <label className={`flex items-center gap-2 text-xs ${darf ? 'cursor-pointer' : 'opacity-60'}`}>
                  <input type="checkbox" className="w-4 h-4 accent-stone-900"
                    disabled={!darf || laeuft === z.person} checked={z.sehen}
                    onChange={e => setzen(z, e.target.checked, e.target.checked && z.senden)} />
                  Sehen
                </label>
                <label className={`flex items-center gap-2 text-xs ${darf ? 'cursor-pointer' : 'opacity-60'}`}>
                  <input type="checkbox" className="w-4 h-4 accent-stone-900"
                    disabled={!darf || laeuft === z.person} checked={z.senden}
                    onChange={e => setzen(z, z.sehen || e.target.checked, e.target.checked)} />
                  Weiterleiten
                </label>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminVertreterRechnungen;
